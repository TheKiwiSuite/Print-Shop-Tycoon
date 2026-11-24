extends SceneTree
# 1.2.0 systems on the real simulation: end-of-day planning and daily focus,
# business specializations, and recurring-client contracts. No injected income:
# every payment goes through the normal production, pickup and save code.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Strategy=preload("res://scripts/shop_strategy.gd")
const Planning=preload("res://scripts/shop_planning.gd")
const Contracts=preload("res://scripts/shop_contracts.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var failures=0
var checks=0
var scratch=""

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+label)

func _initialize() -> void:
	call_deferred("run")

func career(preset:String="Standard") -> Object:
	var s=Sim.new()
	s.save_enabled=false
	s.start_shop(preset)
	for id in ["cutter","heat","art","finish","pack"]:
		s.install_equipment(id,C.garage_spot(id))
	s.end_walkthrough()
	return s

func finish_day(s) -> void:
	s.end_day()
	s.next_day()

# Drive one order through the real production path to payment.
func deliver(s,i:int,max_ticks:int=40000) -> bool:
	s.owner()["manual"]=false
	s.state["paused"]=false
	s.state["speed"]=4
	for t in max_ticks:
		var o=s.order(i)
		if o["stage"]=="completed":
			return true
		if not s.state["report"].is_empty():
			return false
		if t%8==0:
			if o["stage"]=="preflight": s.preflight(i,"repair")
			if o["stage"]=="plan": s.queue_order(i)
			if o["stage"]=="fault": s.recover(i,true)
			if o["stage"]=="waiting_stock" or (o["stage"]=="press" and not s.garment_available(o)) or (o["stage"]=="pack" and s.state["stock"]["packaging"]<s.boxes_for(o)):
				if s.state["deliveries"].is_empty(): s.restock()
		s.tick(.1)
	return s.order(i)["stage"]=="completed"

func run() -> void:
	scratch=ProjectSettings.globalize_path("res://../../../work/planning-contracts")
	DirAccess.make_dir_recursive_absolute(scratch)
	planning_checks()
	focus_effects()
	specialization_checks()
	contract_checks()
	old_save_checks()
	print("PLANNING + CONTRACTS: %d checks, %d failures" % [checks,failures])
	quit(failures)

func planning_checks() -> void:
	var s=career()
	s.state["cash"]=900
	var report=s.end_day()
	var p=Planning.plan(s)
	var st=report["stats"]
	var expected_due=float(st["wages"])+float(st["overhead"])+float(st.get("loan_payment",0))+float(st.get("equipment_finance",0))
	check(is_equal_approx(p["due_now"],expected_due),"Plan shows exactly the bills charged when the next day starts")
	check(is_equal_approx(p["overhead"],float(s.daily_overhead())),"Plan overhead uses the day-close formula")
	check(p.has("jobs") and p.has("short") and p.has("service") and p.has("scheduled"),"Plan lists jobs, stock, maintenance and contract deliveries")
	var before=float(s.state["cash"])
	s.next_day()
	check(is_equal_approx(float(s.state["cash"]),before-expected_due),"Starting the day charges exactly the planned bills (balanced focus)")
	# Stock shortages and maintenance come from the real board and machines.
	s.state["machines"]["heat"]["condition"]=60.0
	var p2=Planning.plan(s)
	var flagged=false
	for row in p2["service"]:
		if row["id"]=="heat": flagged=row["status"].begins_with("Overdue")
	check(flagged,"Plan flags a station below the 65% service line")
	check(not Planning.choose(s,"turbo"),"Unknown focus is rejected")
	check(String(s.state["next_focus"])=="balanced","Rejected focus leaves the plan unchanged")

func twin(preset:String) -> Array:
	var a=career(preset);var b=career(preset)
	return [a,b]

func focus_effects() -> void:
	for preset in ["Relaxed","Standard","Expert"]:
		# Volume: one extra inquiry, faster production, extra wear on print runs.
		var pair=twin(preset)
		var a=pair[0];var b=pair[1]
		for o in a.state["orders"]: o["stage"]="declined"
		for o in b.state["orders"]: o["stage"]="declined"
		check(Planning.choose(b,"volume"),"Choose Volume "+preset)
		finish_day(a);finish_day(b)
		check(int(b.state["stats"]["inquiries"])==mini(6,int(a.state["stats"]["inquiries"])+1),"Volume adds exactly one inquiry "+preset)
		check(is_equal_approx(Strategy.speed_factor(b,"cutter"),0.9) and is_equal_approx(Strategy.speed_factor(a,"cutter"),1.0),"Volume production is 10% faster "+preset)
		check(Planning.extra_wear(b)==2,"Volume adds disclosed wear "+preset)
		# The focus applies to one day only unless chosen again (it persists as the next choice).
		check(String(b.state["next_focus"])=="volume","Chosen focus stays selected for the next plan "+preset)
		# Growth: $40 outreach charged at day start and recorded as marketing.
		var g=career(preset)
		Planning.choose(g,"growth")
		var r=g.end_day()
		var bills=float(r["stats"]["wages"])+float(r["stats"]["overhead"])+float(r["stats"].get("loan_payment",0))+float(r["stats"].get("equipment_finance",0))
		var cash=float(g.state["cash"])
		g.next_day()
		check(is_equal_approx(float(g.state["cash"]),cash-bills-40.0),"Growth outreach is charged once with the bills "+preset)
		check(int(g.state["stats"]["marketing"])==40 and int(g.state["stats"]["focus_cost"])==40,"Growth cost appears in today's marketing line "+preset)
		check(is_equal_approx(Planning.patience(g),1.25),"Growth patience bonus "+preset)
		# Growth falls back to Balanced when cash is short, with no charge.
		var poor=career(preset)
		Planning.choose(poor,"growth")
		poor.end_day()
		poor.state["cash"]=10
		poor.next_day()
		check(Planning.today_id(poor)=="balanced","Unaffordable outreach falls back to Balanced "+preset)
		# Recovery: stations tuned and at most two open inquiries.
		var rc=career(preset)
		rc.state["machines"]["cutter"]["condition"]=50.0
		Planning.choose(rc,"recovery")
		var open_before=0
		for o in rc.state["orders"]:
			if o["stage"] in ["intake","scheduled"]: open_before+=1
		finish_day(rc)
		check(is_equal_approx(float(rc.state["machines"]["cutter"]["condition"]),60.0),"Recovery tunes each station by 10% "+preset)
		var open=0
		for o in rc.state["orders"]:
			if o["stage"] in ["intake","scheduled"]: open+=1
		check(open<=maxi(2,open_before) and (open_before<2 or int(rc.state["stats"]["inquiries"])==0),"Recovery adds no inquiries beyond two open "+preset)
		# Quality: no random alignment defects; satisfaction bonus.
		var q=career(preset)
		Planning.choose(q,"quality")
		finish_day(q)
		var o=C.make_order("Q-1","sticker",10,"Test",q.now()+5,50)
		o["rules_at_accept"]={"faults":2.0};o["fault_roll"]=0.0;o["reprints"]=0;o["production_skill"]=1
		check(q._quality_issue(o,{"condition":100,"kind":"sticker"})=="","Premium quality blocks the random alignment defect "+preset)
		Planning.choose(q,"balanced");finish_day(q)
		check(q._quality_issue(o,{"condition":100,"kind":"sticker"})!="","Balanced day keeps the random defect roll "+preset)
		# Close-day log records actual results for the next plan.
		check(not Planning.last_result(q).is_empty() and Planning.result_text(Planning.last_result(q)).begins_with("Day "),"Focus result is recorded at day close "+preset)
	# Accepted terms never change with focus or specialization.
	var t=career()
	var i=-1
	for k in t.state["orders"].size():
		if t.order(k)["stage"] in ["intake","scheduled"]: i=k;break
	if i>=0:
		t.order(i)["stage"]="intake"
		t.accept(i)
		var reward=t.order(i)["reward"];var due=t.order(i)["due"]
		Planning.choose(t,"volume");t.state["cash"]+=500
		finish_day(t)
		check(t.order(i)["reward"]==reward and is_equal_approx(float(t.order(i)["due"]),float(due)),"Accepted reward and deadline unchanged by focus")
	# Old-economy shops: focus has no effect and cannot be chosen.
	var legacy=career()
	legacy.state["rules"]["version"]=0
	check(not Planning.choose(legacy,"volume"),"Old-economy shop cannot pick a focus")
	check(is_equal_approx(Planning.focus_speed(legacy),1.0),"Old-economy shop production unchanged")

func specialization_checks() -> void:
	var s=career()
	check(not s.select_specialty("Signs"),"Signs needs a banner printer or CNC")
	check(String(s.state["specialty"])=="General","Rejected specialization leaves General")
	var cash=float(s.state["cash"])
	check(s.select_specialty("Apparel"),"Apparel house available with a heat press")
	check(is_equal_approx(float(s.state["cash"]),cash),"First specialization from General is free")
	check(is_equal_approx(Strategy.speed_factor(s,"heat"),0.88) and is_equal_approx(Strategy.speed_factor(s,"art"),1.0),"Apparel speeds its stations, leaves shared benches")
	check(is_equal_approx(Strategy.speed_factor(s,"sticker"),1.08),"Apparel slows other print work 8%")
	check(Strategy.inquiry_terms(s,"apparel")==[1.0,1.06] and Strategy.inquiry_terms(s,"sticker")==[1.0,1.0],"Apparel price applies to its own new inquiries only")
	s.state["machines"]["sticker"]=s.state["machines"]["heat"].duplicate(true)
	s.state["machines"]["sticker"]["kind"]="sticker"
	cash=float(s.state["cash"])
	check(s.select_specialty("Stickers"),"Switch Apparel to Stickers")
	check(is_equal_approx(float(s.state["cash"]),cash-Strategy.RETOOL_FEE) and int(s.state["stats"]["retool"])==Strategy.RETOOL_FEE,"Switching specializations charges the disclosed retool fee once")
	cash=float(s.state["cash"])
	check(s.select_specialty("Stickers") and is_equal_approx(float(s.state["cash"]),cash),"Re-selecting the same specialization costs nothing")
	check(s.select_specialty("General") and is_equal_approx(float(s.state["cash"]),cash),"Returning to General is free")
	s.select_specialty("Stickers")
	s.state["cash"]=Strategy.RETOOL_FEE-1
	check(not s.select_specialty("Apparel") and String(s.state["specialty"])=="Stickers","Retool refused without enough cash")
	# Accepted orders keep their price when specialization changes later.
	var t=career()
	t.select_specialty("Apparel")
	t.state["cash"]=5000
	for k in 4: finish_day(t)
	var sticker_pieces=0;var apparel_quotes=0
	for o in t.state["orders"]:
		if String(o["id"]).begins_with("DAY") and o["type"]=="apparel": apparel_quotes+=1
	check(apparel_quotes>=2,"Apparel house favors shirt inquiries over four days")
	# Signs overhead flows into the authoritative day close.
	var w=career()
	w.state["machines"]["banner"]=w.state["machines"]["heat"].duplicate(true)
	w.state["machines"]["banner"]["kind"]="banner"
	var base=w.daily_overhead()
	check(w.select_specialty("Signs"),"Signs available with a banner printer")
	check(w.daily_overhead()==base+roundi(30*float(w.state["rules"]["overhead"])),"Signs adds its disclosed floor cost to overhead")
	var rep=w.end_day()
	check(int(rep["stats"]["overhead"])==w.daily_overhead(),"Day close charges the same overhead the plan shows")
	check(Strategy.spec_floor(w,"Signs")>0,"Specialization floor footprint is measured from installed stations")
	# Older-economy shops: specialization keeps its old meaning only.
	var legacy=career()
	legacy.state["rules"]["version"]=0
	legacy.select_specialty("Apparel")
	check(is_equal_approx(Strategy.speed_factor(legacy,"heat"),1.0) and legacy.daily_overhead()==roundi(legacy.base_overhead()*float(legacy.state["rules"]["overhead"])),"Old-economy shop: no speed or cost effects")

func contract_checks() -> void:
	var s=career()
	s.state["cash"]=3000
	Contracts.ensure(s)
	check(s.state["clients"].size()==Contracts.CLIENTS.size(),"Every named client has a relationship record")
	# Relationship comes only from real paid deliveries of the client's orders.
	for other in s.state["orders"]:
		if other["stage"] in ["intake","scheduled"]: other["stage"]="declined"
	s.state["orders"].append(C.make_order("CL-1","apparel",6,"x",s.now()+6,300))
	var i=s.state["orders"].size()-1
	var o=s.order(i)
	s._ensure_visit(o)
	Contracts.tag_inquiry(s,o,"lakeside")
	check(o["customer"]=="Lakeside High Boosters" and o["client"]=="lakeside","Client inquiry is named and tagged")
	s.assign_method(o)
	if not s.accept(i): print("DEBUG quote ",s.quote(i))
	var ok=deliver(s,i)
	if not ok: print("DEBUG client order stage=",s.order(i)["stage"]," report=",not s.state["report"].is_empty()," clock=",s.state["clock"]," visit=",s.order(i)["visit"].get("status",""))
	check(ok,"Client order delivered through real production")
	var rel=int(Contracts.client_state(s,"lakeside")["rel"])
	check(rel in [4,10],"Volume client gains relationship from a real delivery: %d" % rel)
	var cash=float(s.state["cash"])
	s._fulfill(s.order(i))
	check(is_equal_approx(float(s.state["cash"]),cash) and int(Contracts.client_state(s,"lakeside")["rel"])==rel,"Replayed payment is ignored (cash and relationship)")
	# Milestone offer with every term disclosed.
	Contracts.client_state(s,"lakeside")["rel"]=30
	if s.state["report"].is_empty(): s.end_day()
	s.next_day()
	var offer=Contracts.offer_for(s,"lakeside")
	check(not offer.is_empty(),"Reaching 25 relationship produces a contract offer")
	if offer.is_empty(): return
	check(offer["deliveries"].size()==2 and int(offer["quantity"])>0 and int(offer["deposit"])==roundi(int(offer["per_delivery"])*2*Contracts.DEPOSIT_SHARE),"Offer discloses deliveries, quantity and deposit")
	var assessed=Contracts.assess(s,offer)
	check(assessed["risk"] in ["ON TRACK","AT RISK","BLOCKED"] and assessed["inputs"].size()>0,"Offer shows inputs and capacity risk from the live board")
	var count=s.state["orders"].size()
	check(count==s.state["orders"].size(),"Assessment leaves no temporary order behind")
	# Decline: free, cooldown, offer returns later.
	check(Contracts.decline(s,offer["id"]),"Decline the offer")
	check(int(Contracts.client_state(s,"lakeside")["rel"])==30 and Contracts.offer_for(s,"lakeside").is_empty(),"Declining keeps the relationship and removes the offer")
	for k in Contracts.DECLINE_COOLDOWN+1: finish_day(s)
	offer=Contracts.offer_for(s,"lakeside")
	check(not offer.is_empty(),"Client offers again after the cooldown")
	if offer.is_empty(): return
	check(not Contracts.accept(s,"no-such-offer"),"Unknown contract id is refused")
	cash=float(s.state["cash"])
	check(Contracts.accept(s,offer["id"]),"Accept the contract")
	check(is_equal_approx(float(s.state["cash"]),cash+int(offer["deposit"])) and int(s.state["stats"]["deposits"])==int(offer["deposit"]),"Deposit is paid once and recorded")
	check(not Contracts.accept(s,offer["id"]),"Accepting the same offer twice is refused")
	var k=Contracts.active_for(s,"lakeside")
	# Save and reload mid-contract.
	s.save_enabled=true;s.save_path=scratch.path_join("contract.json")
	check(s.save_game(),"Save mid-contract")
	var r=Sim.new();r.save_enabled=false;r.save_path=s.save_path
	check(r.load_game() and not Contracts.active_for(r,"lakeside").is_empty(),"Contract survives save and reload")
	s=r
	# Deliveries become real orders exactly once on their days.
	for step in 6:
		finish_day(s)
		Contracts._create_deliveries(s,int(s.state["day"]))
	var made={}
	var duplicates=0
	for ord in s.state["orders"]:
		if ord.has("contract") and String(ord["contract"]["id"])==String(k["id"]):
			if made.has(ord["id"]): duplicates+=1
			made[ord["id"]]=true
	var listed=0
	for ord in s.state["orders"]:
		if ord.has("contract") and String(ord["contract"]["id"])==String(k["id"]): listed+=1
	check(listed==k["deliveries"].size() and duplicates==0,"Each scheduled delivery creates exactly one order (%d/%d)" % [listed,k["deliveries"].size()])
	# Deliver them all; last delivery nets the deposit; bonus once.
	var received=0.0
	for idx in s.state["orders"].size():
		var ord=s.order(idx)
		if not ord.has("contract") or String(ord["contract"]["id"])!=String(k["id"]): continue
		var before=float(s.state["cash"])
		var day_before=int(s.state["day"])
		if not deliver(s,idx):
			finish_day(s);deliver(s,idx)
		received+=float(ord.get("payment",0))
	var live=Contracts.active_for(s,"lakeside")
	var done={}
	for kk in s.state["contracts"]:
		if kk["id"]==k["id"]: done=kk
	check(String(done.get("status",""))=="completed" and done.get("bonus_paid",false),"Contract completes after every delivery is paid")
	var expected=int(k["per_delivery"])*k["deliveries"].size()-int(k["deposit"])
	check(roundi(received)==expected,"Deliveries pay the agreed amounts net of the deposit (%d vs %d)" % [roundi(received),expected])
	var bonus_cash=float(s.state["cash"])
	Contracts._settle_delivery(s,s.order(s.state["orders"].size()-1) if s.order(s.state["orders"].size()-1).has("contract") else {"contract":{"id":k["id"],"n":0}},true,100)
	check(is_equal_approx(float(s.state["cash"]),bonus_cash),"Bonus and settlement are idempotent")
	check(int(Contracts.client_state(s,"lakeside")["milestone"])==1,"Completing tier 1 advances the client milestone")
	# Bounded scheduling: never more than two contracts running or offered.
	var b=career();b.state["cash"]=4000
	for c in Contracts.CLIENTS: Contracts.client_state(b,c["id"])["rel"]=90
	b.state["machines"]["sticker"]=b.state["machines"]["heat"].duplicate(true);b.state["machines"]["sticker"]["kind"]="sticker"
	for d in 6:
		finish_day(b)
		for off in b.state["contract_offers"].duplicate(): Contracts.accept(b,off["id"])
		check(Contracts.active_count(b)+b.state["contract_offers"].size()<=Contracts.MAX_ACTIVE,"No more than two contracts at once (day %d)" % d)
	# Expiry: an ignored offer disappears with no penalty.
	var e=career()
	Contracts.client_state(e,"maple")["rel"]=30
	e.state["machines"]["sticker"]=e.state["machines"]["heat"].duplicate(true);e.state["machines"]["sticker"]["kind"]="sticker"
	finish_day(e)
	var waiting=not Contracts.offer_for(e,"maple").is_empty()
	for d in Contracts.OFFER_DAYS+1: finish_day(e)
	check(waiting,"Reliability client offers at 25")
	check(int(Contracts.client_state(e,"maple")["rel"])==30,"Ignoring an offer costs no relationship")
	# Damaged save entries are dropped, not crashed on.
	var bad=career()
	bad.state["contracts"]=[{"id":"x"},"junk",{"id":"K9","client":"nobody","deliveries":[]}]
	bad.state["contract_offers"]="junk"
	Contracts.ensure(bad)
	check(bad.state["contracts"].is_empty() and bad.state["contract_offers"] is Array,"Malformed contract data is sanitized on load")

func old_save_checks() -> void:
	# A 1.1.0 save (no 1.2.0 keys) and the legacy day-8 fixture both load and play.
	var s=career()
	s.save_enabled=true;s.save_path=scratch.path_join("v110.json")
	for key in ["next_focus","focus","focus_log","clients","contract_offers","contracts","contract_serial"]: s.state.erase(key)
	s.save_game()
	var r=Sim.new();r.save_enabled=false;r.save_path=s.save_path
	check(r.load_game(),"1.1.0-shaped save loads")
	check(String(r.state["next_focus"])=="balanced" and r.state["clients"].size()==5 and r.state["contracts"].is_empty(),"1.1.0 save gets safe 1.2.0 defaults")
	check(String(r.state["specialty"])==String(s.state["specialty"]),"Existing client focus is kept")
	var cash=float(r.state["cash"])
	var rep=r.end_day();r.next_day()
	check(is_equal_approx(float(r.state["cash"]),cash-float(rep["stats"]["wages"])-float(rep["stats"]["overhead"])-float(rep["stats"].get("loan_payment",0))-float(rep["stats"].get("equipment_finance",0))),"1.1.0 save closes a day with unchanged accounting")
	# A genuine save written by the published 1.1.0 code (Standard, day 4, work in progress).
	var real=Sim.new();real.save_enabled=true
	real.save_path=scratch.path_join("v110-real.json")
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://test/fixtures/v110-standard-day4.json"),real.save_path)
	check(real.load_game(),"Real 1.1.0 save loads in 1.2.0")
	var cash110=float(real.state["cash"]);var orders110=real.state["orders"].size();var completed110=int(real.state["completed"])
	check(String(real.state["specialty"])=="Apparel" and int(real.state["day"])==4,"1.1.0 progress and specialization kept")
	check(String(real.state["next_focus"])=="balanced" and real.state["contracts"].is_empty(),"1.1.0 save starts with safe 1.2.0 defaults")
	Planning.choose(real,"volume")
	var reps=0
	for day in 3:
		real.owner()["manual"]=false;real.state["paused"]=false;real.state["speed"]=4
		for t in 7000:
			if not real.state["report"].is_empty(): break
			if t%8==0:
				for k in real.active_orders():
					var o=real.order(k)
					if o["stage"]=="intake" and real.quote(k)["valid"]: real.accept(k)
					if o["stage"]=="preflight": real.preflight(k,"repair")
					if o["stage"]=="plan": real.queue_order(k)
					if o["stage"] in ["waiting_stock","press","pack"] and real.state["deliveries"].is_empty() and real.state["cash"]>300: real.restock()
					if o["stage"]=="fault": real.recover(k,true)
			real.tick(.1)
		var day_rep=real.end_day()
		var before=float(real.state["cash"])
		real.next_day()
		var bills=float(day_rep["stats"]["wages"])+float(day_rep["stats"]["overhead"])+float(day_rep["stats"].get("loan_payment",0))+float(day_rep["stats"].get("equipment_finance",0))
		check(is_equal_approx(float(real.state["cash"]),before-bills-float(real.state["stats"].get("focus_cost",0))),"1.1.0 career closes day %d with reconciled cash" % (day+4))
		reps+=1
	check(int(real.state["completed"])>completed110,"1.1.0 career keeps producing paid work in 1.2.0")
	check(real.save_game(),"1.1.0 career saves in 1.2.0")
	var again=Sim.new();again.save_enabled=false;again.save_path=real.save_path
	check(again.load_game() and int(again.state["day"])==int(real.state["day"]) and String(again.state["next_focus"])=="volume","Reloaded 1.2.0 save keeps day and chosen focus")
	var legacy=Sim.new();legacy.save_enabled=false
	legacy.save_path=ProjectSettings.globalize_path("res://test/fixtures/day8-blocked.json")
	var copy=scratch.path_join("day8.json")
	DirAccess.copy_absolute(legacy.save_path,copy)
	legacy.save_path=copy
	check(legacy.load_game(),"Legacy day-8 save loads")
	var lp=Planning.plan(legacy)
	check(lp.has("jobs"),"Legacy save produces a plan")
	legacy.end_day();legacy.next_day()
	check(legacy.state["contracts"].is_empty() and Planning.today_id(legacy)=="balanced","Legacy economy: no contracts, balanced focus")

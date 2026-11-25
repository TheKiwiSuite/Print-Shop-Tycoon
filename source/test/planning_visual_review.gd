extends SceneTree
# Rendered layout certification for the 1.2.0 planning, specialization and contract panels.
# Checks every recorded modal text block against every control and every other
# text block, keeps text and controls inside the modal panel, and captures PNGs.
const C=preload("res://scripts/catalog.gd")
const Ops=preload("res://scripts/shop_operations.gd")
const Style=preload("res://scripts/shop_style.gd")
const Planning=preload("res://scripts/shop_planning.gd")
const Contracts=preload("res://scripts/shop_contracts.gd")
const Strategy=preload("res://scripts/shop_strategy.gd")
var game
var folder=""
var failures=0
var checks=0
var captured=0

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+label)

func _initialize() -> void:
	call_deferred("run")

func frame() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func layout(name:String,save:bool=true) -> void:
	await frame()
	var panel=Rect2(Vector2(355,105)+game.ui_offset,Vector2(890,680)).grow(1)
	var screen=Rect2(Vector2.ZERO,game.get_viewport_rect().size)
	var texts=game.layout_text.duplicate()
	var controls=game.semantic_buttons.duplicate()
	check(not texts.is_empty(),"Layout recorded "+name)
	for c in controls:
		check(screen.encloses(c["rect"]),"Control on screen "+name+" / "+c["label"])
		if game.modal!="" and c["action"]!="close":
			check(panel.encloses(c["rect"]),"Control inside panel "+name+" / "+c["label"])
	for i in texts.size():
		var t=texts[i]
		var r:Rect2=t["rect"].grow(-1)
		if r.size.x<=0 or str(t["text"]).strip_edges()=="":
			continue
		if game.modal!="":
			check(panel.encloses(r),"Text inside panel "+name+" / "+str(t["text"]).left(60))
		for c in controls:
			check(not r.intersects(c["rect"]),"Text clear of control "+name+" / "+str(t["text"]).left(50)+" / "+c["label"])
		for j in range(i+1,texts.size()):
			var u:Rect2=texts[j]["rect"].grow(-1)
			if u.size.x<=0 or str(texts[j]["text"]).strip_edges()=="":
				continue
			check(not r.intersects(u),"Text clear of text "+name+" / "+str(t["text"]).left(40)+" / "+str(texts[j]["text"]).left(40))
	for i in controls.size():
		for j in range(i+1,controls.size()):
			check(not controls[i]["rect"].intersects(controls[j]["rect"]),"Controls separate "+name+" / "+controls[i]["label"]+" / "+controls[j]["label"])
	if save:
		var image=root.get_texture().get_image()
		check(not image.is_empty(),"Frame rendered "+name)
		if not image.is_empty():
			image.save_png(folder.path_join(name+".png"))
			captured+=1

func add_order(type:String,quantity:int,reward:int) -> int:
	var o=C.make_order("QA-%s-%d" % [type.to_upper(),game.sim.state["orders"].size()],type,quantity,"Layout Check Club With A Long Name",game.sim.now()+6.0,reward)
	game.sim.state["orders"].append(o)
	return game.sim.state["orders"].size()-1

func order_stage(index:int,stage:String) -> void:
	var o=game.sim.order(index)
	o["stage"]=stage
	if stage=="fault":
		o["issue"]="Registration drift on the contour cut; marks were misread at the right edge"
	if stage=="completed":
		o["payment"]=o["reward"];o["satisfaction"]=100;o["quality"]=100


func no_truncation(name:String) -> void:
	for t in game.layout_text:
		check(not t.get("truncated",false),"Text not truncated "+name+" / "+str(t["text"]).left(60))

func text_has(fragment:String) -> bool:
	for t in game.layout_text:
		if str(t["text"]).find(fragment)>=0:
			return true
	return false

func run() -> void:
	folder=ProjectSettings.globalize_path("res://../captures/planning-review")
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://main.tscn").instantiate()
	game.sim.save_enabled=false
	root.add_child(game)
	game.set_process(false)
	game.screen="shop"
	game.sim.start_demo()
	game.music.stop()
	var s=game.sim
	Contracts.ensure(s)
	Planning.ensure(s)
	s.state["cash"]=4000
	# A full queue with long names, every risk state and a contract delivery.
	var risks=["sticker","apparel","transfer","decal","sticker","apparel","transfer"]
	for k in risks.size():
		var i=add_order(risks[k],24 if risks[k]!="apparel" else 6,210+k)
		order_stage(i,["queued","plan","preflight","press","qc","pack","queued"][k])
		s.order(i)["due"]=s.now()+(0.5 if k%3==0 else 6.0)
	s.state["machines"]["heat"]["condition"]=55.0
	s.state["machines"]["sticker"]["condition"]=70.0
	for key in ["film","white","sticker","laminate"]: s.state["stock"][key]=0
	for c in Contracts.CLIENTS: Contracts.client_state(s,c["id"])["rel"]=[0,30,58,100,12][Contracts.CLIENTS.find(c)]
	for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=size
		await process_frame
		game.reset_camera()
		var tag="%dx%d" % [size.x,size.y]
		# Day report -> plan, with a pending report.
		s.state["report"]={}
		s.state["report_applied"]=false
		s.state["stats"]["deposits"]=88
		s.end_day()
		game.modal="report"
		await layout(tag+"-day-report")
		check(text_has("Sales + contract deposits"),"Report names contract deposits "+tag)
		game._action("plan")
		check(game.modal=="plan","PLAN TOMORROW opens the plan "+tag)
		for id in Planning.FOCUS_ORDER:
			game._action("focus:"+id)
			check(String(s.state["next_focus"])==id,"Focus button selects "+id+" "+tag)
			await layout("%s-plan-%s" % [tag,id],id in ["balanced","growth","recovery"])
			no_truncation(tag+" plan "+id)
			check(text_has(Planning.FOCUS[id]["effects"]),"Plan discloses the effect of "+id+" "+tag)
		check(text_has("(actual)") and text_has("(estimate)"),"Plan separates actuals from estimates "+tag)
		check(text_has("Overdue"),"Plan lists overdue maintenance "+tag)
		check(text_has("Short:"),"Plan lists stock shortages "+tag)
		game._action("focus:balanced")
		# Mid-day plan (no pending report).
		s.state["report"]={}
		game.modal="plan"
		await layout(tag+"-plan-midday")
		no_truncation(tag+" plan midday")
		# Specialization panel: General current, all choices visible with costs.
		game._action("specialize")
		check(game.modal=="specialize","Plan opens specialization "+tag)
		s.state["specialty"]="General"
		await layout(tag+"-specialize-general")
		no_truncation(tag+" specialize")
		check(text_has("RETOOL")==false,"No retool fee shown from General "+tag)
		s.state["specialty"]="Stickers"
		await layout(tag+"-specialize-stickers")
		check(text_has("$%d RETOOL" % Strategy.RETOOL_FEE) or game.semantic_buttons.any(func(b):return str(b["label"]).find("RETOOL")>=0),"Retool fee disclosed before switching "+tag)
		var cash=float(s.state["cash"])
		game._action("spec_pick:Apparel")
		check(String(s.state["specialty"])=="Apparel" and is_equal_approx(float(s.state["cash"]),cash-Strategy.RETOOL_FEE),"Switch through the panel charges the disclosed fee "+tag)
		s.state["specialty"]="General"
		game._action("spec_back")
		check(game.modal=="plan","Back returns to the plan "+tag)
		# Clients: no offers, then offers from each trait, paging, running contracts.
		game._action("clients")
		s.state["contract_offers"]=[]
		await layout(tag+"-clients-none")
		no_truncation(tag+" clients none")
		var offers=[]
		for id in ["maple","riverside","lakeside"]:
			var o=Contracts.build_offer(s,id,2,int(s.state["day"]))
			check(not o.is_empty(),"Offer builds for "+id+" "+tag)
			if not o.is_empty(): offers.append(o)
		s.state["contract_offers"]=offers.slice(0,2)
		game.client_offer_page=0
		await layout(tag+"-clients-offer-1")
		no_truncation(tag+" offer 1")
		check(text_has("deposit today") and text_has("Inputs per delivery") and text_has("Capacity (estimate)"),"Offer shows payments, inputs and capacity before acceptance "+tag)
		check(game.semantic_buttons.any(func(b):return str(b["action"])=="offer_next"),"Offer paging control is drawn "+tag)
		var page_image=root.get_texture().get_image()
		var page_rect:Rect2=Rect2()
		for b in game.semantic_buttons:
			if str(b["action"])=="offer_next": page_rect=b["rect"]
		# The control is visible: its pixels differ from the card's fill colour.
		var visible_pixels=0
		if page_rect.size.x>0:
			for x in range(int(page_rect.position.x)+4,int(page_rect.end.x)-4,6):
				var px=page_image.get_pixel(x,int(page_rect.get_center().y))
				if px.is_equal_approx(Color("fff8e1"))==false: visible_pixels+=1
		check(visible_pixels>4,"Offer paging control is not hidden under the card "+tag)
		game._action("offer_next")
		await layout(tag+"-clients-offer-2")
		game._action("offer_next")
		check(game.client_offer_page==0,"Offer paging wraps "+tag)
		var first=s.state["contract_offers"][0]
		cash=float(s.state["cash"])
		var accept_enabled=false
		for b in game.semantic_buttons:
			if str(b["action"])=="contract_accept:"+first["id"]: accept_enabled=b.get("enabled",true)
		game._action("contract_accept:"+first["id"])
		check(Contracts.active_count(s)==1 and is_equal_approx(float(s.state["cash"]),cash+int(first["deposit"])),"Accept through the panel pays the deposit once "+tag)
		s.state["contract_offers"]=[offers[2]]
		await layout(tag+"-clients-offer-with-active")
		game._action("contract_decline:"+offers[2]["id"])
		check(s.state["contract_offers"].is_empty(),"Decline through the panel "+tag)
		await layout(tag+"-clients-running")
		no_truncation(tag+" clients running")
		s.state["contracts"]=[]
		game._action("clients_back")
		check(game.modal=="plan","Clients back returns to the plan "+tag)
		# Growth panel specialization block and customers panel link.
		game.modal="move"
		await layout(tag+"-growth-specialization")
		game.modal="customers"
		await layout(tag+"-customers-with-clients")
		game._action("clients")
		check(game.modal=="clients","Customers panel opens clients "+tag)
		game._action("clients_back")
		check(game.modal=="customers","Back returns to customers "+tag)
		game.modal=""
	# Legacy-economy shop shows the older-economy notes without crashing.
	s.state["rules"]["version"]=0
	root.size=Vector2i(1280,720)
	await process_frame
	game.modal="specialize"
	await layout("1280x720-specialize-legacy")
	game.modal="clients"
	await layout("1280x720-clients-legacy")
	game.modal="plan"
	await layout("1280x720-plan-legacy")
	game.modal=""
	await preload("res://test/qa_audio_cleanup.gd").stop(game,self);game.queue_free()
	await process_frame
	print("PLANNING VISUAL REVIEW: %d checks, %d failures, %d captures" % [checks,failures,captured])
	call_deferred("quit",failures)

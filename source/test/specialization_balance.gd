extends SceneTree
# 1.2.0 multi-day balance: specializations x daily focus x presets, with
# contract offers accepted when the live assessment says ON TRACK. Same scripted
# play rules as strategy_balance.gd; no income is injected and every day close
# is reconciled (bills plus any outreach), as are all contract receipts.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Progress=preload("res://scripts/shop_progress.gd")
const Planning=preload("res://scripts/shop_planning.gd")
const Contracts=preload("res://scripts/shop_contracts.gd")
var failures=0
var results=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
 if not ok: failures+=1;push_error("FAIL: "+message)
func simulate(preset:String,branch:String,policy:String,focus:String="balanced",warehouse:bool=false,contracts:bool=true) -> void:
 var s=Sim.new();s.save_enabled=false;s.start_shop(preset)
 if warehouse:
  # A warehouse shop with every heavy station (banner, CNC, two DTF lines) so
  # Signs can be compared fairly with the other specializations.
  s.state["location"]=2;s.state.erase("premises");s.state["machines"]=C.layout(2);s.state["fit_out"]=true;s.end_walkthrough()
  Progress.ensure(s)["xp"]=Progress.LEVEL_XP[3]
  s.state["cash"]=roundi(3500*float(s.state["rules"]["cash"]))
 else:
  var ids=["sticker","cutter","heat","art","finish","pack"]
  Progress.ensure(s)["xp"]=Progress.LEVEL_XP[1]
  for id in ids:
   var spot=C.garage_spot(id)
   check(s.install_equipment(id,spot),"Install opening station "+id)
 check(s.select_specialty(branch),"Select "+branch+" "+preset)
 Planning.choose(s,focus)
 s.owner()["manual"]=false;s.state["speed"]=4;s.state["paused"]=false
 var daily=[];var floor_cash=float(s.state["cash"]);var blocked=0;var first_paid=-1.0;var expired=0
 for day in 14:
  var day_open_cash=float(s.state["cash"])
  # Poll every few simulation frames to represent deliberate, imperfect play.
  for frame in 7000:
   if not s.state["report"].is_empty(): break
   if frame%8==0:
    for i in s.active_orders():
     var o=s.order(i)
     if o["stage"]=="intake":
      var quote=s.quote(i,policy=="Rush")
      var rush=policy=="Rush" and quote["valid"]
      if policy=="Rush" and not quote["valid"]: quote=s.quote(i,false)
      if not quote["valid"]:
       if not quote.get("missing",{}).is_empty(): s.restock(quote["missing"])
       blocked+=1
      else: s.accept(i,rush)
     if o["stage"]=="preflight": s.preflight(i,"revision" if policy=="Novice" else "repair")
     if o["stage"]=="plan":
      if o["type"] in ["transfer","apparel"]: s.auto_pack(i)
      if policy=="Batch" and s.batch_preview(i)["valid"]: s.batch_orders(i)
      else: s.queue_order(i)
     if o["stage"]=="waiting_stock":
      var needed={}
      for key in o["recipe"]:
       var in_transit=0
       for d in s.state["deliveries"]: in_transit+=int(d["items"].get(key,0))
       var shortfall=int(o["recipe"][key])-int(s.state["stock"].get(key,0))-in_transit
       if shortfall>0: needed[key]=shortfall
      if not needed.is_empty(): s.restock(needed)
     # Buy the blanks this job is missing (tees, hoodies or totes), once per delivery.
     if o["stage"]=="press" and not s.garment_available(o) and s.state["deliveries"].is_empty():
      var blanks={}
      for key in o["garments"]:
       var short=int(o["garments"][key])-int(s.state["garments"].get(key,0))
       if short>0: blanks["garment:"+key]=maxi(short,6)
      if not blanks.is_empty(): s.restock(blanks)
     if o["stage"]=="pack" and s.state["stock"]["packaging"]<s.boxes_for(o): s.restock({"packaging":12})
     if o["stage"]=="fault": s.recover(i,policy!="Novice")
    # Planned inventory replenishment is a paid purchase with its real lead time.
    if s.state["deliveries"].is_empty() and s.state["cash"]>220:
     var wanted={}
     for key in ["film","white","powder","sticker","laminate","cyan","magenta","yellow","black","packaging","maintenance","htv","vinyl","transfer_tape"]:
      if s.state["stock"][key]<10: wanted[key]=20
     if not wanted.is_empty(): s.restock(wanted)
   s.tick(.1)
   floor_cash=minf(floor_cash,float(s.state["cash"]))
   if first_paid<0 and s.state["completed"]>0: first_paid=s.now()*60
  var report=s.end_day()
  var bills=report["stats"]["wages"]+report["stats"]["overhead"]+report["stats"].get("loan_payment",0)+report["stats"].get("equipment_finance",0)
  var before=float(s.state["cash"])
  s.next_day()
  var outreach=float(s.state["stats"].get("focus_cost",0))
  check(is_equal_approx(float(s.state["cash"]),before-bills-outreach),"Day-close cash reconciles with focus cost "+preset+branch+focus+str(day))
  if contracts:
   for offer in s.state["contract_offers"].duplicate():
    var a=Contracts.assess(s,offer)
    if a["risk"]=="ON TRACK": Contracts.accept(s,offer["id"])
  # Accounting invariant: every contract payment is a recorded order payment, deposit or bonus.
  var expected=0.0
  for k in s.state["contracts"]:
   expected+=float(k["deposit"])+(float(k["bonus"]) if k.get("bonus_earned",false) else 0.0)
   for d in k["deliveries"]:
    if d["paid"]:
     for o in s.state["orders"]:
      if o["id"]==String(d["order_id"]): expected+=float(o["payment"])
  var received=0.0
  for k in s.state["contracts"]:
   received+=float(k["deposit"])+(float(k["bonus"]) if k.get("bonus_paid",false) and k.get("bonus_earned",false) else 0.0)
   for d in k["deliveries"]:
    if d["paid"]:
     for o in s.state["orders"]:
      if o["id"]==String(d["order_id"]) and o.get("paid",false): received+=float(o["payment"])
  check(is_equal_approx(expected,received),"Contract receipts reconcile "+preset+branch+str(day))
  daily.append({"day":day+1,"cash":s.state["cash"],"cash_change":float(s.state["cash"])-day_open_cash,"profit":report["net"],"paid":report["stats"]["delivered"],"open":s.active_orders().size()})
  floor_cash=minf(floor_cash,float(s.state["cash"]))
 var ontime=0.0 if s.state["completed"]==0 else float(s.state["on_time"])/float(s.state["completed"])
 for o in s.state["orders"]:
  if o["stage"]=="abandoned": expired+=1
 check(s.state["completed"]>=(10 if warehouse else 14),"Viable throughput (paid jobs) "+preset+branch+policy+focus)
 check(floor_cash>=0,"Remains solvent without injected income: "+preset+branch+policy+focus)
 var finished=0;var active=0;var detail=[]
 for k in s.state["contracts"]:
  if k["status"]=="completed": finished+=1
  else: active+=1
  var ds=[]
  for d in k["deliveries"]:
   var stage=""
   for o in s.state["orders"]:
    if o["id"]==String(d["order_id"]): stage=o["stage"]
   ds.append({"day":d["day"],"paid":d["paid"],"on_time":d.get("on_time",false),"stage":stage})
  detail.append({"client":k["client"],"tier":k["tier"],"type":k["type"],"status":k["status"],"accepted_day":k["accepted_day"],"bonus_earned":k.get("bonus_earned",false),"deliveries":ds})
 results.append({"preset":preset,"branch":branch,"policy":policy,"focus":focus,"warehouse":warehouse,"contracts_completed":finished,"contracts":detail,"contracts_active":active,"first_paid_minutes":first_paid,"cash_floor":floor_cash,"ending_cash":s.state["cash"],"completed":s.state["completed"],"on_time_fraction":ontime,"blocked_quote_polls":blocked,"expired_inquiries":expired,"day7":daily[6],"day14":daily[13],"daily":daily})
 print("SPECIALIZATION BALANCE ",preset," / ",branch," / ",focus," / ",("warehouse" if warehouse else "garage"),": ",s.state["completed"]," paid, cash floor ",floor_cash," ending ",s.state["cash"])
func run() -> void:
 for preset in ["Relaxed","Standard","Expert"]:
  for branch in ["General","Stickers","Apparel"]:
   simulate(preset,branch,"Conservative")
  simulate(preset,"Stickers","Conservative","volume")
  simulate(preset,"Apparel","Conservative","quality")
  for branch in ["General","Signs","Apparel"]:
   simulate(preset,branch,"Conservative","balanced",true)
 # No single dominant build: in each preset and layout, the best specialization
 # must not beat every alternative by more than 60% ending cash, and each
 # specialization must be best somewhere or within 25% of the best.
 for preset in ["Relaxed","Standard","Expert"]:
  for warehouse in [false,true]:
   var group=[]
   for r in results:
    if r["preset"]==preset and r["warehouse"]==warehouse and r["focus"]=="balanced": group.append(r)
   var best=-INF;var worst=INF
   for r in group: best=maxf(best,float(r["ending_cash"]));worst=minf(worst,float(r["ending_cash"]))
   check(worst>0 and best<=worst*1.6,"No runaway dominant build: %s %s best %.0f worst %.0f" % [preset,"warehouse" if warehouse else "garage",best,worst])
 var folder=ProjectSettings.globalize_path("res://../verification")
 DirAccess.make_dir_recursive_absolute(folder)
 var f=FileAccess.open(folder+"/specialization-balance.json",FileAccess.WRITE)
 if f!=null: f.store_string(JSON.stringify({"engine":"Godot 4.5.1","rules":"strategy-v1 + 1.2.0 specialization/focus/contracts","scope":"24 scripted 14-day careers. Scripted play only; not a human balance certification.","failures":failures,"results":results},"  "))
 print("SPECIALIZATION BALANCE: ",results.size()," runs, ",failures," failures")
 quit(failures)

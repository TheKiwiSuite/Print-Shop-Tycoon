extends SceneTree
# Repeatable policies exercise actual arrivals, acceptance, production, restocking,
# receipts and day-close charges. They do not inject income or completed work.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var failures=0
var results=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
 if not ok: failures+=1;push_error("FAIL: "+message)
func simulate(preset:String,branch:String,policy:String) -> void:
 var s=Sim.new();s.save_enabled=false;s.start_shop(preset)
 var ids=["sticker","art","finish","pack"] if branch=="Stickers" else ["dtf","heat","art","finish","pack"]
 for id in ids:
  check(s.install_equipment(id,s.cell(C.layout(1)[id]["pos"])),"Install opening station "+id)
 s.select_specialty(branch);s.owner()["manual"]=false;s.state["speed"]=4;s.state["paused"]=false
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
     if o["stage"]=="press" and not s.garment_available(o): s.restock({"garment:navy:S":6,"garment:navy:M":6,"garment:navy:L":6})
     if o["stage"]=="pack" and s.state["stock"]["packaging"]<s.boxes_for(o): s.restock({"packaging":12})
     if o["stage"]=="fault": s.recover(i,policy!="Novice")
    # Planned inventory replenishment is a paid purchase with its real lead time.
    if s.state["deliveries"].is_empty() and s.state["cash"]>220:
     var wanted={}
     for key in ["film","white","powder","sticker","laminate","cyan","magenta","yellow","black","packaging","maintenance"]:
      if s.state["stock"][key]<10: wanted[key]=20
     if not wanted.is_empty(): s.restock(wanted)
   s.tick(.1)
   floor_cash=minf(floor_cash,float(s.state["cash"]))
   if first_paid<0 and s.state["completed"]>0: first_paid=s.now()*60
  var report=s.end_day()
  var bills=report["stats"]["wages"]+report["stats"]["overhead"]+report["stats"].get("loan_payment",0)
  var before=float(s.state["cash"])
  s.next_day()
  check(is_equal_approx(float(s.state["cash"]),before-bills),"Day-close cash reconciles "+preset+branch+str(day))
  daily.append({"day":day+1,"cash":s.state["cash"],"cash_change":float(s.state["cash"])-day_open_cash,"profit":report["net"],"paid":report["stats"]["delivered"],"open":s.active_orders().size()})
  floor_cash=minf(floor_cash,float(s.state["cash"]))
 var ontime=0.0 if s.state["completed"]==0 else float(s.state["on_time"])/float(s.state["completed"])
 for o in s.state["orders"]:
  if o["stage"]=="abandoned": expired+=1
 check(s.state["completed"]>=14,"At least one paid job/day on average: "+preset+branch+policy)
 check(floor_cash>=0,"Opening branch remains solvent without injected income: "+preset+branch+policy)
 results.append({"preset":preset,"branch":branch,"policy":policy,"first_paid_minutes":first_paid,"cash_floor":floor_cash,"ending_cash":s.state["cash"],"completed":s.state["completed"],"on_time_fraction":ontime,"blocked_quote_polls":blocked,"expired_inquiries":expired,"day7":daily[6],"day14":daily[13],"daily":daily})
 print("BALANCE ",preset," / ",branch," / ",policy,": ",s.state["completed"]," paid, cash floor ",floor_cash," ending ",s.state["cash"])
func run() -> void:
 for preset in ["Relaxed","Standard","Expert"]:
  for branch in ["Stickers","Apparel"]:
   simulate(preset,branch,"Conservative")
  simulate(preset,"Stickers","Novice")
  simulate(preset,"Apparel","Rush")
 var folder=ProjectSettings.globalize_path("res://../verification")
 DirAccess.make_dir_recursive_absolute(folder)
 var f=FileAccess.open(folder+"/strategy-balance.json",FileAccess.WRITE)
 if f!=null: f.store_string(JSON.stringify({"engine":"Godot 4.5.1","rules":"strategy-v1","scope":"12 reproducible scripted policies over 14 actual shop days. No manual-player or animation certification.","failures":failures,"runs":results},"  "))
 print("STRATEGY BALANCE: ",results.size()," runs, ",failures," failures")
 quit(failures)

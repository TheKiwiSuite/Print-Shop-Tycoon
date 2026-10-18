extends RefCounted
# Authored game rules, not manufacturer throughput or prices.
const C=preload("res://scripts/catalog.gd")
const FACTORS=["cash","slack","overhead","supply","patience","faults"]
const PRESETS={
 "Relaxed":[1.5,1.5,0.75,0.75,1.5,0.5],
 "Standard":[1.0,1.0,1.0,1.0,1.0,1.0],
 "Expert":[0.85,0.85,1.15,1.15,0.85,1.15]}
const BASE_CASH=1600
const SPECIALTIES={"General":["transfer","sticker","apparel","banner","cnc"],"Stickers":["sticker"],"Apparel":["transfer","apparel"],"Signs":["banner","cnc"]}

static func rules(preset:String,custom:Dictionary={}) -> Dictionary:
 var result={"preset":preset if PRESETS.has(preset) else "Custom","version":1}
 var values=PRESETS.get(preset,PRESETS["Standard"])
 for i in FACTORS.size():
  var key=FACTORS[i]
  result[key]=clampf(float(custom.get(key,values[i])),0.5,2.0)
 return result

static func ensure(s) -> void:
 # Existing shops keep the old economy until an explicit rules change.
 if not s.state.get("rules") is Dictionary:
  s.state["rules"]=rules("Standard");s.state["rules"]["version"]=0
 if not s.state.has("rule_history"): s.state["rule_history"]=[]
 if not s.state.has("specialty"): s.state["specialty"]="General"
 if not s.state.has("client_presets"): s.state["client_presets"]={}
 if not s.state.has("fit_out"): s.state["fit_out"]=int(s.state["location"])==2
 if not s.state.has("rescue_used"): s.state["rescue_used"]=false

static func planned(o:Dictionary) -> Dictionary:
 var p=o.duplicate(true)
 if p["type"] in ["transfer","apparel"] and p["gang"].is_empty():
  var best=[]
  for turn in [false,true]:
   var w=float(p["art_h"] if turn else p["art_w"])
   var h=float(p["art_w"] if turn else p["art_h"])
   if w<=0 or h<=0: continue
   var candidate=[]
   for y in floori(float(p["sheet_length"])/h):
    for x in floori(float(p["film_width"])/w):
     if candidate.size()<int(p["quantity"]): candidate.append([x*w,y*h,w,h])
   if candidate.size()>best.size(): best=candidate
  p["gang"]=best
 return p

static func inputs(o:Dictionary) -> Dictionary:
 var required={}
 if not o.get("consumed",false) and o["stage"] not in ["press","pressing","qc","inspecting","fault","pack","packing","ready","delivering","completed"]:
  required=o.get("batch_recipe",C.recipe(planned(o))).duplicate(true)
 if o["type"]=="apparel" and not o.get("garments_consumed",false):
  for key in o["garments"]: required["garment:"+key]=o["garments"][key]
 if not o.get("boxes_consumed",false) and o["stage"] not in ["ready","delivering","completed"]:
  required["packaging"]=maxi(1,ceili(float(o["quantity"])/50.0))
 return required

static func route(o:Dictionary) -> Array:
 var print_station={"transfer":"dtf","apparel":"dtf","sticker":"sticker","banner":"banner","cnc":"cnc"}[o["type"]]
 var stages=["art",print_station]
 if o["type"]=="apparel": stages.append("heat")
 stages.append_array(["finish","pack","handoff"])
 var current={"intake":"art","preflight":"art","prepress":"art","revision":"art","plan":print_station,"queued":print_station,"waiting_stock":print_station,"production":print_station,"batch_wait":print_station,"press":"heat","pressing":"heat","qc":"finish","inspecting":"finish","fault":"finish","pack":"pack","packing":"pack","ready":"handoff","delivering":"handoff"}.get(o["stage"],"art")
 return stages.slice(maxi(0,stages.find(current)))

static func board(s,include_inquiries:bool=false) -> Dictionary:
 ensure(s)
 var inventory=s.state["stock"].duplicate(true)
 for key in s.state["garments"]: inventory["garment:"+key]=s.state["garments"][key]
 var original=inventory.duplicate(true)
 var reserved={};var station_free={};var worker_free={};var worker_pos={};var batch_release={};var rows=[]
 var clock=s.now()
 for w in s.state["workers"]: worker_free[w["id"]]=clock;worker_pos[w["id"]]=Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1]))
 # Seed availability with actual in-flight work so new quotes cannot skip it.
 for w in s.state["workers"]:
  var task=w["task"]
  if w.has("service_job"):
   var m=s.state["machines"].get(w["service_job"],{})
   if m.has("service_work"):worker_free[w["id"]]=clock+(float(m["service_work"]["remaining"])+w["path"].size()/2.2)*s.SHOP_HOURS_PER_SECOND
  if task.is_empty(): continue
  var m=s.state["machines"].get(task["machine"],{})
  if m.is_empty(): continue
  var remaining=maxf(0,s.task_duration(w)-float(m["elapsed"]))+w["path"].size()/2.2
  var until=clock+remaining*s.SHOP_HOURS_PER_SECOND
  worker_free[w["id"]]=until;station_free[task["machine"]]=until
  worker_pos[w["id"]]=s.service(task["machine"])
 var indexes=s.active_orders()
 # Inquiries are assessed after work already promised, regardless of their due date.
 indexes.sort_custom(func(a,b):
  var ai=s.order(a)["stage"]=="intake";var bi=s.order(b)["stage"]=="intake"
  if ai!=bi: return not ai
  var ao=s.order(int(s.order(a).get("batch_leader",a))) if s.order(a)["stage"]=="batch_wait" else s.order(a)
  var bo=s.order(int(s.order(b).get("batch_leader",b))) if s.order(b)["stage"]=="batch_wait" else s.order(b)
  var ap=int(ao.get("priority",0));var bp=int(bo.get("priority",0))
  if ap!=bp: return ap<bp
  if float(ao["due"])!=float(bo["due"]): return float(ao["due"])<float(bo["due"])
  return a==int(s.order(b).get("batch_leader",-1)) if ao["id"]==bo["id"] else a<b)
 for i in indexes:
  var o=s.order(i)
  if o["stage"]=="intake" and not include_inquiries: continue
  var p=planned(o);var required=inputs(o);var missing={};var reasons=[];var input_at=clock
  var incoming_used={}
  for key in required:
   var need=int(required[key]);reserved[key]=int(reserved.get(key,0))+need
   if int(inventory.get(key,0))<need:
    # Delayed purchases are a finite shared resource, never counted twice.
    var events=s.state["deliveries"].duplicate(true)
    events.sort_custom(func(a,b):return float(a["eta"])<float(b["eta"]))
    var available=int(inventory.get(key,0))
    for d in events:
     available+=int(d["items"].get(key,0))
     if available>=need:
      input_at=maxf(input_at,float(d["eta"]));break
    if available<need:
     missing[key]=need-available
   inventory[key]=int(inventory.get(key,0))-need
  # Track delivery reservation across earlier rows using negative on-hand quantities.
  if not missing.is_empty(): reasons.append("Needs supplies: "+s.missing_all(missing))
  if p["type"] in ["transfer","apparel"] and p["gang"].is_empty(): reasons.append("Artwork does not fit the selected sheet")
  if not o.get("artwork_offer",{}).is_empty():reasons.append("Artwork change awaiting agreement")
  if o["stage"]=="fault": reasons.append("Choose reprint or reduced-quality payment")
  if o["stage"] in ["intake","preflight","revision","plan"]: reasons.append("Needs player approval")
  var finish=input_at;var operator_name="";var station_name=""
  var steps=route(o)
  if o["stage"]=="batch_wait" and batch_release.has(int(o["batch_leader"])):
   finish=maxf(finish,float(batch_release[int(o["batch_leader"])]))
   steps=steps.slice(1)
  for requested in steps:
   var target=requested
   if target=="handoff": target="dock" if o["fulfillment"]=="ship" and int(s.state["location"])==2 else "pack"
   var candidates=[target]
   if target=="dtf" and s.state["machines"].has("dtf2"): candidates.append("dtf2")
   var best={};var best_end=INF
   for id in candidates:
    if not s.state["machines"].has(id): continue
    var m=s.state["machines"][id]
    if m.get("broken",false):reasons.append("Service required: "+id);continue
    if m.has("service_work"):station_free[id]=maxf(float(station_free.get(id,clock)),clock+(float(m["service_work"]["remaining"])+8.0)*s.SHOP_HOURS_PER_SECOND)
    for w in s.state["workers"]:
     if int(w.get("absent_until_day",0))>int(s.state["day"]):continue
     var assignment=m["worker"]
     if assignment!=w["id"] and (assignment!="auto" or not s.role_matches(w,id)): continue
     var own_task=w["task"]
     var is_current=not own_task.is_empty() and int(own_task["order"])==i and own_task["machine"]==id
     var duration=0.0
     for phase in C.phases("deliver" if requested=="handoff" else m["kind"],p): duration+=float(phase[1])
     if m["kind"]=="dtf" and s.state["upgrades"]["auto_feeder"]: duration*=0.7
     if s.state.has("operations") and m["condition"]<65:duration*=1.15
     if o.get("intervention_bonus",false):duration*=.95
     duration/=maxf(.1,float(w["skill"]))
     if m["kind"]=="dtf" and o.has("batch_members"):
      var count=0
      for member in o["batch_members"]: count+=int(s.order(int(member))["quantity"])
      duration*=maxf(1,float(count)/float(o["quantity"]))
     if is_current and own_task.get("working",false): duration=maxf(0,s.task_duration(w)-float(m["elapsed"]))
     # Actual grid path to this station provides a disclosed travel allowance.
     var start_pos=worker_pos[w["id"]]
     var walk=s.path(start_pos,s.service(id))
     if start_pos!=s.service(id) and walk.is_empty(): continue
     var distance=walk.size()
     var start=maxf(finish,maxf(float(station_free.get(id,clock)),float(worker_free[w["id"]])))
     if is_current: start=finish
     var end=start+(duration+distance/2.2)*s.SHOP_HOURS_PER_SECOND
     if end<best_end: best_end=end;best={"machine":id,"worker":w["id"],"name":w["name"]}
   if best.is_empty(): reasons.append("Needs station / available qualified operator: "+target);finish=INF;break
   finish=best_end;station_free[best["machine"]]=finish;worker_free[best["worker"]]=finish
   worker_pos[best["worker"]]=s.service(best["machine"])
   if requested=="dtf" and o.has("batch_members"): batch_release[i]=finish
   if station_name=="": station_name=best["machine"];operator_name=best["name"]
  var blocked=not missing.is_empty() or not is_finite(finish) or o["stage"]=="fault"
  var cost=0.0
  for key in required: cost+=required[key]*(4.0 if key.begins_with("garment:") else float(C.PRICES.get(key,0)))
  var payout=roundi(o["reward"]*(.76 if o.get("quality_accepted",false) else 1))
  rows.append({"index":i,"id":o["id"],"required":required,"missing":missing,"reasons":reasons,"finish":-1.0 if blocked else finish,"risk":"BLOCKED" if blocked else ("OVERDUE" if clock>float(o["due"]) else ("AT RISK" if finish>float(o["due"]) else "ON TRACK")),"operator":operator_name,"station":station_name,"remaining_cost":cost,"payout":payout,"margin":payout-float(o["material_cost"])-cost,"assumptions":"Estimate assumes prompt approvals, uninterrupted operators and normal quality; customer return can add time."})
 var wages=0.0
 for w in s.state["workers"]: wages+=float(w["wage"])
 var overhead=roundi((125 if int(s.state["location"])==1 else 200)*float(s.state["rules"]["overhead"]))
 var loan=mini(50,int(s.state.get("loan_remaining",0)))
 var receipts=0
 for row in rows:
  if row["finish"]>=0 and row["finish"]<=clock+17-float(s.state["clock"]): receipts+=row["payout"]
 loan+=preload("res://scripts/shop_operations.gd").daily_debt(s)
 overhead+=75 if s.state.get("production_annex",false) else 0
 return {"rows":rows,"required":reserved,"on_hand":original,"wages":wages,"overhead":overhead,"loan_payment":loan,"obligations":wages+overhead+loan,"receipts":receipts,"cash_after_bills":float(s.state["cash"])-wages-overhead-loan,"cash_if_collected":float(s.state["cash"])-wages-overhead-loan+receipts}

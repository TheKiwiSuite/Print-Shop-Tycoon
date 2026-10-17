extends RefCounted
# Authored game systems. No real-world equipment economics or credit advice.
const C=preload("res://scripts/catalog.gd")
const SERVICE={"dtf":"Nozzle check / capping / feed cleanup","shaker":"Powder cleanup / cure check","sticker":"Roller clean / registration calibration","heat":"Platen and pad inspection","banner":"Feed and printhead check","cnc":"Bed and tool inspection"}
const CONFIG_VERSION=1
static func ensure(s) -> void:
 if not s.state.get("operations") is Dictionary:
  s.state["operations"]={"version":CONFIG_VERSION,"seed":int((str(s.state["day"])+str(s.state["cash"])+"workshop").hash()),"away":false,"offline_enabled":false,"offline_anchor":0,"offline_cap":900,"spending_cap":100,"spent":0,"service_spent":0,"service_cap":24,"close_walkins":true,"auto_service":false,"repeat_allowed":false,"min_margin":50,"qte_enabled":true,"assist":true,"event_enabled":true,"event_day":int(s.state["day"]),"event":{},"event_history":[],"qtes":{},"qte_day":0,"qte_count":0,"active_qte":{},"debts":[],"finance_intent":"","promo_day":0,"return_report":{},"settlement_seq":0,"closing_service":false}
 s.state["schema"]=maxi(5,int(s.state.get("schema",3)))
 for m in s.state["machines"].values():
  if not m.has("last_service_day"):m["last_service_day"]=int(s.state["day"])
  if not m.has("service_uses"):m["service_uses"]=0
static func daily_debt(s) -> int:
 var total=0
 for debt in s.state.get("operations",{}).get("debts",[]):total+=mini(int(debt["daily"]),int(debt["remaining"]))
 return total
static func equipment_cost(s,id:String) -> int:
 return ceili(C.EQUIPMENT_PRICES[id]*.2) if s.state.get("operations",{}).get("finance_intent","")==id else int(C.EQUIPMENT_PRICES[id])
static func finance(s,id:String) -> bool:
 ensure(s)
 if id not in ["dtf","sticker","heat","banner","cnc","dock"] or s.state["machines"].has(id):return false
 var price=int(C.EQUIPMENT_PRICES[id]);var deposit=ceili(price*.2)
 var payment=ceili((price-deposit+ceili(price*.1))/10.0)
 if s.state["cash"]<deposit+s.daily_obligations()+payment:s.notice("Deposit and the next daily bill buffer are required.");return false
 if s.state["operations"]["debts"].filter(func(d):return d["remaining"]>0).size()>=2:s.notice("At most two equipment agreements can be active.");return false
 s.state["operations"]["finance_intent"]=id
 s.notice("Financing selected: $%d deposit, then up to 10 daily payments of $%d. Fixed game fee $%d. No charge until valid placement." % [deposit,payment,ceili(price*.1)])
 return true
static func commit_equipment(s,id:String) -> void:
 if not s.state.has("operations"):return
 var ops=s.state["operations"]
 if ops["finance_intent"]==id:
  var price=int(C.EQUIPMENT_PRICES[id]);var principal=price-ceili(price*.2);var fee=ceili(price*.1)
  ops["debts"].append({"id":"finance-"+id+"-"+str(s.state["day"]),"equipment":id,"remaining":principal+fee,"principal":principal,"fee":fee,"daily":ceili((principal+fee)/10.0),"last_payment_day":-1})
  ops["finance_intent"]=""
 s.state["machines"][id]["unbox_remaining"]=2.0
static func pay_debts(s,day:int) -> int:
 if not s.state.has("operations"):return 0
 var total=0
 for debt in s.state["operations"]["debts"]:
  if int(debt["last_payment_day"])==day:continue
  var amount=mini(int(debt["remaining"]),int(debt["daily"]))
  debt["remaining"]-=amount;debt["last_payment_day"]=day;total+=amount
 s.state["cash"]-=total
 return total
static func promo(s) -> bool:
 ensure(s)
 var ops=s.state["operations"]
 if ops["promo_day"]==s.state["day"] or s.state["cash"]<25 or s.active_orders().size()>=6:return false
 var kind="sticker" if s.state["machines"].has("sticker") else "transfer"
 if not s.state["machines"].has("sticker" if kind=="sticker" else "dtf"):s.notice("Install suitable printing equipment before promoting a sale.");return false
 var quantity=24 if kind=="sticker" else 8
 var o=C.make_order("PROMO-%d" % s.state["day"],kind,quantity,"Community print promotion",s.now()+6,roundi(quantity*(4.2 if kind=="sticker" else 20)*.85))
 o["promotion"]=true;o["art_ready"]=true
 s.state["orders"].append(o);s._ensure_visit(o)
 s.state["cash"]-=25;s.state["stats"]["marketing"]+=25;ops["promo_day"]=s.state["day"]
 s.notice("$25 community promotion: a discounted inquiry. Complete it well to earn normal trust plus 2; no trust is granted for spending alone.")
 return true
static func service_status(s,id:String) -> String:
 var m=s.state["machines"][id]
 if m.has("service_work"):return "Service in progress"
 if m.get("broken",false):return "Stopped: wear-related feed/tool fault"
 var days=int(s.state["day"])-int(m.get("last_service_day",s.state["day"]))
 if float(m["condition"])<65:return "Overdue / +15% production time"
 if int(m.get("service_uses",0))>=4 or (days>=2 and m.get("service_uses",0)>0):return "Routine service due"
 return "Ready / light-use daily visual check"
static func start_service(s,id:String) -> bool:
 ensure(s)
 var m=s.state["machines"].get(id,{})
 if m.is_empty() or not SERVICE.has(m["kind"]) or m.has("service_work") or int(m["active"])>=0:return false
 for w in s.state["workers"]:
  if not w["task"].is_empty() and w["task"]["machine"]==id:s.notice("Finish or safely stop the current job before service.");return false
 if int(s.state["stock"]["maintenance"])<1:s.notice("One maintenance kit ($8 stock value) is required.");return false
 var operator={}
 for w in s.state["workers"]:
  if not w["task"].is_empty() or w.has("service_job") or int(w.get("absent_until_day",0))>int(s.state["day"]):continue
  if not s.role_matches(w,id):continue
  var route=s.path(s.cell(w["pos"]),s.service(id))
  if s.cell(w["pos"])!=s.service(id) and route.is_empty():continue
  operator=w;operator["path"]=route;break
 if operator.is_empty():s.notice("A free qualified operator or Sam and clear service access are required.");return false
 var ops=s.state["operations"]
 if ops["away"] and (float(ops["spent"])+8>float(ops["spending_cap"]) or float(ops.get("service_spent",0))+8>float(ops["service_cap"])):return false
 s.state["stock"]["maintenance"]-=1;s.state["stats"]["materials"]+=8
 if ops["away"]:ops["spent"]+=8;ops["service_spent"]=float(ops.get("service_spent",0))+8
 operator["service_job"]=id
 m["service_work"]={"worker":operator["id"],"remaining":12.0,"kit_consumed":true,"day":s.state["day"]}
 m["phase"]=SERVICE[m["kind"]]
 s.notice("Service reserved: one kit, 12 work seconds plus walking. The machine is locked until completion.")
 return true
static func cosmetic(s,dt:float) -> void:
 for m in s.state["machines"].values():
  if m.get("unbox_remaining",0)>0:m["unbox_remaining"]=maxf(0,float(m["unbox_remaining"])-dt)
static func tick(s,dt:float) -> void:
 if not s.state.has("operations"):return
 var ops=s.state["operations"]
 for id in s.state["machines"]:
  var m=s.state["machines"][id]
  if m.has("service_work"):
   var job=m["service_work"];var w=s.worker(job["worker"])
   if w.is_empty():continue
   if not w["path"].is_empty() or s.cell(w["pos"])!=s.service(id):continue
   job["remaining"]=maxf(0,float(job["remaining"])-dt*float(w["skill"]))
   if job["remaining"]<=0:
    m["condition"]=100;m["last_service_day"]=s.state["day"];m["service_uses"]=0;m["broken"]=false;m["phase"]="Service complete";m.erase("service_work");w.erase("service_job")
    if m["kind"]=="dtf":
     var shaker=s.state["machines"].get("shaker2" if id=="dtf2" else "shaker",{})
     if not shaker.is_empty():shaker["condition"]=100;shaker["last_service_day"]=s.state["day"]
  elif not m.get("broken",false) and m.get("service_uses",0)>=8 and m["condition"]<=40 and int(s.state["day"])-int(m.get("last_service_day",s.state["day"]))>=3 and int(m["active"])<0:
   m["broken"]=true;m["phase"]="Stopped: neglected service"
   s.notice("%s stopped after sustained wear and missed service. One kit and a qualified service task can recover it." % m["title"])
  if ops["away"] and ops["auto_service"] and not m.has("service_work") and SERVICE.has(m["kind"]) and (m.get("broken",false) or m["condition"]<65):start_service(s,id)
 if ops["event_enabled"] and int(s.state["day"])>=3 and ops["event_day"]<s.state["day"] and ops["event"].is_empty() and float(s.state["clock"])>=10:
  var selection=absi(int(ops["seed"])+int(s.state["day"])*17)%4
  var types=["supplier","artwork","absence","opportunity"]
  ops["event"]={"id":"event-%d" % s.state["day"],"kind":types[selection],"resolved":false};ops["event_day"]=s.state["day"]
  s.notice("A shop decision is waiting in Operations. No accepted deadline or cash has changed.")
 if ops["away"]:
  var pending=false
  for i in s.active_orders():
   if s.order(i)["stage"] in ["preflight","plan","fault"]:pending=true
  if not ops["event"].is_empty():pending=true
  if pending:s.state["paused"]=true;ops["return_report"]={"reason":"Decision / artwork / quality approval needs the manager. No reaction penalty was applied.","spent":ops["spent"]}
static func resolve_event(s,choice:String) -> bool:
 ensure(s)
 var ops=s.state["operations"];var event=ops["event"]
 if event.is_empty() or event.get("resolved",false):return false
 if choice=="expedite":
  if event["kind"]!="supplier" or s.state["cash"]<25:return false
  s.state["cash"]-=25;s.state["stats"]["hurdles"]=s.state["stats"].get("hurdles",0)+25
 elif choice=="delay":
  if event["kind"]!="supplier":return false
  for d in s.state["deliveries"]:d["eta"]+=.25
 elif choice=="opportunity":
  if s.active_orders().size()>=6:return false
  var type="sticker" if s.state["machines"].has("sticker") else "transfer"
  if int(s.state["location"])==2 and s.state.get("fit_out",false):type="banner" if not s.state["machines"].has("banner") else "cnc"
  if type in ["sticker","transfer"] and not s.state["machines"].has("sticker" if type=="sticker" else "dtf"):return false
  var quantity=2 if type in ["banner","cnc"] else 20
  var reward={"sticker":200,"transfer":600,"banner":1400,"cnc":1800}[type]
  var o=C.make_order("OPP-"+event["id"],type,quantity,"Rare local event commission",s.now()+7,reward);o["art_ready"]=true;o["opportunity"]=true
  s.state["orders"].append(o);s._ensure_visit(o)
 elif choice=="cover":
  if event["kind"]!="absence" or s.state["cash"]<45:return false
  s.state["cash"]-=45;s.state["stats"]["hurdles"]=s.state["stats"].get("hurdles",0)+45
 elif choice=="absence":
  if event["kind"]!="absence":return false
  for w in s.state["workers"]:
   if w["id"]!="owner" and w["task"].is_empty() and not w.has("service_job"):w["absent_until_day"]=int(s.state["day"])+1;break
 elif choice!="keep":return false
 event["resolved"]=true;event["choice"]=choice;ops["event_history"].append(event.duplicate(true));ops["event"]={}
 s.save_game();s.notice("Shop decision recorded. Existing accepted terms remain fixed.");return true
static func begin_qte(s,index:int,kind:String) -> bool:
 ensure(s)
 var ops=s.state["operations"];var o=s.order(index)
 if o.is_empty() or not ops["qte_enabled"] or ops["away"] or not ops["active_qte"].is_empty():return false
 if kind not in ["registration","press","jam"]:return false
 if kind=="registration" and (o["type"]!="sticker" or o["stage"] not in ["plan","queued"]):return false
 if kind=="press" and (o["type"]!="apparel" or o["stage"]!="press"):return false
 if kind=="jam" and not s.state["machines"].get(s.machine_for(o),{}).get("broken",false):return false
 var id=o["id"]+":"+kind
 if ops["qtes"].has(id):return false
 if ops["qte_day"]!=s.state["day"]:ops["qte_day"]=s.state["day"];ops["qte_count"]=0
 if ops["qte_count"]>=2:return false
 ops["active_qte"]={"id":id,"order":index,"kind":kind,"elapsed":0.0,"step":0,"practice":ops["qtes"].is_empty(),"resume_paused":s.state["paused"]};return true
static func qte_result(s,automatic:bool=false) -> bool:
 var ops=s.state["operations"];var q=ops["active_qte"]
 if q.is_empty() or ops["qtes"].has(q["id"]):return false
 var marker=fmod(float(q["elapsed"]),2.0)/2.0
 var success=not automatic and (ops["assist"] or q["practice"] or (marker>=.25 and marker<=.75))
 if q["kind"]=="jam" and success:
  if q["step"]<2:q["step"]+=1;return false
  var m=s.state["machines"][q["machine"] if q.has("machine") else s.machine_for(s.order(q["order"]))]
  if s.state["stock"]["maintenance"]<1:return false
  s.state["stock"]["maintenance"]-=1;s.state["stats"]["materials"]+=8;m["broken"]=false;m["condition"]=maxf(70,m["condition"]);m["service_uses"]=0;m["last_service_day"]=s.state["day"]
 if success and int(q["order"])>=0:s.order(q["order"])["intervention_bonus"]=true
 ops["qtes"][q["id"]]={"success":success,"automatic":automatic,"day":s.state["day"]};ops["qte_count"]+=1;ops["active_qte"]={}
 s.save_game();s.notice(("Jam cleared using one kit; station recovered to at least 70%." if q["kind"]=="jam" else "Intervention saved: 5% task-time benefit.") if success else "Ordinary automatic production retained. No missed-reaction penalty.");return true
static func away(s,on:bool) -> bool:
 ensure(s)
 var ops=s.state["operations"]
 var previous=s.state.duplicate(true)
 if on:
  for w in s.state["workers"]:
   if w["id"]=="owner":w["manual"]=false
  if not ops["active_qte"].is_empty():qte_result(s,true)
  ops["spent"]=0;ops["service_spent"]=0;ops["away"]=true;ops["return_report"]={};s.state["paused"]=false
  ops["offline_anchor"]=int(Time.get_unix_time_from_system())
 else:
  ops["away"]=false;s.state["paused"]=true
  ops["return_report"]={"reason":"Away shift ended. Review completed jobs, waiting pickups and unresolved work.","cash":s.state["cash"],"spent":ops["spent"]}
 if not s.save_game():s.state=previous;return false
 return true
static func settle_offline(s,wall_time:int=-1) -> bool:
 ensure(s)
 var ops=s.state["operations"]
 if not ops["offline_enabled"] or not ops["away"]:return false
 var current=int(Time.get_unix_time_from_system()) if wall_time<0 else wall_time
 var elapsed=clampi(current-int(ops["offline_anchor"]),0,int(ops["offline_cap"]))
 if ops["offline_anchor"]<=0 or elapsed<1:return false
 var original=s.state.duplicate(true);var enabled=s.save_enabled;var cash=float(s.state["cash"]);var done=int(s.state["completed"]);var speed=s.state["speed"]
 s.save_enabled=false;s.state["speed"]=1;s.state["paused"]=false
 var simulated=0.0
 while simulated<float(elapsed) and not s.state["paused"]:
  s.tick(.1);cosmetic(s,.1);simulated+=.1
 s.state["speed"]=speed;s.state["paused"]=true;s.save_enabled=enabled
 ops=s.state["operations"];ops["offline_anchor"]=current;ops["settlement_seq"]+=1
 ops["return_report"]={"reason":"Offline work settled once; 1 real second = 0.009 shop hours, always 1x. Stops at closing or a manager decision.","seconds":snappedf(simulated,.1),"cap":ops["offline_cap"],"jobs":int(s.state["completed"])-done,"cash_change":float(s.state["cash"])-cash,"spent":ops["spent"],"sequence":ops["settlement_seq"]}
 if not s.save_game():s.state=original;return false
 return true

static func annex(s) -> bool:
 if int(s.state["location"])!=2 or not s.state.get("fit_out",false) or s.state.get("production_annex",false):return false
 if int(s.state["completed"])<10 or int(s.state["reputation"])<80 or float(s.state["cash"])<2200+s.daily_obligations()+75:s.notice("Annex requires fit-out, 10 paid jobs, 80 trust and $2,200 plus the next daily bills including $75 extra rent.");return false
 s.state["production_annex"]=true;s.state["cash"]-=2200;s.state["stats"]["capex"]=s.state["stats"].get("capex",0)+2200
 s.notice("Production annex added: 22 x 16 floor, retained equipment, $75 extra daily overhead. Arrange separate production and display zones.");s.save_game();return true

static func begin_jam(s,id:String) -> bool:
 ensure(s)
 var ops=s.state["operations"];var m=s.state["machines"].get(id,{})
 if not m.get("broken",false) or m.has("service_work") or m.get("active",-1)>=0 or s.state["stock"]["maintenance"]<1 or not ops["qte_enabled"] or ops["away"] or not ops["active_qte"].is_empty():return false
 if ops["qte_day"]!=s.state["day"]:ops["qte_day"]=s.state["day"];ops["qte_count"]=0
 var key="jam-"+id+"-"+str(s.state["day"])
 if ops["qte_count"]>=2 or ops["qtes"].has(key):return false
 ops["active_qte"]={"id":key,"order":-1,"machine":id,"kind":"jam","elapsed":0.0,"step":0,"practice":ops["qtes"].is_empty(),"resume_paused":s.state["paused"]};return true

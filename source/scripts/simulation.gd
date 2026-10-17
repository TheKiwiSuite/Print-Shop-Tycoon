extends RefCounted

const C = preload("res://scripts/catalog.gd")
const Marketing = preload("res://scripts/marketing.gd")
const Strategy = preload("res://scripts/shop_strategy.gd")
const SHOP_HOURS_PER_SECOND=0.009
const SAVE = "user://native-shop-v3.json"
var save_path=SAVE
var state:Dictionary = C.empty_shop()
var save_enabled = true
var manual_input = Vector2.ZERO
var last_save_error = ""

func start_shop(preset:String="Standard",custom:Dictionary={}) -> void:
 state=C.empty_shop()
 state["rules"]=Strategy.rules(preset,custom)
 state["schema"]=4
 state["cash"]=roundi(Strategy.BASE_CASH*state["rules"]["cash"])
 state["day_open_cash"]=state["cash"]
 Strategy.ensure(self)
 notice("%s shop. Starting cash $%d. Forecast commitments before accepting work." % [state["rules"]["preset"],state["cash"]])

func change_rules(preset:String,custom:Dictionary={}) -> bool:
 if not state["paused"]: notice("Pause the shop before changing difficulty.");return false
 Strategy.ensure(self)
 var next=Strategy.rules(preset,custom)
 state["rule_history"].append({"at":now(),"before":state["rules"].duplicate(true),"after":next.duplicate(true)})
 state["rules"]=next
 state["schema"]=4
 notice("Rules changed for future commitments and purchases. Accepted terms, stock, cash and fault rolls are retained.")
 save_game()
 return true

func capacity_board(include_inquiries:bool=false) -> Dictionary:
 return Strategy.board(self,include_inquiries)

func missing_all(items:Dictionary) -> String:
 var parts=[]
 for key in items: parts.append("%s %d" % [key,int(items[key])])
 return ", ".join(parts)

func daily_obligations(extra_wage:int=0) -> float:
 Strategy.ensure(self)
 var bills=roundi((125 if int(state["location"])==1 else 200)*float(state["rules"]["overhead"]))+extra_wage+mini(50,int(state.get("loan_remaining",0)))
 for w in state["workers"]: bills+=int(w["wage"])
 return bills

func hiring_buffer(role_index:int) -> bool:
 Strategy.ensure(self)
 return int(state["rules"]["version"])==0 or float(state["cash"])-C.HIRE_COST[role_index]>=daily_obligations(45)

func reprint_cost(o:Dictionary) -> float:
 var p=Strategy.planned(o)
 p["settings"]["white"]="standard";p["settings"]["registration"]=true
 var cost=float(C.PRICES["maintenance"])
 var recipe=C.recipe(p)
 for key in recipe: cost+=float(recipe[key])*C.PRICES[key]
 if o["type"]=="apparel": cost+=int(o["quantity"])*4
 return cost

func preset_feedback(o:Dictionary) -> Dictionary:
 var p=Strategy.planned(o);var recipe=C.recipe(p);var cost=0.0;var seconds=0.0
 for key in recipe: cost+=float(recipe[key])*C.PRICES[key]
 var kind={"transfer":"dtf","apparel":"dtf","sticker":"sticker","banner":"banner","cnc":"cnc"}[o["type"]]
 for phase in C.phases(kind,p): seconds+=float(phase[1])
 var risks=[]
 if kind=="dtf" and p["settings"]["white"]=="economy": risks.append("Economy white causes low-opacity recovery")
 if kind=="sticker" and not p["settings"]["registration"]: risks.append("Skipped marks cause registration recovery")
 if o["type"]=="apparel" and p["settings"]["press"]!="cotton_warm": risks.append("Cotton blanks require warm peel")
 var note="Print inputs $%.1f / base machine work %.1f shop min. Pressing, handling and packing are additional." % [cost,seconds*SHOP_HOURS_PER_SECOND*60]
 if not risks.is_empty(): note+=" "+"; ".join(risks)+"."
 return {"text":note,"warning":not risks.is_empty()}

func quote(i:int,rush:bool=false,board_snapshot:Dictionary={}) -> Dictionary:
 Strategy.ensure(self)
 var o=order(i)
 if o.is_empty(): return {"valid":false,"reason":"Choose an order."}
 var row={}
 var board=capacity_board(true) if board_snapshot.is_empty() else board_snapshot
 for candidate in board["rows"]:
  if candidate["index"]==i: row=candidate;break
 if row.is_empty(): return {"valid":false,"reason":"No live quote for this order."}
 var legacy=int(state["rules"]["version"])==0
 var finish=float(row["finish"])
 var due=now()+(1.8 if rush else 6.5)*float(state["rules"]["slack"])
 if not legacy and finish>=0: due=maxf(due,finish+(.5 if rush else 2.0)*float(state["rules"]["slack"]))
 var valid=legacy or finish>=0
 var reason="Resolve supplies and station/operator blockers before quoting." if not valid else row["assumptions"]
 if rush and not legacy:
  for other in state["orders"]:
   if other.get("rush",false) and int(other.get("accepted_day",-1))==int(state["day"]):
    valid=false;reason="One rush premium per shop day. Review the normal quote instead.";break
 return {"valid":valid,"reason":reason,"due":due,"finish":finish,"payout":roundi(o["reward"]*(1.3 if rush else 1.0)),"cost":row["remaining_cost"],"missing":row["missing"],"risk":"BLOCKED" if finish<0 else ("AT RISK" if finish>due else "ON TRACK")}

func select_specialty(name:String) -> bool:
 if not Strategy.SPECIALTIES.has(name): return false
 Strategy.ensure(self)
 state["specialty"]=name
 notice(name+" focus selected. Future daily inquiries favor its installed routes; prices on accepted work stay fixed.")
 return true

func repeat_order(i:int) -> bool:
 var original=order(i)
 if original.is_empty() or original["stage"]!="completed": return false
 if active_orders().size()>=6: notice("Clear an inquiry slot before requesting a repeat.");return false
 var price=int(original.get("base_reward",roundi(original["reward"]/(1.3 if original.get("rush",false) else 1.0))))
 var next=C.make_order("REPEAT-%d" % state["orders"].size(),original["type"],int(original["quantity"]),original["customer"],now()+6.5,price)
 for key in ["settings","gang","film_width","sheet_length","art_w","art_h"]: next[key]=original[key].duplicate(true) if original[key] is Array or original[key] is Dictionary else original[key]
 next["art_ready"]=true;next["returning"]=true;next["source_order"]=original["id"]
 state["orders"].append(next);_ensure_visit(next)
 notice("Repeat inquiry created with approved artwork and preset. Review the new quote before accepting.")
 return true

func recovery_shift() -> bool:
 if not state["paused"] or float(state["clock"])>15 or not state["report"].is_empty(): return false
 if not owner()["task"].is_empty(): notice("Finish Sam's current job first.");return false
 var target=float(state["clock"])+2.0
 var speed=state["speed"];var manual=owner()["manual"]
 state["cash"]+=100
 state["stats"]["recovery"]=state["stats"].get("recovery",0)+100
 state["paused"]=false;state["speed"]=4;owner()["manual"]=true
 # Staff, supplier arrivals, accepted deadlines and inquiry patience keep running.
 while float(state["clock"])<target-.0000001 and not state["paused"]:
  tick(minf(.1,(target-float(state["clock"]))/float(SHOP_HOURS_PER_SECOND*4)))
 state["clock"]=target;state["speed"]=speed;owner()["manual"]=manual;state["paused"]=true
 notice("Recovery shift earned $100 and used two shop hours. Existing deadlines keep running.")
 return true

func rescue_loan() -> bool:
 Strategy.ensure(self)
 if state["rules"]["preset"]!="Relaxed" or state["rescue_used"]: return false
 state["cash"]+=400;state["rescue_used"]=true;state["loan_remaining"]=400
 state["stats"]["loan_in"]=state["stats"].get("loan_in",0)+400
 notice("Optional $400 interest-free rescue loan. $50 is repaid at each day close until cleared.")
 return true

func expand_premises() -> bool:
 if int(state["location"])==2 or not garage_progress()["ready"]: return false
 for w in state["workers"]:
  if not w["task"].is_empty(): notice("Finish active work before moving.");return false
 # The larger room contains the old room: retain every equipment transform.
 state["cash"]-=900;state["location"]=2;state["fit_out"]=false
 state["stats"]["capex"]=state["stats"].get("capex",0)+900
 _reroute_customers()
 notice("Larger premises purchased for $900. Existing equipment and layout retained. Fit-out and new machines are separate investments.")
 save_game();return true

func fit_out() -> bool:
 Strategy.ensure(self)
 if int(state["location"])!=2 or state["fit_out"] or state["cash"]<350: return false
 state["cash"]-=350;state["fit_out"]=true
 state["stats"]["capex"]=state["stats"].get("capex",0)+350
 notice("Industrial fit-out complete. Banner, CNC and shipping equipment can now be purchased separately.")
 return true

func install_second_line() -> bool:
 Strategy.ensure(self)
 if int(state["location"])!=2 or not state["fit_out"] or state["machines"].has("dtf2") or state["cash"]<900: return false
 var previous=state["machines"]
 var candidate=previous.duplicate(true)
 var source=C.layout(2)
 candidate["dtf2"]=source["dtf2"];candidate["shaker2"]=source["shaker2"]
 state["machines"]=candidate
 for y in range(2,10):
  for x in range(3,14):
   var result=placement_feedback("dtf2",Vector2i(x,y))
   if result["valid"]:
    state["machines"]=result["machines"];state["cash"]-=900
    state["stats"]["capex"]=state["stats"].get("capex",0)+900
    notice("Second DTF line purchased for $900 and placed with clear service aisles. Use Build to adjust it.")
    save_game();return true
 state["machines"]=previous
 notice("No safe position for a second line. Rearrange equipment and keep a full line footprint clear.")
 return false

func order_recipe(o:Dictionary) -> Dictionary:
 return o.get("batch_recipe",C.recipe(o))

func dispatch_recipe(o:Dictionary) -> Dictionary:
 var total={}
 for i in o.get("batch_members",[]):
  var member=order(int(i))
  if member.get("consumed",false): continue
  for key in member["recipe"]: total[key]=int(total.get(key,0))+int(member["recipe"][key])
 return total if o.has("batch_members") else o["recipe"]

func batch_preview(i:int) -> Dictionary:
 var base=order(i);var members=[]
 if base.is_empty() or base["type"] not in ["transfer","apparel"]: return {"valid":false,"reason":"Select a planned DTF job."}
 for j in active_orders():
  var o=order(j)
  if o["type"] not in ["transfer","apparel"] or o["stage"] not in ["plan","queued"] or o["consumed"] or o.has("batch_leader"): continue
  if o["film_width"]!=base["film_width"] or o["sheet_length"]!=base["sheet_length"] or o["settings"]["white"]!=base["settings"]["white"] or not o["art_ready"]: continue
  var busy=false
  for w in state["workers"]:
   if not w["task"].is_empty() and int(w["task"]["order"])==j: busy=true
  if not busy: members.append(j)
 if not members.has(i) or members.size()<2: return {"valid":false,"reason":"Need two unstarted DTF jobs with matching film, length and white preset."}
 # Deterministic shelf packing records every customer-owned design on each sheet.
 var slots=[];var sheet=0;var x=0.0;var y=0.0;var height=0.0;var old_film=0;var counts={}
 for j in members:
  var o=order(j);var p=Strategy.planned(o)
  old_film+=int(C.recipe(p)["film"]);counts[j]=int(o["quantity"])
  var w=float(o["art_w"]);var h=float(o["art_h"])
  if w>float(base["film_width"]) or h>float(base["sheet_length"]): return {"valid":false,"reason":"A design does not fit an unrotated batch sheet."}
  for n in int(o["quantity"]):
   if x+w>float(base["film_width"]): x=0;y+=height;height=0
   if y+h>float(base["sheet_length"]): sheet+=1;x=0;y=0;height=0
   slots.append({"order":o["id"],"sheet":sheet,"rect":[x,y,w,h]})
   x+=w;height=maxf(height,h)
 var film=ceili((sheet+1)*float(base["sheet_length"])/12.0)
 if film>=old_film: return {"valid":false,"reason":"This grouping saves no film. Keep individual jobs or change their layouts."}
 return {"valid":true,"members":members,"leader":i,"slots":slots,"film":film,"saved":old_film-film,"sheets":sheet+1}

func batch_orders(i:int) -> bool:
 var plan=batch_preview(i)
 if not plan["valid"]: notice(plan["reason"]);return false
 var recipes={};var total={};var remaining=int(plan["film"]);var quantity=0
 for j in plan["members"]: quantity+=int(order(j)["quantity"])
 for n in plan["members"].size():
  var j=plan["members"][n];var o=order(j)
  var recipe=C.recipe(Strategy.planned(o))
  recipe["film"]=remaining if n==plan["members"].size()-1 else floori(float(plan["film"])*float(o["quantity"])/quantity)
  remaining-=int(recipe["film"]);recipes[j]=recipe
  for key in recipe: total[key]=int(total.get(key,0))+int(recipe[key])
 if not materials_available(total): notice("Batch needs supplies: "+missing(total));return false
 for j in plan["members"]:
  var o=order(j)
  if o["gang"].is_empty(): o["gang"]=Strategy.planned(o)["gang"]
  o["batch_leader"]=i;o["batch_recipe"]=recipes[j];o["recipe"]=recipes[j]
  o["stage"]="queued" if j==i else "batch_wait"
 order(i)["batch_members"]=plan["members"];order(i)["batch_slots"]=plan["slots"]
 notice("Mixed batch queued: %d jobs, %d sheets, %d ft film saved. Each customer's output and payment stay separate." % [plan["members"].size(),plan["sheets"],plan["saved"]])
 return true

func notice(text:String) -> void:
 state["notices"].push_front(text)
 while state["notices"].size()>6: state["notices"].pop_back()

func now() -> float:
 return (int(state["day"])-1)*9.0 + float(state["clock"])-8.0

func bounds() -> Vector2i:
 return Vector2i(14,12) if state["location"] == 1 else Vector2i(18,14)

func entrance() -> Vector2i:
 return Vector2i(0,9) if state["location"] == 1 else Vector2i(0,11)

func room_props() -> Array:
 if state.get("empty_start",false): return []
 var size=bounds()
 return [
  {"kind":"rack","pos":Vector2i(4,0)},
  {"kind":"rack","pos":Vector2i(7,0)},
  {"kind":"rack","pos":Vector2i(11,0)},
  {"kind":"plant","pos":Vector2i(0,2)},
  {"kind":"plant","pos":Vector2i(0,6)},
  {"kind":"plant","pos":Vector2i(size.x-1,size.y-2)},
  {"kind":"plant","pos":Vector2i(size.x-1,4)}
 ]

func v(p:Array) -> Vector2:
 return Vector2(float(p[0]),float(p[1]))

func cell(p:Array) -> Vector2i:
 return Vector2i(int(p[0]),int(p[1]))

func order(i:int) -> Dictionary:
 return state["orders"][i] if i>=0 and i<state["orders"].size() else {}

func worker(id:String) -> Dictionary:
 for w in state["workers"]:
  if w["id"] == id: return w
 return {}

func owner() -> Dictionary:
 return worker("owner")

func _ensure_visit(o:Dictionary) -> void:
 if not o.has("paid"): o["paid"]=o["stage"]=="completed"
 if not o.has("payment"): o["payment"]=roundi(o["reward"]*(0.76 if o.get("quality_accepted",false) else 1.0)) if o["paid"] else 0
 if not o.has("satisfaction"): o["satisfaction"]=int(o.get("quality",100)) if o["paid"] else -1
 if not o.get("visit") is Dictionary:
  var status="production"
  match o["stage"]:
   "intake": status="inquiry"
   "scheduled": status="scheduled"
   "ready","delivering": status="pickup"
   "completed": status="served"
   "declined": status="withdrawn"
   "abandoned": status="left"
  o["visit"]={"status":status,"arrival_at":now(),"arrived_at":now(),"patience_until":-1.0,"settled_at":o.get("finished_at",-1.0),"satisfaction":o["satisfaction"]}
 if o["stage"]=="completed": o["paid"]=true;o["visit"]["status"]="served"

func customer_status(o:Dictionary) -> String:
 _ensure_visit(o)
 var actor=o["visit"].get("actor",{})
 if actor.get("phase","")=="entering" and actor.get("purpose","") in ["inquiry","pickup"]:
  return "Customer walking in" if actor["purpose"]=="inquiry" else "Customer returning for pickup"
 return {"scheduled":"Expected customer","inquiry":"Customer awaiting acceptance","production":"Customer order in production","pickup":"Ready for customer pickup" if o["fulfillment"]=="pickup" else "Ready for dispatch","served":"Customer served","withdrawn":"Inquiry declined","left":"Customer left before acceptance"}.get(o["visit"]["status"],"Customer order")

func customer_patience(o:Dictionary) -> float:
 _ensure_visit(o)
 var until=float(o["visit"].get("patience_until",-1.0))
 return maxf(0.0,until-now()) if o["visit"]["status"]=="inquiry" and until>=0 else -1.0

func _ensure_marketing() -> void:
 if not state.get("marketing") is Dictionary: state["marketing"]=Marketing.defaults()
 if not state["stats"].has("marketing"): state["stats"]["marketing"]=0

func marketing_feedback(id:String) -> Dictionary:
 _ensure_marketing()
 if not Marketing.CAMPAIGNS.has(id): return {"valid":false,"reason":"Unknown campaign."}
 var offer=Marketing.CAMPAIGNS[id]
 var types=Marketing.supported(state["machines"])
 if types.is_empty(): return {"valid":false,"reason":"Place a printer before promoting your shop."}
 for bench in ["finish","pack"]:
  if not state["machines"].has(bench): return {"valid":false,"reason":"Add the included inspection and pickup benches first."}
 if not state["report"].is_empty(): return {"valid":false,"reason":"Start the next shop day before launching a campaign."}
 if state["cash"]<offer["cost"]: return {"valid":false,"reason":"This campaign needs $%d." % offer["cost"]}
 var count=_lead_count(types)
 if count+offer["leads"]>6: return {"valid":false,"reason":"Finish or decline some inquiries first. Your shop can commit to 6 leads at a time."}
 if now()<float(state["marketing"]["cooldown_until"]): return {"valid":false,"reason":"Next campaign in %d shop minutes." % ceili((float(state["marketing"]["cooldown_until"])-now())*60)}
 var today=0
 for campaign in state["marketing"]["history"]:
  if campaign["day"]==state["day"]: today+=1
 if today>=3: return {"valid":false,"reason":"Three campaigns per day. Serve your current leads or return tomorrow."}
 return {"valid":true,"reason":"First inquiry in %d shop minutes after the clock resumes." % roundi(offer["delay"]*60),"types":types,"cost":offer["cost"],"leads":offer["leads"]}

func _lead_count(types:Array) -> int:
 var count=0
 for o in state["orders"]:
  if o["stage"] in ["completed","declined","abandoned"]: continue
  var starter_adapts=o["id"]=="DTF-001" and "sticker" in types and not state["machines"].has("dtf")
  if o["stage"]!="scheduled" or o["type"] in types or starter_adapts: count+=1
 return count

func start_campaign(id:String) -> bool:
 var feedback=marketing_feedback(id)
 if not feedback["valid"]: notice(feedback["reason"]);return false
 var campaign=Marketing.CAMPAIGNS[id]
 var number=int(state["marketing"]["next_id"])
 var ids=[]
 for n in campaign["leads"]:
  var type=feedback["types"][(number-1+n)%feedback["types"].size()]
  var job=Marketing.JOBS[type]
  var customer=C.CUSTOMERS[(number*3+n)%C.CUSTOMERS.size()]
  var arrival=now()+campaign["delay"]+n*0.75
  var o=C.make_order("MKT-%d-%d" % [number,n],type,job["quantity"],customer,arrival+6.5,job["reward"])
  o["stage"]="scheduled";o["campaign"]=number
  o["paid"]=false;o["payment"]=0;o["satisfaction"]=-1
  o["visit"]={"status":"scheduled","arrival_at":arrival,"arrived_at":-1.0,"patience_until":-1.0,"settled_at":-1.0,"satisfaction":-1}
  state["orders"].append(o);ids.append(o["id"])
 state["cash"]-=campaign["cost"]
 state["stats"]["marketing"]+=campaign["cost"]
 state["marketing"]["next_id"]=number+1
 state["marketing"]["cooldown_until"]=now()+0.5
 state["marketing"]["history"].push_front({"id":number,"kind":id,"day":state["day"],"cost":campaign["cost"],"orders":ids,"launched_at":now()})
 if state["marketing"]["history"].size()>20: state["marketing"]["history"].pop_back()
 notice("%s launched for $%d. %d equipment-matched inquiries scheduled; resume the clock to receive them." % [campaign["title"],campaign["cost"],campaign["leads"]])
 save_game()
 return true

func _update_visits() -> void:
 Strategy.ensure(self)
 for i in state["orders"].size():
  var o=order(i)
  if not state.get("customer_flow",false) and not o.has("campaign"): continue
  _ensure_visit(o)
  if o["stage"]=="scheduled" and now()>=float(o["visit"]["arrival_at"]):
   # Let a sticker-only beginner receive achievable first work.
   if o["id"]=="DTF-001" and not state["machines"].has("dtf") and state["machines"].has("sticker"):
    var visit=o["visit"]
    o=C.make_order("STK-START","sticker",36,C.CUSTOMERS[0],now()+6.5,150)
    o["visit"]=visit
    state["orders"][i]=o
    state["tutorial"]=false
    _ensure_visit(o)
   var station={"transfer":"dtf","apparel":"dtf","sticker":"sticker","banner":"banner","cnc":"cnc"}[o["type"]]
   if not state["machines"].has(station): continue
   if o["type"]=="apparel" and not state["machines"].has("heat"): continue
   o["stage"]="intake"
   o["due"]=now()+6.5
   o["visit"]["status"]="inquiry"
   o["visit"]["arrived_at"]=now()
   o["visit"]["patience_until"]=now()+3.0*float(state["rules"]["patience"])
   notice("%s arrived: %d %s. Respond within %d shop minutes." % [o["customer"],o["quantity"],o["product"],roundi(180*float(state["rules"]["patience"]))])
  elif o["stage"]=="intake" and float(o["visit"].get("patience_until",-1.0))>=0 and now()>=float(o["visit"]["patience_until"]):
   o["stage"]="abandoned"
   o["visit"]["status"]="left"
   o["visit"]["settled_at"]=now()
   o["visit"]["satisfaction"]=0
   o["satisfaction"]=0
   state["reputation"]=maxi(0,int(state["reputation"])-2)
   notice(o["customer"]+" left before their inquiry was accepted. No materials or payment were taken.")

func active_orders() -> Array:
 var a = []
 for i in state["orders"].size():
  if order(i)["stage"] not in ["completed","declined","scheduled","abandoned"]: a.append(i)
 a.sort_custom(func(i,j):
  var p1=float(order(i).get("priority",0))
  var p2=float(order(j).get("priority",0))
  return float(order(i)["due"])<float(order(j)["due"]) if p1==p2 else p1<p2)
 return a

func visible_customers() -> Array:
 var visitors=[]
 for o in state["orders"]:
  var actor=o.get("visit",{}).get("actor",{})
  if not actor.is_empty() and actor["phase"]!="away": visitors.append(actor)
 return visitors

func _customer_goal(i:int,pickup:bool) -> Vector2i:
 var preferred=entrance()+Vector2i(3,i%4-2)
 if pickup and state["machines"].has("pack"): preferred=service("pack")+Vector2i(0,1)
 var solids=blocked()
 var best=entrance()
 var score=INF
 for x in bounds().x:
  for y in bounds().y:
   var point=Vector2i(x,y)
   if point==entrance() or solids.has(point): continue
   var occupied=false
   for actor in visible_customers():
    if actor["order"]!=i and cell(actor["goal"])==point: occupied=true;break
   for w in state["workers"]:
    if v(w["pos"]).distance_to(Vector2(point))<0.6: occupied=true;break
   var distance=Vector2(point).distance_squared_to(Vector2(preferred))
   if occupied or distance>=score or path(entrance(),point).is_empty(): continue
   if distance<score: best=point;score=distance
 return best

func _door_busy(except_order:int) -> bool:
 for other in visible_customers():
  if other["order"]!=except_order and v(other["pos"]).distance_to(Vector2(entrance()))<0.8: return true
 return false

func _customer_obstacles(actor:Dictionary) -> Dictionary:
 var occupied={}
 for other in visible_customers():
  if other["order"]!=actor["order"] and actor["purpose"]!="exit": occupied[Vector2i(roundi(other["pos"][0]),roundi(other["pos"][1]))]=true
 for w in state["workers"]:
  occupied[Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1]))]=true
 occupied.erase(Vector2i(roundi(actor["pos"][0]),roundi(actor["pos"][1])))
 return occupied

func _walk_customer(actor:Dictionary,dt:float) -> void:
 actor["walking"]=false
 if actor["path"].is_empty(): return
 var pos=v(actor["pos"])
 var target=v(actor["path"][0])
 var next=pos.move_toward(target,dt*2.2)
 var occupied=false
 for other in visible_customers():
  if other["order"]!=actor["order"] and actor["purpose"]!="exit" and next.distance_to(v(other["pos"]))<0.55: occupied=true;break
 if not occupied:
  for w in state["workers"]:
   if next.distance_to(v(w["pos"]))<0.55: occupied=true;break
 if occupied:
  var start=Vector2i(roundi(pos.x),roundi(pos.y))
  actor["path"]=path(start,cell(actor["goal"]),{},_customer_obstacles(actor))
  return
 _walk(actor,dt)

func _update_customer_actors(dt:float) -> void:
 for i in state["orders"].size():
  var o=order(i)
  _ensure_visit(o)
  var visit=o["visit"]
  var actor=visit.get("actor",{})
  var stage=o["stage"]
  if actor.is_empty():
   if stage not in ["intake","ready","delivering"]: continue
   var entry=entrance()
   if _door_busy(i): continue
   actor={"order":i,"name":o["customer"],"pos":[entry.x,entry.y],"goal":[entry.x,entry.y],"path":[],"purpose":"","phase":"entering","walking":false,"step":0.0,"face":1,"variant":absi(o["customer"].hash())%3}
   visit["actor"]=actor
  var purpose="exit"
  if stage=="intake": purpose="inquiry"
  elif stage in ["ready","delivering"] and o["fulfillment"]=="pickup": purpose="pickup"
  if actor["phase"]=="away" and purpose=="exit": continue
  if actor["phase"]=="away":
   if _door_busy(i): continue
   var entry=entrance();actor["pos"]=[entry.x,entry.y];actor["phase"]="entering"
  var goal=cell(actor["goal"])
  var goal_occupied=false
  if purpose!="exit" and actor["phase"]=="entering":
   for w in state["workers"]:
    if v(w["pos"]).distance_to(Vector2(goal))<0.6: goal_occupied=true;break
  if actor["purpose"]!=purpose:
   goal=entrance() if purpose=="exit" else _customer_goal(i,purpose=="pickup")
  elif goal_occupied: goal=_customer_goal(i,purpose=="pickup")
  var start=Vector2i(roundi(actor["pos"][0]),roundi(actor["pos"][1]))
  if actor["purpose"]!=purpose or cell(actor["goal"])!=goal:
   actor["purpose"]=purpose;actor["goal"]=[goal.x,goal.y]
   actor["path"]=path(start,goal,{},_customer_obstacles(actor))
   actor["phase"]="leaving" if purpose=="exit" else "entering"
  # A saved fractional position can round to the goal cell without reaching it.
  # BFS then returns an empty route; finish that last partial step explicitly.
  if actor["path"].is_empty() and start==goal and v(actor["pos"]).distance_to(Vector2(goal))>=0.05:
   actor["path"]=[[goal.x,goal.y]]
  _walk_customer(actor,dt*0.8)
  if actor["path"].is_empty():
   if v(actor["pos"]).distance_to(Vector2(goal))<0.05:
    actor["phase"]="away" if purpose=="exit" else "waiting"
   else: actor["path"]=path(start,goal,{},_customer_obstacles(actor))

func customer_ready_for_handoff(o:Dictionary) -> bool:
 if (not state.get("customer_flow",false) and not o.has("campaign")) or o["fulfillment"]!="pickup": return true
 var actor=o.get("visit",{}).get("actor",{})
 return not actor.is_empty() and actor["purpose"]=="pickup" and actor["phase"]=="waiting"

func _reroute_customers() -> void:
 for actor in visible_customers(): actor["purpose"]="";actor["path"]=[];actor["phase"]="entering";actor["walking"]=false


static func facing_of(m:Dictionary) -> int:
 return posmod(int(m.get("facing",int(m["rotation"])*4)),16)

func equipment_center(id:String,ms:Dictionary) -> Vector2:
 if ms[id]["kind"]=="shaker": id="dtf2" if id=="shaker2" else "dtf"
 var m=ms[id]
 var low=v(m["pos"])-Vector2(0.5,0.5)
 var high=low+v(m["size"])
 if m["kind"]=="dtf":
  var sh=ms["shaker2" if id=="dtf2" else "shaker"]
  var sl=v(sh["pos"])-Vector2(0.5,0.5)
  low=low.min(sl);high=high.max(sl+v(sh["size"]))
 return (low+high)*0.5+v(m.get("floor_offset",[0,0]))

func uses_rotated_footprint(id:String,ms:Dictionary) -> bool:
 if ms[id]["kind"]=="shaker":id="dtf2" if id=="shaker2" else "dtf"
 return facing_of(ms[id])%4!=0 or not v(ms[id].get("floor_offset",[0,0])).is_zero_approx()

func equipment_polygon(id:String,ms:Dictionary) -> PackedVector2Array:
 if ms[id]["kind"]=="shaker": id="dtf2" if id=="shaker2" else "dtf"
 var m=ms[id]
 var size=v(m["size"])
 if m["kind"]=="dtf": size=Vector2(3,4) if int(m["rotation"])%2==0 else Vector2(4,3)
 var center=equipment_center(id,ms)
 var polygon=PackedVector2Array()
 for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
  polygon.append(center+(corner*size*0.5).rotated(float(facing_of(m)%4)*PI/8.0))
 return polygon

func polygon_cells(polygon:PackedVector2Array) -> Array:
 var low=polygon[0];var high=polygon[0]
 for point in polygon: low=low.min(point);high=high.max(point)
 var cells=[]
 for x in range(floori(low.x),ceili(high.x)+1):
  for y in range(floori(low.y),ceili(high.y)+1):
   var tile=PackedVector2Array([Vector2(x-.499,y-.499),Vector2(x+.499,y-.499),Vector2(x+.499,y+.499),Vector2(x-.499,y+.499)])
   if not Geometry2D.intersect_polygons(polygon,tile).is_empty():cells.append(Vector2i(x,y))
 return cells

func service(id:String, machines:Dictionary={}) -> Vector2i:
 var ms = state["machines"] if machines.is_empty() else machines
 var m = ms[id]
 var goal=cell(m["pos"])+cell(m["service"])
 if not uses_rotated_footprint(id,ms): return goal
 var center=equipment_center(id,ms)
 var parent="dtf2" if id=="shaker2" else ("dtf" if id=="shaker" else id)
 var base=center-v(ms[parent].get("floor_offset",[0,0]))
 var ideal=center+(Vector2(goal)-base).rotated(float(facing_of(m)%4)*PI/8.0)
 var own=footprint("dtf2" if id=="shaker2" else ("dtf" if id=="shaker" else id),ms)
 var best=Vector2i(roundi(ideal.x),roundi(ideal.y))
 var score=INF
 for x in range(best.x-3,best.x+4):
  for y in range(best.y-3,best.y+4):
   var point=Vector2i(x,y)
   if inside(point) and not own.has(point) and Vector2(point).distance_squared_to(ideal)<score:
    score=Vector2(point).distance_squared_to(ideal);best=point
 return best

func footprint(id:String, machines:Dictionary={}) -> Array:
 var ms = state["machines"] if machines.is_empty() else machines
 var m = ms[id]
 if uses_rotated_footprint(id,ms):
  if m["kind"]=="shaker": return []
  return polygon_cells(equipment_polygon(id,ms))
 var a = []
 for x in int(m["size"][0]):
  for y in int(m["size"][1]): a.append(cell(m["pos"])+Vector2i(x,y))
 return a

func blocked(machines:Dictionary={}) -> Dictionary:
 var ms = state["machines"] if machines.is_empty() else machines
 var b = {}
 for id in ms:
  for p in footprint(id,ms): b[p] = true
 for id in ["dtf","dtf2"]:
  if ms.has(id) and not uses_rotated_footprint(id,ms):
   for x in 3: b[dtf_cell(id,Vector2i(x,1),ms)] = true
 for prop in room_props(): b[prop["pos"]]=true
 return b

func inside(p:Vector2i) -> bool:
 var size = bounds()
 return p.x>=0 and p.y>=0 and p.x<size.x and p.y<size.y

func path(start:Vector2i, goal:Vector2i, machines:Dictionary={}, extra_blocks:Dictionary={}) -> Array:
 var b = blocked(machines)
 b.merge(extra_blocks)
 if not inside(goal) or b.has(goal): return []
 var parents = {start:start}
 var q = [start]
 var head = 0
 while head<q.size():
  var p:Vector2i = q[head]
  head += 1
  if p == goal: break
  for direction in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]:
   var n:Vector2i = p+direction
   if inside(n) and not b.has(n) and not parents.has(n):
    parents[n]=p
    q.append(n)
 if not parents.has(goal): return []
 var result = []
 var p = goal
 while p!=start:
  result.push_front([p.x,p.y])
  p=parents[p]
 return result

func walk_segment_clear(from:Vector2, to:Vector2, machines:Dictionary={}) -> bool:
 # Sample the owner's whole swept step, including shoulder clearance at diagonal corners.
 var solids=blocked(machines)
 var steps=maxi(1,ceili(from.distance_to(to)/0.06))
 for n in range(1,steps+1):
  var p=from.lerp(to,float(n)/steps)
  for offset in [Vector2.ZERO,Vector2(-0.22,0),Vector2(0.22,0),Vector2(0,-0.22),Vector2(0,0.22),Vector2(-0.16,-0.16),Vector2(0.16,-0.16),Vector2(-0.16,0.16),Vector2(0.16,0.16)]:
   var tile=Vector2i(roundi(p.x+offset.x),roundi(p.y+offset.y))
   if not inside(tile) or solids.has(tile): return false
 return true

func nearest_floor(target:Vector2i) -> Vector2i:
 var b = blocked()
 if inside(target) and not b.has(target): return target
 var best = entrance()
 var score = 9999.0
 for x in bounds().x:
  for y in bounds().y:
   var p=Vector2i(x,y)
   var d=Vector2(target).distance_squared_to(Vector2(p))
   if not b.has(p) and d<score:
    score=d
    best=p
 return best

func rotate_dtf_cell(p:Vector2i,rotation:int) -> Vector2i:
 match posmod(rotation,4):
  1: return Vector2i(3-p.y,p.x)
  2: return Vector2i(2-p.x,3-p.y)
  3: return Vector2i(p.y,2-p.x)
 return p

func dtf_cell(id:String,local:Vector2i,ms:Dictionary) -> Vector2i:
 var m=ms[id]
 var r=int(m["rotation"])
 var corner=[Vector2i.ZERO,Vector2i(3,0),Vector2i(0,3),Vector2i.ZERO][posmod(r,4)]
 return cell(m["pos"])-corner+rotate_dtf_cell(local,r)

func configure_dtf(ms:Dictionary,id:String,pos:Vector2i,r:int) -> void:
 r=posmod(r,4)
 var m=ms[id]
 m["pos"]=[pos.x,pos.y];m["rotation"]=r
 m["size"]=[3,1] if r%2==0 else [1,3]
 var shake="shaker2" if id=="dtf2" else "shaker"
 var s=ms[shake]
 var cells=[dtf_cell(id,Vector2i(0,2),ms),dtf_cell(id,Vector2i(2,3),ms)]
 var at=Vector2i(mini(cells[0].x,cells[1].x),mini(cells[0].y,cells[1].y))
 s["pos"]=[at.x,at.y];s["rotation"]=r;s["size"]=[3,2] if r%2==0 else [2,3]
 var rear_service=dtf_cell(id,Vector2i(-1,1),ms)-pos
 var front_service=dtf_cell(id,Vector2i(-1,2),ms)-at
 m["service"]=[rear_service.x,rear_service.y];s["service"]=[front_service.x,front_service.y]

func install_feedback(id:String,pos:Vector2i,rotation:int=0,facing:int=-1,center:Vector2=Vector2(INF,INF)) -> Dictionary:
 if not C.EQUIPMENT_PRICES.has(id): return {"valid":false,"reason":"Unknown equipment."}
 if state["machines"].has(id): return {"valid":false,"reason":"This station is already installed."}
 if state["cash"]<C.EQUIPMENT_PRICES[id]: return {"valid":false,"reason":"Not enough cash for this station."}
 if id in ["banner","cnc","dock"] and state["location"]==1: return {"valid":false,"reason":"Expand to the industrial shop for this equipment."}
 Strategy.ensure(self)
 if id in ["banner","cnc","dock"] and int(state["rules"]["version"])>0 and not state["fit_out"]: return {"valid":false,"reason":"Complete the $350 industrial fit-out first."}
 var previous=state["machines"]
 var candidate=previous.duplicate(true)
 var source=C.layout(2 if id in ["banner","cnc","dock"] else 1)
 candidate[id]=source[id].duplicate(true)
 if id=="dtf": candidate["shaker"]=source["shaker"].duplicate(true)
 state["machines"]=candidate
 var result=placement_feedback(id,pos,rotation,facing,center)
 state["machines"]=previous
 return result

func install_equipment(id:String,pos:Vector2i,rotation:int=0,facing:int=-1,center:Vector2=Vector2(INF,INF)) -> bool:
 var result=install_feedback(id,pos,rotation,facing,center)
 notice(result["reason"])
 if not result["valid"]: return false
 state["machines"]=result["machines"]
 _reroute_customers()
 state["cash"]-=C.EQUIPMENT_PRICES[id]
 state["stats"]["capex"]=state["stats"].get("capex",0)+C.EQUIPMENT_PRICES[id]
 notice("Placed "+state["machines"][id]["title"]+". Add more stations or resume the clock when ready.")
 save_game()
 return true

func placement_feedback(id:String, pos:Vector2i, rotation:int=0,facing:int=-1,center:Vector2=Vector2(INF,INF)) -> Dictionary:
 if not state["machines"].has(id): return {"valid":false,"reason":"Unknown equipment."}
 var ms = state["machines"].duplicate(true)
 if facing<0: facing=posmod(rotation,4)*4
 facing=posmod(facing,16)
 rotation=floori(float(facing)/4.0)
 var m = ms[id]
 if int(m["active"])>=0: return {"valid":false,"reason":"Finish the current job before moving equipment."}
 m["pos"]=[pos.x,pos.y]
 if rotation != int(m["rotation"]) and m["kind"]!="dtf":
  if m["kind"]=="shaker": return {"valid":false,"reason":"Rotate the complete DTF line by selecting its printer."}
  if rotation%2!=int(m["rotation"])%2:
   var width=m["size"][0]
   m["size"][0]=m["size"][1]
   m["size"][1]=width
  m["rotation"]=rotation
  m["service"]=[-1,0] if rotation%2 else [0,int(m["size"][1])]
 if id in ["dtf","dtf2"]:
  var shake="shaker2" if id=="dtf2" else "shaker"
  if int(ms[shake]["active"])>=0: return {"valid":false,"reason":"The connected curing unit is working."}
  configure_dtf(ms,id,pos,rotation)
  ms[shake]["facing"]=facing
 m["facing"]=facing
 if center.is_finite():
  # Keep the physical floor pivot exact even when odd/even dimensions swap.
  # Integer grid corners alone cannot represent a half-tile center at every angle.
  m.erase("floor_offset")
  var delta=center-equipment_center(id,ms)
  pos+=Vector2i(roundi(delta.x),roundi(delta.y))
  if m["kind"]=="dtf":configure_dtf(ms,id,pos,rotation)
  else:m["pos"]=[pos.x,pos.y]
  var offset=center-equipment_center(id,ms)
  m["floor_offset"]=[offset.x,offset.y]
 var occupied = {}
 for key in ms:
  for p in footprint(key,ms):
   if not inside(p): return {"valid":false,"reason":"Equipment must fit inside this shop.","machines":ms}
   if occupied.has(p): return {"valid":false,"reason":"Equipment overlaps %s." % ms[occupied[p]]["title"],"machines":ms}
   occupied[p]=key
 for prop in room_props():
  if occupied.has(prop["pos"]): return {"valid":false,"reason":"Equipment overlaps a fixed shelf or plant.","machines":ms}
 for printer in ["dtf","dtf2"]:
  if not ms.has(printer): continue
  var shake="shaker2" if printer=="dtf2" else "shaker"
  var p=cell(ms[printer]["pos"])
  var s=cell(ms[shake]["pos"])
  var expected=ms.duplicate(true)
  configure_dtf(expected,printer,p,int(ms[printer]["rotation"]))
  if s!=cell(expected[shake]["pos"]) or cell(ms[shake]["size"])!=cell(expected[shake]["size"]) or int(ms[shake]["rotation"])!=int(ms[printer]["rotation"]): return {"valid":false,"reason":"Disconnected film feed: rotate and move the complete printer / shaker line."}
  if int(ms[printer]["width"])!=int(ms[shake]["width"]): return {"valid":false,"reason":"Printer and shaker media widths do not match."}
  if uses_rotated_footprint(printer,ms): continue
  var reserved=[]
  for local in [Vector2i(1,-1),Vector2i(-1,0),Vector2i(-1,2),Vector2i(1,4)]: reserved.append(dtf_cell(printer,local,ms))
  for x in 3: reserved.append(dtf_cell(printer,Vector2i(x,1),ms))
  for p2 in reserved:
   if not inside(p2) or occupied.has(p2): return {"valid":false,"reason":"Blocked DTF film span, rear loading, side service, or front take-up access.","machines":ms}
 for key in ms:
  var goal=service(key,ms)
  if goal!=entrance() and path(entrance(),goal,ms).is_empty(): return {"valid":false,"reason":"No walkable aisle from the entrance to %s." % ms[key]["title"],"machines":ms}
 for w in state["workers"]:
  if blocked(ms).has(Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1]))): return {"valid":false,"reason":"Move the worker out of this footprint first.","machines":ms}
 for actor in visible_customers():
   if blocked(ms).has(Vector2i(roundi(actor["pos"][0]),roundi(actor["pos"][1]))): return {"valid":false,"reason":"A customer is standing here. Choose a clear floor space.","machines":ms}
 return {"valid":true,"reason":"Valid: equipment fits with clear service access and walkable aisles.","machines":ms}

func move_equipment(id:String, p:Vector2i, rotation:int=0,facing:int=-1,center:Vector2=Vector2(INF,INF)) -> bool:
 var f=placement_feedback(id,p,rotation,facing,center)
 notice(f["reason"])
 if not f["valid"]: return false
 state["machines"]=f["machines"]
 state["machines"][id].erase("rotation_pivot")
 _reroute_customers()
 for w in state["workers"]:
  if not w["task"].is_empty():
   var goal=service(w["task"]["machine"])
   w["path"]=path(Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1])),goal)
  elif not w["path"].is_empty():
   var goal=cell(w["path"][-1])
   w["path"]=path(Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1])),goal)
 save_game()
 return true

func rotate_equipment(id:String) -> bool:
 var m=state["machines"][id]
 var facing=(facing_of(m)+1)%16
 return move_equipment(id,cell(m["pos"]),facing/4,facing,equipment_center(id,state["machines"]))

func accept(i:int, rush:bool=false) -> bool:
 if not state["paused"]: _update_visits()
 var o=order(i)
 if o.is_empty() or o["stage"]!="intake": return false
 Strategy.ensure(self)
 o["base_reward"]=o["reward"]
 if int(state["rules"]["version"])>0:
  var terms=quote(i,rush)
  if not terms["valid"]: notice(terms["reason"]);return false
  o["due"]=terms["due"];o["reward"]=terms["payout"];o["rush"]=rush
  o["rules_at_accept"]=state["rules"].duplicate(true)
  o["accepted_day"]=state["day"]
  o["fault_roll"]=float(absi((o["id"]+":quality").hash())%10000)/10000.0
 o["stage"]="preflight"
 _ensure_visit(o)
 o["visit"]["status"]="production"
 if rush and int(state["rules"]["version"])==0:
  o["rush"]=true
  o["reward"]=roundi(o["reward"]*1.3)
  o["due"]=now()+1.8
 notice("Accepted %s. Preflight comes first." % o["product"])
 return true

func decline(i:int) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"]!="intake": return false
 o["stage"]="declined"
 _ensure_visit(o)
 o["visit"]["status"]="withdrawn"
 o["visit"]["settled_at"]=now()
 notice("Order declined. Existing capacity stays available.")
 return true

func preflight(i:int, action:String) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"]!="preflight": return false
 if action=="revision":
  o["stage"]="revision"
  o["revision_eta"]=now()+0.3
  notice("Customer revision requested. Artwork arrives in 18 shop minutes.")
  return true
 if not o["art_ready"]:
  if state["cash"]<30: notice("Artwork repair needs $30."); return false
  state["cash"]-=30
  state["stats"]["art_fees"]+=30
  o["art_cost"]=o.get("art_cost",0)+30
 o["art_ready"]=true
 o["stage"]="plan"
 notice("Preflight passed: dimensions, transparency, bleed / toolpath checked.")
 return true

func gang_valid(i:int, gang:Array) -> bool:
 var o=order(i)
 if gang.is_empty(): return false
 for n in gang.size():
  var a=gang[n]
  var rect=Rect2(a[0],a[1],a[2],a[3])
  if not Rect2(0,0,float(o["film_width"]),float(o["sheet_length"])).encloses(rect): return false
  if not ((is_equal_approx(float(a[2]),float(o["art_w"])) and is_equal_approx(float(a[3]),float(o["art_h"]))) or (is_equal_approx(float(a[2]),float(o["art_h"])) and is_equal_approx(float(a[3]),float(o["art_w"])))): return false
  for j in n:
   var b=gang[j]
   if rect.intersects(Rect2(b[0],b[1],b[2],b[3])): return false
 return true

func auto_pack(i:int) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"]!="plan": return false
 var best=[]
 for rotate in [false,true]:
  var w=float(o["art_h"] if rotate else o["art_w"])
  var h=float(o["art_w"] if rotate else o["art_h"])
  var a=[]
  var rows=floori(float(o["sheet_length"])/h)
  var cols=floori(float(o["film_width"])/w)
  for y in rows:
   for x in cols:
    if a.size()<o["quantity"]: a.append([x*w,y*h,w,h])
  if a.size()>best.size(): best=a
 o["gang"]=best
 o["recipe"]=C.recipe(o)
 notice("Auto-packed %d designs; physical artwork dimensions preserved." % best.size())
 return not best.is_empty()

func materials_available(recipe:Dictionary) -> bool:
 for key in recipe:
  if int(state["stock"].get(key,0))<int(recipe[key]): return false
 return true

func missing(recipe:Dictionary) -> String:
 var a=[]
 for key in recipe:
  if int(state["stock"].get(key,0))<int(recipe[key]): a.append("%s %d short" % [key,int(recipe[key])-int(state["stock"].get(key,0))])
 return ", ".join(a)

func _consume(recipe:Dictionary, o:Dictionary) -> void:
 var cost=0.0
 for key in recipe:
  state["stock"][key]-=int(recipe[key])
  cost+=float(recipe[key])*C.PRICES.get(key,1.0)
 o["material_cost"]+=cost
 state["stats"]["materials"]+=cost
 if o["reprints"]>0: state["stats"]["waste"]+=cost

func queue_order(i:int) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"] not in ["plan","waiting_stock"]: return false
 if o["type"] in ["transfer","apparel"] and not gang_valid(i,o["gang"]): notice("Lay out a valid gang sheet first."); return false
 if o["type"]=="cnc" and o["settings"]["media"] not in ["PVC","ACM"]: notice("Incompatible cutter preset: select PVC or ACM panel stock."); return false
 o["recipe"]=order_recipe(o)
 o["stage"]="queued" if materials_available(o["recipe"]) else "waiting_stock"
 if o["stage"]=="waiting_stock": notice("Waiting for stock: "+missing(o["recipe"])); return false
 notice("Job queued. Work here with Sam, or let a hired operator take it.")
 return true

func machine_for(o:Dictionary) -> String:
 if o["stage"]=="preflight": return "art"
 if o["stage"] in ["press","qc","pack","ready"]:
  return {"press":"heat","qc":"finish","pack":"pack","ready":"dock" if o["fulfillment"]=="ship" and state["location"]==2 else "pack"}[o["stage"]]
 return {"transfer":"dtf","apparel":"dtf","sticker":"sticker","banner":"banner","cnc":"cnc"}.get(o["type"],"dtf")

func role_matches(w:Dictionary, m:String) -> bool:
 if not state["machines"].has(m): return false
 if w["id"]=="owner": return true
 var kind=state["machines"][m]["kind"]
 return kind in {"Prepress artist":["art"],"DTF operator":["dtf"],"Print / cut operator":["sticker","banner"],"Finisher":["heat","finish"],"CNC operator":["cnc"],"Packer":["pack","finish"],"Shipping worker":["dock","pack"]}.get(w["role"],[])

func _dispatch(i:int, w:Dictionary, m:String) -> bool:
 var o=order(i)
 if w.is_empty() or not w["task"].is_empty() or not state["machines"].has(m): return false
 if not role_matches(w,m): return false
 var machine=state["machines"][m]
 if int(machine["active"])>=0: return false
 for w2 in state["workers"]:
  if not w2["task"].is_empty() and (w2["task"]["machine"]==m or w2["task"]["order"]==i): return false
 if machine["kind"]=="dtf":
  var shake="shaker2" if m=="dtf2" else "shaker"
  if machine["width"]!=state["machines"][shake]["width"] or machine["width"]!=o["film_width"]:
   notice("DTF film, printer, and shaker widths must match.")
   return false
  if not placement_feedback(m,cell(machine["pos"]),int(machine["rotation"]),facing_of(machine))["valid"]: return false
 if o["stage"]=="waiting_stock":
  if not materials_available(dispatch_recipe(o)): return false
  o["stage"]="queued"
 if o["stage"] not in ["preflight","queued","press","qc","pack","ready"]: return false
 if o["stage"]=="ready" and not customer_ready_for_handoff(o): return false
 if o["stage"]=="queued" and not o["consumed"] and not materials_available(dispatch_recipe(o)): o["stage"]="waiting_stock"; return false
 if o["stage"]=="press" and not o.get("garments_consumed",false) and not garment_available(o): notice("Reserve the correct garment sizes / color first."); return false
 if o["stage"]=="pack" and not o.get("boxes_consumed",false) and state["stock"]["packaging"]<boxes_for(o): notice("Packaging stock is low. Restock boxes."); return false
 var start=Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1]))
 var goal=service(m)
 var route=path(start,goal)
 if start!=goal and route.is_empty(): notice("Worker cannot reach this station."); return false
 w["path"]=route
 w["task"]={"order":i,"machine":m,"stage":o["stage"],"working":false}
 o["route_machine"]=m
 return true

func work_order(i:int, station_override:String="") -> bool:
 var o=order(i)
 if o.is_empty(): return false
 if o["stage"]=="ready" and not customer_ready_for_handoff(o):
  notice("The customer is returning for pickup. Wait until they reach the counter.")
  return false
 if not owner()["task"].is_empty():
  notice("Sam is busy. Use WASD to interrupt, or finish the current task.")
  return false
 owner()["manual"]=true
 var m=machine_for(o)
 if station_override!="": m=station_override
 var required=machine_for(o)
 if m!=required and not (required=="dtf" and m=="dtf2"):
  notice("This job needs "+required+" at its current stage.");return false
 if not state["machines"].has(m): notice("Place the required station first: "+m+"."); return false
 if m=="dtf" and state["machines"].has("dtf2") and int(state["machines"]["dtf"]["active"])>=0: m="dtf2"
 var result=_dispatch(i,owner(),m)
 if result: notice("Sam is walking to "+state["machines"][m]["title"]+".")
 return result

func available_order(m:String) -> int:
 for i in active_orders():
  var o=order(i)
  if o["stage"] not in ["preflight","queued","waiting_stock","press","qc","pack","ready"]: continue
  var desired=machine_for(o)
  if desired==m or (desired=="dtf" and m=="dtf2"): return i
 return -1

func work_station(m:String) -> bool:
 if m in ["shaker","shaker2"]: m="dtf2" if m=="shaker2" else "dtf"
 var i=available_order(m)
 if i<0: notice("No prepared jobs are waiting at this station."); return false
 return work_order(i,m)

func interrupt_owner() -> void:
 var w=owner()
 var t=w["task"]
 if not t.is_empty():
  var m=state["machines"][t["machine"]]
  if t["working"]:
   var o=order(t["order"])
   o["stage"]=t["stage"]
   m["active"]=-1
   m["elapsed"]=0.0
   m["phase"]="Paused job"
  w["task"]={}
 w["path"]=[]
 w["manual"]=true

func move_owner(target:Vector2i) -> bool:
 var b=blocked()
 if not inside(target) or b.has(target): notice("Click a clear floor tile. Machines have solid footprints."); return false
 var start=Vector2i(roundi(owner()["pos"][0]),roundi(owner()["pos"][1]))
 var route=path(start,target)
 if target!=start and route.is_empty(): notice("No clear walking route to this spot."); return false
 interrupt_owner()
 owner()["path"]=route
 return true

func assign(w_id:String, m_id:String) -> bool:
 if not state["machines"].has(m_id) or worker(w_id).is_empty(): return false
 var m=state["machines"][m_id]
 if m["kind"]=="shaker": m_id="dtf2" if m_id=="shaker2" else "dtf"; m=state["machines"][m_id]
 if not role_matches(worker(w_id),m_id): notice("This role is not qualified for that station.");return false
 if m["active"]>=0: notice("Finish this job before changing its operator."); return false
 m["worker"]=w_id
 worker(w_id)["manual"]=false
 notice("%s assigned to %s." % [worker(w_id)["name"],m["title"]])
 return true

func _auto_dispatch() -> void:
 for w in state["workers"]:
  if not w["task"].is_empty() or (w["id"]=="owner" and w["manual"]): continue
  for i in active_orders():
   var o=order(i)
   if o["stage"] not in ["preflight","queued","waiting_stock","press","qc","pack","ready"]: continue
   var options=[machine_for(o)]
   if options[0]=="dtf" and state["location"]==2: options.append("dtf2")
   var done=false
   for m in options:
    if not state["machines"].has(m): continue
    var assignment=state["machines"][m]["worker"]
    if assignment!=w["id"] and (assignment!="auto" or not role_matches(w,m)): continue
    if _dispatch(i,w,m): done=true; break
   if done: break

func garment_available(o:Dictionary) -> bool:
 for key in o["garments"]:
  if state["garments"].get(key,0)<o["garments"][key]: return false
 return true

func boxes_for(o:Dictionary) -> int:
 return maxi(1,ceili(o["quantity"]/50.0))

func _begin_task(w:Dictionary) -> void:
 var t=w["task"]
 var o=order(t["order"])
 var m=state["machines"][t["machine"]]
 if o["stage"]!=t["stage"] or m["active"]>=0: w["task"]={}; return
 if t["stage"]=="preflight": o["stage"]="prepress"
 if t["stage"]=="queued":
  var batch=o.get("batch_members",[t["order"]])
  var total={}
  for j in batch:
   var member=order(int(j))
   if member.get("consumed",false): continue
   if state["upgrades"]["quality_sensor"] and member.has("batch_recipe"):
    member["settings"]["white"]="standard";member["settings"]["registration"]=true
    var recipe=C.recipe(member);recipe["film"]=member["batch_recipe"]["film"]
    member["recipe"]=recipe;member["batch_recipe"]=recipe
   for key in member["recipe"]: total[key]=int(total.get(key,0))+int(member["recipe"][key])
  if not materials_available(total): o["stage"]="waiting_stock";w["task"]={};return
  if not o["consumed"]:
   if state["upgrades"]["quality_sensor"]:
    o["settings"]["white"]="standard"
    o["settings"]["registration"]=true
    o["recipe"]=order_recipe(o)
    m["condition"]=maxi(70,m["condition"])
   if not materials_available(o["recipe"]): o["stage"]="waiting_stock"; w["task"]={}; return
   _consume(o["recipe"],o)
   o["consumed"]=true
  for j in batch:
   var member=order(int(j))
   if int(j)!=int(t["order"]) and not member["consumed"]:
    _consume(member["recipe"],member);member["consumed"]=true
   member["production_machine"]=t["machine"];member["route_machine"]=t["machine"]
   member["production_skill"]=w["skill"]
  o["production_machine"]=t["machine"]
  if float(o["started_at"])<0: o["started_at"]=now()
  o["stage"]="production"
 elif t["stage"]=="press":
  if not o.get("garments_consumed",false) and not garment_available(o): w["task"]={}; return
  if not o.get("garments_consumed",false):
   for key in o["garments"]:
    state["garments"][key]-=o["garments"][key]
    o["material_cost"]+=o["garments"][key]*4
    state["stats"]["materials"]+=o["garments"][key]*4
   o["garments_consumed"]=true
  o["stage"]="pressing"
 elif t["stage"]=="qc": o["stage"]="inspecting"
 elif t["stage"]=="pack":
  if not o.get("boxes_consumed",false) and state["stock"]["packaging"]<boxes_for(o): w["task"]={}; return
  if not o.get("boxes_consumed",false):
   _consume({"packaging":boxes_for(o)},o)
   o["boxes_consumed"]=true
  o["stage"]="packing"
 elif t["stage"]=="ready": o["stage"]="delivering"
 t["working"]=true
 m["active"]=t["order"]
 m["elapsed"]=0.0
 m["phase"]="Starting"

func _phases(w:Dictionary) -> Array:
 var t=w["task"]
 return C.phases("deliver" if t["stage"]=="ready" else state["machines"][t["machine"]]["kind"],order(t["order"]))

func task_duration(w:Dictionary) -> float:
 var duration=0.0
 if w["task"].is_empty(): return duration
 for phase in _phases(w): duration+=float(phase[1])
 var kind=state["machines"][w["task"]["machine"]]["kind"]
 if kind=="dtf" and state["upgrades"]["auto_feeder"]: duration*=0.7
 var o=order(int(w["task"]["order"]))
 if w["task"]["stage"]=="queued" and o.has("batch_members"):
  var quantity=0
  for j in o["batch_members"]: quantity+=int(order(int(j))["quantity"])
  duration*=maxf(1.0,float(quantity)/maxf(1,float(o["quantity"])))
 return duration / float(w["skill"])

func machine_progress(id:String) -> float:
 for w in state["workers"]:
  if not w["task"].is_empty() and w["task"]["machine"]==id and w["task"]["working"]:
   return clampf(state["machines"][id]["elapsed"]/maxf(1.0,task_duration(w)),0,1)
 return 0.0

func station_activity(id:String) -> Dictionary:
 var target="dtf2" if id=="shaker2" else ("dtf" if id=="shaker" else id)
 for w in state["workers"]:
  var task=w["task"]
  if task.is_empty() or task["machine"]!=target: continue
  var m=state["machines"][target]
  return {"phase":m["phase"] if task["working"] else "Operator approaching","operator":w["name"],"elapsed":float(m["elapsed"]),"working":bool(task["working"]),"progress":machine_progress(target),"order":int(task["order"])}
 return {"phase":"Idle","operator":"No active operator","elapsed":0.0,"working":false,"progress":0.0,"order":-1}

func worker_status(w:Dictionary) -> String:
 if not w["task"].is_empty(): return ("Operating " if w["task"]["working"] else "Walking to ")+w["task"]["machine"]
 if w["id"]=="owner" and w["manual"]: return "Auto Assist off: manual control"
 for i in active_orders():
  var o=order(i)
  if o["stage"] not in ["queued","waiting_stock","press","qc","pack","ready","preflight"]: continue
  var id=machine_for(o)
  if not role_matches(w,id): continue
  if state["machines"][id]["worker"] not in ["auto",w["id"]]: continue
  if state["machines"][id]["active"]>=0: return "Waiting for a busy station"
  if o["stage"]=="ready" and not customer_ready_for_handoff(o): return "Customer returning for pickup"
  if o["stage"] in ["queued","waiting_stock"] and not materials_available(dispatch_recipe(o)): return "Waiting for supplies"
  return "Ready for dispatch"
 return "No suitable queued work at assigned stations"

func _finish_task(w:Dictionary) -> void:
 var t=w["task"]
 var o=order(t["order"])
 var m=state["machines"][t["machine"]]
 # Settlement saves the entire shop, so release this task before it can save.
 w["task"]={}
 w["walking"]=false
 m["active"]=-1
 m["elapsed"]=0.0
 m["phase"]="Idle"
 o["output_machine"]=t["machine"]
 match t["stage"]:
  "preflight":
   o["art_ready"]=true
   o["stage"]="plan"
   notice("Artist checked dimensions and repaired the artwork. Plan production next.")
  "queued":
   m["condition"]=maxi(20,m["condition"]-3)
   if m["kind"]=="dtf": state["machines"]["shaker2" if t["machine"]=="dtf2" else "shaker"]["condition"]-=2
   for j in o.get("batch_members",[t["order"]]):
    var member=order(int(j))
    member["output_machine"]=t["machine"]
    member["issue"]=_quality_issue(member,m)
    member["stage"]="press" if member["type"]=="apparel" and not member.get("press_done",false) else "qc"
   notice("%s produced. %s next." % [o["product"],"Heat press" if o["stage"]=="press" else "Inspection"])
  "press":
   o["press_done"]=true
   if o["settings"]["press"]!="cotton_warm": o["issue"]="Incorrect peel / press preset for the cotton blanks"
   o["stage"]="qc"
  "qc":
   o["stage"]="fault" if o["issue"]!="" else "pack"
   o["quality"]=70 if o["stage"]=="fault" else 100
   notice("QC issue: "+o["issue"] if o["stage"]=="fault" else "Inspection passed. Cut / roll and pack the output.")
  "pack":
   o["stage"]="ready"
   _ensure_visit(o)
   o["visit"]["status"]="pickup"
   notice("Box ready for %s." % o["fulfillment"])
  "ready": _fulfill(o)
 w["task"]={}
 w["walking"]=false

func _quality_issue(o:Dictionary, m:Dictionary) -> String:
 if o["type"] in ["transfer","apparel"]:
  if o["settings"]["white"]=="economy": return "Low white opacity: economy white-ink setting"
  if m["condition"]<65: return "Nozzle dropout: printer needs cleaning"
  var shaker=state["machines"]["shaker2" if o["route_machine"]=="dtf2" else "shaker"]
  if shaker["condition"]<65: return "Uneven powder / incomplete cure: shaker needs service"
 if o["type"]=="sticker" and not o["settings"]["registration"]: return "Sticker misregistration: marks were not aligned"
 if o["type"]=="banner" and m["condition"]<65: return "Media skew: roll-feed calibration is low"
 if o["type"]=="cnc" and m["condition"]<65: return "Rough cut edge: cutter tool needs maintenance"
 if o.has("rules_at_accept"):
  var roll=float(o.get("fault_roll",1))
  if int(o["reprints"])>0: roll=float(absi((o["id"]+":retry:"+str(int(o["reprints"]))).hash())%10000)/10000.0
  var risk=.02*float(o["rules_at_accept"]["faults"])/maxf(.5,float(o.get("production_skill",1)))
  if roll<risk: return "Recoverable alignment defect: inspect, recalibrate and reprint"
 return ""

func recover(i:int, reprint:bool) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"]!="fault": return false
 if not reprint:
  o["quality_accepted"]=true
  o["stage"]="pack"
  notice("Accepted reduced quality. Payment and customer trust will reflect it.")
  return true
 var m_id=o.get("production_machine",o["route_machine"])
 if m_id in ["finish","pack","heat"]: m_id={"transfer":"dtf","apparel":"dtf","sticker":"sticker","banner":"banner","cnc":"cnc"}[o["type"]]
 if state["stock"]["maintenance"]<=0: notice("A maintenance kit is required to fix the cause before reprinting."); return false
 _consume({"maintenance":1},o)
 state["machines"][m_id]["condition"]=100
 if m_id in ["dtf","dtf2"]: state["machines"]["shaker2" if m_id=="dtf2" else "shaker"]["condition"]=100
 o["settings"]["white"]="standard"
 o["settings"]["registration"]=true
 o["settings"]["press"]="cotton_warm"
 o["issue"]=""
 o["consumed"]=false
 o["press_done"]=false
 if o["type"]=="apparel": o["garments_consumed"]=false
 o["reprints"]+=1
 for key in ["batch_recipe","batch_members","batch_leader","batch_slots"]: o.erase(key)
 o["recipe"]=C.recipe(o)
 o["stage"]="queued"
 notice("Cause corrected. Reprint consumes new film / ink / media and adds production time.")
 return true

func _fulfill(o:Dictionary) -> void:
 if o.get("paid",false) or o["stage"]=="completed": return
 if o["stage"] not in ["ready","delivering"]: return
 _ensure_visit(o)
 var punctual=now()<=float(o["due"])
 var reward=roundi(o["reward"]*(0.76 if o["quality_accepted"] else 1.0))
 # Original print-shop design: quality and lateness determine satisfaction.
 var lateness=maxf(0.0,now()-float(o["due"]))
 var satisfaction=clampi(roundi(float(o["quality"])-minf(40.0,lateness*10.0)),0,100)
 o["paid"]=true
 o["payment"]=reward
 o["satisfaction"]=satisfaction
 o["visit"]["status"]="served"
 o["visit"]["satisfaction"]=satisfaction
 o["visit"]["settled_at"]=now()
 state["cash"]+=reward
 state["stats"]["sales"]+=reward
 state["stats"]["delivered"]+=1
 state["stats"]["quality"]+=o["quality"]
 state["completed"]+=1
 state["quality_total"]+=o["quality"]
 if punctual: state["on_time"]+=1; state["stats"]["on_time"]+=1
 state["reputation"]=clampi(state["reputation"]+(4 if punctual else -5)-(3 if o["quality_accepted"] else 0),0,100)
 o["stage"]="completed"
 o["finished_at"]=now()
 state["customers"][o["customer"]]=state["customers"].get(o["customer"],0)+1
 notice("Delivered %d %s%s. +$%d / Satisfaction %d%%" % [o["quantity"],o["product"]," on time" if punctual else " late",reward,satisfaction])
 save_game()

func _face(w:Dictionary, direction:Vector2) -> void:
 var sx=direction.x-direction.y
 var sy=direction.x+direction.y
 w["face"]=(0 if sx<0 else 1) if sy>=0 else (2 if sx<0 else 3)

func _walk(w:Dictionary, delta:float) -> void:
 w["walking"]=false
 if w["path"].is_empty(): return
 var target=v(w["path"][0])
 var pos=v(w["pos"])
 var direction=target-pos
 var distance=direction.length()
 if distance<0.001: w["path"].pop_front(); return
 var amount=minf(distance,delta*2.2)
 var next=pos+direction.normalized()*amount
 var b=blocked()
 if b.has(Vector2i(roundi(next.x),roundi(next.y))) or not walk_segment_clear(pos,next):
  w["path"]=path(Vector2i(roundi(pos.x),roundi(pos.y)),cell(w["path"][-1]))
  return
 w["pos"]=[next.x,next.y]
 w["step"]+=amount*5.0
 w["walking"]=true
 _face(w,direction)
 if amount>=distance: w["pos"]=[target.x,target.y]; w["path"].pop_front()

func tick(delta:float) -> void:
 if state["paused"]: return
 _update_visits()
 var dt=minf(delta,0.1)*float(state["speed"])
 state["clock"]=minf(17.0,float(state["clock"])+dt*SHOP_HOURS_PER_SECOND)
 _update_customer_actors(dt)
 for d in state["deliveries"].duplicate():
  if now()>=d["eta"]:
   for key in d["items"]:
    if key.begins_with("garment:"):
     var g=key.trim_prefix("garment:")
     state["garments"][g]=state["garments"].get(g,0)+d["items"][key]
    else: state["stock"][key]=state["stock"].get(key,0)+d["items"][key]
   state["deliveries"].erase(d)
   notice("Supply delivery arrived at the %s." % ("storefront" if state["location"]==1 else "garage dock"))
 for i in active_orders():
  var o=order(i)
  if o["stage"]=="revision" and now()>=o["revision_eta"]: o["art_ready"]=true; o["stage"]="plan"; notice("Customer's corrected artwork arrived.")
  if o["stage"]=="waiting_stock" and materials_available(dispatch_recipe(o)): o["stage"]="queued"
 var own=owner()
 if manual_input.length_squared()>0.01:
  if not own["task"].is_empty() or not own["path"].is_empty(): interrupt_owner()
  var direction=manual_input.normalized()
  var pos=v(own["pos"])
  var next=pos+direction*minf(delta,0.1)*3.2
  var b=blocked()
  if inside(Vector2i(roundi(next.x),roundi(next.y))) and not b.has(Vector2i(roundi(next.x),roundi(next.y))) and walk_segment_clear(pos,next):
   own["pos"]=[next.x,next.y]
   own["step"]+=pos.distance_to(next)*5
   own["walking"]=true
   _face(own,direction)
  else: own["walking"]=false
  own["manual"]=true
 _auto_dispatch()
 for w in state["workers"]:
  w["shift_seconds"]=float(w.get("shift_seconds",0))+dt
  if w["id"]=="owner" and manual_input.length_squared()>0.01: continue
  _walk(w,dt)
  if w["task"].is_empty() or not w["path"].is_empty(): continue
  if not w["task"]["working"]: _begin_task(w)
  if w["task"].is_empty(): continue
  w["work_seconds"]=float(w.get("work_seconds",0))+dt
  var m=state["machines"][w["task"]["machine"]]
  m["elapsed"]+=dt
  var duration=task_duration(w)
  var phases=_phases(w)
  var total=0.0
  for phase in phases: total+=float(phase[1])
  var phase_time=m["elapsed"]/maxf(0.1,duration)*total
  for phase in phases:
   if phase_time<=float(phase[1]): m["phase"]=phase[0]; break
   phase_time-=float(phase[1])
  if m["elapsed"]>=duration: _finish_task(w)
 if state["clock"]>=17: state["paused"]=true; end_day()

func restock(items:Dictionary={}) -> bool:
 if items.is_empty():
  items={"film":48,"white":60,"powder":40,"sticker":60,"laminate":40,"cyan":40,"magenta":40,"yellow":40,"black":40,"packaging":20,"maintenance":4,"garment:navy:S":6,"garment:navy:M":6,"garment:navy:L":6}
 var cost=0.0
 for key in items:
  if items[key]<=0: return false
  cost+=items[key]*(4.0 if key.begins_with("garment:") else C.PRICES.get(key,1.0))
 cost=ceilf(cost)
 if state["cash"]<cost: notice("This delivery needs $%d." % int(cost)); return false
 state["cash"]-=int(cost)
 state["stats"]["supply_purchases"]=state["stats"].get("supply_purchases",0)+int(cost)
 Strategy.ensure(self)
 state["deliveries"].append({"items":items.duplicate(true),"eta":now()+0.45*float(state["rules"]["supply"]),"cost":cost})
 notice("Supplies ordered for $%d. Arrival in %d shop minutes." % [int(cost),roundi(27*float(state["rules"]["supply"]))])
 return true

func hire(role_index:int) -> bool:
 if role_index<0 or role_index>=C.ROLES.size() or state["workers"].size()>=9: return false
 var cost=C.HIRE_COST[role_index]
 if state["cash"]<cost: notice("Hiring needs $%d." % cost); return false
 if not hiring_buffer(role_index): notice("Hiring would leave less than the next daily bills, including this worker's $45 wage. Build a cash buffer first.");return false
 state["cash"]-=cost
 state["stats"]["hiring"]=state["stats"].get("hiring",0)+cost
 var id="staff%d" % int(state["next_worker"])
 state["next_worker"]+=1
 var point=nearest_floor(entrance()+Vector2i(1,state["workers"].size()%2))
 state["workers"].append({"id":id,"name":C.NAMES[role_index]+" #"+str(int(state["next_worker"])),"role":C.ROLES[role_index],"pos":[float(point.x),float(point.y)],"path":[],"task":{},"manual":false,"face":1,"step":0.0,"walking":false,"skill":1.25 if state["upgrades"]["training"] else 1.0,"wage":45})
 notice("%s joined as %s. They automatically take suitable prepared work." % [C.NAMES[role_index],C.ROLES[role_index]])
 return true

func buy_upgrade(key:String) -> bool:
 var costs={"auto_feeder":350,"training":400,"quality_sensor":450}
 if not costs.has(key) or state["upgrades"].get(key,false): return false
 if state["cash"]<costs[key]: notice("Upgrade needs $%d." % costs[key]); return false
 state["cash"]-=costs[key]
 state["stats"]["upgrades"]=state["stats"].get("upgrades",0)+costs[key]
 state["upgrades"][key]=true
 if key=="training":
  for w in state["workers"]: w["skill"]=1.25
 if key=="quality_sensor":
  for m in state["machines"].values(): m["condition"]=100
 notice("Installed "+key.replace("_"," ")+".")
 return true

func maintain(id:String) -> bool:
 var m=state["machines"].get(id,{})
 if m.is_empty() or m["active"]>=0: notice("Finish the job before servicing this equipment."); return false
 if state["stock"]["maintenance"]<1: notice("Restock maintenance kits first."); return false
 state["stock"]["maintenance"]-=1
 state["stats"]["materials"]+=8
 m["condition"]=100
 notice("Cleaned / calibrated %s. Used one maintenance kit." % m["title"])
 return true

func reorder(i:int, front:bool) -> bool:
 var o=order(i)
 if o.is_empty() or o["stage"]!="queued": return false
 var rank=9999
 if front:
  rank=-1
  for row in state["orders"]: rank=mini(rank,int(row.get("priority",0))-1)
 o["priority"]=rank
 var indexes=[]
 for n in active_orders(): indexes.append(n)
 # Keep stable order IDs and array indices; dispatch reads priority below.
 notice("Queue priority updated for "+o["product"]+".")
 return true

func garage_progress() -> Dictionary:
 var count=int(state["completed"])
 var quality=100.0 if count==0 else float(state["quality_total"])/count
 var on_time=100.0 if count==0 else float(state["on_time"])*100/count
 return {"cash":state["cash"],"trust":state["reputation"],"orders":count,"quality":quality,"on_time":on_time,"ready":state["cash"]>=1500 and state["reputation"]>=60 and count>=3 and on_time>=75 and quality>=85}

func move_garage() -> bool:
 Strategy.ensure(self)
 if int(state["rules"]["version"])>0: return expand_premises()
 if state["location"]==2: return false
 if not garage_progress()["ready"]: notice("Garage goals are not met yet."); return false
 for w in state["workers"]:
  if not w["task"].is_empty(): notice("Finish active staff tasks before moving the shop."); return false
 state["cash"]-=900
 state["location"]=2
 state["empty_start"]=false
 state["machines"]=C.layout(2)
 for o in C.garage_orders(now()): state["orders"].append(o)
 for w in state["workers"]:
  var point=nearest_floor(entrance()+Vector2i(1,0))
  w["pos"]=[float(point.x),float(point.y)]
  w["path"]=[]
 for o in state["orders"]:
  var actor=o.get("visit",{}).get("actor",{})
  if not actor.is_empty():
   actor["phase"]="away";actor["purpose"]="";actor["path"]=[];actor["walking"]=false
 notice("Welcome to the industrial shop: two DTF lines, wide format, CNC, and shipping.")
 save_game()
 return true

func end_day() -> Dictionary:
 if not state["report"].is_empty(): return state["report"]
 state["clock"]=17.0
 state["paused"]=true
 var s=state["stats"].duplicate(true)
 for w in state["workers"]: s["wages"]+=w["wage"]
 Strategy.ensure(self)
 s["overhead"]=roundi((125 if state["location"]==1 else 200)*float(state["rules"]["overhead"]))
 s["loan_payment"]=mini(50,int(state.get("loan_remaining",0)))
 var net=s["sales"]+s.get("recovery",0)-s["materials"]-s["art_fees"]-s.get("marketing",0)-s["wages"]-s["overhead"]
 state["report"]={"stats":s,"net":net,"day":state["day"],"open":active_orders().size()}
 state["report"]["cash_before_bills"]=state["cash"]
 state["report"]["cash_after_bills"]=state["cash"]-s["wages"]-s["overhead"]-s["loan_payment"]
 if state.has("day_open_cash"):
  state["report"]["cash_bridge"]={"opening":state["day_open_cash"],"receipts":s["sales"],"recovery":s.get("recovery",0),"loan_in":s.get("loan_in",0),"supplies":s.get("supply_purchases",0),"capital":s.get("capex",0),"hiring":s.get("hiring",0),"upgrades":s.get("upgrades",0),"art":s["art_fees"],"marketing":s.get("marketing",0)}
 state["best_profit"]=maxf(state["best_profit"],net)
 save_game()
 return state["report"]

func next_day() -> void:
 var report=end_day()
 if not state["report_applied"]:
  var payment=int(report["stats"].get("loan_payment",0))
  state["cash"]-=report["stats"]["wages"]+report["stats"]["overhead"]+payment
  state["loan_remaining"]=maxi(0,int(state.get("loan_remaining",0))-payment)
 state["day"]+=1
 state["clock"]=8.0
 state["paused"]=false
 state["report"]={}
 state["report_applied"]=false
 state["stats"]=C.day_stats()
 state["day_open_cash"]=state["cash"]
 for w in state["workers"]: w["shift_seconds"]=0.0;w["work_seconds"]=0.0
 var types=["transfer","sticker","apparel"] if state["location"]==1 else ["transfer","sticker","apparel","banner","cnc"]
 if state.get("customer_flow",false):
  var available=[]
  for type in types:
   var station={"transfer":"dtf","sticker":"sticker","apparel":"dtf","banner":"banner","cnc":"cnc"}[type]
   if state["machines"].has(station) and (type!="apparel" or state["machines"].has("heat")): available.append(type)
  types=available
 var count=_lead_count(types)
 for n in types.size():
  if count>=6: break
  var type=types[(n+int(state["day"]))%types.size()]
  if int(state["rules"]["version"])>0 and state["specialty"]!="General" and n==0:
   for favorite in Strategy.SPECIALTIES[state["specialty"]]:
    if types.has(favorite): type=favorite;break
  var q={"transfer":12,"sticker":60,"apparel":12,"banner":2,"cnc":6}[type]
  q+=(int(state["day"])%3)*({"transfer":6,"sticker":20,"apparel":0,"banner":0,"cnc":1}[type])
  if int(state["rules"]["version"])>0:
   # Partial sheets create a real material-saving / waiting tradeoff for batches.
   if type=="transfer": q=10+(int(state["day"])%4)*3
   if type=="apparel": q=9+(int(state["day"])%3)*2
  var customer=C.CUSTOMERS[(n+int(state["day"]))%C.CUSTOMERS.size()]
  var reward=roundi(q*{"transfer":20.0,"sticker":4.2,"apparel":50.0,"banner":380.0,"cnc":118.0}[type])
  var o=C.make_order("DAY%d-%d" % [state["day"],n],type,q,customer,now()+5.5+n*0.5,reward)
  if state["customers"].has(customer): o["returning"]=true; o["reward"]+=35
  if state["reputation"]>=80 and n==0:
   o["wholesale"]=true; o["quantity"]*=2; o["reward"]*=2
   for key in o["garments"]: o["garments"][key]*=2
  state["orders"].append(o)
  if state.get("customer_flow",false):
   o["stage"]="scheduled"
   o["visit"]={"status":"scheduled","arrival_at":now()+float(n)*0.75,"arrived_at":-1.0,"patience_until":-1.0,"settled_at":-1.0,"satisfaction":-1}
  count+=1
 notice("Day %d begins. Paid wages / overhead; unfinished jobs retain their deadlines." % state["day"])
 save_game()

func forecast() -> Dictionary:
 var required={}
 for i in active_orders():
  var o=order(i)
  if o["stage"] in ["intake","completed","declined","scheduled","abandoned"] or o["consumed"]: continue
  var recipe=C.recipe(o)
  for key in recipe: required[key]=required.get(key,0)+recipe[key]
 var shortages={}
 for key in required:
  if required[key]>state["stock"].get(key,0): shortages[key]=required[key]-state["stock"].get(key,0)
 return {"required":required,"shortages":shortages}

func save_game() -> bool:
 last_save_error=""
 if not save_enabled: return true
 var wrapper={"format":"PrintShopTycoonNative","schema":int(state.get("schema",3)),"state":state}
 var temp=save_path+".tmp"
 var f=FileAccess.open(temp,FileAccess.WRITE)
 if f==null: return _save_failed("The local save folder is not writable.")
 f.store_string(JSON.stringify(wrapper))
 f.flush()
 var write_error=f.get_error()
 f.close()
 if write_error!=OK: return _save_failed("The shop file could not be fully written. Check available disk space.")
 var backup=save_path+".bak"
 if FileAccess.file_exists(save_path):
  if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup)!=OK:
   return _save_failed("The previous backup is locked. Your current save has been kept.")
  if DirAccess.rename_absolute(save_path,backup)!=OK:
   return _save_failed("The current save could not be backed up. Your shop is still open.")
 var err=DirAccess.rename_absolute(temp,save_path)
 if err!=OK:
  if not FileAccess.file_exists(save_path) and FileAccess.file_exists(backup):
   DirAccess.copy_absolute(backup,save_path)
  return _save_failed("The new save could not be installed. Your shop is still open.")
 return true

func _save_failed(reason:String) -> bool:
 last_save_error=reason
 notice("Save failed: "+reason)
 return false

func has_save() -> bool:
 return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")

func backup_before_new_shop() -> bool:
 if not save_enabled or not has_save(): return true
 var source=save_path if FileAccess.file_exists(save_path) else save_path+".bak"
 var archive=save_path+".before-new-"+str(int(Time.get_unix_time_from_system()))+"-"+str(Time.get_ticks_usec())+".json"
 if DirAccess.copy_absolute(source,archive)!=OK: return _save_failed("Could not archive the previous shop. New game has not started.")
 return true

func _valid_save_state(loaded:Dictionary) -> bool:
 for key in ["cash","clock","day","location"]:
  if not loaded.get(key) is float and not loaded.get(key) is int: return false
  if not is_finite(float(loaded[key])): return false
 if not loaded.get("machines") is Dictionary or not loaded.get("workers") is Array or not loaded.get("orders") is Array or not loaded.get("stock") is Dictionary: return false
 var ids={};var owner_count=0
 for w in loaded["workers"]:
  if not w is Dictionary: return false
  for key in ["id","name","pos","path","task","manual","role","skill","wage"]:
   if not w.has(key): return false
  if not w["pos"] is Array or w["pos"].size()!=2 or not w["task"] is Dictionary or not w["path"] is Array: return false
  if ids.has(w["id"]): return false
  ids[w["id"]]=true
  if w["id"]=="owner": owner_count+=1
 if owner_count!=1: return false
 for id in loaded["machines"]:
  var m=loaded["machines"][id]
  if not m is Dictionary: return false
  for key in C.station("dtf",[0,0],[3,1],[0,1],"",0):
   if not m.has(key): return false
  if not m["pos"] is Array or m["pos"].size()!=2 or not m["size"] is Array or m["size"].size()!=2: return false
 for o in loaded["orders"]:
  if not o is Dictionary: return false
  for key in C.make_order("","transfer",1,"",1,1):
   if not o.has(key): return false
  if not o["settings"] is Dictionary or not o["recipe"] is Dictionary or not o["gang"] is Array: return false
  if not o["garments"] is Dictionary: return false
  for key in ["white","registration","laminate","cut","media","press"]:
   if not o["settings"].has(key): return false
  for key in ["quantity","art_w","art_h","film_width","sheet_length"]:
   if not o[key] is float and not o[key] is int: return false
   if not is_finite(float(o[key])) or float(o[key])<=0: return false
 for printer in ["dtf","dtf2"]:
  if loaded["machines"].has(printer) and not loaded["machines"].has("shaker2" if printer=="dtf2" else "shaker"): return false
 return true

func load_game() -> bool:
 for file in [save_path,save_path+".bak"]:
  if not FileAccess.file_exists(file): continue
  var f=FileAccess.open(file,FileAccess.READ)
  if f==null: continue
  var parser=JSON.new()
  if parser.parse(f.get_as_text())!=OK: continue
  var parsed=parser.data
  if not parsed is Dictionary or parsed.get("format","")!="PrintShopTycoonNative" or not parsed.get("state") is Dictionary: continue
  var loaded=parsed["state"]
  if not _valid_save_state(loaded): continue
  state=loaded
  var fresh=C.fresh()
  for key in fresh:
   if not state.has(key): state[key]=fresh[key]
  _ensure_marketing()
  Strategy.ensure(self)
  for o in state["orders"]: _ensure_visit(o)
  # Older saves could persist a delivery task after its payment was committed.
  for w in state["workers"]:
   var task=w.get("task",{})
   if task.is_empty(): continue
   var job=order(int(task.get("order",-1)))
   if job.is_empty() or job.get("paid",false) or job.get("stage","") in ["completed","declined","abandoned"]:
    if state["machines"].has(task.get("machine","")):
     var station=state["machines"][task["machine"]]
     if int(station["active"])==int(task.get("order",-1)): station["active"]=-1;station["elapsed"]=0.0;station["phase"]="Idle"
    w["task"]={};w["path"]=[];w["walking"]=false
  manual_input=Vector2.ZERO
  notice("Local shop restored: cash, jobs, staff, inventory, and layout.")
  return true
 notice("No valid save found. The backup is checked automatically.")
 return false

extends RefCounted
# Recurring clients and milestone contracts (1.2.0).
# Clients are named businesses with one clear preference. Relationship points
# come only from real paid deliveries of their orders. At milestones a client
# offers a contract: a short schedule of deliveries with a deposit, per-delivery
# payments and a completion bonus, all shown before acceptance. Declining is
# always free (the offer returns after a cooldown) and there are no streaks or
# daily check-ins. Every delivery is a normal order in the normal production,
# pickup, payment and save systems; contract accounting is idempotent.
const C=preload("res://scripts/catalog.gd")

const MILESTONES=[25,55,85]
const CLIENT_IDS=["maple","riverside","lakeside","hartley","northside"]
const OFFER_DAYS=2
const DECLINE_COOLDOWN=3
const MAX_ACTIVE=2
const DEPOSIT_SHARE=0.2
const CLIENTS=[
 {"id":"maple","name":"Maple Street Cafe","trait":"reliability","types":["sticker","mug","decal","transfer"],"season":"",
  "blurb":"Restocks merch on a schedule. On-time delivery matters most."},
 {"id":"riverside","name":"Riverside Art Collective","trait":"quality","types":["sticker","transfer","apparel"],"season":"Spring",
  "blurb":"Artists who notice every flaw. Pays more for flawless work."},
 {"id":"lakeside","name":"Lakeside High Boosters","trait":"volume","types":["apparel","hat","transfer","sticker"],"season":"Fall",
  "blurb":"Big seasonal team runs. Values getting every piece delivered."},
 {"id":"hartley","name":"Hartley Events & Signage","trait":"reliability","types":["banner","cnc","decal"],"season":"Summer",
  "blurb":"Event dates are fixed. Signs must arrive on time."},
 {"id":"northside","name":"Northside Rec League","trait":"volume","types":["apparel","hat","sticker","decal"],"season":"",
  "blurb":"Leagues every season. Large runs, flexible on looks."}]
const TRAITS={
 "reliability":{"title":"Reliability","rule":"On time: +12. Late: -10.","bonus":"every delivery is on time","price":1.05},
 "quality":{"title":"Quality","rule":"Satisfaction 90%+: +12. 75-89%: +4. Below 75%: -8.","bonus":"every delivery scores 90%+ satisfaction","price":1.15},
 "volume":{"title":"Volume","rule":"Every paid delivery: +10 (late: +4).","bonus":"every delivery is paid","price":0.95}}

static func enabled(s) -> bool:
 return s.state.get("rules") is Dictionary and int(s.state["rules"].get("version",0))>0

static func ensure(s) -> void:
 if not s.state.get("clients") is Dictionary: s.state["clients"]={}
 for c in CLIENTS:
  if not s.state["clients"].get(c["id"]) is Dictionary:
   s.state["clients"][c["id"]]={"rel":0,"jobs":0,"on_time":0,"milestone":0,"cooldown_until":0,"last_inquiry_day":0}
 if not s.state.get("contract_offers") is Array: s.state["contract_offers"]=[]
 if not s.state.get("contracts") is Array: s.state["contracts"]=[]
 # A damaged save entry is dropped rather than crashing the shop.
 var keys=["id","client","client_name","trait","tier","type","product","quantity","per_delivery","deposit","bonus","deliveries"]
 for list in ["contract_offers","contracts"]:
  var clean=[]
  for k in s.state[list]:
   var ok=k is Dictionary and k.get("deliveries") is Array and CLIENT_IDS.has(String(k.get("client",""))) and C.BASE_QTY.has(String(k.get("type","")))
   if ok:
    for key in keys:
     if not k.has(key): ok=false;break
   if ok and list=="contracts" and not k.has("status"): ok=false
   if ok:
    for d in k["deliveries"]:
     if not d is Dictionary or not d.has("day") or not d.has("n") or not d.has("order_id") or not d.has("paid"): ok=false;break
   if ok: clean.append(k)
  s.state[list]=clean
 if not s.state.has("contract_serial"): s.state["contract_serial"]=0

static func client(id:String) -> Dictionary:
 for c in CLIENTS:
  if c["id"]==id: return c
 return {}

static func client_state(s,id:String) -> Dictionary:
 ensure(s)
 return s.state["clients"].get(id,{})

static func next_milestone(s,id:String) -> int:
 var m=int(client_state(s,id).get("milestone",0))
 return MILESTONES[m] if m<MILESTONES.size() else -1

static func producible(s,id:String) -> Array:
 var out=[]
 for type in client(id)["types"]:
  if s.can_produce(type): out.append(type)
 return out

static func active_for(s,id:String) -> Dictionary:
 ensure(s)
 for k in s.state["contracts"]:
  if k["client"]==id and k["status"]=="active": return k
 return {}

static func active_count(s) -> int:
 ensure(s)
 var n=0
 for k in s.state["contracts"]:
  if k["status"]=="active": n+=1
 return n

static func offer_for(s,id:String) -> Dictionary:
 ensure(s)
 for o in s.state["contract_offers"]:
  if o["client"]==id: return o
 return {}

# --- Day start --------------------------------------------------------------
# One client inquiry at most per day; expired offers drop; one new offer per day
# at most; contract deliveries due today become accepted orders.
static func begin_day(s) -> void:
 if not enabled(s): return
 ensure(s)
 var day=int(s.state["day"])
 var kept=[]
 for o in s.state["contract_offers"]:
  if int(o["expires_day"])>=day: kept.append(o)
  else: s.notice("%s's contract offer expired. They will ask again later." % String(o["client_name"]))
 s.state["contract_offers"]=kept
 _create_deliveries(s,day)
 _maybe_offer(s,day)

static func client_inquiry(s,day:int,types:Array) -> Dictionary:
 # Returns {} or {"client":id,"type":type} for today's single client inquiry.
 # Clients you already work with come back first (highest relationship that has
 # not finished every tier), so relationships build instead of scattering.
 if not enabled(s): return {}
 ensure(s)
 var order=[]
 for step in CLIENTS.size(): order.append(CLIENTS[(day+step)%CLIENTS.size()])
 order.sort_custom(func(a,b):
  var ra=int(client_state(s,a["id"])["rel"])-(1000 if int(client_state(s,a["id"])["milestone"])>=MILESTONES.size() else 0)
  var rb=int(client_state(s,b["id"])["rel"])-(1000 if int(client_state(s,b["id"])["milestone"])>=MILESTONES.size() else 0)
  return ra>rb)
 for c in order:
  if not active_for(s,c["id"]).is_empty(): continue
  var open=false
  for o in s.state["orders"]:
   if String(o.get("client",""))==c["id"] and o["stage"] not in ["completed","declined","abandoned"]: open=true;break
  if open: continue
  for type in c["types"]:
   if type in types: return {"client":c["id"],"type":type}
 return {}

static func tag_inquiry(s,o:Dictionary,id:String) -> void:
 var c=client(id)
 o["customer"]=c["name"];o["client"]=id
 o["reward"]=roundi(float(o["reward"])*float(TRAITS[c["trait"]]["price"]))
 client_state(s,id)["last_inquiry_day"]=int(s.state["day"])

static func _maybe_offer(s,day:int) -> void:
 if active_count(s)+s.state["contract_offers"].size()>=MAX_ACTIVE: return
 for c in CLIENTS:
  var st=client_state(s,c["id"])
  var m=int(st["milestone"])
  if m>=MILESTONES.size() or int(st["rel"])<MILESTONES[m]: continue
  if int(st["cooldown_until"])>day or not offer_for(s,c["id"]).is_empty() or not active_for(s,c["id"]).is_empty(): continue
  var offer=build_offer(s,c["id"],m+1,day)
  if offer.is_empty(): continue
  s.state["contract_offers"].append(offer)
  s.notice("%s offers a contract. Review it in Clients + Contracts." % c["name"])
  return

static func build_offer(s,id:String,tier:int,day:int) -> Dictionary:
 var c=client(id)
 var types=producible(s,id)
 if types.is_empty(): return {}
 var type=types[0]
 # In the client's own season, prefer a product the season is boosting.
 var Customers=preload("res://scripts/shop_customers.gd")
 if Customers.active(s) and c["season"]==Customers.season(s)["name"]:
  for t in types:
   if Customers.boosted(s,t): type=t;break
 var base=int(C.BASE_QTY[type])
 var qty=roundi(base*(1.0+0.5*tier) if c["trait"]=="volume" else base*(1.0+0.25*(tier-1)))
 var count=2 if tier==1 else 3
 var per=roundi(qty*float(C.UNIT_PRICE[type])*float(TRAITS[c["trait"]]["price"]))
 var deliveries=[]
 for n in count: deliveries.append({"n":n,"day":day+1+n*2,"order_id":"","paid":false,"on_time":false,"satisfaction":-1})
 var deposit=roundi(per*count*DEPOSIT_SHARE)
 s.state["contract_serial"]=int(s.state.get("contract_serial",0))+1
 return {"id":"K%d-%s" % [int(s.state["contract_serial"]),id],"client":id,"client_name":c["name"],"trait":c["trait"],"tier":tier,"type":type,
  "product":C.make_order("x",type,qty,"",0,0)["product"],"quantity":qty,"per_delivery":per,"deposit":deposit,
  "bonus":roundi(per*count*0.08*tier),"deliveries":deliveries,"created_day":day,"expires_day":day+OFFER_DAYS,"due_clock":16.0}

# Inputs, cost and capacity risk for the FIRST delivery, from the live quote.
static func assess(s,offer:Dictionary) -> Dictionary:
 var o=C.make_order("ASSESS-"+String(offer["id"]),String(offer["type"]),int(offer["quantity"]),String(offer["client_name"]),s.now()+8.0,int(offer["per_delivery"]))
 s.assign_method(o)
 s.state["orders"].append(o)
 var index=s.state["orders"].size()-1
 var q=s.quote(index,false)
 var recipe=preload("res://scripts/shop_strategy.gd").inputs(o)
 s.state["orders"].remove_at(index)
 # Work cannot start before the delivery is created tomorrow at 8:00, but today's
 # backlog still has to clear first, so compare total queued hours with the time
 # left today plus the delivery day up to 16:00.
 var finish=float(q.get("finish",-1))
 var needed=finish-s.now()
 var available=(17.0-float(s.state["clock"]))+8.0
 var risk="BLOCKED" if finish<0 else ("ON TRACK" if needed<=available*0.85 else "AT RISK")
 return {"risk":risk,"hours":needed,"available":available,"cost":float(q.get("cost",0)),"missing":q.get("missing",{}),"inputs":recipe,"reason":String(q.get("reason",""))}

# --- Player choices -----------------------------------------------------------
static func accept(s,offer_id:String) -> bool:
 ensure(s)
 var offer={};var at=-1
 for i in s.state["contract_offers"].size():
  if s.state["contract_offers"][i]["id"]==offer_id: offer=s.state["contract_offers"][i];at=i;break
 if offer.is_empty(): s.notice("That contract offer is no longer available.");return false
 if active_count(s)>=MAX_ACTIVE: s.notice("Two contracts are already running. Finish one first.");return false
 if not s.can_produce(String(offer["type"])): s.notice("The equipment for this contract is no longer installed.");return false
 s.state["contract_offers"].remove_at(at)
 var k=offer.duplicate(true)
 k["status"]="active";k["accepted_day"]=int(s.state["day"]);k["deposit_paid"]=true;k["bonus_paid"]=false;k["rules_at_accept"]=s.state["rules"].duplicate(true)
 s.state["contracts"].append(k)
 s.state["cash"]+=int(k["deposit"])
 s.state["stats"]["deposits"]=int(s.state["stats"].get("deposits",0))+int(k["deposit"])
 s.notice("Contract with %s accepted. Deposit +$%d received; first delivery on Day %d." % [k["client_name"],int(k["deposit"]),int(k["deliveries"][0]["day"])])
 s.save_game()
 return true

static func decline(s,offer_id:String) -> bool:
 ensure(s)
 for i in s.state["contract_offers"].size():
  var o=s.state["contract_offers"][i]
  if o["id"]==offer_id:
   s.state["contract_offers"].remove_at(i)
   client_state(s,o["client"])["cooldown_until"]=int(s.state["day"])+DECLINE_COOLDOWN
   s.notice("Declined. %s keeps the relationship and may offer again after Day %d." % [o["client_name"],int(s.state["day"])+DECLINE_COOLDOWN])
   return true
 return false

static func deliveries_on(s,day:int) -> Array:
 ensure(s)
 var out=[]
 for k in s.state["contracts"]:
  if k["status"]!="active": continue
  for d in k["deliveries"]:
   if int(d["day"])==day and String(d["order_id"])=="": out.append({"contract":k["id"],"client":k["client_name"],"label":"%d %s" % [int(k["quantity"]),k["product"]],"n":int(d["n"])+1,"of":k["deliveries"].size()})
 return out

static func _create_deliveries(s,day:int) -> void:
 for k in s.state["contracts"]:
  if k["status"]!="active": continue
  for d in k["deliveries"]:
   # Idempotent: each scheduled delivery creates exactly one order. A delivery
   # whose day was missed (e.g. an old save) is created on the next day start.
   if int(d["day"])>day or String(d["order_id"])!="": continue
   var last=int(d["n"])==k["deliveries"].size()-1
   var pay=int(k["per_delivery"])-(int(k["deposit"]) if last else 0)
   var id="%s-D%d" % [k["id"],int(d["n"])+1]
   var o=C.make_order(id,String(k["type"]),int(k["quantity"]),String(k["client_name"]),s.now()+(float(k["due_clock"])-8.0),maxi(0,pay))
   s.assign_method(o)
   o["client"]=k["client"];o["contract"]={"id":k["id"],"n":int(d["n"])}
   o["base_reward"]=o["reward"];o["rules_at_accept"]=k["rules_at_accept"].duplicate(true);o["accepted_day"]=day
   o["fault_roll"]=float(absi((o["id"]+":quality").hash())%10000)/10000.0
   o["stage"]="preflight"
   s.state["orders"].append(o)
   s._ensure_visit(o);o["visit"]["status"]="production"
   d["order_id"]=id
   s.notice("Contract delivery %d/%d for %s is in your queue: %d %s due %s." % [int(d["n"])+1,k["deliveries"].size(),k["client_name"],int(k["quantity"]),k["product"],"16:00"])

# --- Outcomes ---------------------------------------------------------------
# Called once from Simulation._fulfill after payment is recorded.
static func on_paid(s,o:Dictionary,punctual:bool,satisfaction:int) -> void:
 if not o.has("client"): return
 ensure(s)
 var id=String(o["client"]);var c=client(id)
 if c.is_empty(): return
 var st=client_state(s,id)
 var gain=0
 match c["trait"]:
  "reliability": gain=12 if punctual else -10
  "quality": gain=12 if satisfaction>=90 else (4 if satisfaction>=75 else -8)
  "volume": gain=10 if punctual else 4
 st["rel"]=clampi(int(st["rel"])+gain,0,100);st["jobs"]=int(st["jobs"])+1;st["on_time"]=int(st["on_time"])+(1 if punctual else 0)
 o["client_points"]=gain
 if o.has("contract"): _settle_delivery(s,o,punctual,satisfaction)

static func _settle_delivery(s,o:Dictionary,punctual:bool,satisfaction:int) -> void:
 for k in s.state["contracts"]:
  if k["id"]!=String(o["contract"]["id"]): continue
  var d=k["deliveries"][int(o["contract"]["n"])]
  if d["paid"]: return
  d["paid"]=true;d["on_time"]=punctual;d["satisfaction"]=satisfaction
  for other in k["deliveries"]:
   if not other["paid"]: return
  if k["bonus_paid"] or k["status"]!="active": return
  var earned=true
  for other in k["deliveries"]:
   if k["trait"]=="reliability" and not other["on_time"]: earned=false
   if k["trait"]=="quality" and int(other["satisfaction"])<90: earned=false
  k["bonus_paid"]=true;k["status"]="completed";k["completed_day"]=int(s.state["day"]);k["bonus_earned"]=earned
  var st=client_state(s,k["client"])
  st["milestone"]=maxi(int(st["milestone"]),int(k["tier"]))
  if earned:
   s.state["cash"]+=int(k["bonus"])
   s.state["stats"]["sales"]+=int(k["bonus"])
   s.state["stats"]["contract_bonus"]=int(s.state["stats"].get("contract_bonus",0))+int(k["bonus"])
   s.notice("Contract complete: %s pays a $%d bonus." % [k["client_name"],int(k["bonus"])])
  else:
   s.notice("Contract complete with %s. No bonus: it needed %s." % [k["client_name"],TRAITS[k["trait"]]["bonus"]])
  return

static func summary(s,id:String) -> String:
 var st=client_state(s,id);var next=next_milestone(s,id)
 var k=active_for(s,id)
 if not k.is_empty():
  var paid=0
  for d in k["deliveries"]: paid+=1 if d["paid"] else 0
  return "Contract %d/%d delivered" % [paid,k["deliveries"].size()]
 if not offer_for(s,id).is_empty(): return "Contract offer waiting"
 if next<0: return "All contract tiers completed"
 if int(st["cooldown_until"])>int(s.state["day"]): return "May offer again after Day %d" % int(st["cooldown_until"])
 if int(st["rel"])>=next:
  if producible(s,id).is_empty(): return "Ready: needs equipment for their products"
  if active_count(s)+s.state["contract_offers"].size()>=MAX_ACTIVE: return "Ready: offers when a contract slot frees up"
  return "Ready: offers at the next day start"
 return "Next contract at %d (now %d)" % [next,int(st["rel"])]

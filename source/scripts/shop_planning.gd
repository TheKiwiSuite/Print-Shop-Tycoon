extends RefCounted
# End-of-day planning and the daily focus (1.2.0).
# The plan reads the authoritative simulation (capacity board, stock, machines,
# day-close formulas). A focus is chosen for the NEXT day, applies only to that
# day's production and new inquiries, and never changes accepted terms.
# Older-economy shops (rules version 0) see the plan but focus has no effect.
const C=preload("res://scripts/catalog.gd")
const Strategy=preload("res://scripts/shop_strategy.gd")
const Ops=preload("res://scripts/shop_operations.gd")

const FOCUS_ORDER=["balanced","volume","quality","growth","recovery"]
const FOCUS={
 "balanced":{"title":"Balanced","speed":1.0,"extra_inquiries":0,"max_inquiries":6,"patience":1.0,"cost":0,"satisfaction":0,"defect_guard":false,"wear":0,"repair":0,
  "effects":"No changes. Production, inquiries and wear run normally.","tradeoff":"No bonus, no cost."},
 "volume":{"title":"Volume","speed":0.9,"extra_inquiries":1,"max_inquiries":6,"patience":1.0,"cost":0,"satisfaction":0,"defect_guard":false,"wear":2,"repair":0,
  "effects":"Production 10% faster and one extra inquiry today (inquiry cap still 6).","tradeoff":"Each finished print run wears its station 2% more."},
 "quality":{"title":"Premium quality","speed":1.1,"extra_inquiries":0,"max_inquiries":6,"patience":1.0,"cost":0,"satisfaction":5,"defect_guard":true,"wear":0,"repair":0,
  "effects":"No random alignment defects today, +5 customer satisfaction on deliveries (better reviews and tips).","tradeoff":"Production 10% slower. Worn-machine faults can still happen."},
 "growth":{"title":"Customer growth","speed":1.0,"extra_inquiries":1,"max_inquiries":6,"patience":1.25,"cost":40,"satisfaction":0,"defect_guard":false,"wear":0,"repair":0,
  "effects":"One extra inquiry today and new customers wait 25% longer before leaving.","tradeoff":"$40 local outreach, charged when the day starts (shown as marketing)."},
 "recovery":{"title":"Recovery","speed":1.0,"extra_inquiries":0,"max_inquiries":2,"patience":1.0,"cost":0,"satisfaction":0,"defect_guard":false,"wear":0,"repair":10,
  "effects":"Staff tidy and tune: every station gains 10% condition when the day starts. Time to clear backlog.","tradeoff":"At most 2 open inquiries today, so fewer new jobs arrive."}}

static func ensure(s) -> void:
 if not s.state.has("next_focus") or not FOCUS.has(String(s.state["next_focus"])): s.state["next_focus"]="balanced"
 if not s.state.get("focus") is Dictionary: s.state["focus"]={"id":"balanced","day":int(s.state.get("day",1))}
 if not s.state.get("focus_log") is Array: s.state["focus_log"]=[]

static func enabled(s) -> bool:
 return s.state.get("rules") is Dictionary and int(s.state["rules"].get("version",0))>0

# The focus in effect today (balanced when disabled or for a stale day).
static func today(s) -> Dictionary:
 if not enabled(s): return FOCUS["balanced"]
 var f=s.state.get("focus",{})
 if not f is Dictionary or int(f.get("day",-1))!=int(s.state.get("day",1)): return FOCUS["balanced"]
 return FOCUS.get(String(f.get("id","balanced")),FOCUS["balanced"])

static func today_id(s) -> String:
 if not enabled(s): return "balanced"
 var f=s.state.get("focus",{})
 if not f is Dictionary or int(f.get("day",-1))!=int(s.state.get("day",1)): return "balanced"
 return String(f.get("id","balanced"))

static func focus_speed(s) -> float:
 return float(today(s)["speed"])

static func choose(s,id:String) -> bool:
 ensure(s)
 if not FOCUS.has(id): return false
 if not enabled(s) and id!="balanced":
  s.notice("Daily focus needs a shop on the current rules (choose rules in Settings > Difficulty).");return false
 s.state["next_focus"]=id
 return true

# Called by next_day() after stats reset and before inquiries are generated.
static func begin_day(s) -> void:
 ensure(s)
 var id=String(s.state["next_focus"]) if enabled(s) else "balanced"
 var f=FOCUS[id]
 var applied={"cost":0,"repair":0}
 if int(f["cost"])>0:
  if float(s.state["cash"])>=float(f["cost"]):
   s.state["cash"]-=int(f["cost"])
   s.state["stats"]["marketing"]=int(s.state["stats"].get("marketing",0))+int(f["cost"])
   applied["cost"]=int(f["cost"])
  else:
   id="balanced";f=FOCUS[id]
   s.notice("Not enough cash for Customer growth outreach; today runs Balanced.")
 if int(f["repair"])>0:
  for mid in s.state["machines"]:
   var m=s.state["machines"][mid]
   if m.has("condition") and not m.get("broken",false):
    var before=float(m["condition"]);m["condition"]=minf(100.0,before+float(f["repair"]))
    applied["repair"]+=1 if m["condition"]>before else 0
 s.state["focus"]={"id":id,"day":int(s.state["day"]),"applied":applied}
 s.state["stats"]["focus"]=id
 s.state["stats"]["focus_cost"]=applied["cost"]

static func inquiry_limit(s) -> int:
 return int(today(s)["max_inquiries"])

static func extra_inquiries(s) -> int:
 return int(today(s)["extra_inquiries"])

static func patience(s) -> float:
 return float(today(s)["patience"])

static func satisfaction_bonus(s) -> int:
 return int(today(s)["satisfaction"])

static func defect_guard(s) -> bool:
 return bool(today(s)["defect_guard"])

static func extra_wear(s) -> int:
 return int(today(s)["wear"])

# Recorded at day close so the next plan can show what the focus actually did.
static func close_day(s,report:Dictionary) -> void:
 ensure(s)
 var st=report["stats"]
 var entry={"day":int(report["day"]),"focus":today_id(s),"delivered":int(st.get("delivered",0)),"on_time":int(st.get("on_time",0)),
  "quality":(float(st.get("quality",0))/maxf(1,float(st.get("delivered",0)))) if int(st.get("delivered",0))>0 else -1.0,
  "inquiries":int(st.get("inquiries",0)),"cost":int(st.get("focus_cost",0)),"net":float(report["net"]),
  "repaired":int(s.state.get("focus",{}).get("applied",{}).get("repair",0))}
 var log=s.state["focus_log"]
 if not log.is_empty() and int(log[0].get("day",-1))==entry["day"]: log[0]=entry
 else: log.push_front(entry)
 while log.size()>14: log.pop_back()

static func last_result(s) -> Dictionary:
 ensure(s)
 return s.state["focus_log"][0] if not s.state["focus_log"].is_empty() else {}

static func money(v:float) -> String:
 return ("-$%.0f" if v<0 else "$%.0f") % absf(v)

static func result_text(entry:Dictionary) -> String:
 if entry.is_empty(): return "No focus results yet. Results appear after a day closes."
 var q="no deliveries" if float(entry["quality"])<0 else "quality %.0f%%" % float(entry["quality"])
 var extra=""
 if int(entry["cost"])>0: extra+=" / outreach $%d" % int(entry["cost"])
 if int(entry["repaired"])>0: extra+=" / %d stations tuned" % int(entry["repaired"])
 return "Day %d actual (%s): %d delivered, %d on time, %s, %d new inquiries, operating profit %s%s." % [int(entry["day"]),FOCUS.get(String(entry["focus"]),FOCUS["balanced"])["title"],int(entry["delivered"]),int(entry["on_time"]),q,int(entry["inquiries"]),money(float(entry["net"])),extra]

# ---------------------------------------------------------------------------
# Tomorrow's plan, computed from the live simulation. Values are labelled:
# "actual" (already fixed by today's close) or "estimate" (forecast).
static func plan(s) -> Dictionary:
 ensure(s)
 var board=Strategy.board(s)
 var report=s.state.get("report",{})
 var due_now=0.0
 if not report.is_empty() and not s.state.get("report_applied",false):
  var st=report["stats"]
  due_now=float(st["wages"])+float(st["overhead"])+float(st.get("loan_payment",0))+float(st.get("equipment_finance",0))
 var wages=0.0
 for w in s.state["workers"]: wages+=float(w["wage"])
 var overhead=s.daily_overhead()
 var loan_after=maxi(0,int(s.state.get("loan_remaining",0))-(int(report["stats"].get("loan_payment",0)) if not report.is_empty() and not s.state.get("report_applied",false) else 0))
 var next_close=wages+overhead+mini(50,loan_after)+Ops.daily_debt(s)
 var focus_cost=float(FOCUS[String(s.state["next_focus"])]["cost"]) if enabled(s) else 0.0
 # Committed jobs: accepted work from the capacity board (estimates).
 var jobs=[]
 for row in board["rows"]:
  var o=s.order(int(row["index"]))
  if o["stage"]=="intake": continue
  jobs.append({"index":int(row["index"]),"label":"%d %s" % [int(o["quantity"]),String(o["product"])],"customer":String(o["customer"]),"due":float(o["due"]),"finish":float(row["finish"]),"risk":String(row["risk"]),"station":String(row["station"]),"contract":o.has("contract")})
 # Contract deliveries that will be created when tomorrow starts.
 var scheduled=preload("res://scripts/shop_contracts.gd").deliveries_on(s,int(s.state["day"])+1)
 # Stock: reserved inputs against on-hand plus deliveries in transit.
 var short={};var short_cost=0.0
 for key in board["required"]:
  var incoming=0
  for d in s.state["deliveries"]: incoming+=int(d["items"].get(key,0))
  var gap=int(board["required"][key])-int(board["on_hand"].get(key,0))-incoming
  if gap>0:
   short[key]=gap
   short_cost+=gap*(C.blank_cost(key.trim_prefix("garment:")) if key.begins_with("garment:") else float(C.PRICES.get(key,1.0)))
 # Maintenance: stations below the 65% service line, broken, or close to it.
 var service=[]
 for id in s.state["machines"]:
  var m=s.state["machines"][id]
  if not m.has("condition") or not Ops.SERVICE.has(m["kind"]): continue
  if m.get("broken",false): service.append({"id":id,"title":String(m.get("title",id)),"condition":float(m["condition"]),"status":"Fault: service before use"})
  elif float(m["condition"])<65: service.append({"id":id,"title":String(m.get("title",id)),"condition":float(m["condition"]),"status":"Overdue: 15% slower"})
  elif float(m["condition"])<75: service.append({"id":id,"title":String(m.get("title",id)),"condition":float(m["condition"]),"status":"Due soon"})
 service.sort_custom(func(a,b):return a["condition"]<b["condition"])
 # Bottleneck: the station the most committed jobs are waiting on.
 var queue={};var top="";var most=0
 for j in jobs:
  if j["station"]=="" : continue
  queue[j["station"]]=int(queue.get(j["station"],0))+1
  if queue[j["station"]]>most: most=queue[j["station"]];top=j["station"]
 var at_risk=0
 for j in jobs:
  if j["risk"] in ["AT RISK","OVERDUE","BLOCKED"]: at_risk+=1
 return {"due_now":due_now,"next_close":next_close,"focus_cost":focus_cost,"wages":wages,"overhead":overhead,"cash":float(s.state["cash"]),
  "cash_after_start":float(s.state["cash"])-due_now-focus_cost,"jobs":jobs,"scheduled":scheduled,"short":short,"short_cost":ceilf(short_cost),
  "service":service,"bottleneck":top,"bottleneck_jobs":most,"at_risk":at_risk,"receipts":float(board.get("receipts",0))}

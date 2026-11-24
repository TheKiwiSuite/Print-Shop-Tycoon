extends RefCounted
# Shop level, goals and awards. Paid jobs and finished goals earn experience (XP);
# levels unlock equipment in new careers; finishing every goal is the ending,
# after which the shop keeps running. Authored game rules, pure state only.
const C=preload("res://scripts/catalog.gd")

# XP needed to reach level index+1.
const LEVEL_XP=[0,60,160,320,540,820,1160,1560,2020,2540]
const LEVEL_TITLES=["Garage Crafter","Side Hustle","Local Favorite","Real Print Shop","Busy Print Shop","Production House","Regional Name","Print Powerhouse","Industry Leader","Print Shop Tycoon"]
# Equipment a new career unlocks by level. Older shops and the demo are not gated.
const UNLOCK_LEVEL={"sticker":2,"dtfmini":3,"mug":3,"dtf":5,"embroidery":5,"banner":6,"cnc":7,"dock":7}
const UNLOCK_NAMES={"sticker":"Sticker print / cut station","dtfmini":"Desktop DTF kit","mug":"Mug + tumbler press","dtf":"Full DTF printer + shaker line","embroidery":"Embroidery machine","banner":"Banner printer","cnc":"CNC flatbed cutter","dock":"Shipping dock"}
const XP_JOB=20
const XP_ON_TIME=10
const XP_QUALITY=5
const XP_AWARD=25

const GOALS=[
 {"id":"first_sale","title":"Make your first sale","hint":"Finish one job and hand it to the customer.","kind":"jobs","need":1,"xp":40},
 {"id":"jobs5","title":"Deliver 5 paid jobs","hint":"Keep the cutter and heat press busy.","kind":"jobs","need":5,"xp":60},
 {"id":"helper","title":"Hire your first helper","hint":"Staff + Upgrades. A garage fits you plus one.","kind":"team","need":2,"xp":50},
 {"id":"dtfmini","title":"Upgrade to DTF printing","hint":"Buy the desktop DTF kit in Add Equipment.","kind":"dtf","xp":80},
 {"id":"storefront","title":"Move out of the garage","hint":"Shop Growth: lease a storefront at shop level 4.","kind":"premises","need":1,"xp":100},
 {"id":"cash3k","title":"Save $3,000","hint":"Cash on hand after bills.","kind":"cash","need":3000,"xp":60},
 {"id":"premises","title":"Move into the warehouse","hint":"Shop Growth lists what the warehouse needs.","kind":"location","need":2,"xp":120},
 {"id":"jobs25","title":"Deliver 25 paid jobs","hint":"Repeat customers and campaigns help.","kind":"jobs","need":25,"xp":100},
 {"id":"dtf","title":"Install the full DTF line","hint":"Printer plus shaker: your fastest transfers.","kind":"own","what":"dtf","xp":120},
 {"id":"trust80","title":"Reach 80% customer trust","hint":"Deliver on time and keep quality high.","kind":"trust","need":80,"xp":100},
 {"id":"fitout","title":"Complete the industrial fit-out","hint":"Shop Growth, after moving premises.","kind":"flag","what":"fit_out","xp":120},
 {"id":"team4","title":"Build a team of four","hint":"The warehouse fits four people.","kind":"team","need":4,"xp":80},
 {"id":"jobs50","title":"Deliver 50 paid jobs","hint":"A real production shop now.","kind":"jobs","need":50,"xp":150},
 {"id":"cash15k","title":"Save $15,000","hint":"Nearly there.","kind":"cash","need":15000,"xp":150},
 {"id":"factory","title":"Open the print factory","hint":"Shop Growth: the production annex makes it a factory.","kind":"flag","what":"production_annex","xp":150}]

const AWARDS=[
 {"id":"streak10","title":"Right on Time","text":"10 on-time deliveries in a row","kind":"stat","what":"best_streak","need":10},
 {"id":"clean15","title":"No Do-Overs","text":"15 jobs in a row without a reprint","kind":"stat","what":"best_clean","need":15},
 {"id":"trust95","title":"Five-Star Shop","text":"Reach 95% customer trust","kind":"trust","need":95},
 {"id":"htv100","title":"Weeding Wizard","text":"Press 100 vinyl shirts","kind":"stat","what":"htv_shirts","need":100},
 {"id":"shirts250","title":"Shirt Factory","text":"Deliver 250 shirts","kind":"stat","what":"shirts","need":250},
 {"id":"transfers300","title":"Transfer Titan","text":"Deliver 300 DTF transfers","kind":"stat","what":"transfers","need":300},
 {"id":"stickers1000","title":"Sticker Storm","text":"Deliver 1,000 stickers","kind":"stat","what":"stickers","need":1000},
 {"id":"decals300","title":"Decal Dealer","text":"Deliver 300 vinyl decals","kind":"stat","what":"decals","need":300},
 {"id":"hoodies60","title":"Cozy Season","text":"Deliver 60 hoodies","kind":"stat","what":"hoodies","need":60},
 {"id":"mugs200","title":"Mug Shot","text":"Deliver 200 printed mugs","kind":"stat","what":"mugs","need":200},
 {"id":"hats100","title":"Hat Trick","text":"Deliver 100 embroidered hats","kind":"stat","what":"hats","need":100},
 {"id":"banners10","title":"Go Big","text":"Deliver 10 banners","kind":"stat","what":"banners","need":10},
 {"id":"signs20","title":"Sign Maker","text":"Deliver 20 routed signs","kind":"stat","what":"signs","need":20},
 {"id":"rush5","title":"Rush Hero","text":"Finish 5 rush jobs","kind":"stat","what":"rush","need":5},
 {"id":"regulars10","title":"Regulars","text":"Serve 10 returning customers","kind":"stat","what":"returning","need":10},
 {"id":"rating45","title":"Loved Locally","text":"Average 4.5+ stars from 20+ reviews","kind":"rating","need":45},
 {"id":"merch100","title":"Merch Maker","text":"Sell 100 items of your own merch","kind":"merch","need":100},
 {"id":"rival","title":"Top Shop in Town","text":"Beat Quick Ink Co. for 5 days in a row","kind":"rival","need":1},
 {"id":"team9","title":"Dream Team","text":"Build a full team of nine","kind":"team","need":9},
 {"id":"decor5","title":"Make It Yours","text":"Place 5 decorations","kind":"decor","need":5},
 {"id":"bigday","title":"Big Day","text":"Earn $1,500 profit in one day","kind":"best_profit","need":1500},
 {"id":"day30","title":"Open 30 Days","text":"Keep the shop open for 30 days","kind":"day","need":30},
 {"id":"cash50k","title":"Stacked","text":"Hold $50,000 in cash","kind":"cash","need":50000},
 {"id":"annex","title":"Room to Grow","text":"Add the production annex","kind":"flag","what":"production_annex"}]

const STATS=["jobs","revenue","shirts","htv_shirts","hoodies","totes","transfers","stickers","decals","mugs","hats","banners","signs","rush","returning","streak","best_streak","clean","best_clean"]

static func ensure(s) -> Dictionary:
 if s.state.get("progress") is Dictionary and s.state["progress"].has("xp"):
  var existing=s.state["progress"]
  for key in STATS:
   if not existing["stats"].has(key): existing["stats"][key]=0
  return existing
 var p={"xp":0,"level_seen":1,"goals":[],"awards":[],"stats":{},"events":[],"ending_seen":false}
 for key in STATS: p["stats"][key]=0
 s.state["progress"]=p
 _catch_up(s,p)
 return p

# A shop that already has history (older save, demo shop) is credited quietly:
# no pop-ups for things that happened before levels existed.
static func _catch_up(s,p:Dictionary) -> void:
 var st=p["stats"]
 for o in s.state["orders"]:
  if not o.get("paid",false): continue
  _count(st,o)
 st["jobs"]=maxi(int(st["jobs"]),int(s.state.get("completed",0)))
 p["xp"]=int(st["jobs"])*25
 for goal in GOALS:
  if _met(s,p,goal): p["goals"].append(goal["id"]);p["xp"]+=int(goal["xp"])
 for award in AWARDS:
  if _met(s,p,award): p["awards"].append(award["id"]);p["xp"]+=XP_AWARD
 # Careers begun under the earlier sales-count unlocks keep what they had earned.
 if s.state.get("starter_path",false):
  if int(s.state.get("completed",0))>=12: p["xp"]=maxi(p["xp"],LEVEL_XP[4])
  elif int(s.state.get("completed",0))>=5: p["xp"]=maxi(p["xp"],LEVEL_XP[2])
 p["level_seen"]=level_for(p["xp"])
 p["ending_seen"]=p["goals"].size()==GOALS.size()

static func level_for(xp:int) -> int:
 var result=1
 for i in LEVEL_XP.size():
  if xp>=int(LEVEL_XP[i]): result=i+1
 return result

static func level(s) -> int:
 return level_for(int(ensure(s)["xp"]))

static func title(s) -> String:
 return LEVEL_TITLES[level(s)-1]

# Level, XP and how far along the bar to the next level is.
static func span(s) -> Dictionary:
 var xp=int(ensure(s)["xp"]);var lv=level_for(xp)
 var low=int(LEVEL_XP[lv-1])
 if lv>=LEVEL_XP.size(): return {"level":lv,"xp":xp,"floor":low,"next":low,"fraction":1.0,"max":true}
 var high=int(LEVEL_XP[lv])
 return {"level":lv,"xp":xp,"floor":low,"next":high,"fraction":clampf(float(xp-low)/float(high-low),0.0,1.0),"max":false}

static func locked(s,id:String) -> bool:
 return s.state.get("starter_path",false) and UNLOCK_LEVEL.has(id) and level(s)<int(UNLOCK_LEVEL[id])

static func lock_reason(s,id:String) -> String:
 return "Unlocks at shop level %d (you are level %d). Paid jobs and goals earn XP." % [int(UNLOCK_LEVEL.get(id,1)),level(s)]

static func unlocks_at(lv:int) -> Array:
 var names=[]
 for id in UNLOCK_LEVEL:
  if int(UNLOCK_LEVEL[id])==lv: names.append(UNLOCK_NAMES[id])
 return names

static func _count(st:Dictionary,o:Dictionary) -> void:
 var q=int(o.get("quantity",0))
 st["revenue"]=int(st["revenue"])+int(o.get("payment",0))
 match String(o.get("type","")):
  "apparel":
   var blank=C.blank_of(o)
   if blank=="hoodie": st["hoodies"]=int(st["hoodies"])+q
   elif blank=="tote": st["totes"]=int(st["totes"])+q
   else:
    st["shirts"]=int(st["shirts"])+q
    if C.is_htv(o): st["htv_shirts"]=int(st["htv_shirts"])+q
  "transfer": st["transfers"]=int(st["transfers"])+q
  "sticker": st["stickers"]=int(st["stickers"])+q
  "decal": st["decals"]=int(st["decals"])+q
  "mug": st["mugs"]=int(st["mugs"])+q
  "hat": st["hats"]=int(st["hats"])+q
  "banner": st["banners"]=int(st["banners"])+q
  "cnc": st["signs"]=int(st["signs"])+q
 if o.get("rush",false): st["rush"]=int(st["rush"])+1
 if o.get("returning",false): st["returning"]=int(st["returning"])+1

# Called once when a customer pays for a job.
static func paid(s,o:Dictionary,punctual:bool) -> void:
 var p=ensure(s);var st=p["stats"]
 st["jobs"]=int(st["jobs"])+1
 _count(st,o)
 st["streak"]=int(st["streak"])+1 if punctual else 0
 st["best_streak"]=maxi(int(st["best_streak"]),int(st["streak"]))
 var clean=int(o.get("reprints",0))==0 and not o.get("quality_accepted",false)
 st["clean"]=int(st["clean"])+1 if clean else 0
 st["best_clean"]=maxi(int(st["best_clean"]),int(st["clean"]))
 var gain=XP_JOB+(XP_ON_TIME if punctual else 0)+(XP_QUALITY if int(o.get("quality",0))>=100 and not o.get("quality_accepted",false) else 0)
 _add_xp(s,p,gain)
 refresh(s)

static func _add_xp(s,p:Dictionary,amount:int) -> void:
 p["xp"]=int(p["xp"])+amount
 var now=level_for(int(p["xp"]))
 while int(p["level_seen"])<now:
  p["level_seen"]=int(p["level_seen"])+1
  var lv=int(p["level_seen"])
  _event(p,{"kind":"level","level":lv,"title":LEVEL_TITLES[lv-1],"unlocks":unlocks_at(lv) if s.state.get("starter_path",false) else []})

static func _event(p:Dictionary,event:Dictionary) -> void:
 p["events"].append(event)
 while p["events"].size()>24: p["events"].pop_front()

static func _value(s,p:Dictionary,item:Dictionary) -> float:
 match String(item["kind"]):
  "jobs": return float(p["stats"]["jobs"])
  "team": return float(s.state["workers"].size())
  "cash": return float(s.state["cash"])
  "trust": return float(s.state["reputation"])
  "location": return float(s.state["location"])
  "premises": return float(s.PREMISES.find(s.premises()))
  "day": return float(s.state["day"])
  "best_profit": return float(s.state.get("best_profit",0))
  "rating": return 0.0 if int(s.state.get("review_count",0))<20 else floorf(float(s.state.get("review_total",0))*10.0/float(s.state["review_count"]))
  "decor": return float(s.state.get("style",{}).get("decor",[]).size())
  "merch": return float(s.state.get("merch",{}).get("sold_total",0))
  "rival": return 1.0 if s.state.get("rival",{}).get("beaten",false) else 0.0
  "stat": return float(p["stats"].get(item["what"],0))
  "own": return 1.0 if s.state["machines"].has(item["what"]) else 0.0
  "dtf": return 1.0 if s.state["machines"].has("dtfmini") or s.state["machines"].has("dtf") else 0.0
  "flag": return 1.0 if s.state.get(item["what"],false) else 0.0
 return 0.0

static func _met(s,p:Dictionary,item:Dictionary) -> bool:
 return _value(s,p,item)>=float(item.get("need",1))

# Checks goals and awards against the shop as it is now. Safe to call often.
static func refresh(s) -> void:
 var p=ensure(s)
 for goal in GOALS:
  if goal["id"] in p["goals"] or not _met(s,p,goal): continue
  p["goals"].append(goal["id"])
  _event(p,{"kind":"goal","title":goal["title"],"xp":int(goal["xp"])})
  _add_xp(s,p,int(goal["xp"]))
 for award in AWARDS:
  if award["id"] in p["awards"] or not _met(s,p,award): continue
  p["awards"].append(award["id"])
  _event(p,{"kind":"award","title":award["title"],"xp":XP_AWARD})
  _add_xp(s,p,XP_AWARD)
 if not p["ending_seen"] and p["goals"].size()==GOALS.size():
  p["ending_seen"]=true
  _event(p,{"kind":"ending"})

static func pop_events(s) -> Array:
 var p=ensure(s)
 var events=p["events"].duplicate(true)
 p["events"].clear()
 return events

static func goals(s) -> Array:
 var p=ensure(s);var rows=[]
 for goal in GOALS:
  var need=float(goal.get("need",1));var value=minf(_value(s,p,goal),need)
  rows.append({"id":goal["id"],"title":goal["title"],"hint":goal["hint"],"xp":int(goal["xp"]),"done":goal["id"] in p["goals"],"value":value,"need":need,"money":goal["kind"]=="cash"})
 return rows

static func next_goal(s) -> Dictionary:
 for row in goals(s):
  if not row["done"]: return row
 return {}

static func awards(s) -> Array:
 var p=ensure(s);var rows=[]
 for award in AWARDS:
  var need=float(award.get("need",1))
  rows.append({"id":award["id"],"title":award["title"],"text":award["text"],"done":award["id"] in p["awards"],"value":minf(_value(s,p,award),need),"need":need})
 return rows

static func progress_text(row:Dictionary) -> String:
 if row["done"]: return "Done"
 if float(row["need"])<=1.0: return "Not yet"
 if row.get("money",false): return "$%d / $%d" % [int(row["value"]),int(row["need"])]
 return "%d / %d" % [int(row["value"]),int(row["need"])]

extends RefCounted
# Staff personalities and the rival shop across town (new careers only).
const Customers=preload("res://scripts/shop_customers.gd")
const Progress=preload("res://scripts/shop_progress.gd")

# Each hire rolls a personality: how fast they work and what they ask to be paid.
const TRAITS={
 "Speedy":{"speed":1.15,"wage":52,"line":"Works fast and asks a bit more pay."},
 "Steady":{"speed":1.0,"wage":45,"line":"Reliable, no surprises."},
 "Thrifty":{"speed":0.94,"wage":38,"line":"A little slower, happy with less pay."},
 "Natural":{"speed":1.08,"wage":45,"line":"Picked it up quickly. A great find."}}
const TRAIT_ORDER=["Steady","Speedy","Thrifty","Natural","Steady","Thrifty","Speedy"]

const RIVAL_NAME="Quick Ink Co."
const RIVAL_DAY=8
const RIVAL_START=3.6
const RIVAL_MAX=4.6
const RIVAL_GROWTH=0.05
const BEAT_DAYS=5

static func active(s) -> bool:
 return bool(s.state.get("starter_path",false))

static func roll_trait(s) -> String:
 return TRAIT_ORDER[int(s.state.get("next_worker",1))%TRAIT_ORDER.size()]

static func apply_trait(s,w:Dictionary) -> void:
 if not active(s) or w["id"]=="owner": return
 var t=roll_trait(s)
 w["trait"]=t;w["wage"]=int(TRAITS[t]["wage"])
 s.notice("%s is %s: %s ($%d a day)" % [String(w["name"]),t,TRAITS[t]["line"],int(w["wage"])])

static func speed(w:Dictionary) -> float:
 return float(TRAITS.get(String(w.get("trait","")),{"speed":1.0})["speed"])

# --- Rival shop ---
static func rival(s) -> Dictionary:
 if not active(s) or int(s.state["day"])<RIVAL_DAY: return {}
 if not s.state.get("rival") is Dictionary:
  s.state["rival"]={"name":RIVAL_NAME,"rating":RIVAL_START,"streak":0,"beaten":false,"lost":0,"lost_today":0}
 return s.state["rival"]

static func ahead(s) -> bool:
 var r=rival(s)
 if r.is_empty(): return true
 return Customers.review_count(s)>=5 and Customers.rating(s)>float(r["rating"])

# How many of today's inquiries the rival takes before they reach you.
static func steals(s) -> int:
 var r=rival(s)
 if r.is_empty() or r["beaten"] or ahead(s): return 0
 return 1

# Called once at the start of each day, before inquiries arrive.
static func new_day(s) -> void:
 var r=rival(s)
 if r.is_empty(): return
 if int(s.state["day"])==RIVAL_DAY and int(r.get("announced",0))==0:
  r["announced"]=1
  s.notice("%s opened across town. Keep your star rating above theirs to win the customers." % RIVAL_NAME)
 if r["beaten"]: return
 r["rating"]=minf(RIVAL_MAX,float(r["rating"])+RIVAL_GROWTH)
 r["streak"]=int(r["streak"])+1 if ahead(s) else 0
 if int(r["streak"])>=BEAT_DAYS:
  r["beaten"]=true
  s.notice("You are the top print shop in town! %s can't keep up." % RIVAL_NAME)
  Progress.refresh(s)

static func note_lost(s,n:int) -> void:
 var r=rival(s)
 if r.is_empty(): return
 r["lost_today"]=n;r["lost"]=int(r["lost"])+n
 if n>0: s.notice("%s won one of today's customers. Raise your rating above ★ %.1f." % [RIVAL_NAME,float(r["rating"])])

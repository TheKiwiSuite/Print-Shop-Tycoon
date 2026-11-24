extends RefCounted
# Customers who feel alive: star reviews, regulars and a seasonal calendar.
# These rules apply to careers started on the starter path (v0.5.1 and later);
# the demo and older shops keep their previous economy. Pure state, no drawing.
const C=preload("res://scripts/catalog.gd")

const SEASON_DAYS=7
const SEASONS=[
 {"name":"Spring","boost":["decal","sticker","transfer"],"note":"Spring markets: decals, stickers and transfers sell well."},
 {"name":"Summer","boost":["apparel","banner","decal"],"note":"Summer events: tees, banners and car decals are in demand."},
 {"name":"Fall","boost":["apparel","hat","transfer"],"note":"Back to school and game days: team shirts, hoodies and hats."},
 {"name":"Winter","boost":["mug","hat","apparel"],"note":"Holiday gifts: mugs, hats and hoodies fly off the shelf."}]
const SEASON_BONUS=1.15
const REGULAR_VISITS=3
const REGULAR_TIP=0.10
const REGULAR_PATIENCE=1.5
const REVIEW_LIMIT=40

static func active(s) -> bool:
 return s.state.get("starter_path",false)

static func season_index(day:int) -> int:
 return int(floor(float(maxi(1,day)-1)/SEASON_DAYS))%SEASONS.size()

static func season(s) -> Dictionary:
 return SEASONS[season_index(int(s.state["day"]))]

static func boosted(s,type:String) -> bool:
 return active(s) and type in season(s)["boost"]

# Seasonal demand pays a little more for the products in season.
static func seasonal_reward(s,type:String,reward:int) -> int:
 return roundi(reward*SEASON_BONUS) if boosted(s,type) else reward

static func visits(s,customer:String) -> int:
 return int(s.state.get("customers",{}).get(customer,0))

# A customer becomes a regular after REGULAR_VISITS paid jobs.
static func is_regular(s,customer:String) -> bool:
 return active(s) and visits(s,customer)>=REGULAR_VISITS

static func tip(s,o:Dictionary,reward:int,satisfaction:int) -> int:
 if not is_regular(s,String(o["customer"])) or satisfaction<70: return 0
 return roundi(reward*REGULAR_TIP)

static func patience_scale(s,customer:String) -> float:
 return REGULAR_PATIENCE if is_regular(s,customer) else 1.0

static func stars_for(satisfaction:int,punctual:bool) -> int:
 var stars=1
 if satisfaction>=95: stars=5
 elif satisfaction>=82: stars=4
 elif satisfaction>=65: stars=3
 elif satisfaction>=45: stars=2
 if not punctual: stars=mini(stars,4)
 return stars

const COMMENTS={
 5:["Perfect, exactly what we wanted!","Fast, friendly and the prints look amazing.","Our new go-to print shop.","Crisp colors and right on time.","Everyone loved them. Ordering again!"],
 4:["Great work, would order again.","Looks good and fairly priced.","Nice quality. A little wait, but worth it.","Solid job, happy customer."],
 3:["It was okay. Took a while.","Decent prints, nothing special.","Fine, but I expected it sooner."],
 2:["Late, and a few pieces looked off.","Not what I hoped for.","Took too long. Might try somewhere else."],
 1:["Very late and the quality was poor.","Disappointed with this order."]}

static func comment_for(stars:int,seed:String) -> String:
 var options=COMMENTS[clampi(stars,1,5)]
 return options[absi(seed.hash())%options.size()]

# Called once when a customer pays. Returns the review that was left.
static func on_paid(s,o:Dictionary,punctual:bool,satisfaction:int) -> Dictionary:
 if not active(s): return {}
 var stars=stars_for(satisfaction,punctual)
 var review={"customer":String(o["customer"]),"stars":stars,"text":comment_for(stars,String(o["id"])),"product":String(o["product"]),"day":int(s.state["day"]),"regular":is_regular(s,String(o["customer"]))}
 if not s.state.get("reviews") is Array: s.state["reviews"]=[]
 s.state["reviews"].push_front(review)
 while s.state["reviews"].size()>REVIEW_LIMIT: s.state["reviews"].pop_back()
 s.state["review_count"]=int(s.state.get("review_count",0))+1
 s.state["review_total"]=int(s.state.get("review_total",0))+stars
 o["review"]=review
 return review

static func rating(s) -> float:
 var count=int(s.state.get("review_count",0))
 return 0.0 if count==0 else float(s.state.get("review_total",0))/count

static func review_count(s) -> int:
 return int(s.state.get("review_count",0))

static func reviews(s) -> Array:
 return s.state.get("reviews",[]) if s.state.get("reviews") is Array else []

static func regulars(s) -> Array:
 var names=[]
 for name in s.state.get("customers",{}):
  if int(s.state["customers"][name])>=REGULAR_VISITS: names.append(name)
 names.sort()
 return names

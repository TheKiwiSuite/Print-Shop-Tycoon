extends RefCounted
# Your own merch line: designs, batches printed on your own machines, a weekly
# trend, an online store that sells stock each day and a weekend craft market.
# Authored game rules; pure state, no drawing.
const C=preload("res://scripts/catalog.gd")
const Customers=preload("res://scripts/shop_customers.gd")
const Progress=preload("res://scripts/shop_progress.gd")

const THEMES=["Retro sunset","Cute cats","Local pride","Funny quotes","Plant parent","Game day","Spooky season","Holiday cheer"]
# Product kinds a design can be printed as, and how each one sells.
const KINDS={
 "tee":{"type":"apparel","label":"Tee","batch":12,"price":22,"demand":3.0,"machine":"heat"},
 "sticker":{"type":"sticker","label":"Sticker pack","batch":48,"price":4,"demand":12.0,"machine":"sticker"},
 "decal":{"type":"decal","label":"Decal","batch":24,"price":5,"demand":6.0,"machine":"cutter"},
 "mug":{"type":"mug","label":"Mug","batch":12,"price":15,"demand":3.0,"machine":"mug"},
 "hat":{"type":"hat","label":"Hat","batch":8,"price":25,"demand":2.0,"machine":"embroidery"}}
const DESIGN_FEE=25
const STORE_FEE=10
const BOOTH_FEE=40
const TREND_BONUS=2.0
const SEASON_BONUS=1.4
const MARKET_BONUS=2.0
const STORE_LEVEL=2

static func ensure(s) -> Dictionary:
 if not s.state.get("merch") is Dictionary:
  s.state["merch"]={"designs":[],"next":1,"store_open":false,"booth_day":-1,"carry":{},"sold_total":0,"revenue_total":0,"last_day":{}}
 return s.state["merch"]

static func unlocked(s) -> bool:
 return not s.state.get("starter_path",false) or Progress.level(s)>=STORE_LEVEL

static func trend(s) -> String:
 var week=int(floor(float(maxi(1,int(s.state["day"]))-1)/7.0))
 return THEMES[(week*3+1)%THEMES.size()]

static func weekend(s) -> bool:
 return int(s.state["day"])%7 in [6,0]

# Product kinds this shop can make right now.
static func makeable(s) -> Array:
 var kinds=[]
 for kind in KINDS:
  var type=String(KINDS[kind]["type"])
  if s.can_produce(type): kinds.append(kind)
 return kinds

static func create_design(s,kind:String,theme:String) -> Dictionary:
 var m=ensure(s)
 if not unlocked(s): s.notice("Your merch line opens at shop level %d." % STORE_LEVEL); return {}
 if not KINDS.has(kind) or not theme in THEMES: return {}
 if s.state["cash"]<DESIGN_FEE: s.notice("A new design costs $%d." % DESIGN_FEE); return {}
 s.state["cash"]-=DESIGN_FEE
 s.state["stats"]["art_fees"]=int(s.state["stats"].get("art_fees",0))+DESIGN_FEE
 var design={"id":"D%d" % int(m["next"]),"kind":kind,"theme":theme,"name":"%s %s" % [theme,KINDS[kind]["label"]],"stock":0,"price":int(KINDS[kind]["price"]),"sold":0,"made":0}
 m["next"]=int(m["next"])+1
 m["designs"].append(design)
 s.notice("New design: %s. Print a batch to stock your store." % design["name"])
 return design

static func design(s,id:String) -> Dictionary:
 for d in ensure(s)["designs"]:
  if d["id"]==id: return d
 return {}

static func batch_open(s,id:String) -> bool:
 for o in s.state["orders"]:
  if o.get("merch","")==id and o["stage"] not in ["completed","declined","abandoned"]: return true
 return false

# A batch is a job for your own shop: it is planned, queued and produced like
# any order, but finishes into store stock instead of a customer payment.
static func make_batch(s,id:String) -> bool:
 var d=design(s,id)
 if d.is_empty(): return false
 if batch_open(s,id): s.notice("A batch of %s is already in production." % d["name"]); return false
 var kind=KINDS[d["kind"]]
 if not s.can_produce(String(kind["type"])): s.notice("Install the equipment for %s first." % d["name"]); return false
 var o=C.make_order("MERCH-%s-%d" % [id,int(d["made"])+1],String(kind["type"]),int(kind["batch"]),"Your merch line",s.now()+30.0,0)
 o["merch"]=id;o["art_ready"]=true;o["fulfillment"]="stock";o["stage"]="plan";o["product"]=String(d["name"])
 s.assign_method(o)
 s.state["orders"].append(o)
 var i=s.state["orders"].size()-1
 if o["type"] in ["transfer","apparel"] and not C.is_htv(o): s.auto_pack(i)
 s.queue_order(i)
 s.notice("Batch of %d %s queued. It joins store stock when it is packed." % [int(kind["batch"]),d["name"]])
 return true

static func finish_batch(s,o:Dictionary) -> void:
 var d=design(s,String(o["merch"]))
 o["paid"]=true;o["payment"]=0;o["stage"]="completed";o["finished_at"]=s.now()
 if d.is_empty(): return
 d["stock"]=int(d["stock"])+int(o["quantity"]);d["made"]=int(d["made"])+1
 s.notice("%d %s added to your store stock." % [int(o["quantity"]),d["name"]])

static func set_price(s,id:String,step:int) -> void:
 var d=design(s,id)
 if d.is_empty(): return
 var base=int(KINDS[d["kind"]]["price"])
 d["price"]=clampi(int(d["price"])+step,maxi(1,roundi(base*0.5)),base*3)

static func toggle_store(s) -> bool:
 var m=ensure(s)
 if not unlocked(s): s.notice("Your online store opens at shop level %d." % STORE_LEVEL); return false
 m["store_open"]=not m["store_open"]
 s.notice("Online store is open: $%d a day in platform fees." % STORE_FEE if m["store_open"] else "Online store closed.")
 return true

static func book_booth(s) -> bool:
 var m=ensure(s)
 if not unlocked(s) or not weekend(s) or int(m["booth_day"])==int(s.state["day"]): return false
 if s.state["cash"]<BOOTH_FEE: s.notice("A market booth costs $%d." % BOOTH_FEE); return false
 s.state["cash"]-=BOOTH_FEE
 s.state["stats"]["marketing"]=int(s.state["stats"].get("marketing",0))+BOOTH_FEE
 m["booth_day"]=int(s.state["day"])
 s.notice("Booth booked at today's craft market. Your stock sells at the close of the day.")
 return true

# Units of a design customers would buy today (before stock limits).
static func demand(s,d:Dictionary) -> float:
 var m=ensure(s)
 var kind=KINDS[d["kind"]]
 var store=1.0 if m["store_open"] else 0.0
 var market=MARKET_BONUS if int(m["booth_day"])==int(s.state["day"]) else 0.0
 if store+market<=0.0: return 0.0
 var amount=float(kind["demand"])*(store+market)
 if d["theme"]==trend(s): amount*=TREND_BONUS
 if Customers.boosted(s,String(kind["type"])): amount*=SEASON_BONUS
 if Customers.review_count(s)>0: amount*=0.6+Customers.rating(s)/5.0*0.6
 amount*=clampf(pow(float(kind["price"])/maxf(1.0,float(d["price"])),1.5),0.25,2.5)
 return amount

# Sells stock at the close of the day. Fractions carry over so small demand still adds up.
static func close_day(s) -> Dictionary:
 var m=ensure(s)
 var units=0;var revenue=0
 for d in m["designs"]:
  var want=demand(s,d)+float(m["carry"].get(d["id"],0.0))
  var sold=mini(int(d["stock"]),int(floor(want)))
  m["carry"][d["id"]]=0.0 if int(d["stock"])<=sold else want-floor(want)
  if sold<=0: continue
  d["stock"]=int(d["stock"])-sold;d["sold"]=int(d["sold"])+sold
  units+=sold;revenue+=sold*int(d["price"])
 var fee=STORE_FEE if m["store_open"] else 0
 s.state["cash"]+=revenue-fee
 s.state["stats"]["sales"]=int(s.state["stats"]["sales"])+revenue
 s.state["stats"]["marketing"]=int(s.state["stats"].get("marketing",0))+fee
 s.state["stats"]["merch_units"]=units
 s.state["stats"]["merch_sales"]=revenue
 m["sold_total"]=int(m["sold_total"])+units;m["revenue_total"]=int(m["revenue_total"])+revenue
 m["last_day"]={"day":int(s.state["day"]),"units":units,"revenue":revenue,"fee":fee}
 if units>0: s.notice("Merch sold %d items today for $%d%s." % [units,revenue," at the craft market and online" if int(m["booth_day"])==int(s.state["day"]) else " online"])
 Progress.refresh(s)
 return m["last_day"]

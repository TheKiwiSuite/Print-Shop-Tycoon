extends RefCounted

const STOCK = {"film":96,"cyan":160,"magenta":160,"yellow":160,"black":160,"white":180,"powder":100,"sticker":180,"laminate":100,"banner":40,"rigid":24,"packaging":50,"maintenance":10}
const PRICES = {"film":2.0,"cyan":0.4,"magenta":0.4,"yellow":0.4,"black":0.4,"white":0.5,"powder":0.5,"sticker":0.8,"laminate":0.5,"banner":3.0,"rigid":8.0,"packaging":1.0,"maintenance":8.0}
const UNITS = {"film":"ft / 24 in","cyan":"units","magenta":"units","yellow":"units","black":"units","white":"units","powder":"units","sticker":"sheets","laminate":"sheets","banner":"ft","rigid":"panels","packaging":"boxes","maintenance":"kits"}
const ROLES = ["Prepress artist","DTF operator","Print / cut operator","Finisher","CNC operator","Packer","Shipping worker"]
const HIRE_COST = [320,420,400,350,600,300,380]
const NAMES = ["Mia","Alex","Jules","Riley","Noah","Casey","Taylor"]
const CUSTOMERS = ["Neon Thread Co.","Mira's Moon Market","Eastview School Club","Riverside Night Market","Trailhead Outfitters","Maple Street Studio","Sunshine Collective","Paper Moon Co."]

static func station(kind:String, pos:Array, size:Array, service:Array, title:String, sprite:int) -> Dictionary:
 return {"kind":kind,"pos":pos,"size":size,"service":service,"title":title,"sprite":sprite,"rotation":0,"condition":96,"worker":"auto","active":-1,"elapsed":0.0,"width":24,"phase":"Idle"}

static func layout(level:int) -> Dictionary:
 var m = {}
 m["dtf"] = station("dtf",[4,2],[3,1],[-1,1],"DTF printer",0)
 m["shaker"] = station("shaker",[4,4],[3,2],[-1,0],"Powder / cure / take-up",1)
 m["storage"] = station("storage",[1,0],[2,1],[1,1],"Material storage",7)
 if level == 1:
  m["sticker"] = station("sticker",[1,5],[2,2],[0,2],"Sticker print / cut",2)
  m["heat"] = station("heat",[8,6],[2,2],[0,2],"Heat press",3)
  m["art"] = station("art",[8,2],[2,1],[0,1],"Artwork desk",6)
  m["finish"] = station("finish",[5,9],[2,1],[0,1],"Inspect / finish",6)
  m["pack"] = station("pack",[10,9],[3,2],[-1,1],"Pack / pickup",6)
 else:
  m["dtf2"] = station("dtf",[9,2],[3,1],[-1,1],"DTF printer 2",0)
  m["shaker2"] = station("shaker",[9,4],[3,2],[-1,0],"Shaker / cure 2",1)
  m["sticker"] = station("sticker",[3,8],[2,2],[0,2],"Sticker print / cut",2)
  m["heat"] = station("heat",[7,9],[2,2],[0,2],"Heat press",3)
  m["art"] = station("art",[1,4],[2,1],[0,1],"Artwork desk",6)
  m["finish"] = station("finish",[10,10],[2,1],[0,1],"Inspect / finish",6)
  m["pack"] = station("pack",[14,10],[3,2],[-1,0],"Packing benches",6)
  m["banner"] = station("banner",[13,3],[3,2],[-1,1],"Roll-to-roll printer",4)
  m["cnc"] = station("cnc",[13,6],[4,3],[-1,1],"CNC flatbed cutter",5)
  m["dock"] = station("dock",[15,0],[3,2],[0,2],"Shipping dock",11)
 return m

static func make_order(id:String, type:String, quantity:int, customer:String, due:float, reward:int) -> Dictionary:
 var products = {"transfer":"DTF transfers","sticker":"Die-cut stickers","apparel":"Club shirts","banner":"Event banners","cnc":"Routed signs"}
 var dim={"transfer":[11,14],"apparel":[11,14],"sticker":[3,3],"banner":[36,84],"cnc":[24,36]}[type]
 return {"id":id,"type":type,"quantity":quantity,"customer":customer,"product":products[type],"reward":reward,"due":due,"stage":"intake","art_ready":type != "transfer" and type != "cnc","art_w":float(dim[0]),"art_h":float(dim[1]),"gang":[],"film_width":24,"sheet_length":48,"recipe":{},"consumed":false,"reprints":0,"issue":"","quality":100,"material_cost":0.0,"rush":false,"route_machine":"","settings":{"white":"standard","registration":true,"laminate":true,"cut":"contour","media":"PVC" if type == "cnc" else "standard","press":"cotton_warm"},"garments":{"navy:S":ceili(quantity/3.0),"navy:M":floori(quantity/3.0),"navy:L":quantity-ceili(quantity/3.0)-floori(quantity/3.0)} if type == "apparel" else {},"fulfillment":"ship" if type in ["banner","cnc"] else "pickup","revision_eta":-1.0,"quality_accepted":false,"started_at":-1.0,"finished_at":-1.0}

static func starters() -> Array:
 return [make_order("DTF-001","transfer",24,CUSTOMERS[0],6.5,480),make_order("STK-002","sticker",100,CUSTOMERS[1],7.5,420),make_order("APP-003","apparel",12,CUSTOMERS[2],8.5,620)]

static func garage_orders(now:float) -> Array:
 return [make_order("BAN-004","banner",2,CUSTOMERS[3],now+5,760),make_order("CNC-005","cnc",10,CUSTOMERS[4],now+7,1180)]

static func phases(kind:String, order:Dictionary) -> Array:
 match kind:
  "art": return [["Check artwork / dimensions",4.0],["Repair bleed / transparency",4.0]]
  "dtf": return [["Print CMYK + white",12.0],["Apply / shake powder",5.0],["Cure transfer",7.0],["Wind front take-up",4.0]]
  "sticker": return [["Print artwork",8.0],["Laminate",4.0 if order["settings"]["laminate"] else 0.1],["Read registration",3.0],["Contour cut",7.0]]
  "banner": return [["Load roll media",4.0],["Wide-format print",14.0],["Trim / grommet finish",5.0]]
  "cnc": return [["Load rigid panel",5.0],["Run toolpath / gantry",16.0],["Unload cut pieces",4.0]]
  "heat": return [["Reserve garment blanks",2.0],["Heat press / timed preset",8.0],["Warm peel / finishing press" if order["settings"]["press"]=="cotton_warm" else "Cold peel / finishing press",4.0]]
  "finish": return [["Inspect output / count",5.0]]
  "pack": return [["Cut / roll / box",6.0]]
  "deliver": return [["Customer pickup / dispatch",3.0]]
 return [["Work",3.0]]

static func recipe(order:Dictionary) -> Dictionary:
 var q = float(order["quantity"])
 var type = order["type"]
 if type in ["transfer","apparel"]:
  var count = maxi(1,order["gang"].size())
  var sheets = ceili(q / count)
  var film = ceili(sheets * float(order["sheet_length"]) / 12.0)
  var area = q * float(order["art_w"]) * float(order["art_h"]) / 154.0
  return {"film":film,"cyan":ceili(area*0.3),"magenta":ceili(area*0.25),"yellow":ceili(area*0.25),"black":ceili(area*0.2),"white":ceili(area*(0.3 if order["settings"]["white"]=="economy" else 0.5)),"powder":ceili(area*0.3)}
 if type == "sticker": return {"sticker":ceili(q/12.0),"laminate":ceili(q/12.0) if order["settings"]["laminate"] else 0,"cyan":ceili(q/25.0),"magenta":ceili(q/25.0),"yellow":ceili(q/25.0),"black":ceili(q/30.0)}
 if type == "banner": return {"banner":int(q*7),"cyan":int(q*4),"magenta":int(q*4),"yellow":int(q*4),"black":int(q*3)}
 if type == "cnc": return {"rigid":int(q)}
 return {}

static func fresh() -> Dictionary:
 return {"schema":3,"day":1,"clock":8.0,"cash":1200,"reputation":54,"location":1,"paused":false,"speed":1,"machines":layout(1),"orders":starters(),"stock":STOCK.duplicate(true),"garments":{"navy:S":12,"navy:M":16,"navy:L":12,"white:S":8,"white:M":8,"white:L":8},"workers":[{"id":"owner","name":"Sam","role":"Owner","pos":[1.0,9.0],"path":[],"task":{},"manual":true,"face":0,"step":0.0,"walking":false,"skill":1.0,"wage":0}],"deliveries":[],"upgrades":{"auto_feeder":false,"training":false,"quality_sensor":false,"second_shift":false},"notices":["WASD / arrows: walk. Click floor: move. E: interact. Start with the 24-transfer order."],"completed":0,"on_time":0,"quality_total":0,"tutorial":true,"tutorial_order":"DTF-001","settings":{"sound":true,"music":true,"text_scale":1.0,"fullscreen":false},"stats":day_stats(),"customers":{},"next_worker":0,"best_profit":0,"report":{},"report_applied":false}

static func empty_shop() -> Dictionary:
 var s=fresh()
 s["workers"][0]["pos"]=[3.0,10.0]
 s["machines"]={}
 s["empty_start"]=true
 s["paused"]=true
 s["customer_flow"]=true
 for i in s["orders"].size():
  var o=s["orders"][i]
  o["stage"]="scheduled"
  o["visit"]={"status":"scheduled","arrival_at":float(i)*0.75,"arrived_at":-1.0,"patience_until":-1.0,"settled_at":-1.0,"satisfaction":-1}
  o["paid"]=false
  o["payment"]=0
  o["satisfaction"]=-1
 s["notices"]=["Your shop is empty. Open ADD EQUIPMENT, choose a station, then click clear floor to place it."]
 return s

const EQUIPMENT_PRICES={"dtf":900,"sticker":500,"heat":250,"art":0,"finish":0,"pack":0,"storage":150,"banner":1500,"cnc":2500,"dock":1000}

static func day_stats() -> Dictionary:
 return {"sales":0,"materials":0.0,"waste":0.0,"art_fees":0,"marketing":0,"wages":0,"overhead":125,"delivered":0,"on_time":0,"quality":0}

extends RefCounted

const CAMPAIGNS={
 "flyers":{"title":"Neighborhood flyers","cost":25,"leads":1,"delay":0.5},
 "social":{"title":"Local social promotion","cost":60,"leads":2,"delay":0.5},
 "business":{"title":"Small-business outreach","cost":100,"leads":3,"delay":0.75}
}
const JOBS={"transfer":{"quantity":12,"reward":240},"sticker":{"quantity":36,"reward":150},"apparel":{"quantity":6,"reward":300},"banner":{"quantity":1,"reward":380},"cnc":{"quantity":2,"reward":236}}
const STATIONS={"transfer":["dtf"],"sticker":["sticker"],"apparel":["dtf","heat"],"banner":["banner"],"cnc":["cnc"]}

static func defaults() -> Dictionary:
 return {"next_id":1,"cooldown_until":-1.0,"history":[]}

static func supported(machines:Dictionary) -> Array:
 var types=[]
 for type in STATIONS:
  var available=true
  for id in STATIONS[type]:
   if not machines.has(id): available=false;break
  if available: types.append(type)
 return types

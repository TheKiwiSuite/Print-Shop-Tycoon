extends SceneTree
# Premises ladder: home garage, neighborhood storefront, warehouse, print factory.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Ops=preload("res://scripts/shop_operations.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var checks=0
var failures=0

func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)

func advance(s, i:int, stage:String, limit:int=9000) -> bool:
 for n in limit:
  if s.order(i)["stage"]==stage: return true
  s.tick(0.1)
 check(false,"Timed out waiting for "+stage+"; actual "+s.order(i)["stage"])
 return false

func _initialize() -> void:
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 check(s.premises()=="garage" and s.premises_title()=="HOME GARAGE","A new career starts in the home garage")
 check(s.bounds()==Vector2i(10,9) and s.entrance()==Vector2i(0,4),"The garage is a small room with its door on the side")
 check(s.inside(s.cell(s.owner()["pos"])) and not s.blocked().has(s.cell(s.owner()["pos"])),"Sam starts on clear garage floor")
 check(s.base_overhead()==60 and s.staff_cap()==2,"The garage is cheap to run and fits you plus one helper")
 # The suggested garage arrangement really fits, with walkable service spots.
 for id in ["cutter","heat","art","finish","pack"]:
  check(s.install_equipment(id,C.garage_spot(id)),"Garage spot fits "+id)
 for id in ["cutter","heat","art","finish","pack"]:
  check(not s.path(s.entrance(),s.service(id)).is_empty(),"Garage service spot is reachable: "+id)
 check(not s.install_equipment("heat",Vector2i(9,8)) or true,"Placement near the far corner does not crash")
 check(not s.install_feedback("storage",Vector2i(12,3))["valid"],"Equipment cannot be placed beyond the garage walls")
 # A whole job runs in the garage, customer in through the door and out again.
 s.state["paused"]=false;s.tick(.1)
 check(s.order(0)["id"]=="SHIRT-START","The first garage customer wants vinyl shirts")
 check(s.accept(0),"Accept the garage job")
 if s.order(0)["stage"]=="preflight": s.preflight(0,"repair")
 check(s.queue_order(0),"Queue the garage job")
 s.owner()["manual"]=false
 advance(s,0,"completed")
 check(s.order(0)["paid"],"The garage job is delivered and paid")
 # Leasing the storefront: level and cash required, layout kept, room grows.
 var machines=s.state["machines"].duplicate(true)
 s.state["cash"]=5000
 check(not s.move_to_storefront() and s.premises()=="garage","A storefront needs shop level %d" % s.STOREFRONT_LEVEL)
 check(not s.expand_premises(),"The warehouse cannot be reached straight from the garage")
 Progress.ensure(s)["xp"]=Progress.LEVEL_XP[s.STOREFRONT_LEVEL-1]
 s.state["cash"]=s.STOREFRONT_COST-1
 check(not s.move_to_storefront(),"A storefront needs the lease money")
 s.state["cash"]=5000
 for w in s.state["workers"]: w["task"]={};w["path"]=[]
 check(s.move_to_storefront(),"Lease the storefront")
 check(s.premises()=="storefront" and s.state["cash"]==5000-s.STOREFRONT_COST,"The lease is charged once")
 check(s.bounds()==Vector2i(14,12) and s.entrance()==Vector2i(0,9),"The storefront is the larger neighborhood shop")
 check(s.state["machines"]==machines,"Every machine stays exactly where it was")
 check(s.base_overhead()==125 and s.staff_cap()==3,"The storefront costs more and fits a team of three")
 check(not s.move_to_storefront(),"The storefront can only be leased once")
 Progress.refresh(s)
 check("storefront" in Progress.ensure(s)["goals"],"Moving out of the garage completes a goal")
 for id in machines:
  check(s.placement_feedback(id,s.cell(s.state["machines"][id]["pos"]),int(s.state["machines"][id]["rotation"]))["valid"],"Layout is still valid in the storefront: "+id)
 # Storefront to warehouse uses the existing growth requirements.
 s.state["reputation"]=70;s.state["completed"]=3;s.state["on_time"]=3;s.state["quality_total"]=300
 check(s.expand_premises() and s.premises()=="warehouse" and s.bounds()==Vector2i(18,14),"The storefront can grow into the warehouse")
 check(s.staff_cap()==4 and s.base_overhead()==200,"The warehouse fits four people")
 check(s.fit_out() and s.staff_cap()==6,"The fit-out makes room for six")
 # The shipping dock is a loading bay at the open door in the outside wall.
 s.state["cash"]=20000;Progress.ensure(s)["xp"]=Progress.LEVEL_XP[6]
 check(not s.install_feedback("dock",Vector2i(6,6))["valid"],"The dock cannot sit in the middle of the floor")
 check(s.install_equipment("dock",Vector2i(s.bounds().x-2,6)),"The dock goes against the outside wall")
 check(s.state["machines"]["dock"]["size"]==[2,3],"The loading bay is two deep and three wide")
 check(not s.rotate_equipment("dock") and s.facing_of(s.state["machines"]["dock"])==0,"The loading bay does not turn")
 check(not s.move_equipment("dock",Vector2i(5,6)),"The dock cannot be moved off the outside wall")
 check(s.move_equipment("dock",Vector2i(s.bounds().x-2,9)),"The dock can slide along the outside wall")
 check(not s.path(s.entrance(),s.service("dock")).is_empty(),"Packers can reach the loading bay")
 s.state["reputation"]=85;s.state["completed"]=10;s.state["cash"]=20000
 check(Ops.annex(s) and s.premises()=="factory" and s.premises_title()=="PRINT FACTORY" and s.staff_cap()==9,"The production annex makes it a print factory")
 var dock=s.state["machines"]["dock"]
 check(int(dock["pos"][0])+2==s.bounds().x and s.placement_feedback("dock",s.cell(dock["pos"]),0,0)["valid"],"The dock moves to the factory's new outside wall")
 # An older save with the dock in the middle of the floor gets it moved to the wall on load.
 s.state["machines"]["dock"]["pos"]=[8,6]
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/premises-dock-qa.json")
 check(s.save_game(),"Save a shop with a misplaced dock")
 var moved=Sim.new();moved.save_path=s.save_path
 check(moved.load_game() and int(moved.state["machines"]["dock"]["pos"][0])+2==moved.bounds().x,"Loading moves a misplaced dock to the outside wall")
 s.save_enabled=false
 # Saving and loading keeps the garage.
 var g=Sim.new();g.save_enabled=false;g.start_shop("Relaxed")
 g.save_enabled=true;g.save_path=ProjectSettings.globalize_path("res://../../../work/premises-qa.json")
 check(g.save_game(),"Save a garage shop")
 var loaded=Sim.new();loaded.save_path=g.save_path
 check(loaded.load_game() and loaded.premises()=="garage" and loaded.bounds()==Vector2i(10,9),"A garage shop loads as a garage")
 # Older shops and the demo stay where they were.
 var legacy=Sim.new();legacy.save_enabled=false;legacy.state=C.fresh()
 check(legacy.premises()=="storefront" and legacy.bounds()==Vector2i(14,12) and legacy.base_overhead()==125,"Older shops stay in the neighborhood shop")
 legacy.state["location"]=2
 check(legacy.premises()=="warehouse","Older industrial shops are the warehouse")
 var demo=Sim.new();demo.save_enabled=false;demo.start_demo()
 check(demo.premises()=="storefront" and demo.staff_cap()==9,"The demo shop is unchanged")
 print("PREMISES CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

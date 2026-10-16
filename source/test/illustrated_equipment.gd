extends SceneTree
const C=preload("res://scripts/catalog.gd")
const S=preload("res://scripts/simulation.gd")
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func run():
 var s=S.new();s.save_enabled=false
 for kind in C.EQUIPMENT_PRICES:
  for facing in 16:
   s.state=C.empty_shop();s.state["location"]=2;s.state["cash"]=100000
   check(s.install_equipment(kind,Vector2i(7,5),facing/4,facing),"Install "+kind+" facing "+str(facing))
   if not s.state["machines"].has(kind):continue
   var m=s.state["machines"][kind]
   check(s.facing_of(m)==facing,"Facing recorded")
   var cash=s.state["cash"]
   check(s.move_equipment(kind,Vector2i(8,6),facing/4,facing),"Relocate "+kind+" facing "+str(facing))
   check(s.state["cash"]==cash,"No relocation charge")
   check(not s.move_equipment(kind,Vector2i(-1,-1),facing/4,facing),"Reject wall placement "+kind)
   check(s.cell(s.state["machines"][kind]["pos"])==Vector2i(8,6),"Failed placement atomic")
   check(not s.path(s.entrance(),s.service(kind)).is_empty(),"Walkable operator point "+kind)
   for p in s.footprint(kind):check(s.blocked().has(p),"Footprint blocks walking")
   if kind=="dtf":check(s.facing_of(s.state["machines"]["shaker"])==facing,"Shaker follows printer")
 s.state=C.empty_shop();s.state["location"]=2;s.state["cash"]=100000
 check(s.install_equipment("sticker",Vector2i(7,5),0,1),"Angled station for overlap test")
 var at=s.footprint("sticker")[0]
 check(not s.install_equipment("heat",at),"Diagonal footprint rejects overlap")
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/illustrated-qa-save.json")
 check(s.save_game(),"Save 22.5 degree layout")
 var restore=S.new();restore.save_path=s.save_path
 check(restore.load_game(),"Load 22.5 degree layout")
 check(restore.facing_of(restore.state["machines"]["sticker"])==1,"Reload preserves exact facing")
 print("ILLUSTRATED_PLACEMENT: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

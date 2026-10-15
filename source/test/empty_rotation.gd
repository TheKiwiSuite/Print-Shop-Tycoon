extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)
func _initialize() -> void:
 var s=Sim.new()
 s.save_enabled=false
 check(s.state["machines"].is_empty(),"New shop has no preinstalled equipment")
 check(s.room_props().is_empty(),"New shop has no preinstalled racks or plants")
 check(s.state["paused"],"Setup clock starts paused")
 var funds=s.state["cash"]
 check(not s.install_equipment("dtf",Vector2i(0,0)),"Out-of-bounds line is rejected")
 check(s.state["cash"]==funds and s.state["machines"].is_empty(),"Rejected placement costs nothing")
 for rotation in 4:
  s.state=C.empty_shop()
  check(s.install_equipment("dtf",Vector2i(5,5),rotation),"Install complete line orientation %d" % rotation)
  check(s.state["machines"].size()==2,"Printer and shaker installed atomically %d" % rotation)
  check(s.state["cash"]==300,"Charge complete-line price once %d" % rotation)
  var p=s.state["machines"]["dtf"]
  var shaker=s.state["machines"]["shaker"]
  check(p["rotation"]==rotation and shaker["rotation"]==rotation,"Both components share rotation %d" % rotation)
  check(p["size"]==([3,1] if rotation%2==0 else [1,3]),"Printer footprint rotates %d" % rotation)
  for x in 3:
   var film=s.dtf_cell("dtf",Vector2i(x,1),s.state["machines"])
   check(s.blocked().has(film),"Film gap blocks walking %d/%d" % [rotation,x])
  check(not s.path(s.entrance(),s.service("dtf")).is_empty(),"Operator reaches rotated printer %d" % rotation)
  check(not s.path(s.entrance(),s.service("shaker")).is_empty(),"Operator reaches rotated shaker %d" % rotation)
  check(s.move_equipment("dtf",Vector2i(5,5),(rotation+1)%4),"Rotate complete installed line %d" % rotation)
  check(not s.install_equipment("dtf",Vector2i(5,5)),"No duplicate charge for installed line %d" % rotation)
 s.state=C.empty_shop()
 check(s.install_equipment("dtf",Vector2i(5,5)),"Place line for rotation collision test")
 check(s.install_equipment("heat",Vector2i(2,5)),"Place neighboring station outside original footprint")
 var layout=s.state["machines"].duplicate(true)
 check(not s.move_equipment("dtf",Vector2i(5,5),1),"Reject rotation into another station")
 check(s.state["machines"]==layout,"Invalid rotation leaves complete layout unchanged")
 s.state=C.empty_shop()
 check(s.install_equipment("sticker",Vector2i(4,4)),"Place starter sticker station")
 check(s.install_equipment("art",Vector2i(8,2)),"Place artwork bench")
 check(s.install_equipment("finish",Vector2i(5,9)),"Place inspection bench")
 check(s.install_equipment("pack",Vector2i(10,9)),"Place packing bench")
 check(not s.install_equipment("heat",Vector2i(4,4)),"Overlapping new equipment is rejected")
 check(not s.work_order(0),"Missing equipment does not crash order work")
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/empty-rotation-test.json")
 check(s.save_game(),"Save player-arranged empty-start shop")
 var load=Sim.new();load.save_path=s.save_path
 check(load.load_game() and load.state["machines"].size()==4 and load.room_props().is_empty(),"Resume keeps manually placed stations without adding decor")
 s.state=C.empty_shop();s.save_enabled=false
 check(s.install_equipment("dtf",Vector2i(4,2)),"Start production shop from empty floor")
 for id in ["art","finish","pack"]:
  var m=C.layout(1)[id]
  check(s.install_equipment(id,s.cell(m["pos"])),"Place production support "+id)
 s.state["paused"]=false
 s.accept(0);s.preflight(0,"repair");s.auto_pack(0);s.queue_order(0)
 s.owner()["manual"]=false
 for n in 8000:
  if s.order(0)["stage"]=="completed": break
  s.tick(.1)
 check(s.order(0)["stage"]=="completed","Manually built shop completes and gets paid for its first transfer order")
 print("EMPTY / ROTATION: ",checks," checks, ",failures," failures")
 quit(failures)

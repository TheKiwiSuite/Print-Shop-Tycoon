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
 call_deferred("run")
func run() -> void:
 var s=Sim.new();s.save_enabled=false
 for id in ["sticker","art","finish","pack"]:
  var m=C.layout(1)[id]
  check(s.install_equipment(id,s.cell(m["pos"])),"Install "+id)
 s.state["paused"]=false;s.tick(.1)
 check(s.visible_customers().size()==1,"Arrived inquiry creates a visible customer")
 var actor=s.order(0)["visit"]["actor"]
 var first=actor["pos"].duplicate()
 s.state["paused"]=true
 for n in 10: s.tick(.1)
 check(actor["pos"]==first,"Pause freezes customer walking")
 s.state["paused"]=false
 var safe=true
 var saw_steps=false
 for n in 200:
  var before=s.v(actor["pos"])
  s.tick(.1)
  safe=safe and s.walk_segment_clear(before,s.v(actor["pos"]))
  saw_steps=saw_steps or actor["walking"]
 check(safe and saw_steps,"Customer walks without crossing equipment or walls")
 check(actor["phase"]=="waiting","Customer reaches inquiry waiting spot")
 check(s.accept(0),"Accept walking customer's inquiry")
 for n in 200: s.tick(.1)
 check(actor["phase"]=="away","Accepted customer walks out during production")
 check(s.preflight(0,"repair") and s.queue_order(0),"Prepare accepted order")
 s.owner()["manual"]=false
 var saw_return=false
 var handoff_waited=true
 var moved_pickup=false
 for n in 8000:
  if s.order(0)["stage"]=="completed": break
  s.tick(.1)
  if actor["purpose"]=="pickup" and actor["phase"]=="entering":
   saw_return=true
   handoff_waited=handoff_waited and not s.order(0)["paid"]
   if not moved_pickup: moved_pickup=s.move_equipment("pack",Vector2i(9,7))
 check(saw_return and handoff_waited,"Pickup waits for returning customer to reach the bench")
 check(moved_pickup,"Returning customer reroutes when pickup bench is relocated")
 check(s.order(0)["paid"] and s.order(0)["payment"]==150,"Arrival permits one paid handoff")
 for n in 400: s.tick(.1)
 check(actor["phase"]=="away","Served customer walks out through the door")
 var departures=Sim.new();departures.save_enabled=false
 departures.install_equipment("sticker",Vector2i(4,4))
 departures.state["clock"]=8.8;departures.state["paused"]=false
 for n in 200: departures.tick(.1)
 check(departures.visible_customers().size()==2,"Staggered doorway admits two waiting customers")
 check(departures.order(0)["visit"]["actor"]["goal"]!=departures.order(1)["visit"]["actor"]["goal"],"Customers wait in distinct floor spaces")
 departures.decline(1)
 for n in 200: departures.tick(.1)
 check(departures.order(1)["visit"]["actor"]["phase"]=="away","Declined customer walks out")
 departures.state["clock"]=12.0
 for n in 200: departures.tick(.1)
 check(departures.order(0)["stage"]=="abandoned" and departures.order(0)["visit"]["actor"]["phase"]=="away","Expired inquiry walks out without payment")
 s.state=C.empty_shop();s.save_enabled=false
 check(s.install_equipment("sticker",Vector2i(4,4)),"Install station for relocation")
 check(s.move_equipment("sticker",Vector2i(7,5)),"Placed station can move again")
 var layout=s.state["machines"].duplicate(true)
 for p in [Vector2i(-1,5),Vector2i(14,5),Vector2i(5,-1),Vector2i(5,12),Vector2i(13,11)]:
  check(not s.move_equipment("sticker",p),"Reject station beyond room: "+str(p))
 check(s.state["machines"]==layout,"Rejected moves retain complete installed layout")
 s.state["paused"]=false;s.tick(.1)
 actor=s.order(0)["visit"]["actor"]
 for n in 80: s.tick(.1)
 s.save_path=ProjectSettings.globalize_path("res://../../../work/customer-walking-test.json");s.save_enabled=true
 check(s.save_game(),"Save walking customer's position")
 var restored=Sim.new();restored.save_path=s.save_path;restored.save_enabled=false
 check(restored.load_game(),"Reload walking customer")
 check(restored.order(0)["visit"]["actor"]["pos"]==actor["pos"],"Reload retains position and route")
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.sim=s;game.sim.save_enabled=false;game.screen="shop";game.selected_machine="sticker"
 game._action("move_equipment")
 check(game.build and game.moving_equipment=="sticker","Equipment panel opens explicit relocation mode")
 game.drag_valid=s.placement_feedback("sticker",Vector2i(-3,-3))
 check(game._equipment_position("sticker")==s.v(s.state["machines"]["sticker"]["pos"]),"Invalid preview cannot hide the installed sprite beyond a wall")
 game._action("build")
 check(game.moving_equipment=="" and not game.build,"Done Building cancels remaining relocation state")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(s.save_path+suffix): DirAccess.remove_absolute(s.save_path+suffix)
 print("CUSTOMER WALKING / PLACEMENT: ",checks," checks, ",failures," failures")
 game.free()
 await process_frame
 quit(failures)

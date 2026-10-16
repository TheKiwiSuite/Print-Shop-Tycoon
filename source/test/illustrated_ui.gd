extends SceneTree
var game:Node2D
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func redraw():
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
func run():
 game=load("res://main.tscn").instantiate()
 game.sim.save_enabled=false
 game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/illustrated-ui-qa.json")
 root.add_child(game);game.set_process(false);game.qa_ui=true
 game.screen="shop";game.build=true
 for kind in game.C.EQUIPMENT_PRICES:
  game.sim.state=game.C.empty_shop();game.sim.state["location"]=2;game.sim.state["cash"]=100000
  check(game.sim.install_equipment(kind,Vector2i(7,5)),"Install "+kind)
  game.selected_machine=kind
  for n in 16:
   await redraw()
   var hit=game.world_hits.filter(func(h):return h["id"]==kind)
   check(hit.size()==1,"One rendered assembly "+kind)
   if hit.size():
    check(hit[0]["facing"]==n,"Correct rendered facing "+kind+str(n))
    var found=false
    for x in range(2,9):
     for y in range(2,9):
      if game._machine_at(hit[0]["rect"].position+hit[0]["rect"].size*Vector2(x*.1,y*.1))==kind:found=true
    check(found,"Opaque sprite selectable "+kind+str(n))
   game._action("rotate_equipment")
  check(game.sim.facing_of(game.sim.state["machines"][kind])==0,"16 rotations wrap "+kind)
 game.sim.state=game.C.fresh();game.sim.state["location"]=2;game.sim.state["machines"]=game.C.layout(2)
 game.sim.state["paused"]=true;game.sim.state["tutorial"]=false;game.build=false;game.reset_camera()
 await redraw()
 game.get_viewport().get_texture().get_image().save_png("res://../captures/illustrated-equipment-native.png")
 game.modal="equipment";await redraw()
 game.get_viewport().get_texture().get_image().save_png("res://../captures/illustrated-equipment-menu.png")
 game.modal="";game.build=true
 game.sim.state=game.C.empty_shop();game.sim.state["cash"]=100000
 game.sim.install_equipment("dtf",Vector2i(5,4),0,1);game.selected_machine="dtf";game.reset_camera()
 await redraw()
 game.get_viewport().get_texture().get_image().save_png("res://../captures/illustrated-dtf-placement.png")
 print("ILLUSTRATED_UI: ",checks," checks, ",failures," failures")
 if "--hold" in OS.get_cmdline_user_args():game.set_process(true);return
 quit(1 if failures else 0)

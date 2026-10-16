extends SceneTree
var game:Node2D
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func redraw():
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
func motion(point:Vector2):
 var e=InputEventMouseMotion.new();e.position=point;game._input(e)
func mouse(point:Vector2,pressed:bool):
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=pressed;game._input(e)
func reset_shop(kind:String):
 game._cancel_world_drag();game.sim.state=game.C.empty_shop()
 game.sim.state["location"]=2;game.sim.state["cash"]=100000
 game.sim.install_equipment(kind,Vector2i(7,5));game.selected_machine=kind
func run():
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false
 game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/rotation-stability-profile.json")
 root.add_child(game);game.set_process(false);game.screen="shop";game.build=true
 for kind in game.C.EQUIPMENT_PRICES:
  reset_shop(kind)
  var center=game.sim.equipment_center(kind,game.sim.state["machines"])
  var max_drift=0.0
  for n in 32:
   check(game.sim.rotate_equipment(kind),"Can rotate "+kind+str(n))
   max_drift=maxf(max_drift,game.sim.equipment_center(kind,game.sim.state["machines"]).distance_to(center))
  check(max_drift<0.00001,"Installed rotation stays on one floor pivot: "+kind+" drift="+str(max_drift))
  game._action("move_equipment")
  motion(game.iso(Vector2(8,6)))
  center=game.sim.equipment_center(kind,game._render_machines())
  max_drift=0.0
  for n in 16:
   game._action("rotate_equipment")
   motion(game.iso(Vector2(8,6)))
   max_drift=maxf(max_drift,game.sim.equipment_center(kind,game._render_machines()).distance_to(center))
  check(max_drift<0.00001,"Move preview rotates around its floor pivot: "+kind+" drift="+str(max_drift))
  game._cancel_world_drag();game.sim.state["machines"]={}
  game._action("place:"+kind);motion(game.iso(Vector2(7,5)))
  center=game.sim.equipment_center(kind,game._render_machines());max_drift=0.0
  for n in 16:
   game._action("rotate_equipment");motion(game.iso(Vector2(7,5)))
   max_drift=maxf(max_drift,game.sim.equipment_center(kind,game._render_machines()).distance_to(center))
  check(max_drift<0.00001,"New placement keeps its floor pivot: "+kind+" drift="+str(max_drift))
  await redraw()
  check(game.world_hits.filter(func(h):return h["id"]==kind).size()==1,"Placement preview is drawn once "+kind)
  # Rotating while a sprite is held must not jump on motion or mouse release.
  reset_shop(kind);await redraw()
  var p=Vector2.ZERO;var found=false
  for hit in game.world_hits:
   if hit["id"]!=kind:continue
   for x in range(2,9):
    for y in range(2,9):
     var at=hit["rect"].position+hit["rect"].size*Vector2(x*.1,y*.1)
     if game._machine_at(at)==kind:p=at;found=true
  check(found,"Find opaque drag point "+kind)
  center=game.sim.equipment_center(kind,game.sim.state["machines"])
  mouse(p,true)
  for n in 4:game._action("rotate_equipment");motion(p)
  check(game.sim.equipment_center(kind,game._render_machines()).is_equal_approx(center),"Held sprite rotation keeps pivot "+kind)
  mouse(p,false)
  check(game.sim.equipment_center(kind,game.sim.state["machines"]).is_equal_approx(center),"Release preserves rotated pivot "+kind)
 reset_shop("dtf");var before=game.sim.state["machines"].duplicate(true)
 game._action("move_equipment");motion(game.iso(Vector2(-4,-4)))
 check(not game.drag_valid.get("valid",true),"Wall preview is invalid")
 check(game._render_machines()!=before,"Invalid preview stays at attempted location instead of jumping home")
 check(game.sim.state["machines"]==before,"Wall preview does not change installed layout")
 await redraw()
 game.get_viewport().get_texture().get_image().save_png("res://../captures/rotation-wall-preview.png")
 game._cancel_world_drag();game.sim.rotate_equipment("dtf")
 var center=game.sim.equipment_center("dtf",game.sim.state["machines"])
 for n in 3:game.sim.rotate_equipment("dtf")
 game.sim.save_enabled=true;check(game.sim.save_game(),"Save exact pivot")
 check(game.sim.load_game(),"Load exact pivot")
 check(game.sim.equipment_center("dtf",game.sim.state["machines"]).is_equal_approx(center),"Reload keeps pivot at quarter turn")
 for n in 12:game.sim.rotate_equipment("dtf")
 check(game.sim.equipment_center("dtf",game.sim.state["machines"]).is_equal_approx(center),"Rotation after reload keeps pivot")
 game.sim.save_enabled=false
 await redraw();game.get_viewport().get_texture().get_image().save_png("res://../captures/rotation-fixed.png")
 if "--record" in OS.get_cmdline_user_args():
  game.qa_ui=true;reset_shop("dtf");game.reset_camera()
  for mode in 2:
   if mode==1:game._action("move_equipment");motion(game.iso(Vector2(7,5)))
   for n in 16:
    game.status=("Installed equipment" if mode==0 else "Move preview")+" - fixed floor pivot - angle "+str(n*22.5)+" degrees"
    await redraw()
    game.get_viewport().get_texture().get_image().save_png("res://../../../work/rotation-demo/%03d.png" % (mode*16+n))
    game._action("rotate_equipment")
    if mode==1:motion(game.iso(Vector2(7,5)))
  game._cancel_world_drag()
 print("ROTATION_STABILITY: ",checks," checks, ",failures," failures")
 if "--hold" in OS.get_cmdline_user_args():game.set_process(true);return
 quit(1 if failures else 0)

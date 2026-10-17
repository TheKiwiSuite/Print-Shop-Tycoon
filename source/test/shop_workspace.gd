extends SceneTree
var game:Node2D
var checks=0
var failures=0
var scratch=""
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func redraw():
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
func mouse(point:Vector2,pressed:bool):
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=pressed;game._input(e)
func click_action(action:String):
 for button in game.buttons:
  if button["action"]==action:
   mouse(button["rect"].get_center(),true);mouse(button["rect"].get_center(),false);return
 check(false,"Visible button exists: "+action)
func run():
 scratch=ProjectSettings.globalize_path("res://../../../work/workspace-qa-%d.json" % Time.get_ticks_usec())
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;game.sim.save_path=scratch
 game.sim.state["settings"]["music"]=false
 root.add_child(game);game.set_process(false);game.screen="shop";game.qa_ui=true
 await redraw()
 var display_size=Vector2(DisplayServer.window_get_size())
 check(absf(game._screen_size().aspect()-display_size.aspect())<.002,"Adaptive canvas fills the window without letterboxing")
 for location in [1,2]:
  for arranging in [false,true]:
   game.sim.state=game.C.fresh();game.sim.state["location"]=location;game.sim.state["machines"]=game.C.layout(location)
   game.sim.state["paused"]=true;game.sim.state["tutorial"]=false;game.build=arranging;game.reset_camera()
   await redraw()
   for button in game.buttons:
    check(not game.SHOP_VIEW.intersects(button["rect"]),"Docked button leaves floor clear: "+button["action"])
   var size=game.sim.bounds()
   for point in [Vector2(-.5,-.5),Vector2(size.x-.5,-.5),Vector2(-.5,size.y-.5),Vector2(size.x-.5,size.y-.5)]:
    check(game.SHOP_VIEW.has_point(game.iso(point)),"Entire floor visible in location "+str(location))
   for point in [Vector2(-.5,-.5),Vector2(size.x-.5,-.5),Vector2(-.5,size.y-.5)]:
    check(game.SHOP_VIEW.has_point(game.iso(point)+Vector2(0,-155)*game.zoom),"Wall top stays below HUD")
   var before=game.sim.owner()["path"].duplicate(true)
   mouse(Vector2(80,805),true);mouse(Vector2(80,805),false)
   check(game.sim.owner()["path"]==before,"Blank sidebar cannot move owner through the dock")
   game.get_viewport().get_texture().get_image().save_png("res://../captures/workspace-%d-%s.png" % [location,"build" if arranging else "play"])
 game.sim.state=game.C.empty_shop();game.sim.state["cash"]=100000;game.sim.state["settings"]["music"]=false
 game.sim.install_equipment("dtf",Vector2i(5,4));game.reset_camera();game.build=true;game.selected_machine="dtf"
 await redraw()
 var before=game.sim.state["machines"].duplicate(true)
 var found=false
 for hit in game.world_hits:
  for x in range(2,9):
   for y in range(2,9):
    var point=hit["rect"].position+hit["rect"].size*Vector2(x*.1,y*.1)
    if not found and game._machine_at(point)=="dtf":mouse(point,true);found=true
 check(found and game.dragging=="machine","Equipment can still be grabbed in the clear view")
 mouse(Vector2(100,780),false)
 check(game.sim.state["machines"]==before and not game._relocating(),"Drop over a UI dock cancels without moving equipment")
 var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=Vector2(1250,30)
 var zoom_before=game.zoom;game._input(wheel)
 check(game.zoom==zoom_before,"Music/HUD scrolling cannot zoom the hidden floor")
 wheel.position=game.SHOP_VIEW.get_center();game._input(wheel)
 check(game.zoom>zoom_before,"Zoom still works inside the shop")
 game._action("camera");check(is_equal_approx(game.zoom,game.fit_zoom()) and game.offset.is_zero_approx(),"Fit Whole Shop restores full room framing")
 game.build=false;game.sim.state["settings"]["music"]=false;game._start_music();await redraw()
 click_action("music");await process_frame
 check(game.sim.state["settings"]["music"] and game.music.playing,"Main Music button starts audio")
 await redraw();click_action("music");await process_frame
 check(not game.sim.state["settings"]["music"] and not game.music.playing,"Main Music button stops audio")
 var preferences=ConfigFile.new()
 check(preferences.load(scratch+".preferences.cfg")==OK and not preferences.get_value("audio","music",true),"Music Off is saved in the QA preference file")
 game.sim.save_enabled=true;game.sim.state["settings"]["music"]=true;game.sim.save_game()
 game._action("continue")
 check(not game.sim.state["settings"]["music"] and not game.music.playing,"Continue respects newer Music Off preference")
 game.sim.save_enabled=false
 var restarted=load("res://main.tscn").instantiate();restarted.sim.save_enabled=false;restarted.sim.save_path=scratch
 root.add_child(restarted);restarted.set_process(false)
 check(not restarted.sim.state["settings"]["music"] and not restarted.music.playing,"Restart remembers Music Off before Continue")
 restarted.queue_free();await process_frame
 game._action("settings");await redraw()
 for button in game.buttons:
  check(Rect2(Vector2.ZERO,game._screen_size()).encloses(button["rect"]),"Centered dialog button stays inside screen: "+button["action"])
 click_action("close")
 check(game.modal=="","Centered dialog close uses the shifted hit region")
 game.sim.state=game.C.fresh();game.sim.state["paused"]=true;game.selected_order=0
 game.sim.order(0)["gang"]=[[0.0,0.0,11.0,14.0]];game.modal="gang";await redraw()
 var gang_center=game.GANG_POS+Vector2(5.5,7)*game.GANG_SCALE+game._modal_offset()
 mouse(gang_center,true)
 check(game.gang_drag==0,"Gang sheet selection accounts for centered dialog offset")
 var drag=InputEventMouseMotion.new();drag.position=gang_center+Vector2(9,0);game._input(drag)
 mouse(drag.position,false)
 check(is_equal_approx(float(game.sim.order(0)["gang"][0][0]),1.0),"Gang sheet drag remains accurate after fullscreen resize")
 game.modal="";game.reset_camera();game.sim.state["settings"]["music"]=false;game._start_music()
 await redraw();game.get_viewport().get_texture().get_image().save_png("res://../captures/workspace-music-off.png")
 print("SHOP_WORKSPACE: ",checks," checks, ",failures," failures")
 if "--hold" in OS.get_cmdline_user_args():game.set_process(true);return
 quit(1 if failures else 0)

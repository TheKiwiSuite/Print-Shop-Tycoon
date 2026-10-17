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
func key(code:Key):
 var event=InputEventKey.new();event.keycode=code;event.pressed=true;game._input(event)
func motion(point:Vector2):
 var event=InputEventMouseMotion.new();event.position=point;game._input(event)
func click(point:Vector2):
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed;game._input(event)
func menu(name:String):
 motion(Vector2(700,1));click(game._desktop_heading_rect(game.DESKTOP_MENUS.find(name)).get_center())
func choose(action:String):
 for button in game._desktop_targets():
  if button["action"]==action:click(button["rect"].get_center());return
 check(false,"Menu action exists: "+action)
func run():
 scratch=ProjectSettings.globalize_path("res://../../../work/window-qa-%d" % Time.get_ticks_usec())
 DirAccess.make_dir_recursive_absolute(scratch)
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;game.sim.save_path=scratch.path_join("shop.json")
 game.sim.state["settings"]["music"]=false;root.add_child(game);game.set_process(false);game.qa_ui=true
 await redraw()
 check(not game.desktop_bar,"App bar starts hidden")
 motion(Vector2(500,1));await redraw()
 check(game.desktop_bar and game.desktop_buttons.size()==8,"Top edge reveals five menus and three caption controls")
 for i in game.DESKTOP_MENUS.size():
  check(game.font.get_string_size(game.DESKTOP_MENUS[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+24<=game._desktop_heading_rect(i).size.x,"Menu label fits its hit region: "+game.DESKTOP_MENUS[i])
 for button in game.desktop_buttons:
  check(not game.SHOP_VIEW.intersects(button["rect"]),"Caption/menu heading stays outside shop: "+button["action"])
 menu("File");await redraw()
 check(game.desktop_menu=="File","File menu opens from the title screen")
 choose("save")
 check(game.desktop_menu=="File" and game.screen=="title","Disabled Save cannot alter the title screen")
 key(KEY_ESCAPE)
 check(not game.desktop_bar and game.modal=="","Escape dismisses app menu without opening Settings")
 game.screen="shop";game.sim.state=game.C.empty_shop();game.sim.state["paused"]=true;game.sim.install_equipment("dtf",Vector2i(5,5))
 game.selected_machine="dtf";game.reset_camera();await redraw()
 var before=game.sim.owner()["path"].duplicate(true)
 menu("File");click(game.SHOP_VIEW.get_center());await redraw()
 check(game.desktop_menu=="" and game.sim.owner()["path"]==before,"Outside click dismisses menu without walking through it")
 menu("Edit");key(KEY_R)
 check(game.sim.state["machines"]["dtf"]["facing"]==0,"Menu swallows hidden equipment rotation")
 choose("build");await redraw()
 check(game.build and game.desktop_menu=="","Edit starts arranging and dismisses menu")
 menu("Edit");choose("move_equipment");await redraw()
 check(game._relocating(),"Edit can move selected equipment")
 # Opening a menu intentionally cancels a held placement.
 menu("View");await redraw()
 check(not game._relocating(),"Opening menu safely cancels held equipment")
 var machines=game.sim.state["machines"].duplicate(true)
 var music_before=game.sim.state["settings"]["music"]
 choose("music");await redraw()
 check(game.sim.state["settings"]["music"]!=music_before and game.music.playing==game.sim.state["settings"]["music"],"View music action changes real playback")
 if game.sim.state["settings"]["music"]:game._action("music")
 menu("Help");choose("help");await redraw()
 check(game.modal=="help" and not game.desktop_bar,"Help opens actual instructions")
 motion(Vector2(500,1));await redraw()
 check(game.desktop_buttons.any(func(b):return b["action"]=="quit"),"Window controls remain available above modal screens")
 game._desktop_dismiss();game._action("close")
 key(KEY_F10);key(KEY_DOWN);key(KEY_RIGHT)
 check(game.desktop_menu=="Edit","F10 and arrow keys navigate menus")
 key(KEY_ESCAPE)
 key(KEY_F10);key(KEY_F10)
 check(not game.desktop_bar,"F10 toggles pinned bar off")
 for mode_action in ["window_restore","window_maximize","window_fullscreen"]:
  menu("Window");choose(mode_action)
  await create_timer(.25).timeout;await redraw()
  var expected={"window_restore":DisplayServer.WINDOW_MODE_WINDOWED,"window_maximize":DisplayServer.WINDOW_MODE_MAXIMIZED,"window_fullscreen":DisplayServer.WINDOW_MODE_FULLSCREEN}[mode_action]
  # Xvfb has no window manager; native Windows review verifies the actual OS modes.
  if OS.get_name()=="Windows":check(DisplayServer.window_get_mode()==expected,"Window action changes OS mode: "+mode_action)
  check(game.sim.state["machines"]==machines,"Window mode preserves shop equipment: "+mode_action)
  check(absf(game._screen_size().aspect()-Vector2(DisplayServer.window_get_size()).aspect())<.002,"Canvas still fills changed window")
 if OS.get_name()=="Windows":
  menu("Window");choose("window_minimize");await create_timer(.3).timeout
  check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_MINIMIZED,"Minimize menu reaches the actual minimized Windows mode")
  game._desktop_run("window_fullscreen");await create_timer(.3).timeout;await redraw()
  check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,"Minimized game can restore to fullscreen")
 menu("Window");await redraw()
 game.get_viewport().get_texture().get_image().save_png("res://../captures/window-controls.png")
 game._desktop_dismiss()
 # The caption X must use the same guarded save flow as native Alt+F4.
 game.sim.save_enabled=true;game.sim.save_path=scratch.path_join("missing/shop.json")
 motion(Vector2(500,1));choose("quit");await redraw()
 check(game.modal=="save_error" and not game.closing and game.screen=="shop","Caption Close cannot bypass a failed save")
 check(game.pending_save_action=="quit","Caption Close retains retry-save context")
 game.sim.save_path=scratch.path_join("shop.json");game._action("close")
 menu("File");choose("save");await redraw()
 check(FileAccess.file_exists(game.sim.save_path) and game.status=="Shop saved locally.","File Save writes only the isolated QA save")
 game.sim.save_enabled=false;game.build=false;game.modal="";game.sim.state["paused"]=true
 check(game.sim.state["machines"]==machines,"App menus preserve installed layout")
 print("WINDOW_CONTROLS: ",checks," checks, ",failures," failures")
 if "--hold" in OS.get_cmdline_user_args():
  game.get_window().title="Print Shop Tycoon - Window Controls QA";game.set_process(true);return
 quit(1 if failures else 0)

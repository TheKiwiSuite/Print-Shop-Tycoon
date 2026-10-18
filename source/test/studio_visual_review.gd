extends SceneTree
const Style=preload("res://scripts/shop_style.gd")
const Art=preload("res://scripts/artwork_negotiation.gd")
const Photo=preload("res://scripts/workshop_photo.gd")
var game
var folder=""
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func capture(name:String) -> void:
 game._sync_shop_name_editor();game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 game._sync_accessibility();game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 check(game.shop_name_edit.visible==(game.modal=="studio"),"Name editor belongs only to studio "+name)
 var image=game.get_viewport().get_texture().get_image();check(not image.is_empty(),"Render "+name)
 if not image.is_empty():image.save_png(folder.path_join(name+".png"))
 for i in game.buttons.size():
  var a=game.buttons[i]
  check(Rect2(Vector2.ZERO,game._screen_size()).encloses(a["rect"]),"Button fits "+name+" / "+a["action"])
  for j in range(i+1,game.buttons.size()):check(not a["rect"].intersects(game.buttons[j]["rect"]),"No button conflict "+name+" / "+a["action"]+" / "+game.buttons[j]["action"])
  var semantic=false
  for control in game.accessible_buttons.values():
   if control.visible and control.position==a["rect"].position and control.size==a["rect"].size and control.accessibility_name!="":semantic=true;break
  check(semantic,"Every visible button has its own semantic control "+a["action"])
 if game.modal=="studio":
  for button in game.buttons:check(not button["rect"].intersects(Rect2(game.shop_name_edit.position,game.shop_name_edit.size)),"Shop name field clears button "+button["action"])
func run() -> void:
 folder=ProjectSettings.globalize_path("res://../captures/strategy-review/studio");DirAccess.make_dir_recursive_absolute(folder)
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;root.add_child(game);game.set_process(false);game.music.stop()
 game.sim.start_demo();Style.ensure(game.sim);game.sim.state["settings"]["music"]=false;game.sim.state["paused"]=true
 for size in [Vector2i(1280,720),Vector2i(1426,810),Vector2i(1920,1080),Vector2i(2400,1350),Vector2i(2880,1620),Vector2i(3840,2160)]:
  root.size=size;await process_frame;game.reset_camera()
  game.screen="title";game.modal="";game.banner_index=0;await capture("%dx%d-banner-updates" % [size.x,size.y])
  game.banner_index=1;await capture("%dx%d-banner-guide" % [size.x,size.y])
  game.screen="shop";game._action("studio");await capture("%dx%d-studio" % [size.x,size.y])
  game.shop_name_edit.text="Raum's Print & DTF Shop";game._action("shop_name_save")
  game.selected_order=1
  if game.sim.order(1)["stage"]=="intake":game.sim.accept(1);game.sim.preflight(1,"repair")
  Art.propose(game.sim,1);game.modal="artwork";await capture("%dx%d-artwork" % [size.x,size.y])
  game.modal="";game._action("photo_mode");game._action("photo_logo");game._action("photo_watermark")
  game.sim.state["style"]["photo"]["logo"]=true;game.sim.state["style"]["photo"]["watermark"]=true
  for format in 3:
   game.photo_format=format;await capture("%dx%d-photo-frame-%d" % [size.x,size.y,format])
  game._action("photo_close")
 root.size=Vector2i(1920,1080);await process_frame;game.reset_camera();game.modal="";game._action("photo_mode")
 var before=game.sim.state.duplicate(true)
 for format in 3:
  var file=await Photo.export_png(game,format);check(file!="","Branded export completes")
  if file!="":
   var image=Image.load_from_file(file);check(image.get_size()==Photo.SIZES[format],"Branded image uses exact preset dimensions")
   DirAccess.copy_absolute(file,folder.path_join("branded-%dx%d.png" % [Photo.SIZES[format].x,Photo.SIZES[format].y]))
 check(game.sim.state==before,"Branded exports do not alter shop economy or settings")
 game._action("photo_close");game.free();await process_frame
 print("STUDIO VISUAL REVIEW: %d checks, %d failures" % [checks,failures]);quit(failures)

extends SceneTree
const Ops=preload("res://scripts/shop_operations.gd")
const Style=preload("res://scripts/shop_style.gd")
const Photo=preload("res://scripts/workshop_photo.gd")
var game
var folder=""
var failures=0
var checks=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func capture(name:String) -> void:
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image();check(not image.is_empty(),"Frame rendered "+name)
 if not image.is_empty():image.save_png(folder.path_join(name+".png"))
 for i in game.buttons.size():
  var a=game.buttons[i];check(Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(a["rect"]),"Button inside screen "+name+" / "+a["action"])
  for j in range(i+1,game.buttons.size()):
   var b=game.buttons[j];check(not a["rect"].intersects(b["rect"]),"No control overlaps "+name+" / "+a["action"]+" / "+b["action"])
func run() -> void:
 folder=ProjectSettings.globalize_path("res://../captures/strategy-review/workshop");DirAccess.make_dir_recursive_absolute(folder)
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;root.add_child(game);game.set_process(false)
 game.screen="shop";game.sim.start_demo();game.music.stop();Style.ensure(game.sim)
 for size in [Vector2i(1426,810),Vector2i(1920,1080)]:
  root.size=size;await process_frame;game.reset_camera();game.modal=""
  await capture("%dx%d-demo" % [size.x,size.y])
  for page in 6:
   game.modal="workshop";game.workshop_page=page
   await capture("%dx%d-workshop-%d" % [size.x,size.y,page])
  game.sim.state["operations"]["event"]={"id":"visual-supplier","kind":"supplier","resolved":false};game.workshop_page=5
  await capture("%dx%d-pending-supplier" % [size.x,size.y])
  for panel in ["help","settings","move"]:
   game.modal=panel;await capture("%dx%d-%s" % [size.x,size.y,panel])
  game.sim.state["location"]=2;game.sim.state["fit_out"]=false;game.modal="move";game.reset_camera()
  await capture("%dx%d-expanded-fitout" % [size.x,size.y])
  game.modal="equipment";game.equipment_page=1;await capture("%dx%d-equipment-prerequisites" % [size.x,size.y])
  game.sim.state["location"]=1;game.sim.start_demo();Style.ensure(game.sim);game.modal="";game.reset_camera()
 game.sim.state["cash"]=10000;game.sim.state["completed"]=5;game.sim.state["best_profit"]=100
 for id in Style.DECOR:
  var placed=false
  for x in game.sim.bounds().x:
   for y in game.sim.bounds().y:
    if Style.place(game.sim,id,Vector2i(x,y)):placed=true;break
   if placed:break
  check(placed,"Real, accessible decor placement for "+id)
 Style.set_outfit(game.sim,"owner","Executive suit");Style.set_outfit(game.sim,"staff1","Red apron")
 game.sim.state["style"]["floor"]="Blue tile";game.modal="";game.reset_camera()
 await capture("decor-clothing-floor")
 Ops.start_service(game.sim,"sticker");game.sim.state["paused"]=false
 for n in 60:game.sim.tick(.1)
 await capture("service-during-production")
 game.selected_order=1;game.sim.order(1)["stage"]="plan";Ops.begin_qte(game.sim,1,"registration");game.modal="intervention"
 await capture("registration-intervention")
 game.modal="";game._action("photo_mode");await capture("photo-preview")
 var before=game.sim.state.duplicate(true)
 for i in Photo.SIZES.size():
  var path=await Photo.export_png(game,i)
  check(path!="","Photo exports "+str(Photo.SIZES[i]))
  if path!="":
   var image=Image.load_from_file(path);check(image.get_size()==Photo.SIZES[i],"Actual PNG dimensions match preset")
   check(image.get_pixel(image.get_width()/2,image.get_height()/2).a>0,"Photo is opaque")
   DirAccess.copy_absolute(path,folder.path_join("photo-%dx%d.png" % [Photo.SIZES[i].x,Photo.SIZES[i].y]))
 check(game.sim.state==before,"Photo rendering never mutates real economy or simulation state")
 game._action("photo_close");game.sim.end_day();game.modal="cash_bridge";await capture("cash-bridge")
 game.queue_free();await process_frame
 print("WORKSHOP VISUAL REVIEW: %d checks, %d failures" % [checks,failures]);quit(failures)

extends SceneTree
const C=preload("res://scripts/catalog.gd")
var game
var failures=0
var folder=""
var matrix=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok: failures+=1;push_error("FAIL: "+label)
func capture(name:String) -> void:
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 game._sync_accessibility()
 var image=game.get_viewport().get_texture().get_image()
 check(not image.is_empty(),"Rendered frame exists: "+name)
 if not image.is_empty(): image.save_png(folder+"/"+name+".png")
 var outside=[]
 for button in game.buttons:
  if not Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(button["rect"]): outside.append(button["action"])
 check(outside.is_empty(),"Input rectangles stay in viewport "+name+str(outside))
 check(game.accessible_buttons.size()>0,"Native accessible controls exist "+name)
 matrix.append({"screen":name,"size":[game.get_viewport_rect().size.x,game.get_viewport_rect().size.y],"buttons":game.buttons.size(),"outside":outside})
func run() -> void:
 folder=ProjectSettings.globalize_path("res://../captures/strategy-review")
 DirAccess.make_dir_recursive_absolute(folder)
 game=load("res://main.tscn").instantiate();root.add_child(game);game.set_process(false)
 game.sim.save_enabled=false;game.sim.save_path="user://strategy-visual-qa.json"
 game.screen="shop";game.sim.state=C.fresh();game.sim.owner()["manual"]=false
 game.sim.state["settings"]["music"]=false;game.music.stop()
 game.sim.Strategy.ensure(game.sim)
 for size in [Vector2i(1280,720),Vector2i(1442,842),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;await process_frame;game.reset_camera()
  for panel in ["capacity","difficulty","move","roster","help","settings","order"]:
   game.modal=panel;game.selected_order=0
   if panel=="move": game.sim.state["rules"]["version"]=1
   await capture("%dx%d-%s" % [size.x,size.y,panel])
 # Asset contact sheet is rendered from the exact approved runtime textures.
 root.size=Vector2i(1600,900);await process_frame
 for kind in game.illustrated:
  game.modal="dtf_views";game.dtf_view_index=0
  for texture in game.illustrated[kind]:
   check(texture.get_width()>0 and texture.get_height()>0,"Nonempty approved asset "+kind)
 game.modal="";game.sim.state=C.fresh();game.sim.owner()["manual"]=false
 game.sim.accept(0);game.sim.preflight(0,"repair");game.sim.auto_pack(0);game.sim.queue_order(0)
 for n in 600:
  game.sim.tick(.1)
  if game.sim.order(0)["stage"]=="production": break
 game.reset_camera();await capture("active-production")
 var before=game.sim.station_activity("dtf")["elapsed"]
 game.sim.state["paused"]=true;game.sim.tick(.1)
 check(game.sim.station_activity("dtf")["elapsed"]==before,"Task-linked animation clock freezes with pause")
 await capture("paused-production")
 var file=FileAccess.open(folder+"/matrix.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"renderer":"Godot viewport","scope":"Linux render and input-rectangle checks; not Windows scaling or screen-reader certification","failures":failures,"matrix":matrix},"  "))
 print("STRATEGY VISUAL REVIEW: ",matrix.size()," screens, ",failures," failures")
 game.free();await process_frame
 quit(failures)

extends SceneTree
const C=preload("res://scripts/catalog.gd")
var game
var failures=0
var folder=""
var matrix=[]
class ContactSheet extends Node2D:
 var entries=[]
 func _draw() -> void:
  draw_rect(Rect2(0,0,1440,ceilf(entries.size()/8.0)*150),Color("eef1e7"))
  for i in entries.size():
   var entry=entries[i];var p=Vector2((i%8)*180,(i/8)*150)
   var box=Rect2(p+Vector2(8,6),Vector2(164,116))
   draw_rect(box,Color.WHITE)
   var texture=entry["texture"]
   var size=Vector2(texture.get_width(),texture.get_height())
   size*=minf(box.size.x/size.x,box.size.y/size.y)
   draw_texture_rect(texture,Rect2(box.get_center()-size*.5,size),false,entry.get("tint",Color.WHITE))
   draw_string(ThemeDB.fallback_font,p+Vector2(9,141),entry["label"],HORIZONTAL_ALIGNMENT_LEFT,164,13,Color("17324e"))
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
func contact_sheet(name:String,entries:Array) -> void:
 var view=SubViewport.new();view.size=Vector2i(1440,ceili(entries.size()/8.0)*150)
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var sheet=ContactSheet.new();sheet.entries=entries;view.add_child(sheet)
 await process_frame;await RenderingServer.frame_post_draw
 var picture=view.get_texture().get_image()
 check(not picture.is_empty(),"Contact sheet renders "+name)
 picture.save_png(folder+"/"+name+".png")
 view.queue_free();await process_frame
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
  for panel in ["capacity","difficulty","move","roster","help","settings","order","accessibility","updates","staff","stock","customers","equipment","gang","report","marketing","dtf_views"]:
   game.sim.state=C.fresh();game.sim.Strategy.ensure(game.sim)
   game.forecast_preview={}
   game.modal=panel;game.selected_order=0
   if panel=="move": game.sim.state["rules"]["version"]=1
   if panel=="gang": game.sim.accept(0);game.sim.preflight(0,"repair");game.sim.auto_pack(0)
   await capture("%dx%d-%s" % [size.x,size.y,panel])
 # Asset contact sheet is rendered from the exact approved runtime textures.
 root.size=Vector2i(1600,900);await process_frame
 var assets=[]
 for kind in game.illustrated:
  game.modal="dtf_views";game.dtf_view_index=0
  for facing in game.illustrated[kind].size():
   var texture=game.illustrated[kind][facing]
   check(texture.get_width()>0 and texture.get_height()>0,"Nonempty approved asset "+kind)
   assets.append({"texture":texture,"label":kind+" / "+str(facing*22.5)+" deg"})
 await contact_sheet("equipment-contact-sheet",assets)
 var people=[]
 for variant in 4:
  for frame in 16:
   var texture=AtlasTexture.new();texture.atlas=game.owner_sheet
   var size=Vector2(game.owner_sheet.get_width()/4.0,game.owner_sheet.get_height()/4.0)
   texture.region=Rect2(Vector2(frame%4,frame/4)*size,size)
   people.append({"texture":texture,"label":"Variant %d / frame %d" % [variant,frame],"tint":[Color.WHITE,Color("ffcfad"),Color("edcaff"),Color("d5f1b1")][variant]})
 await contact_sheet("character-contact-sheet",people)
 for type in ["transfer","apparel","sticker","banner","cnc"]:
  game.sim.state=C.fresh();game.sim.state["orders"]=[C.make_order("VISUAL-"+type,type,3,"Long customer name for safe wrapping / approved artwork",8,180)]
  game.modal="order";game.selected_order=0;game.forecast_preview={}
  await capture("product-"+type)
  game.sim.order(0)["stage"]="plan";game.sim.order(0)["art_ready"]=true
  await capture("preset-"+type)
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

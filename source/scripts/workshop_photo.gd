extends RefCounted
const SIZES=[Vector2i(1920,1080),Vector2i(1080,1080),Vector2i(1080,1350)]
static func ensure(s) -> void:
 preload("res://scripts/shop_style.gd").ensure(s)
 if not s.state["style"].get("photo") is Dictionary:s.state["style"]["photo"]={"logo":false,"watermark":false,"corner":3,"opacity":.75}
static func crop_rect(g,index:int) -> Rect2:
 var screen=g._screen_size();var ratio=float(SIZES[index].x)/SIZES[index].y
 var width=minf(screen.x,screen.y*ratio);var height=width/ratio
 return Rect2((screen-Vector2(width,height))*.5,Vector2(width,height))
static func draw(g) -> void:
 var screen=g._screen_size();var crop=crop_rect(g,g.photo_format);var width=crop.size.x
 draw_brand(g,crop)
 g.draw_rect(Rect2(0,0,crop.position.x,screen.y),Color(0,0,0,.5))
 g.draw_rect(Rect2(crop.end.x,0,screen.x-crop.end.x,screen.y),Color(0,0,0,.5))
 g.draw_rect(Rect2(crop.position.x,0,width,crop.position.y),Color(0,0,0,.5))
 g.draw_rect(Rect2(crop.position.x,crop.end.y,width,screen.y-crop.end.y),Color(0,0,0,.5))
 g.draw_rect(crop.grow(-2),g.CREAM,false,2)
 g._panel(Rect2(20,20,750,116),g.CREAM)
 g._text(Vector2(38,49),"PHOTO MODE / shop paused / local files only",21,g.BLUE)
 g._text(Vector2(38,78),"Wheel: zoom / middle-drag: pan / Home: fit / Escape: return",16,g.INK)
 for i in SIZES.size():g._button(Rect2(800+i*230,24,220,42),str(SIZES[i].x)+" x "+str(SIZES[i].y),"photo_format:"+str(i),g.YELLOW if i==g.photo_format else g.CREAM,not g.photo_busy,16)
 g._button(Rect2(800,80,320,36),"IMPORTED ART: "+("INCLUDE" if g.photo_imported else "EXCLUDE"),"photo_imported",g.CREAM,true,14)
 g._button(Rect2(1130,80,360,36),"RETURN TO SHOP","photo_close",g.NAVY,true,16)
 g._button(Rect2(800,130,690,38),"EXPORT SELECTED FRAME AS LOCAL PNG","photo_export:"+str(g.photo_format),g.CYAN,not g.photo_busy,16)
 var brand=g.sim.state.get("style",{}).get("photo",{})
 g._button(Rect2(800,184,210,35),"GAME LOGO: "+("ON" if brand.get("logo",false) else "OFF"),"photo_logo",g.CREAM,true,14)
 g._button(Rect2(1020,184,230,35),"SHOP WATERMARK: "+("ON" if brand.get("watermark",false) else "OFF"),"photo_watermark",g.CREAM,true,13)
 g._button(Rect2(1260,184,230,35),["TOP LEFT","TOP RIGHT","BOTTOM LEFT","BOTTOM RIGHT"][int(brand.get("corner",3))],"photo_corner",g.CREAM,true,13)
 g._button(Rect2(800,234,210,32),"OPACITY: %d%%" % roundi(float(brand.get("opacity",.75))*100),"photo_opacity",g.CREAM,true,14)
 g._line(Vector2(1025,256),"Watermark text uses your saved shop name.",14,g.INK,465)
 g._line(Vector2(38,109),g.status,13,g.BLUE,710)
static func export_png(g,index:int) -> String:
 if index<0 or index>=SIZES.size() or g.photo_busy:return ""
 g.photo_busy=true
 var viewport=SubViewport.new();viewport.size=SIZES[index];viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 viewport.handle_input_locally=false;g.add_child(viewport)
 var scene=load("res://main.tscn").instantiate()
 scene.photo_render=true;scene.photo_imported=g.photo_imported
 scene.sim.state=g.sim.state.duplicate(true);scene.sim.save_enabled=false
 viewport.add_child(scene);scene.set_process(false);scene.screen="shop"
 # Preserve the user's composition relative to the visible viewport.
 var screen=g._screen_size();var target=Vector2(SIZES[index]);var scale=maxf(target.x/screen.x,target.y/screen.y)
 scene.zoom=g.zoom*scale;scene.offset=g.offset*scale
 scene.origin=g.origin*scale+(target-screen*scale)*.5
 scene.queue_redraw();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image=viewport.get_texture().get_image()
 var directory=OS.get_user_data_dir().path_join("photos");DirAccess.make_dir_recursive_absolute(directory)
 var path=directory.path_join("Print-Shop-%s-%s-%s.png" % [str(Time.get_unix_time_from_system()).replace(".","-"),str(SIZES[index].x),str(Time.get_ticks_usec())])
 var error=image.save_png(path);viewport.queue_free();g.photo_busy=false
 g.status="Saved local PNG: "+path if error==OK else "Photo could not be saved. Try a writable local folder."
 return path if error==OK else ""

static func draw_brand(g,crop:Rect2) -> void:
 var style=g.sim.state.get("style",{});var brand=style.get("photo",{})
 var logo=brand.get("logo",false);var watermark=brand.get("watermark",false)
 if not logo and not watermark:return
 var alpha=clampf(float(brand.get("opacity",.75)),.25,1.0);var corner=clampi(int(brand.get("corner",3)),0,3)
 var scale=maxf(.6,crop.size.y/900.0);var margin=24*scale
 var width=minf(290*scale,crop.size.x-margin*2);var logo_size=Vector2(width,width*.31)
 var height=(logo_size.y if logo else 0)+(32*scale if watermark else 0)
 var p=crop.position+Vector2(margin,margin)
 if corner%2==1:p.x=crop.end.x-margin-width
 if corner>=2:p.y=crop.end.y-margin-height
 if logo:
  g.draw_texture_rect(g.official_logo,Rect2(p,logo_size),false,Color(1,1,1,alpha));p.y+=logo_size.y
 if watermark:
  var text=str(style.get("shop_name","My Print Shop"))
  g._line(p+Vector2(2,26)*scale,text,int(21*scale),Color(0,0,0,alpha),width,true)
  g._line(p+Vector2(0,24)*scale,text,int(21*scale),Color(1,1,1,alpha),width,true)

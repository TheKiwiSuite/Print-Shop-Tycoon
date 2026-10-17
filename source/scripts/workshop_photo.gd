extends RefCounted
const SIZES=[Vector2i(1920,1080),Vector2i(1080,1080),Vector2i(1080,1350)]
static func draw(g) -> void:
 var screen=g._screen_size();var ratio=float(SIZES[g.photo_format].x)/SIZES[g.photo_format].y
 var width=minf(screen.x,screen.y*ratio);var height=width/ratio
 var crop=Rect2((screen-Vector2(width,height))*.5,Vector2(width,height))
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

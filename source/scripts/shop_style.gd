extends RefCounted
const DECOR={"shirt_rack":{"price":120,"width":2,"title":"T-shirt display rack"},"sample_wall":{"price":80,"width":1,"title":"Printed sample stand"},"plant":{"price":40,"width":1,"title":"Plant"},"banner_stand":{"price":90,"width":1,"title":"Shop-made banner stand"},"transfer_rack":{"price":100,"width":2,"title":"Transfer / packing rack"}}
const FLOORS={"Original":"", "Warm oak":"d5a969","Cool concrete":"a9b4bf","Blue tile":"91b6c9","Graphite":"707d89","Cream tile":"ddd6be"}
const OUTFITS=["Workshop","Blue apron","Red apron","Executive suit"]
static func ensure(s) -> void:
 if not s.state.get("style") is Dictionary:s.state["style"]={}
 var defaults={"decor":[],"floor":"Original","floor_image":"","outfits":{},"shop_name":"My Print Shop","next_decor":0}
 for key in defaults:
  if not s.state["style"].has(key):s.state["style"][key]=defaults[key]
static func item(s,id:String) -> Dictionary:
 ensure(s)
 for decor in s.state["style"]["decor"]:
  if decor["id"]==id:return decor
 return {}
static func _validate_layout(s) -> String:
 var occupied={};var size=s.bounds()
 for decor in s.state["style"]["decor"]:
  for dx in int(decor["width"]):
   var at=s.cell(decor["pos"])+Vector2i(dx,0)
   if not s.inside(at) or at==s.entrance() or occupied.has(at):return "Decor needs clear floor inside the shop and must preserve the entrance."
   occupied[at]=true
 for decor_cell in occupied:
  for w in s.state["workers"]:
   if s.cell(w["pos"])==decor_cell:return "A worker is standing there. Choose clear floor."
  for actor in s.visible_customers():
   if s.cell(actor["pos"])==decor_cell:return "A customer is standing there. Choose clear floor."
 # Placement feedback checks all physical footprints and DTF loading clearances.
 # Suppress only the 'moving busy machine' guard: no machine is actually moved.
 var actual=s.state["machines"];var check_machines=actual.duplicate(true)
 for m in check_machines.values():m["active"]=-1;m.erase("service_work")
 s.state["machines"]=check_machines
 var reason=""
 for id in check_machines:
  var m=check_machines[id]
  var feedback=s.placement_feedback(id,s.cell(m["pos"]),int(m["rotation"]),s.facing_of(m),s.equipment_center(id,check_machines))
  if not feedback["valid"]:reason=feedback["reason"]
  break
 s.state["machines"]=actual
 if reason!="":return reason
 var routes={}
 for w in s.state["workers"]:
  if w["path"].is_empty():continue
  var goal=s.cell(w["path"][-1]);var route=s.path(s.cell(w["pos"]),goal)
  if goal!=s.cell(w["pos"]) and route.is_empty():return "That display would cut off a worker's route."
  routes[w["id"]]=route
 for id in routes:s.worker(id)["path"]=routes[id]
 s._reroute_customers();return ""
static func place(s,kind:String,at:Vector2i) -> bool:
 ensure(s)
 if not DECOR.has(kind):return false
 var spec=DECOR[kind]
 if s.state["cash"]<spec["price"]:s.notice("Not enough cash for this decor.");return false
 var before=s.state.duplicate(true)
 s.state["style"]["decor"].append({"id":"decor-"+str(s.state["style"]["next_decor"]),"kind":kind,"pos":[at.x,at.y],"width":spec["width"]})
 var reason=_validate_layout(s)
 if reason!="":s.state=before;s.notice(reason);return false
 s.state["style"]["next_decor"]+=1;s.state["cash"]-=spec["price"];s.state["stats"]["capex"]=s.state["stats"].get("capex",0)+spec["price"]
 s.notice("Placed "+spec["title"]+". Decor changes presentation, not machine throughput.")
 if not s.save_game():s.state=before;return false
 return true
static func move(s,id:String,at:Vector2i) -> bool:
 var decor=item(s,id)
 if decor.is_empty():return false
 var before=s.state.duplicate(true);decor["pos"]=[at.x,at.y]
 var reason=_validate_layout(s)
 if reason!="":s.state=before;s.notice(reason);return false
 s.notice("Display moved. Cash, ownership and its saved ID are unchanged.")
 if not s.save_game():s.state=before;return false
 return true
static func remove(s,id:String="") -> bool:
 ensure(s)
 var items=s.state["style"]["decor"]
 if items.is_empty():return false
 if id=="":id=items[-1]["id"]
 var decor=item(s,id)
 if decor.is_empty():return false
 var before=s.state.duplicate(true);items.erase(decor);s._reroute_customers()
 s.notice("Selected decor removed. No resale cash is created.")
 if not s.save_game():s.state=before;return false
 return true
static func rename_shop(s,value:String) -> bool:
 ensure(s)
 var name=""
 for character in value:
  var code=character.unicode_at(0)
  if code>=32 and code!=127:name+=character
 name=name.strip_edges()
 if name.is_empty() or name.length()>40:s.notice("Enter a shop name from 1 to 40 characters.");return false
 var previous=s.state["style"]["shop_name"];s.state["style"]["shop_name"]=name
 if not s.save_game():s.state["style"]["shop_name"]=previous;return false
 s.notice("Shop sign saved: "+name);return true
static func sign_lines(s) -> Array:
 var name=str(s.state.get("style",{}).get("shop_name","My Print Shop"));var lines=[]
 while name.length()>0:lines.append(name.left(12));name=name.substr(12)
 return lines
static func import_png(s,path:String) -> bool:
 ensure(s)
 if path.get_extension().to_lower()!="png":s.notice("Choose a PNG image.");return false
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>8*1024*1024:s.notice("Floor PNG must be no larger than 8 MB.");return false
 var bytes=file.get_buffer(file.get_length());file.close()
 # Read the PNG header before decoding to reject decompression bombs.
 if bytes.size()<24 or bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]):return false
 var width=(int(bytes[16])<<24)|(int(bytes[17])<<16)|(int(bytes[18])<<8)|int(bytes[19])
 var height=(int(bytes[20])<<24)|(int(bytes[21])<<16)|(int(bytes[22])<<8)|int(bytes[23])
 if width<1 or height<1 or width>2048 or height>2048 or width*height>4194304:s.notice("Use a PNG up to 2048 by 2048 pixels.");return false
 var image=Image.new()
 if image.load_png_from_buffer(bytes)!=OK:return false
 var directory=OS.get_user_data_dir().path_join("custom-floors");DirAccess.make_dir_recursive_absolute(directory)
 var hash=bytes.hex_encode().sha256_text();var destination=directory.path_join(hash+".png")
 if image.save_png(destination)!=OK:return false
 s.state["style"]["floor_image"]=destination;s.notice("Floor PNG copied locally. It is never uploaded and is excluded from photos unless you opt in.");s.save_game();return true
static func set_outfit(s,id:String,outfit:String) -> bool:
 ensure(s)
 if s.worker(id).is_empty() or not OUTFITS.has(outfit):return false
 if outfit=="Executive suit" and (int(s.state["completed"])<5 or float(s.state["best_profit"])<=0):s.notice("Executive clothing unlocks after five fulfilled jobs and a profitable day.");return false
 s.state["style"]["outfits"][id]=outfit;return true
static func draw_decor(g,item:Dictionary) -> void:
 var p=g.iso(Vector2(item["pos"][0],item["pos"][1]));var z=g.zoom;var kind=item["kind"]
 if kind=="plant":g._sprite(8,p,63);return
 g._oval(p+Vector2(0,3)*z,Vector2(33,13)*z,Color(0,0,0,.15))
 if kind in ["shirt_rack","transfer_rack"]:
  for dx in [-28,28]:g.draw_line(p+Vector2(dx,0)*z,p+Vector2(dx,-76)*z,Color("536775"),5*z)
  g.draw_line(p+Vector2(-28,-74)*z,p+Vector2(28,-74)*z,Color("a7b6bf"),6*z)
  for i in 4:
   var at=p+Vector2(-22+i*14,-66)*z
   var color=[Color("163b62"),Color("f4f1df"),Color("dc5a70"),Color("34a8b4")][i]
   if kind=="shirt_rack":g._poly([at+Vector2(-8,5)*z,at+Vector2(-4,0)*z,at+Vector2(4,0)*z,at+Vector2(8,5)*z,at+Vector2(5,11)*z,at+Vector2(4,33)*z,at+Vector2(-4,33)*z,at+Vector2(-5,11)*z],color,g.INK,1)
   else:g._panel(Rect2(at+Vector2(-6,5)*z,Vector2(11,36)*z),color,g.INK,2)
 else:
  g.draw_line(p,p+Vector2(0,-80)*z,g.NAVY,4*z)
  var box=Rect2(p+Vector2(-30,-83)*z,Vector2(60,65)*z)
  g._panel(box,Color("fff5df"),g.NAVY,3)
  g.draw_circle(box.get_center(),15*z,g.CYAN)
  g._line(box.position+Vector2(5,55)*z,"PRINTED HERE",maxi(9,int(9*z)),g.BLUE,box.size.x-10*z)
static var palette_cache={}
static func texture_for(sheet:Texture2D,outfit:String) -> Texture2D:
 if outfit=="Workshop":return sheet
 if palette_cache.has(outfit):return palette_cache[outfit]
 var image=sheet.get_image();var cell=Vector2i(image.get_width()/4,image.get_height()/4)
 # Recolour existing cloth pixels in every original pose. Faces, hats, skin,
 # silhouettes and animation frames remain unchanged; no floating costume slab.
 for row in 4:
  for col in 4:
   var top=.43 if outfit=="Executive suit" else .52
   var bottom=.88 if outfit=="Executive suit" else .73
   for y in range(int(cell.y*top),int(cell.y*bottom)):
    for x in range(int(cell.x*.28),int(cell.x*.78)):
     var at=Vector2i(col*cell.x+x,row*cell.y+y);var pixel=image.get_pixelv(at)
     if pixel.a<.2 or pixel.h<.50 or pixel.h>.68 or pixel.s<.18:continue
     var color=pixel
     if outfit=="Executive suit":color=Color.from_hsv(.59,.20,clampf(pixel.v*.65+.04,.05,.6),pixel.a)
     elif outfit=="Red apron":color=Color.from_hsv(.965,.72,clampf(pixel.v*1.45,0,1),pixel.a)
     else:color=Color.from_hsv(.58,.80,clampf(pixel.v*1.12,0,1),pixel.a)
     image.set_pixelv(at,color)
 var texture=ImageTexture.create_from_image(image);palette_cache[outfit]=texture;return texture
static func draw_outfit(g,w:Dictionary,p:Vector2) -> void:
 var outfit=g.sim.state.get("style",{}).get("outfits",{}).get(w["id"],"Workshop")
 if outfit!="Executive suit" or int(w["face"])>=2:return
 var z=g.zoom;var at=p+Vector2(8,-47)*z
 g._poly([at+Vector2(-6,-10)*z,at+Vector2(0,-5)*z,at+Vector2(-2,7)*z],Color("e9e6df"),Color.TRANSPARENT,0)
 g._poly([at+Vector2(6,-10)*z,at+Vector2(0,-5)*z,at+Vector2(2,7)*z],Color("d7dce0"),Color.TRANSPARENT,0)
 g._poly([at+Vector2(0,-6)*z,at+Vector2(2,-3)*z,at+Vector2(1,8)*z,at+Vector2(-2,7)*z,at+Vector2(-1,-3)*z],Color("ab294b"),Color.TRANSPARENT,0)

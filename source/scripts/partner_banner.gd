extends RefCounted
# Local title-screen artwork and explicit links. Shipped entries point only to this project.
const BUILTIN_ART=["res://assets/banners/project-updates.svg","res://assets/banners/workshop-guide.svg"]
static var textures={}
static func read_config(path:String="user://partner-banners.json") -> Array:
 if not FileAccess.file_exists(path):path="res://config/partner-banners.json"
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>65536:return []
 var data=JSON.parse_string(file.get_as_text())
 if not data is Dictionary or data.get("version",0)!=1 or not data.get("banners") is Array:return []
 var result=[];var ids={}
 var url=RegEx.new();url.compile("^https://[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z]{2,}(?::443)?(?:[/\\?#][^\\s]*)?$")
 for item in data["banners"].slice(0,12):
  if not item is Dictionary or not item.get("enabled",false):continue
  var id=str(item.get("id",""));var target=str(item.get("url",""));var title=str(item.get("title",""));var caption=str(item.get("caption",""))
  if id.is_empty() or ids.has(id) or title.is_empty() or title.length()>70 or caption.length()>150 or target.length()>2048 or url.search(target)==null or "@" in target:continue
  var now=int(Time.get_unix_time_from_system())
  if now<int(item.get("starts",0)) or (int(item.get("ends",0))>0 and now>int(item["ends"])):continue
  var art=str(item.get("art",""))
  if not art.is_empty() and art not in BUILTIN_ART:
   var root=OS.get_user_data_dir().path_join("partner-art")
   if art.get_extension().to_lower()!="png" or art.simplify_path().get_base_dir()!=root:continue
   var file_art=FileAccess.open(art,FileAccess.READ)
   if file_art==null or file_art.get_length()>8*1024*1024:continue
   var bytes=file_art.get_buffer(file_art.get_length());file_art.close()
   if bytes.size()<24 or bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]):continue
   var w=(int(bytes[16])<<24)|(int(bytes[17])<<16)|(int(bytes[18])<<8)|int(bytes[19]);var h=(int(bytes[20])<<24)|(int(bytes[21])<<16)|(int(bytes[22])<<8)|int(bytes[23])
   if w<1 or h<1 or w>2048 or h>2048:continue
   var image=Image.new()
   if image.load_png_from_buffer(bytes)!=OK:continue
   textures[art]=ImageTexture.create_from_image(image)
  ids[id]=true;result.append({"id":id,"url":target,"title":title,"caption":caption,"art":art})
 return result
static func tick(g,delta:float) -> void:
 if g.screen!="title" or g.modal!="" or g.desktop_menu!="" or not g.get_window().has_focus() or g.banner_paused or g.sim.state["settings"].get("reduce_motion",false):return
 g.banner_elapsed+=delta
 if g.banner_elapsed>=12:g.banner_elapsed=0;g.banner_index+=1
static func draw(g) -> void:
 if g.partner_banners.is_empty():return
 var index=posmod(g.banner_index,g.partner_banners.size());var item=g.partner_banners[index]
 g._panel(Rect2(20,360,365,338),g.CREAM)
 g._text(Vector2(36,387),"PROJECT LINKS / OPENS YOUR BROWSER",12,g.MUTED)
 var art=item.get("art","")
 if art in BUILTIN_ART and not textures.has(art):textures[art]=load(art)
 if textures.has(art):
  g.draw_texture_rect(textures[art],Rect2(36,404,333,110),false)
  if art in BUILTIN_ART:g._logo(Vector2(42,419),.6)
 else:g._logo(Vector2(36,407),.95)
 g._line(Vector2(36,545),item["title"],20,g.BLUE,333,true)
 g._text(Vector2(36,575),item["caption"],15,g.INK,333)
 g._button(Rect2(36,612,333,32),"OPEN WEBSITE","partner:"+str(index),g.CYAN,true,14)
 g._button(Rect2(36,655,94,25),"PREVIOUS","banner_previous",g.CREAM,g.partner_banners.size()>1,11)
 g._button(Rect2(141,655,113,25),"RESUME" if g.banner_paused else "PAUSE ROTATION","banner_pause",g.CREAM,true,11)
 g._button(Rect2(265,655,104,25),"NEXT","banner_next",g.CREAM,g.partner_banners.size()>1,11)

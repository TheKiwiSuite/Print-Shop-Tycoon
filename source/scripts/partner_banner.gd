extends RefCounted
# Optional title-screen content only. Release destinations intentionally remain blank.
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
  ids[id]=true;result.append({"id":id,"url":target,"title":title,"caption":caption})
 return result
static func draw(g) -> void:
 if g.partner_banners.is_empty():return
 var item=g.partner_banners[int(g.time/12)%g.partner_banners.size()]
 g._panel(Rect2(20,430,365,166),g.CREAM)
 g._text(Vector2(36,455),"PARTNER / EXTERNAL LINK",12,g.MUTED)
 g._text(Vector2(36,485),item["title"],19,g.BLUE,330)
 g._text(Vector2(36,522),item["caption"],15,g.INK,330)
 g._button(Rect2(36,550,333,32),"OPEN PARTNER WEBSITE","partner:"+str(g.partner_banners.find(item)),g.CYAN,true,13)

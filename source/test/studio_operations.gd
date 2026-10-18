extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Style=preload("res://scripts/shop_style.gd")
const Art=preload("res://scripts/artwork_negotiation.gd")
const Banner=preload("res://scripts/partner_banner.gd")
const Photo=preload("res://scripts/workshop_photo.gd")
var checks=0
var failures=0
func check(value:bool,label:String) -> void:
 checks+=1
 if value:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func fixture():
 var s=Sim.new();s.save_enabled=false;s.start_demo();s.state["orders"]=[];s.state["cash"]=10000;s.state["paused"]=true
 for w in s.state["workers"]:w["task"]={};w["path"]=[]
 Style.ensure(s);return s
func valid_place(s,kind:String) -> bool:
 for x in s.bounds().x:
  for y in s.bounds().y:
   if Style.place(s,kind,Vector2i(x,y)):return true
 return false
func _initialize():call_deferred("run")
func run() -> void:
 var s=fixture()
 check(valid_place(s,"shirt_rack") and valid_place(s,"plant"),"Purchase separate decor items with stable IDs")
 var id=s.state["style"]["decor"][0]["id"];var original=Style.item(s,id).duplicate(true);var cash=s.state["cash"];var count=s.state["style"]["decor"].size()
 check(not Style.move(s,id,s.entrance()),"Moving decor cannot block the entrance")
 check(Style.item(s,id)==original and s.state["cash"]==cash,"Rejected move retains position, ownership and cash")
 var moved=false
 for x in s.bounds().x:
  for y in s.bounds().y:
   var at=Vector2i(x,y)
   if at!=s.cell(original["pos"]) and Style.move(s,id,at):moved=true;break
  if moved:break
 check(moved and Style.item(s,id)["id"]==id and s.state["style"]["decor"].size()==count,"Valid move retains ID and item count")
 check(s.state["cash"]==cash,"Moving a purchased display never charges again")
 check(Style.remove(s,id) and Style.item(s,id).is_empty() and s.state["style"]["decor"].size()==count-1,"Remove acts on selected item, not the last item")
 check(s.state["cash"]==cash,"Removing decor invents no resale money")
 check(Style.rename_shop(s,"Raum's Print & DTF Shop"),"Shop sign accepts plain-text punctuation")
 check(not Style.rename_shop(s,"") and not Style.rename_shop(s,"x".repeat(41)),"Empty and overlong shop names are rejected")
 check(Style.rename_shop(s,"Line\nBreak\tShop") and s.state["style"]["shop_name"]=="LineBreakShop","Sign strips control characters")
 Photo.ensure(s);s.state["style"]["photo"]={"logo":true,"watermark":true,"corner":0,"opacity":.5}
 s.save_path="user://studio-persist-"+str(Time.get_ticks_usec())+".json";s.save_enabled=true
 check(s.save_game(),"Studio settings save atomically")
 var restored=Sim.new();restored.save_path=s.save_path
 check(restored.load_game() and restored.state["style"]["shop_name"]==s.state["style"]["shop_name"] and restored.state["style"]["decor"][0]["id"]==s.state["style"]["decor"][0]["id"] and restored.state["style"]["photo"]["logo"] and is_equal_approx(float(restored.state["style"]["photo"]["opacity"]),.5),"Decor, signage and photo branding survive reload")
 for choice in ["customer","studio","express","keep"]:
  s=fixture();var o=C.make_order("ART-"+choice,"sticker",24,"Revision test",s.now()+6,200);s.state["orders"]=[o]
  check(s.accept(0) and s.preflight(0,"repair"),"Prepare accepted artwork agreement "+choice)
  var due=o["due"];var reward=o["reward"];cash=s.state["cash"];var stock=s.state["stock"].duplicate(true);var roll=o.get("fault_roll",-1)
  check(Art.propose(s,0) and o["due"]==due and o["reward"]==reward and s.state["cash"]==cash,"Offering revision never changes committed terms "+choice)
  check(not s.queue_order(0),"Pending artwork approval prevents production "+choice)
  check(Art.resolve(s,0,choice),"Explicit revised agreement resolves "+choice)
  var after=s.state.duplicate(true)
  check(not Art.resolve(s,0,choice) and s.state==after,"Revision cannot replay charges or terms "+choice)
  check(o.get("fault_roll",-1)==roll and s.state["stock"]==stock,"Negotiation preserves quality roll and stock "+choice)
  if choice=="keep":check(o["due"]==due and o["reward"]==reward and s.state["cash"]==cash,"Declining keeps original brief without trust penalty")
  else:
   var cost={"customer":0,"studio":30,"express":50}[choice]
   check(s.state["cash"]==cash-cost and o["stage"]=="revision" and not o["art_ready"],"Revision cost and waiting state are real "+choice)
   s.state["paused"]=false
   for n in 2500:
    s.tick(.1)
    if o["stage"]=="plan":break
   check(o["stage"]=="plan" and o["art_ready"] and o["artwork_version"]==2,"Revised proof returns through ordinary planning "+choice)
 s=fixture();s.state["orders"]=[C.make_order("PRINTED","transfer",5,"Already printed",10,100)];s.order(0)["stage"]="qc";s.order(0)["consumed"]=true
 check(not Art.propose(s,0),"Already consumed production cannot be rewritten as a cheap revision")
 s=fixture();s.state["orders"]=[C.make_order("POOR","sticker",3,"Cash check",8,100)];s.accept(0);s.preflight(0,"repair");Art.propose(s,0);s.state["cash"]=0
 var old=s.state.duplicate(true)
 check(not Art.resolve(s,0,"studio") and s.order(0)["due"]==old["orders"][0]["due"] and s.order(0)["reward"]==old["orders"][0]["reward"],"Insufficient revision cash leaves accepted terms fixed")
 var entries=Banner.read_config("res://config/partner-banners.json")
 check(entries.size()==2 and entries.all(func(e):return e["url"].begins_with("https://github.com/TheKiwiSuite/Print-Shop-Tycoon/") and e["art"] in Banner.BUILTIN_ART),"Shipped destinations are explicit official project pages with safe local artwork")
 var file=FileAccess.open("user://bad-banners.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":1,"banners":[{"id":"bad","enabled":true,"title":"Bad","url":"javascript:alert(1)","art":"https://example.com/pixel.png"},{"id":"bad2","enabled":true,"title":"Bad","url":"https://github.com/","art":"user://partner-art/../other.png"}]}));file.close()
 check(Banner.read_config("user://bad-banners.json").is_empty(),"Script URLs, remote art and path traversal are rejected")
 var game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;root.add_child(game);game.set_process(false);game.screen="shop";game.sim.start_demo();game.music.stop()
 game._action("studio");game.shop_name_edit.text="Space Walk Studio";game._sync_accessibility()
 check(game.shop_name_edit.visible and game.shop_name_edit.has_focus(),"Shop name is a focused native accessible text control")
 var key=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true;var paused=game.sim.state["paused"];game._input(key)
 check(game.sim.state["paused"]==paused,"Typing spaces in the sign does not pause gameplay")
 game._action("shop_name_save");check(game.sim.state["style"]["shop_name"]=="Space Walk Studio","Native editor saves the wall sign")
 game._action("photo_mode");game._action("photo_logo");game._action("photo_watermark");game._action("photo_corner");game._action("photo_opacity")
 check(game.sim.state["style"]["photo"]["logo"] and game.sim.state["style"]["photo"]["watermark"],"Photo logo and watermark controls are connected")
 game._action("photo_close");check(not game.photo_active,"Branded photo mode returns to the shop")
 game.queue_free();await process_frame
 print("STUDIO OPERATIONS: %d checks, %d failures" % [checks,failures]);quit(failures)

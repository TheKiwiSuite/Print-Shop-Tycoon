extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Ops=preload("res://scripts/shop_operations.gd")
const Style=preload("res://scripts/shop_style.gd")
const Banner=preload("res://scripts/partner_banner.gd")
var failures=0
var checks=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func fixture():
 var s=Sim.new();s.save_enabled=false;s.start_demo();s.state["orders"]=[];s.state["cash"]=10000;s.state["paused"]=false
 for w in s.state["workers"]:w["task"]={};w["path"]=[]
 return s
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var s=fixture()
 check(s.state["schema"]==5,"Operations migrate to schema 5")
 check(Ops.promo(s),"Community sale creates normal inquiry")
 var cash=s.state["cash"];var trust=s.state["reputation"]
 check(s.order(0)["promotion"] and s.order(0)["stage"]=="intake","Promotion requires normal acceptance")
 check(not Ops.promo(s) and s.state["cash"]==cash,"Promotion cannot charge twice in a day")
 check(s.state["reputation"]==trust,"Buying marketing does not buy trust")
 s.state["orders"]=[]
 var m=s.state["machines"]["dtf"];m["condition"]=40;m["broken"]=true
 var kits=s.state["stock"]["maintenance"]
 check(Ops.start_service(s,"dtf"),"Free qualified worker reserves service")
 check(s.state["stock"]["maintenance"]==kits-1 and m.has("service_work"),"Service consumes one kit once")
 check(m["service"] is Array,"Service task preserves physical service offset")
 check(not Ops.start_service(s,"dtf") and s.state["stock"]["maintenance"]==kits-1,"Repeated service click cannot consume another kit")
 for tick in 800:s.tick(.1)
 check(not m.has("service_work") and not m.get("broken",false) and m["condition"]==100,"Operator walks and recovers broken station")
 check(s.state["stock"]["maintenance"]==kits-1,"Service completion never charges a second kit")
 s=fixture();s.state["day"]=5;m=s.state["machines"]["sticker"];m["condition"]=39;m["service_uses"]=8;m["last_service_day"]=1
 Ops.tick(s,.1)
 check(m.get("broken",false),"Severe wear plus sustained missed service creates recoverable stop")
 kits=s.state["stock"]["maintenance"]
 check(Ops.begin_jam(s,"sticker"),"Broken station offers optional three-step recovery")
 check(not Ops.qte_result(s) and not Ops.qte_result(s) and s.state["stock"]["maintenance"]==kits,"First two jam steps do not consume a kit")
 check(Ops.qte_result(s) and not m["broken"] and m["condition"]>=70 and s.state["stock"]["maintenance"]==kits-1,"Third jam step commits recovery and one kit exactly once")
 check(not Ops.qte_result(s) and s.state["stock"]["maintenance"]==kits-1,"Completed jam cannot replay its stock charge")
 s=fixture();s.state["production_annex"]=false;s.state["location"]=2;s.state["fit_out"]=true;s.state["completed"]=10;s.state["reputation"]=80
 var before_machine=s.state["machines"].duplicate(true);var obligation=s.daily_obligations();cash=s.state["cash"]
 check(Ops.annex(s) and s.bounds()==Vector2i(22,16),"Earned production annex adds usable floor")
 check(s.state["machines"]==before_machine and s.daily_obligations()==obligation+75 and s.state["cash"]==cash-2200,"Annex retains layout and adds disclosed rent once")
 check(not Ops.annex(s) and s.state["cash"]==cash-2200,"Annex cannot be purchased twice")
 s=fixture();s.save_path="user://qa-service-persistence-"+str(Time.get_ticks_usec())+".json";s.save_enabled=true
 check(Ops.start_service(s,"sticker") and s.save_game(),"In-flight service can be saved")
 kits=s.state["stock"]["maintenance"]
 var restored=Sim.new();restored.save_path=s.save_path
 check(restored.load_game() and restored.state["machines"]["sticker"].has("service_work"),"Saved service reservation and route restore")
 restored.save_enabled=false
 for tick in 800:restored.tick(.1)
 check(not restored.state["machines"]["sticker"].has("service_work") and restored.state["stock"]["maintenance"]==kits,"Reloaded service finishes without duplicate kit consumption")
 s=fixture();s.state["machines"].erase("sticker")
 var price=C.EQUIPMENT_PRICES["sticker"];cash=s.state["cash"]
 check(Ops.finance(s,"sticker"),"Financing reserves disclosed deposit and repayment terms")
 check(s.state["cash"]==cash and Ops.daily_debt(s)==0,"Selecting financing is not a purchase")
 check(not s.install_equipment("sticker",Vector2i(-100,-100)),"Financing cannot bypass valid placement")
 check(s.state["cash"]==cash and Ops.daily_debt(s)==0,"Failed placement creates no debt or charge")
 var installed=false
 for x in 12:
  for y in 12:
   if s.install_equipment("sticker",Vector2i(x,y)):installed=true;break
  if installed:break
 check(installed,"Financed equipment can be placed with normal access rules")
 check(s.state["cash"]==cash-ceili(price*.2),"Valid placement charges only deposit")
 check(Ops.daily_debt(s)==ceili(price*.9/10),"Daily obligations include equipment agreement")
 var daily=Ops.daily_debt(s);cash=s.state["cash"]
 check(Ops.pay_debts(s,1)==daily and s.state["cash"]==cash-daily,"Daily debt is charged once")
 check(Ops.pay_debts(s,1)==0 and s.state["cash"]==cash-daily,"Reloading same-day debt cannot replay payment")
 s=fixture();Style.ensure(s);cash=s.state["cash"]
 check(not Style.place(s,"shirt_rack",s.entrance()),"Decor cannot block entrance")
 check(s.state["cash"]==cash,"Invalid decor placement is free")
 var placed=false
 for x in 12:
  for y in 12:
   if Style.place(s,"shirt_rack",Vector2i(x,y)):placed=true;break
  if placed:break
 check(placed and s.state["cash"]==cash-120,"Shirt display purchases and saves on clear floor")
 if placed:
  var d=s.state["style"]["decor"][0];check(s.blocked().has(s.cell(d["pos"])) and s.blocked().has(s.cell(d["pos"])+Vector2i(1,0)),"Decor width physically blocks both display tiles")
 check(not Style.set_outfit(s,"owner","Executive suit"),"Suits have progression requirement")
 s.state["completed"]=5;s.state["best_profit"]=100
 check(Style.set_outfit(s,"owner","Executive suit"),"Profitable established shop unlocks suits")
 var image=Image.create(64,64,false,Image.FORMAT_RGBA8);image.fill(Color.CYAN);image.save_png("user://qa-floor.png")
 check(Style.import_png(s,"user://qa-floor.png"),"Valid local PNG is copied into managed floor storage")
 check(s.state["style"]["floor_image"].begins_with(OS.get_user_data_dir()),"Imported image uses local copied path")
 var file=FileAccess.open("user://bad-floor.png",FileAccess.WRITE);file.store_string("not a PNG");file.close()
 check(not Style.import_png(s,"user://bad-floor.png"),"Non-PNG content is rejected")
 var bytes=PackedByteArray([137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,16,0,0,0,16,0]);file=FileAccess.open("user://huge-floor.png",FileAccess.WRITE);file.store_buffer(bytes);file.close()
 check(not Style.import_png(s,"user://huge-floor.png"),"Oversized PNG header is rejected before decode")
 s=fixture();var order=C.make_order("TIMING","sticker",24,"Timing test",s.now()+6,120);order["stage"]="plan";s.state["orders"].append(order)
 check(Ops.begin_qte(s,0,"registration"),"Sticker planning offers optional registration")
 check(Ops.qte_result(s,true) and not s.order(0).get("intervention_bonus",false),"Skipping uses ordinary production without reward or penalty")
 check(not Ops.begin_qte(s,0,"registration"),"Order intervention IDs cannot be rerolled")
 s.order(0)["id"]="TIMING-2"
 check(Ops.begin_qte(s,0,"registration") and Ops.qte_result(s),"Timing Assist succeeds without reaction requirement")
 check(s.order(0)["intervention_bonus"],"Success records bounded production-time benefit")
 s.order(0)["id"]="TIMING-3"
 check(not Ops.begin_qte(s,0,"registration"),"Daily QTE cap persists")
 s=fixture();s.state["day"]=3;s.state["clock"]=10
 Ops.tick(s,.1);var event=s.state["operations"]["event"].duplicate(true)
 check(not event.is_empty(),"Daily hurdle is deterministic and pending")
 cash=s.state["cash"];check(Ops.resolve_event(s,"keep"),"Hurdle has a no-cost keep / decline option")
 check(not Ops.resolve_event(s,"keep") and s.state["cash"]==cash,"Resolved hurdles cannot replay")
 Ops.tick(s,.1);check(s.state["operations"]["event"].is_empty(),"Same-day event cannot reroll")
 s=fixture();s.state["location"]=2;s.state["fit_out"]=true;s.state["operations"]["event"]={"id":"rare-commission","kind":"opportunity"};cash=s.state["cash"]
 check(Ops.resolve_event(s,"opportunity") and s.order(0)["type"]=="banner" and s.order(0)["stage"]=="intake" and s.order(0)["reward"]==1400,"Rare industrial project proposes a lucrative job requiring an equipment decision")
 check(s.state["cash"]==cash and not s.state["machines"].has("banner"),"Rare quote neither buys equipment nor commits the player")
 s=fixture();s.state["operations"]["offline_enabled"]=true;s.state["operations"]["event_enabled"]=false
 check(Ops.away(s,true) and not s.owner()["manual"],"Away selects real owner Auto Assist")
 s.state["operations"]["offline_anchor"]=10000
 check(Ops.settle_offline(s,10060),"Offline interval settles once")
 check(is_equal_approx(s.state["clock"],8.54),"Offline is 1x shop rate independent of selected speed")
 check(not Ops.settle_offline(s,10060),"Same offline timestamp cannot replay")
 s.state["operations"]["offline_anchor"]=10000
 check(Ops.settle_offline(s,20000) and s.state["operations"]["return_report"]["seconds"]<=900.1,"Offline work is capped at 15 real minutes")
 s=fixture();s.save_enabled=true;s.save_path="res://missing-nonexistent-folder/save.json";s.state["operations"]["away"]=true;s.state["operations"]["offline_enabled"]=true;s.state["operations"]["offline_anchor"]=10000
 var before=s.state.duplicate(true)
 check(not Ops.settle_offline(s,10010) and s.state==before,"Offline save failure rolls back all simulation mutations")
 var game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;root.add_child(game);game.set_process(false);game.screen="shop";game.sim.start_demo();game.sim.state["location"]=2;game.sim.state["fit_out"]=false
 game._action("move");check(game.modal=="move","Expanded shop retains permanent Growth route")
 game._action("fit_out");check(game.sim.state["fit_out"],"Fit-out can be purchased after premises")
 game.sim.state["paused"]=false;var oldzoom=game.zoom;var oldoffset=game.offset
 game._action("photo_mode");check(game.photo_active and game.sim.state["paused"],"Photo mode freezes shop")
 game._action("photo_close");check(not game.photo_active and not game.sim.state["paused"] and game.zoom==oldzoom and game.offset==oldoffset,"Leaving photo restores pause and camera exactly")
 check(Banner.read_config("res://config/partner-banners.json").is_empty(),"Release banner stays hidden without configured URLs")
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--review-saves="):
   for name in ["career-nine-paid-expanded-no-fitout.json","demo-three-paid-expanded-no-fitout.json"]:
    var path=arg.get_slice("=",1).path_join(name);var original=FileAccess.get_sha256(path)
    var review=Sim.new();review.save_path=path;review.save_enabled=false
    check(review.load_game() and review.state["location"]==2 and not review.state["fit_out"],"Load supplied reproduction: "+name)
    game.sim=review;game._action("move");game._action("fit_out")
    check(game.sim.state["fit_out"] and FileAccess.get_sha256(path)==original,"Supplied profile buys fit-out without altering evidence: "+name)
 game.queue_free();await process_frame
 print("WORKSHOP OPERATIONS: %d checks, %d failures" % [checks,failures]);quit(failures)

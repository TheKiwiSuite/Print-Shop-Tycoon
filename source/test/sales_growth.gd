extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Marketing=preload("res://scripts/marketing.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)
func shop():
 var s=Sim.new();s.save_enabled=false
 for id in ["sticker","art","finish","pack"]:
  var m=C.layout(1)[id]
  s.install_equipment(id,s.cell(m["pos"]))
 s.state["orders"]=[]
 return s
func safe_visitors(s) -> bool:
 var actors=s.visible_customers()
 for i in actors.size():
  if s.blocked().has(Vector2i(roundi(actors[i]["pos"][0]),roundi(actors[i]["pos"][1]))): return false
  for j in range(i+1,actors.size()):
   if s.v(actors[i]["pos"]).distance_to(s.v(actors[j]["pos"]))<0.54: return false
 return true
func _initialize() -> void:
 var empty=Sim.new();empty.save_enabled=false
 check(not empty.start_campaign("flyers"),"Empty shop cannot buy leads it cannot produce")
 check(not empty.start_campaign("unknown"),"Unknown campaign changes no business state")
 check(empty.state["cash"]==1200 and empty.state["orders"].size()==3,"Rejected campaigns preserve cash and orders")
 empty.install_equipment("sticker",Vector2i(4,4))
 check(not empty.marketing_feedback("flyers")["valid"],"Inspection and pickup are required before promoting")
 var s=shop()
 check(s.marketing_feedback("flyers")["valid"],"Ready starter shop can launch flyers")
 var cash=s.state["cash"]
 var stock=s.state["stock"].duplicate(true)
 check(s.start_campaign("flyers"),"Launch a paid neighborhood campaign")
 check(s.state["cash"]==cash-25 and s.state["stats"]["marketing"]==25,"Campaign charges its displayed cost exactly once")
 check(s.state["orders"].size()==1 and s.order(0)["type"]=="sticker" and s.order(0)["stage"]=="scheduled","Campaign creates equipment-matched scheduled work")
 check(s.state["stock"]==stock and s.state["stats"]["sales"]==0,"Campaign launch consumes no materials and awards no sales")
 check(not s.start_campaign("flyers") and s.state["cash"]==cash-25 and s.state["orders"].size()==1,"Rapid repeat click cannot duplicate the charge or leads")
 for n in 50: s.tick(.1)
 check(s.order(0)["stage"]=="scheduled" and s.now()==0.0,"Pause freezes campaign lead timers")
 s.state["paused"]=false;s.state["clock"]=8.49;s.tick(.1)
 check(s.order(0)["stage"]=="scheduled","Campaign does not arrive before its displayed lead time")
 s.state["clock"]=8.51;s.tick(.1)
 check(s.order(0)["stage"]=="intake" and not s.visible_customers().is_empty(),"Due campaign inquiry arrives as a walking customer")
 check(s.accept(0) and s.preflight(0,"repair") and s.queue_order(0),"Campaign job follows normal artwork and production requirements")
 s.owner()["manual"]=false
 for n in 8000:
  if s.order(0)["paid"]: break
  s.tick(.1)
 check(s.order(0)["paid"] and s.order(0)["payment"]==150,"Campaign completes through customer pickup with real payment")
 check(s.state["cash"]==cash-25+150 and s.state["stats"]["sales"]==150,"Sales follow production; campaign expense remains separate")
 var balance=s.state["cash"]
 s._fulfill(s.order(0))
 check(s.state["cash"]==balance and s.state["completed"]==1,"Repeated settlement never duplicates campaign income")
 var report=s.end_day()
 check(report["stats"]["marketing"]==25,"Daily accounts include marketing spending")
 var expected=report["stats"]["sales"]-report["stats"]["materials"]-25-report["stats"]["art_fees"]-report["stats"]["wages"]-report["stats"]["overhead"]
 check(is_equal_approx(float(report["net"]),float(expected)),"Daily net profit subtracts campaign expense")
 check(not s.start_campaign("social"),"Closed daily accounts cannot launch another campaign")
 s.next_day()
 check(s.state["cash"]==balance-125 and s.state["stats"]["marketing"]==0,"Next day pays overhead without recharging marketing")
 check(s.state["marketing"]["history"].size()==1,"Campaign history survives day changes")
 var types=Marketing.supported(C.layout(1))
 check(types.has("transfer") and types.has("sticker") and types.has("apparel") and not types.has("cnc"),"Campaign routes match installed production capabilities")
 var printer=C.layout(1);printer.erase("heat")
 check(not Marketing.supported(printer).has("apparel"),"A DTF printer alone cannot advertise finished shirts")
 var capacity=shop();capacity.state["orders"]=C.empty_shop()["orders"]
 check(capacity._lead_count(["sticker"])==2,"Lead limit counts the first inquiry that adapts to stickers")
 check(capacity.start_campaign("business"),"Three matching leads fit the starter shop capacity")
 var staggered=true
 for i in range(4,6): staggered=staggered and capacity.order(i)["visit"]["arrival_at"]>capacity.order(i-1)["visit"]["arrival_at"]
 check(staggered,"Multi-lead campaign arrivals are staggered")
 capacity.state["clock"]=8.6
 var prior=capacity.state["cash"]
 check(not capacity.start_campaign("social") and capacity.state["cash"]==prior,"Lead limit blocks oversized campaigns before charging")
 var limits=shop()
 for n in 3:
  limits.state["clock"]=8.0+n*.6
  check(limits.start_campaign("flyers"),"Launch allowed daily campaign %d" % (n+1))
  for o in limits.state["orders"]: o["stage"]="declined"
 limits.state["clock"]=10.0
 check(not limits.start_campaign("flyers"),"Fourth same-day campaign is rejected")
 limits.state["cash"]=0
 check(not limits.start_campaign("business") and limits.state["cash"]==0,"Insufficient campaign funds never create debt or leads")
 var persisted=shop();persisted.save_path=ProjectSettings.globalize_path("res://../../../work/sales-growth-test.json");persisted.save_enabled=true
 check(persisted.start_campaign("social"),"Campaign saves through the isolated test profile")
 var saved_cash=persisted.state["cash"]
 var restored=Sim.new();restored.save_path=persisted.save_path;restored.save_enabled=false
 check(restored.load_game(),"Reload campaign waiting to arrive")
 check(restored.state["cash"]==saved_cash and restored.state["orders"].size()==2 and restored.state["marketing"]["next_id"]==2,"Reload does not replay campaign spending or generation")
 restored.state["paused"]=false;restored.state["clock"]=9.3
 for n in 200: restored.tick(.1)
 check(restored.visible_customers().size()==2,"Both saved scheduled campaign customers can enter")
 var safe=true
 for n in 200: restored.tick(.1);safe=safe and safe_visitors(restored)
 check(safe,"Waiting campaign customers retain separate collision-safe floor space")
 var doorway=shop();doorway.start_campaign("social");doorway.state["paused"]=false;doorway.state["clock"]=8.6
 for n in 100: doorway.tick(.1)
 doorway.accept(0)
 for n in 100: doorway.tick(.1)
 doorway.order(0)["stage"]="ready";doorway.state["clock"]=9.3;doorway.tick(.1)
 check(doorway.visible_customers().size()==1,"Returning and newly arriving customers take turns entering the doorway")
 safe=true
 for n in 250: doorway.tick(.1);safe=safe and safe_visitors(doorway)
 check(safe and doorway.visible_customers().size()==2,"Returning and new customers share the shop without merging bodies")
 check(doorway.customer_ready_for_handoff(doorway.order(0)),"Coordinated doorway still reaches a ready pickup")
 var legacy=Sim.new();legacy.state=C.fresh();legacy.save_enabled=false
 check(legacy.start_campaign("flyers"),"Existing legacy shop can buy a campaign without resetting its orders")
 legacy.state["clock"]=8.6;legacy.tick(.1)
 check(legacy.order(3)["stage"]=="intake" and legacy.order(0)["id"]=="DTF-001","Campaign arrivals work alongside the retained legacy offer schedule")
 persisted.save_game()
 var corrupt=FileAccess.open(persisted.save_path,FileAccess.WRITE);corrupt.store_string("invalid test JSON");corrupt.close()
 var recovery=Sim.new();recovery.save_path=persisted.save_path;recovery.save_enabled=false
 check(recovery.load_game() and recovery.state["cash"]==saved_cash and recovery.state["orders"].size()==2,"Backup recovers paid campaign state without duplicates")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(persisted.save_path+suffix): DirAccess.remove_absolute(persisted.save_path+suffix)
 var route=shop();route.state["paused"]=false
 route.owner()["pos"]=[3.0,3.0]
 check(route.move_owner(Vector2i(10,3)),"Owner starts a floor route before rearrangement")
 check(route.move_equipment("sticker",Vector2i(6,3)),"Move equipment across an idle walking route")
 for n in 200: route.tick(.1)
 check(route.v(route.owner()["pos"]).distance_to(Vector2(10,3))<.05,"Owner reroutes to the original destination after equipment moves")
 var garage=shop();garage.state["paused"]=false;garage.state["clock"]=9.3;garage.start_campaign("flyers")
 garage.state["clock"]=10.0
 for n in 100: garage.tick(.1)
 garage.state["completed"]=3;garage.state["on_time"]=3;garage.state["quality_total"]=300;garage.state["reputation"]=70;garage.state["cash"]=4600
 check(garage.move_garage(),"Existing shop expansion accepts an open customer inquiry")
 for n in 200: garage.tick(.1)
 check(safe_visitors(garage),"Expansion reintroduces visitors without embedding them in new machines")
 print("SALES GROWTH: ",checks," checks, ",failures," failures")
 quit(failures)

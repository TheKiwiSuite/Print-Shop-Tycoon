extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
var s=Sim.new()
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1; push_error("FAIL: "+label)
 else: print("PASS: "+label)
func advance_until(i:int,stage:String,limit:int=8000) -> void:
 for n in limit:
  if s.order(i)["stage"]==stage: return
  s.tick(0.1)
 check(false,"Timeout waiting for %s; actual %s" % [stage,s.order(i)["stage"]])
func prepare(i:int) -> void:
 check(s.accept(i),"Accept order %d" % i)
 check(s.preflight(i,"repair"),"Preflight order %d" % i)
 if s.order(i)["type"] in ["transfer","apparel"]:
  check(s.auto_pack(i),"Gang pack order %d" % i)
  check(s.gang_valid(i,s.order(i)["gang"]),"Physical dimensions / no overlap %d" % i)
 check(s.queue_order(i),"Queue order %d" % i)
func _initialize() -> void:
 s.save_enabled=false
 s.state=C.fresh()
 for id in s.state["machines"]:
  var f=s.placement_feedback(id,s.cell(s.state["machines"][id]["pos"]))
  check(f["valid"],"Initial accessible layout "+id+" / "+f["reason"])
 check(not s.placement_feedback("shaker",Vector2i(5,4))["valid"],"Reject sideways DTF shaker")
 check(not s.placement_feedback("shaker",Vector2i(4,5))["valid"],"Reject disconnected DTF shaker")
 s.state["machines"]["shaker"]["width"]=36
 check(not s.placement_feedback("shaker",Vector2i(4,4))["valid"],"Reject mismatched DTF widths")
 s.state["machines"]["shaker"]["width"]=24
 check(not s.placement_feedback("heat",Vector2i(4,6))["valid"],"Reject blocked front take-up")
 check(not s.placement_feedback("heat",Vector2i(3,0))["valid"],"Keep new equipment off a fixed shelf")
 check(not s.move_owner(Vector2i(0,2)),"Keep the owner out of a fixed planter")
 check(s.move_equipment("heat",Vector2i(9,5)),"Rearrange a station with clear access")
 check(s.move_equipment("heat",Vector2i(8,6)),"Restore heat press layout")
 check(s.move_owner(Vector2i(8,8)),"Click-to-walk path available")
 var traversed=0
 for n in 180:
  s.tick(0.1)
  var p=Vector2i(roundi(s.owner()["pos"][0]),roundi(s.owner()["pos"][1]))
  if not s.blocked().has(p): traversed+=1
 check(traversed==180,"Owner route never crosses machine footprints")
 check(s.v(s.owner()["pos"]).distance_to(Vector2(8,8))<0.05,"Owner reaches clicked floor tile")
 var before=s.v(s.owner()["pos"])
 s.manual_input=Vector2(1,0)
 for n in 20: s.tick(0.05)
 s.manual_input=Vector2.ZERO
 check(s.v(s.owner()["pos"]).distance_to(before)>0.5,"Direct movement changes owner position")
 check(not s.move_owner(Vector2i(4,4)),"Solid equipment rejects owner placement")
 check(not s.walk_segment_clear(Vector2(5,0),Vector2(5,5)),"Swept walking collision blocks a step through equipment")
 check(s.walk_segment_clear(Vector2(3,1),Vector2(3,2)),"Clear aisle permits a grounded walking step beside equipment")
 prepare(0)
 var film_before=s.state["stock"]["film"]
 s.owner()["manual"]=false
 advance_until(0,"completed")
 check(not s.order(0).get("press_done",false),"Transfer-only route never uses heat press")
 check(s.state["stock"]["film"]<film_before,"DTF consumes real film stock")
 check(s.state["completed"]==1 and s.state["cash"]>1200,"Delivery pays once")
 prepare(1)
 s.order(1)["settings"]["registration"]=false
 advance_until(1,"fault")
 check(s.order(1)["issue"].contains("misregistration"),"QC fault has specific settings cause")
 var media=s.state["stock"]["sticker"]
 var due=s.now()
 check(s.recover(1,true),"Fix cause and reprint")
 advance_until(1,"completed")
 check(s.state["stock"]["sticker"]<media,"Reprint consumes new stock")
 check(s.now()>due and s.state["stats"]["waste"]>0,"Reprint adds time and waste cost")
 prepare(2)
 advance_until(2,"press")
 var blanks=s.state["garments"].duplicate(true)
 var medium_before=int(blanks["navy:M"])
 s.state["garments"]["navy:M"]=0
 for n in 15: s.tick(0.1)
 check(s.order(2)["stage"]=="press","Apparel waits for exact garment sizes")
 s.state["garments"]=blanks
 advance_until(2,"completed")
 check(s.order(2)["press_done"],"Apparel requires timed pressing")
 check(s.state["garments"]["navy:M"]==medium_before-4,"Size / color blanks consumed")
 check(s.buy_upgrade("auto_feeder"),"Buy DTF throughput upgrade")
 check(s.hire(1),"Hire DTF operator")
 check(s.hire(2),"Hire print / cut operator")
 check(s.assign("staff0","dtf"),"Assign specialist to station")
 s.state["cash"]=2500
 check(s.garage_progress()["ready"],"Earned quality / delivery goals unlock garage")
 check(s.move_garage(),"Move into industrial shop")
 for id in s.state["machines"]:
  check(s.placement_feedback(id,s.cell(s.state["machines"][id]["pos"]))["valid"],"Garage accessible station "+id)
 check(s.state["machines"].has("dtf2"),"Separate second DTF lane state")
 prepare(3); prepare(4)
 advance_until(3,"completed"); advance_until(4,"completed")
 check(s.order(3)["fulfillment"]=="ship" and s.order(4)["stage"]=="completed","Banner and CNC fully shipped")
 check(s.state["stock"]["rigid"]<24,"CNC consumes rigid panels")
 s.state["cash"]=2000; s.state["stock"]["film"]=0
 var r=C.make_order("STOCK-TEST","transfer",6,"Supply test",s.now()+5,200)
 s.state["orders"].append(r)
 var i=s.state["orders"].size()-1
 s.accept(i); s.preflight(i,"repair"); s.auto_pack(i)
 check(not s.queue_order(i) and r["stage"]=="waiting_stock","Low supplies prevent production")
 check(s.restock({"film":48}),"Buy delayed delivery")
 advance_until(i,"completed")
 check(s.state["deliveries"].is_empty() and s.state["stock"]["film"]>0,"Arrival unblocks production")
 s.save_enabled=true
 s.save_path=ProjectSettings.globalize_path("res://../../../work/acceptance-profile.json")
 var snapshot=s.state.duplicate(true)
 check(s.save_game(),"Atomic native local save")
 var loaded=Sim.new()
 loaded.save_path=s.save_path
 check(loaded.load_game(),"Load local save")
 check(loaded.state["cash"]==snapshot["cash"],"Cash survives reload")
 var same_stock=true
 for key in snapshot["stock"]:
  if int(loaded.state["stock"][key])!=int(snapshot["stock"][key]): same_stock=false
 check(same_stock,"Inventory survives reload")
 check(loaded.state["workers"].size()==snapshot["workers"].size(),"Staff survives reload")
 check(loaded.cell(loaded.state["machines"]["cnc"]["pos"])==s.cell(snapshot["machines"]["cnc"]["pos"]),"Layout survives reload")
 check(loaded.state["orders"].size()==snapshot["orders"].size(),"Order states survive reload")
 loaded.save_enabled=false
 var loaded_orders=loaded.state["orders"].size()
 var loaded_cash=loaded.state["cash"]
 var loaded_day=int(loaded.state["day"])
 var loaded_report=loaded.end_day()
 loaded.next_day()
 check(int(loaded.state["day"])==loaded_day+1,"Reloaded shop advances its day")
 check(loaded.state["orders"].size()>loaded_orders,"Reloaded shop generates next-day offers")
 check(loaded.state["cash"]==loaded_cash-loaded_report["stats"]["wages"]-loaded_report["stats"]["overhead"],"Reloaded shop charges daily costs once")
 check(loaded.state["report"].is_empty() and not loaded.state["paused"],"Reloaded shop opens next day for play")
 s.save_enabled=false
 for day in 4:
  var money=s.state["cash"]
  var report=s.end_day()
  check(report==s.end_day(),"Day report idempotent %d" % day)
  s.next_day()
  check(s.state["cash"]==money-report["stats"]["wages"]-report["stats"]["overhead"],"Daily costs charged once %d" % day)
  check(s.active_orders().size()<=6,"New orders bounded %d" % day)
 check(s.state["day"]==5,"Several shop days remain playable")
 var pre=Sim.new()
 pre.state=C.fresh()
 pre.save_enabled=false
 check(pre.hire(0),"Hire a prepress artist")
 check(pre.accept(0),"Accepted artwork enters prepress queue")
 for n in 500: pre.tick(0.1)
 check(pre.order(0)["stage"]=="plan" and pre.order(0)["art_ready"],"Artist walks to desk and repairs artwork")
 check(pre.state["machines"]["art"]["active"]==-1,"Prepress desk released after job")
 var inflight=Sim.new()
 inflight.state=C.fresh()
 inflight.save_path=ProjectSettings.globalize_path("res://../../../work/acceptance-inflight.json")
 inflight.accept(0); inflight.preflight(0,"repair"); inflight.auto_pack(0); inflight.queue_order(0)
 inflight.work_order(0)
 for n in 45: inflight.tick(0.1)
 var used=int(inflight.state["stock"]["film"])
 check(inflight.save_game(),"Save with work in flight")
 var resumed=Sim.new()
 resumed.save_path=inflight.save_path
 check(resumed.load_game(),"Reload working operator and route")
 resumed.save_enabled=false
 for n in 500: resumed.tick(0.1)
 check(resumed.order(0)["stage"]=="qc","In-flight production resumes to output")
 check(int(resumed.state["stock"]["film"])==used,"Resuming production never double-consumes materials")
 print("NATIVE ACCEPTANCE: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)

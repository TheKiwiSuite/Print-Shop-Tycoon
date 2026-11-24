extends SceneTree
# Starter garage equipment: vinyl cutter bench (decals) and desktop DTF kit.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Marketing=preload("res://scripts/marketing.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var checks=0
var failures=0

func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)

func advance(s, i:int, stage:String, limit:int=9000) -> bool:
 for n in limit:
  if s.order(i)["stage"]==stage: return true
  s.tick(0.1)
 check(false,"Timed out waiting for "+stage+"; actual "+s.order(i)["stage"])
 return false

func prepare(s,i:int) -> void:
 check(s.accept(i),"Accept customer job %d" % i)
 check(s.preflight(i,"repair"),"Approve artwork %d" % i)
 if s.order(i)["type"] in ["transfer","apparel"]: s.auto_pack(i)
 check(s.queue_order(i),"Queue prepared job %d" % i)

func supports(s) -> void:
 for id in ["art","finish","pack"]:
  check(s.install_equipment(id,s.cell(C.layout(1)[id]["pos"])),"Place support station "+id)

func _initialize() -> void:
 cutter_route()
 desktop_dtf_route()
 shared_rules()
 walkthrough_route()
 print("STARTER EQUIPMENT: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

func cutter_route() -> void:
 var s=Sim.new();s.save_enabled=false
 var cash=s.state["cash"]
 s.state["stock"]["vinyl"]=0;s.state["stock"]["transfer_tape"]=0
 check(s.install_equipment("cutter",Vector2i(4,4)),"Buy and place the vinyl cutter bench")
 check(s.state["cash"]==cash-C.EQUIPMENT_PRICES["cutter"],"Cutter costs its listed price")
 check(int(s.state["stock"]["vinyl"])>=24 and int(s.state["stock"]["transfer_tape"])>=24,"Cutter ships with a vinyl starter pack")
 check(s.state["machines"]["cutter"]["size"]==[2,1],"Cutter bench has a 2 x 1 footprint")
 supports(s)
 s.state["paused"]=false;s.tick(.1)
 var o=s.order(0)
 check(o["id"]=="DEC-START" and o["type"]=="decal" and o["stage"]=="intake","First customer asks for decals a cutter-only shop can make")
 var before=s.state["cash"]
 var vinyl=int(s.state["stock"]["vinyl"])
 prepare(s,0)
 check(s.machine_for(s.order(0))=="cutter","Decal production routes to the cutter")
 s.owner()["manual"]=false
 if advance(s,0,"qc"):
  check(int(s.state["stock"]["vinyl"])<vinyl,"Cutting consumes vinyl")
  check(s.state["machines"]["cutter"]["phase"]=="Idle","Cutter returns to idle after the job")
 advance(s,0,"completed")
 check(s.order(0)["paid"] and s.state["cash"]==before+120,"Decal starter job pays exactly once")
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/starter-equipment-qa.json")
 check(s.save_game(),"Save a shop with a cutter")
 var loaded=Sim.new();loaded.save_path=s.save_path
 check(loaded.load_game(),"Load a shop with a cutter")
 loaded.save_enabled=false
 check(loaded.state["machines"].has("cutter") and loaded.state["machines"]["cutter"]["kind"]=="cutter","Cutter survives save and load")
 loaded.next_day();loaded.tick(.1)
 var decal_inquiry=false
 for job in loaded.state["orders"]:
  if job["id"].begins_with("DAY2-") and job["type"]=="decal": decal_inquiry=true
 check(decal_inquiry,"Next-day inquiries include decal work for cutter owners")
 check("decal" in Marketing.supported(loaded.state["machines"]),"Marketing campaigns can bring decal work")
 # Fault recovery fixes the cutter, not a missing printer.
 var i=loaded.state["orders"].size()
 var fault=C.make_order("DEC-FAULT","decal",10,"Fault probe",loaded.now()+5,40)
 fault["stage"]="fault";fault["route_machine"]="cutter";fault["issue"]="Torn or lifted vinyl"
 loaded.state["orders"].append(fault)
 loaded.state["machines"]["cutter"]["condition"]=50
 check(loaded.recover(i,true),"Decal reprint recovery works")
 check(loaded.state["machines"]["cutter"]["condition"]==100,"Reprint recovery services the cutter")
 # A Print / cut operator may run the cutter; a DTF operator may not.
 var w={"id":"staffQA","role":"Print / cut operator"}
 check(loaded.role_matches(w,"cutter"),"Print / cut operator qualifies for the cutter")
 check(not loaded.role_matches({"id":"staffQB","role":"DTF operator"},"cutter"),"DTF operator does not run the cutter")
 # Older saves without vinyl stock load with the new supplies at zero.
 var old=Sim.new();old.save_enabled=true;old.save_path=ProjectSettings.globalize_path("res://../../../work/starter-equipment-old-qa.json")
 old.state["stock"].erase("vinyl");old.state["stock"].erase("transfer_tape")
 check(old.save_game(),"Write an older-style save without vinyl stock")
 var migrated=Sim.new();migrated.save_path=old.save_path
 check(migrated.load_game(),"Older save still loads")
 check(migrated.state["stock"].get("vinyl",-1)==0 and migrated.state["stock"].get("transfer_tape",-1)==0,"Older save gains empty vinyl and tape stock")

func desktop_dtf_route() -> void:
 var s=Sim.new();s.save_enabled=false
 check(s.install_equipment("dtfmini",Vector2i(2,4)),"Buy and place the desktop DTF kit")
 check(not s.state["machines"].has("shaker"),"Desktop kit installs as one station without a shaker")
 check(s.install_equipment("heat",s.cell(C.layout(1)["heat"]["pos"])),"Place a heat press beside the desktop kit")
 supports(s)
 s.state["paused"]=false;s.tick(.1)
 check(s.order(0)["id"]=="DTF-001" and s.order(0)["type"]=="transfer","First transfer order stays a transfer with desktop DTF")
 check(s.can_produce("transfer") and s.can_produce("apparel"),"Desktop kit plus heat press can make transfers and shirts")
 prepare(s,0)
 # Measured after setup: transfer artwork repair has its own disclosed fee.
 var before=s.state["cash"]
 check(s.machine_for(s.order(0))=="dtfmini","Transfer production routes to the desktop kit")
 s.owner()["manual"]=false
 advance(s,0,"completed")
 check(s.order(0)["paid"] and s.state["cash"]==before+480,"Desktop DTF transfer job pays exactly once")
 var mini=0.0;var line=0.0
 for p in C.phases("dtfmini",s.order(0)): mini+=float(p[1])
 for p in C.phases("dtf",s.order(0)): line+=float(p[1])
 check(mini>line,"Desktop kit is slower than the full DTF line")
 # A worn desktop kit reports its own fault without reading a shaker.
 s.state["machines"]["dtfmini"]["condition"]=50
 var probe=C.make_order("DTF-PROBE","transfer",4,"Probe",s.now()+5,80);probe["route_machine"]="dtfmini"
 check(s._quality_issue(probe,s.state["machines"]["dtfmini"]).begins_with("Uneven powder"),"Worn desktop kit reports a cure fault")
 check("transfer" in Marketing.supported(s.state["machines"]) and "apparel" in Marketing.supported(s.state["machines"]),"Marketing treats the desktop kit as a DTF printer")

func shared_rules() -> void:
 var s=Sim.new();s.save_enabled=false;s.state["cash"]=100000
 check(s.install_equipment("dtf",Vector2i(4,2)),"Place a full DTF line")
 check(s.install_equipment("dtfmini",Vector2i(1,8)),"Place a desktop kit in the same shop")
 check(s.station_options("dtf")==["dtf","dtfmini"],"Both DTF stations can take transfer work")
 check(s.print_station("transfer")=="dtf","The full line stays the preferred transfer station")
 # Legacy garage move keeps starter benches in the industrial layout.
 var g=Sim.new();g.save_enabled=false
 g.state["location"]=2;g.state["machines"]=C.layout(2)
 var bench=C.catalog_station("cutter")
 g._rehome_starters({"cutter":bench})
 check(g.state["machines"].has("cutter"),"Starter bench is rehomed when the shop moves")
 if g.state["machines"].has("cutter"):
  var m=g.state["machines"]["cutter"]
  check(g.placement_feedback("cutter",g.cell(m["pos"]),int(m["rotation"]))["valid"],"Rehomed bench sits on a valid spot")

func walkthrough_route() -> void:
 # A new career: gifted cutter, heat press, first heat-transfer vinyl shirts.
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 check(s.is_gift("cutter") and s.walkthrough_step()=="gift","New career starts with a gifted cutter")
 check(s.equipment_locked("dtfmini") and s.equipment_locked("dtf"),"DTF equipment starts locked behind shop level")
 check(not s.install_feedback("dtfmini",Vector2i(1,7))["valid"],"Locked desktop DTF cannot be placed yet")
 var cash=s.state["cash"]
 check(s.install_equipment("cutter",C.garage_spot("cutter")),"Place the gifted cutter")
 check(s.state["cash"]==cash and not s.is_gift("cutter"),"Gifted cutter is free and only once")
 check(int(s.state["stock"]["htv"])>=24,"Cutter comes with shirt vinyl")
 check(s.walkthrough_step()=="press","Walkthrough asks for a heat press next")
 check(s.install_equipment("heat",C.garage_spot("heat")),"Buy and place the heat press")
 check(s.state["cash"]==cash-C.EQUIPMENT_PRICES["heat"],"Heat press is a normal purchase")
 check(s.walkthrough_step()=="benches","Walkthrough asks for work benches next")
 for id in ["art","finish","pack"]:
  check(s.install_equipment(id,C.garage_spot(id)),"Place free bench "+id)
 check(s.walkthrough_step()=="open","Walkthrough asks to open the shop")
 s.state["paused"]=false;s.tick(.1)
 var o=s.order(0)
 check(o["id"]=="SHIRT-START" and o["type"]=="apparel" and C.is_htv(o),"First customer wants vinyl T-shirts")
 check(s.state["tutorial_order"]=="SHIRT-START" and s.walkthrough_step()=="job","The shirt job is the walkthrough job")
 check(s.can_produce("apparel"),"Cutter plus heat press can make shirts")
 check(s.quote(0,false)["valid"],"Vinyl shirt quote is valid")
 var htv=int(s.state["stock"]["htv"])
 check(s.accept(0),"Accept the vinyl shirt job")
 if s.order(0)["stage"]=="preflight": s.preflight(0,"repair")
 check(s.queue_order(0),"Queue the mirrored vinyl cut")
 check(s.machine_for(s.order(0))=="cutter","Vinyl shirts are cut on the cutter")
 var before=s.state["cash"]
 s.owner()["manual"]=false
 if advance(s,0,"press"): check(int(s.state["stock"]["htv"])<htv,"Cutting uses shirt vinyl")
 advance(s,0,"completed")
 check(s.order(0)["paid"] and s.state["cash"]==before+210,"Vinyl shirt job pays once")
 check(s.order(0)["press_done"],"Shirts went through the heat press")
 check(s.walkthrough_step()=="done","Walkthrough celebrates the first sale")
 s.end_walkthrough()
 check(s.walkthrough_step()=="","Walkthrough can be closed")
 # Staff grows with the shop.
 s.state["cash"]=20000
 check(s.staff_cap()==2,"Garage shop fits the owner plus one helper")
 check(s.hire(2),"Hire one helper")
 check(not s.hire(1),"A second helper needs bigger premises")
 s.state["location"]=2
 check(s.staff_cap()==4,"Larger premises fit four people")
 s.state["fit_out"]=true
 check(s.staff_cap()==6,"Industrial fit-out fits six people")
 s.state["production_annex"]=true
 check(s.staff_cap()==9,"Production annex allows the full team")
 # DTF unlocks with shop level.
 Progress.ensure(s)["xp"]=Progress.LEVEL_XP[2]
 check(not s.equipment_locked("dtfmini") and s.equipment_locked("dtf"),"Desktop DTF unlocks at shop level 3")
 Progress.ensure(s)["xp"]=Progress.LEVEL_XP[4]
 check(not s.equipment_locked("dtf"),"Full DTF line unlocks at shop level 5")
 # The demo and older shops keep their previous rules.
 var d=Sim.new();d.save_enabled=false;d.start_demo()
 check(d.staff_cap()==9 and not d.equipment_locked("dtf"),"Demo shop is not limited by the starter path")

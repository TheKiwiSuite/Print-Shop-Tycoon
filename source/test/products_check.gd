extends SceneTree
# New products: printed mugs, embroidered hats, hoodies and tote bags.
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

func advance(s, i:int, stage:String, limit:int=12000) -> bool:
 for n in limit:
  if s.order(i)["stage"]==stage: return true
  s.tick(0.1)
 check(false,"Timed out waiting for "+stage+"; actual "+s.order(i)["stage"])
 return false

func run_job(s,o:Dictionary,label:String) -> int:
 s.state["orders"].append(o)
 var i=s.state["orders"].size()-1
 s.state["paused"]=false;s.tick(.1)
 check(s.accept(i),"Accept the "+label+" job")
 if s.order(i)["stage"]=="preflight": s.preflight(i,"repair")
 for n in 2000:
  if s.order(i)["stage"]=="plan": break
  s.tick(.1)
 check(s.queue_order(i),"Queue the "+label+" job")
 s.owner()["manual"]=false
 advance(s,i,"completed")
 return i

func _initialize() -> void:
 var s=Sim.new();s.save_enabled=false;s.state["cash"]=20000
 check(s.install_equipment("mug",Vector2i(2,2)),"Place the mug + tumbler press")
 check(int(s.state["stock"]["mugs"])>=24 and int(s.state["stock"]["subpaper"])>=12,"The mug press comes with blank mugs and paper")
 check(s.install_equipment("embroidery",Vector2i(2,5)),"Place the embroidery machine")
 check(int(s.state["stock"]["caps"])>=24 and int(s.state["stock"]["thread"])>=8,"The embroidery machine comes with caps and thread")
 for id in ["art","finish","pack"]: check(s.install_equipment(id,s.cell(C.layout(1)[id]["pos"])),"Place "+id)
 # Mugs.
 var mugs=int(s.state["stock"]["mugs"]);var paper=int(s.state["stock"]["subpaper"])
 var mo=C.make_order("MUG-1","mug",12,"Mug tester",s.now()+8,108)
 check(mo["product"]=="Printed mugs" and C.recipe(mo)=={"mugs":12,"subpaper":6},"Mug orders use blank mugs and sublimation paper")
 var mi=run_job(s,mo,"mug")
 check(s.order(mi)["paid"] and int(s.state["stock"]["mugs"])==mugs-12 and int(s.state["stock"]["subpaper"])==paper-6,"Mug job is pressed, paid and uses its blanks")
 var mug_time=0.0;var hat_time=0.0
 for ph in C.phases("mug",mo): mug_time+=float(ph[1])
 # Hats need artwork turned into a stitch file first.
 var caps=int(s.state["stock"]["caps"])
 var ho=C.make_order("HAT-1","hat",8,"Hat tester",s.now()+9,128)
 check(not ho["art_ready"] and ho["product"]=="Embroidered hats","Hat orders start with artwork to prepare")
 for ph in C.phases("embroidery",ho): hat_time+=float(ph[1])
 check(hat_time/8.0>mug_time/12.0,"Each hat takes longer than each mug")
 var hi=run_job(s,ho,"hat")
 check(s.order(hi)["paid"] and int(s.state["stock"]["caps"])==caps-8,"Hat job is stitched, paid and uses blank caps")
 # Hoodies and totes are shirt-style jobs with their own blanks.
 check(s.install_equipment("cutter",Vector2i(11,4)),"Place a cutter for vinyl hoodies")
 check(s.install_equipment("heat",s.cell(C.layout(1)["heat"]["pos"])),"Place a heat press")
 s.state["garments"]["hoodie:S"]=4;s.state["garments"]["hoodie:M"]=4;s.state["garments"]["hoodie:L"]=4
 var hood=C.make_order("HOOD-1","apparel",6,"Hoodie tester",s.now()+9,300)
 C.apply_blank(hood,"hoodie")
 check(hood["product"]=="Team hoodies" and hood["garments"]=={"hoodie:S":2,"hoodie:M":2,"hoodie:L":2} and hood["reward"]==6*72,"A hoodie order uses hoodie blanks and hoodie prices")
 var before_cost=float(s.state["stats"]["materials"])
 var hdi=run_job(s,hood,"hoodie")
 check(s.order(hdi)["paid"] and int(s.state["garments"]["hoodie:M"])==2,"Hoodie job presses and uses hoodie blanks")
 check(float(s.state["stats"]["materials"])-before_cost>=6*9.0,"Hoodie blanks cost more than tees")
 var tote=C.make_order("TOTE-1","apparel",12,"Tote tester",s.now()+9,300)
 C.apply_blank(tote,"tote")
 check(tote["product"]=="Tote bags" and tote["garments"]=={"tote:One":12} and tote["reward"]==12*22,"A tote order uses one size of tote bag")
 # Supplies, marketing, inquiries and stats know the new products.
 check(s.restock({"mugs":24,"caps":24,"garment:hoodie:M":3,"garment:tote:One":12}),"New blanks can be ordered")
 var supported=Marketing.supported(s.state["machines"])
 check("mug" in supported and "hat" in supported,"Marketing can bring mug and hat work")
 s.next_day();s.tick(.1)
 var types={}
 for o in s.state["orders"]: types[o["type"]]=true
 check(types.has("mug") and types.has("hat"),"Daily inquiries include mugs and hats for shops with the machines")
 var p=Progress.ensure(s)
 check(int(p["stats"]["mugs"])==12 and int(p["stats"]["hats"])==8 and int(p["stats"]["hoodies"])==6,"Progress counts mugs, hats and hoodies")
 check(int(p["stats"]["shirts"])==0,"Hoodies are not counted as shirts")
 # New careers unlock the machines by level and get hoodie and tote work later.
 var c=Sim.new();c.save_enabled=false;c.start_shop("Standard")
 check(c.equipment_locked("mug") and c.equipment_locked("embroidery"),"A new career starts without the mug press or embroidery")
 Progress.ensure(c)["xp"]=Progress.LEVEL_XP[2]
 check(not c.equipment_locked("mug") and c.equipment_locked("embroidery"),"The mug press unlocks at level 3")
 Progress.ensure(c)["xp"]=Progress.LEVEL_XP[4]
 check(not c.equipment_locked("embroidery"),"Embroidery unlocks at level 5")
 c.state["cash"]=20000
 for id in ["cutter","heat","art","finish","pack"]: c.install_equipment(id,C.garage_spot(id))
 var blanks={}
 for day in 16:
  for o in c.state["orders"]:
   if o["stage"] in ["scheduled","intake"]: o["stage"]="declined"
  c.next_day()
  for o in c.state["orders"]:
   if o["type"]=="apparel": blanks[C.blank_of(o)]=true
 check(blanks.has("hoodie") and blanks.has("tote") and blanks.has("tee"),"Growing careers get tee, hoodie and tote shirt jobs")
 # Older saves load with the new stock keys and no crashes.
 var old=Sim.new();old.save_enabled=true;old.save_path=ProjectSettings.globalize_path("res://../../../work/products-qa.json")
 for key in ["mugs","subpaper","caps","thread"]: old.state["stock"].erase(key)
 check(old.save_game(),"Write an older-style save")
 var loaded=Sim.new();loaded.save_path=old.save_path
 check(loaded.load_game() and int(loaded.state["stock"].get("caps",-1))==0,"Older saves load with empty new supplies")
 print("PRODUCTS CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

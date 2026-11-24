extends SceneTree
# Merch designs, batches, weekly trend, online store and craft market.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Merch=preload("res://scripts/shop_merch.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)
func _initialize() -> void:
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 check(not Merch.unlocked(s),"Merch is locked on a brand-new career")
 Progress.ensure(s)["xp"]=Progress.LEVEL_XP[1]
 check(Merch.unlocked(s),"Merch opens at shop level 2")
 for id in ["cutter","heat","art","finish","pack"]: s.install_equipment(id,C.garage_spot(id))
 s.state["cash"]=2000
 check(Merch.makeable(s).has("decal"),"The vinyl cutter can make decal merch")
 var cash=s.state["cash"]
 var d=Merch.create_design(s,"decal",Merch.trend(s))
 check(not d.is_empty() and s.state["cash"]==cash-Merch.DESIGN_FEE,"A design costs the design fee")
 check(Merch.make_batch(s,d["id"]),"Queue a batch")
 check(not Merch.make_batch(s,d["id"]),"Only one batch per design at a time")
 s.state["paused"]=false;s.owner()["manual"]=false
 for n in 12000:
  s.tick(.1)
  if int(d["stock"])>0: break
 check(int(d["stock"])==Merch.KINDS["decal"]["batch"],"A finished batch becomes store stock")
 check(not Merch.batch_open(s,d["id"]),"The batch closes when stocked")
 var none=Merch.close_day(s)
 check(int(none["units"])==0,"A closed store sells nothing")
 Merch.toggle_store(s)
 var before=s.state["cash"]
 var res=Merch.close_day(s)
 check(int(res["units"])>0 and s.state["cash"]==before+int(res["revenue"])-Merch.STORE_FEE,"The online store sells stock and charges its fee")
 var t=Merch.demand(s,d)
 d["theme"]="Spooky season" if Merch.trend(s)!="Spooky season" else "Cute cats"
 check(Merch.demand(s,d)<t,"The weekly trend boosts demand")
 var base=Merch.demand(s,d)
 Merch.set_price(s,d["id"],10)
 check(Merch.demand(s,d)<base,"Higher prices sell fewer")
 s.state["day"]=6
 base=Merch.demand(s,d)
 check(Merch.book_booth(s) and Merch.demand(s,d)>base,"A weekend market booth boosts sales")
 s.state["day"]=3
 check(not Merch.book_booth(s),"Craft markets run only on weekends")
 Merch.ensure(s)["sold_total"]=100;Merch.close_day(s)
 check("merch100" in Progress.ensure(s)["awards"],"Selling 100 merch items earns Merch Maker")
 var demo=Sim.new();demo.save_enabled=false;demo.start_demo()
 check(Merch.unlocked(demo),"Older shops can use merch at once")
 print("MERCH CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

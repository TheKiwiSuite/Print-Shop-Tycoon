extends SceneTree
# Reviews, regulars and seasons.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Customers=preload("res://scripts/shop_customers.gd")
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

func ready_order(s,id:String,customer:String,reward:int,late:bool=false) -> Dictionary:
 var o=C.make_order(id,"decal",10,customer,s.now()-1.0 if late else s.now()+5.0,reward)
 o["stage"]="ready";o["quality"]=100
 s.state["orders"].append(o);s._ensure_visit(o)
 return o

func _initialize() -> void:
 # Seasons follow the calendar: a week each, Spring first.
 check(Customers.season_index(1)==0 and Customers.season_index(7)==0 and Customers.season_index(8)==1,"Each season lasts a week")
 check(Customers.season_index(15)==2 and Customers.season_index(22)==3 and Customers.season_index(29)==0,"The seasons cycle Spring, Summer, Fall, Winter")
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 check(Customers.active(s) and Customers.season(s)["name"]=="Spring","A new career starts in Spring")
 s.state["day"]=22
 check(Customers.boosted(s,"mug") and not Customers.boosted(s,"banner"),"Winter boosts mugs")
 check(Customers.seasonal_reward(s,"mug",100)==115 and Customers.seasonal_reward(s,"banner",100)==100,"In-season work pays 15% more")
 s.state["day"]=1
 # A real job leaves a review.
 for id in ["cutter","heat","art","finish","pack"]: s.install_equipment(id,C.garage_spot(id))
 s.state["paused"]=false;s.tick(.1)
 check(s.accept(0),"Accept the first job")
 if s.order(0)["stage"]=="preflight": s.preflight(0,"repair")
 check(s.queue_order(0),"Queue the first job")
 s.owner()["manual"]=false
 advance(s,0,"completed")
 var review=s.order(0).get("review",{})
 check(not review.is_empty() and int(review["stars"])==5,"An on-time, full-quality job earns five stars")
 check(Customers.review_count(s)==1 and is_equal_approx(Customers.rating(s),5.0),"The shop rating updates")
 check(int(s.order(0).get("tip",0))==0,"A first-time customer does not tip")
 # Stars follow satisfaction and lateness.
 check(Customers.stars_for(100,false)==4 and Customers.stars_for(70,true)==3 and Customers.stars_for(10,true)==1,"Late or poor work earns fewer stars")
 # Regulars: the fourth paid job from the same customer tips and waits longer.
 s.state["customers"]["Neon Thread Co."]=3
 check(Customers.is_regular(s,"Neon Thread Co.") and Customers.patience_scale(s,"Neon Thread Co.")>1.0,"Three paid jobs make a regular who waits longer")
 var cash=s.state["cash"]
 var o=ready_order(s,"REG-1","Neon Thread Co.",200)
 s._fulfill(o)
 check(int(o["tip"])==20 and s.state["cash"]==cash+220,"A regular tips 10% on good work")
 var late=ready_order(s,"REG-2","Neon Thread Co.",200,true)
 late["quality"]=60
 s._fulfill(late)
 check(int(late["tip"])==0,"Regulars do not tip for poor work")
 check(Customers.regulars(s).has("Neon Thread Co."),"Regulars are listed")
 # Reviews are kept to a short history but the average counts them all.
 for n in 50: Customers.on_paid(s,{"customer":"Bulk tester","id":"B%d" % n,"product":"Decals"},true,100)
 check(Customers.reviews(s).size()==Customers.REVIEW_LIMIT and Customers.review_count(s)>=50,"Only recent reviews are kept; the average uses every review")
 Progress.refresh(s)
 check("rating45" in Progress.ensure(s)["awards"],"A high average from 20+ reviews earns Loved Locally")
 # Save and load keeps reviews.
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/customers-qa.json")
 check(s.save_game(),"Save a shop with reviews")
 var loaded=Sim.new();loaded.save_path=s.save_path
 check(loaded.load_game() and Customers.review_count(loaded)==Customers.review_count(s),"Reviews survive save and load")
 # The demo and older shops keep their previous rules.
 var demo=Sim.new();demo.save_enabled=false;demo.start_demo()
 demo.state["customers"]["Neon Thread Co."]=5
 check(not Customers.active(demo) and not Customers.is_regular(demo,"Neon Thread Co.") and Customers.seasonal_reward(demo,"mug",100)==100,"The demo has no tips or seasonal prices")
 var dcash=demo.state["cash"]
 var d=ready_order(demo,"DEMO-1","Neon Thread Co.",200)
 demo._fulfill(d)
 check(demo.state["cash"]==dcash+200 and not d.has("review"),"Demo payments are unchanged")
 print("CUSTOMERS CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

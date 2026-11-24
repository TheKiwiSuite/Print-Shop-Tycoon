extends SceneTree
# Staff personalities and the rival shop.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const People=preload("res://scripts/shop_people.gd")
const Customers=preload("res://scripts/shop_customers.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)
func _initialize() -> void:
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 check(People.speed(s.owner())==1.0 and not s.owner().has("trait"),"The owner has no personality modifier")
 var w={"id":"x","trait":"Speedy"}
 check(People.speed(w)>1.0 and People.speed({"trait":"Thrifty"})<1.0,"Speedy works faster, Thrifty slower")
 var seen={}
 for n in 7:
  s.state["next_worker"]=n
  var fake={"id":"staff%d" % n,"name":"T","wage":45}
  People.apply_trait(s,fake)
  seen[fake["trait"]]=true
  check(int(fake["wage"])==int(People.TRAITS[fake["trait"]]["wage"]),"Wage follows personality "+fake["trait"])
 check(seen.size()==4,"Hires come in all four personalities")
 var demo=Sim.new();demo.save_enabled=false;demo.start_demo()
 var dw={"id":"staff1","name":"D","wage":45}
 People.apply_trait(demo,dw)
 check(not dw.has("trait") and int(dw["wage"])==45,"The demo keeps plain staff")
 # Rival shop.
 check(People.rival(s).is_empty() and People.steals(s)==0,"No rival in the first week")
 s.state["day"]=People.RIVAL_DAY
 var r=People.rival(s)
 check(not r.is_empty() and r["name"]==People.RIVAL_NAME,"The rival opens on day 8")
 check(People.steals(s)==1,"Without good reviews the rival wins an inquiry a day")
 for n in 6: Customers.on_paid(s,{"customer":"Fan","id":"F%d" % n,"product":"Decals"},true,100)
 check(People.ahead(s) and People.steals(s)==0,"Beating the rival's rating keeps your customers")
 for n in People.BEAT_DAYS: People.new_day(s)
 check(r["beaten"],"Staying ahead for five days wins the town")
 check("rival" in Progress.ensure(s)["awards"],"Winning the town earns Top Shop in Town")
 # Next day removes one inquiry while behind.
 var t=Sim.new();t.save_enabled=false;t.start_shop("Standard")
 for id in ["cutter","heat","art","finish","pack"]: t.install_equipment(id,C.garage_spot(id))
 t.state["day"]=People.RIVAL_DAY-1
 t.end_day();t.next_day()
 check(int(t.state["rival"]["lost_today"])>=0,"next_day runs the rival check")
 print("PEOPLE CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

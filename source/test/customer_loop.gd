extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0

func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)

func advance(s, i:int, stage:String, limit:int=8000) -> void:
 for n in limit:
  if s.order(i)["stage"]==stage: return
  s.tick(0.1)
 check(false,"Timed out waiting for "+stage+"; actual "+s.order(i)["stage"])

func prepare(s,i:int) -> void:
 check(s.accept(i),"Accept customer job %d" % i)
 check(s.preflight(i,"repair"),"Approve artwork %d" % i)
 if s.order(i)["type"] in ["transfer","apparel"]: s.auto_pack(i)
 check(s.queue_order(i),"Queue prepared job %d" % i)

func _initialize() -> void:
 var s=Sim.new()
 s.save_enabled=false
 check(s.active_orders().is_empty() and s.state["machines"].is_empty(),"New game is blank with no arrived inquiries")
 for n in 100: s.tick(.1)
 check(s.now()==0.0 and s.order(0)["stage"]=="scheduled","Paused setup does not run arrival timers")
 s.state["paused"]=false;s.tick(.1)
 check(s.active_orders().is_empty(),"Unopened equipment route does not generate impossible first work")
 s.state["paused"]=true
 check(s.install_equipment("sticker",Vector2i(4,4)),"Player places starter sticker printer")
 for id in ["art","finish","pack"]:
  check(s.install_equipment(id,s.cell(C.layout(1)[id]["pos"])),"Player places support station "+id)
 s.state["paused"]=false;s.tick(.1)
 check(s.order(0)["type"]=="sticker" and s.order(0)["stage"]=="intake","First customer requests work matching starter equipment")
 check(s.active_orders().size()==1 and s.order(1)["stage"]=="scheduled","Later inquiry arrivals are staggered")
 check(s.customer_patience(s.order(0))>2.99,"Inquiry has a generous three shop-hour acceptance window")
 var before=s.state["cash"]
 prepare(s,0)
 check(s.order(0)["visit"]["status"]=="production" and s.customer_patience(s.order(0))<0,"Accepted work has no abandonment countdown")
 s.owner()["manual"]=false
 # Test a real production stop at a missing station, then complete the loop.
 var finish=s.state["machines"]["finish"].duplicate(true)
 s.state["machines"].erase("finish")
 advance(s,0,"qc")
 check(not s.work_order(0) and s.state["cash"]==before,"Missing inspection station cannot hand off or pay")
 check(s.install_equipment("finish",s.cell(finish["pos"])),"Placing required station resumes blocked production")
 s.owner()["manual"]=false
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/customer-loop-payment.json")
 advance(s,0,"completed")
 check(s.order(0)["visit"]["status"]=="served" and s.order(0)["satisfaction"]==100,"Full sticker loop serves customer with satisfaction")
 check(s.order(0)["paid"] and s.state["cash"]==before+150,"Completion awards the starter payment exactly once")
 var settled=s.state["cash"]
 var completed=s.state["completed"]
 s._fulfill(s.order(0))
 check(s.state["cash"]==settled and s.state["completed"]==completed,"Repeated settlement is idempotent")
 var loaded=Sim.new();loaded.save_path=s.save_path
 check(loaded.load_game(),"Load save written inside payment settlement")
 loaded.save_enabled=false
 check(loaded.owner()["task"].is_empty(),"Settlement snapshot contains no stale worker delivery task")
 for n in 100: loaded.tick(.1)
 check(loaded.state["cash"]==settled and loaded.state["completed"]==completed,"Reloading settlement never replays payment")
 check(loaded.order(0)["visit"]["status"]=="served" and loaded.order(0)["satisfaction"]==100,"Visit and receipt survive reload")
 loaded.next_day();loaded.tick(.1)
 var next_day_supported=false
 for job in loaded.state["orders"]:
  if job["id"].begins_with("DAY2-") and job["type"]=="sticker" and job["stage"]=="intake": next_day_supported=true
 check(next_day_supported,"Next-day customer flow continues with installed starter equipment")
 # Customer patience and accepted orders are pause safe and survive persistence.
 var p=Sim.new();p.save_enabled=false
 p.state["machines"]=C.layout(1);p.state["paused"]=false;p.tick(.1)
 p.accept(0)
 p.state["clock"]=9.0;p.tick(.1)
 check(p.order(1)["visit"]["status"]=="inquiry","Second customer arrives during the shop day")
 p.state["paused"]=true
 var patience=p.customer_patience(p.order(1))
 for n in 100: p.tick(.1)
 check(is_equal_approx(p.customer_patience(p.order(1)),patience),"Pausing freezes customer patience")
 p.save_enabled=true;p.save_path=ProjectSettings.globalize_path("res://../../../work/customer-loop-patience.json");p.save_game()
 var resumed=Sim.new();resumed.save_path=p.save_path
 check(resumed.load_game() and is_equal_approx(resumed.customer_patience(resumed.order(1)),patience),"Save reload preserves exact remaining inquiry time")
 resumed.save_enabled=false;resumed.state["paused"]=false;resumed.state["clock"]=12.1
 var stock=resumed.state["stock"].duplicate(true);var money=resumed.state["cash"]
 resumed.tick(.1)
 check(resumed.order(1)["stage"]=="abandoned" and resumed.order(1)["visit"]["status"]=="left","Unaccepted inquiry leaves after its patience window")
 check(resumed.state["stock"]==stock and resumed.state["cash"]==money,"Abandonment consumes no materials and grants no payment")
 check(resumed.order(0)["stage"]=="preflight","Accepted customer is never abandoned while production is pending")
 check(not resumed.accept(1),"Departed inquiry cannot later be accepted")
 resumed.order(2)["stage"]="intake";resumed.order(2)["visit"]["status"]="inquiry";resumed.order(2)["visit"]["patience_until"]=resumed.now()+3
 check(resumed.decline(2) and resumed.order(2)["visit"]["status"]=="withdrawn","Declining withdraws the corresponding customer visit")
 # Two prepared jobs share one printer and reserve inventory exactly once.
 var q=Sim.new();q.state=C.fresh();q.save_enabled=false
 q.state["orders"].append(C.make_order("SECOND-STICKER","sticker",24,"Second buyer",8,100))
 prepare(q,1);prepare(q,3)
 check(q.hire(2),"Hire one print operator for queue concurrency")
 check(q.work_order(1),"Owner reserves the first queued printer job")
 check(not q._dispatch(3,q.worker("staff0"),"sticker"),"Second worker cannot reserve the same printer concurrently")
 var sheets=q.state["stock"]["sticker"]
 var needed=C.recipe(q.order(1))["sticker"]+C.recipe(q.order(3))["sticker"]
 q.owner()["manual"]=false
 advance(q,1,"completed");advance(q,3,"completed")
 check(q.state["stock"]["sticker"]==sheets-needed,"Queued jobs consume each recipe once")
 check(q.order(1)["paid"] and q.order(3)["paid"],"Both queued jobs reach independent paid settlements")
 # Model the older release's completed-order / working-task save defect.
 var legacy=Sim.new();legacy.state=C.fresh();legacy.save_path=ProjectSettings.globalize_path("res://../../../work/customer-loop-legacy.json")
 var old=legacy.order(0);old["stage"]="completed";old["finished_at"]=1.0
 legacy.state["completed"]=1
 legacy.owner()["task"]={"order":0,"machine":"pack","stage":"ready","working":true}
 legacy.state["machines"]["pack"]["active"]=0
 legacy.save_game()
 var repaired=Sim.new();repaired.save_path=legacy.save_path
 check(repaired.load_game(),"Older save with completed delivery task loads")
 repaired.save_enabled=false
 var original_cash=repaired.state["cash"]
 check(repaired.owner()["task"].is_empty() and repaired.state["machines"]["pack"]["active"]==-1,"Migration releases stale legacy delivery reservation")
 for n in 100: repaired.tick(.1)
 check(repaired.order(0)["paid"] and repaired.state["cash"]==original_cash and repaired.state["completed"]==1,"Legacy completed order is settled without paying it again")
 # A late, accepted lower-quality job has an explicit original satisfaction score.
 var late=Sim.new();late.state=C.fresh();late.save_enabled=false
 late.order(0)["stage"]="ready";late.order(0)["quality"]=70;late.order(0)["quality_accepted"]=true;late.order(0)["due"]=-2.0
 late._fulfill(late.order(0))
 check(late.order(0)["satisfaction"]==50 and late.order(0)["payment"]==365,"Satisfaction combines actual quality and lateness; payment records the quality adjustment")
 for file in [s.save_path,p.save_path,legacy.save_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(file+suffix): DirAccess.remove_absolute(file+suffix)
 print("CUSTOMER LOOP: %d checks, %d failures" % [checks,failures])
 quit(failures)

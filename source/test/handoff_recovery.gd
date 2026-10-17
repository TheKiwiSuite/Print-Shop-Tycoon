extends SceneTree
# Regression fixture copied from the supplied Oct 16 assessment, never a player profile.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error("FAIL: "+label)
 else: print("PASS: "+label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var s=Sim.new()
 s.save_enabled=false
 s.save_path="res://test/fixtures/day8-blocked.json"
 check(s.load_game(),"Load isolated day-eight reproduction fixture")
 var targets=s.active_orders().duplicate()
 check(targets.size()==7,"Fixture contains four unpaid pickups and three queued DTF jobs")
 for id in ["dtf","dtf2"]:
  var m=s.state["machines"][id]
  check(s.placement_feedback(id,s.cell(m["pos"]),int(m["rotation"]))["valid"],"JSON-loaded dimensions preserve valid line "+id)
 var art=s.state["machines"]["art"]
 check(s.placement_feedback("art",s.cell(art["pos"]),int(art["rotation"]))["valid"],"Valid unrelated desk is not rejected as disconnected film feed")
 var damaged=s.state["machines"]["shaker"]["pos"].duplicate()
 s.state["machines"]["shaker"]["pos"]=[4,5]
 check(not s.placement_feedback("art",s.cell(art["pos"]),0)["valid"],"Actually disconnected line remains invalid")
 s.state["machines"]["shaker"]["pos"]=damaged
 var cash=s.state["cash"]
 var expected=0
 for i in targets:
  var o=s.order(i)
  expected+=roundi(o["reward"]*(.76 if o.get("quality_accepted",false) else 1.0))
 s.state["paused"]=false;s.state["clock"]=8.0;s.state["report"]={};s.state["speed"]=4
 for n in 3000:
  s.tick(.1)
  if s.active_orders().is_empty(): break
 for i in targets:
  check(s.order(i)["stage"]=="completed" and s.order(i)["paid"],"Stalled job completes and pays: "+s.order(i)["id"])
 check(is_equal_approx(s.state["cash"]-cash,expected),"All seven payouts reconcile with cash, including accepted discount")
 var settled_cash=s.state["cash"]
 var stock=s.state["stock"].duplicate(true)
 for i in targets: s._fulfill(s.order(i))
 check(s.state["cash"]==settled_cash,"Repeated settlement cannot duplicate payment")
 check(s.state["stock"]==stock,"Repeated settlement cannot consume inventory again")
 # Restart through a writable isolated copy, not the read-only reproduction fixture.
 s.save_path="user://handoff-recovery-qa.json";s.save_enabled=true
 check(s.save_game(),"Save recovered shop to isolated QA profile")
 var restored=Sim.new();restored.save_path=s.save_path;restored.save_enabled=false
 check(restored.load_game(),"Reload recovered shop")
 for i in targets: restored._fulfill(restored.order(i))
 check(restored.state["cash"]==settled_cash,"Reload and repeated settlement preserve exactly-once payment")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(s.save_path+suffix): DirAccess.remove_absolute(s.save_path+suffix)
 # An interrupted print resumes its authoritative stage without consuming twice.
 var r=Sim.new();r.state=C.fresh();r.save_enabled=false
 r.accept(0);r.preflight(0,"repair");r.auto_pack(0);r.queue_order(0)
 r.work_order(0)
 for n in 500:
  r.tick(.1)
  if r.order(0)["stage"]=="production": break
 check(r.order(0)["consumed"],"Initial print consumes materials")
 var print_stock=r.state["stock"].duplicate(true)
 r.interrupt_owner();check(r.work_order(0),"Interrupted print can dispatch again")
 r.tick(.1)
 check(r.order(0)["stage"]=="production","Resumed print returns to production stage")
 check(r.state["stock"]==print_stock,"Resumed print does not consume materials twice")
 # Real input handler and preference path, without touching normal player settings.
 var game=load("res://main.tscn").instantiate()
 game.qa_ui=true;root.add_child(game);game.set_process(false)
 game.sim.save_enabled=false;game.sim.save_path="user://handoff-ui-qa.json"
 game.screen="shop"
 for panel in ["order","machine","staff"]:
  game.modal=panel;game.sim.state["paused"]=false
  var event=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=true
  game._input(event)
  check(game.sim.state["paused"],"Space pauses live panel "+panel)
  game._input(event)
  check(not game.sim.state["paused"],"Space resumes live panel "+panel)
 game.sim.state["settings"]["sound"]=true;game._action("sound")
 game.sim.state["settings"]["sound"]=true;game._load_music_preference()
 check(not game.sim.state["settings"]["sound"],"Sound Off survives snapshot preference restoration")
 check("6-" in game._tutorial_hint(C.make_order("QA","transfer",6,"QA",5,100)),"Tutorial uses live order quantity")
 var pref=game.sim.save_path+".preferences.cfg"
 if FileAccess.file_exists(pref): DirAccess.remove_absolute(pref)
 game.free()
 await process_frame
 print("HANDOFF RECOVERY: ",checks," checks, ",failures," failures")
 quit(failures)

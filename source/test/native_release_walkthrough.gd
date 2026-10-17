extends SceneTree
# Runs inside the actual exported Windows executable in CI. Uses isolated saves.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error("FAIL: "+label)
 else: print("PASS: "+label)
func _initialize() -> void:
 for speed in [1,4]:
  for type in ["transfer","apparel","sticker","banner","cnc"]:
   var s=Sim.new();s.state=C.fresh();s.save_enabled=false
   s.state["location"]=2;s.state["machines"]=C.layout(2)
   var o=C.make_order("NATIVE-"+type+str(speed),type,3,"Release QA",8,180)
   s.state["orders"]=[o];s.owner()["manual"]=false;s.state["speed"]=speed
   check(s.accept(0) and s.preflight(0,"repair"),"Native accept / artwork "+type+str(speed))
   if type in ["transfer","apparel"]: check(s.auto_pack(0),"Native physical gang layout "+type)
   check(s.queue_order(0),"Native queue "+type)
   var paused=false;var restored=false;var saw_press=false
   for frame in 5000:
    var job=s.order(0)
    if job["stage"]=="completed": break
    if job["stage"] in ["press","pressing"]: saw_press=true
    if job["stage"]=="fault": s.recover(0,true)
    if job["stage"]=="production" and not paused:
     s.state["paused"]=true
     var snapshot=JSON.stringify(s.state)
     s.tick(.1)
     check(JSON.stringify(s.state)==snapshot,"Native pause freezes authoritative state "+type)
     s.state["paused"]=false;paused=true
    if paused and not restored:
     s.save_enabled=true;s.save_path="user://release-walkthrough-"+type+str(speed)+".json"
     check(s.save_game(),"Native save during production "+type)
     var next=Sim.new();next.save_path=s.save_path;next.save_enabled=false
     check(next.load_game(),"Native reload during production "+type)
     s=next;restored=true
    s.tick(.1)
   check(s.order(0)["stage"]=="completed" and s.order(0).get("paid",false),"Native complete paid route "+type+str(speed))
   check(saw_press if type=="apparel" else not saw_press,"Native route requires only appropriate stations "+type)
   var cash=s.state["cash"];var stock=s.state["stock"].duplicate(true)
   s._fulfill(s.order(0))
   check(s.state["cash"]==cash and s.state["stock"]==stock,"Native repeated handoff is idempotent "+type)
   for suffix in ["",".bak",".tmp"]:
    if FileAccess.file_exists(s.save_path+suffix): DirAccess.remove_absolute(s.save_path+suffix)
 print("NATIVE RELEASE WALKTHROUGH: ",checks," checks, ",failures," failures / ",OS.get_name())
 quit(failures)

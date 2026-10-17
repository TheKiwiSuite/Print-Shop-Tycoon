extends SceneTree
# Executed with --write-movie and --fixed-fps 20 under the rendered CI runner.
const C=preload("res://scripts/catalog.gd")
var game
var events=[]
var failures=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
 # Movie dimensions are fixed at startup by the workflow's --resolution option.
 # Resizing after the writer starts corrupts the recorded aspect ratio.
 game=load("res://main.tscn").instantiate()
 game.sim.save_enabled=false;game.sim.save_path="user://animation-review-qa.json"
 root.add_child(game);game.set_process(false);game.screen="shop";game.music.stop()
 for speed in [1,4]:
  for type in ["transfer","cnc"]:
   game.sim.state=C.fresh();game.sim.state["location"]=2;game.sim.state["machines"]=C.layout(2)
   game.sim.state["settings"]["reduce_motion"]=false
   game.sim.state["orders"]=[C.make_order("MOTION-"+type+str(speed),type,3,"Motion review",8,180)]
   game.sim.state["speed"]=speed;game.sim.owner()["manual"]=false
   game.sim.accept(0);game.sim.preflight(0,"repair")
   if type=="transfer": game.sim.auto_pack(0)
   game.sim.queue_order(0);game.reset_camera()
   var last="";var pause_frames=0;var did_pause=false
   for frame in 5000:
    var stage=game.sim.order(0)["stage"]
    if stage!=last:
     events.append({"route":type,"speed":speed,"stage":stage,"shop_time":game.sim.now()});last=stage
    if stage=="completed":
     for n in 20: game.queue_redraw();await process_frame
     break
    if stage=="production" and not did_pause: game.sim.state["paused"]=true;pause_frames=40;did_pause=true
    if pause_frames>0:
     pause_frames-=1
     game.status="PAUSED: production motion and output are held"
     if pause_frames==0: game.sim.state["paused"]=false;game.status=""
    game.sim.tick(.05)
    game.queue_redraw();await process_frame
   if game.sim.order(0)["stage"]!="completed": failures+=1;push_error("FAIL: Motion route did not complete "+type+str(speed))
 var folder=ProjectSettings.globalize_path("res://../captures/strategy-review")
 DirAccess.make_dir_recursive_absolute(folder)
 var f=FileAccess.open(folder+"/motion-events.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"scope":"Rendered transfer and CNC routes at 1x and 4x with two-second pause; remaining routes covered by automated state checks.","failures":failures,"events":events},"  "))
 game.free();await process_frame
 print("ANIMATION REVIEW: ",events.size()," stage transitions, ",failures," failures")
 quit(failures)

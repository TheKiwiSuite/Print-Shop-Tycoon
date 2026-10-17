extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
var failures=0
var checks=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if ok: print("PASS: "+label)
 else: failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 var test_root="user://demo-qa-"+str(Time.get_ticks_usec())
 DirAccess.make_dir_recursive_absolute(test_root)
 game.sim.save_path=test_root+"/career.json"
 game.sim.start_shop("Expert");game.sim.state["cash"]=1739
 check(game.sim.save_game(),"Create isolated career fixture")
 var original=FileAccess.get_sha256(game.sim.save_path)
 root.add_child(game);game.set_process(false)
 game.sim.state["settings"]["music"]=false;game._save_audio_preferences()
 game.screen="title";game._action("demo")
 check(game.screen=="shop" and game.sim.state.get("demo",false),"Title launches playable demo")
 check(game.sim.save_path==test_root+"/career.json.demo","Demo save is separate from career")
 check(game.sim.state["machines"].has("dtf") and game.sim.state["machines"].has("sticker") and game.sim.state["machines"].has("heat"),"Demo supplies all starter equipment")
 check(game.sim.state["workers"].size()==4 and game.sim.state["cash"]==5000,"Demo supplies team and disclosed play budget")
 check(not game.sim.state["paused"] and not game.sim.owner()["manual"],"Demo opens running with owner Auto Assist")
 check(not game.sim.state["settings"]["music"],"Demo uses application audio preferences")
 check(game.sim.order(0)["stage"]=="queued","First demo order is prepared using real workflow")
 var pos=game.sim.owner()["pos"].duplicate()
 for tick in 20: game.sim.tick(.1)
 check(game.sim.owner()["pos"]!=pos,"Sam moves to perform the prepared demo job")
 game.sim.state["cash"]=4321
 game._action("title")
 check(game.screen=="title" and game.sim.save_path==test_root+"/career.json","Returning to title restores career slot")
 check(game.sim.state["cash"]==1739 and FileAccess.get_sha256(game.sim.save_path)==original,"Playing and saving demo leaves career byte identical")
 game._action("demo")
 check(game.sim.state["cash"]==4321,"Demo progress resumes from its own saved slot")
 game._action("reset_demo_confirm")
 check(game.sim.state["cash"]==5000 and game.sim.state.get("demo",false),"Demo reset restores supplied shop only")
 check(not game.sim.state["settings"]["music"],"Reset demo retains audio preferences")
 check(FileAccess.get_sha256(test_root+"/career.json")==original,"Reset demo preserves career file")
 game._action("title");game._action("continue")
 check(game.sim.state["cash"]==1739 and not game.sim.state.get("demo",false),"Continue still restores original career")
 game.sim.state["paused"]=true
 var clock=game.sim.state["clock"];var before=game.sim.owner()["pos"].duplicate()
 game.sim.manual_input=Vector2(1,0);game.sim.tick(.1)
 check(game.sim.owner()["pos"]==before and game.sim.state["clock"]==clock,"Pause still freezes movement and shop clock consistently")
 game.queue_free();await process_frame
 print("DEMO SHOP: ",checks," checks, ",failures," failures")
 quit(failures)

extends SceneTree
var failures=0
func check(ok:bool,label:String) -> void:
 if not ok: failures+=1; push_error(label)
 else: print("PASS: "+label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.sim.save_enabled=false
 game.sim.state=game.C.fresh()
 game.screen="shop"
 game.sim.state["paused"]=true
 await process_frame
 await process_frame
 var lines=game.world_hits.filter(func(h): return h["sprite"]==12)
 check(lines.size()==1,"One connected DTF sprite per starter line")
 if lines.size()==1:
  var hit=lines[0]
  var rect:Rect2=hit["rect"]
  check(game._machine_at(rect.position+Vector2(.8,.35)*rect.size)=="dtf","Printer body selects DTF operator panel")
  check(game._machine_at(rect.position+Vector2(.25,.6)*rect.size)=="shaker","White cabinet selects shaker panel")
  check(game._machine_at(rect.position+Vector2(.05,.05)*rect.size)!="shaker","Transparent canvas does not select cabinet")
  game.build=true
  check(game._machine_at(rect.position+Vector2(.25,.6)*rect.size)=="dtf","Build selection moves complete pair from cabinet")
 var printer_before=game._equipment_position("dtf")
 var shaker_before=game._equipment_position("shaker")
 game.dragging="machine";game.drag_id="dtf";game.drag_point=Vector2i(4,1)
 check(game._equipment_position("dtf")-printer_before==game._equipment_position("shaker")-shaker_before,"Drag preview translates printer and shaker together")
 game.dragging=""
 check(game.dtf_views.size()==5,"All five supplied views load")
 for n in 5:
  game._action("dtf_view:%d" % n)
  check(game.modal=="dtf_views" and game.dtf_view_index==n,"View navigation %d" % n)
 game._action("back_machine")
 check(game.modal=="machine","Views return to equipment controls")
 print("DTF ART CHECKS: ",failures," failures")
 quit(failures)

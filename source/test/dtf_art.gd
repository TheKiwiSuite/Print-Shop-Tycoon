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
 # The illustrated printer and shaker are one connected sprite selected as "dtf".
 var lines=game.world_hits.filter(func(h): return h.get("illustrated",false) and h["id"]=="dtf")
 check(lines.size()==1,"One connected DTF sprite per starter line")
 if lines.size()==1:
  var hit=lines[0]
  var rect:Rect2=hit["rect"]
  var selected=""
  for x in range(2,9):
   for y in range(2,9):
    if game._machine_at(rect.position+rect.size*Vector2(x*.1,y*.1))=="dtf": selected="dtf"
  check(selected=="dtf","Illustrated line selects the DTF operator panel")
  check(game._machine_at(rect.position+Vector2(.01,.01)*rect.size)!="dtf","Transparent canvas does not select the line")
  game.build=true
  selected=""
  for x in range(2,9):
   for y in range(2,9):
    if game._machine_at(rect.position+rect.size*Vector2(x*.1,y*.1))=="dtf": selected="dtf"
  check(selected=="dtf","Build selection moves the complete pair")
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
 game.free()
 await process_frame
 # Mixer playbacks retire asynchronously after the game node releases its streams.
 await create_timer(.5).timeout
 call_deferred("quit",failures)

extends SceneTree
var game:Node2D
func _initialize():call_deferred("run")
func capture(name:String):
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 game.get_viewport().get_texture().get_image().save_png("res://../captures/"+name+".png")
func run():
 game=load("res://main.tscn").instantiate()
 game.sim.save_enabled=false
 game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/wall-visual-review.json")
 root.add_child(game);game.set_process(false);game.qa_ui=true
 game.screen="shop";game.sim.state=game.C.empty_shop()
 game.sim.state["settings"]["music"]=false;game.sim.state["settings"]["sound"]=false
 game.sim.install_equipment("dtf",Vector2i(5,4));game.reset_camera()
 await capture("walls-neighborhood")
 game.zoom=.55;await capture("walls-zoomed-out")
 game.sim.state["location"]=2;game.reset_camera();await capture("walls-industrial")
 game.sim.state["location"]=1;game.reset_camera();await capture("walls-neighborhood")
 print("WALL_VISUAL_REVIEW: rendered both shop sizes and minimum zoom")
 if "--hold" in OS.get_cmdline_user_args():game.set_process(true);return
 quit()

extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.qa_ui=true;game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/walking-ui-profile.json")
 game.sim.save_enabled=false;game.sim.state=game.C.empty_shop()
 for id in ["sticker","art","finish","pack"]:
  var m=game.C.layout(1)[id]
  assert(game.sim.install_equipment(id,game.sim.cell(m["pos"])))
 game.sim.state["clock"]=8.8;game.sim.state["paused"]=false
 for n in 20: game.sim.tick(.1)
 game.screen="shop";game.reset_camera()
 if "--capture-customers" in OS.get_cmdline_user_args():
  for n in 180: game.sim.tick(.1)
  game.sim.state["paused"]=true
  await process_frame
  await RenderingServer.frame_post_draw
  game.get_viewport().get_texture().get_image().save_png("res://../captures/walking-customers.png")
  game._quit_game()

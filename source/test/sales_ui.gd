extends SceneTree
# Native UI review uses a dedicated QA profile, never the player's save.
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.qa_ui=true;game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/sales-ui-profile.json")
 if "--resume-qa" in OS.get_cmdline_user_args():
  assert(game.sim.load_game())
 else:
  game.sim.save_enabled=false;game.sim.state=game.C.empty_shop()
  for id in ["sticker","art","finish","pack"]:
   var m=game.C.layout(1)[id]
   assert(game.sim.install_equipment(id,game.sim.cell(m["pos"])))
  game.sim.state["orders"]=[]
  game.sim.save_enabled=true;game.sim.save_game()
 game.screen="shop";game.modal="marketing";game.reset_camera()
 if "--capture-marketing" in OS.get_cmdline_user_args():
  game.sim.save_enabled=false
  await process_frame
  await RenderingServer.frame_post_draw
  game.get_viewport().get_texture().get_image().save_png("res://../captures/marketing-panel.png")
  game._quit_game()

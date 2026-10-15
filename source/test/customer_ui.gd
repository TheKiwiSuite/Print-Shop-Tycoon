extends SceneTree
# Isolated native UI playthrough; never uses the player's save.
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.qa_ui=true
 game.sim.save_path=ProjectSettings.globalize_path("res://../../../work/customer-ui-profile.json")
 if "--review-receipt" in OS.get_cmdline_user_args():
  assert(game.sim.load_game())
  game.sim.save_enabled=false
  game.sim.state["paused"]=true
  game.screen="shop"
  game.selected_order=0
  game.modal="order"
  await process_frame
  await RenderingServer.frame_post_draw
  game.get_viewport().get_texture().get_image().save_png("res://../captures/customer-receipt.png")
  return
 game.sim.state=game.C.empty_shop()
 game.sim.save_enabled=false
 for id in ["sticker","art","finish","pack"]:
  var m=game.C.layout(1)[id]
  assert(game.sim.install_equipment(id,game.sim.cell(m["pos"])))
 game.sim.save_enabled=true
 game.sim.save_game()
 game.screen="shop"
 game.reset_camera()
 if "--capture-receipt" in OS.get_cmdline_user_args():
  game.sim.save_enabled=false
  game.sim.state["paused"]=false
  game.sim.tick(.1)
  assert(game.sim.accept(0))
  assert(game.sim.preflight(0,"repair"))
  assert(game.sim.queue_order(0))
  game.sim.owner()["manual"]=false
  for n in 8000:
   if game.sim.order(0)["stage"]=="completed": break
   game.sim.tick(.1)
  assert(game.sim.order(0)["paid"])
  game.sim.state["paused"]=true
  game.selected_order=0
  game.modal="order"
  await process_frame
  await RenderingServer.frame_post_draw
  game.get_viewport().get_texture().get_image().save_png("res://../captures/customer-receipt.png")
  game._quit_game()

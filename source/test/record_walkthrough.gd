extends SceneTree

const C := preload("res://scripts/catalog.gd")
const FRAMES_PER_SCENE := 60
const OUTPUT_DIR := "res://../../../work/phase-walkthrough-frames"

var game: Node2D
var frame_number := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var absolute_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.qa_ui = true
	game.sim.save_path = ProjectSettings.globalize_path("res://../../../work/walkthrough-profile.json")
	game.sim.save_enabled = false
	game.sim.state = C.empty_shop()
	for id in ["sticker", "art", "finish", "pack"]:
		var machine: Dictionary = C.layout(1)[id]
		assert(game.sim.install_equipment(id, game.sim.cell(machine["pos"])))
	game.sim.state["orders"] = []
	game.sim.state["cash"] = 700
	game.screen = "shop"
	game.modal = "marketing"
	game.reset_camera()
	assert(game.sim.start_campaign("social"))
	await _capture_scene(FRAMES_PER_SCENE)

	game.modal = ""
	game.sim.state["paused"] = false
	game.sim.state["clock"] = 9.3
	game.sim._update_visits()
	for _frame in FRAMES_PER_SCENE * 2:
		game.sim.tick(0.1)
		await _capture_frame()

	assert(game.sim.accept(0))
	assert(game.sim.decline(1))
	assert(game.sim.preflight(0, "repair"))
	assert(game.sim.queue_order(0))
	game.sim.owner()["manual"] = false
	for _tick in 8000:
		game.sim.tick(0.1)
		if game.sim.order(0)["paid"]:
			break
	assert(game.sim.order(0)["paid"])
	game.sim.end_day()
	game.modal = "report"
	await _capture_scene(FRAMES_PER_SCENE)
	print("WALKTHROUGH: %d actual UI frames captured, campaign cost $%d, sale $%d, report net $%.0f" % [frame_number, game.sim.state["stats"]["marketing"], game.sim.state["stats"]["sales"], game.sim.state["report"]["net"]])
	quit()

func _capture_scene(count: int) -> void:
	for _frame in count:
		await _capture_frame()

func _capture_frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUTPUT_DIR + "/frame_%05d.png" % frame_number)
	assert(image.save_png(path) == OK)
	frame_number += 1

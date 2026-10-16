extends SceneTree
const C = preload("res://scripts/catalog.gd")
var game: Node2D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func redraw() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func mouse(point: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = point
	e.pressed = pressed
	game._input(e)

func machine_point() -> Vector2:
	for hit in game.world_hits:
		if hit.get("printer", "") != "dtf": continue
		for y in range(2, 8):
			for x in range(2, 8):
				var p: Vector2 = hit["rect"].position + hit["rect"].size * Vector2(x / 10.0, y / 10.0)
				if game._machine_at(p) == "dtf": return p
	return Vector2(-1, -1)

func drag_release_at(target: Vector2i) -> void:
	await redraw()
	var p := machine_point()
	check(p.x >= 0, "Complete approved DTF sprite is selectable")
	mouse(p, true)
	check(game.dragging == "machine" and game.drag_id == "dtf", "Build click selects complete line")
	# Deliberately omit a motion event to exercise the final drop position.
	mouse(game.iso(Vector2(target) - game.drag_offset), false)
	await redraw()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.sim.save_path = ProjectSettings.globalize_path("res://../../../work/ui-dtf-profile.json")
	game.sim.save_enabled = false
	game.sim.state = C.empty_shop()
	game.sim.state["settings"]["music"] = false
	game.sim.state["settings"]["sound"] = false
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	game.screen = "shop"
	game.build = true
	game._action("place:dtf")
	mouse(game.iso(Vector2(5, 5)), true)
	mouse(game.iso(Vector2(5, 5)), false)
	check(game.sim.state["machines"].size() == 2 and game.pending_equipment == "", "Input handler installs printer and shaker once")
	await redraw()
	var before: Dictionary = game.sim.state["machines"].duplicate(true)
	await drag_release_at(Vector2i(-3, 1))
	check(game.drag_point == Vector2i(-3, 1), "Drop uses mouse-release position even without motion")
	check(game.sim.state["machines"] == before, "Wall drop preserves installed printer and shaker")
	check(game.dragging == "" and game.drag_valid.is_empty(), "Rejected drag clears its preview")
	await drag_release_at(Vector2i(4, 2))
	check(game.sim.cell(game.sim.state["machines"]["dtf"]["pos"]) == Vector2i(4, 2), "Repeated drag commits new location from release event")
	await drag_release_at(Vector2i(5, 5))
	for rotation in 16:
		var key := InputEventKey.new()
		key.keycode = KEY_R
		key.pressed = true
		game._input(key)
		await redraw()
		var expected := (rotation + 1) % 16
		check(game.sim.facing_of(game.sim.state["machines"]["dtf"]) == expected, "R rotates installed printer orientation %d" % expected)
		check(game.sim.facing_of(game.sim.state["machines"]["shaker"]) == expected, "Shaker follows orientation %d" % expected)
		check(game.world_hits.any(func(h): return h.get("printer", "") == "dtf" and h.get("facing",-1) == expected), "Approved angle is rendered and selectable %d" % expected)
	game.selected_machine = "dtf"
	game._action("move_equipment")
	check(game.moving_equipment == "dtf", "Installed machine Move button starts relocation")
	game._action("equipment")
	check(not game._relocating() and game.drag_valid.is_empty(), "Add Equipment cancels earlier relocation")
	game._action("place:art")
	check(game.pending_equipment == "art" and game.moving_equipment == "" and game.dragging == "", "New placement has only one active operation")
	check(game.sim.state["cash"] == 300, "UI relocation and rotation do not charge equipment twice")
	print("UI DTF PLACEMENT: %d checks, %d failures" % [checks, failures])
	quit(failures)

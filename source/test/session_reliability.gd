extends SceneTree
const Sim = preload("res://scripts/simulation.gd")
const C = preload("res://scripts/catalog.gd")
var game: Node2D
var checks := 0
var failures := 0
var scratch := ""

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _initialize() -> void:
	call_deferred("run")

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._input(event)

func redraw() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	scratch = ProjectSettings.globalize_path("res://../../../work/session-qa-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	game = load("res://main.tscn").instantiate()
	game.sim.save_enabled = false
	game.sim.save_path = scratch.path_join("shop.json")
	game.sim.state["settings"]["music"] = false
	game.sim.state["settings"]["sound"] = false
	root.add_child(game)
	game.set_process(false)
	game.screen = "shop"
	game.qa_ui = true
	check(not auto_accept_quit, "Window close waits for the game's save decision")
	check(game.sim.install_equipment("dtf", Vector2i(5, 5)), "Install approved complete DTF line")
	game.selected_machine = "dtf"
	game.build = true
	for panel in ["settings", "help", "stock", "marketing", "staff", "customers"]:
		game._action("move_equipment")
		var before: Dictionary = game.sim.state["machines"].duplicate(true)
		game._action(panel)
		check(not game._relocating() and game.drag_valid.is_empty(), "Opening %s cancels placement preview" % panel)
		key(KEY_R)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.position = game.iso(Vector2(8, 6))
		release.pressed = false
		game._input(release)
		check(game.sim.state["machines"] == before, "Menu blocks hidden rotation and drop: " + panel)
		game._action("close")
	game._action("place:art")
	key(KEY_ESCAPE)
	check(game.pending_equipment == "" and game.drag_valid.is_empty(), "Escape clears new-equipment placement and feedback")
	game._action("move_equipment")
	key(KEY_ESCAPE)
	check(not game._relocating() and game.drag_id == "", "Escape cancels relocation without leaving a selected drag")
	for rotation in 4:
		game.sim.save_enabled = true
		check(game.sim.move_equipment("dtf", Vector2i(5, 5), rotation), "Commit rotated layout %d" % rotation)
		var restored = Sim.new()
		restored.save_path = game.sim.save_path
		check(restored.load_game(), "Reload saved rotated shop %d" % rotation)
		check(int(restored.state["machines"]["dtf"]["rotation"]) == rotation and int(restored.state["machines"]["shaker"]["rotation"]) == rotation, "Printer and shaker keep matching saved rotations %d" % rotation)
		check(restored.cell(restored.state["machines"]["dtf"]["pos"]) == Vector2i(5, 5) and restored.state["cash"] == 300, "Reload preserves position and charges no equipment cost %d" % rotation)
	var real_save: String = game.sim.save_path
	var existing_hash := FileAccess.get_sha256(real_save)
	game.sim.save_path = scratch.path_join("missing-folder/shop.json")
	for action in ["title", "quit", "save"]:
		game._action(action)
		check(game.screen == "shop" and not game.closing and game.modal == "save_error", "Failed %s keeps current session open" % action)
		check(game.pending_save_action == action and not game.sim.last_save_error.is_empty(), "Failed %s has retry context and explanation" % action)
		game._action("close")
		check(game.pending_save_action == "" and game.modal == "", "Keep Playing cancels failed " + action)
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(not game.closing and game.modal == "save_error", "Windows close button cannot bypass failed saving")
	await redraw()
	game.get_viewport().get_texture().get_image().save_png("res://../captures/save-retry-panel.png")
	check(game.buttons.any(func(b): return b["action"] == "retry_save") and game.buttons.any(func(b): return b["action"] == "close"), "Save failure displays retry and keep-playing controls")
	game._action("close")
	game._action("title")
	game.sim.save_path = real_save
	game._action("retry_save")
	check(game.screen == "title" and game.pending_save_action == "", "Retry completes the originally requested Save + Title")
	game._action("continue")
	check(game.screen == "shop" and game.sim.state["machines"].has("dtf"), "Continue restores the retained shop after retry")
	# Block backup rotation using a nonempty directory, entirely in QA scratch.
	var blocked_path := scratch.path_join("blocked.json")
	DirAccess.copy_absolute(real_save, blocked_path)
	DirAccess.make_dir_absolute(blocked_path + ".bak")
	var marker := FileAccess.open(blocked_path + ".bak/keep.txt", FileAccess.WRITE)
	marker.store_string("QA backup obstruction"); marker.close()
	var blocked_hash := FileAccess.get_sha256(blocked_path)
	game.sim.save_path = blocked_path
	check(not game.sim.save_game(), "Backup-rotation failure is reported as save failure")
	check(FileAccess.get_sha256(blocked_path) == blocked_hash, "Failed backup rotation leaves the current save intact")
	check(not game.sim.last_save_error.is_empty(), "Backup failure gives a visible reason")
	# The earlier failed saves must never have changed the previous file.
	check(existing_hash != "" and FileAccess.file_exists(real_save + ".bak"), "Successful retry retains a previous save backup")
	game.sim.save_enabled = false
	print("SESSION RELIABILITY: %d checks, %d failures" % [checks, failures])
	quit(failures)

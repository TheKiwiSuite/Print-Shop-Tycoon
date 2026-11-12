extends SceneTree

const Sim = preload("res://scripts/simulation.gd")
const C = preload("res://scripts/catalog.gd")
var checks = 0
var failures = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func fresh() -> RefCounted:
	var s = Sim.new()
	s.state = C.fresh()
	s.save_enabled = false
	return s

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.qa_ui = true
	root.add_child(game)
	game.sim.save_enabled = false

	# Closing the gang sheet restores a tile whose drag was still in progress.
	game.sim.state = C.fresh()
	game.selected_order = 0
	game.sim.accept(0)
	game.sim.preflight(0, "repair")
	game.sim.auto_pack(0)
	game.modal = "gang"
	var original = game.sim.order(0)["gang"].duplicate(true)
	game._gang_press(game.GANG_POS + Vector2(30, 30))
	if game.gang_drag >= 0:
		game.sim.order(0)["gang"][game.gang_drag][0] += 3.0
	game._action("close")
	check(game.modal == "" and game.gang_drag == -1 and game.sim.order(0)["gang"] == original,
		"Closing a gang sheet during a drag restores its original placement")

	# Owner routing treats occupied customer tiles as obstacles and keeps clearance.
	var s = fresh()
	s.owner()["pos"] = [1.0, 9.0]
	var visitor = s.order(0)
	visitor["stage"] = "intake"
	visitor["visit"] = {"status":"inquiry", "actor":{"order":0,"name":"Waiting customer","pos":[2.0,9.0],"goal":[2,9],"path":[],"purpose":"inquiry","phase":"waiting","walking":false,"step":0.0,"face":1,"variant":0}}
	var customer = visitor["visit"]["actor"]
	var routed = s.move_owner(Vector2i(4, 9))
	var minimum_gap = 99.0
	for n in 60:
		s.tick(0.1)
		minimum_gap = minf(minimum_gap, s.v(s.owner()["pos"]).distance_to(s.v(customer["pos"])))
	check(routed and minimum_gap >= 0.55, "Owner reroutes around customers without occupying their tile")

	# The forecast distinguishes packaging, garment stock, and general materials.
	s = fresh()
	var pack_order = C.make_order("PACK-TEST", "sticker", 50, "Test", 12.0, 120)
	pack_order["stage"] = "pack"
	pack_order["consumed"] = true
	pack_order["boxes_consumed"] = false
	s.state["orders"] = [pack_order]
	s.state["stock"]["packaging"] = 0
	var pack_forecast = s.forecast()
	check(pack_forecast["shortages"].get("packaging", 0) == s.boxes_for(pack_order),
		"Packing forecast includes unconsumed boxes")

	var press_order = C.make_order("PRESS-TEST", "apparel", 6, "Test", 12.0, 120)
	press_order["stage"] = "press"
	press_order["consumed"] = true
	press_order["garments_consumed"] = false
	s.state["orders"] = [press_order]
	s.state["garments"] = press_order["garments"].duplicate(true)
	var garment_forecast = s.forecast()
	check(garment_forecast["shortages"].is_empty(), "Garment forecast reads garment inventory")
	s.state["garments"]["navy:S"] = 0
	garment_forecast = s.forecast()
	check(garment_forecast["shortages"].get("navy:S", 0) == press_order["garments"]["navy:S"],
		"Press forecast reports missing garment sizes")

	# Replaying in a sticker-only shop replaces an incompatible active DTF tutorial.
	game.sim.state = C.empty_shop()
	game.sim.install_equipment("sticker", Vector2i(4, 4))
	var old_tutorial = C.make_order("TUTORIAL-OLD", "transfer", 6, "Tutorial / practice customer", 10.0, 120)
	old_tutorial["priority"] = -1
	old_tutorial["stage"] = "queued"
	game.sim.state["orders"] = [old_tutorial]
	game.sim.state["tutorial_order"] = old_tutorial["id"]
	game._action("tutorial")
	var replacement = game.sim.order(game._tutorial_index())
	check(replacement["type"] == "sticker" and replacement["stage"] == "intake" and game.sim.state["orders"].size() == 1,
		"Sticker-only tutorial replaces an incompatible active DTF job")

	# A failed Continue puts the recovery error in the title screen's visible status.
	var qa_root = ProjectSettings.globalize_path("res://../../../work/qa-regression")
	DirAccess.make_dir_recursive_absolute(qa_root)
	game.sim.save_path = qa_root.path_join("invalid-save.json")
	var corrupt = FileAccess.open(game.sim.save_path, FileAccess.WRITE)
	corrupt.store_string("not valid JSON")
	corrupt.close()
	game.screen = "title"
	game.modal = ""
	game._action("continue")
	check(game.screen == "title" and game.status != "" and game.status.begins_with("No valid save"),
		"Failed Continue exposes the save recovery message on the title screen")
	if FileAccess.file_exists(game.sim.save_path):
		DirAccess.remove_absolute(game.sim.save_path)

	print("BUGFIX REGRESSION: ", checks, " checks, ", failures, " failures")
	game.free()
	await process_frame
	quit(failures)

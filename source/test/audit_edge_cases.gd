extends SceneTree
# Diagnostic reproductions for the v0.2.13 audit. A zero exit means the probe
# finished, not that the observed defects are fixed. See GAME-AUDIT.md.
const Sim = preload("res://scripts/simulation.gd")
const C = preload("res://scripts/catalog.gd")
var game: Node2D
var root_path: String
var findings: Array = []

func _initialize() -> void:
	call_deferred("run")

func observe(id: String, reproduced: bool, actual: Variant) -> void:
	findings.append({"id": id, "reproduced": reproduced, "actual": actual})
	print("AUDIT ", id, " reproduced=", reproduced, " actual=", actual)

func fresh() -> RefCounted:
	var s = Sim.new()
	s.state = C.fresh()
	s.save_enabled = false
	return s

func capture(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(root_path.path_join(name + ".png"))

func run() -> void:
	root_path = ProjectSettings.globalize_path("res://../../../work/audit-v0.2.13")
	DirAccess.make_dir_recursive_absolute(root_path)
	game = load("res://main.tscn").instantiate()
	game.sim.save_enabled = false
	game.sim.state["settings"]["sound"] = false
	game.sim.state["settings"]["music"] = false
	root.add_child(game)
	game.set_process(false)
	game.qa_ui = true
	game.screen = "shop"
	game.sim.state = C.fresh()
	game.sim.state["paused"] = true
	await capture("shop")
	game.build = true
	await capture("build")
	game.build = false

	# A backup exists, but a syntactically valid damaged main save is accepted.
	var valid = fresh()
	valid.save_path = root_path.path_join("damaged-main.json")
	valid.save_enabled = true
	valid.save_game()
	valid.save_game()
	var bad = FileAccess.open(valid.save_path, FileAccess.WRITE)
	bad.store_string(JSON.stringify({"format":"PrintShopTycoonNative", "schema":3, "state":{"machines":{}, "workers":[{}], "orders":[]}}))
	bad.close()
	var restored = Sim.new()
	restored.save_path = valid.save_path
	var accepted = restored.load_game()
	observe("BUG-01", accepted and restored.owner().is_empty(), {"load_returned":accepted,"owner":restored.owner(),"backup_exists":FileAccess.file_exists(valid.save_path+".bak")})

	# The new-game backup is rotated away on the next ordinary save.
	var old = fresh()
	old.save_path = root_path.path_join("new-game.json")
	old.save_enabled = true
	old.state["cash"] = 5432
	old.save_game()
	old.state = C.empty_shop()
	old.save_game()
	var first_backup = JSON.parse_string(FileAccess.get_file_as_string(old.save_path+".bak"))["state"]["cash"]
	old.save_game()
	var second_backup = JSON.parse_string(FileAccess.get_file_as_string(old.save_path+".bak"))["state"]["cash"]
	observe("BUG-02", first_backup==5432 and second_backup==1200, {"original_cash":5432,"backup_after_new_game":first_backup,"backup_after_next_save":second_backup})

	# Walking is solid against equipment but not against waiting customers.
	var s = fresh()
	s.owner()["pos"] = [1.0,9.0]
	var o = s.order(0)
	o["stage"] = "intake"
	s._ensure_visit(o)
	o["visit"]["actor"] = {"order":0,"name":"Waiting customer","pos":[2.0,9.0],"goal":[2,9],"path":[],"purpose":"inquiry","phase":"waiting","walking":false,"step":0.0,"face":1,"variant":0}
	s.move_owner(Vector2i(2,9))
	for n in 20: s.tick(0.1)
	var distance = s.v(s.owner()["pos"]).distance_to(s.v(o["visit"]["actor"]["pos"]))
	observe("BUG-03", distance<0.1, {"owner_customer_distance":distance})

	# Restarting an interrupted, already-consumed print leaves its order queued.
	s = fresh()
	s.owner()["pos"] = [3.0,3.0]
	s.accept(0); s.preflight(0,"repair"); s.auto_pack(0); s.queue_order(0)
	s.work_order(0); s.tick(0.1)
	s.interrupt_owner()
	s.work_order(0); s.tick(0.1)
	observe("BUG-04", s.order(0)["stage"]=="queued" and s.owner()["task"].get("working",false), {"order_stage":s.order(0)["stage"],"machine_active":s.state["machines"]["dtf"]["active"],"worker_working":s.owner()["task"].get("working",false)})

	# Closing the gang sheet during a drag leaves hidden mouse-motion edits live.
	game.sim.state = C.fresh()
	game.selected_order = 0
	game.sim.accept(0); game.sim.preflight(0,"repair"); game.sim.auto_pack(0)
	game.modal = "gang"
	await capture("gang-sheet")
	game._gang_press(game.GANG_POS + Vector2(30,30))
	var gang_before = game.sim.order(0)["gang"].duplicate(true)
	game._action("close")
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2.ZERO
	game._input(motion)
	observe("BUG-05", game.modal=="" and game.sim.order(0)["gang"]!=gang_before, {"modal":game.modal,"drag_index":game.gang_drag,"first_design":game.sim.order(0)["gang"][0]})
	game.gang_drag = -1

	# Forecast omits boxes and garments needed later in an accepted route.
	s = fresh()
	s.order(0)["stage"] = "pack"
	s.order(0)["consumed"] = true
	s.state["stock"]["packaging"] = 0
	var forecast = s.forecast()
	observe("BUG-06", not forecast["shortages"].has("packaging"), {"boxes_needed":s.boxes_for(s.order(0)),"boxes_owned":0,"forecast":forecast})

	# Reprint consumes a maintenance kit without booking its cost.
	s = fresh()
	s.order(0)["stage"] = "fault"
	s.order(0)["production_machine"] = "dtf"
	var kits = s.state["stock"]["maintenance"]
	var material_cost = s.state["stats"]["materials"]
	s.recover(0,true)
	observe("BUG-07", s.state["stock"]["maintenance"]==kits-1 and s.state["stats"]["materials"]==material_cost, {"kits_used":kits-s.state["stock"]["maintenance"],"cost_recorded":s.state["stats"]["materials"]-material_cost})

	# Explicit assignment bypasses the staff specialization used in auto mode.
	s = fresh()
	s.state["cash"] = 10000
	s.hire(0)
	var artist = s.state["workers"][1]
	var matches = s.role_matches(artist,"dtf")
	var assigned = s.assign(artist["id"],"dtf")
	s.accept(0); s.preflight(0,"repair"); s.auto_pack(0); s.queue_order(0)
	s.owner()["manual"] = true
	s.tick(0.1)
	observe("BUG-08", not matches and assigned and artist["task"].get("machine","")=="dtf", {"role":artist["role"],"role_matches":matches,"task":artist["task"]})

	# The curing cabinet panel reports Idle while the parent line is curing.
	s = fresh()
	s.owner()["pos"] = [3.0,3.0]
	s.accept(0); s.preflight(0,"repair"); s.auto_pack(0); s.queue_order(0); s.work_order(0)
	for n in 190: s.tick(0.1)
	observe("BUG-09", s.state["machines"]["dtf"]["phase"]=="Cure transfer" and s.state["machines"]["shaker"]["phase"]=="Idle", {"printer_phase":s.state["machines"]["dtf"]["phase"],"shaker_phase":s.state["machines"]["shaker"]["phase"]})
	game.sim.state = s.state
	game.selected_machine = "shaker"
	game.modal = "machine"
	await capture("shaker-idle-while-curing")

	# A full staff still receives enabled Hire buttons, but clicking is silent.
	game.sim.state = C.fresh()
	game.sim.state["cash"] = 100000
	for n in 8: game.sim.hire(n%7)
	game.modal = "staff"
	game.staff_page = 0
	await capture("staff-cap")
	var can_click = game.buttons.any(func(b): return b["action"]=="hire:0")
	var notices_before = game.sim.state["notices"].duplicate()
	game._action("hire:0")
	observe("BUG-10", can_click and game.sim.state["workers"].size()==9 and notices_before==game.sim.state["notices"], {"hire_button_enabled":can_click,"worker_count":game.sim.state["workers"].size(),"feedback_added":notices_before!=game.sim.state["notices"]})

	# Replay tutorial in a sticker-only shop creates impossible DTF work.
	game.sim.state = C.empty_shop()
	game.sim.install_equipment("sticker",Vector2i(4,4))
	game.sim._update_visits()
	game._action("tutorial")
	var tutorial = game.sim.order(game._tutorial_index())
	observe("BUG-11", tutorial["type"]=="transfer" and not game.sim.state["machines"].has("dtf"), {"tutorial_type":tutorial["type"],"tutorial_stage":tutorial["stage"],"machines":game.sim.state["machines"].keys()})

	# Continue failures only update an invisible notice behind the title screen.
	game.sim.save_path = root_path.path_join("invalid-text-main.json")
	var invalid_file = FileAccess.open(game.sim.save_path,FileAccess.WRITE)
	invalid_file.store_string("invalid JSON"); invalid_file.close()
	game.screen = "title"
	game.modal = ""
	game._action("continue")
	observe("BUG-13", game.screen=="title" and game.modal=="" and game.sim.state["notices"][0].begins_with("No valid save"), {"screen":game.screen,"modal":game.modal,"notice":game.sim.state["notices"][0]})
	await capture("invalid-continue")

	# The title does not load stored preferences; Continue overwrites title edits.
	game.sim.save_path = root_path.path_join("preferences.json")
	game.sim.state = C.fresh()
	game.sim.save_enabled = true
	game.sim.save_game()
	game._action("sound")
	var title_sound = game.sim.state["settings"]["sound"]
	game._action("continue")
	observe("BUG-14", not title_sound and game.sim.state["settings"]["sound"], {"sound_selected_on_title":title_sound,"sound_after_continue":game.sim.state["settings"]["sound"]})
	game.sim.state["settings"]["fullscreen"] = true
	game.sim.save_game()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	game._action("continue")
	observe("BUG-15", game.sim.state["settings"]["fullscreen"] and DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN, {"saved_fullscreen":game.sim.state["settings"]["fullscreen"],"actual_window_mode":DisplayServer.window_get_mode()})
	game.sim.save_enabled = false
	game.screen = "shop"

	game.sim.state = C.fresh()
	game.modal = "help"
	await capture("help")
	game.modal = "stock"
	await capture("stock")
	game.modal = "marketing"
	await capture("marketing")
	game.modal = "report"
	game.sim.end_day()
	await capture("day-report")
	game.modal = ""
	game.sim.state = C.fresh()
	game.sim.state["cash"] = 5000
	game.sim.state["reputation"] = 80
	game.sim.state["completed"] = 3
	game.sim.state["quality_total"] = 300
	game.sim.state["on_time"] = 3
	game.sim.move_garage()
	game.reset_camera()
	await capture("industrial-shop")
	var file = FileAccess.open(root_path.path_join("findings.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(findings,"  ")); file.close()
	print("AUDIT COMPLETE: ", findings.size(), " probes; ", findings.filter(func(f):return f["reproduced"]).size(), " defects reproduced")
	game.sim.save_enabled = false
	quit()

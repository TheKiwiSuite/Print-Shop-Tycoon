extends SceneTree

const C = preload("res://scripts/catalog.gd")
const FPS := 24
const DT := 1.0 / FPS
const OUT := "res://../../../work/dtf-walkthrough-frames"

class Guide extends Node2D:
	var headline := ""
	var detail := ""
	var pointer := Vector2(-100, -100)
	var pressed := false
	func _draw() -> void:
		draw_rect(Rect2(0, 900, 1600, 100), Color("061b37"))
		draw_string(ThemeDB.fallback_font, Vector2(24, 937), headline, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(24, 974), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("a8dff2"))
		if pointer.x < 0: return
		if pressed: draw_circle(pointer, 19, Color(0, 0.9, 1, 0.5))
		var points := PackedVector2Array([pointer, pointer + Vector2(2, 25), pointer + Vector2(9, 17), pointer + Vector2(19, 16)])
		draw_colored_polygon(points, Color.WHITE)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("09234b"), 2)

var game: Node2D
var guide := Guide.new()
var frame := 0
var segments: Array = []
var last_stage := ""

func _initialize() -> void:
	call_deferred("run")

func caption(headline: String, detail: String = "") -> void:
	guide.headline = headline
	guide.detail = detail
	segments.append({"frame": frame, "seconds": float(frame) / FPS, "caption": headline, "detail": detail})
	print("SCENE %.1fs: %s" % [float(frame) / FPS, headline])

func capture() -> void:
	if game.screen == "shop" and not game.build and game.modal in ["", "order", "machine", "staff"]:
		var before: Vector2 = game.sim.v(game.sim.owner()["pos"])
		game.sim.tick(DT)
		var after: Vector2 = game.sim.v(game.sim.owner()["pos"])
		if before != after: assert(game.sim.walk_segment_clear(before, after), "Sam crossed a solid footprint")
	game.time += DT
	game.queue_redraw()
	guide.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUT + "/frame_%05d.png" % frame)
	assert(game.get_viewport().get_texture().get_image().save_png(path) == OK)
	frame += 1

func hold(seconds: float) -> void:
	for _n in ceili(seconds * FPS): await capture()

func mouse(point: Vector2, pressed: bool) -> void:
	guide.pointer = point
	guide.pressed = pressed
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = point
	e.pressed = pressed
	game._input(e)

func motion(point: Vector2) -> void:
	guide.pointer = point
	var e := InputEventMouseMotion.new()
	e.position = point
	game._input(e)

func button(action: String, pause: float = 0.5) -> void:
	var point := Vector2(-1, -1)
	for b in game.buttons:
		if b["action"] == action: point = b["rect"].get_center(); break
	assert(point.x >= 0, "Visible button missing: " + action)
	guide.pointer = point
	await hold(pause)
	mouse(point, true)
	await capture()
	mouse(point, false)
	await hold(0.25)

func place(id: String, tile: Vector2i) -> void:
	await button("equipment", 0.25)
	var available: bool = game.buttons.any(func(b): return b["action"] == "place:" + id)
	if not available: await button("equipment_page", 0.25)
	await button("place:" + id, 0.25)
	motion(game.iso(Vector2(tile)))
	await hold(0.5)
	mouse(game.iso(Vector2(tile)), true)
	await capture()
	mouse(game.iso(Vector2(tile)), false)
	await hold(0.5)
	assert(game.sim.state["machines"].has(id), "Station was not placed: " + id)

func machine_point() -> Vector2:
	for hit in game.world_hits:
		if hit.get("printer", "") != "dtf": continue
		for y in range(2, 8):
			for x in range(2, 8):
				var p: Vector2 = hit["rect"].position + hit["rect"].size * Vector2(x / 10.0, y / 10.0)
				if game._machine_at(p) == "dtf" and p.x > 413: return p
	return Vector2(-1, -1)

func drag_line(target: Vector2i, valid: bool) -> void:
	var original: Dictionary = game.sim.state["machines"].duplicate(true)
	var start := machine_point()
	assert(start.x > 0, "DTF sprite has no selectable point")
	guide.pointer = start
	await hold(0.4)
	mouse(start, true)
	assert(game.dragging == "machine", "DTF selection did not start a drag")
	var end: Vector2 = game.iso(Vector2(target) - game.drag_offset)
	for n in FPS:
		motion(start.lerp(end, float(n + 1) / FPS))
		await capture()
	await hold(0.6)
	mouse(end, false)
	await hold(0.7)
	if valid: assert(game.sim.cell(game.sim.state["machines"]["dtf"]["pos"]) == target, "DTF relocation did not commit")
	else: assert(game.sim.state["machines"] == original, "Rejected placement changed the installed line")

func until_stage(stage: String, max_seconds: float = 60.0) -> void:
	for _n in ceili(max_seconds * FPS):
		if game.sim.order(0)["stage"] == stage: return
		await capture()
	assert(false, "Timed out waiting for " + stage + "; got " + str(game.sim.order(0)["stage"]))

func run() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1600, 1000)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = load("res://main.tscn").instantiate()
	game.sim.save_path = ProjectSettings.globalize_path("res://../../../work/dtf-video-profile.json")
	game.sim.save_enabled = false
	game.sim.state = C.empty_shop()
	game.sim.state["settings"]["music"] = false
	game.sim.state["settings"]["sound"] = false
	game.qa_ui = true
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	assert(not game.is_processing(), "Recorder must own the deterministic gameplay clock")
	guide.z_index = 1000
	game.add_child(guide)
	caption("Native Windows gameplay: a complete DTF transfer order", "Scripted controls in a separate test profile. Every production step is shown; your save is untouched.")
	await hold(2.0)
	await button("new", 0.4)
	caption("1. New Game opens an empty shop", "Start with $1,200. Choose equipment, place it, and arrange your own workspace.")
	await hold(2.0)
	await place("dtf", Vector2i(5, 5))
	caption("2. Rotate the complete printer + shaker line", "R turns both machines together. These are the four supported quarter-turn views using the approved images.")
	for _n in 4:
		var e := InputEventKey.new()
		e.keycode = KEY_R
		e.pressed = true
		game._input(e)
		await hold(1.4)
	caption("3. Reposition an installed DTF line", "Select and drag either visual component. The printer, shaker, film path and floor footprint move together.")
	await drag_line(Vector2i(4, 2), true)
	await drag_line(Vector2i(5, 3), true)
	caption("4. A wall placement is rejected", "The red marker shows the blocked drop. Releasing here keeps the complete installed line in its last valid spot.")
	await drag_line(Vector2i(-2, 1), false)
	caption("5. Move it again after the rejected drop", "The same installed line remains selectable and can be moved to another valid space without another purchase.")
	await drag_line(Vector2i(4, 2), true)
	caption("6. Add the free artwork, inspection and pickup benches", "The DTF line costs $900; the three starter support benches are included.")
	for id in ["art", "finish", "pack"]:
		await place(id, game.sim.cell(C.layout(1)[id]["pos"]))
	await button("build", 0.3)
	caption("7. Open the shop and walk Sam on the floor", "Click clear floor to walk there. The customer walks in for the first 24-transfer inquiry.")
	await button("pause", 0.3)
	var floor_point: Vector2 = game.iso(Vector2(3, 7))
	mouse(floor_point, true)
	mouse(floor_point, false)
	await hold(4.0)
	caption("8. Accept the customer order and repair the artwork", "The order shows the quantity, payment, deadline and required production route.")
	await button("order:0", 0.3)
	await hold(1.0)
	await button("accept", 0.3)
	await button("preflight", 0.3)
	await button("gang", 0.3)
	caption("9. Build the gang sheet in Kiwi Suite", "Auto-pack keeps the artwork at its physical size. Approve the sheet to queue the transfer job.")
	await button("auto_pack", 0.3)
	await hold(1.2)
	await button("queue", 0.3)
	await button("work", 0.3)
	for _n in 3:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		game._input(wheel)
	await button("speed:2", 0.1)
	caption("10. Sam walks to the DTF line and runs the complete process", "The HUD shows 2x speed. Watch CMYK + white printing, powder shaking, curing and front take-up on the progress label.")
	await until_stage("qc")
	await hold(0.7)
	caption("11. Inspect the finished transfers", "Open the job and select Work as Sam. He walks to the inspection bench and checks output and count.")
	await button("camera", 0.1)
	await button("order:0", 0.2)
	await button("work", 0.3)
	await until_stage("pack")
	caption("12. Pack the order", "The finished job moves to the pickup bench. Packaging stock is consumed here.")
	await button("order:0", 0.2)
	await button("work", 0.3)
	await until_stage("ready")
	caption("13. The customer returns for pickup", "Payment waits for the customer to reach the counter and the handoff to finish.")
	for _n in FPS * 20:
		if game.sim.customer_ready_for_handoff(game.sim.order(0)): break
		await capture()
	assert(game.sim.customer_ready_for_handoff(game.sim.order(0)), "Pickup customer never reached the counter")
	await hold(0.7)
	await button("order:0", 0.2)
	await button("work", 0.3)
	await until_stage("completed")
	caption("14. Completed: 24 DTF transfers, customer paid $480", "The cash total updates only after handoff. The receipt records the payment and satisfaction.")
	await hold(1.2)
	await button("customers", 0.3)
	await hold(2.0)
	await button("close", 0.2)
	await button("end_day", 0.3)
	caption("15. Day-end accounts show the result", "Sales, materials, artwork, marketing, wages and overhead are shown here. This walkthrough used no marketing campaign.")
	await hold(3.0)
	var result := {"fps": FPS, "frames": frame, "seconds": float(frame) / FPS, "version": ProjectSettings.get_setting("application/config/version"), "paid": game.sim.order(0)["payment"], "completed": game.sim.state["completed"], "segments": segments}
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../../../work/dtf-walkthrough.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("DTF WALKTHROUGH COMPLETE: %d frames, %.1f seconds, payment $%d" % [frame, float(frame) / FPS, game.sim.order(0)["payment"]])
	quit()

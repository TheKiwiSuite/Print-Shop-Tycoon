extends SceneTree
# Rendered layout certification for the 1.1 finalization pass.
# Checks every recorded modal text block against every control and every other
# text block, keeps text and controls inside the modal panel, and captures PNGs.
const C=preload("res://scripts/catalog.gd")
const Ops=preload("res://scripts/shop_operations.gd")
const Style=preload("res://scripts/shop_style.gd")
var game
var folder=""
var failures=0
var checks=0
var captured=0

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+label)

func _initialize() -> void:
	call_deferred("run")

func frame() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func layout(name:String,save:bool=true) -> void:
	await frame()
	var panel=Rect2(Vector2(355,105)+game.ui_offset,Vector2(890,680)).grow(1)
	var screen=Rect2(Vector2.ZERO,game.get_viewport_rect().size)
	var texts=game.layout_text.duplicate()
	var controls=game.semantic_buttons.duplicate()
	check(not texts.is_empty(),"Layout recorded "+name)
	for c in controls:
		check(screen.encloses(c["rect"]),"Control on screen "+name+" / "+c["label"])
		if game.modal!="" and c["action"]!="close":
			check(panel.encloses(c["rect"]),"Control inside panel "+name+" / "+c["label"])
	for i in texts.size():
		var t=texts[i]
		var r:Rect2=t["rect"].grow(-1)
		if r.size.x<=0 or str(t["text"]).strip_edges()=="":
			continue
		if game.modal!="":
			check(panel.encloses(r),"Text inside panel "+name+" / "+str(t["text"]).left(60))
		for c in controls:
			check(not r.intersects(c["rect"]),"Text clear of control "+name+" / "+str(t["text"]).left(50)+" / "+c["label"])
		for j in range(i+1,texts.size()):
			var u:Rect2=texts[j]["rect"].grow(-1)
			if u.size.x<=0 or str(texts[j]["text"]).strip_edges()=="":
				continue
			check(not r.intersects(u),"Text clear of text "+name+" / "+str(t["text"]).left(40)+" / "+str(texts[j]["text"]).left(40))
	for i in controls.size():
		for j in range(i+1,controls.size()):
			check(not controls[i]["rect"].intersects(controls[j]["rect"]),"Controls separate "+name+" / "+controls[i]["label"]+" / "+controls[j]["label"])
	if save:
		var image=root.get_texture().get_image()
		check(not image.is_empty(),"Frame rendered "+name)
		if not image.is_empty():
			image.save_png(folder.path_join(name+".png"))
			captured+=1

func add_order(type:String,quantity:int,reward:int) -> int:
	var o=C.make_order("QA-%s-%d" % [type.to_upper(),game.sim.state["orders"].size()],type,quantity,"Layout Check Club With A Long Name",game.sim.now()+6.0,reward)
	game.sim.state["orders"].append(o)
	return game.sim.state["orders"].size()-1

func order_stage(index:int,stage:String) -> void:
	var o=game.sim.order(index)
	o["stage"]=stage
	if stage=="fault":
		o["issue"]="Registration drift on the contour cut; marks were misread at the right edge"
	if stage=="completed":
		o["payment"]=o["reward"];o["satisfaction"]=100;o["quality"]=100

func run() -> void:
	folder=ProjectSettings.globalize_path("res://../captures/final-review")
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://main.tscn").instantiate()
	game.sim.save_enabled=false
	root.add_child(game)
	game.set_process(false)
	game.screen="shop"
	game.sim.start_demo()
	game.music.stop()
	Style.ensure(game.sim)
	Ops.ensure(game.sim)
	var types={"sticker":24,"apparel":6,"transfer":24,"mug":12,"hat":8,"decal":24,"banner":2,"cnc":4}
	var indices={}
	for type in types:
		indices[type]=add_order(type,types[type],210)
	for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=size
		await process_frame
		game.reset_camera()
		var tag="%dx%d" % [size.x,size.y]
		# Every product's order panel through each decision stage.
		for type in indices:
			for stage in ["intake","preflight","plan","queued","press","fault","completed"]:
				if stage=="press" and type!="apparel":
					continue
				order_stage(indices[type],stage)
				game.selected_order=indices[type]
				game.modal="order"
				await layout("%s-order-%s-%s" % [tag,type,stage],type in ["sticker","apparel"] or stage in ["intake","plan"])
		# Sticker plan with the artwork-change offer visible (the reported overlap state).
		var sticker=indices["sticker"]
		order_stage(sticker,"plan")
		game.sim.order(sticker)["artwork_offer"]={"kind":"qa"}
		game.selected_order=sticker
		game.modal="order"
		await layout(tag+"-sticker-plan-with-artwork-offer")
		game.sim.order(sticker).erase("artwork_offer")
		# Optional timing: enabled only when eligible; reasons shown inside the panel.
		var shirt=indices["apparel"]
		# Each window size is a fresh attempt for the same fixture job.
		game.sim.state["operations"]["qtes"].clear()
		game.sim.state["operations"]["qte_count"]=0
		order_stage(shirt,"plan")
		game.selected_order=shirt
		game.modal="order"
		check(Ops.qte_unavailable(game.sim,shirt,"press")!="","Shirt planning stage is not timing-eligible")
		await layout(tag+"-timing-unavailable-reason")
		var reason_shown=false
		for t in game.layout_text:
			if str(t["text"])==Ops.qte_unavailable(game.sim,shirt,"press"):
				reason_shown=true
		check(reason_shown,"Ineligible timing reason is drawn in the order panel")
		game._action("intervene")
		check(game.modal=="order","Ineligible timing keeps the order panel open")
		check(game.modal_toast.find("Optional timing unavailable")>=0,"Ineligible timing feedback is shown with the panel")
		await layout(tag+"-timing-feedback-toast")
		order_stage(shirt,"press")
		var press_reason=Ops.qte_unavailable(game.sim,shirt,"press")
		check(press_reason=="","Ready-to-press shirt is timing-eligible: "+press_reason)
		game._action("intervene")
		check(game.modal=="intervention","Enabled timing button always opens an intervention")
		game._action("qte_skip")
		game.modal=""
		# Workshop pages, including Away with no report and with real report shapes.
		for page in 6:
			game.modal="workshop"
			game.workshop_page=page
			game.workshop_service_page=0
			await layout("%s-workshop-%d" % [tag,page])
		var ops=game.sim.state["operations"]
		ops["return_report"]={}
		game.modal="workshop"
		game.workshop_page=2
		await layout(tag+"-away-empty")
		var empty_text=""
		for t in game.layout_text:
			empty_text+=str(t["text"])
		check(empty_text.find("No away shift completed yet")>=0,"Empty Away report is plain language")
		check(empty_text.find("{}")<0,"No raw dictionary in Away panel")
		ops["return_report"]={"reason":"Offline work settled once; 1 real second = 0.009 shop hours, always 1x. Stops at closing or a manager decision.","seconds":900.0,"cap":900,"jobs":2,"cash_change":296.0,"spent":24}
		await layout(tag+"-away-offline-report")
		ops["return_report"]={}
		# Service list at maximum equipment: every serviceable machine reachable, nothing leaves the panel.
		var machines=game.sim.state["machines"]
		var originals=machines.keys()
		var serial=0
		for kind in ["dtf","sticker","heat","banner","cnc","cutter","dtfmini","mug","embroidery"]:
			for copy in 2:
				var source_id=""
				for id in originals:
					if machines[id]["kind"]==kind:
						source_id=id
				var m={}
				if source_id!="":
					m=machines[source_id].duplicate(true)
				else:
					m=machines["heat"].duplicate(true)
					m["kind"]=kind
					m["title"]="Added "+kind+" station"
				m["title"]=str(m.get("title",kind))+" #%d" % (copy+2)
				m["active"]=-1
				m["broken"]=copy==1
				serial+=1
				machines["qa_%s_%d" % [kind,serial]]=m
		var expected=[]
		for id in machines:
			if Ops.SERVICE.has(machines[id]["kind"]) and machines[id]["kind"]!="shaker":
				expected.append(id)
		check(expected.size()>=14,"Maximum-equipment fixture has many serviceable machines")
		var reached={}
		var pages=ceili(expected.size()/5.0)
		for page in pages:
			game.modal="workshop"
			game.workshop_page=1
			game.workshop_service_page=page
			await layout("%s-service-page-%d" % [tag,page],page<2)
			for c in game.semantic_buttons:
				if str(c["action"]).begins_with("service:"):
					reached[str(c["action"]).trim_prefix("service:")]=true
		for id in expected:
			check(reached.has(id),"Service row reachable for "+id)
		# Page navigation works through the real action path.
		game._action("worktab:1:1")
		check(game.workshop_service_page==1 and game.modal=="workshop","Service NEXT page action")
		for id in machines.keys():
			if str(id).begins_with("qa_"):
				machines.erase(id)
		# Growth guidance for each premises step.
		var premises_before=game.sim.state.get("premises","")
		game.sim.state["premises"]="garage"
		game.modal="move"
		await layout(tag+"-growth-garage")
		for t in game.layout_text:
			check(not t.get("truncated",false),"Growth guidance is not truncated at "+tag+" / "+str(t["text"]).left(50))
		var advice=game._growth_advice()
		check(str(advice[0]).begins_with("NEXT STEP"),"Growth panel names a concrete next step in the garage")
		game.sim.state["premises"]=premises_before
		game.sim.state["location"]=2
		game.sim.state["fit_out"]=false
		await layout(tag+"-growth-warehouse")
		for t in game.layout_text:
			check(not t.get("truncated",false),"Warehouse guidance is not truncated at "+tag+" / "+str(t["text"]).left(50))
		game.sim.state["location"]=1
		game.reset_camera()
		# The world-space next step for a manual handoff.
		game.modal=""
		var owner=game.sim.owner()
		owner["manual"]=true
		owner["task"]={}
		order_stage(shirt,"queued")
		game.sim.order(shirt)["method"]=game.sim.shirt_method(game.sim.order(shirt))
		game.selected_order=shirt
		await frame()
		var chip=false
		for c in game.buttons:
			if str(c["action"])=="next_work:%d" % shirt:
				chip=true
		check(chip,"Next-step chip offers Sam's next hand-off for the selected job")
		var image=root.get_texture().get_image()
		image.save_png(folder.path_join(tag+"-next-step-chip.png"))
		# Photo mode: deck fits the window, fit-to-frame keeps the floor inside the crop.
		game._action("photo_mode")
		await frame()
		var screen_rect=Rect2(Vector2.ZERO,game.get_viewport_rect().size)
		for i in game.buttons.size():
			check(screen_rect.encloses(game.buttons[i]["rect"]),"Photo control on screen "+tag+" / "+game.buttons[i]["label"])
			for j in range(i+1,game.buttons.size()):
				check(not game.buttons[i]["rect"].intersects(game.buttons[j]["rect"]),"Photo controls separate "+tag+" / "+game.buttons[i]["label"]+" / "+game.buttons[j]["label"])
		root.get_texture().get_image().save_png(folder.path_join(tag+"-photo-deck.png"))
		for fmt in 3:
			game.photo_format=fmt
			game._action("photo_fit")
			var crop=preload("res://scripts/workshop_photo.gd").crop_rect(game,fmt)
			var b=game.shop_world_bounds()
			var projected=Rect2(game.origin+game.offset+b.position*game.zoom,b.size*game.zoom)
			check(crop.grow(1).encloses(projected),"Fit-to-frame keeps the whole floor in format %d at %s" % [fmt,tag])
		game.photo_format=2
		game._action("photo_controls")
		await frame()
		root.get_texture().get_image().save_png(folder.path_join(tag+"-photo-portrait-fitted.png"))
		game._action("photo_controls")
		game._action("photo_close")
		# Growth, capacity, settings and help panels.
		for panel in ["move","capacity","help","settings","stock","staff","marketing"]:
			game.modal=panel
			await layout(tag+"-"+panel)
		game.modal=""
	game.sim.save_enabled=false
	game.music.stop()
	await preload("res://test/qa_audio_cleanup.gd").stop(game,self);game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	print("FINAL VISUAL REVIEW: %d checks, %d failures, %d captures" % [checks,failures,captured])
	call_deferred("quit",failures)

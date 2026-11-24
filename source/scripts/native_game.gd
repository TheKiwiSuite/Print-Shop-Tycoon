extends Node2D

const Ops=preload("res://scripts/shop_operations.gd")
const Studio=preload("res://scripts/workshop_studio.gd")
const Art=preload("res://scripts/artwork_negotiation.gd")
const Style=preload("res://scripts/shop_style.gd")
const Look=preload("res://scripts/character_look.gd")
const Progress=preload("res://scripts/shop_progress.gd")
const Customers=preload("res://scripts/shop_customers.gd")
const Merch=preload("res://scripts/shop_merch.gd")
const People=preload("res://scripts/shop_people.gd")
const Workshop=preload("res://scripts/workshop_ui.gd")
const Photo=preload("res://scripts/workshop_photo.gd")
const Banner=preload("res://scripts/partner_banner.gd")
var partner_banners=[]
var world_labels=[]
var workshop_page=0
var workshop_service_page=0
var style_worker="owner"
var pending_decor=""
var moving_decor=""
var selected_decor=""
var decor_point=Vector2i(2,2)
var decor_previous_pause=true
var shop_name_edit:LineEdit
var banner_index=0
var banner_elapsed=0.0
var banner_paused=false
var floor_texture:Texture2D
var floor_texture_path=""
var photo_render=false
var photo_active=false
var photo_busy=false
var photo_format=0
var photo_imported=false
var photo_controls_hidden=false
var photo_last_path=""
var photo_previous={}
var qte_previous_pause=false
const Sim = preload("res://scripts/simulation.gd")
const C = preload("res://scripts/catalog.gd")
const Strategy = preload("res://scripts/shop_strategy.gd")
const Updates = preload("res://scripts/game_updates.gd")
var update_service
var career_sim
const Ground = preload("res://scripts/grounding.gd")
const NAVY = Color("09234b")
const BLUE = Color("103bb5")
const CYAN = Color("00bce8")
const MAGENTA = Color("ef1f8e")
const YELLOW = Color("ffd52f")
const GREEN = Color("32c981")
const RED = Color("b52742")
var SHOP_VIEW:Rect2:
 get:
  if photo_render or photo_active:return Rect2(Vector2.ZERO,get_viewport_rect().size)
  return Rect2(276,76,get_viewport_rect().size.x-288,get_viewport_rect().size.y-214)
var ui_offset=Vector2.ZERO
const DOCK = Color("eef1e7")
const CREAM = Color("fffdf5")
const INK = Color("17324e")
const MUTED = Color("4a6477")
var sim = Sim.new()
var screen = "title"
var modal = ""
var font:Font
var bold:Font
var atlas:Texture2D
var official_logo:Texture2D
var owner_sheet:Texture2D
var dtf_texture:Texture2D
var shaker_texture:Texture2D
var dtf_line_texture:Texture2D
var dtf_views=[]
var dtf_view_index=0
var illustrated={}
var illustrated_info={}
var placement_facing=0
var drag_facing=0
var pending_equipment=""
var placement_rotation=0
var equipment_page=0
const DTF_LINE_ORIGIN=Vector2(0.46,0.84)
const DTF_LINE_CONTACTS=[Vector2(0.056,0.735),Vector2(0.169,0.837),Vector2(0.32,0.677),Vector2(0.382,0.802),Vector2(0.691,0.963),Vector2(0.979,0.902)]
var dtf_shaker_region=PackedVector2Array([Vector2(0.373,0.403),Vector2(0.61,0.321),Vector2(0.94,0.343),Vector2(1,0.684),Vector2(1,1),Vector2(0.64,1),Vector2(0.35,0.766),Vector2(0.337,0.5)])
var machine_images={}
var atlas_tiles={}
var atlas_regions = [Rect2(20,22,358,320),Rect2(394,13,355,317),Rect2(781,33,363,317),Rect2(1164,15,365,348),Rect2(20,344,351,333),Rect2(390,362,379,299),Rect2(782,366,381,314),Rect2(1230,348,269,349),Rect2(49,667,304,337),Rect2(481,667,172,349),Rect2(862,669,167,348),Rect2(1133,689,370,312)]
var buttons = []
var semantic_buttons=[]
var world_hits = []
var worker_hits = []
var customer_hits = []
var output_hits = []
var selected_order = -1
var selected_machine = "dtf"
var selected_worker = "owner"
var order_page = 0
var customer_page = 0
var merch_kind = ""
var merch_theme = 0
var staff_page = 0
var build = false
var zoom = 0.92
var offset = Vector2.ZERO
var origin = Vector2(700,190)
var pan = false
var dragging = ""
var drag_id = ""
var drag_order = -1
var drag_point = Vector2i.ZERO
var drag_rotation = 0
var drag_offset = Vector2.ZERO
var preview_center_offset = Vector2.ZERO
var moving_equipment = ""
var drag_valid = {}
var gang_drag = -1
var gang_selected = -1
var gang_before = []
var time = 0.0
var autosave = 0.0
var status = ""
var audio:AudioStreamPlayer
var music:AudioStreamPlayer
# Original tunes and sound effects (see art/audio-v1). The shop shuffles three
# tunes; the title screen has its own. Sounds follow what happens in the shop.
const MUSIC_SHOP=["open-sign","weeding-by-the-window","rush-order"]
const MUSIC_TITLE="paper-and-ink"
const SFX_NAMES=["click","place","cash","door","done","fanfare","levelup","error","cutter","press","print","pack","day"]
var sfx_streams={}
var sfx_players=[]
var sfx_last={}
var music_tracks={}
var music_queue=[]
var music_last=""
var music_context=""
var audio_watch={}
# Shop level pop-ups and goal toasts waiting to be shown.
var goals_page=0
var reviews_view=false
var season_seen=-1
var progress_card={}
var pending_cards=[]
var toasts=[]
# Headless runs (tests, packaged smoke check) have no audio device: stay silent so
# nothing is left playing when the engine shuts down.
var audio_output=true
var capture_args = []
var qa_ui=false
var qa_desktop=false
var qa_frame_deltas=[]
var accessibility_context=""
var last_key={}
var key_tap=Vector2.ZERO
var closing=false
var pending_save_action=""
var desktop_bar=false
var desktop_pinned=false
var desktop_menu=""
var desktop_timeout=0.0
var desktop_buttons=[]
var desktop_mouse_down=false
var desktop_choice=-1
var draft_rules=Strategy.rules("Standard")
var board_page=0
var board_filter="All"
var board_sort="Due"
var accessible_buttons={}
var accessible_summary:Label
var movement_bindings={"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S}
var binding_action=""
var forecast_preview={}
var forecast_preview_at=-1000
var record_modal_text=false
# QA-only layout record: drawn text bounds in modal UI coordinates, checked by final_visual_review.gd.
var layout_text=[]
var layout_in_button=false
var modal_toast=""
var modal_toast_modal=""
var modal_toast_until=0
var modal_accessible_text=[]
const DESKTOP_MENUS=["File","Edit","View","Window","Help"]
const DESKTOP_HEIGHT=40.0
const GANG_POS = Vector2(460,218)
const GANG_SCALE = 9.0

func _ready() -> void:
 get_tree().auto_accept_quit=false
 get_window().title="Print Shop Tycoon - v" + str(ProjectSettings.get_setting("application/config/version"))
 font=ThemeDB.fallback_font
 bold=load("res://assets/logo-font.ttf")
 atlas=load("res://assets/shop-atlas.png")
 official_logo=load("res://assets/official-logo.png")
 owner_sheet=load("res://assets/owner-walk.png")
 Look.load_layers()
 dtf_line_texture=load("res://assets/dtf-line-approved.png")
 for path in ["approved","right","left","back","front"]:
  dtf_views.append(load("res://assets/dtf-line-"+path+".png"))
 for index in atlas_regions.size():
  var img=_isolated_sprite(atlas.get_image().get_region(atlas_regions[index]))
  atlas_tiles[index]=ImageTexture.create_from_image(img)
  machine_images[index]=img
 if dtf_texture!=null: machine_images[0]=dtf_texture.get_image()
 if shaker_texture!=null: machine_images[1]=shaker_texture.get_image()
 machine_images[12]=dtf_line_texture.get_image()
 machine_images[13]=dtf_views[2].get_image()
 machine_images[14]=dtf_views[4].get_image()
 machine_images[15]=dtf_views[1].get_image()
 _load_illustrated()
 audio=AudioStreamPlayer.new()
 music=AudioStreamPlayer.new()
 add_child(audio)
 add_child(music)
 audio_output=DisplayServer.get_name()!="headless"
 _load_audio()
 capture_args=OS.get_cmdline_user_args()
 if "--qa-desktop" in capture_args:
  qa_desktop=true;qa_ui=true;sim.save_path="user://desktop-acceptance-profile.json";sim.save_enabled=false
  sim.start_demo();sim.state["paused"]=true;sim.owner()["manual"]=true;screen="shop"
  sim.state["settings"]["music"]=false
 if "--qa-ui" in capture_args:
  qa_ui=true
  sim.save_path="user://ui-acceptance-profile.json"
 if "--smoke" in capture_args or "--capture" in capture_args:
  if "--capture" in capture_args and not "--empty" in capture_args: sim.state=C.fresh()
  sim.save_enabled=false
  screen="shop"
  if "--garage" in capture_args:
   sim.state["completed"]=3; sim.state["on_time"]=3; sim.state["quality_total"]=300; sim.state["reputation"]=70; sim.state["cash"]=4600
   sim.move_garage()
   reset_camera()
  if "--build" in capture_args: build=true
  for arg in capture_args:
   if str(arg).begins_with("--rotation="):
    sim.state=C.empty_shop();sim.save_enabled=false
    sim.install_equipment("dtf",Vector2i(5,5),int(str(arg).get_slice("=",1)))
    build=true
  if "--capture" in capture_args: call_deferred("_capture")
  if "--smoke" in capture_args: get_tree().create_timer(3.0).timeout.connect(_quit_game)
 if photo_render:
  reset_camera();return
 partner_banners=Banner.read_config()
 _load_music_preference()
 reset_camera()
 get_viewport().size_changed.connect(reset_camera)
 _start_music()
 shop_name_edit=LineEdit.new();shop_name_edit.max_length=40
 shop_name_edit.accessibility_name="Shop name, up to 40 characters"
 shop_name_edit.accessibility_description="Save this name to paint the shop's wall sign and use it as an optional photo watermark."
 shop_name_edit.placeholder_text="Your print shop name";shop_name_edit.add_theme_font_size_override("font_size",20)
 shop_name_edit.text_submitted.connect(func(_value):_action("shop_name_save"))
 add_child(shop_name_edit);shop_name_edit.hide()
 accessible_summary=Label.new()
 accessible_summary.mouse_filter=Control.MOUSE_FILTER_IGNORE
 accessible_summary.self_modulate=Color(1,1,1,0)
 accessible_summary.accessibility_name="Shop status"
 accessible_summary.accessibility_live=1
 accessible_summary.size=Vector2(800,600)
 accessible_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 accessible_summary.clip_text=true
 add_child(accessible_summary)
 update_service=Updates.new();add_child(update_service)
 if "--update-health" in OS.get_cmdline_user_args():
  var probe=Sim.new();probe.save_enabled=false
  if probe.has_save() and not probe.load_game():return
  Updates.acknowledge_startup()

func _capture() -> void:
 await get_tree().create_timer(1.2).timeout
 await RenderingServer.frame_post_draw
 var filename="native-level2.png" if sim.state["location"]==2 else "native-level1.png"
 if build: filename="native-build.png"
 if "--empty" in capture_args: filename="native-empty-shop.png"
 for arg in capture_args:
  if str(arg).begins_with("--rotation="): filename="native-dtf-rotation-%s.png" % str(arg).get_slice("=",1)
 get_viewport().get_texture().get_image().save_png("res://../captures/"+filename)
 _quit_game()

# Release every audio stream when the game node leaves the tree, so the engine
# never shuts down with a sound still playing.
func _exit_tree() -> void:
 if audio!=null: audio.stop();audio.stream=null
 if music!=null: music.stop();music.stream=null
 for player in sfx_players: player.stop();player.stream=null

func _quit_game() -> void:
 if closing: return
 closing=true
 audio.stop(); music.stop()
 for player in sfx_players: player.stop();player.stream=null
 audio.stream=null; music.stream=null
 await get_tree().create_timer(0.1).timeout
 get_tree().quit()

func _notification(what:int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  if photo_active:_action("photo_close")
  _action("quit")
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT: sim.manual_input=Vector2.ZERO; key_tap=Vector2.ZERO

func _process(delta:float) -> void:
 time+=delta
 if qa_desktop and qa_frame_deltas.size()<240:qa_frame_deltas.append(delta)
 _desktop_tick(delta)
 Banner.tick(self,delta)
 if screen=="shop":
  Ops.cosmetic(sim,delta)
  if modal=="intervention" and get_window().has_focus() and desktop_menu=="":
   var q=sim.state.get("operations",{}).get("active_qte",{})
   if not q.is_empty():q["elapsed"]+=delta
  if photo_active:
   sim.manual_input=Vector2.ZERO;queue_redraw();_sync_accessibility();return
  var input=Vector2.ZERO
  if modal=="" and desktop_menu=="" and not build and get_window().has_focus():
   var sx=float(_held(KEY_D) or _held(KEY_RIGHT))-float(_held(KEY_A) or _held(KEY_LEFT))
   var sy=float(_held(KEY_S) or _held(KEY_DOWN))-float(_held(KEY_W) or _held(KEY_UP))
   input=Vector2(sx+sy,sy-sx)
   if input==Vector2.ZERO: input=key_tap
  key_tap=Vector2.ZERO
  sim.manual_input=input
  if modal in ["","order","machine","staff"] and desktop_menu=="" and not build:
   sim.tick(delta)
  autosave+=delta
  if autosave>10:
   _stamp_offline();sim.save_game(); autosave=0.0
  if not sim.state["report"].is_empty() and modal=="": modal="report"
  _progress_events()
  _audio_events()
 # The title screen and the shop each have their own music.
 if ("shop" if screen=="shop" else "title")!=music_context and not photo_render: _start_music()
 queue_redraw()
 _sync_accessibility()
 if qa_ui:
  var qa=FileAccess.open("user://desktop-acceptance-state.json" if qa_desktop else "user://ui-acceptance-state.json",FileAccess.WRITE)
  var focus=get_viewport().gui_get_focus_owner()
  if qa!=null:qa.store_string(JSON.stringify({"accessibility_enabled":get_tree().is_accessibility_enabled(),"accessibility_supported":get_tree().is_accessibility_supported(),"semantic_count":accessible_buttons.size(),"screen":screen,"modal":modal,"owner":sim.owner(),"orders":sim.state["orders"],"cash":sim.state["cash"],"build":build,"speed":sim.state["speed"],"paused":sim.state["paused"],"last_key":last_key,"window_mode":DisplayServer.window_get_mode(),"window_focus":get_window().has_focus(),"focused":focus.accessibility_name if focus!=null else "","style":sim.state.get("style",{}),"frames":qa_frame_deltas,"viewport":[_screen_size().x,_screen_size().y]}))

func iso(p:Vector2) -> Vector2:
 return origin+offset+Vector2((p.x-p.y)*48,(p.x+p.y)*23)*zoom

func _held(key:Key) -> bool:
 var remap={KEY_A:"left",KEY_D:"right",KEY_W:"up",KEY_S:"down"}
 if remap.has(key): key=movement_bindings[remap[key]]
 return Input.is_key_pressed(key)

func uniso(p:Vector2) -> Vector2:
 var d=(p-origin-offset)/zoom
 return Vector2((d.x/48+d.y/23)*0.5,(d.y/23-d.x/48)*0.5)

func shop_world_bounds() -> Rect2:
 var size=sim.bounds()
 # The warehouse and factory include their outdoor loading yard on the right.
 var wide=size.x+_yard_depth()
 return Rect2(Vector2(-size.y*48-12,-190),Vector2((wide+size.y)*48+24,(wide+size.y-1)*23+198))

func fit_zoom() -> float:
 var bounds=shop_world_bounds()
 return minf((SHOP_VIEW.size.x-24)/bounds.size.x,(SHOP_VIEW.size.y-24)/bounds.size.y)

func reset_camera() -> void:
 zoom=fit_zoom();offset=Vector2.ZERO
 origin=SHOP_VIEW.get_center()-shop_world_bounds().get_center()*zoom

func _clamp_camera() -> void:
 var projected=shop_world_bounds().size*zoom
 var limit=(projected-SHOP_VIEW.size).max(Vector2.ZERO)*.5
 offset=offset.clamp(-limit,limit)

func _zoom_shop(point:Vector2,amount:float) -> void:
 var floor_before=uniso(point)
 zoom=clampf(zoom+amount,fit_zoom(),maxf(1.55,fit_zoom()*1.8))
 origin=SHOP_VIEW.get_center()-shop_world_bounds().get_center()*zoom
 offset=point-iso(floor_before)+offset
 _clamp_camera()

func _input(event:InputEvent) -> void:
 if event is InputEventKey and shop_name_edit!=null and shop_name_edit.visible and shop_name_edit.has_focus():
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_action("worktab:4");get_viewport().set_input_as_handled()
  return
 if photo_active:
  if event is InputEventKey and event.pressed:
   if event.keycode==KEY_ESCAPE:_action("photo_close");return
   if event.keycode==KEY_HOME:reset_camera();return
   return
  if event is InputEventMouseButton:
   if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
    for b in buttons:
     if b["rect"].has_point(event.position):_action(b["action"]);return
    return
   if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:_zoom_shop(event.position,.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -.08)
   if event.button_index==MOUSE_BUTTON_MIDDLE:pan=event.pressed
  if event is InputEventMouseMotion and pan:offset+=event.relative;_clamp_camera()
  return
 if _desktop_input(event):return
 if event is InputEventKey:
  last_key={"physical":event.physical_keycode,"keycode":event.keycode,"unicode":event.unicode,"pressed":event.pressed}
 if event is InputEventKey and event.pressed and not event.echo:
  var code=event.keycode if event.keycode!=0 else event.physical_keycode
  if screen=="shop" and modal=="" and (pending_decor!="" or moving_decor!=""):
   var moves={KEY_LEFT:Vector2i(-1,0),KEY_RIGHT:Vector2i(1,0),KEY_UP:Vector2i(0,-1),KEY_DOWN:Vector2i(0,1)}
   if moves.has(code):decor_point+=moves[code];get_viewport().set_input_as_handled();return
   if code in [KEY_ENTER,KEY_KP_ENTER]:_commit_decor(decor_point);get_viewport().set_input_as_handled();return
   if code==KEY_ESCAPE:_cancel_world_drag();get_viewport().set_input_as_handled();return
  if binding_action!="":
   if code==KEY_ESCAPE: binding_action="";return
   if code<KEY_A or code>KEY_Z or code in [KEY_B,KEY_E,KEY_Q,KEY_R]: status="Choose a letter other than reserved B, E, Q or R, or Escape to cancel.";return
   for name in movement_bindings:
    if name!=binding_action and movement_bindings[name]==code: status="That key already moves "+name+".";return
   movement_bindings[binding_action]=code;binding_action="";_save_audio_preferences();return
  if screen=="shop" and modal=="" and (pending_equipment!="" or _relocating()):
   var move={KEY_LEFT:Vector2i(-1,0),KEY_RIGHT:Vector2i(1,0),KEY_UP:Vector2i(0,-1),KEY_DOWN:Vector2i(0,1)}
   if move.has(code): drag_point+=move[code];_refresh_equipment_preview();get_viewport().set_input_as_handled();return
   if code in [KEY_ENTER,KEY_KP_ENTER]:
    var ok=sim.install_equipment(pending_equipment,drag_point,placement_rotation,placement_facing,Vector2(drag_point)+preview_center_offset) if pending_equipment!="" else sim.move_equipment(drag_id,drag_point,drag_rotation,drag_facing,Vector2(drag_point)+preview_center_offset)
    if ok: _cancel_world_drag()
    else: status=drag_valid.get("reason","Choose clear floor.")
    get_viewport().set_input_as_handled();return
  if code==KEY_Q and screen=="shop": _action("capacity");return
  if screen=="shop" and modal=="" and not build:
   var directions={movement_bindings["right"]:Vector2(1,-1),KEY_RIGHT:Vector2(1,-1),movement_bindings["left"]:Vector2(-1,1),KEY_LEFT:Vector2(-1,1),movement_bindings["up"]:Vector2(-1,-1),KEY_UP:Vector2(-1,-1),movement_bindings["down"]:Vector2(1,1),KEY_DOWN:Vector2(1,1)}
   if directions.has(code): key_tap=directions[code]
  match code:
   KEY_F11: _action("fullscreen")
   KEY_ESCAPE:
    if pending_decor!="":pending_decor="";return
    if modal=="intervention":_action("qte_skip")
    elif modal!="" and modal!="report": _action("close")
    elif pending_equipment!="" or moving_equipment!="" or dragging!="": _cancel_world_drag()
    elif build: build=false
    else: modal="settings"
   KEY_SPACE:
    if screen=="shop" and modal in ["","order","machine","staff"]:
     _action("pause");get_viewport().set_input_as_handled()
   KEY_B:
    if screen=="shop" and modal=="": _action("build")
   KEY_HOME: reset_camera()
   KEY_1,KEY_2,KEY_4:
    if modal=="": sim.state["speed"]={KEY_1:1,KEY_2:2,KEY_4:4}[code]
   KEY_E:
    if modal=="" and screen=="shop" and not build: _interact_nearby()
   KEY_R:
    if modal=="gang": _rotate_gang()
    elif modal!="" or screen!="shop": pass
    elif pending_equipment!="": _rotate_equipment()
    elif _relocating(): _rotate_equipment()
    elif build and sim.state["machines"].has(selected_machine):
     var id="dtf2" if selected_machine=="shaker2" else ("dtf" if selected_machine=="shaker" else selected_machine)
     var m=sim.state["machines"][id]
     _rotate_equipment()
   KEY_F5:
    if screen=="shop": _action("save")
  return
 if event is InputEventMouseButton:
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed and modal=="" and SHOP_VIEW.has_point(event.position):
   _zoom_shop(event.position,0.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.08)
  if event.button_index==MOUSE_BUTTON_MIDDLE:
   pan=event.pressed and SHOP_VIEW.has_point(event.position)
  if event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed:
    for b in buttons:
     if b["rect"].has_point(event.position): _action(b["action"]); return
    if modal=="gang": _gang_press(event.position-_modal_offset()); return
    if modal!="" or screen!="shop" or not SHOP_VIEW.has_point(event.position): return
    if pending_decor!="" or moving_decor!="":
     var tile=uniso(event.position);decor_point=Vector2i(roundi(tile.x),roundi(tile.y));_commit_decor(decor_point);return
    if pending_equipment!="":
     var tile=uniso(event.position)
     var at=Vector2i(roundi(tile.x),roundi(tile.y))
     if sim.install_equipment(pending_equipment,at,placement_rotation,placement_facing,Vector2(at)+preview_center_offset):
      selected_machine=pending_equipment;pending_equipment=""
     return
    if moving_equipment!="":
     var tile=uniso(event.position)
     var at=Vector2i(roundi(tile.x),roundi(tile.y))
     if sim.move_equipment(moving_equipment,at,drag_rotation,drag_facing,Vector2(at)+preview_center_offset):
      moving_equipment="";drag_valid={}
     return
    if not build:
     for n in range(customer_hits.size()-1,-1,-1):
      var hit=customer_hits[n]
      if hit["rect"].has_point(event.position): selected_order=hit["order"];modal="order";return
    for hit in worker_hits:
     if hit["rect"].has_point(event.position):
      dragging="worker"; drag_id=hit["id"]; selected_worker=drag_id; return
    if not build:
     for hit in output_hits:
      if hit["rect"].has_point(event.position): dragging="output"; drag_order=hit["order"]; return
    var machine=_machine_at(event.position)
    if machine!="":
     selected_machine=machine
     if build:
      dragging="machine"; drag_id=machine; drag_point=sim.cell(sim.state["machines"][machine]["pos"]); drag_offset=Vector2(drag_point)-uniso(event.position); drag_rotation=int(sim.state["machines"][machine]["rotation"]);drag_facing=sim.facing_of(sim.state["machines"][machine]); drag_valid=sim.placement_feedback(machine,drag_point,drag_rotation,drag_facing)
      preview_center_offset=sim.equipment_center(machine,sim.state["machines"])-Vector2(drag_point)
     else: modal="machine"
     return
    var p=uniso(event.position)
    sim.move_owner(Vector2i(roundi(p.x),roundi(p.y)))
   else:
    if modal!="" and modal!="gang":
     _cancel_world_drag()
     return
    if modal=="" and screen=="shop" and dragging!="" and not SHOP_VIEW.has_point(event.position):
     _cancel_world_drag();sim.notice("Move cancelled outside the shop view.");return
    if gang_drag>=0:
     var gang=sim.order(selected_order)["gang"]
     if not sim.gang_valid(selected_order,gang): gang[gang_drag]=gang_before
     gang_drag=-1
    elif dragging=="machine":
     # Commit from the release event, not the preceding mouse-motion preview.
     # A fast final movement (or a dropped motion event) must still reject walls.
     var p=uniso(event.position)+drag_offset
     drag_point=Vector2i(roundi(p.x),roundi(p.y))
     _refresh_equipment_preview()
     sim.move_equipment(drag_id,drag_point,drag_rotation,drag_facing,Vector2(drag_point)+preview_center_offset)
     dragging=""
     drag_valid={}
    elif dragging=="worker":
     var machine=_machine_at(event.position)
     if machine!="": sim.assign(drag_id,machine)
     elif drag_id=="owner":
      var p=uniso(event.position); sim.move_owner(Vector2i(roundi(p.x),roundi(p.y)))
     else:
      var w=sim.worker(drag_id)
      if w["task"].is_empty():
       var p=uniso(event.position); var goal=Vector2i(roundi(p.x),roundi(p.y))
       w["path"]=sim.path(Vector2i(roundi(w["pos"][0]),roundi(w["pos"][1])),goal)
     dragging=""
    elif dragging=="output":
     var target=_machine_at(event.position)
     var o=sim.order(drag_order)
     if target==sim.machine_for(o) or (sim.dtf_family(target) and sim.dtf_family(sim.machine_for(o))): sim.work_order(drag_order,target)
     else: status="Take this job to the required station: "+sim.machine_for(o)+"."
     dragging=""
 if event is InputEventMouseMotion:
  if pan and modal=="":
   offset+=event.relative;_clamp_camera()
  if _relocating():
   var p=uniso(event.position)+(drag_offset if moving_equipment=="" else Vector2.ZERO)
   drag_point=Vector2i(roundi(p.x),roundi(p.y))
   _refresh_equipment_preview()
  if pending_equipment!="":
   var p=uniso(event.position)
   drag_point=Vector2i(roundi(p.x),roundi(p.y))
   _refresh_equipment_preview()
  if gang_drag>=0:
   var tile=sim.order(selected_order)["gang"][gang_drag]
   var pos=(event.position-_modal_offset()-GANG_POS)/GANG_SCALE-Vector2(tile[2],tile[3])*0.5
   tile[0]=snappedf(pos.x,0.5); tile[1]=snappedf(pos.y,0.5)

func _machine_at(p:Vector2) -> String:
 for n in range(world_hits.size()-1,-1,-1):
  var hit=world_hits[n]
  if not hit["rect"].has_point(p): continue
  var img:Image=machine_images.get(hit["sprite"])
  if img==null: return hit["id"]
  var uv=(p-hit["rect"].position)/hit["rect"].size
  if hit["flip"]: uv.x=1.0-uv.x
  var px=clampi(int(uv.x*img.get_width()),0,img.get_width()-1)
  var py=clampi(int(uv.y*img.get_height()),0,img.get_height()-1)
  if img.get_pixel(px,py).a>0.15:
   if hit.get("illustrated",false): return hit["id"]
   if hit["sprite"] in [12,13,14,15]:
    if build: return hit["printer"]
    if hit["sprite"]==13: return hit["id"] if uv.x<0.63 and uv.y>0.3 else hit["printer"]
    if hit["sprite"]==14: return hit["id"] if uv.x>0.24 and uv.x<0.78 and uv.y>0.38 else hit["printer"]
    if hit["sprite"]==15: return hit["id"] if uv.x>0.4 and uv.y>0.38 else hit["printer"]
    return hit["id"] if Geometry2D.is_point_in_polygon(uv,dtf_shaker_region) else hit["printer"]
   return hit["id"]
 return ""

func _relocating() -> bool:
 return dragging=="machine" or moving_equipment!=""

func _cancel_world_drag() -> void:
 if pending_decor!="" or moving_decor!="":sim.state["paused"]=decor_previous_pause
 pending_decor="";moving_decor=""
 if sim.state.has("operations"):sim.state["operations"]["finance_intent"]=""
 pending_equipment="";moving_equipment="";dragging="";drag_id="";drag_valid={};drag_offset=Vector2.ZERO;pan=false

func _save_before(action:String) -> bool:
 _stamp_offline()
 if sim.save_game():
  pending_save_action=""
  return true
 pending_save_action=action
 _cancel_world_drag()
 modal="save_error"
 return false

func _render_machines() -> Dictionary:
 return drag_valid["machines"] if (_relocating() or pending_equipment!="") and drag_valid.has("machines") else sim.state["machines"]

func _refresh_equipment_preview() -> void:
 # The loading bay always sits against the outside wall: slide it along that wall.
 if pending_equipment=="dock" or (_relocating() and drag_id=="dock") or moving_equipment=="dock":
  drag_point.x=sim.bounds().x-2
 var center=Vector2(drag_point)+preview_center_offset
 if pending_equipment!="":drag_valid=sim.install_feedback(pending_equipment,drag_point,placement_rotation,placement_facing,center)
 elif _relocating():drag_valid=sim.placement_feedback(drag_id,drag_point,drag_rotation,drag_facing,center)

func _interact_nearby() -> void:
 var nearest=""
 var distance=3.0
 var pos=sim.v(sim.owner()["pos"])
 for id in sim.state["machines"]:
  var d=pos.distance_to(Vector2(sim.service(id)))
  if d<distance: distance=d; nearest=id
 if nearest=="": status="Walk closer to a station, then press E."
 else: selected_machine=nearest; modal="machine"

func _draw() -> void:
 _sync_shop_name_editor()
 buttons.clear();semantic_buttons.clear(); world_hits.clear(); worker_hits.clear(); customer_hits.clear(); output_hits.clear()
 world_labels.clear()
 _world()
 if not (photo_render or photo_active):_draw_world_labels()
 if photo_render:
  Photo.draw_brand(self,Rect2(Vector2.ZERO,_screen_size()));return
 if photo_active:Photo.draw(self);return
 if pending_decor!="" or moving_decor!="":
  _diamond(iso(Vector2(decor_point)),48*zoom,23*zoom,Color(.1,.8,.9,.35),CYAN)
 if screen=="title":
  _set_ui_offset(_modal_offset())
  _title()
  _set_ui_offset(Vector2.ZERO)
  _version_badge()
  _desktop_draw()
  return
 _ui_docks()
 _hud()
 _orders()
 _toolbar()
 if not build:_setup_card()
 if not build: _customer_card()
 if build: _build_panel()
 if dragging=="worker":
  var p=uniso(get_global_mouse_position())
  _diamond(iso(Vector2(roundf(p.x),roundf(p.y))),48*zoom,23*zoom,Color(0.1,0.8,1,0.4))
 if dragging=="output": _product(sim.order(drag_order)["type"],get_global_mouse_position(),42)
 if modal=="" and dragging=="" and SHOP_VIEW.has_point(get_global_mouse_position()): _station_hover_label()
 if modal=="" and not build and dragging=="": _next_action_chip()
 _toasts()
 if modal!="":
  _set_ui_offset(_modal_offset());_modal();_set_ui_offset(Vector2.ZERO)
 _version_badge()
 _desktop_draw()

func _desktop_tick(delta:float) -> void:
 if not desktop_bar:return
 var mouse=get_global_mouse_position()
 if desktop_pinned or desktop_menu!="" or mouse.y<=DESKTOP_HEIGHT:
  desktop_timeout=.7
 else:
  desktop_timeout-=delta
  if desktop_timeout<=0:desktop_bar=false

func _desktop_items(menu:String) -> Array:
 var shop=screen=="shop"
 var editable=shop and modal=="" and sim.state["report"].is_empty()
 var selected=editable and sim.state["machines"].has(selected_machine)
 match menu:
  "File":return [["Workshop: operations + style","workshop",shop],["Photo mode","photo_mode",shop],["Selected job intervention","intervene",shop and selected_order>=0],["Shop growth + fit-out","move",shop],["New game","new",modal!="save_error"],["Continue saved shop","continue",screen=="title" and sim.has_save()],["Save shop    F5","save",shop],["Save and return to title","title",shop],["Settings","settings",true],["Save and quit    Alt+F4","quit",true]]
  "Edit":return [["Arrange equipment    B","build",editable],["Move selected equipment","move_equipment",selected],["Rotate selected equipment    R","rotate_equipment",selected and build],["Cancel placement    Esc","cancel_placement",editable and (pending_equipment!="" or _relocating())]]
  "View":return [["Fit whole shop    Home","camera",shop],["Music: "+("On" if sim.state["settings"]["music"] else "Off"),"music",true],["Toggle fullscreen    F11","fullscreen",true]]
  "Window":return [["Minimize","window_minimize",true],["Windowed / restore","window_restore",true],["Maximize","window_maximize",true],["Fullscreen    F11","window_fullscreen",true]]
  "Help":return [["Check for updates","updates",true],["Separate-folder updater (fallback)","check_updates",true],["How to play","help",true],["Settings and keyboard controls","settings",true]]
 return []

func _desktop_heading_rect(index:int) -> Rect2:
 return Rect2(220+index*70+(24 if index>3 else 0),0,94 if index==3 else 70,DESKTOP_HEIGHT)

func _desktop_menu_rect() -> Rect2:
 var index=DESKTOP_MENUS.find(desktop_menu)
 return Rect2(_desktop_heading_rect(index).position.x,DESKTOP_HEIGHT,316,_desktop_items(desktop_menu).size()*36+8)

func _desktop_cell(rect:Rect2,label:String,action:String,enabled:bool=true,active:bool=false) -> void:
 var hover=rect.has_point(get_global_mouse_position())
 if active or (hover and enabled):draw_rect(rect,RED if action=="quit" else BLUE)
 var color=CREAM if enabled else Color("7d91ab")
 var x=(rect.size.x-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x)*.5 if rect.size.x==60 else 12.0
 _text(rect.position+Vector2(x,rect.size.y*.5+6),label,17,color)

func _desktop_targets() -> Array:
 var result=[]
 for i in DESKTOP_MENUS.size():
  result.append({"rect":_desktop_heading_rect(i),"action":"desktop_menu:"+DESKTOP_MENUS[i],"enabled":true})
 var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
 result.append({"rect":Rect2(_screen_size().x-180,0,60,DESKTOP_HEIGHT),"action":"window_minimize","enabled":true})
 result.append({"rect":Rect2(_screen_size().x-120,0,60,DESKTOP_HEIGHT),"action":"window_restore" if full else "window_fullscreen","enabled":true})
 result.append({"rect":Rect2(_screen_size().x-60,0,60,DESKTOP_HEIGHT),"action":"quit","enabled":true})
 if desktop_menu!="":
  var box=_desktop_menu_rect()
  for i in _desktop_items(desktop_menu).size():
   var row=_desktop_items(desktop_menu)[i]
   result.append({"rect":Rect2(box.position+Vector2(4,4+i*36),Vector2(box.size.x-8,36)),"action":row[1],"enabled":row[2]})
 return result

func _desktop_draw() -> void:
 desktop_buttons.clear()
 # This transient bar occupies the HUD dock, never the shop floor.
 if not desktop_bar:
  draw_rect(Rect2(_screen_size().x*.35,0,_screen_size().x*.3,3),CYAN)
  return
 desktop_buttons=_desktop_targets()
 draw_rect(Rect2(0,0,_screen_size().x,DESKTOP_HEIGHT),NAVY)
 _text(Vector2(13,26),"PRINT SHOP TYCOON",19,CREAM,-1,true)
 for i in DESKTOP_MENUS.size():
  _desktop_cell(_desktop_heading_rect(i),DESKTOP_MENUS[i],"desktop_menu:"+DESKTOP_MENUS[i],true,desktop_menu==DESKTOP_MENUS[i])
 _text(Vector2(_screen_size().x-365,25),"F10  /  F11",15,Color("9cb9d1"))
 _desktop_cell(Rect2(_screen_size().x-180,0,60,DESKTOP_HEIGHT),"—","window_minimize")
 var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
 _desktop_cell(Rect2(_screen_size().x-120,0,60,DESKTOP_HEIGHT),"□","window_restore" if full else "window_fullscreen")
 _desktop_cell(Rect2(_screen_size().x-60,0,60,DESKTOP_HEIGHT),"X","quit")
 if desktop_menu=="":return
 var box=_desktop_menu_rect()
 _panel(box,NAVY,Color("607b9a"),3)
 var items=_desktop_items(desktop_menu)
 for i in items.size():
  var row=items[i]
  _desktop_cell(Rect2(box.position+Vector2(4,4+i*36),Vector2(box.size.x-8,36)),row[0],row[1],row[2],desktop_choice==i)

func _desktop_dismiss() -> void:
 desktop_menu="";desktop_pinned=false;desktop_bar=false;desktop_choice=-1
 key_tap=Vector2.ZERO;pan=false

func _desktop_run(action:String) -> void:
 _desktop_dismiss()
 match action:
  "window_minimize":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
  "window_restore":
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
   sim.state["settings"]["fullscreen"]=false
  "window_maximize":
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
   sim.state["settings"]["fullscreen"]=false
  "window_fullscreen":
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
   sim.state["settings"]["fullscreen"]=true
  "cancel_placement":_cancel_world_drag()
  _: _action(action)
 if action in ["window_restore","window_maximize","window_fullscreen"]: _save_window_preference()

func _desktop_input(event:InputEvent) -> bool:
 if event is InputEventMouseMotion:
  if event.position.y<=6 and dragging=="" and gang_drag<0 and not pan:
   desktop_bar=true;desktop_timeout=.7
  if desktop_menu!="" and event.position.y<DESKTOP_HEIGHT:
   for i in DESKTOP_MENUS.size():
    if _desktop_heading_rect(i).has_point(event.position):
     desktop_menu=DESKTOP_MENUS[i];desktop_choice=-1
  return desktop_bar and (event.position.y<DESKTOP_HEIGHT or desktop_menu!="")
 if event is InputEventKey and event.pressed and not event.echo:
  var code=event.keycode if event.keycode!=0 else event.physical_keycode
  if code==KEY_F10:
   if desktop_bar and desktop_pinned:_desktop_dismiss()
   else:desktop_bar=true;desktop_pinned=true;desktop_timeout=.7
   return true
  if code==KEY_ESCAPE and desktop_bar:_desktop_dismiss();return true
  if desktop_menu!="":
   var items=_desktop_items(desktop_menu)
   if code in [KEY_LEFT,KEY_RIGHT]:
    desktop_menu=DESKTOP_MENUS[posmod(DESKTOP_MENUS.find(desktop_menu)+(1 if code==KEY_RIGHT else -1),DESKTOP_MENUS.size())];desktop_choice=-1
   elif code in [KEY_DOWN,KEY_UP]:
    var step=1 if code==KEY_DOWN else -1
    for attempt in items.size():
     desktop_choice=posmod(desktop_choice+step,items.size())
     if items[desktop_choice][2]:break
   elif code in [KEY_ENTER,KEY_KP_ENTER] and desktop_choice>=0:
    if items[desktop_choice][2]:_desktop_run(items[desktop_choice][1])
   elif code==KEY_F11:_desktop_run("fullscreen")
   return true
  if desktop_pinned and code in [KEY_DOWN,KEY_ENTER,KEY_KP_ENTER]:
   desktop_menu="File";desktop_choice=-1;return true
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and desktop_mouse_down:
   desktop_mouse_down=false;return true
  if desktop_bar:
   var in_bar=event.position.y<DESKTOP_HEIGHT
   var menu_open=desktop_menu!=""
   if event.pressed and event.button_index==MOUSE_BUTTON_LEFT and (in_bar or menu_open):
    desktop_mouse_down=true
    # Use current geometry even when the mouse revealed the bar this frame.
    desktop_buttons=_desktop_targets()
    for button in desktop_buttons:
     if button["rect"].has_point(event.position):
      if button["enabled"]:
       var action=button["action"]
       if action.begins_with("desktop_menu:"):
        var name=action.get_slice(":",1)
        desktop_menu="" if desktop_menu==name else name
        desktop_choice=-1;desktop_pinned=false;_cancel_world_drag();pan=false
       else:_desktop_run(action)
      return true
    _desktop_dismiss();return true
   if in_bar or menu_open:return true
 return false

func _screen_size() -> Vector2:
 return get_viewport_rect().size

func _modal_offset() -> Vector2:
 return (_screen_size()-Vector2(1600,900))*.5

func _set_ui_offset(value:Vector2) -> void:
 ui_offset=value
 draw_set_transform(ui_offset)

func _version_badge() -> void:
 # A reserved footer keeps the release visible without covering any controls.
 draw_rect(Rect2(0,_screen_size().y-22,_screen_size().x,22),NAVY)
 var label="v%s  |  WINDOWS PLAYTEST" % ProjectSettings.get_setting("application/config/version")
 if sim.state.get("demo",false): label+="  |  DEMO / SEPARATE SAVE"
 if qa_ui: label+="  |  TEST PROFILE"
 _text(Vector2(18,_screen_size().y-6),label,16,CREAM)

func _panel(r:Rect2, color:Color=CREAM, border:Color=NAVY, radius:int=13) -> void:
 var box=StyleBoxFlat.new()
 box.bg_color=color
 box.border_color=border
 box.set_border_width_all(2)
 box.set_corner_radius_all(radius)
 box.shadow_size=4
 box.shadow_color=Color(0,0.04,0.10,0.18)
 box.shadow_offset=Vector2(0,3)
 draw_style_box(box,r)

func _text(p:Vector2, text:String, size:int=19, color:Color=INK, width:float=-1, heavy:bool=false) -> void:
 if record_modal_text: modal_accessible_text.append(text)
 var f=bold if heavy else font
 if color==GREEN: color=Color("137a47")
 if record_modal_text and not layout_in_button:
  var extent=f.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,size) if width>0 else f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size)
  layout_text.append({"rect":Rect2(p+ui_offset-Vector2(0,f.get_ascent(size)),extent),"text":text})
 if width>0: draw_multiline_string(f,p,text,HORIZONTAL_ALIGNMENT_LEFT,width,size,-1,color)
 else: draw_string(f,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _line(p:Vector2,text:String,size:int,color:Color,width:float,heavy:bool=false) -> void:
 if record_modal_text: modal_accessible_text.append(text)
 var f=bold if heavy else font
 if color==GREEN: color=Color("137a47")
 var shown=text.replace("\n"," / ")
 if f.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
  var low=0;var high=shown.length()
  while low<high:
   var mid=(low+high+1)/2
   if f.get_string_size(shown.left(mid)+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,size).x<=width: low=mid
   else: high=mid-1
  shown=shown.left(low)+"…"
 if record_modal_text and not layout_in_button:layout_text.append({"rect":Rect2(p+ui_offset-Vector2(0,f.get_ascent(size)),f.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,size)),"text":shown,"truncated":shown!=text.replace("\n"," / ")})
 draw_string(f,p,shown,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _button(r:Rect2, title:String, action:String, color:Color=CYAN, enabled:bool=true, size:int=18) -> void:
 var hovered=enabled and r.has_point(get_global_mouse_position()-ui_offset)
 _panel(r,color.lightened(0.12) if hovered else (color if enabled else Color("ccd4db")))
 var text_color=CREAM if color in [NAVY,BLUE,RED] else INK
 while size>11 and font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>r.size.x-12: size-=1
 var w=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
 layout_in_button=true
 _line(r.position+Vector2(maxf(6,(r.size.x-w)*0.5),r.size.y*0.5+size*0.36),title,size,text_color if enabled else INK,r.size.x-12)
 layout_in_button=false
 semantic_buttons.append({"rect":Rect2(r.position+ui_offset,r.size),"action":action,"label":title,"enabled":enabled})
 if enabled:
  buttons.append({"rect":Rect2(r.position+ui_offset,r.size),"action":action,"label":title})
  for control in accessible_buttons.values():
   if control.visible and control.has_focus() and control.position==r.position+ui_offset:
    draw_rect(r.grow(3),YELLOW,false,3);break

func _sync_shop_name_editor() -> void:
 if shop_name_edit!=null:
  var editor_visible=modal=="studio"
  if shop_name_edit.visible!=editor_visible:
   shop_name_edit.visible=editor_visible;shop_name_edit.queue_accessibility_update()
  shop_name_edit.position=Vector2(389,247)+_modal_offset();shop_name_edit.size=Vector2(610,42)

func _sync_accessibility() -> void:
 _sync_shop_name_editor()
 var seen={};var ordered=[];var occurrences={}
 var controls=semantic_buttons if not semantic_buttons.is_empty() else buttons
 for b in controls:
  var action=b["action"];var count=int(occurrences.get(action,0))+1;occurrences[action]=count
  var key=action if count==1 else action+"#"+str(count)
  seen[key]=true
  if not accessible_buttons.has(key):
   var control=Button.new()
   control.flat=true;control.focus_mode=Control.FOCUS_ALL
   control.mouse_filter=Control.MOUSE_FILTER_IGNORE
   control.self_modulate=Color(1,1,1,0)
   control.pressed.connect(_action.bind(action))
   add_child(control);accessible_buttons[key]=control
  var button:Button=accessible_buttons[key]
  # Text is custom-drawn. Keep the semantic control free of theme text minimums.
  var label=b.get("label",key.replace(":"," ").replace("_"," "))
  button.text="";button.position=b["rect"].position;button.size=b["rect"].size
  button.accessibility_name="Close dialog" if action=="close" and label=="X" else label
  if not button.visible:button.show();button.queue_accessibility_update()
  button.disabled=not b.get("enabled",true)
  if not button.disabled:ordered.append(button)
 for key in accessible_buttons:
  if not seen.has(key) and accessible_buttons[key].visible:
   accessible_buttons[key].hide();accessible_buttons[key].queue_accessibility_update()
 if shop_name_edit!=null and shop_name_edit.visible:ordered.append(shop_name_edit)
 ordered.sort_custom(func(a,b):return a.position.x<b.position.x if absf(a.position.y-b.position.y)<8 else a.position.y<b.position.y)
 for i in ordered.size():
  ordered[i].focus_next=ordered[i].get_path_to(ordered[(i+1)%ordered.size()]);ordered[i].focus_previous=ordered[i].get_path_to(ordered[posmod(i-1,ordered.size())])
 var context=screen+":"+modal+":"+str(workshop_page)+":"+str(photo_active)
 if not ordered.is_empty() and context!=accessibility_context:
  accessibility_context=context
  var focus=get_viewport().gui_get_focus_owner()
  if focus==null or not ordered.has(focus):ordered[0].grab_focus()
 if accessible_summary!=null:
  var clock_status="Clock held by desktop menu" if desktop_menu!="" else ("Clock paused" if sim.state["paused"] else ("Clock running" if modal in ["","order","machine","staff"] else "Clock held by menu"))
  accessible_summary.text="%s. %s. %s. Cash %d. %d open orders. %s" % [screen,modal,clock_status,sim.state["cash"],sim.active_orders().size(),sim.state["notices"][0]]
  if modal!="": accessible_summary.text+=". "+". ".join(modal_accessible_text)

func _diamond(p:Vector2, w:float, h:float, color:Color, border:Color=Color("947450")) -> void:
 _poly([p+Vector2(-w,0),p+Vector2(0,-h),p+Vector2(w,0),p+Vector2(0,h)],color,border,1.0)

func _poly(p:Array, color:Color, border:Color=INK, stroke:float=1.5) -> void:
 draw_colored_polygon(PackedVector2Array(p),color)
 if stroke>0: draw_polyline(PackedVector2Array(p+[p[0]]),border,stroke)

func _oval(p:Vector2, size:Vector2, color:Color) -> void:
 var points=[]
 for n in 28: points.append(p+Vector2(cos(n*TAU/28),sin(n*TAU/28))*size)
 draw_colored_polygon(PackedVector2Array(points),color)

func _sprite(index:int,p:Vector2,width:float, world:bool=true) -> void:
 var region=atlas_regions[index]
 var z=zoom if world else 1.0
 var size=Vector2(width,width*region.size.y/region.size.x)*z
 if not world and size.y>55: size*=55/size.y
 var anchor=Ground.atlas_origin(index,region) if world else Vector2(0.5,1.0)
 if world: _contact_shadow(p,size,anchor,Ground.atlas_contacts(index,region))
 draw_texture_rect(atlas_tiles[index],Ground.rect_at(p,size,anchor),false)

func _texture(texture:Texture2D,p:Vector2,width:float) -> void:
 var size=Vector2(width,width*float(texture.get_height())/texture.get_width())*zoom
 var kind="dtf" if texture==dtf_texture else "shaker"
 var anchor=Ground.texture_origin(kind)
 _contact_shadow(p,size,anchor,Ground.texture_contacts(kind),true)
 draw_set_transform(p,0,Vector2(-1,1))
 draw_texture_rect(texture,Rect2(-size*anchor,size),false)
 draw_set_transform(Vector2.ZERO)

func _contact_shadow(p:Vector2,size:Vector2,anchor:Vector2,contacts:Array,flipped:bool=false) -> void:
 var points=PackedVector2Array()
 for point in contacts: points.append(Ground.point_at(p,size,anchor,point,flipped))
 # The floor shadow follows the support polygon, and every visible leg/wheel
 # touches its own compact contact shadow. No detached bottom-center oval.
 if points.size()>2:
  var hull=Geometry2D.convex_hull(points)
  draw_colored_polygon(hull,Color(0.10,0.07,0.03,0.13))
 for point in points:
  _oval(point,Vector2(7.0,3.0)*zoom,Color(0.07,0.045,0.02,0.27))

func _isolated_sprite(img:Image) -> Image:
 # The atlas includes tiny disconnected fragments from neighboring cells.
 # Keep the connected equipment silhouette; do not render those as floor debris.
 img.convert(Image.FORMAT_RGBA8)
 var bytes=img.get_data()
 var width=img.get_width()
 var height=img.get_height()
 var visited=PackedByteArray()
 visited.resize(width*height)
 var seed=int(height/2)*width+int(width/2)
 if bytes[seed*4+3]<32:
  var nearest=INF
  for i in width*height:
   if bytes[i*4+3]<32: continue
   var distance=Vector2(i%width,int(i/width)).distance_squared_to(Vector2(width/2.0,height/2.0))
   if distance<nearest: nearest=distance; seed=i
 var queue=PackedInt32Array([seed])
 visited[seed]=1
 var head=0
 while head<queue.size():
  var current=queue[head]; head+=1
  var x=current%width
  for next in [current-1 if x>0 else -1,current+1 if x<width-1 else -1,current-width,current+width]:
   if next<0 or next>=visited.size() or visited[next] or bytes[next*4+3]<32: continue
   visited[next]=1; queue.append(next)
 for i in visited.size():
  if not visited[i]: bytes[i*4+3]=0
 return Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes)

func _trim_texture(texture:Texture2D) -> Texture2D:
 var t=AtlasTexture.new()
 t.atlas=texture
 t.region=texture.get_image().get_used_rect()
 return t

func _world() -> void:
 draw_rect(Rect2(Vector2.ZERO,_screen_size()),Color("c5cfc1"))
 var style=sim.state.get("style",{})
 var image_path=style.get("floor_image","") if not (photo_render or photo_active) or photo_imported else ""
 if floor_texture_path!=image_path:
  floor_texture_path=image_path;floor_texture=null
  if image_path.begins_with(OS.get_user_data_dir().path_join("custom-floors/")) and FileAccess.file_exists(image_path):
   var image=Image.load_from_file(image_path)
   if image!=null:floor_texture=ImageTexture.create_from_image(image)
 var size=sim.bounds()
 var high=155*zoom
 var a=iso(Vector2(-0.5,-0.5))
 var b=iso(Vector2(-0.5,size.y-0.5))
 var c=iso(Vector2(size.x-0.5,-0.5))
 var wall=Vector2(0,-high)
 var place=sim.premises()
 var room=ROOMS[place]
 _poly([a,b,b+wall,a+wall],Color(room["left"]),Color("70685d"),2)
 _poly([a,c,c+wall,a+wall],Color(room["back"]),Color("70685d"),2)
 var exterior=Vector2(-11,-5)*zoom
 _poly([b,b+wall,b+wall+exterior,b+exterior],Color("a7ac9f"),Color("606e68"),2)
 var entrance_y=float(sim.entrance().y)
 if place=="garage": _garage_wall(entrance_y,wall)
 else:
  # Three generous windows, separated by solid wall, rather than one per tile.
  for n in 3:
   var along=lerpf(1.35,entrance_y-2.0,float(n)/2.0)
   var p=iso(Vector2(-0.5,along))
   var half=Vector2(-50.4,24.15)*zoom
   _poly([p+half+wall*.22,p-half+wall*.22,p-half+wall*.91,p+half+wall*.91],Color("365767"),INK,2)
   _poly([p+half*.9+wall*.27,p-half*.9+wall*.27,p-half*.9+wall*.86,p+half*.9+wall*.86],Color("b4e9f1"),Color("5a8492"),1)
   draw_line(p+wall*.27,p+wall*.86,Color("4a7f8d"),3*zoom)
   draw_line(p+half*.72+wall*.32,p+half*.72+wall*.8,Color("e1faff"),2*zoom)
  var door=iso(Vector2(-0.5,entrance_y))
  var door_half=Vector2(-21.6,10.35)*zoom
  _poly([door+door_half,door-door_half,door-door_half+wall*.93,door+door_half+wall*.93],Color("224660"),INK,2)
  _poly([door+door_half*.8+Vector2(0,-8)*zoom,door-door_half*.8+Vector2(0,-8)*zoom,door-door_half*.8+wall*.87,door+door_half*.8+wall*.87],Color("a1def0"),Color("4a9eaf"),2)
  _panel(Rect2(door+Vector2(-22,-94)*zoom,Vector2(46,27)*zoom),RED)
  _text(door+Vector2(-19,-76)*zoom,"OPEN",int(14*zoom),CREAM)
 _loading_yard(size)
 for x in size.x:
  for y in size.y:
   var p=iso(Vector2(x,y))
   var color=Color(room["floor"])
   if Style.FLOORS.get(style.get("floor","Original"),"")!="":color=Color(Style.FLOORS[style["floor"]])
   color=color.lightened(float((x*13+y*7)%7)*0.013)
   _diamond(p,48*zoom,23*zoom,color,Color(room["edge"]))
   if floor_texture!=null:
    draw_polygon(PackedVector2Array([p+Vector2(0,-23)*zoom,p+Vector2(48,0)*zoom,p+Vector2(0,23)*zoom,p+Vector2(-48,0)*zoom]),PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),floor_texture)
   if room["pattern"]=="wood" and floor_texture==null:
    for k in 2:
     var line=p+Vector2(-25+k*20,3)*zoom
     draw_line(line,line+Vector2(28,13)*zoom,Color(0.63,0.36,0.14,0.12),1)
   elif place!="garage" and (y in [1,7,12] or x==12):
    draw_line(p+Vector2(-43,0)*zoom,p+Vector2(0,20)*zoom,YELLOW,3*zoom)
   if build: _diamond(p,48*zoom,23*zoom,Color(0.0,0.5,0.9,0.07),Color(0.1,0.6,0.8,0.35))
 _poly([b,c,iso(Vector2(size.x-0.5,size.y-0.5))],Color(0,0,0,0),Color(0,0,0,0),0)
 _outer_wall(size)
 var sign_x=0.7 if place=="garage" else 4.0
 if place=="garage":
  # Daylight spilling in from the open door, and an old oil stain on the concrete.
  var spill=iso(Vector2(0,entrance_y))
  _poly([spill+Vector2(-48,-46)*zoom,spill+Vector2(140,46)*zoom,spill+Vector2(60,92)*zoom,spill+Vector2(-130,0)*zoom],Color(1,0.97,0.78,0.13),Color.TRANSPARENT,0)
  _oval(iso(Vector2(6.3,6.4)),Vector2(34,13)*zoom,Color(0.16,0.17,0.2,0.09))
  _oval(iso(Vector2(6.6,6.2)),Vector2(15,6)*zoom,Color(0.16,0.17,0.2,0.08))
  _pegboard(6.6,wall)
 else:
  # Warm floor light and cast window reflections stay behind equipment.
  for n in [2,5,8]:
   var p=iso(Vector2(0,n))
   _poly([p,p+Vector2(92,44)*zoom,p+Vector2(139,22)*zoom,p+Vector2(47,-22)*zoom],Color(1,0.95,0.69,0.11),Color.TRANSPARENT,0)
  _poster(iso(Vector2(size.x-3,-0.5)),["GOOD","PRINTS","HAPPIER","PEOPLE"],[MAGENTA,BLUE,BLUE,GREEN],false)
  if place=="factory":
   # The factory's back wall has loading-dock doors for outgoing pallets.
   for dock_x in [9.5,13.5]: _dock_door(dock_x,wall)
 if sim.state.get("style",{}).get("shop_name","My Print Shop")!="My Print Shop":_poster(iso(Vector2(sign_x,-0.5)),Style.sign_lines(sim),[BLUE,BLUE,MAGENTA,BLUE],true)
 else:_poster(iso(Vector2(sign_x,-0.5)),["PRINT","MORE","GROW","BIGGER"],[BLUE,BLUE,MAGENTA,BLUE],true)
 var items=[]
 for id in _render_machines():
  var m=_render_machines()[id]
  var pos=sim.equipment_center(id,_render_machines())
  var depth=pos.x+pos.y+0.3
  if m["kind"]=="shaker":
   var printer="dtf2" if id=="shaker2" else "dtf"
   var pm=_render_machines()[printer]
   var rear=_equipment_position(printer)+(sim.v(pm["size"])-Vector2.ONE)*0.5
   depth=maxf(depth,rear.x+rear.y+0.3)
  items.append({"kind":"machine","id":id,"depth":depth})
 for prop in sim.room_props():
  var p=Vector2(prop["pos"])
  items.append({"kind":prop["kind"],"pos":p,"depth":p.x+p.y})
 for decor in sim.state.get("style",{}).get("decor",[]):items.append({"kind":"decor","item":decor,"depth":decor["pos"][0]+decor["pos"][1]+.2})
 for w in sim.state["workers"]: items.append({"kind":"worker","id":w["id"],"depth":w["pos"][0]+w["pos"][1]+0.4})
 for actor in sim.visible_customers(): items.append({"kind":"customer","actor":actor,"depth":actor["pos"][0]+actor["pos"][1]+0.4})
 # The loading door frame and the parked truck sit on the outside wall line.
 if _yard_depth()>0:
  var bay=_dock_span()
  if not bay.is_empty():
   items.append({"kind":"door_frame","depth":float(size.x)-0.5+float(bay["y1"])+0.05})
   items.append({"kind":"truck","pos":Vector2(float(size.x)+1.9,float(bay["mid"])),"depth":float(size.x)+1.9+float(bay["mid"])})
 items.sort_custom(func(i,j): return i["depth"]<j["depth"])
 if not (photo_render or photo_active):_film_paths()
 for item in items:
  match item["kind"]:
   "machine":
    _machine(item["id"])
    _draw_unboxing(item["id"])
    var machine=sim.state["machines"].get(item["id"],{})
    if machine.has("service_work"):
     world_labels.append({"at":iso(sim.equipment_center(item["id"],sim.state["machines"])),"text":"Service / "+str(machine["phase"]),"progress":1.0-float(machine["service_work"]["remaining"])/12.0})
   "decor": Style.draw_decor(self,item["item"])
   "worker": _worker(item["id"])
   "customer": _customer(item["actor"])
   "rack": _illustrated_prop("storage",iso(item["pos"]))
   "plant": _sprite(8,iso(item["pos"]),63)
   "door_frame": _door_frame(size)
   "truck": _truck(iso(item["pos"]))
 # The pendants hang from a visible ceiling beam at the cutaway roof edge.
 draw_line(a+wall,c+wall,Color("354451"),7*zoom)
 draw_line(a+wall+Vector2(0,-3)*zoom,c+wall+Vector2(0,-3)*zoom,Color("7a8b93"),2*zoom)
 for x in ([4.5,8.9] if place=="garage" else [1.0,7.0,float(size.x)-.8]):
  _pendant(iso(Vector2(x,-0.5))+wall)

# Wall and floor colours for each step of the premises ladder.
const ROOMS={
 "garage":{"left":"d8d1c1","back":"cec6b5","floor":"bdbab2","edge":"a5a299","pattern":"concrete"},
 "storefront":{"left":"e7d7b9","back":"f2dfbb","floor":"e6b574","edge":"c99b69","pattern":"wood"},
 "warehouse":{"left":"e7d7b9","back":"c4ccd0","floor":"aab2b7","edge":"909ba3","pattern":"lines"},
 "factory":{"left":"dde3e7","back":"b6c2ca","floor":"a2acb4","edge":"88949d","pattern":"lines"}}

# The home garage's side wall: a roll-up door standing open onto the driveway
# (customers walk in through it), a small window and a hand-painted OPEN sign.
func _garage_wall(entrance_y:float,wall:Vector2) -> void:
 var p=iso(Vector2(-0.5,entrance_y))
 var half=Vector2(-48,23)*1.5*zoom
 _poly([p+half,p-half,p-half+wall*.9,p+half+wall*.9],Color("59636d"),INK,2)
 var inner=half*.93
 _poly([p+inner+wall*.34,p-inner+wall*.34,p-inner+wall*.84,p+inner+wall*.84],Color("bfe8f7"),Color.TRANSPARENT,0)
 _poly([p+inner+wall*.22,p-inner+wall*.22,p-inner+wall*.36,p+inner+wall*.36],Color("7dbb6b"),Color.TRANSPARENT,0)
 _poly([p+inner,p-inner,p-inner+wall*.23,p+inner+wall*.23],Color("cfcdc5"),Color.TRANSPARENT,0)
 # The rolled-up door sits in the top of the frame.
 _poly([p+inner+wall*.70,p-inner+wall*.70,p-inner+wall*.86,p+inner+wall*.86],Color("e3e7ea"),Color("7c8790"),1)
 for k in 3: draw_line(p+inner+wall*(.74+k*.04),p-inner+wall*(.74+k*.04),Color("aab4bb"),1.5*zoom)
 draw_line(p+inner+wall*.70,p-inner+wall*.70,Color("4b5560"),3*zoom)
 var w=iso(Vector2(-0.5,entrance_y+2.9))
 var wh=Vector2(-48,23)*.55*zoom
 _poly([w+wh+wall*.42,w-wh+wall*.42,w-wh+wall*.8,w+wh+wall*.8],Color("365767"),INK,2)
 _poly([w+wh*.82+wall*.46,w-wh*.82+wall*.46,w-wh*.82+wall*.76,w+wh*.82+wall*.76],Color("b4e9f1"),Color("5a8492"),1)
 var sign=iso(Vector2(-0.5,entrance_y-2.15))
 _panel(Rect2(sign+Vector2(-23,-104)*zoom,Vector2(46,27)*zoom),RED)
 _text(sign+Vector2(-20,-86)*zoom,"OPEN",int(14*zoom),CREAM)

# A closed roll-up loading door on the factory's back wall, with hazard stripes.
func _dock_door(x:float,wall:Vector2) -> void:
 var p=iso(Vector2(x,-0.5))
 var half=Vector2(48,23)*1.25*zoom
 _poly([p-half,p+half,p+half+wall*.78,p-half+wall*.78],Color("4c5863"),INK,2)
 var inner=half*.9
 _poly([p-inner+wall*.02,p+inner+wall*.02,p+inner+wall*.72,p-inner+wall*.72],Color("d5dade"),Color("7c8790"),1)
 for k in 7: draw_line(p-inner+wall*(.10+k*.09),p+inner+wall*(.10+k*.09),Color("a7b1b8"),1.5*zoom)
 for k in 6:
  var from=(p-inner).lerp(p+inner,k/6.0)
  var to=(p-inner).lerp(p+inner,(k+.5)/6.0)
  _poly([from+wall*.02,to+wall*.02,to+wall*.07,from+wall*.07],YELLOW,Color.TRANSPARENT,0)

# The garage's back wall: a pegboard of tools over a shelf of paint and vinyl.
func _pegboard(x:float,wall:Vector2) -> void:
 var p=iso(Vector2(x,-0.5))
 var half=Vector2(48,23)*1.2*zoom
 _poly([p-half+wall*.40,p+half+wall*.40,p+half+wall*.84,p-half+wall*.84],Color("c9a36b"),Color("7a5a33"),2)
 for k in 5:
  var at=p-half*.8+half*1.6*(k/4.0)
  draw_line(at+wall*.76,at+wall*(.54-.04*(k%2)),[Color("4b5560"),RED,Color("4b5560"),BLUE,Color("4b5560")][k],3*zoom)
  draw_circle(at+wall*.78,3*zoom,Color("3a2a18"))
 var shelf_a=p-half+wall*.30
 var shelf_b=p+half+wall*.30
 draw_line(shelf_a,shelf_b,Color("7a5a33"),5*zoom)
 for k in 4:
  var at=shelf_a.lerp(shelf_b,.14+k*.24)
  var can=Rect2(at+Vector2(-7,-18)*zoom,Vector2(14,15)*zoom)
  draw_rect(can,[CYAN,MAGENTA,YELLOW,Color("e9edf0")][k])
  draw_rect(can,INK,false,1.2)

# Frame of the truck sheet that shows it backed up, cab facing away from the door.
const TRUCK_FRAME=2

# The warehouse and factory have an outdoor loading yard beyond the right wall.
func _yard_depth() -> int:
 return 5 if int(sim.state["location"])==2 else 0

# Rows of the right wall covered by the shipping dock's loading bay, if any.
func _dock_span() -> Dictionary:
 var ms=_render_machines()
 if not ms.has("dock"): return {}
 var low=INF;var high=-INF
 for p in sim.footprint("dock",ms):
  low=minf(low,float(p.y));high=maxf(high,float(p.y))
 return {"y0":low-0.5,"y1":high+0.5,"mid":(low+high)*0.5}

func _loading_yard(size:Vector2i) -> void:
 var depth=_yard_depth()
 if depth<=0: return
 var x0=float(size.x)-0.5;var x1=x0+depth
 var y0=-0.5;var y1=float(size.y)-0.5
 # Asphalt lot with a concrete apron along the building.
 _poly([iso(Vector2(x0,y0)),iso(Vector2(x1,y0)),iso(Vector2(x1,y1)),iso(Vector2(x0,y1))],Color("8b9297"),Color("6c7378"),2)
 _poly([iso(Vector2(x0,y0)),iso(Vector2(x0+0.9,y0)),iso(Vector2(x0+0.9,y1)),iso(Vector2(x0,y1))],Color("b9bcb8"),Color.TRANSPARENT,0)
 for k in 3:
  var cx=x0+1.6+k*1.55
  var cy=y0+1.3+k*3.6
  _oval(iso(Vector2(cx,cy)),Vector2(26,9)*zoom,Color(0.2,0.22,0.25,0.08))
 # Parking stripes running out from the wall.
 var y=y0+0.8
 while y<y1-0.4:
  draw_line(iso(Vector2(x0+1.2,y)),iso(Vector2(x1-0.6,y)),Color(1,1,1,0.55),2*zoom)
  y+=3.0
 # A low fence and a planter strip at the far edge of the lot.
 _poly([iso(Vector2(x1-0.45,y0)),iso(Vector2(x1,y0)),iso(Vector2(x1,y1)),iso(Vector2(x1-0.45,y1))],Color("8fbf73"),Color("6f9a59"),1)
 var post=Vector2(0,-30)*zoom
 for k in int(size.y)+1:
  var p=iso(Vector2(x1-0.2,y0+k*(y1-y0)/float(size.y)))
  draw_line(p,p+post,Color("5d666d"),2*zoom)
 draw_line(iso(Vector2(x1-0.2,y0))+post,iso(Vector2(x1-0.2,y1))+post,Color("5d666d"),2*zoom)
 draw_line(iso(Vector2(x1-0.2,y0))+post*0.55,iso(Vector2(x1-0.2,y1))+post*0.55,Color("7d868d"),1.5*zoom)
 # The truck's marked bay outside the loading door.
 var bay=_dock_span()
 if not bay.is_empty():
  var bx0=x0+0.25;var bx1=x0+3.6
  var a=float(bay["y0"])-0.15;var b=float(bay["y1"])+0.15
  var corners=[iso(Vector2(bx0,a)),iso(Vector2(bx1,a)),iso(Vector2(bx1,b)),iso(Vector2(bx0,b))]
  for k in 4: draw_line(corners[k],corners[(k+1)%4],YELLOW,3*zoom)

# The building's front-right wall is shown cut away to knee height so the
# shop stays visible; the loading door is a gap in it.
func _outer_wall(size:Vector2i) -> void:
 if _yard_depth()<=0: return
 var x=float(size.x)-0.5
 var low=Vector2(0,-22)*zoom
 var thick=Vector2(10,5)*zoom
 var spans=[[-0.5,float(size.y)-0.5]]
 var bay=_dock_span()
 if not bay.is_empty(): spans=[[-0.5,float(bay["y0"])],[float(bay["y1"]),float(size.y)-0.5]]
 for span in spans:
  if float(span[1])-float(span[0])<0.05: continue
  var a=iso(Vector2(x,float(span[0])));var b=iso(Vector2(x,float(span[1])))
  _poly([a,b,b+low,a+low],Color("c9cfd3"),Color("70685d"),1.5)
  _poly([a+low,b+low,b+low+thick,a+low+thick],Color("e3e7ea"),Color("70685d"),1.5)

# The open roll-up door: two posts, the rolled door drum and a striped threshold.
func _door_frame(size:Vector2i) -> void:
 var bay=_dock_span()
 if bay.is_empty(): return
 var x=float(size.x)-0.5
 var a=iso(Vector2(x,float(bay["y0"])));var b=iso(Vector2(x,float(bay["y1"])))
 var tall=Vector2(0,-118)*zoom
 for k in 6:
  var from=a.lerp(b,k/6.0);var to=a.lerp(b,(k+.5)/6.0)
  _poly([from,to,to+Vector2(0,-5)*zoom,from+Vector2(0,-5)*zoom],YELLOW,Color.TRANSPARENT,0)
 for p in [a,b]:
  _poly([p+Vector2(-5,0)*zoom,p+Vector2(5,0)*zoom,p+Vector2(5,0)*zoom+tall,p+Vector2(-5,0)*zoom+tall],Color("4b5560"),INK,1.5)
 _poly([a+tall+Vector2(-6,0)*zoom,b+tall+Vector2(6,0)*zoom,b+tall+Vector2(6,-16)*zoom,a+tall+Vector2(-6,-16)*zoom],Color("d5dade"),INK,1.5)
 for k in 2: draw_line(a+tall+Vector2(0,-5-k*5)*zoom,b+tall+Vector2(0,-5-k*5)*zoom,Color("9aa5ad"),1.5*zoom)
 _panel(Rect2(a.lerp(b,0.5)+tall+Vector2(-30,-38)*zoom,Vector2(60,18)*zoom),NAVY,CREAM,4)
 _text(a.lerp(b,0.5)+tall+Vector2(-25,-24)*zoom,"LOADING",int(11*zoom),YELLOW)

# The delivery truck parked outside, backed up to the loading door.
func _truck(p:Vector2) -> void:
 if not illustrated.has("dock"): return
 var frame=TRUCK_FRAME
 var info=illustrated_info["dock"]["frames"][frame]
 var rect=Ground.rect_at(p,Vector2(info["size"][0],info["size"][1])*zoom*1.05,Vector2(info["origin"][0],info["origin"][1]))
 _oval(p+Vector2(0,4)*zoom,Vector2(70,26)*zoom,Color(0.1,0.12,0.15,0.18))
 draw_texture_rect(illustrated["dock"][frame],rect,false)

# Inside, the dock is a loading bay: hatched floor and pallets of boxed orders.
func _loading_bay(target:String,ms:Dictionary) -> Rect2:
 var center=sim.equipment_center(target,ms)
 var polygon=sim.equipment_polygon(target,ms)
 var points=[]
 for point in polygon: points.append(iso(point))
 _poly(points,Color("d9d4c4"),YELLOW,3*zoom)
 var low=INF;var high=-INF
 for point in points: low=minf(low,point.y);high=maxf(high,point.y)
 for k in 4:
  var t=(k+1)/5.0
  draw_line(iso(center+Vector2(-0.8,-1.3+t*2.6)),iso(center+Vector2(0.8,-1.3+t*2.6)),Color(0.95,0.75,0.1,0.35),2*zoom)
 var top=0.0
 for spot in [Vector2(-0.3,-0.7),Vector2(-0.3,0.7)]:
  var base=iso(center+spot)
  _poly([base+Vector2(-30,0)*zoom,base+Vector2(0,-14)*zoom,base+Vector2(30,0)*zoom,base+Vector2(0,14)*zoom],Color("b8874f"),Color("6e4b25"),1.5)
  for level in 2:
   var lift=Vector2(0,-8-level*22)*zoom
   var w=Vector2(22,10)*zoom;var h=Vector2(0,-20)*zoom
   var c=base+lift
   _poly([c-Vector2(w.x,0),c+Vector2(0,w.y),c+Vector2(0,w.y)+h,c-Vector2(w.x,0)+h],Color("c9955a"),Color("6e4b25"),1.2)
   _poly([c+Vector2(0,w.y),c+Vector2(w.x,0),c+Vector2(w.x,0)+h,c+Vector2(0,w.y)+h],Color("b07c45"),Color("6e4b25"),1.2)
   _poly([c-Vector2(w.x,0)+h,c+Vector2(0,-w.y)+h,c+Vector2(w.x,0)+h,c+Vector2(0,w.y)+h],Color("dcb07a"),Color("6e4b25"),1.2)
   draw_line(c+h+Vector2(-w.x*.5,-w.y*.5),c+h+Vector2(w.x*.5,w.y*.5),Color("e8d29e"),3*zoom)
   top=minf(top,(c+h).y)
 return Rect2(Vector2(points[0].x,low),Vector2(1,1)).merge(Rect2(points[2],Vector2(1,1))).merge(Rect2(Vector2(points[1].x,top),Vector2(1,high-top))).merge(Rect2(Vector2(points[3].x,top),Vector2(1,high-top)))

func _pendant(p:Vector2) -> void:
 var z=zoom
 _oval(p,Vector2(7,3)*z,Color("293440"))
 draw_line(p,p+Vector2(0,25)*z,Color("1a2531"),2.5*z)
 _poly([p+Vector2(-5,23)*z,p+Vector2(5,23)*z,p+Vector2(10,28)*z,p+Vector2(15,36)*z,p+Vector2(18,43)*z,p+Vector2(-18,43)*z,p+Vector2(-15,36)*z,p+Vector2(-10,28)*z],Color("253440"),Color("111e2d"),1.5*z)
 draw_line(p+Vector2(-8,29)*z,p+Vector2(-13,38)*z,Color("526775"),2*z)
 _oval(p+Vector2(0,43)*z,Vector2(19,6)*z,Color("14202b"))
 _oval(p+Vector2(0,44)*z,Vector2(15,4)*z,Color("ffd66a"))
 _oval(p+Vector2(0,44)*z,Vector2(10,2)*z,Color("fff4ca"))

func _poster(p:Vector2,lines:Array,colors:Array,heart:bool) -> void:
 # Match the wall's horizontal slope. Text and frame share one local canvas,
 # so the lettering stays centered, inside the border, and flush to the wall.
 var across=Vector2(1.0,23.0/48.0)
 draw_set_transform_matrix(Transform2D(across*zoom,Vector2(0,zoom),p-(across*50+Vector2(0,139))*zoom))
 draw_rect(Rect2(3,3,100,122),Color(0.18,.12,.06,.12))
 draw_rect(Rect2(0,0,100,122),Color("fffdf4"))
 draw_rect(Rect2(0,0,100,122),Color("bd9970"),false,2)
 draw_rect(Rect2(5,5,90,112),Color("e9d7bd"),false,1)
 for n in lines.size():
  var font_size=22
  while bold.get_string_size(lines[n],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>78:font_size-=1
  var width=bold.get_string_size(lines[n],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
  draw_string(bold,Vector2((100-width)*.5,23+n*21),lines[n],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,colors[n])
 if heart:
  draw_circle(Vector2(45,102),6,MAGENTA);draw_circle(Vector2(55,102),6,MAGENTA)
  _poly([Vector2(39,103),Vector2(61,103),Vector2(50,116)],MAGENTA,Color.TRANSPARENT,0)
 else:
  draw_circle(Vector2(50,105),11,YELLOW)
  draw_circle(Vector2(46,102),1.4,INK);draw_circle(Vector2(54,102),1.4,INK)
  draw_arc(Vector2(50,105),5,0,PI,16,INK,1.5)
 draw_set_transform_matrix(Transform2D.IDENTITY)

func _film_paths() -> void:
 # The supplied combined sprite already contains the connected printed film.
 if dtf_line_texture!=null: return
 for id in ["dtf","dtf2"]:
  if not sim.state["machines"].has(id): continue
  var shake="shaker2" if id=="dtf2" else "shaker"
  var a=_equipment_port(id,Ground.PRINTER_OUTLET)
  var b=_equipment_port(shake,Ground.SHAKER_INLET)
  var half_roll=Vector2(72.5,30.25)*zoom
  _poly([a-half_roll,a+half_roll,b+half_roll,b-half_roll],Color("fffbf1"),Color("c7c5b4"),1)
  if sim.state["machines"][id]["active"]>=0:
   for n in 3:
    var point=a.lerp(b,fmod(time*0.35+n*0.33,1.0))
    _product("transfer",point,16*zoom)

func _equipment_position(id:String) -> Vector2:
 # This helper describes installed equipment; attempted previews use _render_machines.
 # Keep the authoritative position stable even while a rejected preview is shown.
 return sim.v(sim.state["machines"][id]["pos"]) if sim.state["machines"].has(id) else sim.v(_render_machines()[id]["pos"])

func _equipment_width(kind:String) -> float:
 match kind:
  "dtf","banner": return 235.0
  # Both Blender images need the same pixels-to-world scale. A deeper cabinet
  # has a wider projected crop even though its physical print width is equal.
  "shaker": return 235.0*588.0/462.0
  "cnc": return 330.0
  "dock": return 215.0
  "art","finish": return 130.0
  "storage": return 125.0
 return 200.0

func _equipment_port(id:String,point:Vector2) -> Vector2:
 var m=sim.state["machines"][id]
 var center=_equipment_position(id)+Vector2((float(m["size"][0])-1)*0.5,(float(m["size"][1])-1)*0.5)
 var texture=dtf_texture if m["kind"]=="dtf" else shaker_texture
 var width=_equipment_width(m["kind"])
 var size=Vector2(width,width*float(texture.get_height())/texture.get_width())*zoom
 return Ground.point_at(iso(center),size,Ground.texture_origin(m["kind"]),point,true)

func _machine(id:String) -> void:
 var m=_render_machines()[id]
 if not illustrated.is_empty():
  _illustrated_machine(id)
  return
 if m["kind"] in ["dtf","shaker"] and dtf_line_texture!=null:
  _approved_dtf_line(id)
  return
 var position=_equipment_position(id)
 var center=position+Vector2((float(m["size"][0])-1)*0.5,(float(m["size"][1])-1)*0.5)
 var p=iso(center)
 var width=_equipment_width(m["kind"])
 if build:
  var valid=true
  if _relocating() and drag_id==id: valid=drag_valid.get("valid",false)
  for x in int(m["size"][0]):
   for y in int(m["size"][1]): _diamond(iso(position+Vector2(x,y)),48*zoom,23*zoom,Color(0.2,0.9,0.5,0.45) if valid else Color(1,0.2,0.3,0.5))
  _diamond(iso(Vector2(sim.service(id))+position-sim.v(m["pos"])),30*zoom,14*zoom,Color(0.1,0.8,1,0.6))
 if m["kind"]=="dtf" and dtf_texture!=null: _texture(dtf_texture,p,width)
 elif m["kind"]=="shaker" and shaker_texture!=null: _texture(shaker_texture,p,width)
 elif m["kind"] in ["dtf","shaker"]: _equipment_geometry(m["kind"],p,width)
 else: _sprite(int(m["sprite"]),p,width)
 var img:Image=machine_images.get(int(m["sprite"]))
 var height=width*float(img.get_height())/img.get_width() if img!=null else width*0.8
 var anchored=m["kind"] in ["dtf","shaker"]
 var anchor=Ground.texture_origin(m["kind"]) if anchored else Ground.atlas_origin(int(m["sprite"]),atlas_regions[int(m["sprite"])])
 var rect=Ground.rect_at(p,Vector2(width,height)*zoom,anchor,anchored)
 world_hits.append({"id":id,"rect":rect,"sprite":int(m["sprite"]),"flip":m["kind"] in ["dtf","shaker"]})
 if not (photo_render or photo_active) and m["active"]>=0:
  var progress=sim.machine_progress(id)
  world_labels.append({"at":p,"text":m["phase"],"progress":progress})
  var kind=m["kind"]
  if kind in ["dtf","sticker"]:
   var head=p+Vector2(lerpf(-47,47,(sin(time*3)+1)*0.5),-76 if kind!="cnc" else -83)*zoom
   _panel(Rect2(head,Vector2(18,10)*zoom),CREAM,NAVY,2)
  if kind=="cnc":
   var across=Vector2(73,35)*zoom
   var head=p+Vector2(lerpf(-80,24,(sin(time*1.7)+1)*0.5),-88)*zoom
   draw_line(head-across,head+across,Color("d6dde6"),13*zoom)
   draw_line(head-across,head+across,NAVY,3*zoom)
   _panel(Rect2(head+Vector2(sin(time*4)*47,0)*zoom,Vector2(22,25)*zoom),CREAM,NAVY,2)
  if kind=="dtf":
   var shake="shaker2" if id=="dtf2" else "shaker"
   var roll=iso(sim.v(sim.state["machines"][shake]["pos"])+Vector2(1,1))+Vector2(-51,-14)*zoom
   draw_arc(roll,7*zoom,time*4,time*4+4.3,16,Color("8c9ca8"),2*zoom)
  if kind=="banner": _product("banner",p+Vector2(0,-30)*zoom,30*zoom)
 elif not (photo_render or photo_active) and not build and m["kind"] not in ["shaker","storage"]:
  var waiting=-1
  for oi in sim.active_orders():
   var job=sim.order(oi)
   if job.get("output_machine","")==id and job["stage"] in ["press","qc","pack","ready"]:
    waiting=oi; break
  if waiting>=0:
   var r=Rect2(p+Vector2(45,-27)*zoom,Vector2(38,38)*zoom)
   _panel(r,YELLOW,NAVY,8)
   _product(sim.order(waiting)["type"],r.get_center(),25*zoom)
   output_hits.append({"rect":r,"order":waiting})

func _approved_dtf_line(id:String) -> void:
 var machines=_render_machines()
 var m=machines[id]
 var position=_equipment_position(id)
 if build:
  var valid=drag_valid.get("valid",false) if _relocating() and drag_id==id else true
  for x in int(m["size"][0]):
   for y in int(m["size"][1]): _diamond(iso(position+Vector2(x,y)),48*zoom,23*zoom,Color(0.2,0.9,0.5,0.45) if valid else Color(1,0.2,0.3,0.5))
  _diamond(iso(Vector2(sim.service(id))+position-sim.v(m["pos"])),30*zoom,14*zoom,Color(0.1,0.8,1,0.6))
 # Draw each pair once, at the foreground cabinet's depth. In build mode
 # either visual component selects its printer, so the complete line moves.
 if m["kind"]=="dtf": return
 var printer="dtf2" if id=="shaker2" else "dtf"
 var rear=_equipment_position(printer)+(sim.v(machines[printer]["size"])-Vector2.ONE)*0.5
 var front=position+(sim.v(m["size"])-Vector2.ONE)*0.5
 var p=iso((rear+front)*0.5)
 var rotation=posmod(int(machines[printer]["rotation"]),4)
 var texture:Texture2D=[dtf_views[0],dtf_views[2],dtf_views[4],dtf_views[1]][rotation]
 var anchor=[DTF_LINE_ORIGIN,Vector2(.55,.862),Vector2(.5,.84),Vector2(.52,.883)][rotation]
 var flip=rotation==0
 var size=Vector2(330,330.0*texture.get_height()/texture.get_width())*zoom
 var contacts=[DTF_LINE_CONTACTS,[Vector2(.25,.844),Vector2(.56,.855),Vector2(.647,.884),Vector2(.93,.884),Vector2(.06,.875)],[Vector2(.145,.724),Vector2(.841,.724),Vector2(.269,.962),Vector2(.725,.962)],[Vector2(.067,.886),Vector2(.363,.886),Vector2(.46,.873),Vector2(.78,.873),Vector2(.95,.89)]][rotation]
 _contact_shadow(p,size,Vector2(1.0-anchor.x,anchor.y) if flip else anchor,contacts.map(func(q): return Vector2(1.0-q.x,q.y) if flip else q))
 draw_set_transform(p,0,Vector2(-1,1) if flip else Vector2.ONE)
 draw_texture_rect(texture,Rect2(-size*anchor,size),false)
 draw_set_transform(Vector2.ZERO)
 var rect=Ground.rect_at(p,size,anchor,flip)
 world_hits.append({"id":id,"printer":printer,"rect":rect,"sprite":12+rotation,"flip":flip})
 var active=sim.state["machines"][printer]
 if not (photo_render or photo_active) and active["active"]>=0:
  var progress=sim.machine_progress(printer)
  world_labels.append({"at":p,"text":active["phase"],"progress":progress})
 elif not (photo_render or photo_active) and not build:
  for oi in sim.active_orders():
   var job=sim.order(oi)
   if job.get("output_machine","")==printer and job["stage"] in ["press","qc","pack","ready"]:
    var r=Rect2(p+Vector2(78,-10)*zoom,Vector2(38,38)*zoom)
    _panel(r,YELLOW,NAVY,8)
    _product(job["type"],r.get_center(),25*zoom)
    output_hits.append({"rect":r,"order":oi})
    break

func _station_hover_label() -> void:
 var mouse=get_global_mouse_position()
 if not SHOP_VIEW.has_point(mouse): return
 for button in buttons:
  if button["rect"].has_point(mouse): return
 # Resolve one frontmost opaque sprite after all machine hit regions exist.
 # Overlapping image rectangles must never produce stacked station labels.
 var id=_machine_at(mouse)
 if id=="": return
 var title=_render_machines()[id]["title"]
 var width=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+18
 var p=Vector2(clampf(mouse.x+15,SHOP_VIEW.position.x,SHOP_VIEW.end.x-width),clampf(mouse.y+20,SHOP_VIEW.position.y,SHOP_VIEW.end.y-30))
 _panel(Rect2(p,Vector2(width,27)),NAVY)
 _text(p+Vector2(9,19),title,14,CREAM)

func _equipment_geometry(kind:String,p:Vector2,w:float) -> void:
 # Explicit reference-shaped equipment is used while the editable Blender render is imported.
 var z=w/190*zoom
 if kind=="dtf":
  _poly([p+Vector2(-80,-20)*z,p+Vector2(25,28)*z,p+Vector2(80,0)*z,p+Vector2(-25,-48)*z],Color("293943"))
  for x in [-67,63]: draw_line(p+Vector2(x,-11)*z,p+Vector2(x,-94)*z,Color("172632"),11*z)
  _poly([p+Vector2(-91,-107)*z,p+Vector2(23,-66)*z,p+Vector2(82,-97)*z,p+Vector2(-33,-139)*z],Color("56d6a7"))
  _poly([p+Vector2(-70,-111)*z,p+Vector2(23,-78)*z,p+Vector2(61,-98)*z,p+Vector2(-32,-132)*z],Color("143b3b"))
  _poly([p+Vector2(-91,-107)*z,p+Vector2(23,-66)*z,p+Vector2(23,-36)*z,p+Vector2(-91,-77)*z],Color("374654"))
  draw_line(p+Vector2(-81,-79)*z,p+Vector2(23,-41)*z,Color("111e2c"),10*z)
 else:
  _poly([p+Vector2(-79,-96)*z,p+Vector2(31,-55)*z,p+Vector2(84,-82)*z,p+Vector2(-26,-124)*z],Color("fffefa"))
  _poly([p+Vector2(-79,-96)*z,p+Vector2(31,-55)*z,p+Vector2(31,14)*z,p+Vector2(-79,-25)*z],Color("e9e7ed"))
  _poly([p+Vector2(31,-55)*z,p+Vector2(84,-82)*z,p+Vector2(84,-13)*z,p+Vector2(31,14)*z],Color("cbd1da"))
  for n in 5: draw_circle(p+Vector2(-67+n*23,-65+n*8.5)*z,3.5*z,Color("172b35"))
  draw_line(p+Vector2(-62,-12)*z,p+Vector2(28,21)*z,INK,12*z)
  draw_line(p+Vector2(-61,-31)*z,p+Vector2(29,2)*z,INK,9*z)
  _product("transfer",p+Vector2(-20,-8)*z,36*z)
  draw_line(p+Vector2(-22,-106)*z,p+Vector2(-22,-123)*z,Color("747887"),8*z)

func _worker(id:String) -> void:
 var w=sim.worker(id)
 var p=iso(sim.v(w["pos"]))
 _oval(p+Vector2(0,2)*zoom,Vector2(18,7)*zoom,Color(0.05,0.09,0.15,0.23))
 if id=="owner": _oval(p+Vector2(0,3)*zoom,Vector2(23,10)*zoom,Color(0.0,0.73,0.95,0.3))
 var col=0
 if w["walking"]: col=[1,2,3,2][int(w["step"])%4]
 var reduce=sim.state["settings"].get("reduce_motion",false)
 # Sam keeps the original look; staff get stable skin, hair, cap and shirt colours.
 var look={} if id=="owner" else Look.look(id+":"+str(w.get("name","")),false)
 var working=not w["task"].is_empty() and w["task"]["working"] and sim.state["machines"].has(w["task"]["machine"])
 var face=int(w["face"])
 var lift=0.0
 var tool_clock=0.0
 if working:
  # Face the station being operated and add a small working motion.
  var target=sim.equipment_center(w["task"]["machine"],sim.state["machines"])
  face=Look.face_toward(target-sim.v(w["pos"]),face)
  tool_clock=0.0 if reduce else float(sim.station_activity(w["task"]["machine"])["elapsed"])
  lift=absf(sin(tool_clock*4.0))*2.5
 var cellsize=Vector2(owner_sheet.get_width()/4.0,owner_sheet.get_height()/4.0)
 var region=Rect2(Vector2(col,face)*cellsize,cellsize)
 var size=Vector2(116,116)*zoom*float(look.get("scale",1.0))
 # Cell feet are at 97% of height; use the real sole baseline as the ground anchor.
 var rect=Rect2(p-Vector2(size.x*0.5,size.y*0.965+lift*zoom),size)
 var outfit=sim.state.get("style",{}).get("outfits",{}).get(id,"Workshop")
 Look.draw(self,Style.texture_for(owner_sheet,outfit),rect,region,look,["shirt"] if outfit=="Executive suit" else [])
 worker_hits.append({"id":id,"rect":Rect2(p-Vector2(35,107)*zoom,Vector2(70,112)*zoom)})
 if working:
  var hand=p+Vector2(18,-37-lift)*zoom
  Look.draw_tool(self,sim.state["machines"][w["task"]["machine"]]["kind"],hand,tool_clock,zoom)
  draw_arc(hand,22*zoom,tool_clock*3,tool_clock*3+1.4,8,CYAN,2*zoom)
 elif not w["task"].is_empty() and w["task"]["stage"] in ["press","qc","pack","ready"]:
  var hand=p+Vector2(18,-37)*zoom
  if w["task"]["stage"]=="ready": _panel(Rect2(hand-Vector2(11,8)*zoom,Vector2(22,17)*zoom),Color("d5a467"),NAVY,2)
  else: _product(sim.order(w["task"]["order"])["type"],hand,17*zoom)
 Style.draw_outfit(self,{"id":w["id"],"face":face},p)
 if not (photo_render or photo_active) and (id==selected_worker or dragging=="worker"):
  var label=w["name"]+ (" • YOU" if id=="owner" else "")
  world_labels.append({"at":p,"text":label,"progress":-1.0})

func _customer(actor:Dictionary) -> void:
 var p=iso(sim.v(actor["pos"]))
 _oval(p+Vector2(0,2)*zoom,Vector2(18,7)*zoom,Color(0.05,0.09,0.15,0.23))
 var col=[1,2,3,2][int(actor["step"])%4] if actor["walking"] else 0
 var cellsize=Vector2(owner_sheet.get_width()/4.0,owner_sheet.get_height()/4.0)
 var region=Rect2(Vector2(col,int(actor["face"]))*cellsize,cellsize)
 var index=int(actor["order"])
 # Each visiting customer gets a stable look; waiting customers shift gently.
 var look=Look.look(str(actor.get("name",""))+":"+str(sim.order(index).get("id","")),true)
 var bob=0.0
 if actor["phase"]=="waiting" and not sim.state["settings"].get("reduce_motion",false): bob=(sin(time*2.0+float(look["phase"]))+1.0)*0.8
 var size=Vector2(108,108)*zoom*float(look["scale"])
 Look.draw(self,owner_sheet,Rect2(p-Vector2(size.x*.5,size.y*.965+bob*zoom),size),region,look)
 if look.has("bag"): Look.draw_bag(self,p,int(actor["face"]),look["bag"],zoom)
 if sim.order(index).get("paid",false) and actor["purpose"]=="exit":
  _panel(Rect2(p+Vector2(11,-46)*zoom,Vector2(23,18)*zoom),Color("d5a467"),NAVY,2)
  if not (photo_render or photo_active) and sim.now()-float(sim.order(index).get("finished_at",-1))<.03:
   _text(p+Vector2(-24,-118)*zoom,"+$%d" % sim.order(index).get("payment",0),int(17*zoom),GREEN)
   var review=sim.order(index).get("review",{})
   if not review.is_empty(): _text(p+Vector2(-30,-138)*zoom,"★".repeat(int(review["stars"]))+"☆".repeat(5-int(review["stars"])),int(17*zoom),Color("e0a800"))
 customer_hits.append({"order":index,"rect":Rect2(p-Vector2(31,99)*zoom,Vector2(62,103)*zoom)})
 if not (photo_render or photo_active) and actor["phase"]=="waiting":
  _oval(p+Vector2(24,-89)*zoom,Vector2(14,13)*zoom,CREAM)
  _text(p+Vector2(18,-84)*zoom,"?" if actor["purpose"]=="inquiry" else "✓",int(19*zoom),BLUE)
 if not (photo_render or photo_active) and Rect2(p-Vector2(31,99)*zoom,Vector2(62,103)*zoom).has_point(get_global_mouse_position()) and modal=="" and not build:
  var label=actor["name"]
  var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+18
  _panel(Rect2(p+Vector2(-width*.5,8)*zoom,Vector2(width,24)*zoom),NAVY)
  _text(p+Vector2(-width*.5+9,25)*zoom,label,int(13*zoom),CREAM)

# "24 Shirts", "6 Hoodies", "12 Mugs": the plural shown on order cards.
func _units_name(o:Dictionary) -> String:
 if o["type"]=="apparel": return str(C.BLANKS[C.blank_of(o)]["units"])
 return {"transfer":"Transfers","sticker":"Stickers","banner":"Banners","cnc":"Signs","decal":"Decals","mug":"Mugs","hat":"Hats"}.get(o["type"],"Jobs")

func _product(type:String,p:Vector2,size:float) -> void:
 var r=Rect2(p-Vector2(size/2,size/2),Vector2(size,size))
 if type=="apparel":
  _poly([p+Vector2(-0.5,-0.3)*size,p+Vector2(-0.25,-0.5)*size,p+Vector2(0.25,-0.5)*size,p+Vector2(0.5,-0.3)*size,p+Vector2(0.33,-0.06)*size,p+Vector2(0.25,-0.13)*size,p+Vector2(0.25,0.5)*size,p+Vector2(-0.25,0.5)*size,p+Vector2(-0.25,-0.13)*size,p+Vector2(-0.33,-0.06)*size],CREAM,BLUE,1.8)
 elif type=="banner":
  draw_rect(r,Color("fd8dc2")); draw_rect(Rect2(r.position+Vector2(0,size*0.55),Vector2(size,size*0.45)),CYAN); draw_circle(p+Vector2(0,-size*0.1),size*0.23,YELLOW); draw_rect(r,BLUE,false,2)
  return
 elif type=="cnc":
  _panel(r,Color("ffd38b"),BLUE,2); _poly([p+Vector2(-0.25,0.3)*size,p+Vector2(-0.25,0)*size,p+Vector2(-0.35,0)*size,p+Vector2(-0.35,-0.22)*size,p+Vector2(-0.18,-0.22)*size,p+Vector2(-0.18,-0.05)*size,p+Vector2(-0.04,-0.05)*size,p+Vector2(-0.04,-0.4)*size,p+Vector2(0.13,-0.4)*size,p+Vector2(0.13,0.05)*size,p+Vector2(0.25,0.05)*size,p+Vector2(0.25,-0.2)*size,p+Vector2(0.4,-0.2)*size,p+Vector2(0.4,0.2)*size,p+Vector2(0.13,0.2)*size,p+Vector2(0.13,0.3)*size],GREEN,GREEN,0)
  return
 elif type=="mug":
  # A white mug with a printed band and a handle.
  _panel(r,Color("e9f6ff"),BLUE,3)
  var body=Rect2(p+Vector2(-0.28,-0.26)*size,Vector2(0.46,0.56)*size)
  draw_arc(p+Vector2(0.22,0.02)*size,size*0.13,-PI*0.5,PI*0.5,10,BLUE,size*0.07)
  draw_rect(body,Color("fffdf8"));draw_rect(Rect2(body.position+Vector2(0,body.size.y*0.3),Vector2(body.size.x,body.size.y*0.34)),MAGENTA)
  draw_rect(body,BLUE,false,1.6)
  return
 elif type=="hat":
  # A baseball cap with a stitched badge.
  _panel(r,Color("e9f6ff"),BLUE,3)
  var crown=[]
  for k in 9: crown.append(p+Vector2(cos(PI+k*PI/8.0)*0.3,sin(PI+k*PI/8.0)*0.28+0.08)*size)
  _poly(crown,Color("2a3f8f"),INK,1.4)
  _poly([p+Vector2(0.2,0.06)*size,p+Vector2(0.46,0.12)*size,p+Vector2(0.44,0.2)*size,p+Vector2(0.16,0.15)*size],Color("2a3f8f"),INK,1.2)
  draw_circle(p+Vector2(-0.02,-0.06)*size,size*0.09,YELLOW)
  return
 elif type=="decal":
  # Weeded vinyl star on its transfer-tape backing.
  _panel(r,Color("e9f6ff"),BLUE,3)
  var star=[]
  for k in 10:
   var rad=size*(0.36 if k%2==0 else 0.16)
   star.append(p+Vector2(cos(-PI/2+k*PI/5),sin(-PI/2+k*PI/5))*rad)
  _poly(star,MAGENTA,INK,1)
  return
 else: _panel(r,CREAM,BLUE,4)
 var s=size*0.45 if type=="apparel" else size*0.73
 _poly([p+Vector2(-0.4,-0.12)*s,p+Vector2(-0.4,-0.5)*s,p+Vector2(-0.13,-0.31)*s,p+Vector2(0.13,-0.31)*s,p+Vector2(0.4,-0.5)*s,p+Vector2(0.4,-0.12)*s],MAGENTA if type=="sticker" else Color("ffa359"),INK,1)
 _oval(p,Vector2(s*0.45,s*0.35),MAGENTA if type=="sticker" else Color("ffad6c"))
 draw_circle(p+Vector2(-0.16,-0.02)*s,s*0.055,INK); draw_circle(p+Vector2(0.16,-0.02)*s,s*0.055,INK)
 _oval(p+Vector2(0,0.15)*s,Vector2(s*0.2,s*0.12),CREAM)
 draw_circle(p+Vector2(0,0.09)*s,s*0.04,INK)

func _logo(p:Vector2, scale:float=1.0) -> void:
 var box=Rect2(p,Vector2(335,104)*scale)
 var size=Vector2(official_logo.get_width(),official_logo.get_height())
 size*=minf(box.size.x/size.x,box.size.y/size.y)
 draw_texture_rect(official_logo,Rect2(box.get_center()-size*0.5,size),false)

func _title() -> void:
 draw_rect(Rect2(-ui_offset,_screen_size()),Color(0.02,0.07,0.16,0.40))
 _panel(Rect2(430,120,740,640),Color(0.98,0.98,0.93,0.97),NAVY,20)
 _logo(Vector2(550,154),1.5)
 _text(Vector2(552,354),"BUILD YOUR DREAM PRINT SHOP",32,BLUE,-1,true)
 _text(Vector2(548,390),"Walk the floor. Make great prints. Grow your business.",19,INK)
 _button(Rect2(545,429,510,76),"START A NEW SHOP","new",YELLOW,true,27)
 _button(Rect2(545,525,245,55),"CONTINUE","continue",NAVY,sim.has_save(),22)
 _button(Rect2(811,525,245,55),"HOW TO PLAY","help",NAVY,true,22)
 _button(Rect2(545,600,245,52),"SETTINGS","settings",CYAN)
 _button(Rect2(811,600,245,52),"QUIT","quit",CREAM)
 _button(Rect2(545,670,510,48),"PLAY DEMO SHOP","demo",GREEN,true,23)
 var title_message=status if status!="" else "Demo equipment and team included. Career save stays separate."
 _line(Vector2(549,742),title_message,14,RED if status!="" else MUTED,510)
 Banner.draw(self)
 if modal!="": _modal()

func _ui_docks() -> void:
 var screen_size=_screen_size();var extra=screen_size-Vector2(1600,900)
 draw_rect(Rect2(0,0,264,screen_size.y-22),DOCK)
 draw_rect(Rect2(264,0,screen_size.x-264,66),DOCK)
 draw_rect(Rect2(264,768+extra.y,screen_size.x-264,110),DOCK)
 draw_line(Vector2(264,0),Vector2(264,screen_size.y-22),Color("a5b4b3"),2)
 draw_line(Vector2(264,66),Vector2(screen_size.x,66),Color("a5b4b3"),2)
 draw_line(Vector2(264,768+extra.y),Vector2(screen_size.x,768+extra.y),Color("a5b4b3"),2)
 _logo(Vector2(7,9),.75)
 _button(Rect2(14,89,235,25),"WORKSHOP + STYLE","workshop",CYAN,true,13)
 var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
 _button(Rect2(14,829+extra.y,235,35),"WINDOW MODE  F11" if full else "FULLSCREEN  F11","fullscreen",NAVY,true,14)

func _hud() -> void:
 var extra=_screen_size().x-1600
 _panel(Rect2(278,7,258,49),NAVY,NAVY,8)
 _text(Vector2(292,25),"PAUSED / SPACE TO RESUME" if sim.state["paused"] else ("DEMO SHOP / SEPARATE SAVE" if sim.state.get("demo",false) else sim.premises_title()+(" / "+str(Customers.season(sim)["name"]).to_upper() if Customers.active(sim) else "")),14,CYAN,240,true)
 _text(Vector2(292,47),"DAY %d  %s" % [sim.state["day"],_clock(sim.state["clock"])],20,CREAM)
 _panel(Rect2(546,7,166,49),NAVY,NAVY,8)
 draw_circle(Vector2(568,31),11,YELLOW)
 _text(Vector2(564,37),"$",16,Color("ab6400"))
 _text(Vector2(586,39),"$%d" % sim.state["cash"],26,CREAM,-1,true)
 _panel(Rect2(722,7,117,49),NAVY,NAVY,8)
 _text(Vector2(733,26),"TRUST",12,CYAN)
 _text(Vector2(733,47),"%d%%" % sim.state["reputation"],22,CREAM,-1,true)
 # Shop level with its XP bar; opens Goals + Awards.
 var lv=Progress.span(sim)
 _button(Rect2(849,7,132,49),"LEVEL %d" % int(lv["level"]),"goals",NAVY,true,18)
 draw_rect(Rect2(861,45,108,6),Color("23395f"))
 draw_rect(Rect2(861,45,108*float(lv["fraction"]),6),YELLOW)
 _button(Rect2(995,9,43,45),">" if sim.state["paused"] else "II","pause",NAVY,true,19)
 for i in 3:
  var speed=[1,2,4][i]
  _button(Rect2(1048+i*49,9,41,45),"%dx" % speed,"speed:%d" % speed,CYAN if sim.state["speed"]==speed else NAVY,true,16)
 _button(Rect2(1205+extra,9,158,45),"MUSIC: ON" if sim.state["settings"]["music"] else "MUSIC: OFF","music",CYAN if sim.state["settings"]["music"] else NAVY,true,16)
 _button(Rect2(1375+extra,9,91,45),"SAVE","save",NAVY,true,16)
 _button(Rect2(1478+extra,9,106,45),"MENU","settings",NAVY,true,16)

func _orders() -> void:
 var rows=sim.active_orders()
 var pages=maxi(1,ceili(rows.size()/3.0))
 order_page=order_page%pages
 _text(Vector2(17,464),"ACTIVE ORDERS  %d" % sim.active_orders().size(),19,BLUE,-1,true)
 _button(Rect2(14,790+_screen_size().y-900,235,27),"CAPACITY + CASH  [Q]","capacity",CYAN,true,13)
 if rows.is_empty():_text(Vector2(17,489),"New inquiries appear here.",14,MUTED,230)
 for n in 3:
  var j=order_page*3+n
  if j>=rows.size():break
  var i=rows[j];var o=sim.order(i);var r=Rect2(13,477+n*94,237,86)
  _panel(r,CREAM,Color("c3d0d5"),8)
  _product(o["type"],r.position+Vector2(27,26),30)
  _text(r.position+Vector2(50,22),"%d %s" % [o["quantity"],_units_name(o)],21,BLUE,-1,true)
  var stage={"queued":"Needs operator","waiting_stock":"Needs supplies","prepress":"Artwork preparation","production":"Printing / curing","press":"Ready to press","inspecting":"Quality check","delivering":"Pickup / shipping"}.get(o["stage"],_stage(o["stage"]))
  if o["stage"]=="production": stage={"transfer":"DTF print / powder / cure","apparel":"DTF transfer production","sticker":"Print / laminate / cut","banner":"Wide-format printing","cnc":"Cutting rigid panels","decal":"Cut / weed / tape vinyl","mug":"Print / wrap / press mugs","hat":"Hoop / stitch / trim hats"}.get(o["type"],"Production")
  if o["stage"]=="production" and C.is_htv(o): stage="Cut / weed heat-transfer vinyl"
  _text(r.position+Vector2(50,47),stage,12,RED if sim.now()>o["due"] else MUTED)
  _text(r.position+Vector2(12,69),"$%d  /  %s" % [o["reward"],_due(o)],12,INK)
  draw_rect(Rect2(r.position+Vector2(12,80),Vector2(212,5)),Color("c4d9f2"))
  draw_rect(Rect2(r.position+Vector2(12,80),Vector2(212*_route_progress(o),5)),CYAN)
  buttons.append({"rect":r,"action":"order:%d" % i})
 if pages>1:_button(Rect2(14,757+_screen_size().y-900,235,27),"MORE ORDERS  >","more_orders",NAVY,true,14)

func _toolbar() -> void:
 _set_ui_offset(Vector2(0,_screen_size().y-900))
 var extra_width=_screen_size().x-1600
 var notice=status if status!="" else sim.state["notices"][0]
 var placing=pending_equipment!="" or _relocating()
 if pending_decor!="" or moving_decor!="":notice="Click clear floor or arrows + Enter to "+("move selected decor" if moving_decor!="" else "place "+pending_decor.replace("_"," "))+". Escape cancels. Shop held."
 if placing:notice=("Click to place. " if dragging!="machine" else "Release to place. ")+drag_valid.get("reason","Choose clear floor.")
 draw_rect(Rect2(276,775,_screen_size().x-288,21),RED if placing and not drag_valid.get("valid",false) else NAVY)
 _text(Vector2(286,791),notice,14,CREAM,_screen_size().x-310)
 var entries=[[0,"DTF LINE","machine:dtf"],[2,"STICKER PRINT / CUT","machine:sticker"],[3,"HEAT PRESS","machine:heat"],[7,"ADD EQUIPMENT","equipment"],[9,"STAFF + UPGRADES","staff"],[6,"BUILD / ARRANGE","build"],[11,"EXPAND SHOP","move"]]
 if not sim.state["machines"].has("dtf") and sim.state["machines"].has("dtfmini"):entries[0]=[100,"DESKTOP DTF","machine:dtfmini"]
 if not sim.state["machines"].has("sticker") and sim.state["machines"].has("cutter"):entries[1]=[101,"VINYL CUTTER","machine:cutter"]
 if sim.state["location"]==2:entries[2]=[4,"ROLL-TO-ROLL","machine:banner"];entries[6]=[11,"SHOP GROWTH","move"]
 for i in entries.size():
  var entry=entries[i]
  if str(entry[2]).begins_with("machine:") and not sim.state["machines"].has(str(entry[2]).get_slice(":",1)):entry[2]="equipment"
  var step=133+extra_width/7.0
  var r=Rect2(276+i*step,803,step-8,66)
  _panel(r,Color("e7fbff") if i==0 else CREAM,BLUE,8)
  var kind={0:"dtf",2:"sticker",3:"heat",4:"banner",5:"cnc",6:"art",7:"storage",11:"dock",100:"dtfmini",101:"cutter"}.get(entry[0],"")
  if kind!="":_illustrated_icon(kind,Rect2(r.position+Vector2(21,2),Vector2(83,44)))
  else:
   var texture:Texture2D=atlas_tiles[entry[0]]
   var icon_size=texture.get_size();icon_size*=minf(83/icon_size.x,44/icon_size.y)
   draw_texture_rect(texture,Rect2(r.position+Vector2(62,24)-icon_size*.5,icon_size),false)
  _line(r.position+Vector2(6,59),entry[1],13,BLUE,r.size.x-12,true)
  buttons.append({"rect":Rect2(r.position+ui_offset,r.size),"action":entry[2]})
 _button(Rect2(1214+extra_width,803,180,29),"SAM: MANUAL" if sim.owner()["manual"] else "SAM: AUTO ASSIST","assist",CYAN,true,13)
 _button(Rect2(1406+extra_width,803,182,29),"END DAY","end_day",YELLOW,true,15)
 _button(Rect2(1214+extra_width,840,180,29),"FIT WHOLE SHOP","camera",NAVY,true,13)
 _button(Rect2(1406+extra_width,840,182,29),"HOW TO PLAY","help",NAVY,true,13)
 _set_ui_offset(Vector2.ZERO)

func _welcome_gift_panel() -> void:
 _header("A GIFT FOR YOUR NEW SHOP","Almost every print shop starts the same way.")
 _panel(Rect2(389,215,300,230),Color("eef9e4"),Color("8dc63f"),10)
 _illustrated_icon("cutter",Rect2(404,232,270,196))
 _text(Vector2(712,250),"YOUR FIRST VINYL CUTTER",24,BLUE,-1,true)
 _text(Vector2(712,282),"One small vinyl cutter in a garage. That is how most of us began.\n\nCut heat-transfer vinyl, weed it, and press it onto shirts. Add a heat press, make your first sales, and grow from there.\n\nWhen the sales add up, upgrade to a desktop DTF kit and then the full DTF line.",17,INK,490)
 _text(Vector2(389,486),"WALKTHROUGH",19,BLUE,-1,true)
 _text(Vector2(389,512),"1. Place your gifted cutter (free)     2. Buy and place a heat press\n3. Place the free artwork, inspection and packing benches     4. Open the shop\n5. Make and deliver your first vinyl T-shirt order",16,INK,818)
 _button(Rect2(389,690,397,52),"PLACE MY CUTTER","place:cutter",GREEN,true,18)
 _button(Rect2(801,690,406,52),"SKIP WALKTHROUGH","walkthrough_skip",CREAM,true,15)

func _walkthrough_card(step:String) -> void:
 var title={"gift":"YOUR FIRST CUTTER","press":"ADD A HEAT PRESS","benches":"WORK BENCHES","open":"OPEN THE SHOP","done":"FIRST SALE!"}.get(step,"WALKTHROUGH")
 var body={"gift":"Place your gifted vinyl\ncutter on clear floor.\nIt is free.","press":"Shirts need heat. Buy the\n$250 heat press and place it\nnear your cutter.","benches":"Place the free artwork,\ninspection and packing\nbenches.","open":"Press Space or Open Shop.\nYour first customer wants\nvinyl T-shirts.","done":"Every paid job earns XP.\nDesktop DTF unlocks at\nshop level %d." % int(Progress.UNLOCK_LEVEL["dtfmini"])}.get(step,"")
 _text(Vector2(25,146),title,23,BLUE,-1,true)
 _text(Vector2(25,173),body,14,INK,211)
 match step:
  "gift": _button(Rect2(24,233,140,27),"PLACE CUTTER","place:cutter",GREEN,true,12)
  "press": _button(Rect2(24,233,140,27),"HEAT PRESS  $250","place:heat",GREEN,sim.state["cash"]>=sim.Ops.equipment_cost(sim,"heat"),12)
  "benches":
   var next_bench="art"
   for id in ["art","finish","pack"]:
    if not sim.state["machines"].has(id): next_bench=id;break
   _button(Rect2(24,233,140,27),{"art":"ARTWORK DESK","finish":"INSPECT BENCH","pack":"PACKING BENCH"}[next_bench],"place:"+next_bench,GREEN,true,12)
  "open": _button(Rect2(24,233,140,27),"OPEN SHOP","pause",GREEN,true,12)
  "done": _button(Rect2(24,233,140,27),"GOT IT","walkthrough_done",GREEN,true,12)
 if step!="done": _button(Rect2(172,233,66,27),"SKIP","walkthrough_skip",CREAM,true,11)

func _setup_card() -> void:
 _panel(Rect2(13,119,237,152),CREAM,Color("c3d0d5"),8)
 var step=sim.walkthrough_step()
 if step!="" and step!="job":
  _walkthrough_card(step)
 elif sim.state["machines"].is_empty():
  _text(Vector2(25,146),"YOUR EMPTY SHOP",23,BLUE,-1,true)
  _text(Vector2(25,173),"Choose your first station.\nPlace it on clear floor.\nPaused: Space to walk.",14,INK,211)
  _button(Rect2(24,233,213,27),"ADD YOUR FIRST STATION","equipment",CYAN,true,12)
 elif sim.state["paused"] and _setup_pending():
  _text(Vector2(25,146),"READY TO OPEN?",23,BLUE,-1,true)
  _text(Vector2(25,173),"Add free inspection and\npickup benches. Space runs\nthe clock and lets Sam walk.",14,INK,211)
  _button(Rect2(24,233,104,27),"EQUIPMENT","equipment",CYAN,true,12)
  _button(Rect2(138,233,100,27),"OPEN SHOP","pause",GREEN,true,12)
 elif sim.state["tutorial"] and _tutorial_index()>=0:
  var i=_tutorial_index()
  _text(Vector2(25,146),"FIRST PRINT JOB",23,BLUE,-1,true)
  _text(Vector2(25,173),_tutorial_hint(sim.order(i)),13,INK,211)
  _button(Rect2(24,233,104,27),"OPEN JOB","order:%d" % i,CYAN,true,12)
  _button(Rect2(138,233,100,27),"SKIP TUTORIAL","skip",CREAM,true,11)
 else:
  var goal=Progress.next_goal(sim)
  if goal.is_empty():
   _text(Vector2(25,146),"PRINT SHOP TYCOON",21,BLUE,-1,true)
   _text(Vector2(25,174),"Every goal is done.\nThe shop is yours to run.\nAwards are still out there.",14,INK,211)
  else:
   _text(Vector2(25,146),"NEXT GOAL",23,BLUE,-1,true)
   _text(Vector2(25,172),str(goal["title"]),15,INK,211,true)
   _text(Vector2(25,208),"%s   +%d XP" % [Progress.progress_text(goal),int(goal["xp"])],13,MUTED,211)
  _button(Rect2(24,233,214,27),"GOALS + AWARDS","goals",CYAN,true,12)

func _next_action_index() -> int:
 # The job whose next step Sam can do by hand right now: selected job first, then the guided job, then the oldest.
 var owner=sim.owner()
 if not owner.get("manual",true) or not owner.get("task",{}).is_empty() or sim.state.get("operations",{}).get("away",false): return -1
 var candidates=[]
 if selected_order>=0: candidates.append(selected_order)
 var tutorial=_tutorial_index() if sim.state.get("tutorial",false) else -1
 if tutorial>=0: candidates.append(tutorial)
 for i in sim.active_orders(): candidates.append(i)
 for i in candidates:
  var o=sim.order(i)
  if o.is_empty() or o["stage"] not in ["queued","press","qc","pack","ready"]: continue
  if o["stage"]=="ready" and not sim.customer_ready_for_handoff(o): continue
  if not sim.state["machines"].has(sim.machine_for(o)): continue
  return i
 return -1

func _next_action_chip() -> void:
 if photo_active or photo_render or screen!="shop": return
 var i=_next_action_index()
 if i<0: return
 var o=sim.order(i)
 var station=str(sim.state["machines"][sim.machine_for(o)]["title"])
 var label="NEXT FOR %d %s: %s" % [int(o["quantity"]),str(o["product"]).to_upper(),station.to_upper()]
 var width=minf(SHOP_VIEW.size.x-40,760.0)
 var rect=Rect2(SHOP_VIEW.get_center().x-width*.5,SHOP_VIEW.end.y-50,width,42)
 _panel(rect,Color(1,.99,.96,.96),BLUE,10)
 _line(rect.position+Vector2(14,27),label,15,INK,width-330,true)
 _button(Rect2(rect.end.x-312,rect.position.y+5,170,32),"SAM: WORK IT","next_work:%d" % i,GREEN,true,14)
 _button(Rect2(rect.end.x-134,rect.position.y+5,126,32),"AUTO ASSIST","next_assist",CYAN,true,13)

func _toasts() -> void:
 # Goal and award banners over the shop floor, one at a time.
 while not toasts.is_empty() and time>float(toasts[0]["until"]): toasts.pop_front()
 if toasts.is_empty() or photo_active or photo_render: return
 var label=str(toasts[0]["text"])
 var width=minf(SHOP_VIEW.size.x-40,bold.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+44)
 var rect=Rect2(SHOP_VIEW.get_center().x-width*.5,SHOP_VIEW.position.y+12,width,38)
 _panel(rect,NAVY,YELLOW,10)
 _text(rect.position+Vector2(22,25),label,18,YELLOW,width-40,true)

func _goals_panel() -> void:
 var lv=Progress.span(sim)
 var paid_jobs=int(Progress.ensure(sim)["stats"]["jobs"])
 _header("GOALS + AWARDS","Level %d  •  %s  •  %d %s paid" % [int(lv["level"]),Progress.title(sim),paid_jobs,"job" if paid_jobs==1 else "jobs"])
 _button(Rect2(389,206,396,40),"GOALS","goals_list",CYAN if goals_page==0 else CREAM,true,17)
 _button(Rect2(801,206,406,40),"AWARDS","goals_awards",CYAN if goals_page==1 else CREAM,true,17)
 draw_rect(Rect2(389,258,818,14),Color("d7e2ee"))
 draw_rect(Rect2(389,258,818*float(lv["fraction"]),14),YELLOW)
 _text(Vector2(389,292),"Shop level is at its highest." if lv["max"] else "%d / %d XP to level %d. Paid jobs, on-time delivery and goals earn XP." % [int(lv["xp"]),int(lv["next"]),int(lv["level"])+1],15,MUTED,818)
 if goals_page==0:
  var rows=Progress.goals(sim)
  for i in rows.size():
   var row=rows[i];var y=306+i*25
   var done=bool(row["done"])
   draw_circle(Vector2(401,y+10),9,GREEN if done else Color("c8d3de"))
   if done: _text(Vector2(395,y+16),"✓",15,CREAM,-1,true)
   _text(Vector2(420,y+16),str(row["title"]),16,MUTED if done else INK,520)
   _text(Vector2(948,y+16),Progress.progress_text(row),15,GREEN if done else BLUE,150)
   _text(Vector2(1120,y+16),"+%d XP" % int(row["xp"]),15,MUTED,90)
  var next=Progress.next_goal(sim)
  _text(Vector2(389,700),"Next: "+str(next["hint"]) if not next.is_empty() else "Every goal is done. You built a Print Shop Tycoon.",15,BLUE,818)
 else:
  var rows=Progress.awards(sim)
  for i in rows.size():
   var row=rows[i];var column=i%2;var y=310+int(i/2.0)*42
   var x=389+column*414
   var done=bool(row["done"])
   _panel(Rect2(x,y,404,37),Color("fff3c4") if done else Color("eef2f6"),Color("e0b93a") if done else Color("c8d3de"),8)
   draw_circle(Vector2(x+20,y+18),11,YELLOW if done else Color("c8d3de"))
   _text(Vector2(x+14,y+24),"★",16,Color("ab6400") if done else CREAM,-1,true)
   _text(Vector2(x+40,y+16),str(row["title"]),14,INK if done else MUTED,250,true)
   _text(Vector2(x+40,y+31),str(row["text"]),11,MUTED,290)
   if not done and float(row["need"])>1 and row["id"]!="rating45": _text(Vector2(x+322,y+23),"%d / %d" % [int(row["value"]),int(row["need"])],12,BLUE,78)
 _button(Rect2(389,722,818,36),"BACK TO SHOP","close",NAVY,true,16)

func _levelup_panel() -> void:
 var lv=int(progress_card.get("level",Progress.level(sim)))
 _header("SHOP LEVEL %d" % lv,"Your shop is growing.")
 draw_circle(Vector2(800,330),78,YELLOW)
 draw_circle(Vector2(800,330),66,Color("fff3c4"))
 var number=str(lv)
 _text(Vector2(800-bold.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,84).x*.5,360),number,84,BLUE,-1,true)
 var rank=str(progress_card.get("title",Progress.title(sim))).to_upper()
 _text(Vector2(800-bold.get_string_size(rank,HORIZONTAL_ALIGNMENT_LEFT,-1,30).x*.5,455),rank,30,BLUE,-1,true)
 var unlocks=progress_card.get("unlocks",[])
 if unlocks.is_empty():
  _text(Vector2(389,510),"Keep delivering good work on time. Bigger equipment and a bigger shop are ahead.",17,INK,818)
 else:
  _text(Vector2(389,505),"NOW IN ADD EQUIPMENT",17,BLUE,-1,true)
  for i in unlocks.size(): _text(Vector2(389,535+i*27),"•  "+str(unlocks[i]),18,INK,818)
 var next=Progress.next_goal(sim)
 if not next.is_empty(): _text(Vector2(389,640),"Next goal: "+str(next["title"]),16,MUTED,818)
 _button(Rect2(389,690,397,52),"KEEP GOING","close",GREEN,true,18)
 _button(Rect2(801,690,406,52),"GOALS + AWARDS","goals",CREAM,true,16)

func _ending_panel() -> void:
 var p=Progress.ensure(sim);var st=p["stats"]
 _header("YOU BUILT A PRINT SHOP TYCOON","From one small vinyl cutter to a real production shop.")
 _illustrated_icon("cutter",Rect2(389,212,150,116))
 _text(Vector2(556,246),"Every goal is complete.",24,BLUE,-1,true)
 _text(Vector2(556,280),"It started with a gifted cutter and a heat press. Look at it now.",17,INK,650)
 var facts=[["Days open",str(int(sim.state["day"]))],["Jobs delivered",str(int(st["jobs"]))],["Money earned from jobs","$%d" % int(st["revenue"])],["Shirts made",str(int(st["shirts"]))],["Team","%d %s" % [sim.state["workers"].size(),"person" if sim.state["workers"].size()==1 else "people"]],["Customer trust","%d%%" % int(sim.state["reputation"])],["Best on-time streak",str(int(st["best_streak"]))],["Awards","%d of %d" % [p["awards"].size(),Progress.AWARDS.size()]]]
 for i in facts.size():
  var x=389+(i%2)*414;var y=356+int(i/2.0)*62
  _panel(Rect2(x,y,404,52),Color("edf5ff"),Color("c5d8ee"),8)
  _text(Vector2(x+16,y+22),str(facts[i][0]),14,MUTED,250)
  _text(Vector2(x+16,y+44),str(facts[i][1]),20,BLUE,360,true)
 _text(Vector2(389,636),"The shop is still yours. Keep playing as long as you like: awards, a bigger team and bigger days are all still there.",16,INK,818)
 _button(Rect2(389,690,397,52),"KEEP PLAYING","close",GREEN,true,18)
 _button(Rect2(801,690,406,52),"GOALS + AWARDS","goals",CREAM,true,16)

# Turns finished goals, awards and new levels into banners, pop-ups and sounds.
func _progress_events() -> void:
 if Customers.active(sim):
  var season_now=Customers.season_index(int(sim.state["day"]))
  if season_seen>=0 and season_now!=season_seen:
   var season=Customers.season(sim)
   toasts.append({"text":"NEW SEASON: %s  •  %s" % [str(season["name"]).to_upper(),season["note"]],"until":maxf(time,float(toasts[-1]["until"]) if not toasts.is_empty() else time)+6.0})
   _play("levelup",.6)
  season_seen=season_now
 Progress.refresh(sim)
 for event in Progress.pop_events(sim):
  match str(event["kind"]):
   "goal":
    toasts.append({"text":"GOAL DONE:  %s   +%d XP" % [event["title"],int(event["xp"])],"until":maxf(time,float(toasts[-1]["until"]) if not toasts.is_empty() else time)+4.0})
    _play("done")
   "award":
    toasts.append({"text":"AWARD:  %s   +%d XP" % [event["title"],int(event["xp"])],"until":maxf(time,float(toasts[-1]["until"]) if not toasts.is_empty() else time)+4.0})
    _play("levelup",.7)
   "level","ending": pending_cards.append(event)
 if modal=="" and not build and not pending_cards.is_empty() and pending_equipment=="" and dragging=="":
  progress_card=pending_cards.pop_front()
  # Several levels at once show only the newest card.
  while not pending_cards.is_empty() and str(pending_cards[0]["kind"])=="level" and str(progress_card["kind"])=="level":
   var newer=pending_cards.pop_front()
   newer["unlocks"]=progress_card.get("unlocks",[])+newer.get("unlocks",[])
   progress_card=newer
  modal="ending" if str(progress_card["kind"])=="ending" else "levelup"
  _play("fanfare" if modal=="ending" else "levelup")

func _build_panel() -> void:
 _panel(Rect2(13,119,237,222),CREAM,BLUE,8)
 _text(Vector2(25,147),"ARRANGE YOUR SHOP",23,BLUE,-1,true)
 _text(Vector2(25,173),"Drag equipment to move it.\nR: rotate by 22.5 degrees.\nGreen fits. Red is blocked.\nEscape: cancel this placement.",14,INK,211)
 _button(Rect2(24,254,102,31),"ROTATE  R","rotate_equipment",GREEN,true,13)
 _button(Rect2(137,254,101,31),"MOVE","move_equipment",CYAN,sim.state["machines"].has(selected_machine),13)
 _button(Rect2(24,296,214,31),"DONE BUILDING","build",YELLOW,true,14)
 _button(Rect2(24,363,214,34),"ADD EQUIPMENT","equipment",CYAN,true,14)
 _text(Vector2(25,424),"The full floor stays clear.",14,MUTED,211)

func _clock(hour:float) -> String:
 var h=floori(hour)
 var minute=floori((hour-h)*60)
 return "%d:%02d %s" % [12 if h%12==0 else h%12,minute,"AM" if h<12 else "PM"]

func _due(o:Dictionary) -> String:
 var due=float(o["due"])
 var day=floori(due/9)+1
 return "D%d %s" % [day,_clock(8+fmod(due,9))]

func _stage(s:String) -> String:
 return {"scheduled":"Customer due to arrive","abandoned":"Inquiry expired","intake":"New order","preflight":"Check artwork","revision":"Awaiting artwork","plan":"Plan production","queued":"Queued / needs operator","waiting_stock":"Waiting for stock","batch_wait":"Shared sheet in production","production":"Production in progress","press":"Ready for heat press","pressing":"Pressing garments","qc":"Inspect output","inspecting":"Quality inspection","fault":"Quality recovery","pack":"Ready to pack","packing":"Packing output","ready":"Ready for delivery","delivering":"Pickup / dispatch","completed":"Fulfilled","declined":"Declined"}.get(s,s)

func _setup_pending() -> bool:
 return sim.state["day"]==1 and sim.state["completed"]==0 and sim.state["orders"].all(func(o): return o["stage"]=="scheduled")

func _customer_card() -> void:
 _panel(Rect2(13,287,237,151),CREAM,Color("c3d0d5"),8)
 _text(Vector2(25,313),"CUSTOMER DESK",23,BLUE,-1,true)
 var waiting=0;var pickup=0
 for o in sim.state["orders"]:
  if o["stage"]=="intake":waiting+=1
  if o["stage"]=="ready" and sim.customer_ready_for_handoff(o):pickup+=1
 var detail="%d inquiries / %d ready" % [waiting,pickup]
 if Customers.review_count(sim)>0: detail+="  •  ★ %.1f" % Customers.rating(sim)
 if sim.state["paused"] and _setup_pending():detail="Set up, then open your shop."
 _text(Vector2(25,338),detail,13,INK,211)
 _button(Rect2(24,354,214,30),"CUSTOMERS + RECEIPTS","customers",NAVY,true,12)
 if Merch.unlocked(sim):
  _button(Rect2(24,396,104,30),"MARKETING","marketing",CYAN,true,12)
  _button(Rect2(134,396,104,30),"MERCH","merch",GREEN,true,12)
 else: _button(Rect2(24,396,214,30),"MARKETING + LEADS","marketing",CYAN,true,12)

func _merch_panel() -> void:
 var m=Merch.ensure(sim)
 var last=m.get("last_day",{})
 _header("MERCH + STORE","Your own designs, printed on your machines and sold online or at the weekend craft market.")
 _text(Vector2(389,222),"THIS WEEK'S TREND: %s (double demand)  •  Cash $%d" % [Merch.trend(sim).to_upper(),sim.state["cash"]],16,BLUE,818)
 _button(Rect2(389,236,260,36),"CLOSE ONLINE STORE" if m["store_open"] else "OPEN ONLINE STORE  $%d/day" % Merch.STORE_FEE,"merch_store",NAVY if m["store_open"] else GREEN,true,13)
 var booked=int(m["booth_day"])==int(sim.state["day"])
 var booth="BOOTH BOOKED TODAY" if booked else ("BOOK MARKET BOOTH  $%d" % Merch.BOOTH_FEE if Merch.weekend(sim) else "MARKET: WEEKENDS ONLY")
 _button(Rect2(661,236,260,36),booth,"merch_booth",CYAN,Merch.weekend(sim) and not booked,13)
 _text(Vector2(935,259),"Sold %d all-time  •  $%d" % [int(m["sold_total"]),int(m["revenue_total"])],14,MUTED,270)
 var kinds=Merch.makeable(sim)
 if merch_kind=="" or not merch_kind in kinds: merch_kind=kinds[0] if not kinds.is_empty() else ""
 _panel(Rect2(389,284,818,58),Color("eef8ee"),Color("bfdcc0"),8)
 if kinds.is_empty(): _text(Vector2(407,318),"Install a cutter, press, printer or other machine to make merch.",15,INK,780)
 else:
  _button(Rect2(399,294,190,38),"MAKE: "+str(Merch.KINDS[merch_kind]["label"]).to_upper(),"merch_kind",CREAM,kinds.size()>1,13)
  _button(Rect2(599,294,300,38),"THEME: "+str(Merch.THEMES[merch_theme]).to_upper(),"merch_theme",CREAM,true,13)
  _button(Rect2(909,294,288,38),"NEW DESIGN  $%d" % Merch.DESIGN_FEE,"merch_new",GREEN,sim.state["cash"]>=Merch.DESIGN_FEE,14)
 var designs=m["designs"]
 if designs.is_empty(): _text(Vector2(389,380),"No designs yet. Pick a product and theme, then make a design and print a batch.",16,MUTED,818)
 for n in mini(designs.size(),5):
  var d=designs[designs.size()-1-n]
  var y=352+n*66
  _panel(Rect2(389,y,818,58),Color("edf5ff"),Color("c5d8ee"),8)
  var tag="  ★ TRENDING" if d["theme"]==Merch.trend(sim) else ""
  _text(Vector2(403,y+24),str(d["name"])+tag,17,BLUE,420,true)
  _text(Vector2(403,y+47),"Stock %d  •  Sold %d  •  ~%.1f/day" % [int(d["stock"]),int(d["sold"]),Merch.demand(sim,d)],13,INK,330)
  _button(Rect2(745,y+12,34,34),"-","merch_price:%s:-1" % d["id"],CREAM,true,16)
  _text(Vector2(786,y+36),"$%d" % int(d["price"]),17,INK,60)
  _button(Rect2(840,y+12,34,34),"+","merch_price:%s:1" % d["id"],CREAM,true,16)
  var busy=Merch.batch_open(sim,d["id"])
  _button(Rect2(887,y+12,306,34),"BATCH PRINTING..." if busy else "PRINT BATCH OF %d" % int(Merch.KINDS[d["kind"]]["batch"]),"merch_batch:"+str(d["id"]),GREEN,not busy and sim.can_produce(str(Merch.KINDS[d["kind"]]["type"])),13)
 var summary="Stock sells at the close of each day."
 if not last.is_empty(): summary="Day %d: sold %d for $%d (fees $%d)." % [int(last["day"]),int(last["units"]),int(last["revenue"]),int(last["fee"])]
 _text(Vector2(389,697),summary,15,BLUE,808)
 _button(Rect2(389,712,397,43),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,712,406,43),"MARKETING","marketing",CREAM)

func _marketing_panel() -> void:
 sim._ensure_marketing()
 _header("GROW YOUR PRINT SHOP","Campaigns bring equipment-matched inquiries. Clock paused while this panel is open.")
 var names={"transfer":"transfers","sticker":"stickers","apparel":"shirts","banner":"banners","cnc":"signs","decal":"decals","mug":"mugs","hat":"hats"}
 var types=sim.Marketing.supported(sim.state["machines"])
 var products=[]
 for type in types: products.append(names[type])
 _text(Vector2(389,222),"Cash $%d  •  Marketing spent today $%d" % [sim.state["cash"],sim.state["stats"].get("marketing",0)],20,BLUE)
 _text(Vector2(389,253),"Promoting: "+(", ".join(products) if not products.is_empty() else "add a printer first"),17,INK,808)
 var keys=["flyers","social","business"]
 for n in keys.size():
  var id=keys[n]
  var campaign=sim.Marketing.CAMPAIGNS[id]
  var feedback=sim.marketing_feedback(id)
  var y=278+n*112
  _panel(Rect2(389,y,818,101),Color("edf5ff"),Color("c5d8ee"),8)
  _text(Vector2(407,y+28),campaign["title"],22,BLUE,-1,true)
  var quotes=0
  for lead in campaign["leads"]:
   if not types.is_empty(): quotes+=sim.Marketing.JOBS[types[(int(sim.state["marketing"]["next_id"])-1+lead)%types.size()]]["reward"]
  var inquiry_label="inquiry" if int(campaign["leads"])==1 else "inquiries"
  _text(Vector2(407,y+53),"%d %s • Quotes $%d total • First in %d shop min" % [campaign["leads"],inquiry_label,quotes,roundi(campaign["delay"]*60)],15,INK,556)
  _text(Vector2(407,y+80),feedback["reason"],14,MUTED,555)
  _button(Rect2(986,y+24,201,48),"LAUNCH  $%d" % campaign["cost"],"campaign:"+id,GREEN,feedback["valid"],17)
 var history=sim.state["marketing"]["history"]
 var summary="No campaigns launched yet."
 if not history.is_empty():
  var recent=history[0]
  var arrived=0
  var pending=0
  var collected=0
  for o in sim.state["orders"]:
   if o.get("campaign",-1)!=recent["id"]: continue
   if o["stage"]=="scheduled": pending+=1
   else: arrived+=1
   collected+=int(o.get("payment",0))
  summary="Latest: %d arrived • %d expected • $%d collected" % [arrived,pending,collected]
 _text(Vector2(389,645),summary,17,BLUE,808)
 _text(Vector2(389,677),"An inquiry still needs acceptance and production. Sales are collected at handoff.",16,MUTED,808)
 _button(Rect2(389,710,397,43),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,710,406,43),"VIEW CUSTOMERS","customers",CREAM)

func _reviews_panel() -> void:
 var count=Customers.review_count(sim)
 _header("REVIEWS + REGULARS","★ %.1f average from %d %s" % [Customers.rating(sim),count,"review" if count==1 else "reviews"] if count>0 else "Every paid job leaves a star review.")
 _button(Rect2(930,122,230,37),"RECEIPTS","reviews_view",CREAM,true,15)
 var season=Customers.season(sim)
 _text(Vector2(389,222),"%s  •  %s" % [str(season["name"]).to_upper(),season["note"]],15,BLUE,818)
 var list=Customers.reviews(sim)
 var pages=maxi(1,ceili(list.size()/6.0))
 customer_page=customer_page%pages
 if list.is_empty(): _text(Vector2(389,290),"No reviews yet. Deliver good work on time and customers will say so.",17,MUTED,818)
 for n in 6:
  var j=customer_page*6+n
  if j>=list.size(): break
  var r=list[j];var y=242+n*62
  _panel(Rect2(386,y,822,54),Color("fff8e1") if int(r["stars"])>=4 else Color("edf2f6"),Color("e6cf8a") if int(r["stars"])>=4 else Color("d0dbe6"),8)
  _text(Vector2(402,y+23),"★".repeat(int(r["stars"]))+"☆".repeat(5-int(r["stars"])),20,Color("e0a800"))
  _line(Vector2(530,y+22),"%s%s  •  %s  •  day %d" % [r["customer"],"  (regular)" if r.get("regular",false) else "",r["product"],int(r["day"])],15,BLUE,660,true)
  _line(Vector2(530,y+43),"\""+str(r["text"])+"\"",15,INK,660)
 var regulars=Customers.regulars(sim)
 _line(Vector2(389,627),"REGULARS (tip 10% on good work, wait longer): "+(", ".join(regulars) if not regulars.is_empty() else "none yet. A customer's fourth paid job makes them a regular."),14,INK,818)
 var rival=People.rival(sim)
 if not rival.is_empty():
  var rival_text="RIVAL: %s  ★ %.1f  •  " % [rival["name"],float(rival["rating"])]
  if rival["beaten"]: rival_text+="You are the top shop in town."
  elif People.ahead(sim): rival_text+="You are ahead (%d / %d days to win the town)." % [int(rival["streak"]),People.BEAT_DAYS]
  else: rival_text+="They win one inquiry a day until your rating (5+ reviews) beats theirs. Lost so far: %d." % int(rival["lost"])
  _line(Vector2(389,665),rival_text,14,Color("b03a2e") if not People.ahead(sim) else BLUE,818,true)
 _button(Rect2(389,703,397,48),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,703,406,48),"PAGE %d / %d  >" % [customer_page+1,pages],"more_customers",CREAM,pages>1)

func _customers_panel() -> void:
 if reviews_view and Customers.active(sim): _reviews_panel();return
 _header("CUSTOMERS + RECEIPTS","Inquiries, production commitments and paid jobs. Clock paused while this book is open.")
 if Customers.active(sim): _button(Rect2(930,122,230,37),"REVIEWS  ★ %.1f" % Customers.rating(sim) if Customers.review_count(sim)>0 else "REVIEWS","reviews_view",CYAN,true,15)
 var rows=[]
 for i in sim.state["orders"].size():
  if sim.order(i)["stage"] not in ["completed","declined","abandoned"]: rows.append(i)
 for i in range(sim.state["orders"].size()-1,-1,-1):
  if sim.order(i)["stage"] in ["completed","declined","abandoned"]: rows.append(i)
 var pages=maxi(1,ceili(rows.size()/4.0))
 customer_page=customer_page%pages
 for n in 4:
  var j=customer_page*4+n
  if j>=rows.size(): break
  var i=rows[j]
  var o=sim.order(i)
  var y=215+n*112
  _panel(Rect2(386,y,822,99),Color("edf5ff"),Color("d0e1f6"),8)
  _product(o["type"],Vector2(426,y+45),43)
  _line(Vector2(468,y+26),str(o["customer"])+("   ★ REGULAR" if Customers.is_regular(sim,str(o["customer"])) else ""),20,BLUE,490,true)
  _text(Vector2(468,y+52),"%d %s  •  %s" % [o["quantity"],o["product"],_stage(o["stage"])],15,INK,495)
  var detail=_customer_detail(o)
  if o["stage"]=="completed": detail="Paid $%d  •  Satisfaction %d%%" % [o.get("payment",o["reward"]),o.get("satisfaction",o["quality"])]
  if o["stage"]=="completed" and o.has("review"): detail+="  •  "+"★".repeat(int(o["review"]["stars"]))+("  •  tip $%d" % int(o["tip"]) if int(o.get("tip",0))>0 else "")
  elif o["stage"]=="intake" and sim.customer_patience(o)>=0: detail+="  •  %d shop minutes to respond" % ceili(sim.customer_patience(o)*60)
  _line(Vector2(468,y+80),detail,15,MUTED,495)
  _button(Rect2(1000,y+26,190,47),"RECEIPT" if o["stage"]=="completed" else "VIEW JOB","order:%d" % i,CYAN,true,16)
 _button(Rect2(389,703,397,48),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,703,406,48),"PAGE %d / %d  >" % [customer_page+1,pages],"more_customers",CREAM,pages>1)

func _customer_detail(o:Dictionary) -> String:
 if o["stage"]=="scheduled":
  if o["id"]=="DTF-001" and not sim.state["machines"].has("dtf") and not sim.state["machines"].has("dtfmini") and (sim.state["machines"].has("sticker") or sim.state["machines"].has("cutter")):
   return "First inquiry adapts to your starter printer"
  var required={"transfer":["dtf"],"apparel":["dtf","heat"],"sticker":["sticker"],"banner":["banner"],"cnc":["cnc"],"decal":["cutter"],"mug":["mug"],"hat":["embroidery"]}.get(o["type"],[])
  var missing=[]
  for id in required:
   if id=="dtf" and (sim.state["machines"].has("dtfmini") or (o["type"]=="apparel" and sim.state["machines"].has("cutter"))): continue
   if not sim.state["machines"].has(id): missing.append({"dtf":"DTF line or desktop DTF","heat":"heat press","sticker":"sticker station","banner":"banner printer","cnc":"CNC cutter","cutter":"vinyl cutter","mug":"mug press","embroidery":"embroidery machine"}.get(id,id))
  if not missing.is_empty(): return "Available after adding "+" + ".join(missing)
  if o.has("campaign"): return "Campaign inquiry expected in %d shop minutes" % maxi(0,ceili((float(o["visit"]["arrival_at"])-sim.now())*60))
  return "Expected after the shop clock resumes"
 return sim.customer_status(o)

func _route_progress(o:Dictionary) -> float:
 return {"intake":0.0,"preflight":0.07,"revision":0.1,"plan":0.17,"queued":0.25,"waiting_stock":0.2,"batch_wait":0.4,"production":0.4,"press":0.52,"pressing":0.59,"qc":0.66,"inspecting":0.73,"fault":0.7,"pack":0.8,"packing":0.86,"ready":0.92,"delivering":0.96,"completed":1.0}.get(o["stage"],0.0)

func _tutorial_index() -> int:
 for i in sim.state["orders"].size():
  if sim.order(i)["id"]==sim.state["tutorial_order"]: return i
 return -1

func _tutorial_hint(o:Dictionary) -> String:
 if o["type"]=="decal":
  var d={"plan":"Approve the cut file and queue the vinyl.","queued":"Work this job: Sam walks to the vinyl cutter.","production":"Watch the cutter cut, weed and tape the decals.","pack":"Pack your finished decals."}
  if d.has(o["stage"]): return d[o["stage"]]
 if o["stage"]=="queued" and sim.machine_for(o)=="dtfmini": return "Work this job: Sam walks to the desktop DTF kit."
 if C.is_htv(o):
  var t={"plan":"Approve the mirrored vinyl cut and queue it.","queued":"Work this job: Sam walks to the vinyl cutter.","production":"Watch Sam cut and weed the heat-transfer vinyl.","press":"Take the vinyl and blank shirts to the heat press.","pressing":"Sam presses the vinyl onto the shirts, then peels it warm.","inspecting":"Checking every pressed shirt.","packing":"Folding and boxing the shirts.","ready":"Hand the box over at the pickup counter.","delivering":"The customer is paying for their shirts.","qc":"Check the pressed shirts at the inspection bench.","pack":"Fold and pack the finished shirts.","completed":"Paid! Keep selling shirts to unlock the desktop DTF kit."}
  if t.has(o["stage"]): return t[o["stage"]]
 return {"intake":"Accept the %d-%s order." % [o["quantity"],o["product"]],"preflight":"Check artwork and fix the background.","plan":"Open the gang sheet and auto-pack designs.","queued":"Work this job: Sam walks to the DTF line.","production":"Watch film print, powder, cure and wind.","qc":"Take output to the inspection bench.","pack":"Cut / roll and pack your finished transfers.","ready":"Deliver the box at the pickup counter.","completed":"Paid! Try stickers, then buy an upgrade."}.get(o["stage"],"Follow the highlighted next step in this job.")

func _modal() -> void:
 record_modal_text=true;modal_accessible_text=[];layout_text=[]
 buttons.clear();semantic_buttons.clear()
 draw_rect(Rect2(-ui_offset,_screen_size()),Color(0.015,0.055,0.14,0.42))
 match modal:
  "cash_bridge":_cash_bridge_panel()
  "studio":Studio.draw(self)
  "artwork":Art.draw(self)
  "workshop": Workshop.draw(self)
  "intervention": _intervention_panel()
  "marketing": _marketing_panel()
  "merch": _merch_panel()
  "capacity": _capacity_panel()
  "difficulty": _difficulty_panel()
  "roster": _roster_panel()
  "accessibility": _accessibility_panel()
  "updates": _updates_panel()
  "welcome_gift": _welcome_gift_panel()
  "customers": _customers_panel()
  "order": _order_panel()
  "machine": _machine_panel()
  "dtf_views": _dtf_views_panel()
  "equipment": _equipment_panel()
  "gang": _gang_panel()
  "staff": _staff_panel()
  "stock": _stock_panel()
  "move": _move_panel()
  "report": _report_panel()
  "settings": _settings_panel()
  "help": _help_panel()
  "goals": _goals_panel()
  "levelup": _levelup_panel()
  "ending": _ending_panel()
  "confirm_new": _new_panel()
  "confirm_demo":
   _header("RESET THE DEMO SHOP?","Your current demo will be archived. Your career is unchanged.")
   _text(Vector2(389,284),"Start the supplied demo shop again with equipment, staff and $5,000.\nThis resets demo progress only.",21,INK,810)
   _button(Rect2(389,425,818,54),"RESET DEMO SHOP","reset_demo_confirm",YELLOW)
   _button(Rect2(389,505,818,48),"KEEP PLAYING","close",NAVY)
  "save_error": _save_error_panel()
 record_modal_text=false
 # The workshop draws its own latest notice; other panels get a strip directly under them.
 if modal_toast!="" and modal==modal_toast_modal and modal!="workshop" and Time.get_ticks_msec()<modal_toast_until:
  _panel(Rect2(355,793,890,38),Color("fff6d6"),YELLOW,9)
  _line(Vector2(372,818),modal_toast,16,INK,856)
 elif modal_toast!="":modal_toast=""

func _save_error_panel() -> void:
 _header("YOUR SHOP IS STILL OPEN","Saving did not finish. Your current progress is still in this session.")
 _text(Vector2(389,286),sim.last_save_error,20,RED,810)
 _text(Vector2(389,348),"Check that the save folder is available and your disk has free space.",20,INK,810)
 _text(Vector2(389,390),"Then retry, or return to the shop without closing the game.",20,INK,810)
 _button(Rect2(389,535,396,60),"RETRY SAVE","retry_save",GREEN,true,23)
 _button(Rect2(801,535,406,60),"KEEP PLAYING","close",CREAM,true,23)

func _header(title:String,subtitle:String="") -> void:
 _panel(Rect2(355,105,890,680),CREAM,BLUE,18)
 var title_size=32
 while title_size>22 and bold.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>535: title_size-=1
 _text(Vector2(389,151),title,title_size,BLUE,535,true)
 _text(Vector2(389,182),subtitle,17,MUTED,810)
 if modal!="report": _button(Rect2(1180,122,42,37),"X","close",NAVY,true,20)
 if modal in ["order","machine","staff"]:
  _button(Rect2(930,122,230,37),"RESUME CLOCK" if sim.state["paused"] else "PAUSE CLOCK", "pause",NAVY,true,16)
 elif screen=="shop": _text(Vector2(968,146),"CLOCK HELD BY MENU",14,BLUE)

func _order_panel() -> void:
 var o=sim.order(selected_order)
 if o.is_empty(): modal=""; return
 _header("%d %s" % [o["quantity"],o["product"]],o["customer"]+(" • RETURNING CUSTOMER" if o.get("returning",false) else "")+(" • WHOLESALE" if o.get("wholesale",false) else ""))
 _product(o["type"],Vector2(1160,249),73)
 _text(Vector2(389,233),("$%d  •  "+("Proposed" if o["stage"]=="intake" else "Committed")+" %s  •  %s") % [roundi(o["reward"]*(0.76 if o.get("quality_accepted",false) else 1.0)),_due(o),o["fulfillment"].to_upper()] if o["stage"]!="scheduled" else "$%d  •  Deadline starts when the customer arrives" % o["reward"],22,INK)
 _text(Vector2(389,266),_stage(o["stage"])+"  •  "+sim.customer_status(o),18,RED if o["stage"]=="fault" else BLUE,710,true)
 var routes={"mug":"ART CHECK > PRINT TRANSFERS > WRAP MUGS > MUG PRESS > QC > PACK","hat":"DIGITIZE ART > HOOP CAPS > STITCH > TRIM THREADS > QC > PACK","decal":"ART CHECK > VINYL CUT > WEED > TRANSFER TAPE > QC > PACK","transfer":"ART > GANG SHEET > CMYK + WHITE > POWDER > CURE > TAKE-UP > QC > PACK","apparel":"ART > DTF TRANSFER > GARMENT BLANKS > HEAT PRESS / PEEL > QC > PACK","sticker":"BLEED / CUT PATH > PRINT > LAMINATE > REGISTRATION > CONTOUR CUT > QC","banner":"MEDIA WIDTH > WIDE PRINT > TRIM / GROMMETS > INSPECT > PACK > SHIP","cnc":"TOOLPATH > PANEL / TOOL PRESET > LOAD > GANTRY CUT > UNLOAD > QC"}
 _panel(Rect2(385,287,823,53),Color("edf5ff"),Color("d0e1f6"),6)
 _text(Vector2(400,309),"ART CHECK > MIRRORED VINYL CUT > WEED > HEAT PRESS / PEEL > QC > PACK" if C.is_htv(o) else routes[o["type"]],15,INK,790)
 if o["type"] in ["sticker","apparel"] and o["stage"] in ["plan","queued","press"]:
  var timing_reason=Ops.qte_unavailable(sim,selected_order,"registration" if o["type"]=="sticker" else "press")
  _button(Rect2(1015,348,192,29),"OPTIONAL TIMING","intervene",CYAN,timing_reason=="",12)
  if timing_reason!="":_line(Vector2(1015,393),timing_reason,11,MUTED,192)
 _text(Vector2(389,375),"Artwork: %s  •  Physical design: %.1f x %.1f in" % ["ready" if o["art_ready"] else "needs a fix",o["art_w"],o["art_h"]],18,INK)
 var recipe=C.recipe(o)
 var used=[]
 for key in recipe: used.append("%s %d" % [key,recipe[key]])
 _text(Vector2(389,409),"Material estimate: "+", ".join(used),16,MUTED,800)
 var revenue=o.get("payment",o["reward"]) if o["stage"]=="completed" else roundi(o["reward"]*(.76 if o.get("quality_accepted",false) else 1))
 var spent=float(o["material_cost"])
 if o["stage"] in ["completed","abandoned","declined"]:
  _text(Vector2(389,454),"Materials used: $%.0f   •   Contribution: $%.0f before overhead and wages" % [spent,revenue-spent],17,INK,810)
 else:
  var estimate=_material_estimate(selected_order,o)
  _text(Vector2(389,446),"Estimated materials: $%.0f   •   Expected contribution: $%.0f before overhead and wages" % [estimate,revenue-estimate],16,INK,810)
  _text(Vector2(389,467),"Used so far: $%.0f of materials. Daily overhead and wages are charged at day close." % spent,13,MUTED,810)
 var stage=o["stage"]
 var pos=Vector2(389,493)
 match stage:
  "intake":
   var normal=sim.quote(selected_order,false,_preview_board());var rush=sim.quote(selected_order,true,_preview_board())
   var due_text="Normal %s / Rush %s" % [_due({"due":normal.get("due",sim.now())}),_due({"due":rush.get("due",sim.now())})]
   _text(pos,due_text,16,INK,805)
   _button(Rect2(389,522,246,51),"ACCEPT ORDER","accept",GREEN,normal.get("valid",false))
   _button(Rect2(650,522,272,51),"ACCEPT RUSH +30%","rush",YELLOW,rush.get("valid",false),18)
   _button(Rect2(938,522,269,51),"DECLINE","decline",CREAM)
   _text(Vector2(389,607),"Materials $%.0f / Normal pays $%d / Rush pays $%d / %s" % [normal.get("cost",0),normal.get("payout",0),rush.get("payout",0),normal.get("risk","BLOCKED")],17,BLUE,805)
   _text(Vector2(389,645),"One rush premium per day. "+(normal["reason"] if not normal["valid"] else "Review capacity, supplies and finish estimate."),16,MUTED,805)
   _button(Rect2(389,665,818,29),"VIEW COMMITMENT FORECAST","capacity",CREAM,true,14)
  "preflight":
   _text(pos,{"mug":"Check the wrap size, colours and handle side.","hat":"Check the stitch file, thread colours and cap position.","decal":"Check decal size, vinyl color and weeding detail.","transfer":"Check size, transparency, white layer and film layout.","apparel":"Check transfer size, garment quantities and cotton press preset.","sticker":"Check bleed, cut path and registration marks.","banner":"Check final banner dimensions, roll width and finishing allowance.","cnc":"Check panel dimensions, material and cutter toolpath."}[o["type"]],17,INK,805)
   _button(Rect2(389,522,396,51),"APPROVE ARTWORK" if o["art_ready"] else "REPAIR ARTWORK  $30","preflight",GREEN)
   _button(Rect2(801,522,406,51),"REQUEST CUSTOMER REVISION","revision",CREAM)
  "revision": _text(pos,"Corrected artwork arrives in %d shop minutes." % maxi(0,ceili((o["revision_eta"]-sim.now())*60)),19,BLUE)
  "plan":
   var feedback=sim.preset_feedback(o)
   var mixed_route=o["type"] in ["transfer","apparel"] and o.get("method",sim.shirt_method(o))!="htv"
   _line(Vector2(389,638 if o["type"]=="sticker" else (590 if mixed_route else 606)),feedback["text"],15,RED if feedback["warning"] else BLUE,810)
   if o["type"] in ["transfer","apparel"] and o.get("method",sim.shirt_method(o))!="htv":
    var batch=sim.batch_preview(selected_order)
    _button(Rect2(389,610,818,34),"MIXED BATCH: SAVE %d FT FILM" % batch.get("saved",0) if batch["valid"] else "BATCH: "+batch.get("reason","No match"),"batch",CREAM,batch["valid"],14)
   if o["type"] in ["transfer","apparel"] and o.get("method",sim.shirt_method(o))!="htv":
    _button(Rect2(389,511,396,54),"OPEN GANG SHEET","gang",CYAN)
    _button(Rect2(801,511,406,54),"WHITE: "+o["settings"]["white"].to_upper(),"white",CREAM)
   elif o["type"]=="apparel": _button(Rect2(389,512,818,51),"APPROVE MIRRORED VINYL CUT + QUEUE","queue",GREEN)
   elif o["type"]=="sticker":
    _button(Rect2(389,504,256,43),"LAMINATE: "+("ON" if o["settings"]["laminate"] else "OFF"),"laminate",CREAM,true,16)
    _button(Rect2(660,504,259,43),"MARKS: "+("ALIGNED" if o["settings"]["registration"] else "SKIP"),"registration",CREAM,true,16)
    _button(Rect2(936,504,272,43),"CUT: "+o["settings"]["cut"].to_upper(),"cut",CREAM,true,16)
    _button(Rect2(389,564,818,51),"APPROVE PRESET + QUEUE","queue",GREEN)
   elif o["type"]=="cnc":
    _button(Rect2(389,512,397,49),"PANEL / TOOL: "+o["settings"]["media"],"media",CREAM)
    _button(Rect2(801,512,406,49),"APPROVE TOOLPATH + QUEUE","queue",GREEN)
   elif o["type"]=="mug": _button(Rect2(389,512,818,51),"APPROVE MUG WRAP + QUEUE","queue",GREEN)
   elif o["type"]=="hat": _button(Rect2(389,512,818,51),"APPROVE STITCH FILE + QUEUE","queue",GREEN)
   elif o["type"]=="decal": _button(Rect2(389,512,818,51),"APPROVE CUT FILE + QUEUE VINYL","queue",GREEN)
   else: _button(Rect2(389,512,818,51),"SELECT 36-IN MEDIA + QUEUE PRINT","queue",GREEN)
  "queued","waiting_stock","press","qc","pack","ready":
   var m=sim.machine_for(o)
   _text(pos,"Next station: "+sim.state["machines"].get(m,{"title":"Place "+m+" first"})["title"],21,BLUE)
   var ready_to_work=stage!="ready" or sim.customer_ready_for_handoff(o)
   _button(Rect2(389,522,396,54),"WORK THIS JOB AS SAM" if ready_to_work else "WAITING FOR CUSTOMER","work",GREEN,ready_to_work)
   _button(Rect2(801,522,406,54),"ENABLE OWNER AUTO ASSIST","assist_order",CYAN)
   if stage=="queued": _button(Rect2(389,592,396,40),"PRIORITIZE THIS JOB","priority",CREAM,true,16)
   if stage=="press":
    _button(Rect2(389,592,818,43),"PRESET: "+("COTTON / WARM PEEL" if o["settings"]["press"]=="cotton_warm" else "POLY / COLD PEEL"),"press_preset",CREAM,true,17)
    _text(Vector2(389,664),"Navy blanks needed S%d / M%d / L%d • Stock S%d / M%d / L%d" % [o["garments"].get("navy:S",0),o["garments"].get("navy:M",0),o["garments"].get("navy:L",0),sim.state["garments"].get("navy:S",0),sim.state["garments"].get("navy:M",0),sim.state["garments"].get("navy:L",0)],17,INK)
  "prepress","production","pressing","inspecting","packing","delivering":
   var m=sim.state["machines"][o["route_machine"]]
   _text(pos,m["phase"],22,BLUE,-1,true)
   _panel(Rect2(389,515,818,20),Color("c5d8ed"),Color("c5d8ed"),6)
   draw_rect(Rect2(389,515,818*sim.machine_progress(o["route_machine"]),20),CYAN)
   _text(Vector2(389,575),"Your worker is operating the station. Close this panel to watch.",18,INK)
  "fault":
   _text(pos,"Visible issue: "+o["issue"],19,RED,800)
   _button(Rect2(389,557,396,54),"REPRINT INPUTS $%.0f" % sim.reprint_cost(o),"reprint",GREEN,true,19)
   _button(Rect2(801,557,406,54),"ACCEPT 76% PAYMENT","downgrade",YELLOW)
  "completed":
   _text(pos,"PAYMENT RECEIVED  $%d" % o.get("payment",o["reward"]),25,GREEN,-1,true)
   _text(pos+Vector2(0,39),"Customer satisfaction %d%%  •  Quality %d%%" % [o.get("satisfaction",o["quality"]),o["quality"]],21,INK)
   _text(pos+Vector2(0,75),"Order %s  •  Reprints %d  •  Fulfillment complete" % [o["id"],o["reprints"]],17,MUTED,800)
   _button(Rect2(389,628,818,46),"REQUEST REPEAT WITH APPROVED ARTWORK","repeat",CYAN,true,17)
  "batch_wait": _text(pos,"This customer's designs are on a shared sheet. Printing completes with the batch; finishing and payment remain individual.",20,BLUE,800)
  "scheduled": _text(pos,_customer_detail(o)+".\nFinish setup, then resume the shop clock.",19,INK,800)
  "abandoned": _text(pos,"The customer left before a quote was accepted. No payment was taken.",19,MUTED,800)
  "declined": _text(pos,"This order was declined.",21,MUTED)
 if Art.eligible(sim,selected_order) or not o.get("artwork_offer",{}).is_empty():_button(Rect2(389,665,818,29),"REVIEW CUSTOMER ARTWORK CHANGE","artwork_offer",CREAM,true,14)
 _button(Rect2(389,703,397,48),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,703,406,48),"VIEW MATERIAL STOCK","stock",CREAM)

func _machine_panel() -> void:
 var m=sim.state["machines"].get(selected_machine,{})
 if m.is_empty(): modal=""; return
 _header(m["title"].to_upper(),"Queue, operator, condition and consumables")
 _text(Vector2(389,233),"CONDITION  %d%%" % m["condition"],22,GREEN if m["condition"]>=70 else RED,-1,true)
 _text(Vector2(389,271),"Operator: "+("available qualified staff" if m["worker"]=="auto" else sim.worker(m["worker"]).get("name","Sam")),20,INK)
 _button(Rect2(817,235,391,44),"CYCLE OPERATOR","assign_cycle",CREAM)
 var live=sim.station_activity(selected_machine)
 _text(Vector2(389,319),"Current action: "+live["phase"]+" / "+live["operator"],18,BLUE,810)
 if m["kind"] in ["dtf","shaker"]:
  _text(Vector2(389,355),"%d-in film width • Straight printer > shaker > low front take-up" % m["width"],18,INK)
  _text(Vector2(389,394),"Film %d ft  /  White %d  /  Powder %d" % [sim.state["stock"]["film"],sim.state["stock"]["white"],sim.state["stock"]["powder"]],19,MUTED)
  _button(Rect2(969,370,239,40),"EQUIPMENT VIEWS","dtf_views",CREAM,true,16)
 elif m["kind"]=="cnc": _text(Vector2(389,355),"Rigid stock %d panels • PVC / ACM compatible tool presets" % sim.state["stock"]["rigid"],19,INK)
 elif m["kind"]=="heat": _text(Vector2(389,355),"Finished apparel only. Transfer orders skip this station.",19,INK)
 elif m["kind"]=="cutter": _text(Vector2(389,355),"Shirt vinyl %d ft  /  Decal vinyl %d ft  /  Tape %d ft  •  Cut and weed shirts and decals" % [sim.state["stock"].get("htv",0),sim.state["stock"].get("vinyl",0),sim.state["stock"].get("transfer_tape",0)],18,INK)
 elif m["kind"]=="mug": _text(Vector2(389,355),"Blank mugs %d  /  Transfer paper %d  •  Print, wrap and press mugs and tumblers" % [sim.state["stock"].get("mugs",0),sim.state["stock"].get("subpaper",0)],18,INK)
 elif m["kind"]=="embroidery": _text(Vector2(389,355),"Blank caps %d  /  Thread %d cones  •  Hoop, stitch and trim embroidered hats" % [sim.state["stock"].get("caps",0),sim.state["stock"].get("thread",0)],18,INK)
 elif m["kind"]=="dtfmini": _text(Vector2(389,355),"Film %d ft  /  White %d  /  Powder %d  •  Desktop: slower than the full line" % [sim.state["stock"]["film"],sim.state["stock"]["white"],sim.state["stock"]["powder"]],19,INK)
 elif m["kind"]=="storage": _text(Vector2(389,355),"Storage receives delivered supplies. Check forecast before ordering.",19,INK)
 else: _text(Vector2(389,355),"Prepared jobs wait for a free operator and the correct stock.",19,INK)
 var station=selected_machine
 if m["kind"]=="shaker": station="dtf2" if selected_machine=="shaker2" else "dtf"
 var jobs=[]
 for i in sim.active_orders():
  var o=sim.order(i)
  var target=sim.machine_for(o)
  if target==station or (sim.dtf_family(target) and sim.dtf_family(station)): jobs.append(i)
 _text(Vector2(389,445),"WAITING / ACTIVE JOBS",20,BLUE,-1,true)
 for n in mini(jobs.size(),3):
  var o=sim.order(jobs[n])
  _button(Rect2(389,459+n*43,818,36),"%d %s  •  %s" % [o["quantity"],o["product"],_stage(o["stage"])],"order:%d" % jobs[n],CREAM,true,16)
 _button(Rect2(389,612,258,48),"GO + WORK NEXT JOB","work_station",GREEN)
 _button(Rect2(664,612,256,48),"CLEAN / CALIBRATE","maintain",CYAN)
 _button(Rect2(938,612,269,48),"MOVE EQUIPMENT","move_equipment",CREAM)
 _button(Rect2(389,703,397,48),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,703,406,48),"RESTOCK / DELIVERIES","stock",CREAM)

func _equipment_panel() -> void:
 _header("ADD EQUIPMENT","Choose a station, then click the shop floor. Cash: $%d" % sim.state["cash"])
 var ids=["cutter","heat","dtfmini","mug","sticker","dtf","embroidery","art","finish","pack","storage","banner","cnc","dock"]
 var titles={"cutter":"VINYL CUTTER BENCH","mug":"MUG + TUMBLER PRESS","embroidery":"EMBROIDERY MACHINE","dtfmini":"DESKTOP DTF KIT","dtf":"DTF PRINTER + SHAKER","sticker":"STICKER PRINT / CUT","heat":"HEAT PRESS","art":"ARTWORK DESK","finish":"INSPECT / FINISH BENCH","pack":"PACKING / PICKUP BENCH","storage":"MATERIAL STORAGE","banner":"BANNER PRINTER","cnc":"CNC FLATBED","dock":"SHIPPING DOCK"}
 for n in range(equipment_page*5,mini(equipment_page*5+5,ids.size())):
  var id=ids[n]
  var y=220+(n%5)*83
  var station=C.catalog_station(id)
  _illustrated_icon(id,Rect2(394,y-12,90,68))
  _text(Vector2(500,y+10),titles[id],21,BLUE,-1,true)
  var price=C.EQUIPMENT_PRICES[id]
  var blurb={"dock":"  •  Loading bay at an open door; the truck parks outside","mug":"  •  Printed mugs and tumblers","embroidery":"  •  Embroidered hats","cutter":"  •  Vinyl shirts (with a heat press) + decals","dtfmini":"  •  Transfers + shirts. Slower than the full DTF line"}.get(id,"")
  if sim.equipment_locked(id): blurb="  •  Unlocks at shop level %d" % int(Progress.UNLOCK_LEVEL[id])
  _text(Vector2(500,y+37),("GIFT  •  FREE" if sim.is_gift(id) else ("Included starter bench" if price==0 else "$%d" % price))+blurb,17,GREEN if sim.is_gift(id) else MUTED)
  var installed=sim.state["machines"].has(id)
  Strategy.ensure(sim)
  var locked=id in ["banner","cnc","dock"] and (sim.state["location"]==1 or (int(sim.state["rules"]["version"])>0 and not sim.state["fit_out"]))
  if sim.equipment_locked(id) and not installed: _button(Rect2(989,y-9,218,49),"LEVEL %d" % int(Progress.UNLOCK_LEVEL[id]),"equipment",CREAM,false,15)
  else: _button(Rect2(989,y-9,218,49),"INSTALLED" if installed else (("PREMISES REQUIRED" if sim.state["location"]==1 else "FIT-OUT  $350") if locked else "PLACE"),"move" if locked else "place:"+id,CYAN if locked else GREEN,not installed and (locked or sim.state["cash"]>=sim.Ops.equipment_cost(sim,id)),15)
 _button(Rect2(389,710,397,43),"BACK TO SHOP","close",NAVY)
 var equipment_pages=ceili(ids.size()/5.0)
 _button(Rect2(801,710,406,43),("MORE EQUIPMENT  %d / %d" % [equipment_page+1,equipment_pages]) if equipment_page<equipment_pages-1 else "STARTER EQUIPMENT","equipment_page",CYAN)

func _dtf_views_panel() -> void:
 _header("DTF PRINTER + SHAKER","Approved illustrated equipment - 16 viewing angles")
 var texture:Texture2D=illustrated["dtf"][dtf_view_index]
 var box=Rect2(405,206,790,389)
 var size=Vector2(texture.get_width(),texture.get_height())
 size*=minf(box.size.x/size.x,box.size.y/size.y)
 draw_texture_rect(texture,Rect2(box.get_center()-size*0.5,size),false)
 for n in 16:
  _button(Rect2(389+(n%8)*103,610+(n/8)*43,96,37),"%s°" % (n*22.5),"dtf_view:%d" % n,CYAN if n==dtf_view_index else CREAM,true,15)
 _button(Rect2(389,710,818,43),"BACK TO EQUIPMENT","back_machine",NAVY)

func _gang_panel() -> void:
 var o=sim.order(selected_order)
 _header("KIWI SUITE GANG SHEET BUILDER","Drag designs • R rotates selected design • Physical sizes stay fixed")
 var size=Vector2(o["film_width"],o["sheet_length"])*GANG_SCALE
 _panel(Rect2(GANG_POS-Vector2(10,10),size+Vector2(20,20)),Color("f5f0e3"),BLUE,4)
 draw_rect(Rect2(GANG_POS,size),Color("fffdf8"))
 for x in range(0,int(o["film_width"])+1,2): draw_line(GANG_POS+Vector2(x*GANG_SCALE,0),GANG_POS+Vector2(x*GANG_SCALE,size.y),Color(0.08,0.3,0.5,0.10),1)
 for y in range(0,int(o["sheet_length"])+1,2): draw_line(GANG_POS+Vector2(0,y*GANG_SCALE),GANG_POS+Vector2(size.x,y*GANG_SCALE),Color(0.08,0.3,0.5,0.10),1)
 var area=0.0
 for n in o["gang"].size():
  var tile=o["gang"][n]
  var rect=Rect2(GANG_POS+Vector2(tile[0],tile[1])*GANG_SCALE,Vector2(tile[2],tile[3])*GANG_SCALE)
  draw_rect(rect,Color("fbe6f2"))
  draw_rect(rect,YELLOW if n==gang_selected else MAGENTA,false,3)
  _product("transfer",rect.get_center(),minf(rect.size.x,rect.size.y)*0.62)
  area+=tile[2]*tile[3]
 _text(Vector2(755,240),"%d x %d in film" % [o["film_width"],o["sheet_length"]],25,BLUE,-1,true)
 _text(Vector2(755,277),"Each design: %.1f x %.1f in" % [o["art_w"],o["art_h"]],18,INK)
 _text(Vector2(755,314),"Used area: %.1f%%" % (area/(o["film_width"]*o["sheet_length"])*100),22,GREEN)
 _text(Vector2(755,350),"%d designs / sheet • %d sheets needed" % [o["gang"].size(),ceili(float(o["quantity"])/maxi(1,o["gang"].size()))],18,INK)
 var recipe=C.recipe(o)
 _text(Vector2(755,387),"Film %d ft • White %d • Powder %d" % [recipe["film"],recipe["white"],recipe["powder"]],18,MUTED)
 _text(Vector2(755,423),"Nearest deadline: "+_due(o),18,INK)
 _button(Rect2(755,449,209,43),"AUTO-PACK","auto_pack",CYAN)
 _button(Rect2(981,449,226,43),"ADD / DUPLICATE","duplicate",CREAM)
 _button(Rect2(755,509,209,43),"ROTATE DESIGN","rotate",CREAM)
 _button(Rect2(981,509,226,43),"CLEAR SHEET","clear_gang",CREAM)
 _text(Vector2(755,594),"Overlaps and out-of-bounds drops revert.\nOne valid sheet repeats until the order count is met.",17,INK,445)
 _button(Rect2(389,703,397,48),"BACK TO ORDER","back_order",NAVY)
 _button(Rect2(801,703,406,48),"APPROVE SHEET + QUEUE","queue",GREEN,sim.gang_valid(selected_order,o["gang"]))

func _gang_press(p:Vector2) -> void:
 var o=sim.order(selected_order)
 for n in range(o["gang"].size()-1,-1,-1):
  var tile=o["gang"][n]
  if Rect2(GANG_POS+Vector2(tile[0],tile[1])*GANG_SCALE,Vector2(tile[2],tile[3])*GANG_SCALE).has_point(p): gang_drag=n; gang_selected=n; gang_before=tile.duplicate(); return

func _rotate_gang() -> void:
 var o=sim.order(selected_order)
 if gang_selected<0 or gang_selected>=o["gang"].size(): return
 var tile=o["gang"][gang_selected]
 var old=tile.duplicate()
 var width=tile[2]; tile[2]=tile[3]; tile[3]=width
 if not sim.gang_valid(selected_order,o["gang"]): o["gang"][gang_selected]=old; status="Rotated artwork does not fit here. Move it or auto-pack first."

func _staff_panel() -> void:
 _header("STAFF + SHOP UPGRADES","Hire specialists. Drag a worker onto a station to assign them.")
 var page=staff_page%2
 _button(Rect2(389,206,396,43),"HIRING + ASSIGNMENTS","staff_hiring",CYAN if page==0 else CREAM)
 _button(Rect2(801,206,406,43),"EQUIPMENT + TRAINING","staff_upgrades",CYAN if page==1 else CREAM)
 if page==0:
  for i in C.ROLES.size():
   var y=270+i*53
   _text(Vector2(389,y+27),C.ROLES[i],20,INK)
   _text(Vector2(688,y+27),"$%d / $45 day" % C.HIRE_COST[i],17,MUTED)
   _button(Rect2(1002,y,206,43),"HIRE "+C.NAMES[i],"hire:%d" % i,GREEN,sim.state["cash"]>=C.HIRE_COST[i] and sim.state["workers"].size()<sim.staff_cap() and sim.hiring_buffer(i),16)
  var team_note="" if sim.state["workers"].size()<sim.staff_cap() else " "+sim.staff_cap_reason()
  _text(Vector2(389,677),("Team %d / %d. Daily bills $%.0f." % [sim.state["workers"].size(),sim.staff_cap(),sim.daily_obligations()])+(team_note if team_note!="" else " Hiring requires the fee plus the next day's bill buffer."),16,INK,808)
 else:
  var upgrades=[["auto_feeder","AUTO FEEDER",350,"30% faster printing on both DTF lanes."],["training","STAFF TRAINING",400,"25% faster work for Sam and current / future staff."],["quality_sensor","QUALITY SENSORS",450,"Detect risky ink / registration presets before starting."]]
  for i in 3:
   var row=upgrades[i]
   var y=274+i*115
   _panel(Rect2(389,y,818,100),Color("edf5ff"),Color("c5d8ee"),8)
   _text(Vector2(409,y+30),"%s / $%d" % [row[1],row[2]],23,BLUE,-1,true)
   _text(Vector2(409,y+65),row[3],17,INK,548)
   var owned=sim.state["upgrades"][row[0]]
   _button(Rect2(1020,y+24,166,51),"INSTALLED" if owned else "BUY","upgrade:"+row[0],GREEN,not owned,17)
  _text(Vector2(389,652),"Bigger rooms unlock through fulfilled jobs, quality, trust and cash.",18,INK)
 _button(Rect2(389,703,397,48),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,703,406,48),"TEAM TASKS + COSTS","roster",CYAN)

func _team_names() -> String:
 var names=[]
 for w in sim.state["workers"]: names.append(w["name"])
 return ", ".join(names)

func _stock_panel() -> void:
 _header("SUPPLIES + DELIVERIES","Production uses owned stock; purchases arrive after a visible lead time.")
 # The core supplies, then whatever the installed machines need.
 var keys=["film","white","powder","sticker","laminate","packaging","maintenance"]
 if sim.state["machines"].has("banner") or sim.state["location"]==2: keys.append("banner")
 if sim.state["machines"].has("cnc") or sim.state["location"]==2: keys.append("rigid")
 if sim.state["machines"].has("cutter"): keys.append_array(["htv","vinyl","transfer_tape"])
 if sim.state["machines"].has("mug"): keys.append_array(["mugs","subpaper"])
 if sim.state["machines"].has("embroidery"): keys.append_array(["caps","thread"])
 var row_gap=44 if keys.size()<=9 else floori(392.0/keys.size())
 var row_h=mini(35,row_gap-3)
 var f=sim.forecast()
 for i in keys.size():
  var key=keys[i]
  var y=215+i*row_gap
  _text(Vector2(389,y+26),{"htv":"Heat-transfer vinyl","mugs":"Blank mugs","subpaper":"Sublimation paper","caps":"Blank caps","thread":"Embroidery thread"}.get(key,key.capitalize()),19 if row_gap>=36 else 16,INK,160)
  _text(Vector2(555,y+26),"%d %s" % [sim.state["stock"][key],C.UNITS[key]],16,MUTED)
  _text(Vector2(770,y+26),"Queue needs %d" % f["required"].get(key,0),16,RED if f["shortages"].has(key) else BLUE)
  var qty={"film":48,"white":60,"powder":40,"sticker":60,"laminate":40,"banner":30,"rigid":12,"packaging":25,"maintenance":5,"vinyl":24,"transfer_tape":24,"htv":24,"mugs":24,"subpaper":20,"caps":24,"thread":8}[key]
  _button(Rect2(1001,y,206,row_h),"+%d / $%d" % [qty,ceili(qty*C.PRICES[key])],"restock:"+key,CREAM,true,16 if row_h>=33 else 14)
 _button(Rect2(389,618,262,42),"TEES S/M/L +6 EACH  $72","garments",CYAN,true,13)
 _button(Rect2(659,618,262,42),"HOODIES S/M/L +3  $81","hoodies",CYAN,true,13)
 _button(Rect2(929,618,278,42),"TOTE BAGS +12  $30","totes",CYAN,true,13)
 _button(Rect2(389,666,262,32),"CMYK INK +40 EACH  $64","ink",CYAN,true,13)
 var deliveries=[]
 for d in sim.state["deliveries"]: deliveries.append("%s: %d min" % [sim.missing_all(d["items"]),maxi(0,ceili((d["eta"]-sim.now())*60))])
 _line(Vector2(667,688),"Incoming: "+("none" if deliveries.is_empty() else "; ".join(deliveries)),15,INK,540)
 _button(Rect2(389,714,818,42),"BACK TO SHOP","close",NAVY)

func _move_panel() -> void:
 Strategy.ensure(sim)
 if int(sim.state["rules"]["version"])>0:
  _growth_panel();return
 _header("YOUR NEXT PRINT SHOP","Unlock the industrial garage by running a reliable neighborhood business.")
 var p=sim.garage_progress()
 var lines=[["Cash available",p["cash"],1500,"$"],["Customer trust",p["trust"],60,"%"],["Orders fulfilled",p["orders"],3,""],["On-time delivery",p["on_time"],75,"%"],["Average quality",p["quality"],85,"%"]]
 for i in lines.size():
  var row=lines[i]; var y=229+i*63
  _text(Vector2(389,y),row[0],22,INK)
  _text(Vector2(893,y),"%.0f / %d%s" % [row[1],row[2],row[3]],22,GREEN if row[1]>=row[2] else MUTED)
  draw_rect(Rect2(389,y+15,818,7),Color("d0deed"))
  draw_rect(Rect2(389,y+15,818*clampf(float(row[1])/float(row[2]),0,1),7),GREEN if row[1]>=row[2] else CYAN)
 _text(Vector2(389,578),"Move costs $900 after goals are met. The garage adds a second DTF line,\na wide-format printer, a large CNC cutter, and a working shipping dock.",19,INK,804)
 _button(Rect2(389,659,818,49),"MOVE TO INDUSTRIAL SHOP  $900","move_garage",YELLOW,p["ready"] and sim.state["location"]==1)
 _button(Rect2(389,723,818,37),"BACK TO SHOP","close",NAVY)

func _report_panel() -> void:
 var report=sim.end_day()
 var s=report["stats"]
 _header("DAY %d • SHOP ACCOUNTS" % report["day"],"Inventory costs reflect actual use; reprint waste is included in material cost.")
 var rows=[["Sales collected",s["sales"]],["Materials used",-s["materials"]],["Artwork fees",-s["art_fees"]],["Marketing campaigns",-s.get("marketing",0)],["Staff wages",-s["wages"]],["Rent / utilities",-s["overhead"]],["NET PROFIT",report["net"]]]
 for i in rows.size():
  var y=239+i*48
  _text(Vector2(389,y),rows[i][0],24,BLUE if i==6 else INK,-1,i==6)
  _text(Vector2(1000,y),"$%.0f" % rows[i][1],24,GREEN if rows[i][1]>=0 else RED,-1,i==6)
 var ontime=100.0 if s["delivered"]==0 else s["on_time"]*100.0/s["delivered"]
 var quality=100.0 if s["delivered"]==0 else float(s["quality"])/s["delivered"]
 _button(Rect2(389,548,818,28),"CASH BRIDGE / PURCHASES / DEBT PAYMENTS","cash_bridge",CREAM,true,13)
 _text(Vector2(389,597),"Delivered %d • On time %.0f%% • Quality %.0f%% • Open jobs %d" % [s["delivered"],ontime,quality,report["open"]],19,INK)
 _text(Vector2(389,633),"Waste $%.0f / recovery $%d / loan $%d / equipment payment $%d" % [s["waste"],s.get("recovery",0),s.get("loan_payment",0),s.get("equipment_finance",0)],17,MUTED,810)
 _text(Vector2(389,668),"Cash now $%.0f / after daily bills $%.0f. Inventory use is not charged twice." % [report.get("cash_before_bills",sim.state["cash"]),report.get("cash_after_bills",sim.state["cash"])],17,BLUE,810)
 _button(Rect2(389,703,397,48),"SAVE + HOME","title",NAVY)
 _button(Rect2(801,703,406,48),"START NEXT DAY","next_day",YELLOW)

func _settings_panel() -> void:
 _header("SETTINGS + LOCAL SAVE","Mouse and keyboard • Windows executable • No account or connection required")
 var settings=sim.state["settings"]
 _button(Rect2(389,230,236,51),"SOUND: "+("ON" if settings["sound"] else "OFF"),"sound",CREAM)
 _button(Rect2(633,230,46,51),"-","sound_down",CREAM,_volume("sound_volume",0.8)>0.01,24)
 _text(Vector2(684,262),"%d%%" % roundi(_volume("sound_volume",0.8)*100),17,BLUE)
 _button(Rect2(739,230,46,51),"+","sound_up",CREAM,_volume("sound_volume",0.8)<0.99,24)
 _button(Rect2(801,230,246,51),"MUSIC: "+("ON" if settings["music"] else "OFF"),"music",CREAM)
 _button(Rect2(1055,230,46,51),"-","music_down",CREAM,_volume("music_volume",0.6)>0.01,24)
 _text(Vector2(1106,262),"%d%%" % roundi(_volume("music_volume",0.6)*100),17,BLUE)
 _button(Rect2(1161,230,46,51),"+","music_up",CREAM,_volume("music_volume",0.6)<0.99,24)
 _button(Rect2(389,301,396,51),"FULLSCREEN / WINDOW  F11","fullscreen",CREAM)
 _button(Rect2(801,301,406,51),"REPLAY TUTORIAL","tutorial",CYAN,screen=="shop")
 _button(Rect2(389,359,396,36),"DIFFICULTY + RULES","difficulty",CYAN,true,16)
 _button(Rect2(801,359,406,36),"REDUCE MOTION: "+("ON" if settings.get("reduce_motion",false) else "OFF"),"reduce_motion",CREAM,true,16)
 _text(Vector2(389,421),"Tab selects controls; Enter activates. Q opens capacity forecasts.\nSpace pauses live panels. Arrows place equipment; Enter confirms.",17,INK,818)
 _button(Rect2(389,476,818,31),"ACCESSIBILITY + REMAP MOVEMENT","accessibility",CREAM,true,15)
 _line(Vector2(389,531),"Demo save is separate from career." if sim.state.get("demo",false) else "Local saves stay on this computer. Updates include backups.",16,MUTED,810)
 if sim.state.get("demo",false) and screen=="shop": _button(Rect2(389,544,818,27),"RESET DEMO / CAREER STAYS SEPARATE","reset_demo",CREAM,true,14)
 _button(Rect2(389,581,396,51),"SAVE DEMO" if sim.state.get("demo",false) else "SAVE SHOP","save",GREEN,screen=="shop")
 _button(Rect2(801,581,406,51),"SAVE + HOME","title",NAVY,screen=="shop")
 _button(Rect2(389,648,818,37),"GAME UPDATES + SAVE BACKUPS","updates",CREAM,true,16)
 _button(Rect2(389,703,397,48),"BACK","close",CYAN)
 _button(Rect2(801,703,406,48),"SAVE + QUIT","quit",CREAM)

func _help_panel() -> void:
 _header("HOW TO PLAY","Hands-on workshop play with a growing tycoon business")
 var lines=["1. Place your gifted vinyl cutter, a heat press and the free benches.","2. Open the shop. Marketing campaigns bring more inquiries.","3. Open the shop clock. Accept customer inquiries before they leave.","4. Walk with WASD / arrows, click floor, or use owner Auto Assist.","5. Check artwork. Vinyl shirts are cut mirrored, weeded, then pressed.","6. Queue the job and choose Work as Sam or enable Auto Assist.","7. Print, inspect and pack. Correct faults or accept reduced payment.","8. Shirts need garment blanks, vinyl or transfers, and the heat press.","9. Complete pickup to get paid. Find receipts in the Customer Desk.","10. Marketing costs appear in the daily profit report.","11. Paid jobs and goals earn XP. New shop levels unlock DTF and more.","12. Restock supplies, hire help and grow into bigger premises."]
 for i in lines.size(): _text(Vector2(389,222+i*33),lines[i],16,INK,810)
 _text(Vector2(389,635),"Tab / Shift+Tab: select. Enter: activate / confirm placement.\nArrow keys: place equipment. Q: capacity. Space: pause.",16,BLUE,810)
 _text(Vector2(389,689),"Every saved shop stays on this Windows computer. Closing the game autosaves.",15,MUTED)
 _button(Rect2(389,718,818,43),"LET'S PRINT","close",YELLOW)

func _new_panel() -> void:
 _difficulty_panel(true)

func _difficulty_panel(new_shop:bool=false) -> void:
 _header("CHOOSE YOUR SHOP RULES" if new_shop else "DIFFICULTY FOR FUTURE WORK","Prices and accepted deadlines stay fixed when changing an existing shop.")
 var presets=["Relaxed","Standard","Expert"]
 for i in presets.size(): _button(Rect2(389+i*275,211,260,43),presets[i],"rules_preset:"+presets[i],CYAN if draft_rules["preset"]==presets[i] else CREAM,true,19)
 var labels=["Opening cash (new shops)","Quoted deadline slack","Daily overhead","Supply travel time","Inquiry decision window","Recoverable defect risk"]
 for i in Strategy.FACTORS.size():
  var key=Strategy.FACTORS[i];var y=281+i*52
  _text(Vector2(389,y+25),labels[i],19,INK,465)
  _button(Rect2(875,y,54,37),"-","rules_adjust:"+key+":-1",CREAM,true,20)
  _text(Vector2(947,y+25),"%.2fx" % draft_rules[key],19,BLUE)
  _button(Rect2(1060,y,54,37),"+","rules_adjust:"+key+":1",CREAM,true,20)
 _text(Vector2(389,631),"%s / Starting cash $%d. Pause, speed and Auto Assist remain available." % [draft_rules["preset"],roundi(Strategy.BASE_CASH*draft_rules["cash"])],18,BLUE,810)
 _text(Vector2(389,672),"Bounded factors: 0.50–2.00. Existing shops receive no cash grant and keep accepted terms.",16,MUTED,810)
 _button(Rect2(389,703,397,48),"START NEW GAME" if new_shop else "APPLY + KEEP PAUSED","new_confirm" if new_shop else "apply_rules",YELLOW,true,17)
 _button(Rect2(801,703,406,48),"BACK","close",CREAM)

func _capacity_panel() -> void:
 var board=_preview_board()
 _header("CAPACITY + CASH FORECAST","Includes current work and shared operators. Approvals and arrivals can add time.")
 var filters=["All","Input","Blocked","Overdue","Ready"]
 for i in filters.size(): _button(Rect2(389+i*141,209,132,36),filters[i],"board_filter:"+filters[i],CYAN if board_filter==filters[i] else CREAM,true,15)
 _button(Rect2(1103,209,104,36),board_sort,"board_sort",CREAM,true,14)
 var rows=[]
 for row in board["rows"]:
  var o=sim.order(row["index"])
  if board_filter=="Input" and o["stage"] not in ["intake","preflight","plan","fault","revision"]: continue
  if board_filter=="Blocked" and row["risk"]!="BLOCKED": continue
  if board_filter=="Overdue" and sim.now()<=float(o["due"]): continue
  if board_filter=="Ready" and o["stage"]!="ready": continue
  rows.append(row)
 rows.sort_custom(func(a,b):return a["margin"]>b["margin"] if board_sort=="Margin" else float(sim.order(a["index"])["due"])<float(sim.order(b["index"])["due"]))
 var pages=maxi(1,ceili(rows.size()/4.0));board_page=posmod(board_page,pages)
 for n in mini(4,rows.size()-board_page*4):
  var row=rows[board_page*4+n];var o=sim.order(row["index"]);var y=261+n*80
  _panel(Rect2(389,y,818,73),Color("edf5ff"),Color("d0e1f6"),6)
  var eta="No ETA" if row["finish"]<0 else _due({"due":row["finish"]})
  _line(Vector2(400,y+22),"%s / %d %s / %s" % [o["id"],o["quantity"],o["product"],row["risk"]],16,BLUE,650,true)
  _line(Vector2(400,y+43),"Finish %s / margin $%.0f / %s at %s" % [eta,row["margin"],row["operator"],row["station"]],14,INK,650)
  _line(Vector2(400,y+63),"; ".join(row["reasons"]),13,RED,650)
  _button(Rect2(1080,y+15,115,40),"OPEN","order:%d" % row["index"],CYAN,true,15)
 _line(Vector2(389,606),"Bills $%.0f / possible receipts $%d / cash after bills $%.0f" % [board["obligations"],board["receipts"],board["cash_after_bills"]],18,RED if board["cash_after_bills"]<0 else BLUE,810)
 _text(Vector2(389,636),"Stock is allocated in queue order. A forecast reserves no cash and guarantees no payment.",15,MUTED,810)
 _button(Rect2(389,659,397,34),"RECOVERY: +$100 / 2 HOURS","recovery_shift",CREAM,sim.state["clock"]<=15,14)
 _button(Rect2(801,659,406,34),"OPTIONAL RELAXED LOAN: $400","rescue_loan",CREAM,sim.state["rules"]["preset"]=="Relaxed" and not sim.state["rescue_used"],14)
 _button(Rect2(389,710,397,43),"BACK TO SHOP","close",NAVY)
 _button(Rect2(801,710,406,43),"PAGE %d / %d >" % [board_page+1,pages],"board_page",CYAN,pages>1)

func _growth_panel() -> void:
 _header("GROW AT YOUR OWN PACE","Premises, fit-out and equipment are separate investments. Your existing layout is retained.")
 var board=_preview_board();var p=sim.garage_progress()
 _text(Vector2(389,235),"Cash $%d / daily bills $%.0f / buffer after bills $%.0f" % [sim.state["cash"],board["obligations"],board["cash_after_bills"]],20,BLUE,810)
 # Garage > storefront > warehouse > factory. The next step is always shown here.
 var advice=_growth_advice()
 _panel(Rect2(385,246,823,62),Color("edf5ff"),Color("d0e1f6"),6)
 _line(Vector2(399,270),advice[0],16,BLUE,795,true)
 _line(Vector2(399,295),advice[1],14,INK,795)
 if sim.premises()=="garage":
  var lease=sim.storefront_status()
  _button(Rect2(389,315,818,49),"LEASE A STOREFRONT  $%d" % sim.STOREFRONT_COST,"storefront",YELLOW,lease["ready"],19)
 else:
  _button(Rect2(389,315,818,49),"MOVE TO THE WAREHOUSE  $900","move_garage",YELLOW,p["ready"] and sim.state["location"]==1,19)
 _button(Rect2(389,380,397,49),"INDUSTRIAL FIT-OUT  $350","fit_out",CYAN,sim.state["location"]==2 and not sim.state["fit_out"] and sim.state["cash"]>=350,17)
 _button(Rect2(801,380,406,49),"PURCHASE EQUIPMENT","equipment",CREAM,true,17)
 _button(Rect2(389,439,818,32),"SECOND DTF LINE  $900 / PLACE IN A CLEAR AISLE","second_line",CREAM,sim.state["fit_out"] and not sim.state["machines"].has("dtf2") and sim.state["cash"]>=900,14)
 _text(Vector2(389,499),"CLIENT FOCUS: "+sim.state["specialty"],23,BLUE,-1,true)
 var names=["General","Stickers","Apparel","Signs"]
 for i in names.size(): _button(Rect2(389+i*207,526,197,47),names[i],"specialty:"+names[i],CYAN if names[i]==sim.state["specialty"] else CREAM,true,17)
 _text(Vector2(389,610),"Your focus favors the next day's first inquiry when its equipment is installed. Diversify whenever useful. No accepted order changes.",19,INK,810)
 _button(Rect2(389,661,818,34),"PRINT FACTORY: PRODUCTION ANNEX  $2,200 / +$75 DAILY","annex",CREAM,sim.state["location"]==2 and sim.state["fit_out"] and not sim.state.get("production_annex",false),15)
 _button(Rect2(389,710,818,43),"BACK TO SHOP","close",NAVY)

# One concrete next step for the growth panel: what to do, and why it helps.
func _growth_advice() -> Array:
 var lv=Progress.span(sim);var level=int(lv["level"]);var cash=int(sim.state["cash"])
 var unlocked=[]
 for id in Progress.UNLOCK_LEVEL:
  if not sim.state["machines"].has(id) and not sim.equipment_locked(id) and C.EQUIPMENT_PRICES.has(id): unlocked.append(id)
 var busiest="";var most=0;var queues={}
 for i in sim.active_orders():
  var o=sim.order(i)
  if o["stage"] in ["intake","scheduled","completed"]: continue
  var m=sim.machine_for(o);queues[m]=int(queues.get(m,0))+1
  if queues[m]>most: most=queues[m];busiest=m
 var why="Bottleneck: %d jobs wait for %s." % [most,str(sim.state["machines"].get(busiest,{}).get("title",busiest))] if most>=2 else "No queues yet, so extra capacity mostly adds daily cost."
 if sim.premises()=="garage":
  var need=[]
  if level<sim.STOREFRONT_LEVEL: need.append("level %d (now %d, %d/%d XP)" % [sim.STOREFRONT_LEVEL,level,int(lv["xp"]),int(lv["next"])])
  if cash<sim.STOREFRONT_COST: need.append("$%d cash (have $%d)" % [sim.STOREFRONT_COST,cash])
  if need.is_empty(): return ["NEXT STEP: Lease the storefront now ($%d)." % sim.STOREFRONT_COST,"Same layout, bigger floor, team of three; rent $60 to $125/day. "+why]
  if not unlocked.is_empty():
   var id=unlocked[0]
   return ["NEXT STEP: %s ($%d) is unlocked at your level." % [Progress.UNLOCK_NAMES[id],int(C.EQUIPMENT_PRICES[id])],"New products bring new inquiries. "+why]
  return ["NEXT STEP: Earn XP with on-time paid jobs for the storefront.","Storefront needs "+", ".join(need)+". "+why]
 var p=sim.garage_progress()
 if sim.state["location"]==1:
  var gaps=[]
  if p["cash"]<1500: gaps.append("$1,500 cash ($%d)" % int(p["cash"]))
  if p["trust"]<60: gaps.append("trust 60 (%d)" % int(p["trust"]))
  if p["orders"]<3: gaps.append("3 paid jobs (%d)" % int(p["orders"]))
  if p["on_time"]<75: gaps.append("75%% on time (%.0f%%)" % p["on_time"])
  if p["quality"]<85: gaps.append("85%% quality (%.0f%%)" % p["quality"])
  if gaps.is_empty(): return ["NEXT STEP: Move to the warehouse ($900).","Room for banners, CNC and a second DTF line. "+why]
  return ["NEXT STEP: Warehouse needs "+", ".join(gaps)+".",why]
 if not sim.state["fit_out"]: return ["NEXT STEP: Industrial fit-out ($350) opens heavy equipment and a bigger team.",why]
 if not unlocked.is_empty():
  var id2=unlocked[0]
  return ["NEXT STEP: %s ($%d) is available." % [Progress.UNLOCK_NAMES[id2],int(C.EQUIPMENT_PRICES[id2])],why]
 if not sim.state.get("production_annex",false): return ["NEXT STEP: Production annex ($2,200, +$75/day) for the full factory floor.","Needs 10 paid jobs and 80 trust after fit-out. "+why]
 return ["Your factory is fully grown.","Use client focus and staffing to balance the busiest stations. "+why]

func _roster_panel() -> void:
 _header("TEAM TASKS + DAILY COSTS","Unique worker IDs distinguish repeat hires. Automatic assignments still require the matching role.")
 for i in sim.state["workers"].size():
  var w=sim.state["workers"][i];var y=214+i*49
  var activity=sim.worker_status(w)
  var utilization=0 if float(w.get("shift_seconds",0))==0 else roundi(float(w.get("work_seconds",0))*100/float(w["shift_seconds"]))
  var personality=(" / "+str(w["trait"])) if w.has("trait") else ""
  _text(Vector2(389,y+19),"%s (%s) / %s%s / skill %.2f / $%d day" % [w["name"],w["id"],w["role"],personality,w["skill"],w["wage"]],17,BLUE,810)
  _text(Vector2(409,y+39),"%s / working %d%% of this shift" % [activity,utilization],15,MUTED,790)
 _button(Rect2(389,710,818,43),"BACK TO STAFF","staff",NAVY)

func _action(action:String) -> void:
 var before_notice=sim.state["notices"][0] if not sim.state["notices"].is_empty() else ""
 var before_count=sim.state["notices"].size()
 var before_modal=modal
 _action_inner(action)
 # A notice raised by an action taken inside a panel is shown with that panel, not hidden behind it.
 if before_modal!="" and modal!="" and not sim.state["notices"].is_empty() and (sim.state["notices"][0]!=before_notice or sim.state["notices"].size()!=before_count):
  modal_toast=sim.state["notices"][0];modal_toast_until=Time.get_ticks_msec()+6000;modal_toast_modal=modal
 elif modal=="":modal_toast=""

func _action_inner(action:String) -> void:
 if modal=="intervention" and action not in ["qte_hit","qte_skip","close"]:
  Ops.qte_result(sim,true);sim.state["paused"]=qte_previous_pause;modal="order"
 if action.begins_with("partner:"):
  var index=int(action.get_slice(":",1))
  if index>=0 and index<partner_banners.size():OS.shell_open(partner_banners[index]["url"])
  return
 if action=="cash_bridge":modal="cash_bridge";return
 if action=="annex":Ops.annex(sim);reset_camera();return
 if action in ["banner_previous","banner_next","banner_pause"]:
  if action=="banner_pause":banner_paused=not banner_paused
  else:banner_index+=(-1 if action=="banner_previous" else 1);banner_elapsed=0
  return
 if _workshop_action(action):return
 if action=="close" and gang_drag>=0 and selected_order>=0 and selected_order<sim.state["orders"].size():
  var sheet=sim.order(selected_order)["gang"]
  if gang_drag<sheet.size(): sheet[gang_drag]=gang_before.duplicate()
  gang_drag=-1
  gang_before=[]
 status=""
 forecast_preview={}
 var parts=action.split(":")
 if action in ["settings","help","stock","move","marketing","merch","staff","customers","dtf_views","gang","capacity","difficulty","roster","updates"] or parts[0] in ["order","machine"]:
  _cancel_world_drag()
 if parts.size()>1:
  match parts[0]:
   "bind": binding_action=parts[1]
   "rules_preset": draft_rules=Strategy.rules(parts[1])
   "rules_adjust":
    var key=parts[1]
    if Strategy.FACTORS.has(key): draft_rules[key]=clampf(float(draft_rules[key])+int(parts[2])*.05,.5,2.0);draft_rules["preset"]="Custom"
   "board_filter": board_filter=parts[1];board_page=0
   "specialty": sim.select_specialty(parts[1])
   "order": selected_order=int(parts[1]); modal="order"
   "next_work":
    selected_order=int(parts[1])
    if not sim.work_order(selected_order): sim.notice("Sam can't start that step yet: check stock, the station and the customer.")
   "campaign": sim.start_campaign(parts[1])
   "merch_batch": Merch.make_batch(sim,parts[1])
   "merch_price": Merch.set_price(sim,parts[1],int(parts[2]))
   "machine": selected_machine=parts[1]; modal="machine"; build=false
   "place":
    moving_equipment="";dragging="";drag_id="";drag_offset=Vector2.ZERO
    pending_equipment=parts[1];placement_rotation=0;placement_facing=0;drag_point=Vector2i(sim.bounds().x-2,3) if parts[1]=="dock" else Vector2i(5,3);drag_valid=sim.install_feedback(pending_equipment,drag_point);modal="";build=true
    var ms=_render_machines()
    preview_center_offset=sim.equipment_center(pending_equipment,ms)-Vector2(drag_point) if ms.has(pending_equipment) else Vector2.ZERO
   "dtf_view": dtf_view_index=int(parts[1]); modal="dtf_views"
   "speed": sim.state["speed"]=int(parts[1])
   "hire": sim.hire(int(parts[1]))
   "upgrade": sim.buy_upgrade(parts[1])
   "restock":
    var key=parts[1]
    var qty={"film":48,"white":60,"powder":40,"sticker":60,"laminate":40,"banner":30,"rigid":12,"packaging":25,"maintenance":5,"vinyl":24,"transfer_tape":24,"htv":24,"mugs":24,"subpaper":20,"caps":24,"thread":8}[key]
    sim.restock({key:qty})
  _sfx(); return
 var o=sim.order(selected_order)
 match action:
  "check_updates":
   if OS.get_name()!="Windows" or OS.has_feature("editor"):
    status="Updates are available in the Windows download.";return
   var updater=OS.get_executable_path().get_base_dir().path_join("Update-Game.ps1")
   if not FileAccess.file_exists(updater):
    status="Updater missing. Download the next release from the official GitHub page.";return
   var result=OS.create_process(OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe"),PackedStringArray(["-NoProfile","-File",updater,"-CurrentVersion",str(ProjectSettings.get_setting("application/config/version"))]),true)
   status="Save and close the game, then confirm UPDATE in the updater window." if result>0 else "Could not open updater. Run Update-Game.ps1 from the game folder."
  "new":
   draft_rules=Strategy.rules("Standard");modal="confirm_new"
  "demo":
   if screen!="title":return
   career_sim=sim
   sim=Sim.new();sim.save_path=career_sim.save_path+".demo";sim.save_enabled=career_sim.save_enabled
   if sim.has_save():
    if not sim.load_game():
     sim=career_sim;career_sim=null;status="Demo save could not be restored. Career is unchanged.";return
   else: sim.start_demo()
   Ops.settle_offline(sim)
   screen="shop";modal="report" if not sim.state["report"].is_empty() else "";build=false;_cancel_world_drag();order_page=0;customer_page=0;reset_camera();_load_music_preference();_start_music()
  "reset_demo": modal="confirm_demo"
  "reset_demo_confirm":
   if not sim.state.get("demo",false):return
   if not sim.backup_before_new_shop():status=sim.last_save_error;return
   sim.start_demo();modal="";build=false;_cancel_world_drag();order_page=0;customer_page=0;reset_camera();_load_music_preference();_start_music();sim.save_game()
  "new_confirm":
   if career_sim!=null:
    if not _save_before("new_confirm"):return
    sim=career_sim;career_sim=null
   if not sim.backup_before_new_shop(): status=sim.last_save_error;return
   sim.start_shop(draft_rules["preset"],draft_rules); screen="shop"; modal="";build=false;pending_equipment="";moving_equipment="";dragging="";drag_valid={};order_page=0;customer_page=0;reset_camera(); _load_music_preference();sim.save_game(); _start_music()
   if sim.walkthrough_step()!="": modal="welcome_gift"
  "continue":
   if sim.load_game(): Ops.settle_offline(sim); screen="shop"; modal="report" if not sim.state["report"].is_empty() else ""; reset_camera(); _load_music_preference();_start_music()
   else: status=sim.state["notices"][0] if not sim.state["notices"].is_empty() else "No valid shop save was found. Your save and backup could not be loaded."
  "close":
   if modal=="intervention":_action("qte_skip");return
   modal=""; status="";pending_save_action="";binding_action=""
  "dtf_views": dtf_view_index=0; modal="dtf_views"
  "back_machine": modal="machine"
  "equipment":
   modal="equipment";equipment_page=0;pending_equipment="";moving_equipment="";dragging="";drag_id="";drag_valid={};drag_offset=Vector2.ZERO
  "equipment_page": equipment_page=(equipment_page+1)%ceili(14/5.0)
  "move_equipment":
   var id="dtf2" if selected_machine=="shaker2" else ("dtf" if selected_machine=="shaker" else selected_machine)
   if sim.state["machines"].has(id):
    selected_machine=id;moving_equipment=id;drag_id=id;dragging="";pending_equipment="";build=true;modal=""
    drag_point=sim.cell(sim.state["machines"][id]["pos"]);drag_rotation=int(sim.state["machines"][id]["rotation"]);drag_facing=sim.facing_of(sim.state["machines"][id])
    preview_center_offset=sim.equipment_center(id,sim.state["machines"])-Vector2(drag_point)
    drag_valid=sim.placement_feedback(id,drag_point,drag_rotation,drag_facing)
  "rotate_equipment":
   if pending_equipment!="": _rotate_equipment()
   elif _relocating(): _rotate_equipment()
   elif sim.state["machines"].has(selected_machine):
    var id="dtf2" if selected_machine=="shaker2" else ("dtf" if selected_machine=="shaker" else selected_machine)
    var m=sim.state["machines"][id]
    _rotate_equipment()
  "save":
   if _save_before("save"):
    status="Shop saved locally."
    if modal=="save_error": modal=""
  "retry_save":
   if pending_save_action!="": _action(pending_save_action)
  "title":
   if _save_before("title"):
    if career_sim!=null: sim=career_sim;career_sim=null;_load_music_preference()
    screen="title";modal="";build=false;_cancel_world_drag()
  "quit":
   if screen=="shop" and not _save_before("quit"): return
   _quit_game()
  "report":modal="report"
  "settings","help","stock","move","marketing": _cancel_world_drag();modal=action
  "capacity": board_page=0;modal="capacity"
  "goals": _cancel_world_drag();goals_page=0;modal="goals"
  "goals_list": goals_page=0
  "goals_awards": goals_page=1
  "board_page": board_page+=1
  "board_sort": board_sort="Margin" if board_sort=="Due" else "Due"
  "roster": modal="roster"
  "accessibility": modal="accessibility"
  "updates": modal="updates"
  "update_check": await update_service.check(str(ProjectSettings.get_setting("application/config/version")))
  "update_download": await update_service.download()
  "update_install":
   if screen=="shop" and not _save_before("update_install"):return
   if update_service.restart():_quit_game()
  "update_folder": OS.shell_open(OS.get_user_data_dir().path_join("updates"))
  "reset_bindings": movement_bindings={"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S};binding_action="";_save_audio_preferences()
  "difficulty": Strategy.ensure(sim);draft_rules=sim.state["rules"].duplicate(true);modal="difficulty"
  "apply_rules": sim.state["paused"]=true;sim.change_rules(draft_rules["preset"],draft_rules);modal="settings"
  "recovery_shift": sim.state["paused"]=true;sim.recovery_shift()
  "rescue_loan": sim.rescue_loan()
  "fit_out": sim.fit_out()
  "second_line": sim.install_second_line()
  "repeat":
   if sim.repeat_order(selected_order): selected_order=sim.state["orders"].size()-1;modal="order"
  "batch": sim.batch_orders(selected_order)
  "reduce_motion":
   sim.state["settings"]["reduce_motion"]=not sim.state["settings"].get("reduce_motion",false)
   _save_audio_preferences()
  "staff": modal="staff"; staff_page=0
  "staff_hiring": staff_page=0
  "staff_upgrades": staff_page=1
  "pause":
   if sim.state["report"].is_empty(): sim.state["paused"]=not sim.state["paused"]
  "camera": reset_camera()
  "more_orders": order_page+=1
  "customers": customer_page=0;modal="customers"
  "merch": _cancel_world_drag();modal="merch"
  "merch_store": Merch.toggle_store(sim)
  "merch_booth": Merch.book_booth(sim)
  "merch_theme": merch_theme=(merch_theme+1)%Merch.THEMES.size()
  "merch_new": Merch.create_design(sim,merch_kind,Merch.THEMES[merch_theme])
  "merch_kind":
   var kinds=Merch.makeable(sim)
   if not kinds.is_empty(): merch_kind=kinds[(kinds.find(merch_kind)+1)%kinds.size()]
  "more_customers": customer_page+=1
  "reviews_view": reviews_view=not reviews_view;customer_page=0
  "build": build=not build; modal="";pending_equipment="";moving_equipment="";dragging="";drag_valid={}
  "snap":
   var target="shaker2" if selected_machine in ["dtf2","shaker2"] else "shaker"
   var printer="dtf2" if target=="shaker2" else "dtf"
   if sim.state["machines"].has(printer):
    var m=sim.state["machines"][printer]
    sim.move_equipment(printer,sim.cell(m["pos"]),int(m["rotation"]),sim.facing_of(m))
  "accept": sim.accept(selected_order)
  "rush": sim.accept(selected_order,true)
  "decline": sim.decline(selected_order)
  "preflight": sim.preflight(selected_order,"repair")
  "revision": sim.preflight(selected_order,"revision")
  "gang": modal="gang"; gang_selected=-1
  "back_order": modal="order"
  "auto_pack": sim.auto_pack(selected_order)
  "queue":
   if sim.queue_order(selected_order): modal="order"
  "white": o["settings"]["white"]="economy" if o["settings"]["white"]=="standard" else "standard"
  "laminate": o["settings"]["laminate"]=not o["settings"]["laminate"]
  "registration": o["settings"]["registration"]=not o["settings"]["registration"]
  "cut": o["settings"]["cut"]="through" if o["settings"]["cut"]=="contour" else "contour"
  "media": o["settings"]["media"]={"PVC":"ACM","ACM":"Incompatible","Incompatible":"PVC"}[o["settings"]["media"]]
  "press_preset": o["settings"]["press"]="poly_cold" if o["settings"]["press"]=="cotton_warm" else "cotton_warm"
  "work":
   if sim.work_order(selected_order): modal=""
  "work_station":
   var id=selected_machine
   if sim.state["machines"][id]["kind"]=="shaker": id="dtf2" if id=="shaker2" else "dtf"
   if sim.work_station(id): modal=""
  "assist_order": sim.owner()["manual"]=false; modal=""; sim.notice("Sam will walk between prepared jobs. WASD returns to manual control.")
  "next_assist": sim.owner()["manual"]=false; sim.notice("Auto Assist: Sam walks to each prepared step and stops for decisions. WASD returns to manual control.")
  "assist":
   if sim.owner()["manual"]: sim.owner()["manual"]=false; sim.notice("Owner auto assist enabled.")
   else: sim.interrupt_owner(); sim.notice("Manual control: WASD / arrows or click the floor.")
  "reprint": sim.recover(selected_order,true)
  "downgrade": sim.recover(selected_order,false)
  "priority": sim.reorder(selected_order,true)
  "maintain": sim.maintain(selected_machine)
  "assign_cycle":
   var m=sim.state["machines"][selected_machine]
   if m["active"]>=0: sim.notice("Finish this job before changing its operator."); return
   var ids=["auto"]
   for w in sim.state["workers"]: ids.append(w["id"])
   var n=(ids.find(m["worker"])+1)%ids.size()
   if ids[n]=="auto": m["worker"]="auto"
   else: sim.assign(ids[n],selected_machine)
  "clear_gang": o["gang"]=[]; gang_selected=-1
  "rotate": _rotate_gang()
  "duplicate":
   var tile=[0.0,0.0,float(o["art_w"]),float(o["art_h"])] if gang_selected<0 else o["gang"][gang_selected].duplicate()
   var added=false
   for y in range(int(o["sheet_length"])-int(tile[3])+1):
    if added: break
    for x in range(int(o["film_width"])-int(tile[2])+1):
     var candidate=o["gang"].duplicate(true)
     tile[0]=float(x); tile[1]=float(y); candidate.append(tile.duplicate())
     if sim.gang_valid(selected_order,candidate): o["gang"]=candidate; added=true; break
   if not added: status="No room for another full-size design."
  "ink": sim.restock({"cyan":40,"magenta":40,"yellow":40,"black":40})
  "garments": sim.restock({"garment:navy:S":6,"garment:navy:M":6,"garment:navy:L":6})
  "hoodies": sim.restock({"garment:hoodie:S":3,"garment:hoodie:M":3,"garment:hoodie:L":3})
  "totes": sim.restock({"garment:tote:One":12})
  "storefront":
   if sim.move_to_storefront(): modal=""; reset_camera(); order_page=0;_play("levelup",.8)
  "move_garage":
   if sim.move_garage(): modal=""; reset_camera(); order_page=0
  "end_day": sim.end_day(); modal="report"
  "next_day": sim.next_day(); modal=""
  "sound":
   sim.state["settings"]["sound"]=not sim.state["settings"]["sound"]
   _save_audio_preferences()
  "music":
   sim.state["settings"]["music"]=not sim.state["settings"]["music"]
   _start_music()
   _save_audio_preferences()
  "sound_down","sound_up","music_down","music_up":
   var key="sound_volume" if action.begins_with("sound") else "music_volume"
   var current=_volume(key,0.8 if key=="sound_volume" else 0.6)
   sim.state["settings"][key]=snappedf(clampf(current+(-0.1 if action.ends_with("down") else 0.1),0.0,1.0),0.1)
   if key=="music_volume":
    if _volume(key,0.6)<=0.01: music.stop()
    elif music.playing: music.volume_db=_music_db()
    else: _start_music()
   _save_audio_preferences()
  "fullscreen":
   var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
   sim.state["settings"]["fullscreen"]=not full
   _save_window_preference()
  "skip": sim.state["tutorial"]=false
  "walkthrough_skip": sim.end_walkthrough(); modal=""; status="Walkthrough skipped. Your gifted cutter is still free in ADD EQUIPMENT."
  "walkthrough_done":
   sim.end_walkthrough()
   # The guided first job is over; the goal card takes its place.
   var first=_tutorial_index()
   if first>=0 and sim.order(first)["stage"]=="completed": sim.state["tutorial"]=false
  "tutorial":
   var tutorial_type=""
   if sim.state["machines"].has("dtf") or sim.state["machines"].has("dtfmini"): tutorial_type="transfer"
   elif sim.state["machines"].has("sticker"): tutorial_type="sticker"
   elif sim.state["machines"].has("banner"): tutorial_type="banner"
   elif sim.state["machines"].has("cnc"): tutorial_type="cnc"
   elif sim.state["machines"].has("cutter"): tutorial_type="decal"
   if tutorial_type=="":
    sim.state["tutorial"]=false
    status="Place a printer or cutter before starting the production tutorial."
    return
   sim.state["tutorial"]=true
   var i=_tutorial_index()
   var id="TUTORIAL-%d" % sim.state["orders"].size()
   var quantity=12 if tutorial_type in ["sticker","decal"] else (2 if tutorial_type=="cnc" else 3)
   if i>=0 and sim.order(i)["type"]!=tutorial_type and sim.order(i)["stage"] not in ["completed","declined"]:
    # A tutorial job belongs to the tutorial system; replace it in place when
    # the shop's available equipment changes so no impossible job is stranded.
    id=sim.order(i)["id"]
    var replacement=C.make_order(id,tutorial_type,quantity,"Tutorial / practice customer",sim.now()+4,120)
    replacement["priority"]=-1
    sim.state["orders"][i]=replacement
    sim.state["tutorial_order"]=id
   elif i<0 or sim.order(i)["stage"] in ["completed","declined"]:
    var tutorial_order=C.make_order(id,tutorial_type,quantity,"Tutorial / practice customer",sim.now()+4,120)
    tutorial_order["priority"]=-1
    sim.state["orders"].append(tutorial_order)
    sim.state["tutorial_order"]=id
   modal=""
 _sfx()

func _load_audio() -> void:
 for name in SFX_NAMES:
  var path="res://assets/audio/sfx-%s.wav" % name
  if ResourceLoader.exists(path): sfx_streams[name]=load(path)
 for name in MUSIC_SHOP+[MUSIC_TITLE]:
  var path="res://assets/audio/music-%s.ogg" % name
  if ResourceLoader.exists(path): music_tracks[name]=load(path)
 for i in 6:
  var player=AudioStreamPlayer.new();add_child(player);sfx_players.append(player)
 music.finished.connect(_next_track)

func _volume(key:String,fallback:float) -> float:
 return clampf(float(sim.state["settings"].get(key,fallback)),0.0,1.0)

func _music_db() -> float:
 return linear_to_db(maxf(0.001,_volume("music_volume",0.6)))-6.0

func _play(name:String,gain:float=1.0) -> void:
 if not sim.state["settings"]["sound"]: return
 var level=_volume("sound_volume",0.8)*gain
 if level<=0.01: return
 if not sfx_streams.has(name):
  if name=="click": _fallback_click()
  return
 # At 4x speed with several staff the same sound can fire many times at once.
 if time-float(sfx_last.get(name,-9.0))<0.12: return
 sfx_last[name]=time
 if not audio_output: return
 var player=sfx_players[0]
 for candidate in sfx_players:
  if not candidate.playing: player=candidate;break
 player.stream=sfx_streams[name];player.volume_db=linear_to_db(level)-3.0;player.play()

func _sfx() -> void:
 _play("click")

# Sounds follow what the simulation did since the last frame: a sale, a visitor
# at the door, a job ready, a fault, a machine starting work, the day closing.
func _audio_events() -> void:
 var s=sim.state
 var working={};var faults=0;var ready=0
 for w in s["workers"]:
  if not w["task"].is_empty() and w["task"]["working"] and s["machines"].has(w["task"]["machine"]):
   working[w["id"]]=str(w["task"]["machine"])+":"+str(w["task"]["order"])+":"+str(w["task"]["stage"])
 for o in s["orders"]:
  if o["stage"]=="fault": faults+=1
  elif o["stage"]=="ready": ready+=1
 var seen={"state":s,"completed":int(s["completed"]),"visitors":sim.visible_customers().size(),"report":not s["report"].is_empty(),"step":sim.walkthrough_step(),"working":working,"faults":faults,"ready":ready,"machines":s["machines"].size()}
 # A new or loaded shop starts a fresh comparison instead of replaying sounds.
 if not audio_watch.is_empty() and is_same(audio_watch["state"],s):
  if seen["completed"]>audio_watch["completed"]: _play("cash")
  if seen["visitors"]>audio_watch["visitors"]: _play("door",.8)
  if seen["report"] and not audio_watch["report"]: _play("day")
  if seen["faults"]>audio_watch["faults"]: _play("error")
  if seen["ready"]>audio_watch["ready"]: _play("done",.8)
  if seen["step"]=="done" and audio_watch["step"]=="job": _play("fanfare")
  if seen["machines"]>audio_watch["machines"]: _play("place")
  for id in working:
   if audio_watch["working"].get(id,"")==working[id]: continue
   var kind=str(s["machines"][working[id].get_slice(":",0)]["kind"])
   var sound={"cutter":"cutter","sticker":"cutter","cnc":"cutter","dtf":"print","dtfmini":"print","banner":"print","heat":"press","mug":"press","embroidery":"cutter","pack":"pack","dock":"pack"}.get(kind,"")
   if sound!="": _play(sound,.7)
 audio_watch=seen

func _fallback_click() -> void:
 var stream=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=22050
 var bytes=PackedByteArray(); bytes.resize(4400)
 for i in 2200:
  var sample=sin(i*TAU*620/22050.0)*sin(i*TAU*3/22050.0)*1800*(1-i/2200.0)
  bytes.encode_s16(i*2,int(sample))
 stream.data=bytes; audio.stream=stream; audio.play()

func _preference_save_path() -> String:
 return career_sim.save_path if career_sim!=null else sim.save_path

func _save_audio_preferences() -> void:
 var preferences=ConfigFile.new()
 preferences.load(_preference_save_path()+".preferences.cfg")
 for key in ["music","sound"]: preferences.set_value("audio",key,sim.state["settings"][key])
 preferences.set_value("audio","music_volume",_volume("music_volume",0.6));preferences.set_value("audio","sound_volume",_volume("sound_volume",0.8))
 preferences.set_value("display","reduce_motion",sim.state["settings"].get("reduce_motion",false))
 for key in movement_bindings: preferences.set_value("input",key,movement_bindings[key])
 if preferences.save(_preference_save_path()+".preferences.cfg")!=OK: sim.notice("Audio changed; preference could not be saved.")

func _load_music_preference() -> void:
 var preferences=ConfigFile.new()
 if preferences.load(_preference_save_path()+".preferences.cfg")==OK:
  for key in ["music","sound"]:
   sim.state["settings"][key]=bool(preferences.get_value("audio",key,sim.state["settings"][key]))
  sim.state["settings"]["music_volume"]=clampf(float(preferences.get_value("audio","music_volume",0.6)),0.0,1.0)
  sim.state["settings"]["sound_volume"]=clampf(float(preferences.get_value("audio","sound_volume",0.8)),0.0,1.0)
  sim.state["settings"]["reduce_motion"]=bool(preferences.get_value("display","reduce_motion",false))
  for key in movement_bindings: movement_bindings[key]=int(preferences.get_value("input",key,movement_bindings[key]))
  var mode=int(preferences.get_value("display","mode",DisplayServer.window_get_mode()))
  if mode in [DisplayServer.WINDOW_MODE_WINDOWED,DisplayServer.WINDOW_MODE_MAXIMIZED,DisplayServer.WINDOW_MODE_FULLSCREEN]: DisplayServer.window_set_mode(mode)
 sim.state["settings"]["fullscreen"]=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN

func _save_window_preference() -> void:
 var preferences=ConfigFile.new();preferences.load(_preference_save_path()+".preferences.cfg")
 preferences.set_value("display","mode",DisplayServer.window_get_mode())
 if preferences.save(_preference_save_path()+".preferences.cfg")!=OK: sim.notice("Display changed; preference could not be saved.")

func _updates_panel() -> void:
 _header("GAME UPDATES + SAVE BACKUPS","Installed v"+str(ProjectSettings.get_setting("application/config/version"))+" / Official Windows releases")
 _text(Vector2(389,243),update_service.status,20,BLUE,810)
 if update_service.request!=null:
  _text(Vector2(389,312),"Downloaded %.1f MB" % (float(update_service.request.get_downloaded_bytes())/1000000),18,INK)
 var supported=OS.get_name()=="Windows" and not OS.has_feature("editor")
 _button(Rect2(389,346,818,49),"CHECK FOR UPDATES","update_check",CYAN,supported and not update_service.busy)
 _button(Rect2(389,412,818,49),"DOWNLOAD VERIFIED UPDATE","update_download",CREAM,supported and not update_service.busy and not update_service.available.is_empty())
 _button(Rect2(389,478,818,49),"SAVE, BACK UP + RESTART TO INSTALL","update_install",YELLOW,supported and not update_service.busy and update_service.staged!="",18)
 _text(Vector2(389,571),"Downloads use the official GitHub release and its recorded SHA-256 digest.\nInstallation waits for this game to close. Saves stay in AppData, with an\nextra backup. Failed startup restores the previous executable.\nNo administrator access, account or background update service is needed.",17,INK,810)
 _button(Rect2(389,675,818,31),"OPEN UPDATE LOGS + SAVE BACKUPS","update_folder",CREAM,true,14)
 _button(Rect2(389,723,818,37),"BACK TO SETTINGS","settings",NAVY)

func _accessibility_panel() -> void:
 _header("KEYBOARD + ACCESSIBILITY","Native focusable controls expose names to assistive software. Tab / Shift+Tab navigates; Enter activates.")
 _text(Vector2(389,238),"REMAP OWNER MOVEMENT",23,BLUE,-1,true)
 var names=["left","right","up","down"]
 for i in names.size():
  var key=names[i]
  _button(Rect2(389+(i%2)*412,266+(i/2)*75,396,58),key.to_upper()+": "+OS.get_keycode_string(movement_bindings[key]),"bind:"+key,CYAN,true,22)
 _text(Vector2(389,466),"Press a new key for "+binding_action+", or Escape to cancel." if binding_action!="" else "Arrow movement remains available. Reserved game keys cannot be overwritten.",19,INK,810)
 _text(Vector2(389,516),status,17,RED,810)
 _button(Rect2(389,564,396,48),"RESET MOVEMENT KEYS","reset_bindings",CREAM,true,17)
 _button(Rect2(801,564,406,48),"REDUCE MOTION: "+("ON" if sim.state["settings"].get("reduce_motion",false) else "OFF"),"reduce_motion",CREAM,true,16)
 _button(Rect2(389,710,818,43),"BACK TO SETTINGS","settings",NAVY)

func _material_estimate(index:int,o:Dictionary) -> float:
 # Spent so far plus the forecast's remaining inputs, so the quote and receipt use one basis.
 for row in _preview_board().get("rows",[]):
  if int(row.get("index",-1))==index: return float(o["material_cost"])+float(row.get("remaining_cost",0.0))
 return maxf(float(o["material_cost"]),sim.reprint_cost(o)-float(C.PRICES["maintenance"]))

func _preview_board() -> Dictionary:
 var stamp=Time.get_ticks_msec()
 if forecast_preview.is_empty() or stamp-forecast_preview_at>=500:
  forecast_preview=sim.capacity_board(true);forecast_preview_at=stamp
 return forecast_preview

func _start_music() -> void:
 music.stop()
 music_context="shop" if screen=="shop" else "title"
 if not audio_output: return
 if not sim.state["settings"]["music"] or music_tracks.is_empty() or _volume("music_volume",0.6)<=0.01: return
 var track=MUSIC_TITLE
 if music_context=="shop" or not music_tracks.has(MUSIC_TITLE):
  # The shop shuffles its tunes and never plays the same one twice in a row.
  if music_queue.is_empty():
   for candidate in MUSIC_SHOP:
    if music_tracks.has(candidate): music_queue.append(candidate)
   music_queue.shuffle()
   if music_queue.size()>1 and music_queue[0]==music_last: music_queue.push_back(music_queue.pop_front())
  if music_queue.is_empty(): return
  track=music_queue.pop_front()
 music_last=track
 var stream=music_tracks[track]
 if stream is AudioStreamOggVorbis: stream.loop=music_context!="shop"
 music.stream=stream; music.volume_db=_music_db(); music.play()

func _next_track() -> void:
 if sim.state["settings"]["music"]: _start_music()

func _load_illustrated() -> void:
 illustrated_info=JSON.parse_string(FileAccess.get_file_as_string("res://assets/equipment/equipment.json"))
 for kind in illustrated_info:
  var sheet:Texture2D=load("res://assets/equipment/"+kind+".png")
  var image=sheet.get_image()
  illustrated[kind]=[]
  for frame in illustrated_info[kind]["frames"]:
   var r=frame["region"]
   var img=image.get_region(Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3])))
   illustrated[kind].append(ImageTexture.create_from_image(img))
   machine_images[kind+":"+str(illustrated[kind].size()-1)]=img

func _illustrated_icon(kind:String,rect:Rect2) -> void:
 var texture:Texture2D=illustrated[kind][14]
 var size=texture.get_size();size*=minf(rect.size.x/size.x,rect.size.y/size.y)
 draw_texture_rect(texture,Rect2(rect.get_center()-size*0.5,size),false)

func _rotate_equipment() -> void:
 if pending_equipment!="":
  placement_facing=(placement_facing+1)%16;placement_rotation=placement_facing/4
  _refresh_equipment_preview()
 elif _relocating():
  drag_facing=(drag_facing+1)%16;drag_rotation=drag_facing/4
  _refresh_equipment_preview()
 elif build and sim.state["machines"].has(selected_machine):
  var id="dtf2" if selected_machine=="shaker2" else ("dtf" if selected_machine=="shaker" else selected_machine)
  var m=sim.state["machines"][id]
  var facing=(sim.facing_of(m)+1)%16
  sim.rotate_equipment(id)

func _illustrated_prop(kind:String,p:Vector2) -> void:
 var info=illustrated_info[kind]["frames"][14]
 var size=Vector2(info["size"][0],info["size"][1])*zoom
 draw_texture_rect(illustrated[kind][14],Ground.rect_at(p,size,Vector2(info["origin"][0],info["origin"][1])),false)

func _illustrated_machine(id:String) -> void:
 var ms=_render_machines();var m=ms[id];var kind=str(m["kind"])
 if kind=="dtf":return
 var target=id
 if kind=="shaker":
  target="dtf2" if id=="shaker2" else "dtf";m=ms[target];kind="dtf"
 var facing=sim.facing_of(m)
 var frame=posmod(14-facing,16)
 var info=illustrated_info[kind]["frames"][frame]
 var p=iso(sim.equipment_center(target,ms))
 if build:
  var polygon=sim.equipment_polygon(target,ms)
  var points=[]
  for point in polygon:points.append(iso(point))
  var invalid=(target==pending_equipment or target==drag_id and _relocating()) and not drag_valid.get("valid",true)
  _poly(points,Color(.95,.12,.15,.25) if invalid else Color(.15,.9,.5,.22),RED if invalid else Color(.05,.5,.3,.6),1.5)
  _diamond(iso(Vector2(sim.service(target,ms))),25*zoom,12*zoom,CYAN)
 var size=Vector2(info["size"][0],info["size"][1])*zoom
 var anchor=Vector2(info["origin"][0],info["origin"][1])
 var rect=Ground.rect_at(p,size,anchor)
 if kind=="dock":
  # The truck parks outside; inside, the dock is the loading bay by the door.
  rect=_loading_bay(target,ms)
 else:
  var floor_poly=[]
  var center=sim.equipment_center(target,ms)
  for point in sim.equipment_polygon(target,ms):floor_poly.append(iso(center+(point-center)*.75))
  _poly(floor_poly,Color(0.1,.06,.02,.12),Color.TRANSPARENT,0)
  draw_texture_rect(illustrated[kind][frame],rect,false)
 if sim.state["machines"].has(target): _station_work_animation(target,p)
 world_hits.append({"id":target,"printer":target if kind=="dtf" else "","rect":rect,"sprite":kind+":"+str(frame),"flip":false,"illustrated":true,"facing":facing})
 var activity=sim.station_activity(target) if sim.state["machines"].has(target) else {"working":false}
 if not (photo_render or photo_active) and activity["working"]:
  world_labels.append({"at":p,"text":activity["phase"],"progress":sim.machine_progress(target)})
 elif not (photo_render or photo_active) and not build and sim.state["machines"].has(target):
  for oi in sim.active_orders():
   var job=sim.order(oi)
   if job.get("output_machine","")==target and job["stage"] in ["press","qc","pack","ready"]:
    var r=Rect2(p+Vector2(45,-27)*zoom,Vector2(38,38)*zoom)
    _panel(r,YELLOW,NAVY,8);_product(job["type"],r.get_center(),25*zoom)
    output_hits.append({"rect":r,"order":oi});break

func _station_work_animation(id:String,p:Vector2) -> void:
 var a=sim.station_activity(id)
 if build or not a["working"]: return
 var kind=sim.state["machines"][id]["kind"]
 var elapsed=0.0 if sim.state["settings"].get("reduce_motion",false) else float(a["elapsed"])
 var progress=float(a["progress"])
 var center=p+Vector2(0,-42)*zoom
 var scan=sin(elapsed*2.5)
 match kind:
  "dtf","shaker","banner","dtfmini":
   # Visible material and a bounded scan/take-up cue share the task clock.
   _panel(Rect2(center+Vector2(-32,-5)*zoom,Vector2(64,18)*zoom),CREAM,BLUE,2)
   for n in 4:
    var x=-27+n*16
    draw_line(center+Vector2(x,-2)*zoom,center+Vector2(x+10,8)*zoom,[CYAN,MAGENTA,YELLOW,NAVY][n],3*zoom)
   draw_line(center+Vector2(scan*26,-8)*zoom,center+Vector2(scan*26,13)*zoom,CYAN,2*zoom)
  "cutter","sticker","embroidery":
   # Cutting mat with a blade tracing the design outline.
   _panel(Rect2(center+Vector2(-30,-15)*zoom,Vector2(60,30)*zoom),Color("8fe3c2"),BLUE,2)
   draw_rect(Rect2(center+Vector2(-22,-11)*zoom,Vector2(44,22)*zoom),MAGENTA if kind=="cutter" else CREAM)
   var outline=[]
   for k in 11:
    var rad=(10.0 if k%2==0 else 4.5)
    outline.append(center+Vector2(cos(-PI/2+k*PI/5)*rad*1.6,sin(-PI/2+k*PI/5)*rad)*zoom)
   draw_polyline(PackedVector2Array(outline),CREAM if kind=="cutter" else MAGENTA,1.5*zoom)
   var t=fmod(elapsed*.6,10.0)
   draw_circle(outline[int(t)].lerp(outline[int(t)+1],fmod(t,1.0)),3.5*zoom,NAVY)
  "cnc":
   var u=fmod(elapsed*.22,4)
   var corners=[Vector2(-32,-13),Vector2(32,-13),Vector2(32,13),Vector2(-32,13),Vector2(-32,-13)]
   var at=corners[int(u)].lerp(corners[int(u)+1],fmod(u,1))
   draw_polyline(PackedVector2Array(corners.map(func(q):return center+q*zoom)),YELLOW,2*zoom)
   draw_circle(center+at*zoom,5*zoom,NAVY)
  "heat","mug":
   var closed="Heat press" in a["phase"] or "Press mugs" in a["phase"]
   draw_line(center+Vector2(-24,-15 if closed else -28)*zoom,center+Vector2(24,-15 if closed else -28)*zoom,RED if closed else BLUE,7*zoom)
   _product("mug" if kind=="mug" else "apparel",center+Vector2(0,4)*zoom,30*zoom)
  "art":
   _panel(Rect2(center+Vector2(-24,-16)*zoom,Vector2(48,30)*zoom),CREAM,BLUE,2)
   draw_line(center+Vector2(-16,0)*zoom,center+Vector2(16*scan,4)*zoom,MAGENTA,3*zoom)
  "finish":
   draw_arc(center,16*zoom,0,TAU*progress,24,GREEN,3*zoom)
   _text(center+Vector2(-6,7)*zoom,"✓",int(20*zoom),BLUE)
  "pack","dock":
   _panel(Rect2(center+Vector2(-24,-12)*zoom,Vector2(48,31)*zoom),Color("d5a467"),NAVY,2)
   draw_line(center+Vector2(0,-12)*zoom,center+Vector2(0,19)*zoom,YELLOW,5*zoom)
   draw_line(center+Vector2(-24,1)*zoom,center+Vector2(lerpf(-24,24,progress),1)*zoom,CREAM,3*zoom)

func _stamp_offline() -> void:
 var ops=sim.state.get("operations",{})
 if ops.get("away",false) and ops.get("offline_enabled",false):ops["offline_anchor"]=int(Time.get_unix_time_from_system())

func _workshop_action(action:String) -> bool:
 var p=action.split(":")
 if p[0] not in ["studio","shop_name_save","decor_cycle","decor_move","decor_remove_selected","artwork_offer","art_decide","back_order","photo_logo","photo_watermark","photo_corner","photo_opacity","workshop","worktab","promotion","service","finance","decor","decor_remove","floor_next","floor_import","outfit_worker","outfit_next","away_toggle","offline_toggle","offline_settle","auto_service","qte_toggle","assist_toggle","events_toggle","event","intervene","jam","qte_hit","qte_skip","photo_mode","photo_close","photo_export","photo_format","photo_imported","photo_fit","photo_controls","photo_folder"]:return false
 Ops.ensure(sim);Style.ensure(sim)
 var ops=sim.state["operations"];var style=sim.state["style"]
 match p[0]:
  "studio":
   _cancel_world_drag();modal="studio";shop_name_edit.text=style["shop_name"]
  "shop_name_save":Style.rename_shop(sim,shop_name_edit.text)
  "decor_cycle":
   var ids=[]
   for item in style["decor"]:ids.append(item["id"])
   if not ids.is_empty():selected_decor=ids[posmod(ids.find(selected_decor)+int(p[1]),ids.size())]
  "decor_move":
   var item=Style.item(sim,selected_decor)
   if not item.is_empty():
    _cancel_world_drag();decor_previous_pause=sim.state["paused"];moving_decor=selected_decor;decor_point=sim.cell(item["pos"]);sim.state["paused"]=true;modal="";build=false
  "decor_remove_selected":Style.remove(sim,selected_decor)
  "artwork_offer":
   if Art.propose(sim,selected_order):modal="artwork"
  "art_decide":
   if Art.resolve(sim,selected_order,p[1]):modal="order"
  "back_order":modal="order"
  "workshop":_cancel_world_drag();workshop_page=0;modal="workshop"
  "worktab":
   workshop_page=int(p[1]);modal="workshop"
   if p.size()>2:workshop_service_page=int(p[2])
  "promotion":Ops.promo(sim)
  "service":Ops.start_service(sim,p[1]);modal="";sim.state["paused"]=false
  "finance":
   if Ops.finance(sim,p[1]):_action("place:"+p[1])
  "decor":_cancel_world_drag();decor_previous_pause=sim.state["paused"];pending_decor=p[1];decor_point=Vector2i(2,2);modal="";build=false;sim.state["paused"]=true
  "decor_remove":Style.remove(sim)
  "floor_next":
   var floors=Style.FLOORS.keys();style["floor"]=floors[(floors.find(style["floor"])+1)%floors.size()];style["floor_image"]=""
  "floor_import":
   var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
   dialog.filters=PackedStringArray(["*.png ; PNG floor image (local)"]);dialog.title="Choose a local floor PNG / maximum 8 MB and 2048 x 2048"
   dialog.use_native_dialog=true;add_child(dialog)
   dialog.file_selected.connect(func(path):Style.import_png(sim,path);dialog.queue_free())
   dialog.canceled.connect(dialog.queue_free);dialog.popup_centered_ratio(.75)
  "outfit_worker":
   var ids=[]
   for w in sim.state["workers"]:ids.append(w["id"])
   style_worker=ids[(ids.find(style_worker)+1)%ids.size()]
  "outfit_next":
   var current=style["outfits"].get(style_worker,"Workshop")
   Style.set_outfit(sim,style_worker,Style.OUTFITS[(Style.OUTFITS.find(current)+1)%Style.OUTFITS.size()])
  "away_toggle":Ops.away(sim,not ops["away"]);modal="workshop" if not ops["away"] else ""
  "offline_toggle":ops["offline_enabled"]=not ops["offline_enabled"];_stamp_offline()
  "offline_settle":Ops.settle_offline(sim)
  "auto_service":ops["auto_service"]=not ops["auto_service"]
  "qte_toggle":ops["qte_enabled"]=not ops["qte_enabled"]
  "assist_toggle":ops["assist"]=not ops["assist"]
  "events_toggle":ops["event_enabled"]=not ops["event_enabled"]
  "event":
   if Ops.resolve_event(sim,p[1]) and p[1]=="artwork" and int(ops.get("artwork_order",-1))>=0:selected_order=int(ops["artwork_order"]);modal="artwork"
  "intervene":
   var o=sim.order(selected_order);var kind="registration" if o.get("type","")=="sticker" else "press"
   if Ops.begin_qte(sim,selected_order,kind):qte_previous_pause=sim.state["paused"];sim.state["paused"]=true;modal="intervention"
   else:
    var reason=Ops.qte_unavailable(sim,selected_order,kind) if not o.is_empty() else "Select a current job"
    sim.notice("Optional timing unavailable: "+(reason if reason!="" else "today's limit is reached")+".")
  "jam":
   if Ops.begin_jam(sim,p[1]):qte_previous_pause=sim.state["paused"];sim.state["paused"]=true;modal="intervention"
  "qte_hit","qte_skip":
   if Ops.qte_result(sim,p[0]=="qte_skip"):sim.state["paused"]=qte_previous_pause;modal="order";sim.save_game()
  "photo_mode":
   if screen!="shop":return true
   Photo.ensure(sim)
   _cancel_world_drag();photo_previous={"paused":sim.state["paused"],"zoom":zoom,"offset":offset,"origin":origin,"modal":modal,"build":build}
   photo_active=true;photo_controls_hidden=false;sim.state["paused"]=true;modal="";build=false;reset_camera();Photo.fit(self);status="";return true
  "photo_close":
   if photo_busy:return true
   photo_active=false;sim.state["paused"]=photo_previous.get("paused",true);zoom=photo_previous.get("zoom",zoom);offset=photo_previous.get("offset",offset);origin=photo_previous.get("origin",origin);modal=photo_previous.get("modal","");build=photo_previous.get("build",false)
  "photo_logo","photo_watermark","photo_corner","photo_opacity":
   Photo.ensure(sim);var brand=sim.state["style"]["photo"]
   if action=="photo_logo":brand["logo"]=not brand["logo"]
   elif action=="photo_watermark":brand["watermark"]=not brand["watermark"]
   elif action=="photo_corner":brand["corner"]=(int(brand["corner"])+1)%4
   else:brand["opacity"]=.25 if float(brand["opacity"])>=1.0 else float(brand["opacity"])+.25
   return true
  "photo_format":photo_format=int(p[1]);return true
  "photo_export":Photo.export_png(self,int(p[1]));return true
  "photo_imported":photo_imported=not photo_imported;return true
  "photo_fit":Photo.fit(self);return true
  "photo_controls":photo_controls_hidden=not photo_controls_hidden;return true
  "photo_folder":
   if photo_last_path!="":OS.shell_open(photo_last_path.get_base_dir())
   return true
 if not photo_active:sim.save_game()
 return true

func _intervention_panel() -> void:
 var q=sim.state["operations"]["active_qte"]
 _header("OPTIONAL SHOP INTERVENTION","Shop time is held. Your timing is independent of shop speed. Skipping retains ordinary production.")
 if q.is_empty():return
 _text(Vector2(389,284),str(q["kind"]).to_upper()+ (" / STEP %d OF 3" % (int(q["step"])+1) if q["kind"]=="jam" else "")+ (" / FIRST PRACTICE" if q["practice"] else ""),27,BLUE)
 var benefit="Three accurate steps clear the fault using one kit; skipping leaves normal service available." if q["kind"]=="jam" else "An accurate intervention gives this job a 5% task-time benefit, with no cash reward."
 _text(Vector2(389,340),"Press when the marker is in the green zone. Timing Assist accepts any press.\n"+benefit+"\nFocus loss holds this timer. There is no automatic timeout or reaction penalty.",18,INK,810)
 draw_rect(Rect2(389,448,818,36),NAVY);draw_rect(Rect2(593,448,410,36),GREEN)
 var x=389+fmod(float(q["elapsed"]),2.0)/2.0*818
 draw_rect(Rect2(x-4,439,8,54),YELLOW)
 _button(Rect2(389,542,818,57),"REGISTER / PRESS","qte_hit",CYAN)
 _button(Rect2(389,633,818,48),"SKIP / ORDINARY AUTOMATIC PRODUCTION","qte_skip",CREAM,true,18)

func _draw_unboxing(id:String) -> void:
 if photo_render or photo_active or sim.state["settings"].get("reduce_motion",false):return
 var m=sim.state["machines"].get(id,{})
 if m.get("unbox_remaining",0)<=0:return
 var p=iso(sim.equipment_center(id,sim.state["machines"]))
 var z=zoom;var size=Vector2(95,57)*z
 _poly([p+Vector2(-55,4)*z,p+Vector2(8,32)*z,p+Vector2(60,7)*z,p+Vector2(-3,-20)*z],Color("8a6546"),NAVY,1)
 _panel(Rect2(p-Vector2(47,64)*z,size),Color("bc915e"),Color("795533"),2)
 draw_line(p+Vector2(0,-64)*z,p+Vector2(0,-7)*z,Color("f2dfac"),8*z)
 _line(p+Vector2(-39,-25)*z,"UNPACKING",maxi(10,int(12*z)),NAVY,80*z,true)

func _draw_world_labels() -> void:
 var used=[]
 for label in world_labels:
  var at=label["at"];var height=38 if label["progress"]>=0 else 24
  var w=clampf(font.get_string_size(str(label["text"]),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+16,120,250)
  var size=Vector2(w,height);var rect=Rect2(at+Vector2(-w*.5,22),size);var found=false
  for n in 24:
   var candidate=Rect2(at+Vector2(-w*.5+(n%3-1)*(w+14),20+floori(n/3.0)*43),size)
   if not SHOP_VIEW.encloses(candidate):continue
   var blocked=false
   for hit in worker_hits:
    if candidate.intersects(hit["rect"].grow(3)):blocked=true;break
   for r in used:
    if candidate.intersects(r.grow(3)):blocked=true;break
   if not blocked:rect=candidate;found=true;break
  if not found:continue
  used.append(rect)
  draw_line(at,rect.get_center(),Color(.1,.2,.3,.3),1)
  _panel(rect,NAVY,NAVY,4)
  _line(rect.position+Vector2(7,17),label["text"],12,CREAM,w-14)
  if label["progress"]>=0:draw_rect(Rect2(rect.position+Vector2(7,27),Vector2((w-14)*label["progress"],5)),GREEN)

func _cash_bridge_panel() -> void:
 var report=sim.end_day();var stats=report["stats"];var bridge=report.get("cash_bridge",{})
 _header("DAILY CASH BRIDGE","Operating profit and cash balance differ when you buy stock, equipment or premises, or repay debt.")
 var rows=[["Opening cash",bridge.get("opening",0)],["Sales collected + recovery + loan receipts",stats["sales"]+stats.get("recovery",0)+stats.get("loan_in",0)],["Supply purchases (not stock consumed)",-stats.get("supply_purchases",0)],["Premises / equipment / decor",-stats.get("capex",0)],["Hiring / upgrades",-stats.get("hiring",0)-stats.get("upgrades",0)],["Artwork / marketing / event costs",-stats["art_fees"]-stats.get("marketing",0)-stats.get("hurdles",0)],["Current cash before closing bills",report.get("cash_before_bills",sim.state["cash"])],["Daily wages / overhead",-stats["wages"]-stats["overhead"]],["Loan / equipment repayments",-stats.get("loan_payment",0)-stats.get("equipment_finance",0)],["Cash after closing bills",report.get("cash_after_bills",sim.state["cash"])]]
 for i in rows.size():
  var y=238+i*40
  _text(Vector2(389,y),rows[i][0],18,BLUE if i in [0,6,9] else INK)
  _text(Vector2(1060,y),"$%.0f" % rows[i][1],18,BLUE)
 _text(Vector2(389,669),"Stock consumption is already paid through inventory purchases; it is not charged twice.",16,MUTED,810)
 _button(Rect2(389,715,818,40),"BACK TO DAY REPORT","report",NAVY)

func _commit_decor(at:Vector2i) -> void:
 var moved=Style.move(sim,moving_decor,at) if moving_decor!="" else Style.place(sim,pending_decor,at)
 if moved:
  _cancel_world_drag();sim.save_game()

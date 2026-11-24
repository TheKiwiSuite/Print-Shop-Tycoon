extends SceneTree
# Native captures for the starter equipment and character variety pass.
const C=preload("res://scripts/catalog.gd")
var game
var folder=""
var failures=0
var checks=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func capture(name:String) -> void:
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image();check(not image.is_empty(),"Frame rendered "+name)
 if not image.is_empty():image.save_png(folder.path_join(name+".png"))
 for i in game.buttons.size():
  var a=game.buttons[i];check(Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(a["rect"]),"Button inside screen "+name+" / "+a["action"])
  for j in range(i+1,game.buttons.size()):
   var b=game.buttons[j];check(not a["rect"].intersects(b["rect"]),"No control overlaps "+name+" / "+a["action"]+" / "+b["action"])
func run() -> void:
 folder=ProjectSettings.globalize_path("res://../captures/starter-review");DirAccess.make_dir_recursive_absolute(folder)
 game=load("res://main.tscn").instantiate();game.sim.save_enabled=false;root.add_child(game);game.set_process(false)
 game.music.stop();game.qa_ui=true
 root.size=Vector2i(1600,900);await process_frame
 var s=game.sim
 game.screen="shop";s.state["cash"]=20000
 game.modal="equipment";game.equipment_page=0;await capture("equipment-menu-starters")
 game.modal=""
 check(s.install_equipment("cutter",Vector2i(4,4)),"Place cutter for review")
 check(s.install_equipment("dtfmini",Vector2i(1,7)),"Place desktop DTF for review")
 for id in ["art","finish","pack","heat"]:
  check(s.install_equipment(id,s.cell(C.layout(1)[id]["pos"])),"Place "+id+" for review")
 check(s.hire(1),"Hire one helper for the desktop DTF")
 game.reset_camera();await capture("shop-starters-placed")
 game.selected_machine="cutter";game.modal="machine";await capture("machine-cutter")
 game.selected_machine="dtfmini";game.modal="machine";await capture("machine-dtfmini")
 game.modal="stock";await capture("supplies-with-vinyl")
 game.modal=""
 # Run the shop so customers arrive and staff work at the new stations.
 s.state["paused"]=false;s.owner()["manual"]=false
 var decal=C.make_order("DEC-QA","decal",24,"Visual review decals",s.now()+6,96)
 s.state["orders"].append(decal)
 var captured={}
 for n in 4000:
  s.tick(.1)
  for i in s.active_orders():
   var o=s.order(i)
   if o["stage"]=="intake": s.accept(i)
   elif o["stage"]=="preflight": s.preflight(i,"repair")
   elif o["stage"]=="plan":
    if o["type"] in ["transfer","apparel"]: s.auto_pack(i)
    s.queue_order(i)
  for w in s.state["workers"]:
   if w["task"].is_empty() or not w["task"]["working"]: continue
   var m=w["task"]["machine"]
   if m in ["cutter","dtfmini"] and not captured.has(m):
    captured[m]=true
    game.reset_camera();await capture("working-"+m+"-wide")
    # Zoom on the operator so the tool and look are readable.
    game.zoom=2.0;game.offset=Vector2.ZERO
    game.origin=game.SHOP_VIEW.get_center()-Vector2((w["pos"][0]-w["pos"][1])*48,(w["pos"][0]+w["pos"][1])*23)*game.zoom
    await capture("working-"+m+"-zoom")
  if captured.size()==2: break
 check(captured.has("cutter"),"A worker operates the vinyl cutter")
 check(captured.has("dtfmini"),"A worker operates the desktop DTF kit")
 game.reset_camera();await capture("shop-busy")
 # New-career walkthrough: gift, guide card steps, locked DTF, first vinyl shirts.
 var w=game.sim
 w.start_shop("Standard");game.screen="shop";game.reset_camera()
 game.modal="welcome_gift";await capture("walkthrough-welcome")
 game.modal="";await capture("walkthrough-step-gift")
 game.modal="equipment";game.equipment_page=0;await capture("walkthrough-menu-locked-dtf")
 game.modal=""
 check(w.install_equipment("cutter",C.garage_spot("cutter")),"Walkthrough cutter placed")
 await capture("walkthrough-step-press")
 check(w.install_equipment("heat",C.garage_spot("heat")),"Walkthrough heat press placed")
 await capture("walkthrough-step-benches")
 for id in ["art","finish","pack"]: check(w.install_equipment(id,C.garage_spot(id)),"Walkthrough bench "+id)
 await capture("walkthrough-step-open")
 w.state["paused"]=false;w.owner()["manual"]=false
 var pressed=false
 for n in 6000:
  w.tick(.1)
  var o=w.order(0)
  if o["stage"]=="intake": w.accept(0)
  elif o["stage"]=="plan": w.queue_order(0)
  if not pressed and o["stage"]=="pressing":
   pressed=true
   game.zoom=2.0;game.offset=Vector2.ZERO
   var p=w.owner()["pos"]
   game.origin=game.SHOP_VIEW.get_center()-Vector2((p[0]-p[1])*48,(p[0]+p[1])*23)*game.zoom
   await capture("walkthrough-pressing-shirts")
   game.reset_camera()
  if o["stage"]=="completed": break
 check(pressed,"Walkthrough job reaches the heat press")
 check(w.walkthrough_step()=="done","Walkthrough reaches the first-sale card")
 await capture("walkthrough-step-done")
 game.modal="staff";await capture("walkthrough-staff-cap")
 game.modal="customers";game.reviews_view=false;await capture("customers-receipts")
 game.reviews_view=true;await capture("customers-reviews")
 game.reviews_view=false;game.modal=""
 game.modal=""
 # Shop level, goals, awards and the ending.
 game._progress_events()
 check(game.modal=="levelup","The first sale raises the shop level")
 await capture("progress-levelup")
 game._action("close")
 check(not game.toasts.is_empty(),"A finished goal shows a banner")
 await capture("progress-toast-and-level-bar")
 game._action("goals");await capture("progress-goals")
 game._action("goals_awards");await capture("progress-awards")
 game._action("close")
 game._action("walkthrough_done");await capture("progress-next-goal-card")
 game.progress_card={"kind":"ending"};game.modal="ending";await capture("progress-ending")
 game.modal=""
 game.modal="equipment";game.equipment_page=0;await capture("progress-equipment-levels")
 game.modal=""
 # The premises ladder: garage, storefront, warehouse, factory.
 game.toasts.clear();game.reset_camera();await capture("premises-1-garage")
 game.modal="move";await capture("premises-growth-from-garage")
 game.modal=""
 game.Progress.ensure(w)["xp"]=game.Progress.LEVEL_XP[w.STOREFRONT_LEVEL-1];w.state["cash"]=6000
 for worker in w.state["workers"]: worker["task"]={};worker["path"]=[]
 check(w.move_to_storefront(),"Lease the storefront for review")
 game.Progress.pop_events(w);game.reset_camera();await capture("premises-2-storefront")
 game.modal="move";await capture("premises-growth-from-storefront")
 game.modal=""
 w.state["reputation"]=85;w.state["completed"]=12;w.state["on_time"]=12;w.state["quality_total"]=1200
 check(w.expand_premises(),"Move to the warehouse for review")
 game.reset_camera();await capture("premises-3-warehouse")
 check(w.fit_out(),"Fit out the warehouse for review")
 w.state["cash"]=20000
 check(game.Ops.annex(w),"Open the factory for review")
 game.Progress.pop_events(w);game.reset_camera();await capture("premises-4-factory")
 # New products: mug press and embroidery machine in the factory, their orders and supplies.
 game.Progress.ensure(w)["xp"]=game.Progress.LEVEL_XP[6]
 check(w.install_equipment("mug",Vector2i(12,3)),"Place the mug press for review")
 check(w.install_equipment("embroidery",Vector2i(12,6)),"Place the embroidery machine for review")
 game.Progress.pop_events(w);game.toasts.clear();game.reset_camera();await capture("products-machines")
 var hood=C.make_order("HOOD-QA","apparel",6,"Review hoodies",w.now()+8,300);C.apply_blank(hood,"hoodie")
 for o in [C.make_order("MUG-QA","mug",12,"Review mugs",w.now()+8,108),C.make_order("HAT-QA","hat",8,"Review hats",w.now()+8,128),hood]: w.state["orders"].append(o)
 game.reset_camera();await capture("products-order-cards")
 game.modal="stock";await capture("products-supplies")
 game.modal="equipment";game.equipment_page=0;await capture("products-equipment-menu")
 game.modal=""
 # Merch line: designs, trend, online store and the weekend craft market.
 game.modal="merch";await capture("merch-1-empty")
 for k in ["tee","sticker","mug","hat"]: check(not game.Merch.create_design(w,k,game.Merch.THEMES[["tee","sticker","mug","hat"].find(k)+(1 if k=="sticker" else 0)]).is_empty(),"Create a "+k+" design")
 var first=game.Merch.ensure(w)["designs"][0]
 first["stock"]=12;check(game.Merch.make_batch(w,game.Merch.ensure(w)["designs"][2]["id"]),"Queue a mug batch")
 game.Merch.toggle_store(w);w.state["day"]=6;game.Merch.book_booth(w)
 await capture("merch-2-designs")
 game.Merch.close_day(w);await capture("merch-3-sold")
 game.modal="";game.toasts.clear();await capture("merch-4-card-button")
 # Rival shop and staff personalities.
 w.state["day"]=game.People.RIVAL_DAY;game.People.rival(w)
 game.modal="customers";game.reviews_view=true;await capture("people-rival")
 w.state["cash"]=20000;check(w.hire(1) and w.hire(2),"Hire two staff with personalities")
 game.reviews_view=false;game.modal="roster";await capture("people-roster")
 game.modal=""
 # Shipping dock: loading bay inside, open roll-up door, truck parked in the yard outside.
 check(w.install_equipment("dock",Vector2i(w.bounds().x-2,8)),"Place the shipping dock against the outside wall")
 game.reset_camera();await capture("dock-1-yard")
 game.zoom=1.7;game.offset=Vector2.ZERO
 var dock_view=Vector2(w.bounds().x+0.8,9.0)
 game.origin=game.SHOP_VIEW.get_center()-Vector2((dock_view.x-dock_view.y)*48,(dock_view.x+dock_view.y)*23)*game.zoom
 await capture("dock-2-closeup")
 game.reset_camera()
 game.modal=""
 print("STARTER VISUAL REVIEW: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Strategy=preload("res://scripts/shop_strategy.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error("FAIL: "+label)
 else: print("PASS: "+label)
func full(preset:String="Standard"):
 var s=Sim.new();s.state=C.fresh();s.save_enabled=false
 s.state["rules"]=Strategy.rules(preset);Strategy.ensure(s)
 return s
func pump(s,limit:int=2500) -> void:
 s.state["paused"]=false;s.state["speed"]=4;s.owner()["manual"]=false
 for n in limit:
  s.tick(.1)
  if s.state["paused"] or s.active_orders().is_empty(): break
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for name in Strategy.PRESETS:
  var s=Sim.new();s.save_enabled=false;s.start_shop(name)
  check(s.state["cash"]==roundi(1600*Strategy.rules(name)["cash"]),"Opening budget matches "+name)
  check(s.state["cash"]-500-125*Strategy.rules(name)["overhead"]>0,"Starter sticker route retains a cash buffer: "+name)
 var bounded=Strategy.rules("Custom",{"cash":100,"slack":-2,"faults":0})
 check(bounded["cash"]==2 and bounded["slack"]==.5 and bounded["faults"]==.5,"Custom rules are safely bounded")
 var legacy=Sim.new();legacy.state=C.fresh();legacy.save_enabled=false
 var cash=legacy.state["cash"];var due=legacy.order(0)["due"]
 Strategy.ensure(legacy)
 check(legacy.state["cash"]==cash and legacy.order(0)["due"]==due and legacy.state["rules"]["version"]==0,"Migration keeps legacy cash and accepted terms")
 var s=full()
 var before=JSON.stringify(s.state)
 var normal=s.quote(0);var rush=s.quote(0,true)
 check(normal["valid"] and normal["finish"]>=s.now() and normal["due"]>normal["finish"],"Normal quote covers modeled route plus slack")
 check(rush["payout"]>normal["payout"] and rush["due"]<normal["due"],"Rush previews premium and tighter deadline")
 check(JSON.stringify(s.state)==before,"Forecast and quote do not mutate an established shop")
 check(s.accept(0,true),"Accept forecast rush terms")
 var terms=s.order(0).duplicate(true)
 check(not s.change_rules("Expert"),"Difficulty change requires a paused shop")
 s.state["paused"]=true
 check(s.change_rules("Relaxed"),"Explicit paused rule change succeeds")
 check(s.order(0)["due"]==terms["due"] and s.order(0)["reward"]==terms["reward"] and s.order(0)["fault_roll"]==terms["fault_roll"],"Rule changes preserve accepted price deadline and fault outcome")
 check(s.state["cash"]==1200,"Rule change creates no free starting money")
 s.order(1)["stage"]="intake"
 check(not s.quote(1,true)["valid"],"Rush premiums have a disclosed daily capacity limit")
 s.state["stock"]["packaging"]=0;s.state["garments"]["navy:S"]=0
 var board=s.capacity_board(true)
 var apparel={}
 for row in board["rows"]:
  if row["index"]==2: apparel=row
 check(apparel["missing"].has("packaging") and apparel["missing"].has("garment:navy:S"),"Forecast includes boxes and garment sizes before acceptance")
 check(apparel["risk"]=="BLOCKED" and apparel["finish"]<0,"Missing stock has no invented completion ETA")
 var supply=full();supply.state["orders"]=[C.make_order("A","sticker",12,"A",6,50),C.make_order("B","sticker",12,"B",6,50)]
 supply.state["stock"]["sticker"]=0;supply.state["deliveries"]=[{"items":{"sticker":1},"eta":1.0,"cost":1}]
 var rows=supply.capacity_board(true)["rows"]
 check(rows[0]["finish"]>=1 and rows[1]["missing"].has("sticker"),"One incoming unit is not promised to two jobs")
 var expand=full();expand.state["cash"]=3000;expand.state["completed"]=3;expand.state["on_time"]=3;expand.state["quality_total"]=300;expand.state["reputation"]=70
 var layout=expand.state["machines"].duplicate(true)
 check(expand.move_garage(),"Staged premises unlock through actual progression gates")
 check(expand.state["machines"]==layout and expand.state["cash"]==2100,"Expansion retains layout and charges only premises")
 check(not expand.install_feedback("banner",Vector2i(13,3))["valid"],"Industrial equipment waits for explicit fit-out")
 check(expand.fit_out() and expand.state["cash"]==1750,"Fit-out is a separate visible investment")
 check(expand.state["machines"].size()==layout.size(),"Fit-out supplies no free machines")
 var repeat=full();var original=repeat.order(0)
 original["stage"]="completed";original["paid"]=true;original["rush"]=true;original["reward"]=624;original["base_reward"]=480
 original["gang"]=Strategy.planned(original)["gang"]
 check(repeat.repeat_order(0),"Completed client can request a new inquiry")
 var next=repeat.order(repeat.state["orders"].size()-1)
 check(next["stage"]=="intake" and next["art_ready"] and next["gang"]==original["gang"] and not next.get("paid",false),"Repeat preserves approved art with independent fulfillment")
 check(next["reward"]==480,"Repeated rush jobs cannot compound their premium")
 var batch=full();batch.state["orders"]=[]
 for n in 2:
  var o=C.make_order("MIX-%d" % n,"transfer" if n==0 else "apparel",1,"Client%d" % n,8,50)
  o["art_ready"]=true;o["stage"]="plan";o["gang"]=Strategy.planned(o)["gang"]
  batch.state["orders"].append(o)
 var preview=batch.batch_preview(0)
 check(preview["valid"] and preview["saved"]==4 and preview["slots"].size()==2,"Mixed client batch records every design and saves a physical sheet")
 var valid_slots=true
 for slot in preview["slots"]:
  var r=slot["rect"]
  valid_slots=valid_slots and Rect2(0,0,24,48).encloses(Rect2(r[0],r[1],r[2],r[3]))
 check(valid_slots,"Every customer design remains within physical batch sheet bounds")
 var film=batch.state["stock"]["film"];var boxes=batch.state["stock"]["packaging"];var money=batch.state["cash"]
 check(batch.batch_orders(0),"Compatible transfer and apparel orders form one physical print batch")
 pump(batch)
 check(batch.order(0)["paid"] and batch.order(1)["paid"],"Both batch clients finish and receive distinct payments")
 check(batch.state["cash"]==money+100 and batch.state["stock"]["film"]==film-4 and batch.state["stock"]["packaging"]==boxes-2,"Batch stock output and payment reconcile exactly")
 check(batch.order(1).get("press_done",false),"Apparel batch output still requires its heat press")
 var settled=batch.state["cash"]
 batch._fulfill(batch.order(0));batch._fulfill(batch.order(1))
 check(batch.state["cash"]==settled,"Batch handoff remains idempotent")
 batch.order(1)["stage"]="fault"
 check(batch.recover(1,true) and not batch.order(1).has("batch_recipe") and batch.order(1)["recipe"]["film"]==4,"Individual reprint detaches from discounted shared film allocation")
 var support=full("Relaxed");support.state["paused"]=true
 var at=support.now();var funds=support.state["cash"]
 check(support.recovery_shift() and support.now()==at+2 and support.state["cash"]==funds+100,"Recovery income spends disclosed finite shop time")
 check(support.rescue_loan() and not support.rescue_loan(),"Relaxed rescue loan is opt-in and one-time")
 var report=support.end_day();support.next_day()
 check(support.state["loan_remaining"]==350,"Disclosed loan repayment occurs at day close")
 var persisted=full();persisted.save_enabled=true;persisted.save_path="user://strategy-schema-qa.json"
 check(persisted.save_game() and persisted.save_game(),"Create isolated valid save and backup")
 var bad=FileAccess.open(persisted.save_path,FileAccess.WRITE)
 bad.store_string(JSON.stringify({"format":"PrintShopTycoonNative","schema":3,"state":{"cash":1,"clock":8,"day":1,"location":1,"machines":{},"workers":[{}],"orders":[],"stock":{}}}));bad.close()
 var repaired=Sim.new();repaired.save_path=persisted.save_path;repaired.save_enabled=false
 check(repaired.load_game() and not repaired.owner().is_empty(),"Malformed main state falls back to structurally valid backup")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(persisted.save_path+suffix): DirAccess.remove_absolute(persisted.save_path+suffix)
 # Real game scene and keyboard/accessibility integration.
 var game=load("res://main.tscn").instantiate();root.add_child(game);game.set_process(false)
 game.sim.save_enabled=false;game.sim.save_path="user://strategy-ui-qa.json";game.screen="shop"
 game._action("new");check(game.modal=="confirm_new","Every new shop exposes difficulty before creation")
 game._action("rules_preset:Expert");game._action("new_confirm")
 check(game.sim.state["rules"]["preset"]=="Expert","New-game selection reaches the actual simulation")
 game._action("place:sticker")
 var key=InputEventKey.new();key.pressed=true;key.keycode=KEY_RIGHT
 var point=game.drag_point;game._input(key)
 check(game.drag_point==point+Vector2i.RIGHT,"Equipment placement supports keyboard movement")
 game._cancel_world_drag();game._action("capacity")
 check(game.modal=="capacity","Capacity board is connected to live actions")
 var motion_before=game.sim.state["settings"].get("reduce_motion",false)
 game._action("reduce_motion")
 check(game.sim.state["settings"]["reduce_motion"]!=motion_before,"Reduce Motion is connected to application preferences")
 game._action("accessibility");game._action("bind:up")
 var remap=InputEventKey.new();remap.pressed=true;remap.keycode=KEY_I;game._input(remap)
 check(game.movement_bindings["up"]==KEY_I and game.binding_action=="","Movement remapping captures a permitted key")
 game.movement_bindings["up"]=KEY_W;game._load_music_preference()
 check(game.movement_bindings["up"]==KEY_I,"Movement preference survives shop snapshot restoration")
 var preferences=game.sim.save_path+".preferences.cfg"
 if FileAccess.file_exists(preferences): DirAccess.remove_absolute(preferences)
 game.free();await process_frame
 print("STRATEGY GROWTH: ",checks," checks, ",failures," failures")
 quit(failures)

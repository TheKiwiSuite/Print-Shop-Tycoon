extends RefCounted
# Panels for 1.2.0: end-of-day plan, business specialization and clients/contracts.
# Drawing only; every value comes from shop_planning / shop_strategy /
# shop_contracts and the live simulation. Coordinates use the shared 1600x900
# modal frame (panel 355..1245 x 105..785).
const Planning=preload("res://scripts/shop_planning.gd")
const Strategy=preload("res://scripts/shop_strategy.gd")
const Contracts=preload("res://scripts/shop_contracts.gd")
const RISK_COLOR={"ON TRACK":Color("1f7a4c"),"AT RISK":Color("9a5b00"),"OVERDUE":Color("b52742"),"BLOCKED":Color("b52742")}

static func _short_items(items:Dictionary,limit:int=4) -> String:
 var parts=[]
 for key in items:
  parts.append("%d %s" % [int(items[key]),String(key).trim_prefix("garment:").replace("_"," ")])
 if parts.size()>limit: return ", ".join(parts.slice(0,limit))+" +%d more" % (parts.size()-limit)
 return ", ".join(parts)

static func _heading(g,p:Vector2,text:String) -> void:
 g._text(p,text,15,g.BLUE,-1,true)

static func draw_plan(g) -> void:
 var s=g.sim
 var plan=Planning.plan(s)
 var day=int(s.state["day"])+(0 if s.state["report"].is_empty() else 1)
 var pending=not s.state["report"].is_empty()
 g._header("PLAN DAY %d" % day,"Actual = already fixed by today's close. Estimate = forecast from your shop right now.")
 # Left column: bills and committed work.
 _heading(g,Vector2(389,226),"BILLS")
 if pending: g._line(Vector2(389,250),"Charged when Day %d starts (actual): $%.0f" % [day,plan["due_now"]],15,g.INK,404)
 else: g._line(Vector2(389,250),"Today's bills are charged when this day closes.",15,g.INK,404)
 g._line(Vector2(389,272),"At Day %d close (estimate): $%.0f wages + overhead + debt" % [day,plan["next_close"]],15,g.INK,404)
 var focus_cost=plan["focus_cost"] if pending else 0.0
 g._line(Vector2(389,294),"Cash after the day starts (estimate): $%.0f" % (plan["cash"]-(plan["due_now"] if pending else 0.0)-focus_cost),15,g.RED if plan["cash"]-plan["due_now"]-focus_cost<0 else g.INK,404)
 _heading(g,Vector2(389,330),"COMMITTED JOBS (estimates)")
 var y=354
 var shown=0
 for j in plan["jobs"]:
  if shown>=5: break
  var tag=" (contract)" if j["contract"] else ""
  g._line(Vector2(389,y),"%s%s / due %s / %s" % [j["label"],tag,g._due({"due":j["due"]}),j["risk"]],14,RISK_COLOR.get(j["risk"],g.INK),404)
  y+=21;shown+=1
 if plan["jobs"].size()>shown: g._line(Vector2(389,y),"+%d more on the capacity board (Q)" % (plan["jobs"].size()-shown),13,g.MUTED,404);y+=21
 if plan["jobs"].is_empty(): g._line(Vector2(389,y),"No accepted jobs yet. New inquiries arrive when the day starts.",14,g.MUTED,404);y+=21
 for d in plan["scheduled"].slice(0,2):
  g._line(Vector2(389,y),"Contract %d/%d: %s for %s, added at 8:00" % [d["n"],d["of"],d["label"],d["client"]],14,g.BLUE,404);y+=21
 # Right column: stock, maintenance, bottleneck and next investment.
 _heading(g,Vector2(815,226),"STOCK FOR COMMITTED WORK")
 if plan["short"].is_empty(): g._text(Vector2(815,250),"Everything is on hand or arriving.",14,g.INK,392)
 else: g._text(Vector2(815,250),"Short: %s. About $%.0f to order (estimate)." % [_short_items(plan["short"],3),plan["short_cost"]],14,g.RED,392)
 _heading(g,Vector2(815,308),"MAINTENANCE")
 if plan["service"].is_empty(): g._line(Vector2(815,332),"All stations at 75% condition or better.",14,g.INK,392)
 else:
  for k in mini(2,plan["service"].size()):
   var m=plan["service"][k]
   g._line(Vector2(815,332+k*21),"%s %.0f%%: %s" % [m["title"],m["condition"],m["status"]],14,g.RED if m["condition"]<65 else g.INK,392)
 _heading(g,Vector2(815,392),"BOTTLENECK")
 if plan["bottleneck_jobs"]>=2: g._line(Vector2(815,416),"%d jobs wait for %s." % [plan["bottleneck_jobs"],String(s.state["machines"].get(plan["bottleneck"],{}).get("title",plan["bottleneck"]))],14,g.INK,392)
 else: g._line(Vector2(815,416),"No station has a queue.",14,g.INK,392)
 _heading(g,Vector2(815,452),"NEXT INVESTMENT")
 g._text(Vector2(815,476),String(g._growth_advice()[0]).trim_prefix("NEXT STEP: "),14,g.INK,392)
 # Focus choice.
 _heading(g,Vector2(389,532),"DAY %d FOCUS" % day+("  (accepted prices and deadlines never change)" if Planning.enabled(s) else "  (needs current rules: Settings > Difficulty)"))
 var chosen=String(s.state["next_focus"])
 var w=(818.0-4*8)/5.0
 for k in Planning.FOCUS_ORDER.size():
  var id=Planning.FOCUS_ORDER[k]
  g._button(Rect2(389+k*(w+8),546,w,38),Planning.FOCUS[id]["title"].to_upper(),"focus:"+id,g.YELLOW if id==chosen else g.CREAM,Planning.enabled(s) or id=="balanced",13)
 var f=Planning.FOCUS[chosen]
 g._text(Vector2(389,606),"Effect: "+f["effects"],14,g.INK,818)
 g._text(Vector2(389,630),"Trade-off: "+f["tradeoff"],14,g.INK,818)
 g._text(Vector2(389,660),"Last result: "+Planning.result_text(Planning.last_result(s)),13,g.MUTED,818)
 g._button(Rect2(389,703,195,48),"BACK" if pending else "BACK TO SHOP","report" if pending else "close",g.NAVY,true,15)
 g._button(Rect2(594,703,200,48),"SPECIALIZATION","specialize",g.CREAM,true,14)
 g._button(Rect2(804,703,200,48),"CLIENTS + CONTRACTS","clients",g.CREAM,true,14)
 if pending: g._button(Rect2(1014,703,193,48),"START DAY %d" % day,"next_day",g.YELLOW,true,15)
 else: g._button(Rect2(1014,703,193,48),"CAPACITY (Q)","capacity",g.CYAN,true,15)

static func draw_specialize(g) -> void:
 var s=g.sim
 var current=String(s.state.get("specialty","General"))
 g._header("BUSINESS SPECIALIZATION","Shapes new inquiries, station speed, new quotes and overhead. Accepted orders keep their terms.")
 var names=["General","Stickers","Apparel","Signs"]
 var legacy=int(s.state["rules"].get("version",0))==0
 for k in names.size():
  var name=names[k]
  var data=Strategy.SPECIALIZATION[name]
  var r=Rect2(389+(k%2)*414,214+(k/2)*240,404,228)
  g._panel(r,Color("eef6ff") if name==current else g.CREAM,g.BLUE if name==current else Color("c9d6e6"),10)
  g._line(r.position+Vector2(14,26),data["title"].to_upper()+("  (CURRENT)" if name==current else ""),17,g.BLUE,376,true)
  g._text(r.position+Vector2(14,50),data["pitch"],13,g.INK,376)
  g._text(r.position+Vector2(14,110),data["cost"],13,g.MUTED,376)
  var staff=0
  for wk in s.state["workers"]:
   for id in data["stations"]:
    if s.state["machines"].has(id) and s.role_matches(wk,id): staff+=1;break
  g._line(r.position+Vector2(14,166),"Your floor: %d cells of its stations / %d staff can run them" % [Strategy.spec_floor(s,name),staff] if name!="General" else "Uses every installed station equally.",12,g.INK,376)
  var ready=Strategy.spec_ready(s,name)
  var fee=Strategy.retool_fee(s,name)
  var label="CURRENT" if name==current else (ready["reason"].to_upper() if not ready["ok"] else ("SWITCH  $%d RETOOL" % fee if fee>0 else "CHOOSE  (FREE)"))
  g._button(Rect2(r.position.x+14,r.position.y+182,376,34),label,"spec_pick:"+name,g.YELLOW if name!=current and ready["ok"] else g.CREAM,name!=current and ready["ok"] and float(s.state["cash"])>=fee,13)
 if legacy: g._text(Vector2(389,700),"This shop uses the older economy: specialization only changes which inquiry comes first.",13,g.RED,818)
 g._button(Rect2(389,712,818,44),"BACK","spec_back",g.NAVY,true,16)

static func draw_clients(g) -> void:
 var s=g.sim
 Contracts.ensure(s)
 g._header("CLIENTS + CONTRACTS","Relationships grow only from delivered work. Declining is free; there are no streaks.")
 var offers=s.state["contract_offers"]
 if not Contracts.enabled(s):
  g._text(Vector2(389,240),"Named clients and contracts need a shop on the current rules (Settings > Difficulty).",16,g.RED,818)
 elif not offers.is_empty():
  g.client_offer_page=clampi(g.client_offer_page,0,offers.size()-1)
  var o=offers[g.client_offer_page]
  var t=Contracts.TRAITS[o["trait"]]
  var a=g.contract_assessment(o)
  g._panel(Rect2(385,212,826,256),Color("fff8e1"),g.YELLOW,10)
  # Drawn after the card so the paging control sits on top of it.
  if offers.size()>1: g._button(Rect2(1043,220,160,28),"OFFER %d / %d  >" % [g.client_offer_page+1,offers.size()],"offer_next",g.CREAM,true,13)
  g._line(Vector2(401,240),"%s / %s client / tier %d contract" % [o["client_name"],t["title"],int(o["tier"])],17,g.BLUE,632,true)
  var days=[]
  for d in o["deliveries"]: days.append("Day %d" % int(d["day"]))
  g._line(Vector2(401,264),"%d deliveries of %d %s, due 4:00 PM on %s. Offer open until Day %d." % [o["deliveries"].size(),int(o["quantity"]),o["product"],", ".join(days),int(o["expires_day"])],15,g.INK,794)
  g._text(Vector2(401,288),"Inputs per delivery (estimate): %s. Materials about $%.0f." % [_short_items(a["inputs"],5),a["cost"]],14,g.INK,794)
  var risk_text=("BLOCKED until you order "+_short_items(a["missing"],3) if not a["missing"].is_empty() else "BLOCKED: needs a station or qualified operator") if a["risk"]=="BLOCKED" else "%s: about %.1f shop hours of queued work vs %.1f available before the first delivery" % [a["risk"],a["hours"],a["available"]]
  g._text(Vector2(401,330),"Capacity (estimate) "+risk_text+".",14,RISK_COLOR.get(a["risk"],g.INK),794)
  var total=int(o["per_delivery"])*o["deliveries"].size()
  g._text(Vector2(401,372),"Payments: $%d deposit today, $%d per delivery (last one $%d after the deposit). Bonus $%d if %s." % [int(o["deposit"]),int(o["per_delivery"]),int(o["per_delivery"])-int(o["deposit"]),int(o["bonus"]),t["bonus"]],14,g.INK,794)
  g._line(Vector2(401,414),"Total $%d plus bonus. Relationship: %s" % [total,t["rule"]],13,g.MUTED,794)
  g._button(Rect2(401,424,392,36),"ACCEPT CONTRACT  +$%d DEPOSIT" % int(o["deposit"]),"contract_accept:"+o["id"],g.GREEN,Contracts.active_count(s)<Contracts.MAX_ACTIVE and (a["risk"]!="BLOCKED" or not a["missing"].is_empty()),14)
  g._button(Rect2(803,424,392,36),"DECLINE  (NO PENALTY)","contract_decline:"+o["id"],g.CREAM,true,14)
 else:
  var running=[]
  for k in s.state["contracts"]:
   if k["status"]=="active": running.append(k)
  if running.is_empty():
   g._text(Vector2(389,240),"No offers right now. Deliver named clients' orders on their terms: each client offers a contract when your relationship reaches %d, %d and %d." % Contracts.MILESTONES,16,g.INK,818)
  else:
   var yy=238
   for k in running:
    var parts=[]
    for d in k["deliveries"]: parts.append("Day %d %s" % [int(d["day"]),"paid" if d["paid"] else ("in queue" if String(d["order_id"])!="" else "scheduled")])
    g._line(Vector2(389,yy),"%s: %d %s / %s" % [k["client_name"],int(k["quantity"]),k["product"],", ".join(parts)],15,g.INK,818);yy+=28
    g._line(Vector2(389,yy),"Bonus $%d if %s." % [int(k["bonus"]),Contracts.TRAITS[k["trait"]]["bonus"]],13,g.MUTED,818);yy+=34
 # Client roster.
 _heading(g,Vector2(389,500),"NAMED CLIENTS")
 for k in Contracts.CLIENTS.size():
  var c=Contracts.CLIENTS[k]
  var st=Contracts.client_state(s,c["id"])
  var y=522+k*36
  g._line(Vector2(389,y+16),c["name"],15,g.INK,250)
  g._line(Vector2(645,y+16),Contracts.TRAITS[c["trait"]]["title"],13,g.MUTED,90)
  g.draw_rect(Rect2(Vector2(740,y+5)+Vector2.ZERO,Vector2(120,12)),Color("dbe5f0"))
  g.draw_rect(Rect2(Vector2(740,y+5),Vector2(120*int(st["rel"])/100.0,12)),g.GREEN)
  g._line(Vector2(870,y+16),"%d  %s" % [int(st["rel"]),Contracts.summary(s,c["id"])],13,g.INK,337)
 g._button(Rect2(389,712,818,44),"BACK","clients_back",g.NAVY,true,16)

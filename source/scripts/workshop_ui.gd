extends RefCounted
const Ops=preload("res://scripts/shop_operations.gd")
const Style=preload("res://scripts/shop_style.gd")
const C=preload("res://scripts/catalog.gd")
static func draw(g) -> void:
 Ops.ensure(g.sim);Style.ensure(g.sim)
 if g.sim.worker(g.style_worker).is_empty():g.style_worker="owner"
 var s=g.sim;var o=s.state["operations"];var page=g.workshop_page
 g._header("YOUR WORKSHOP", "Operations, recovery and personal style. Changes use this profile's normal cash and saves.")
 var tabs=["Operations","Service","Away","Finance","Style","Decisions"]
 for i in tabs.size():g._button(Rect2(389+i*138,204,128,35),tabs[i],"worktab:"+str(i),g.CYAN if i==page else g.CREAM,true,14)
 match page:
  0:
   g._text(Vector2(389,280),"BUILD TRUST THROUGH GOOD WORK",23,g.BLUE,-1,true)
   g._text(Vector2(389,320),"Run a community sale: $25 marketing, 15% discounted print inquiry.\nYou review capacity and accept normally. Good, on-time fulfillment earns\nnormal trust plus 2. Spending alone earns no reputation.",19,g.INK,810)
   g._button(Rect2(389,410,818,44),"RUN COMMUNITY PROMOTION  $25","promotion",g.YELLOW,o["promo_day"]!=s.state["day"] and s.state["cash"]>=25)
   g._button(Rect2(389,477,397,44),"SHOP GROWTH + FIT-OUT","move",g.CREAM)
   g._button(Rect2(801,477,406,44),"CAPACITY + COMMITTED JOBS","capacity",g.CREAM,true,16)
   g._text(Vector2(389,568),"Too much work creates queues, stock shortages and late-delivery trust losses.\nReview the Capacity board before accepting a rush or an opportunity.\nDecline an inquiry when its proposed deadline is unrealistic.",18,g.INK,810)
  1:
   g._text(Vector2(389,274),"One kit per service. A qualified worker walks over and locks the station.",18,g.INK,810)
   var row=0
   for id in s.state["machines"]:
    var m=s.state["machines"][id]
    if not Ops.SERVICE.has(m["kind"]) or m["kind"]=="shaker":continue
    var y=315+row*58;row+=1
    g._line(Vector2(389,y),m["title"]+" / "+Ops.service_status(s,id),16,g.INK,622)
    g._button(Rect2(1025,y-22,182,36),"SERVICE  1 KIT","service:"+id,g.CYAN,not m.has("service_work") and m["active"]<0,14)
    if m.get("broken",false):g._button(Rect2(850,y+13,357,22),"OPTIONAL 3-STEP JAM RECOVERY / 1 KIT","jam:"+id,g.YELLOW,true,11)
   g._text(Vector2(389,675),"4 uses: routine due. Under 65%: 15% slower. Severe sustained neglect can stop a station.\nService continues during an open shift; paused shops do not advance service.",16,g.MUTED,810)
  2:
   g._text(Vector2(389,279),"AWAY SHIFT / ACCEPTED JOBS ONLY",23,g.BLUE,-1,true)
   g._text(Vector2(389,318),"Sam uses Auto Assist. Inquiries wait; no new jobs are accepted.\nNormal routes, skills, stock and deadlines still apply. Stops at closing,\nartwork, layout or quality decisions. Review the report when you return.",18,g.INK,810)
   g._button(Rect2(389,407,397,43),"END AWAY SHIFT" if o["away"] else "START AWAY SHIFT","away_toggle",g.YELLOW)
   g._button(Rect2(801,407,406,43),"OFFLINE: "+("ON (15 MIN MAX)" if o["offline_enabled"] else "OFF"),"offline_toggle",g.CREAM,true,16)
   g._button(Rect2(389,469,397,43),"AUTO SERVICE: "+("ON" if o["auto_service"] else "OFF"),"auto_service",g.CREAM,true,16)
   g._button(Rect2(801,469,406,43),"OFFLINE SETTLES ON CONTINUE","worktab:2",g.CREAM,false,15)
   g._text(Vector2(389,550),"Service budget: $24 within $100 total / no automatic supply purchases.\nOffline runs at 1x once per saved interval. Enable it before leaving an Away shift.\nIt saves the result before showing it; save failure restores the prior state.",17,g.INK,810)
   g._text(Vector2(389,636),JSON.stringify(o["return_report"]),14,g.BLUE,810)
  3:
   g._text(Vector2(389,275),"OPTIONAL EQUIPMENT AGREEMENTS",23,g.BLUE,-1,true)
   g._text(Vector2(389,313),"20% deposit + 10% fixed price fee, repaid over up to ten daily bills.\nA next-bill cash buffer is required. Maximum two active agreements.\nNo charge until placement succeeds. Accepted jobs never guarantee profit.",17,g.INK,810)
   var ids=["dtf","sticker","heat","banner","cnc","dock"]
   for i in ids.size():
    var id=ids[i];var price=C.EQUIPMENT_PRICES[id];var y=396+i*42
    g._line(Vector2(389,y+4),id.to_upper()+" / $%d deposit / $%d daily / $%d total" % [ceili(price*.2),ceili(price*.9/10),price+ceili(price/10.0)],16,g.INK,600)
    g._button(Rect2(1015,y-19,192,33),"SELECT FINANCE","finance:"+id,g.CYAN,not s.state["machines"].has(id),13)
   g._text(Vector2(389,675),"Active daily payments: $%d. Equipment prerequisites and clear access still apply." % Ops.daily_debt(s),17,g.BLUE,810)
  4:
   var style=s.state["style"]
   g._text(Vector2(389,275),"DISPLAY GOODS + FLOOR + CLOTHING",23,g.BLUE,-1,true)
   var ids=Style.DECOR.keys()
   for i in ids.size():
    var id=ids[i];var spec=Style.DECOR[id]
    g._button(Rect2(389+(i%2)*414,298+floori(i/2.0)*45,404,37),spec["title"]+"  $"+str(spec["price"]),"decor:"+id,g.CREAM,true,14)
   g._button(Rect2(803,388,404,37),"MOVE DECOR + SHOP SIGN","studio",g.CREAM,true,14)
   g._button(Rect2(389,454,397,39),"FLOOR: "+style["floor"],"floor_next",g.CYAN,true,16)
   g._button(Rect2(801,454,406,39),"IMPORT LOCAL PNG FLOOR","floor_import",g.CREAM,true,15)
   g._button(Rect2(389,508,397,39),"WORKER: "+s.worker(g.style_worker)["name"],"outfit_worker",g.CREAM,true,15)
   g._button(Rect2(801,508,406,39),style["outfits"].get(g.style_worker,"Workshop"),"outfit_next",g.CYAN,true,16)
   g._text(Vector2(389,580),"Click clear floor to place decor; Escape cancels. Keep service aisles open.\nImported PNG: local only, up to 8 MB / 2048 x 2048. Click a floor preset to clear it.\nSuits unlock after five paid jobs and a profitable day.",17,g.INK,810)
   g._button(Rect2(389,660,818,39),"PHOTO MODE / LOCAL PNG EXPORT","photo_mode",g.YELLOW,true,16)
  5:
   g._text(Vector2(389,278),"OPTIONAL INTERVENTIONS",23,g.BLUE,-1,true)
   g._button(Rect2(389,303,397,39),"QTE: "+("ON" if o["qte_enabled"] else "OFF"),"qte_toggle",g.CREAM,true,16)
   g._button(Rect2(801,303,406,39),"TIMING ASSIST: "+("ON" if o["assist"] else "OFF"),"assist_toggle",g.CREAM,true,16)
   g._text(Vector2(389,382),"Select a sticker or apparel job to try registration or press timing.\nMaximum two per day. First attempt is practice. Skip keeps ordinary production.\nNo cash rewards, failed-order penalties or reaction requirements.",17,g.INK,810)
   var event=o["event"]
   g._text(Vector2(389,475),"SHOP DECISION: "+str(event.get("kind","None waiting")),22,g.BLUE)
   if not event.is_empty():
    var kind=event["kind"]
    var choices={"supplier":[["Expedite supplies $25","expedite"],["Accept 15 shop-minute delay","delay"]],"artwork":[["Review artwork-change request / new print quote","artwork"],["Keep accepted artwork and terms","keep"]],"absence":[["Pay $45 for shift cover","cover"],["Accept one worker absence today","absence"]],"opportunity":[["Review rare project / equipment may be required","opportunity"],["Decline with no trust penalty","keep"]]}
    for i in choices[kind].size():g._button(Rect2(389,508+i*53,818,42),choices[kind][i][0],"event:"+choices[kind][i][1],g.YELLOW,true,17)
   g._button(Rect2(389,654,818,39),"DAILY HURDLES: "+("ON" if o["event_enabled"] else "OFF"),"events_toggle",g.CREAM,true,16)
 g._line(Vector2(389,729),str(s.state["notices"][0]),14,g.BLUE,810)
 g._button(Rect2(389,750,818,30),"BACK TO SHOP","close",g.NAVY,true,14)

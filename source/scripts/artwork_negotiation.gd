extends RefCounted
static func eligible(s,index:int) -> bool:
 var o=s.order(index)
 if o.is_empty() or o.get("paid",false) or o.get("consumed",false) or o["stage"] not in ["preflight","plan","queued","waiting_stock"]:return false
 if o.has("batch_leader") or o.has("batch_members") or not o.get("artwork_history",[]).is_empty():return false
 for w in s.state["workers"]:
  if not w["task"].is_empty() and int(w["task"]["order"])==index:return false
 return true
static func propose(s,index:int) -> bool:
 var o=s.order(index)
 if not o.get("artwork_offer",{}).is_empty():return true
 if not eligible(s,index):s.notice("Artwork changes are offered before production or batching, with no operator reserved.");return false
 var before=s.state.duplicate(true)
 o["artwork_offer"]={"id":o["id"]+":artwork-change","original_due":o["due"],"original_reward":o["reward"],"original_stage":o["stage"],"offered_at":s.now(),"request":"Customer requests a revised proof before printing."}
 s.notice("Artwork change proposed. Existing payout and deadline remain fixed until a new agreement is chosen.")
 if not s.save_game():s.state=before;return false
 return true
static func resolve(s,index:int,choice:String) -> bool:
 var o=s.order(index);var offer=o.get("artwork_offer",{})
 if offer.is_empty() or not eligible(s,index):return false
 if o["due"]!=offer["original_due"] or o["reward"]!=offer["original_reward"]:s.notice("Terms changed since this offer. Keep the current agreement.");return false
 var options={"customer":{"cost":0,"bonus":45,"extra":.75,"wait":.3},"studio":{"cost":30,"bonus":75,"extra":.25,"wait":.2},"express":{"cost":50,"bonus":110,"extra":0.0,"wait":.1}}
 if choice!="keep" and not options.has(choice):return false
 var before=s.state.duplicate(true);var record=offer.duplicate(true);record["choice"]=choice;record["decided_at"]=s.now();record["cost"]=0
 if choice!="keep":
  var terms=options[choice]
  if s.state["cash"]<terms["cost"]:s.notice("Not enough cash for that artwork service. Original agreement is unchanged.");return false
  if s.now()+terms["wait"]>=float(o["due"])+terms["extra"]:s.notice("That revision cannot arrive before its proposed deadline. Keep the original brief or choose a longer revision.");return false
  s.state["cash"]-=terms["cost"];s.state["stats"]["art_fees"]+=terms["cost"];o["art_cost"]=o.get("art_cost",0)+terms["cost"]
  o["reward"]=float(offer["original_reward"])+terms["bonus"];o["due"]=float(offer["original_due"])+terms["extra"]
  o["art_ready"]=false;o["gang"]=[];o["recipe"]={};o["stage"]="revision";o["revision_eta"]=s.now()+terms["wait"]
  o["artwork_version"]=int(o.get("artwork_version",1))+1
  record["cost"]=terms["cost"];record["reward"]=o["reward"];record["due"]=o["due"]
 if not o.has("artwork_history"):o["artwork_history"]=[]
 o["artwork_history"].append(record);o["artwork_offer"]={}
 s.notice("Original artwork and terms retained; no charge or trust loss." if choice=="keep" else "Revised agreement saved. Artwork service is charged once; the extra payout arrives only on delivery.")
 if not s.save_game():s.state=before;return false
 return true
static func draw(g) -> void:
 var o=g.sim.order(g.selected_order);var offer=o.get("artwork_offer",{})
 g._header("ARTWORK CHANGE / NEW AGREEMENT","You choose whether to change accepted terms. No extra payment is collected until fulfillment.")
 if offer.is_empty():
  g._text(Vector2(389,260),"No pending artwork change for this job.",21,g.INK)
  g._button(Rect2(389,710,818,43),"BACK TO JOB","back_order",g.NAVY);return
 g._text(Vector2(389,244),o["customer"]+" / "+str(o["quantity"])+" "+o["product"],21,g.BLUE,810)
 g._text(Vector2(389,284),"Request: a revised proof before printing. Quantity and materials stay reserved normally.\nEach option includes a separately agreed artwork fee in the final job payout.",17,g.INK,810)
 g._text(Vector2(389,354),"CURRENT: $%d payout / %s" % [offer["original_reward"],g._due({"due":offer["original_due"]})],21,g.BLUE)
 var rows=[["Customer supplies revision","customer",0,45,.75,.3],["Studio prepares revision","studio",30,75,.25,.2],["Express studio revision","express",50,110,0.0,.1]]
 for i in rows.size():
  var r=rows[i];var y=391+i*78
  g._panel(Rect2(389,y,818,69),g.CREAM,g.NAVY,5)
  g._line(Vector2(402,y+24),r[0]+" / pay $%d now / final payout $%d" % [r[2],offer["original_reward"]+r[3]],17,g.INK,582)
  g._line(Vector2(402,y+49),"New deadline %s / proof in %d shop min" % [g._due({"due":float(offer["original_due"])+r[4]}),roundi(r[5]*60)],15,g.BLUE,582)
  var valid=g.sim.state["cash"]>=r[2] and g.sim.now()+r[5]<float(offer["original_due"])+r[4]
  g._button(Rect2(1002,y+13,192,42),"AGREE + REVISE","art_decide:"+r[1],g.YELLOW,valid,13)
 g._button(Rect2(389,641,818,43),"KEEP ORIGINAL ARTWORK / NO CHARGE / NO TRUST PENALTY","art_decide:keep",g.CREAM,true,15)
 g._line(Vector2(389,708),g.sim.state["notices"][0],14,g.BLUE,810)
 g._button(Rect2(389,737,818,37),"BACK / LEAVE OFFER PENDING","back_order",g.NAVY,true,15)

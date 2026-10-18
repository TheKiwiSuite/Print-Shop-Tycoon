extends RefCounted
const Style=preload("res://scripts/shop_style.gd")
static func draw(g) -> void:
 Style.ensure(g.sim)
 g._header("DECOR + YOUR SHOP SIGN","Select any purchased item. Moving it costs nothing and must retain machine and walking access.")
 g._text(Vector2(389,230),"SHOP NAME / WALL SIGN / UP TO 40 CHARACTERS",16,g.BLUE)
 g._button(Rect2(1015,247,192,42),"SAVE SHOP NAME","shop_name_save",g.CYAN,true,15)
 g._text(Vector2(389,327),"Your sign is painted on the back wall and saved with this profile.\nDecor is never repurchased when moved. Invalid placement leaves it where it was.",18,g.INK,810)
 var items=g.sim.state["style"]["decor"]
 var selected=Style.item(g.sim,g.selected_decor)
 if selected.is_empty() and not items.is_empty():g.selected_decor=items[0]["id"];selected=items[0]
 g._text(Vector2(389,405),Style.DECOR[selected["kind"]]["title"] if not selected.is_empty() else "NO PURCHASED DECOR YET",24,g.BLUE,-1,true)
 g._text(Vector2(389,440),"ID: %s / tile %d, %d" % [selected["id"],selected["pos"][0],selected["pos"][1]] if not selected.is_empty() else "Buy a display or plant from Workshop > Style.",18,g.INK,810)
 g._button(Rect2(389,471,397,42),"PREVIOUS DECOR","decor_cycle:-1",g.CREAM,items.size()>1,16)
 g._button(Rect2(801,471,406,42),"NEXT DECOR","decor_cycle:1",g.CREAM,items.size()>1,16)
 g._button(Rect2(389,535,397,45),"MOVE SELECTED ON FLOOR","decor_move",g.YELLOW,not selected.is_empty(),16)
 g._button(Rect2(801,535,406,45),"REMOVE SELECTED / NO REFUND","decor_remove_selected",g.CREAM,not selected.is_empty(),15)
 g._text(Vector2(389,625),"Placement: click a tile, or use arrow keys and Enter. Escape cancels.\nThe shop holds while placing, then restores its previous pause state.",18,g.INK,810)
 g._line(Vector2(389,709),g.sim.state["notices"][0],15,g.BLUE,810)
 g._button(Rect2(389,739,818,37),"BACK TO STYLE","worktab:4",g.NAVY,true,15)

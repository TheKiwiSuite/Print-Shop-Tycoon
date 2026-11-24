extends SceneTree
# Shop level, XP, goals, awards, level-gated equipment and the ending.
const Sim=preload("res://scripts/simulation.gd")
const C=preload("res://scripts/catalog.gd")
const Progress=preload("res://scripts/shop_progress.gd")
var checks=0
var failures=0

func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)

func job(s,id:String,type:String,quantity:int,htv:bool=false) -> Dictionary:
 var o=C.make_order(id,type,quantity,"Progress tester",s.now()+5,100)
 if htv: o["method"]="htv"
 o["paid"]=true;o["payment"]=100;o["quality"]=100;o["stage"]="completed"
 s.state["orders"].append(o)
 s.state["completed"]=int(s.state["completed"])+1
 return o

func kinds(events:Array) -> Array:
 var out=[]
 for e in events: out.append(str(e["kind"]))
 return out

func _initialize() -> void:
 check(Progress.level_for(0)==1 and Progress.level_for(59)==1 and Progress.level_for(60)==2,"Level 2 starts at 60 XP")
 check(Progress.level_for(Progress.LEVEL_XP[9]-1)==9 and Progress.level_for(Progress.LEVEL_XP[9])==10 and Progress.level_for(999999)==10,"Level 10 is the top")
 check(Progress.LEVEL_TITLES.size()==Progress.LEVEL_XP.size(),"Every level has a title")
 var s=Sim.new();s.save_enabled=false;s.start_shop("Standard")
 var p=Progress.ensure(s)
 check(Progress.level(s)==1 and int(p["xp"])==0 and p["goals"].is_empty(),"A new career starts at level 1 with nothing earned")
 check(s.equipment_locked("sticker") and s.equipment_locked("dtfmini") and s.equipment_locked("dtf"),"Level 1 locks the sticker station and both DTF machines")
 check(not s.equipment_locked("cutter") and not s.equipment_locked("heat") and not s.equipment_locked("art"),"Cutter, heat press and benches are never locked")
 check(not s.install_feedback("sticker",Vector2i(1,5))["valid"],"A locked machine cannot be placed")
 # First paid job: job XP, on-time and quality bonuses, first-sale goal, level 2.
 Progress.paid(s,job(s,"P1","apparel",6,true),true)
 check(int(p["xp"])==Progress.XP_JOB+Progress.XP_ON_TIME+Progress.XP_QUALITY+40,"First on-time job earns job XP, bonuses and the first-sale goal")
 check(Progress.level(s)==2 and not s.equipment_locked("sticker") and s.equipment_locked("dtfmini"),"Level 2 unlocks the sticker station only")
 var events=Progress.pop_events(s)
 check(kinds(events)==["level","goal"] or kinds(events)==["goal","level"],"The first sale reports a goal and a new level")
 var level_event={}
 for e in events:
  if e["kind"]=="level": level_event=e
 check(int(level_event.get("level",0))==2 and "Sticker print / cut station" in level_event.get("unlocks",[]),"The level card lists what unlocked")
 check(Progress.pop_events(s).is_empty(),"Events are handed over once")
 check(int(p["stats"]["shirts"])==6 and int(p["stats"]["htv_shirts"])==6 and int(p["stats"]["streak"])==1,"Job statistics are counted")
 # A late, reduced-quality job earns the base XP only and breaks the streaks.
 var before=int(p["xp"])
 var late=job(s,"P2","decal",24);late["quality"]=70;late["quality_accepted"]=true
 Progress.paid(s,late,false)
 check(int(p["xp"])==before+Progress.XP_JOB and int(p["stats"]["streak"])==0 and int(p["stats"]["clean"])==0,"A late, reduced-quality job earns base XP and resets streaks")
 check(int(p["stats"]["decals"])==24,"Decals are counted by quantity")
 # Levels 3 and 5 unlock DTF.
 var n=3
 while Progress.level(s)<3:
  Progress.paid(s,job(s,"P%d" % n,"apparel",6,true),true);n+=1
 check(not s.equipment_locked("dtfmini") and s.equipment_locked("dtf"),"Level 3 unlocks the desktop DTF kit")
 while Progress.level(s)<5:
  Progress.paid(s,job(s,"P%d" % n,"transfer",12),true);n+=1
 check(not s.equipment_locked("dtf") and s.equipment_locked("banner"),"Level 5 unlocks the full DTF line")
 check("jobs5" in p["goals"],"Five paid jobs is a goal")
 check(int(p["stats"]["best_streak"])>=10 and "streak10" in p["awards"],"Ten on-time jobs in a row earns an award")
 Progress.pop_events(s)
 # Goals follow the shop itself.
 s.state["cash"]=5000
 check(s.hire(2),"Hire a helper")
 Progress.refresh(s)
 check("helper" in p["goals"] and "cash3k" in p["goals"],"Hiring and savings goals complete")
 s.state["cash"]=10
 Progress.refresh(s)
 check("cash3k" in p["goals"],"A finished goal stays finished after spending the money")
 var rows=Progress.goals(s)
 check(rows.size()==Progress.GOALS.size() and rows[0]["done"] and not rows[-1]["done"],"The goal list shows what is done and what is left")
 check(not Progress.next_goal(s).is_empty(),"There is always a next goal until the end")
 # Save and load keep progress.
 s.save_enabled=true;s.save_path=ProjectSettings.globalize_path("res://../../../work/progress-qa.json")
 check(s.save_game(),"Save a shop with progress")
 var loaded=Sim.new();loaded.save_path=s.save_path
 check(loaded.load_game(),"Load a shop with progress")
 loaded.save_enabled=false
 var lp=Progress.ensure(loaded)
 check(int(lp["xp"])==int(p["xp"]) and lp["goals"].size()==p["goals"].size() and Progress.level(loaded)==Progress.level(s),"Level, XP and goals survive save and load")
 s.save_enabled=false
 # The ending: every goal done, reported exactly once.
 s.state["location"]=2;s.state["fit_out"]=true;s.state["production_annex"]=true;s.state["reputation"]=80;s.state["cash"]=15000
 var line=C.layout(1)
 s.state["machines"]["dtf"]=line["dtf"];s.state["machines"]["shaker"]=line["shaker"]
 while s.state["workers"].size()<4:
  var extra=s.state["workers"][1].duplicate(true);extra["id"]="staffx%d" % s.state["workers"].size()
  s.state["workers"].append(extra)
 p["stats"]["jobs"]=50
 Progress.refresh(s)
 check(p["goals"].size()==Progress.GOALS.size() and Progress.next_goal(s).is_empty(),"Every goal can be completed")
 check(kinds(Progress.pop_events(s)).count("ending")==1,"Finishing every goal triggers the ending")
 Progress.refresh(s)
 check(not ("ending" in kinds(Progress.pop_events(s))),"The ending is shown once")
 check(Progress.span(s)["fraction"]>=0.0 and Progress.span(s)["fraction"]<=1.0,"The XP bar stays in range")
 # Older saves are credited quietly, and keep unlocks earned under the old rule.
 var old=Sim.new();old.save_enabled=false;old.start_shop("Standard")
 old.state.erase("progress");old.state["completed"]=12
 var op=Progress.ensure(old)
 check(Progress.level(old)>=5 and not old.equipment_locked("dtf"),"A career with 12 sales keeps its DTF unlock")
 check(op["events"].is_empty() and "first_sale" in op["goals"] and "jobs5" in op["goals"],"Older saves are credited without pop-ups")
 var five=Sim.new();five.save_enabled=false;five.start_shop("Standard")
 five.state.erase("progress");five.state["completed"]=5
 Progress.ensure(five)
 check(not five.equipment_locked("dtfmini"),"A career with 5 sales keeps its desktop DTF unlock")
 # The demo and older-economy shops are never gated.
 var demo=Sim.new();demo.save_enabled=false;demo.start_demo()
 check(not demo.equipment_locked("dtf") and not demo.equipment_locked("banner") and Progress.ensure(demo)["events"].is_empty(),"The demo shop is not level-gated and starts quietly")
 var legacy=Sim.new();legacy.save_enabled=false;legacy.state=C.fresh()
 check(not legacy.equipment_locked("sticker") and not legacy.equipment_locked("cnc") and Progress.ensure(legacy)["events"].is_empty(),"Older-economy shops are not level-gated and start quietly")
 print("PROGRESS CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

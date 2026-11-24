extends SceneTree
# Music playlist, sound effects and volume controls.
var failures=0
var checks=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(label)
 else: print("PASS: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 var scratch=ProjectSettings.globalize_path("res://../../../work/audio-qa-profile.json")
 game.sim.save_enabled=false;game.sim.save_path=scratch
 root.add_child(game);game.set_process(false)
 var settings=game.sim.state["settings"]
 settings["music"]=true;settings["sound"]=true;settings["music_volume"]=0.6;settings["sound_volume"]=0.8
 check(game.sfx_streams.size()==game.SFX_NAMES.size(),"Every sound effect loads")
 check(game.music_tracks.size()==4,"Three shop tunes and the title tune load")
 for name in game.music_tracks:
  var length=game.music_tracks[name].get_length()
  check(length>45.0 and length<120.0,"Tune has a sensible length: "+name)
 game.screen="title";game._start_music()
 check(game.music.playing and game.music_last==game.MUSIC_TITLE,"Title screen plays its own tune")
 check(game.music.stream.loop,"Title tune loops")
 game.screen="shop";game._start_music()
 check(game.music.playing and game.music_last in game.MUSIC_SHOP,"Shop plays a shop tune")
 check(not game.music.stream.loop,"Shop tunes end so the playlist can move on")
 var heard={}
 var previous=game.music_last
 var repeats=0
 for n in 9:
  game._next_track()
  if game.music_last==previous: repeats+=1
  previous=game.music_last;heard[game.music_last]=true
 check(heard.size()==3,"The playlist reaches all three shop tunes")
 check(repeats==0,"The same tune never plays twice in a row")
 game._action("music")
 check(not settings["music"] and not game.music.playing,"Music button turns the music off")
 game._action("music")
 check(settings["music"] and game.music.playing,"Music button turns the music back on")
 for n in 12: game._action("music_down")
 check(is_equal_approx(settings["music_volume"],0.0) and not game.music.playing,"Music volume steps down to silent")
 game._action("music_up")
 check(is_equal_approx(settings["music_volume"],0.1) and game.music.playing,"Raising the volume resumes the music")
 for n in 12: game._action("music_up")
 check(is_equal_approx(settings["music_volume"],1.0),"Music volume stops at 100 percent")
 for n in 3: game._action("sound_down")
 check(is_equal_approx(settings["sound_volume"],0.5),"Sound volume steps in tenths")
 var preferences=ConfigFile.new()
 check(preferences.load(scratch+".preferences.cfg")==OK and is_equal_approx(float(preferences.get_value("audio","sound_volume",-1)),0.5) and is_equal_approx(float(preferences.get_value("audio","music_volume",-1)),1.0),"Volumes are saved with the audio preferences")
 settings["sound_volume"]=0.8;settings["music_volume"]=0.6
 game._load_music_preference()
 check(is_equal_approx(settings["sound_volume"],0.5) and is_equal_approx(settings["music_volume"],1.0),"Saved volumes load again")
 # Sounds follow the simulation.
 game.time=10.0;game._audio_events()
 game.sim.state["completed"]=int(game.sim.state["completed"])+1
 game.time=11.0;game._audio_events()
 check(is_equal_approx(float(game.sfx_last.get("cash",-1)),11.0),"A paid job plays the cash sound")
 game.sim.state["cash"]=5000
 game.sim.state["gifts"]=["cutter"]
 check(game.sim.install_equipment("cutter",Vector2i(4,4)),"Place a cutter for the sound check")
 game.time=12.0;game._audio_events()
 check(is_equal_approx(float(game.sfx_last.get("place",-1)),12.0),"Placing equipment plays the place sound")
 settings["sound"]=false
 game.sim.state["completed"]=int(game.sim.state["completed"])+1
 game.time=13.0;game._audio_events()
 check(is_equal_approx(float(game.sfx_last.get("cash",-1)),11.0),"Sound Off silences effects")
 # Let the audio server release every stream before the engine shuts down.
 game.music.stop();game.music.stream=null
 for player in game.sfx_players: player.stop();player.stream=null
 await create_timer(.3).timeout
 print("AUDIO CHECK: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

extends SceneTree
const Updates=preload("res://scripts/game_updates.gd")
var root_path=""
var plan={}
func _initialize() -> void:call_deferred("run")
func finish(message:String,restart_old:bool=true) -> void:
 Updates.write_json(root_path.path_join("result.json"),{"message":message,"version":plan.get("version",""),"time":Time.get_unix_time_from_system()})
 if restart_old and FileAccess.file_exists(plan.get("target","")):OS.create_process(plan["target"],[])
 print(message);quit()
func run() -> void:
 var args=OS.get_cmdline_user_args()
 if OS.get_name()!="Windows" or args.size()!=1 or not Updates.nonce_valid(args[0]):quit(1);return
 root_path=Updates.folder(args[0])
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("plan.json")))
 if not parsed is Dictionary:quit(1);return
 plan=parsed
 var target=str(plan.get("target",""))
 if plan.get("nonce","")!=args[0] or not target.is_absolute_path() or target.simplify_path()!=target or target.get_file()!="Print Shop Tycoon.exe" or int(plan.get("pid",0))<=0:quit(1);return
 if not Updates.newer(str(plan.get("version","")),str(plan.get("old_version",""))):quit(1);return
 # Never replace an executable while the original game process is alive.
 for tick in 120:
  if not OS.is_process_running(int(plan["pid"])):break
  await create_timer(.5).timeout
 if OS.is_process_running(int(plan["pid"])):finish("Update cancelled: the game did not close.",false);return
 if FileAccess.get_sha256(target)!=plan.get("old_hash",""):finish("Update cancelled: the installed executable changed.",false);return
 var service=Updates.new();root.add_child(service)
 var release=await service.fetch_json(Updates.API+"/releases/"+str(int(plan.get("release_id",0))))
 var verified=Updates.metadata(release,plan["old_version"])
 for key in ["version","digest","size","release_id","asset_id","name"]:
  if verified.get(key,null)!=plan.get(key,null):finish("Update revalidation failed. The previous game is retained.");return
 var archive=OS.get_user_data_dir().path_join("updates").path_join(plan["name"])
 if plan.get("archive","")!=archive or not Updates.verify_archive(archive,verified):finish("Update digest mismatch. The previous game is retained.");return
 var next=target.get_base_dir().path_join("Print Shop Tycoon.next-"+args[0]+".exe")
 var backup=target.get_base_dir().path_join("Print Shop Tycoon.rollback-"+args[0]+".exe")
 if not Updates.extract_executable(archive,next):finish("Could not stage the verified game executable.");return
 var candidate_hash=FileAccess.get_sha256(next)
 if not Updates.atomic_replace(target,next,backup,plan["old_hash"]):finish("Windows could not replace the game. Check folder permissions or antivirus; the previous build is retained.");return
 var pid=OS.create_process(target,["--","--update-health",args[0]])
 var healthy=false
 if pid>0:
  for tick in 120:
   if FileAccess.file_exists(root_path.path_join("healthy.json")):
    var receipt=JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("healthy.json")))
    healthy=receipt is Dictionary and receipt.get("nonce","")==args[0] and int(receipt.get("pid",-1))==pid and receipt.get("version","")==plan["version"] and FileAccess.get_sha256(target)==candidate_hash
    if healthy:break
   if not OS.is_process_running(pid):break
   await create_timer(.5).timeout
 if healthy:finish("Update installed. Save backups and the previous executable are retained.",false);return
 if pid>0 and OS.is_process_running(pid):OS.kill(pid);await create_timer(1).timeout
 var rejected=target.get_base_dir().path_join("Print Shop Tycoon.failed-"+args[0]+".exe")
 if Updates.atomic_replace(target,backup,rejected,candidate_hash):finish("The new version did not confirm startup. Rolled back to the previous build.")
 else:finish("Automatic rollback was blocked by Windows. The previous executable remains at: "+backup,false)

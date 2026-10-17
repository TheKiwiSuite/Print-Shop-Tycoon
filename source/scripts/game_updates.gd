extends Node
# Trust boundary: fixed official GitHub repository, HTTPS and GitHub's asset digest.
# No downloaded script, installer, checksum sidecar or archive path is executed.
const REPOSITORY="TheKiwiSuite/Print-Shop-Tycoon"
const API="https://api.github.com/repos/"+REPOSITORY
const DOWNLOAD="https://github.com/"+REPOSITORY+"/releases/download/"
const ENTRY="PrintShopTycoon/windows/Print Shop Tycoon.exe"
const MAX_ARCHIVE=120*1024*1024
const MAX_EXECUTABLE=300*1024*1024
var status="Check for a newer Windows alpha. Updates are optional."
var busy=false
var available={}
var staged=""
var request:HTTPRequest

func _ready() -> void:
 var root=OS.get_user_data_dir().path_join("updates");var dir=DirAccess.open(root);var latest=0
 if dir==null:return
 for name in dir.get_directories():
  if not nonce_valid(name):continue
  var path=root.path_join(name).path_join("result.json")
  if FileAccess.file_exists(path) and FileAccess.get_modified_time(path)>latest:
   var result=JSON.parse_string(FileAccess.get_file_as_string(path))
   if result is Dictionary:status=str(result.get("message",status));latest=FileAccess.get_modified_time(path)

static func version_parts(value:String) -> Array:
 var regex=RegEx.new();regex.compile("^(0|[1-9][0-9]{0,5})\\.(0|[1-9][0-9]{0,5})\\.(0|[1-9][0-9]{0,5})$")
 if regex.search(value)==null:return []
 var result=[]
 for part in value.split("."):result.append(int(part))
 return result

static func newer(a:String,b:String) -> bool:
 var x=version_parts(a);var y=version_parts(b)
 if x.is_empty() or y.is_empty():return false
 for i in 3:
  if x[i]!=y[i]:return x[i]>y[i]
 return false

static func metadata(release:Variant,current:String) -> Dictionary:
 if not release is Dictionary or release.get("draft",true) or release.get("published_at",null)==null:return {}
 var tag=str(release.get("tag_name",""))
 if not tag.begins_with("v") or not tag.ends_with("-windows-alpha"):return {}
 var version=tag.trim_prefix("v").trim_suffix("-windows-alpha")
 if not newer(version,current) or not release.get("assets",null) is Array:return {}
 var name="PrintShopTycoon-Windows-v"+version+".zip"
 for asset in release["assets"]:
  if not asset is Dictionary or asset.get("name","")!=name:continue
  var digest=str(asset.get("digest",""));var regex=RegEx.new();regex.compile("^sha256:[0-9a-f]{64}$")
  if regex.search(digest)==null or int(asset.get("size",0))<1024 or int(asset["size"])>MAX_ARCHIVE:continue
  if asset.get("browser_download_url","")!=DOWNLOAD+tag+"/"+name or asset.get("state","")!="uploaded":continue
  if int(asset.get("id",0))<=0 or int(release.get("id",0))<=0:continue
  return {"version":version,"tag":tag,"name":name,"digest":digest.trim_prefix("sha256:"),"size":int(asset["size"]),"asset_id":int(asset["id"]),"release_id":int(release["id"])}
 return {}

static func verify_archive(path:String,meta:Dictionary) -> bool:
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null:return false
 var size=file.get_length();file.close()
 return size==int(meta.get("size",-1)) and size<=MAX_ARCHIVE and FileAccess.get_sha256(path)==meta.get("digest","")

static func write_json(path:String,value:Dictionary) -> bool:
 var file=FileAccess.open(path,FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(value));file.flush()
 return file.get_error()==OK

static func nonce_valid(nonce:String) -> bool:
 var regex=RegEx.new();regex.compile("^[0-9a-f]{32}$");return regex.search(nonce)!=null

static func folder(nonce:String) -> String:
 return OS.get_user_data_dir().path_join("updates").path_join(nonce)

func fetch_json(url:String) -> Variant:
 # Callers construct all URLs from the fixed API; never accept a release-body URL.
 if not url.begins_with(API+"/releases"):return null
 var http=HTTPRequest.new();add_child(http);http.timeout=25;http.body_size_limit=2*1024*1024;http.max_redirects=3
 var err=http.request(url,["Accept: application/vnd.github+json","User-Agent: Print-Shop-Tycoon-Updater","X-GitHub-Api-Version: 2022-11-28"])
 if err!=OK:http.queue_free();return null
 var reply=await http.request_completed;http.queue_free()
 if reply[0]!=HTTPRequest.RESULT_SUCCESS or reply[1]!=200:return null
 return JSON.parse_string(reply[3].get_string_from_utf8())

func check(current:String) -> void:
 if busy:return
 busy=true;available={};staged="";status="Checking the official GitHub release channel…"
 var releases=await fetch_json(API+"/releases?per_page=20")
 if not releases is Array:status="Update check failed. Your game and saves are unchanged. Try again later.";busy=false;return
 for release in releases:
  var candidate=metadata(release,current)
  if not candidate.is_empty() and (available.is_empty() or newer(candidate["version"],available["version"])):available=candidate
 status="Version "+available["version"]+" is available. Download size: %.1f MB." % (float(available["size"])/1000000) if not available.is_empty() else "You have the newest compatible Windows alpha."
 busy=false

func download() -> void:
 if busy or available.is_empty():return
 busy=true;staged="";status="Downloading to a separate update folder. You can keep playing."
 var root=OS.get_user_data_dir().path_join("updates")
 if DirAccess.make_dir_recursive_absolute(root)!=OK:status="Cannot create the update folder.";busy=false;return
 var path=root.path_join(available["name"]+".part")
 request=HTTPRequest.new();add_child(request);request.timeout=180;request.body_size_limit=MAX_ARCHIVE;request.max_redirects=5;request.download_file=path
 var err=request.request(DOWNLOAD+available["tag"]+"/"+available["name"],["User-Agent: Print-Shop-Tycoon-Updater"])
 if err!=OK:request.queue_free();request=null;status="Download could not start.";busy=false;return
 var reply=await request.request_completed;request.queue_free();request=null
 if reply[0]!=HTTPRequest.RESULT_SUCCESS or reply[1]!=200 or not verify_archive(path,available):
  status="Download incomplete or digest mismatch. Installation is blocked; your current game is unchanged.";busy=false;return
 staged=root.path_join(available["name"])
 if DirAccess.rename_absolute(path,staged)!=OK:staged="";status="Could not retain the verified download.";busy=false;return
 status="Download verified. Save, back up and restart when you are ready.";busy=false

static func backup_saves(source:String,destination:String) -> bool:
 if DirAccess.make_dir_recursive_absolute(destination)!=OK:return false
 var directory=DirAccess.open(source)
 if directory==null:return false
 for name in directory.get_files():
  if name.ends_with(".json") or name.ends_with(".bak") or name.ends_with(".preferences.cfg") or ".before-new-" in name:
   if DirAccess.copy_absolute(source.path_join(name),destination.path_join(name))!=OK:return false
 return true

func restart() -> bool:
 if busy or staged=="" or OS.get_name()!="Windows" or OS.has_feature("editor"):return false
 if not verify_archive(staged,available):status="The staged download changed. Download again.";return false
 var nonce=Crypto.new().generate_random_bytes(16).hex_encode();var root=folder(nonce)
 var target=OS.get_executable_path();var helper=root.path_join("update-helper.exe")
 if target.get_file()!="Print Shop Tycoon.exe":status="Keep the original Print Shop Tycoon.exe filename to use in-game updates.";return false
 var directory=DirAccess.open(target.get_base_dir())
 if directory==null or directory.get_space_left()<MAX_EXECUTABLE*2:status="At least 600 MB of free space is needed for staging and rollback.";return false
 var probe_path=target.get_base_dir().path_join(".tycoon-update-"+nonce+".probe")
 var probe=FileAccess.open(probe_path,FileAccess.WRITE)
 if probe==null:status="This game folder is read-only. Move the extracted game to a folder you own, then retry.";return false
 probe.close();DirAccess.remove_absolute(probe_path)
 if not backup_saves(OS.get_user_data_dir(),root.path_join("saves")):status="Save backup failed. Installation is blocked.";return false
 var hash=FileAccess.get_sha256(target)
 if DirAccess.copy_absolute(target,helper)!=OK or FileAccess.get_sha256(helper)!=hash:status="Could not prepare the isolated update helper.";return false
 var plan=available.duplicate(true);plan.merge({"nonce":nonce,"archive":staged,"target":target,"pid":OS.get_process_id(),"old_hash":hash,"old_version":str(ProjectSettings.get_setting("application/config/version"))})
 if not write_json(root.path_join("plan.json"),plan):status="Could not save the update plan.";return false
 var pid=OS.create_process(helper,["--headless","--log-file",root.path_join("update.log"),"--script","res://scripts/update_worker.gd","--",nonce])
 if pid<=0:status="Update helper could not start. Your game is unchanged.";return false
 return true

static func extract_executable(archive:String,destination:String) -> bool:
 var reader=ZIPReader.new()
 if reader.open(archive)!=OK:return false
 # Read one canonical entry directly, never extract paths supplied by the archive.
 var count=0
 for path in reader.get_files():
  if path==ENTRY:count+=1
 if count!=1:reader.close();return false
 var bytes=reader.read_file(ENTRY);reader.close()
 if bytes.size()<1024 or bytes.size()>MAX_EXECUTABLE or bytes[0]!=77 or bytes[1]!=90:return false
 var file=FileAccess.open(destination,FileAccess.WRITE)
 if file==null:return false
 file.store_buffer(bytes);file.flush()
 return file.get_error()==OK

static func atomic_replace(target:String,candidate:String,backup:String) -> bool:
 # Godot 4.5.1's Windows rename deletes the target before moving. Use Windows'
 # built-in .NET File.Replace instead: no delete-then-move gap, no elevation,
 # downloaded scripts, shell interpolation or execution-policy changes.
 if OS.get_name()!="Windows":return false
 for path in [target,candidate,backup]:
  if not path.is_absolute_path() or path.simplify_path()!=path or path.get_base_dir()!=target.get_base_dir():return false
 var quote=func(path):return "'"+str(path).replace("'","''")+"'"
 var script="$ErrorActionPreference='Stop'; try { [System.IO.File]::Replace(%s,%s,%s,$false); exit 0 } catch { exit 1 }" % [quote.call(candidate),quote.call(target),quote.call(backup)]
 var powershell=OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
 if not FileAccess.file_exists(powershell):return false
 var output=[]
 return OS.execute(powershell,["-NoProfile","-NonInteractive","-EncodedCommand",Marshalls.raw_to_base64(script.to_utf16_buffer())],output,true)==0

static func acknowledge_startup() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()!=2 or args[0]!="--update-health" or not nonce_valid(args[1]):return
 var root=folder(args[1]);var plan=JSON.parse_string(FileAccess.get_file_as_string(root.path_join("plan.json")))
 if not plan is Dictionary or plan.get("target","")!=OS.get_executable_path() or plan.get("version","")!=str(ProjectSettings.get_setting("application/config/version")):return
 write_json(root.path_join("healthy.json"),{"nonce":args[1],"pid":OS.get_process_id(),"version":plan["version"]})

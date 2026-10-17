extends SceneTree
const U=preload("res://scripts/game_updates.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func write(path:String,bytes:PackedByteArray) -> void:
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
func _initialize() -> void:call_deferred("run")
func run() -> void:
 check(U.newer("0.3.10","0.3.9"),"Versions compare numerically")
 check(not U.newer("0.3.1","0.3.1") and not U.newer("0.3.0","0.3.1"),"Equal and older releases cannot install")
 check(U.version_parts("01.2.3").is_empty() and U.version_parts("1.2.3-preview").is_empty(),"Malformed versions fail closed")
 var asset={"id":2,"name":"PrintShopTycoon-Windows-v0.3.2.zip","size":2048,"digest":"sha256:"+"a".repeat(64),"state":"uploaded","browser_download_url":U.DOWNLOAD+"v0.3.2-windows-alpha/PrintShopTycoon-Windows-v0.3.2.zip"}
 var release={"id":1,"draft":false,"published_at":"2026-10-17","tag_name":"v0.3.2-windows-alpha","assets":[asset]}
 check(not U.metadata(release,"0.3.1").is_empty(),"Official channel release with GitHub digest is accepted")
 var bad=release.duplicate(true);bad["draft"]=true
 check(U.metadata(bad,"0.3.1").is_empty(),"Draft releases are rejected")
 bad=release.duplicate(true);bad["assets"][0]["digest"]=""
 check(U.metadata(bad,"0.3.1").is_empty(),"Missing digest blocks installation")
 bad=release.duplicate(true);bad["assets"][0]["browser_download_url"]="https://example.org/game.exe"
 check(U.metadata(bad,"0.3.1").is_empty(),"External download locations are rejected")
 bad=release.duplicate(true);bad["assets"][0]["size"]=U.MAX_ARCHIVE+1
 check(U.metadata(bad,"0.3.1").is_empty(),"Oversized downloads are rejected")
 bad=release.duplicate(true);bad["assets"][0]["name"]="../../installer.exe"
 check(U.metadata(bad,"0.3.1").is_empty(),"Unexpected filenames cannot become installation paths")
 check(not U.nonce_valid("../escape") and U.nonce_valid("a".repeat(32)),"Operation IDs cannot traverse directories")
 var nonce=Crypto.new().generate_random_bytes(16).hex_encode()
 var base=OS.get_user_data_dir().path_join("updater-fixture-"+nonce)
 DirAccess.make_dir_recursive_absolute(base)
 var path=base.path_join("archive.zip");var pack=ZIPPacker.new();pack.open(path)
 pack.start_file(U.ENTRY);pack.write_file(("MZ"+"x".repeat(2046)).to_utf8_buffer());pack.close_file()
 pack.start_file("../../outside.txt");pack.write_file("must not extract".to_utf8_buffer());pack.close_file();pack.close()
 var file=FileAccess.open(path,FileAccess.READ);var size=file.get_length();file.close()
 var meta={"size":size,"digest":FileAccess.get_sha256(path)}
 check(U.verify_archive(path,meta),"Complete archive matches trusted size and digest")
 check(not U.verify_archive(path,{"size":size,"digest":"b".repeat(64)}),"Tampered archive cannot pass integrity")
 check(not U.verify_archive(path,{"size":size+1,"digest":meta["digest"]}),"Truncated download cannot pass integrity")
 var extracted=base.path_join("candidate.exe")
 check(U.extract_executable(path,extracted) and FileAccess.file_exists(extracted),"Only the canonical executable is extracted")
 check(not FileAccess.file_exists(OS.get_user_data_dir().path_join("outside.txt")),"Other archive paths are never extracted")
 var saves=base.path_join("old-saves");DirAccess.make_dir_recursive_absolute(saves)
 write(saves.path_join("native-shop-v3.json"),"accepted terms and stock".to_utf8_buffer())
 write(saves.path_join("native-shop-v3.json.bak"),"previous state".to_utf8_buffer())
 write(saves.path_join("native-shop-v3.json.preferences.cfg"),"preferences".to_utf8_buffer())
 var backup=saves+"-backup"
 check(U.backup_saves(saves,backup),"Save and preference backup completes before installation")
 check(FileAccess.get_sha256(saves.path_join("native-shop-v3.json"))==FileAccess.get_sha256(backup.path_join("native-shop-v3.json")),"Save backup is byte identical")
 check(FileAccess.file_exists(backup.path_join("native-shop-v3.json.bak")) and FileAccess.file_exists(backup.path_join("native-shop-v3.json.preferences.cfg")),"Fallback and preferences are backed up")
 if OS.get_name()=="Windows":
  var directory=base.path_join("shop's & tests");DirAccess.make_dir_recursive_absolute(directory)
  var target=directory.path_join("Print Shop Tycoon.exe");var next=directory.path_join("next.exe");var previous=directory.path_join("previous.exe")
  write(target,"old application".to_utf8_buffer());write(next,"new application".to_utf8_buffer())
  check(not U.atomic_replace(target,next,previous,"0".repeat(64)),"Changed installed bytes block replacement")
  check(U.atomic_replace(target,next,previous,FileAccess.get_sha256(target)),"Windows atomically replaces executable using literal paths")
  check(FileAccess.get_file_as_string(target)=="new application" and FileAccess.get_file_as_string(previous)=="old application","Replacement retains the exact previous build")
  check(not U.atomic_replace(target,directory.path_join("missing.exe"),directory.path_join("missing-backup.exe")),"Failed replacement reports failure")
  check(FileAccess.get_file_as_string(target)=="new application","Failed replacement leaves current executable intact")
  check(U.atomic_replace(target,previous,directory.path_join("rejected.exe")),"Rollback uses the same atomic replacement")
  check(FileAccess.get_file_as_string(target)=="old application","Rollback restores previous executable bytes")
  # Exercise startup confirmation in a copy of this exact exported executable.
  var healthy_dir=U.folder(nonce);DirAccess.make_dir_recursive_absolute(healthy_dir)
  check(DirAccess.copy_absolute(OS.get_executable_path(),target)==OK,"Stage actual Windows executable for isolated startup")
  U.write_json(healthy_dir.path_join("plan.json"),{"target":target,"version":str(ProjectSettings.get_setting("application/config/version"))})
  var pid=OS.create_process(target,["--headless","--","--update-health",nonce]);var healthy=false
  if pid>0:
   for tick in 80:
    if FileAccess.file_exists(healthy_dir.path_join("healthy.json")):healthy=true;break
    if not OS.is_process_running(pid):break
    await create_timer(.25).timeout
  check(healthy,"Actual exported Windows game acknowledges successful startup")
  if pid>0 and OS.is_process_running(pid):OS.kill(pid)
 print("UPDATER SECURITY: ",checks," checks, ",failures," failures / ",OS.get_name())
 quit(failures)

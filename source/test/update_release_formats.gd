extends SceneTree
const U=preload("res://scripts/game_updates.gd")
var checks=0
var failures=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if ok: print("PASS: "+label)
 else: failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:
 var release={"id":456255026,"draft":false,"prerelease":false,"published_at":"2026-11-24T03:03:16Z","tag_name":"v1.0.0","assets":[{"id":785476515,"name":"Print.Shop.Tycoon.exe","size":128313248,"digest":"sha256:1aa659c5bb94bafdbe6e5f974ef9a14b2d55a436ad7dc281c1bb0b5d5b3e01f9","state":"uploaded","browser_download_url":U.DOWNLOAD+"v1.0.0/Print.Shop.Tycoon.exe"}]}
 var meta=U.metadata(release,"0.3.2")
 check(meta.get("version","")=="1.0.0" and meta.get("format","")=="exe","Exact published v1 metadata upgrades legacy cohort")
 check(meta.get("size",0)>U.MAX_ARCHIVE,"Stable EXE uses its own size cap instead of legacy ZIP cap")
 check(U.metadata(release,"1.0.0").is_empty(),"Equal version is not an upgrade")
 check(U.metadata(release,"1.0.1").is_empty(),"Stable downgrade is rejected")
 var future=release.duplicate(true);future["tag_name"]="v1.0.1";future["assets"][0]["browser_download_url"]=U.DOWNLOAD+"v1.0.1/Print.Shop.Tycoon.exe"
 check(not U.metadata(future,"1.0.0").is_empty(),"Stable 1.x upgrade is supported")
 var bad=release.duplicate(true);bad["prerelease"]=true
 check(U.metadata(bad,"0.3.2").is_empty(),"Prerelease cannot masquerade as stable")
 bad=release.duplicate(true);bad["tag_name"]="v1.0.0-other"
 check(U.metadata(bad,"0.3.2").is_empty(),"Unknown channel fails closed")
 bad=release.duplicate(true);bad["assets"].append(bad["assets"][0].duplicate(true))
 check(U.metadata(bad,"0.3.2").is_empty(),"Duplicate canonical assets are ambiguous and rejected")
 bad=release.duplicate(true);bad["assets"][0]["size"]=U.MAX_EXECUTABLE+1
 check(U.metadata(bad,"0.3.2").is_empty(),"Stable executable size remains bounded")
 bad=release.duplicate(true);bad["assets"][0]["browser_download_url"]="https://example.org/Print.Shop.Tycoon.exe"
 check(U.metadata(bad,"0.3.2").is_empty(),"Stable download cannot leave official repository")
 bad=release.duplicate(true);bad["assets"][0]["digest"]=""
 check(U.metadata(bad,"0.3.2").is_empty(),"Missing stable digest blocks download")
 check(U.supported_filename("C:/games/Print.Shop.Tycoon.exe") and U.supported_filename("C:/games/Print Shop Tycoon.exe") and not U.supported_filename("C:/games/renamed.exe"),"Only both official installed filenames are supported")
 var path=OS.get_environment("PST_RELEASE_EXE")
 if path!="":
  check(U.verify_archive(path,meta),"Downloaded real v1 EXE matches the published bytes and digest")
  var root=OS.get_user_data_dir().path_join("format-test-"+Crypto.new().generate_random_bytes(16).hex_encode());DirAccess.make_dir_recursive_absolute(root)
  var staged=root.path_join("candidate.exe")
  check(U.stage_package(path,staged,meta),"Real standalone EXE stages without ZIP extraction")
  check(FileAccess.get_sha256(staged)==meta["digest"],"Staged real executable remains byte-identical")
  var tampered=meta.duplicate();tampered["digest"]="0".repeat(64)
  check(not U.stage_package(path,root.path_join("rejected.exe"),tampered),"Tampered standalone package never stages")
  check(not U.verify_archive(path,{"format":"unknown","size":128313248,"digest":meta["digest"]}),"Unknown package format fails closed")
 print("UPDATE RELEASE FORMATS: ",checks," checks, ",failures," failures")
 quit(failures)

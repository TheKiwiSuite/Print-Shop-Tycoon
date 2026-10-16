param([string[]]$Kinds=@('sticker','heat','art','finish','pack','storage','banner','cnc','dock'),[string]$RenderFolder='rotations-v1')
$ErrorActionPreference='Stop'
$blenderExe='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$artRoot=$PSScriptRoot
foreach($kind in $Kinds){
  if($kind -notin @('sticker','heat','art','finish','pack','storage','banner','cnc','dock')){throw "Unknown equipment: $kind"}
  $itemRoot=Join-Path $artRoot "equipment-review-v1/$kind"
  New-Item -ItemType Directory -Force -Path $itemRoot | Out-Null
  & $blenderExe --background --python (Join-Path $artRoot 'build_equipment_collection.py') -- --kind $kind *> (Join-Path $itemRoot 'model-build.log')
  if($LASTEXITCODE -ne 0){throw "Blender model failed: $kind. See $itemRoot/model-build.log"}
  Write-Output "MODEL_READY $kind"
  & $blenderExe --background --python (Join-Path $artRoot 'render_measured_rotations.py') -- --source (Join-Path $itemRoot "$kind.blend") --output (Join-Path $itemRoot $RenderFolder) --size 900 --status candidate *> (Join-Path $itemRoot 'rotation-render.log')
  if($LASTEXITCODE -ne 0){throw "Rotation failed: $kind. See $itemRoot/rotation-render.log"}
  Write-Output "ROTATIONS_READY $kind 16"
}

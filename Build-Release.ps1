param(
    [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [string]$GodotPath,
    [string]$ExportTemplatePath,
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'
$releaseRoot = $PSScriptRoot
$workspaceRoot = (Resolve-Path -LiteralPath (Join-Path $releaseRoot '../..')).Path
$workRoot = (Resolve-Path -LiteralPath (Join-Path $workspaceRoot 'work')).Path
$sourceRoot = Join-Path $releaseRoot 'source'
$projectPath = Join-Path $sourceRoot 'project.godot'
$installedExe = Join-Path $releaseRoot 'windows/Print Shop Tycoon.exe'
$infoPath = Join-Path $releaseRoot 'BUILD-INFO.json'
$packagePath = Join-Path $workspaceRoot 'outputs/PrintShopTycoon-Windows-Playable.zip'
if (!$GodotPath) { $GodotPath = Join-Path $workRoot 'godot/Godot_v4.5.1-stable_win64_console.exe' }
if (!(Test-Path -LiteralPath $GodotPath)) { throw "Godot not found: $GodotPath" }
if (Test-Path -LiteralPath $infoPath) {
    $installed = Get-Content -LiteralPath $infoPath -Raw | ConvertFrom-Json
    if ([version]$Version -le [version]$installed.version) {
        throw "Each release needs a higher version than the installed $($installed.version)."
    }
}
# Build separately so a failed export cannot destroy the installed game.
$stageRoot = Join-Path $workRoot ('native-release-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stageRoot | Out-Null
$candidate = Join-Path $stageRoot 'Print Shop Tycoon.exe'
$stagedPackage = Join-Path $stageRoot 'PrintShopTycoon-Windows-Playable.zip'
$stagedInfo = Join-Path $stageRoot 'BUILD-INFO.json'
$exportLog = Join-Path $workRoot 'latest-native-export.log'
$smokeLog = Join-Path $workRoot 'latest-native-smoke.log'
$originalProject = Get-Content -LiteralPath $projectPath -Raw
$presetPath = Join-Path $sourceRoot 'export_presets.cfg'
$originalPresets = Get-Content -LiteralPath $presetPath -Raw
if (!$ExportTemplatePath) {
    $workspaceTemplate = Join-Path $workRoot 'export-templates/templates/windows_release_x86_64.exe'
    if (Test-Path -LiteralPath $workspaceTemplate) { $ExportTemplatePath = $workspaceTemplate }
}
if ($ExportTemplatePath) {
    $ExportTemplatePath = (Resolve-Path -LiteralPath $ExportTemplatePath).Path.Replace('\','/')
}
$previousBuildTemp = $env:TEMP
$previousBuildTmp = $env:TMP
$published = $false
try {
    # Isolate build scratch/logs from the player's AppData and system Temp.
    $env:TEMP = $stageRoot
    $env:TMP = $stageRoot
    if ($originalProject -notmatch '(?m)^config/version="[^"]+"') { throw 'Missing application config/version.' }
    $newProject = $originalProject -replace '(?m)^config/version="[^"]+"', ('config/version="' + $Version + '"')
    [IO.File]::WriteAllText($projectPath, $newProject, [Text.UTF8Encoding]::new($false))
    # Keep machine-specific template locations out of the shared export preset.
    if ($ExportTemplatePath) {
        $localPresets = $originalPresets -replace '(?m)^custom_template/release="[^"]*"', ('custom_template/release="' + $ExportTemplatePath + '"')
        [IO.File]::WriteAllText($presetPath, $localPresets, [Text.UTF8Encoding]::new($false))
    }
    & $GodotPath --headless --log-file (Join-Path $stageRoot 'export-engine.log') --path $sourceRoot --export-release 'Windows Desktop' $candidate *> $exportLog
    [IO.File]::WriteAllText($presetPath, $originalPresets, [Text.UTF8Encoding]::new($false))
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $candidate) -or
        # Godot reports an unavailable Windows CA store in this restricted build environment.
        # This offline game makes no HTTPS requests; keep all other engine errors fatal.
        (Select-String -LiteralPath $exportLog -Pattern 'SCRIPT ERROR:|ERROR:(?! Failed to read the root certificate store\.)' -Quiet)) {
        throw "Export failed. See $exportLog"
    }
    $smokeErrors = Join-Path $stageRoot 'smoke-stderr.log'
    $smokeProcess = Start-Process -FilePath $candidate -ArgumentList @('--headless','--log-file',(Join-Path $stageRoot 'smoke-engine.log'),'--','--smoke') -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput $smokeLog -RedirectStandardError $smokeErrors
    Get-Content -LiteralPath $smokeErrors | Add-Content -LiteralPath $smokeLog
    if ($smokeProcess.ExitCode -ne 0 -or (Select-String -LiteralPath $smokeLog -Pattern 'SCRIPT ERROR:|ERROR:(?! Failed to read the root certificate store\.)' -Quiet)) {
        throw "Exported game startup failed. See $smokeLog"
    }
    $running = @(Get-Process -Name 'Print Shop Tycoon' -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -eq $installedExe
    })
    if ($running.Count) { throw 'Close the running game normally to save progress, then rerun this release command.' }
    $info = [ordered]@{
        version = $Version
        built_at = [DateTimeOffset]::Now.ToString('o')
        platform = 'Windows x86_64'
        engine = 'Godot 4.5.1'
        executable = 'windows/Print Shop Tycoon.exe'
        sha256 = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
    }
    [IO.File]::WriteAllText($stagedInfo, ($info | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($stagedPackage, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $files = Get-ChildItem -LiteralPath $releaseRoot -File -Recurse | Where-Object {
            $_.FullName -notmatch '[\\/]\.(godot|git)[\\/]' -and $_.Extension -notin @('.blend1','.tmp') -and
            $_.FullName -ne $infoPath -and $_.FullName -ne $installedExe
        }
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($releaseRoot.Length + 1).Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName,
                ('PrintShopTycoon-Native/' + $relative), [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $candidate,
            'PrintShopTycoon-Native/windows/Print Shop Tycoon.exe') | Out-Null
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $stagedInfo,
            'PrintShopTycoon-Native/BUILD-INFO.json') | Out-Null
    } finally { $zip.Dispose() }
    # Read back the packaged executable and verify it is the exact candidate.
    $verifyZip = [IO.Compression.ZipFile]::OpenRead($stagedPackage)
    try {
        $entry = $verifyZip.GetEntry('PrintShopTycoon-Native/windows/Print Shop Tycoon.exe')
        $entryStream = $entry.Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $packedHash = [BitConverter]::ToString($hasher.ComputeHash($entryStream)).Replace('-','') }
        finally { $entryStream.Dispose(); $hasher.Dispose() }
        if ($packedHash -ne $info.sha256) { throw 'Packaged executable checksum mismatch.' }
    } finally { $verifyZip.Dispose() }
    Copy-Item -LiteralPath $candidate -Destination $installedExe -Force
    Copy-Item -LiteralPath $stagedInfo -Destination $infoPath -Force
    Move-Item -LiteralPath $stagedPackage -Destination $packagePath -Force
    $published = $true
    # A fixed shortcut targets the fixed native executable, with no test flags.
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktopPath 'Print Shop Tycoon.lnk'
    $shortcutWriter = New-Object -ComObject WScript.Shell
    $shortcut = $shortcutWriter.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $installedExe
    $shortcut.WorkingDirectory = Split-Path -Parent $installedExe
    $shortcut.Arguments = ''
    $shortcut.Description = "Print Shop Tycoon - latest installed build v$Version"
    $officialIcon = Join-Path $releaseRoot 'icon/PrintShopTycoon.ico'
    $shortcut.IconLocation = if (Test-Path -LiteralPath $officialIcon) { "$officialIcon,0" } else { "$installedExe,0" }
    $shortcut.Save()
    Write-Output "Installed v$Version. Desktop shortcut: $shortcutPath"
    Write-Output "SHA256: $($info.sha256)"
    $env:TEMP = $previousBuildTemp
    $env:TMP = $previousBuildTmp
    if (!$NoLaunch) { Start-Process -FilePath $installedExe -WorkingDirectory (Split-Path -Parent $installedExe) }
} finally {
    [IO.File]::WriteAllText($presetPath, $originalPresets, [Text.UTF8Encoding]::new($false))
    $env:TEMP = $previousBuildTemp
    $env:TMP = $previousBuildTmp
    if (!$published) { [IO.File]::WriteAllText($projectPath, $originalProject, [Text.UTF8Encoding]::new($false)) }
    # Resolve and bound the recursive cleanup to this script's own staging folder.
    $resolvedStage = (Resolve-Path -LiteralPath $stageRoot).Path
    if ((Split-Path -Parent $resolvedStage) -ne $workRoot -or
        (Split-Path -Leaf $resolvedStage) -notmatch '^native-release-[0-9a-f]{32}$') {
        throw "Refusing unexpected staging cleanup path: $resolvedStage"
    }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
}

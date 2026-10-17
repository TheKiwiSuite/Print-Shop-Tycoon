$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'Update-Game.ps1'
$root = Join-Path $env:RUNNER_TEMP ('updater-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($scenario in @('valid', 'corrupt', 'traversal', 'running', 'older', 'missing_digest')) {
    $case = Join-Path $root $scenario
    New-Item -ItemType Directory -Path $case | Out-Null
    $zip = Join-Path $case 'fixture.zip'
    $archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
    $entryName = if ($scenario -eq 'traversal') { 'PrintShopTycoon/../../outside.exe' } else { 'PrintShopTycoon/windows/Print Shop Tycoon.exe' }
    $entry = $archive.CreateEntry($entryName)
    $writer = New-Object IO.StreamWriter($entry.Open())
    $writer.Write('inert QA fixture, never executed'); $writer.Dispose(); $archive.Dispose()
    $wrapper = Join-Path $case 'run.ps1'
    @'
param($Case, $Updater, $Scenario)
$env:LOCALAPPDATA = Join-Path $Case 'local'
$env:APPDATA = Join-Path $Case 'roaming'
$profilePath = Join-Path $env:APPDATA 'PrintShopTycoonNative'
New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $profilePath 'native-shop-v3.json'), '{"fixture":"preserve exactly"}')
function Read-Host { param($Prompt) return 'UPDATE' }
function Get-Process { param($Name, $ErrorAction) if ($Scenario -eq 'running') { return [pscustomobject]@{Id=123} } }
function Start-Process { param($FilePath, $ArgumentList) if ($FilePath -ne 'explorer.exe') { throw 'Unexpected executable launch' } }
function Invoke-RestMethod {
    param($Uri, $Headers, $TimeoutSec)
    if ($Uri -ne 'https://api.github.com/repos/TheKiwiSuite/Print-Shop-Tycoon/releases?per_page=100') { throw 'Unexpected API endpoint' }
    $zip = Join-Path $Case 'fixture.zip'
    $digest = 'sha256:' + (Get-FileHash -LiteralPath $zip).Hash.ToLowerInvariant()
    if ($Scenario -eq 'corrupt') { $digest = 'sha256:' + ('0' * 64) }
    if ($Scenario -eq 'missing_digest') { $digest = $null }
    return @([pscustomobject]@{draft=$false;tag_name='v9.0.0-windows-alpha';assets=@([pscustomobject]@{name='PrintShopTycoon-Windows-v9.0.0.zip';id=42;digest=$digest;size=(Get-Item $zip).Length;browser_download_url='https://github.com/TheKiwiSuite/Print-Shop-Tycoon/releases/download/v9.0.0-windows-alpha/PrintShopTycoon-Windows-v9.0.0.zip'})})
}
function Invoke-WebRequest { param($UseBasicParsing, $Uri, $OutFile, $Headers, $TimeoutSec) Copy-Item -LiteralPath (Join-Path $Case 'fixture.zip') -Destination $OutFile }
# Declare the mock switch correctly for Windows PowerShell binding.
Remove-Item Function:Invoke-WebRequest
function Invoke-WebRequest { param([switch]$UseBasicParsing, $Uri, $OutFile, $Headers, $TimeoutSec) Copy-Item -LiteralPath (Join-Path $Case 'fixture.zip') -Destination $OutFile }
$version = if ($Scenario -eq 'older') { '10.0.0' } else { '0.3.0' }
& $Updater -CurrentVersion $version
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $wrapper
    $log = Join-Path $case 'out.txt'
    & powershell.exe -NoProfile -File $wrapper $case $scriptPath $scenario *> $log
    $code = $LASTEXITCODE
    $expected = if ($scenario -in @('valid', 'older')) { 0 } else { 1 }
    if ($code -ne $expected) { Get-Content $log; throw "$scenario returned $code, expected $expected" }
    $installed = Test-Path -LiteralPath (Join-Path $case 'local/PrintShopTycoonUpdates/v9.0.0-42/windows/Print Shop Tycoon.exe')
    if ($installed -ne ($scenario -eq 'valid')) { Get-Content $log; throw "$scenario publication mismatch" }
    $save = Join-Path $case 'roaming/PrintShopTycoonNative/native-shop-v3.json'
    if ([IO.File]::ReadAllText($save) -cne '{"fixture":"preserve exactly"}') { throw "$scenario changed save" }
    if ($scenario -eq 'valid') {
        $backups = @(Get-ChildItem (Join-Path $case 'local/PrintShopTycoonUpdates') -Directory -Filter 'save-backup-*')
        if ($backups.Count -ne 1 -or (Get-FileHash $save).Hash -cne (Get-FileHash (Join-Path $backups[0].FullName 'native-shop-v3.json')).Hash) { throw 'Backup mismatch' }
    }
    Write-Host "PASS updater $scenario"
}

# Windows PowerShell 5.1+. No elevation or execution-policy bypass.
[CmdletBinding()]
param([string]$CurrentVersion = '0.0.0')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repo = 'TheKiwiSuite/Print-Shop-Tycoon'
$headers = @{ 'User-Agent' = 'PrintShopTycoon-Updater'; Accept = 'application/vnd.github+json' }
$lock = $null
try {
    $current = [version]$CurrentVersion
    $root = Join-Path $env:LOCALAPPDATA 'PrintShopTycoonUpdates'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $lock = [IO.File]::Open((Join-Path $root 'update.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    Write-Host 'Checking official Windows alpha releases...'
    # Latest endpoint omits alpha releases. Select only the exact Windows channel.
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=100" -Headers $headers -TimeoutSec 30
    $candidates = @($releases | Where-Object { !$_.draft -and $_.tag_name -cmatch '^v(\d+\.\d+\.\d+)-windows-alpha$' } | Sort-Object { [version]($_.tag_name -replace '^v|\-windows-alpha$', '') } -Descending)
    if (!$candidates.Count) { throw 'No official release is available.' }
    $release = $candidates[0]
    $version = [version]($release.tag_name -replace '^v|\-windows-alpha$', '')
    if ($version -le $current) { Write-Host 'You already have the newest version in this channel.'; return }
    $name = "PrintShopTycoon-Windows-v$version.zip"
    $assets = @($release.assets | Where-Object { $_.name -ceq $name })
    if ($assets.Count -ne 1) { throw 'Missing or ambiguous Windows package.' }
    $asset = $assets[0]
    # Trust the digest supplied by the authenticated HTTPS GitHub API, never a checksum inside the ZIP.
    if (!$asset.digest -or $asset.digest -cnotmatch '^sha256:[a-f0-9]{64}$') { throw 'Release has no valid GitHub SHA-256 digest. Update refused.' }
    $expectedUrl = "https://github.com/$repo/releases/download/$($release.tag_name)/$name"
    if ($asset.browser_download_url -cne $expectedUrl -or $asset.size -le 0 -or $asset.size -gt 536870912) { throw 'Invalid package URL or size.' }
    Write-Host "Available: $version. Save and close the game before continuing."
    if ((Read-Host 'Type UPDATE to download and prepare this version') -cne 'UPDATE') { return }
    $gameProcesses = @(Get-Process -Name 'Print Shop Tycoon' -ErrorAction SilentlyContinue)
    if ($gameProcesses.Count) { throw 'The game is still running. Save and close it, then run this updater again.' }
    $stage = Join-Path $root ('staging-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage | Out-Null
    $zip = Join-Path $stage 'package.zip'
    Invoke-WebRequest -UseBasicParsing -Uri $expectedUrl -OutFile $zip -Headers $headers -TimeoutSec 180
    if ((Get-Item -LiteralPath $zip).Length -ne $asset.size) { throw 'Download size mismatch; old game retained.' }
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -cne $asset.digest.Substring(7)) { throw 'Download checksum mismatch; old game retained.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    $unpack = Join-Path $stage 'unpacked'
    $seen = @{}
    $total = [long]0
    try {
        foreach ($entry in $archive.Entries) {
            $path = $entry.FullName.Replace('\', '/')
            if ($path -notmatch '^PrintShopTycoon/' -or $path -match '(^|/)\.\.?(/|$)|:|^/' -or $path -match '[. ](/|$)' -or $seen.ContainsKey($path.ToLowerInvariant())) { throw 'Unsafe or duplicate archive path.' }
            $seen[$path.ToLowerInvariant()] = $true
            $total += $entry.Length
            if ($total -gt 1073741824 -or $archive.Entries.Count -gt 10000) { throw 'Archive expansion limit exceeded.' }
            if (($entry.ExternalAttributes -shr 16 -band 61440) -eq 40960) { throw 'Archive links are prohibited.' }
        }
    } finally { $archive.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $unpack)
    $package = Join-Path $unpack 'PrintShopTycoon'
    $exe = Join-Path $package 'windows/Print Shop Tycoon.exe'
    if (!(Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Package has no Windows game.' }
    # Snapshot the complete persistent profile, including preferences and rotating backup.
    $profile = Join-Path $env:APPDATA 'PrintShopTycoonNative'
    if (Test-Path -LiteralPath $profile) {
        $backup = Join-Path $root ('save-backup-' + [guid]::NewGuid().ToString('N'))
        Copy-Item -LiteralPath $profile -Destination $backup -Recurse
        foreach ($file in Get-ChildItem -LiteralPath $profile -Recurse -File) {
            $relative = $file.FullName.Substring($profile.Length).TrimStart('\', '/')
            if ((Get-FileHash -LiteralPath $file.FullName).Hash -cne (Get-FileHash -LiteralPath (Join-Path $backup $relative)).Hash) { throw 'Save backup verification failed.' }
        }
        Write-Host "Verified save backup: $backup"
    }
    $destination = Join-Path $root "v$version-$($asset.id)"
    if (Test-Path -LiteralPath $destination) { throw 'This version is already prepared; open its folder or choose a newer release.' }
    # Same-volume directory rename publishes only a completely verified package.
    Move-Item -LiteralPath $package -Destination $destination
    Write-Host "Update ready: $destination\windows\Print Shop Tycoon.exe"
    Write-Host 'Your previous installation is retained. Continue loads the same saved shop.'
    Write-Host 'Do not reopen an older version after saving with a newer version. Restore a pre-update backup first.'
    Start-Process explorer.exe -ArgumentList ('"{0}"' -f $destination)
} catch {
    Write-Host ("Update stopped safely: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $lock) { $lock.Dispose() }
    if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
}

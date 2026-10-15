param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_]+$')]
    [string]$Test,
    [switch]$Graphics,
    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$source = Join-Path $PSScriptRoot 'source'
$testFile = Join-Path $source "test/$Test.gd"
if (!(Test-Path -LiteralPath $testFile -PathType Leaf)) { throw "Unknown QA test: $Test" }
# Launch the engine directly so a console wrapper cannot leave an orphaned child.
$engine = Join-Path $workspace 'work/godot/Godot_v4.5.1-stable_win64.exe'
$runId = '{0}-{1}-{2}' -f $Test, (Get-Date -Format 'yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
$runRoot = Join-Path $workspace "work/qa-runs/$runId"
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$engineLog = Join-Path $runRoot 'engine.log'
$stdout = Join-Path $runRoot 'stdout.log'
$stderr = Join-Path $runRoot 'stderr.log'
# Fail before starting Godot if its log is not writable. Godot 4.5.1 can crash
# inside RotatedFileLogger when FileAccess::open returns null.
Set-Content -LiteralPath $engineLog -Value '' -NoNewline
$engineArguments = @('--log-file', ('"{0}"' -f $engineLog), '--path', ('"{0}"' -f $source), '--script', "res://test/$Test.gd")
if (!$Graphics) { $engineArguments = @('--headless') + $engineArguments }
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
$qaProcess = $null
try {
    $env:TEMP = $runRoot
    $env:TMP = $runRoot
    $qaProcess = Start-Process -FilePath $engine -ArgumentList $engineArguments -WorkingDirectory $source -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    Write-Output "QA_PID=$($qaProcess.Id)"
    Write-Output "QA_LOG=$engineLog"
    if (!$qaProcess.WaitForExit($TimeoutSeconds * 1000)) {
        throw "QA timed out after $TimeoutSeconds seconds. Logs: $runRoot"
    }
    $qaProcess.WaitForExit()
    $qaProcess.Refresh()
    $result = $qaProcess.ExitCode
    Get-Content -LiteralPath $stdout
    Get-Content -LiteralPath $stderr
    # Keep the already-investigated offline certificate diagnostic visible;
    # every other engine/script error still fails the test.
    $failure = Select-String -LiteralPath $engineLog, $stdout, $stderr -Pattern 'SCRIPT ERROR:|ERROR:(?! Failed to read the root certificate store\.)|Program crashed with signal' -Quiet
    if ($result -ne 0 -or $failure) { throw "QA failed (exit $result). Logs: $runRoot" }
    Write-Output "QA_RESULT=PASS ($Test)"
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
    if ($null -ne $qaProcess) {
        # This exact Process object is owned by this runner; never match by name
        # or terminate the separately installed player executable.
        if (!$qaProcess.HasExited) {
            $qaProcess.Kill()
            $null = $qaProcess.WaitForExit(5000)
        }
        $qaProcess.Dispose()
    }
}

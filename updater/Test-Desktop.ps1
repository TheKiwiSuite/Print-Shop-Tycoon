param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Windows.Forms,System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class DesktopQA {
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd,uint msg,IntPtr wParam,IntPtr lParam);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd,int x,int y,int width,int height,bool repaint);
 [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr extra);
}
'@
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory=(Resolve-Path $OutputDirectory).Path
$script:checks=0
$script:results=@()
function Assert([bool]$Value,[string]$Label) {
 $script:checks++
 $script:results += [pscustomobject]@{check=$Label;passed=$Value}
 if (!$Value) {throw "FAIL: $Label"}
 Write-Host "PASS: $Label"
}
function State {
 for($i=0;$i -lt 30;$i++) {
  try {if(Test-Path $script:statePath){$parsed=Get-Content -LiteralPath $script:statePath -Raw | ConvertFrom-Json;if($null -ne $parsed -and $null -ne $parsed.owner -and $parsed.screen){return $parsed}}} catch {}
  Start-Sleep -Milliseconds 100
 }
 throw 'Desktop QA state not available.'
}
function Wait-State([scriptblock]$Predicate,[string]$Label) {
 for($i=0;$i -lt 80;$i++) {
  $value=State
  if (& $Predicate $value) {Assert $true $Label;return $value}
  Start-Sleep -Milliseconds 100
 }
 Assert $false $Label
}
function Button([string]$Name) {
 for($i=0;$i -lt 50;$i++) {
  # AccessKit's Windows provider can append whitespace to an accessible label.
  $elements=$script:window.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
  foreach($element in $elements) {if($element.Current.Name.Trim() -eq $Name){return $element}}
  Start-Sleep -Milliseconds 100
 }
 throw "Accessible control not found: $Name"
}
function Invoke-Button([string]$Name) {
 $element=Button $Name
 $pattern=$element.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
 $pattern.Invoke()
}
function Capture([string]$Name) {
 $rect=$script:window.Current.BoundingRectangle
 $bitmap=New-Object System.Drawing.Bitmap([int]$rect.Width,[int]$rect.Height)
 $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
 try {
  $graphics.CopyFromScreen([int]$rect.X,[int]$rect.Y,0,0,$bitmap.Size)
  $bitmap.Save((Join-Path $OutputDirectory "$Name.png"),[System.Drawing.Imaging.ImageFormat]::Png)
 } finally {$graphics.Dispose();$bitmap.Dispose()}
}
$script:statePath=Join-Path $env:APPDATA 'PrintShopTycoonNative/desktop-acceptance-state.json'
$log=Join-Path $OutputDirectory 'game-desktop.log'
$process=$null
try {
 # ANGLE DLLs are supplied only to this disposable CI validation folder from
 # a digest-verified official CEF archive. They are not shipped to players.
 $arguments=@('--windowed','--resolution','1280x720','--position','20,20','--rendering-method','gl_compatibility','--rendering-driver','opengl3_angle','--audio-driver','Dummy','--accessibility','always','--max-fps','60','--log-file',('"{0}"' -f $log),'--','--qa-desktop')
 $process=Start-Process -FilePath $Executable -ArgumentList $arguments -PassThru
 $process.Refresh()
 for($i=0;$i -lt 120 -and $process.MainWindowHandle -eq 0;$i++) {
  Start-Sleep -Milliseconds 250;$process.Refresh()
  if($process.HasExited){Get-Content $log -ErrorAction SilentlyContinue;throw 'Packaged GUI exited before creating a window.'}
 }
 Assert ($process.MainWindowHandle -ne 0) 'Packaged Windows executable creates a real desktop window'
 [DesktopQA]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
 $script:window=[System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
 $initial=Wait-State {param($s) $s.screen -eq 'shop' -and $s.paused} 'Isolated desktop demo starts paused'
 Assert ($initial.cash -eq 5000) 'Desktop tests use a disposable demo, not career progress'
 $process.Refresh()
 [DesktopQA]::SendMessage($process.MainWindowHandle,0x003D,[IntPtr]::Zero,[IntPtr](-25)) | Out-Null
 Start-Sleep -Milliseconds 500
 $script:window=[System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
 $elements=$script:window.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
 @($elements | ForEach-Object { [pscustomobject]@{name=$_.Current.Name;type=$_.Current.ControlType.ProgrammaticName;offscreen=$_.Current.IsOffscreen} }) | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDirectory 'initial-accessibility-tree.json')
 Capture 'windows-initial'
 $workshop=Button 'WORKSHOP + STYLE'
 Assert ($workshop.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button) 'Windows UI Automation exposes a named button'
 Invoke-Button 'WORKSHOP + STYLE'
 $null=Wait-State {param($s) $s.modal -eq 'workshop'} 'Native accessible Invoke opens Workshop'
 Invoke-Button 'Style'
 $null=Wait-State {param($s) $s.modal -eq 'workshop'} 'Style tab remains in Workshop'
 Invoke-Button 'MOVE DECOR + SHOP SIGN'
 $null=Wait-State {param($s) $s.modal -eq 'studio'} 'Decor and signage controls open through Windows accessibility'
 $name=Button 'Shop name, up to 40 characters'
 Assert ($name.Current.ControlType -eq [System.Windows.Automation.ControlType]::Edit) 'Windows exposes shop name as an editable text field'
 $name.SetFocus()
 [System.Windows.Forms.SendKeys]::SendWait('^aDesktop Print Studio')
 [System.Windows.Forms.SendKeys]::SendWait('{TAB}')
 $null=Wait-State {param($s) $s.focused -eq 'SAVE SHOP NAME'} 'Tab moves from text field to Save in visual order'
 [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
 $null=Wait-State {param($s) $s.style.shop_name -eq 'Desktop Print Studio'} 'Actual keyboard Enter saves typed signage'
 Assert ((State).paused) 'Typing spaces in the shop name never toggles shop pause'
 Capture 'windows-signage-accessibility'
 Invoke-Button 'BACK TO STYLE';Invoke-Button 'BACK TO SHOP'
 $null=Wait-State {param($s) $s.modal -eq ''} 'Desktop navigation returns to floor'
 [DesktopQA]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
 [System.Windows.Forms.SendKeys]::SendWait(' ')
 $null=Wait-State {param($s) !$s.paused} 'Real Space input resumes the shop'
 $before=(State).owner.pos
 [DesktopQA]::keybd_event(0x44,0,0,[UIntPtr]::Zero)
 Start-Sleep -Milliseconds 500
 [DesktopQA]::keybd_event(0x44,0,2,[UIntPtr]::Zero)
 $after=(State).owner.pos
 Assert (($before[0] -ne $after[0]) -or ($before[1] -ne $after[1])) 'Physical D key moves Sam in the packaged Windows game'
 $form=New-Object System.Windows.Forms.Form
 $form.Text='Temporary focus acceptance';$form.Width=280;$form.Height=100
 $form.Show();$form.Activate();[System.Windows.Forms.Application]::DoEvents()
 $null=Wait-State {param($s) !$s.window_focus} 'Native focus loss is observed'
 $stopped=(State).owner.pos
 Start-Sleep -Milliseconds 400
 $settled=(State).owner.pos
 Assert (($stopped[0] -eq $settled[0]) -and ($stopped[1] -eq $settled[1])) 'Losing focus stops manual movement without stuck keys'
 $form.Close();$form.Dispose()
 [DesktopQA]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
 $null=Wait-State {param($s) $s.window_focus} 'Native window focus can return'
 [System.Windows.Forms.SendKeys]::SendWait(' ')
 $null=Wait-State {param($s) $s.paused} 'Pause remains available after focus recovery'
 $screen=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
 $sizes=@(@(960,540),@(1280,720),@(1426,810))
 foreach($size in $sizes){
  $w=[Math]::Min($size[0],$screen.Width-30);$h=[Math]::Min($size[1],$screen.Height-30)
  [DesktopQA]::MoveWindow($process.MainWindowHandle,10,10,$w,$h,$true) | Out-Null
  Start-Sleep -Milliseconds 400
  $rect=$script:window.Current.BoundingRectangle
  $buttons=$script:window.FindAll([System.Windows.Automation.TreeScope]::Descendants,(New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty,[System.Windows.Automation.ControlType]::Button)))
  Assert ($buttons.Count -gt 10) "Native controls remain exposed at $w x $h"
  foreach($b in $buttons){
   # Raw UIA descendants include hidden nodes; only the Control View is player-facing.
   if($b.Current.IsOffscreen -or !$b.Current.IsControlElement){continue}
   $r=$b.Current.BoundingRectangle
   Assert ($r.X -ge $rect.X-2 -and $r.Y -ge $rect.Y-2 -and $r.Right -le $rect.Right+2 -and $r.Bottom -le $rect.Bottom+2) "Control stays inside window: $($b.Current.Name) at $w x $h"
  }
  Capture "windows-${w}x${h}"
 }
 $state=State;$frames=@($state.frames | Sort-Object)
 $metadata=[pscustomobject]@{scope='Automated actual Windows desktop, UI Automation, keyboard, focus and window resize. Human screen-reader listening and changes to OS monitor scaling are not certified.';dpi=[DesktopQA]::GetDpiForWindow($process.MainWindowHandle);screen=@($screen.Width,$screen.Height);frame_count=$frames.Count;p95_frame_seconds=if($frames.Count){$frames[[Math]::Min($frames.Count-1,[int]($frames.Count*.95))]}else{0};checks=$script:results}
 $metadata | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $OutputDirectory 'windows-desktop.json')
 Write-Host "WINDOWS DESKTOP ACCEPTANCE: $script:checks checks, 0 failures"
} finally {
 try {State | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $OutputDirectory 'last-desktop-state.json')} catch {}
 if($null -ne $process -and !$process.HasExited){$process.CloseMainWindow() | Out-Null;if(!$process.WaitForExit(5000)){$process.Kill()}}
 if(Test-Path $log){Get-Content -LiteralPath $log}
}

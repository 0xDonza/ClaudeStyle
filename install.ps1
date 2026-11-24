# install.ps1 - sets up ClaudeStyle. Run via Install.bat / Uninstall.bat.
param([switch]$Uninstall)
Add-Type -AssemblyName System.Windows.Forms

$App   = 'ClaudeStyle'
$Dest  = Join-Path $env:LOCALAPPDATA $App
$Dirs  = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))
$Links = $Dirs | ForEach-Object { Join-Path $_ "$App.lnk" }
$StartupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'ClaudeStyle (background).lnk'
$PS = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

# Stop any running ClaudeStyle helpers so the new version takes over
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -like '*ClaudeStyle.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

# Clean up the earlier test version ("Claude (Themed)")
foreach ($d in $Dirs) { Remove-Item (Join-Path $d 'Claude (Themed).lnk') -ErrorAction SilentlyContinue }
Remove-Item (Join-Path $env:LOCALAPPDATA 'ClaudeTheme') -Recurse -Force -ErrorAction SilentlyContinue

if ($Uninstall) {
  $Links | ForEach-Object { Remove-Item $_ -ErrorAction SilentlyContinue }
  foreach ($d in $Dirs) { Remove-Item (Join-Path $d 'ClaudeStyle (Browser).lnk') -ErrorAction SilentlyContinue }
  Remove-Item $StartupLink -ErrorAction SilentlyContinue
  foreach ($n in 'ClaudeStyle - Turn off.lnk', 'ClaudeStyle - Turn on.lnk', 'ClaudeStyle On - Off.lnk') { Remove-Item (Join-Path ([Environment]::GetFolderPath('Programs')) $n) -ErrorAction SilentlyContinue }
  Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue
  [Windows.Forms.MessageBox]::Show("ClaudeStyle removed.`nYour normal Claude app is untouched.", $App) | Out-Null
  exit 0
}

$Src = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item (Join-Path $Src 'ClaudeStyle.ps1') $Dest -Force
Copy-Item (Join-Path $Src 'mod.js') $Dest -Force
Copy-Item (Join-Path $Src 'main-inject.js') $Dest -Force
if (-not (Test-Path (Join-Path $Dest 'theme.css'))) { Copy-Item (Join-Path $Src 'theme.css') $Dest -Force }
Get-ChildItem $Dest | Unblock-File -ErrorAction SilentlyContinue

# Find Claude (Microsoft Store version first, then the classic installer) for the icon
$pkg = Get-AppxPackage -Name 'Claude' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pkg) { $pkg = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.PackageFamilyName -like 'Claude_*' } | Select-Object -First 1 }
$cands = @()
if ($pkg) {
  $app = (Get-AppxPackageManifest $pkg).Package.Applications.Application | Select-Object -First 1
  $cands += (Join-Path $pkg.InstallLocation $app.Executable)
}
$cands += @("$env:LOCALAPPDATA\AnthropicClaude\claude.exe", "$env:LOCALAPPDATA\Programs\Claude\Claude.exe", "$env:ProgramFiles\Claude\Claude.exe")
$icon = "$env:SystemRoot\System32\shell32.dll,43"
foreach ($p in $cands) { if ($p -and (Test-Path $p)) { $icon = "$p,0"; break } }
if (-not $pkg -and $icon -like '*shell32*') {
  [Windows.Forms.MessageBox]::Show("Heads up: couldn't find the Claude app. Install Claude first, then run this again.", $App) | Out-Null
}

$shell = New-Object -ComObject WScript.Shell
foreach ($l in $Links) {
  $s = $shell.CreateShortcut($l)
  $s.TargetPath = $PS
  $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Dest\ClaudeStyle.ps1`""
  $s.WorkingDirectory = $Dest
  $s.WindowStyle = 7
  $s.IconLocation = $icon
  $s.Description = 'Open Claude with your ClaudeStyle theme'
  $s.Save()
}

# Only one Start menu entry ("ClaudeStyle"). Remove on/off shortcuts from earlier versions;
# turning off and on now happens inside Claude's ClaudeStyle panel.
$Programs = [Environment]::GetFolderPath('Programs')
foreach ($old in 'ClaudeStyle - Turn off.lnk', 'ClaudeStyle - Turn on.lnk', 'ClaudeStyle On - Off.lnk') { Remove-Item (Join-Path $Programs $old) -ErrorAction SilentlyContinue }
Remove-Item (Join-Path $Dest 'off.flag') -ErrorAction SilentlyContinue   # installing = on

# Background helper: starts with Windows and connects whenever Claude opens (no clicking needed)
$s = $shell.CreateShortcut($StartupLink)
$s.TargetPath = $PS
$s.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Dest\ClaudeStyle.ps1`" -Watch"
$s.WorkingDirectory = $Dest
$s.WindowStyle = 7
$s.IconLocation = $icon
$s.Description = 'ClaudeStyle background helper'
$s.Save()
Start-Process $PS -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Dest\ClaudeStyle.ps1`" -Watch" -WindowStyle Hidden

[Windows.Forms.MessageBox]::Show("Done!`n`nJust open Claude the normal way - ClaudeStyle connects by itself (it starts with Windows).`nIn Claude, tick Developer > Enable Main Process Debugger (menu at the top-left).`n`nOpen the panel with the palette button in Claude's top-left toolbar, or press Ctrl+Shift+Y.", $App) | Out-Null

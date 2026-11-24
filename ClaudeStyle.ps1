# ClaudeStyle - opens the Claude desktop app with your theme (mod.js + theme.css).
# Runs hidden. Windows PowerShell 5.1.
#   ClaudeStyle.ps1          clicked shortcut: open Claude (if needed), connect, exit when Claude quits
#   ClaudeStyle.ps1 -Watch   starts with Windows: waits in the background and connects whenever Claude opens
#   ClaudeStyle.ps1 -Off     turn ClaudeStyle off (removes it from Claude now, stops it starting with Windows)
#   ClaudeStyle.ps1 -On      turn it back on
#   ClaudeStyle.ps1 -Toggle  flips between on and off (kept for scripts; no shortcut uses it)
#
# Two ways in, tried in order:
#   A) start Claude with --remote-debugging-port and inject into its windows
#   B) Claude's own Developer menu > "Enable Main Process Debugger", then inject from inside the app

param([switch]$Watch, [switch]$Off, [switch]$On, [switch]$Toggle, [switch]$Quiet)
$ErrorActionPreference = 'SilentlyContinue'
$Port     = 9339   # route A (unusual port, so we never grab a browser's debugger)
$MainPort = 9229   # route B (Node inspector opened by Claude's Developer menu)
$Here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModFile  = Join-Path $Here 'mod.js'
$CssFile  = Join-Path $Here 'theme.css'
$MainFile = Join-Path $Here 'main-inject.js'
$LogFile  = Join-Path $Here 'log.txt'
$Title    = 'ClaudeStyle'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$script:Tray = New-Object Windows.Forms.NotifyIcon
$script:Tray.Icon = [Drawing.SystemIcons]::Information
$script:Tray.Text = 'ClaudeStyle'
function Notify([string]$text) {
  try { $script:Tray.Visible = $true; $script:Tray.Text = 'ClaudeStyle'; $script:Tray.ShowBalloonTip(5000, 'ClaudeStyle', $text, [Windows.Forms.ToolTipIcon]::Info) } catch {}
}
function Stop-Tray { try { $script:Tray.Visible = $false; $script:Tray.Dispose() } catch {} }

# Fast local HTTP: skips Windows proxy auto-detection (which made each check take seconds).
[Net.WebRequest]::DefaultWebProxy = $null
function Http-Json([string]$url, [int]$ms = 800) {
  try {
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Proxy = $null; $req.Timeout = $ms; $req.ReadWriteTimeout = $ms; $req.KeepAlive = $false
    $resp = $req.GetResponse()
    $sr = New-Object IO.StreamReader($resp.GetResponseStream())
    $txt = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
    return ,@(($txt | ConvertFrom-Json) | ForEach-Object { $_ })
  } catch { return $null }
}

function Log([string]$m) { Add-Content -Path $LogFile -Value ("{0:HH:mm:ss} {1}" -f (Get-Date), $m) -Encoding UTF8 }
function Show-Msg([string]$text) {
  # DefaultDesktopOnly = Windows' own always-on-top message box
  [void][Windows.Forms.MessageBox]::Show($text, $Title, [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information, [Windows.Forms.MessageBoxDefaultButton]::Button1,
        [Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly)
}

# ---------- find Claude ----------
function Find-Claude {
  $pkg = Get-AppxPackage -Name 'Claude' | Select-Object -First 1
  if (-not $pkg) { $pkg = Get-AppxPackage | Where-Object { $_.PackageFamilyName -like 'Claude_*' } | Select-Object -First 1 }
  if ($pkg) {
    $app = (Get-AppxPackageManifest $pkg).Package.Applications.Application | Where-Object { $_.Id -eq 'Claude' } | Select-Object -First 1
    if (-not $app) { $app = (Get-AppxPackageManifest $pkg).Package.Applications.Application | Select-Object -First 1 }
    return @{ Kind = 'store'; Root = $pkg.InstallLocation; Family = $pkg.PackageFamilyName
              Aumid = "$($pkg.PackageFamilyName)!$($app.Id)"; Exe = (Join-Path $pkg.InstallLocation $app.Executable) }
  }
  foreach ($r in @("$env:LOCALAPPDATA\AnthropicClaude", "$env:LOCALAPPDATA\Programs\Claude", "$env:ProgramFiles\Claude")) {
    if (-not (Test-Path $r)) { continue }
    $apps = @(Get-ChildItem $r -Directory -Filter 'app-*' | Where-Object { Test-Path (Join-Path $_.FullName 'claude.exe') })
    if ($apps.Count -gt 0) {
      $best = $apps | Sort-Object { try { [version]($_.Name.Substring(4)) } catch { [version]'0.0' } } -Descending | Select-Object -First 1
      return @{ Kind = 'classic'; Root = $r; Exe = (Join-Path $best.FullName 'claude.exe') }
    }
    if (Test-Path "$r\claude.exe") { return @{ Kind = 'classic'; Root = $r; Exe = "$r\claude.exe" } }
  }
  return $null
}

# Start a program the way a terminal does (CreateProcess), so arguments are passed through.
function Start-Direct([string]$file, [string]$argsText) {
  $psi = New-Object Diagnostics.ProcessStartInfo
  $psi.FileName = $file
  $psi.Arguments = $argsText
  $psi.UseShellExecute = $false
  [void][Diagnostics.Process]::Start($psi)
}

function Start-Claude($c, [string]$argsText) {
  if ($c.Kind -eq 'store') {
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\claude-desktop.exe'
    if (Test-Path $alias) {
      try { Start-Direct $alias $argsText; Log "Launched via app alias (direct)"; return } catch { Log "Alias direct launch failed: $_" }
    }
    try { Start-Process "shell:AppsFolder\$($c.Aumid)"; Log 'Launched via AppsFolder (no arguments possible)' } catch { Log "AppsFolder launch failed: $_" }
  } else {
    try { Start-Direct $c.Exe $argsText; Log 'Launched classic exe (direct)' } catch { Start-Process $c.Exe -ArgumentList $argsText }
  }
}

# Claude's own processes only (never Claude Code, which is also called claude.exe)
function Get-ClaudeProcs($c) {
  @(Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($c.Root, [StringComparison]::OrdinalIgnoreCase) })
}

function Get-MainCmdLines($c) {
  @(Get-CimInstance Win32_Process -Filter "Name like 'claude%'" |
    Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($c.Root, [StringComparison]::OrdinalIgnoreCase) -and $_.CommandLine -notmatch '--type=' } |
    ForEach-Object { "PID $($_.ProcessId): $($_.CommandLine)" })
}

# Find Claude's debugger ports in one quick pass. 'page' = window debugger, 'node' = main-process debugger.
$script:PortKinds = @{}   # port -> 'page' | 'node' | 'none' (cached; a port's kind doesn't change)
$script:PortHost  = @{}
function Scan-ClaudePorts {
  $ids = @(Get-ClaudeProcs $claude | ForEach-Object { $_.Id })
  if ($ids.Count -eq 0) { return }
  $listen = @(Get-NetTCPConnection -State Listen | Where-Object { $ids -contains $_.OwningProcess -and ($_.LocalAddress -eq '127.0.0.1' -or $_.LocalAddress -eq '::1' -or $_.LocalAddress -eq '0.0.0.0') })
  # likely debugger ports first
  $listen = @($listen | Sort-Object { if ($_.LocalPort -eq 9229 -or $_.LocalPort -eq $Port) { 0 } else { 1 } })
  foreach ($l in $listen) {
    $p = [int]$l.LocalPort
    if ($script:PortKinds.ContainsKey($p)) { continue }
    $h = $(if ($l.LocalAddress -eq '::1') { '[::1]' } else { '127.0.0.1' })
    $list = Http-Json "http://${h}:$p/json/list" 600
    $kind = 'none'
    if ($list) {
      if (@($list | Where-Object { $_.type -eq 'node' -and $_.webSocketDebuggerUrl }).Count) { $kind = 'node' }
      elseif (@($list | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count) { $kind = 'page' }
    }
    $script:PortKinds[$p] = $kind
    $script:PortHost[$p] = $h
    if ($kind -ne 'none') { Log "Debugger found: port $p ($kind)" }
  }
}
function Find-ClaudeDebugPort([string]$kind) {
  foreach ($k in @($script:PortKinds.Keys)) { if ($script:PortKinds[$k] -eq $kind) { $script:DebugHost = $script:PortHost[$k]; return $k } }
  return $null
}

function Log-ClaudePorts {
  $ids = @(Get-ClaudeProcs $claude | ForEach-Object { $_.Id })
  $ports = @(Get-NetTCPConnection -State Listen | Where-Object { $ids -contains $_.OwningProcess } | ForEach-Object { "$($_.LocalAddress):$($_.LocalPort)" })
  Log ("Claude listening ports: " + ($(if ($ports.Count) { $ports -join ', ' } else { 'none' })))
}

# Turn on Claude's Developer menu (documented developer_settings.json switch).
function Enable-DevMenu($c) {
  $dirs = @("$env:APPDATA\Claude")
  if ($c.Family) {
    $dirs += "$env:LOCALAPPDATA\Packages\$($c.Family)\LocalCache\Roaming\Claude"
    $dirs += "$env:LOCALAPPDATA\Claude-Data\$($c.Family.ToLower())"
  }
  foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { continue }
    $f = Join-Path $d 'developer_settings.json'
    $obj = $null
    if (Test-Path $f) { try { $obj = Get-Content $f -Raw | ConvertFrom-Json } catch {} }
    if (-not $obj) { $obj = New-Object psobject }
    if ($obj.allowDevTools -ne $true) {
      $obj | Add-Member -NotePropertyName allowDevTools -NotePropertyValue $true -Force
      [IO.File]::WriteAllText($f, ($obj | ConvertTo-Json -Compress))
      Log "Developer menu switched on in $f"
    }
  }
}

# ---------- start ----------
Set-Content -Path $LogFile -Value 'ClaudeStyle log' -Encoding UTF8
Log "Started (PID $PID)"

$claude = Find-Claude
if (-not $claude) { Log 'Claude not found'; Stop-Tray; Show-Msg "Couldn't find the Claude desktop app.`nIs it installed?"; exit 1 }
Log "Found Claude: kind=$($claude.Kind) root=$($claude.Root)"

function Find-Route {
  Scan-ClaudePorts
  $p = Find-ClaudeDebugPort 'page'
  if ($p) { $script:Port = $p; return 'A' }
  $p = Find-ClaudeDebugPort 'node'
  if ($p) { $script:MainPort = $p; return 'B' }
  return $null
}
function Get-Helpers {
  @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*ClaudeStyle.ps1*' })
}
# Helpers started by the shortcut click (not the background helper, not -On/-Off/-Toggle)
function Is-ClickHelper($p) { $p.CommandLine -notlike '*-Watch*' -and $p.CommandLine -notmatch '\s-(Toggle|On|Off)(\s|"|$)' }
function Reset-PortCache { $script:PortKinds = @{}; $script:PortHost = @{} }

# ---------- DevTools connection helpers ----------
Add-Type -AssemblyName System.Web
$None_ = [Threading.CancellationToken]::None
$script:msgId = 0
function JsStr([string]$s) { [Web.HttpUtility]::JavaScriptStringEncode($s, $true) }   # fast, no size limit

# $paramsJson is a ready-made JSON object string (built by hand so big payloads stay fast)
function Send-Cdp($c, [string]$method, [string]$paramsJson) {
  $script:msgId++
  $json = '{"id":' + $script:msgId + ',"method":"' + $method + '","params":' + $paramsJson + '}'
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $seg = New-Object 'ArraySegment[byte]' -ArgumentList (, $bytes)
  [void]$c.Ws.SendAsync($seg, [Net.WebSockets.WebSocketMessageType]::Text, $true, $None_).Wait(15000)
}
function Send-Eval($c, [string]$expr, [bool]$cmdApi) {
  $p = '{"expression":' + (JsStr $expr) + $(if ($cmdApi) { ',"includeCommandLineAPI":true' } else { '' }) + '}'
  Send-Cdp $c 'Runtime.evaluate' $p
}
function Start-Recv($c) {  # keep reading replies so the connection never backs up
  $seg = New-Object 'ArraySegment[byte]' -ArgumentList (, $c.Buf)
  $c.Recv = $c.Ws.ReceiveAsync($seg, $None_)
}
function Open-Ws([string]$url) {
  $ws = New-Object Net.WebSockets.ClientWebSocket
  if (-not $ws.ConnectAsync([Uri]$url, $None_).Wait(5000)) { $ws.Dispose(); return $null }
  $c = [pscustomobject]@{ Ws = $ws; Buf = (New-Object byte[] 65536); Recv = $null }
  Start-Recv $c
  return $c
}
function Drain($c) {
  while ($c.Recv -and $c.Recv.IsCompleted -and -not $c.Recv.IsFaulted -and $c.Ws.State -eq 'Open') { Start-Recv $c }
}
function Read-Css { if (Test-Path $CssFile) { return [IO.File]::ReadAllText($CssFile) } else { return '' } }
function Get-Stamp { "$((Get-Item $ModFile).LastWriteTimeUtc.Ticks)|$((Get-Item $CssFile -ErrorAction SilentlyContinue).LastWriteTimeUtc.Ticks)" }
function Get-PageExpr {
  return [IO.File]::ReadAllText($ModFile) + "`n;window.__claudeMod && window.__claudeMod.setFileCss(" + (JsStr (Read-Css)) + ");"
}
function Get-MainExpr {
  $startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'ClaudeStyle (background).lnk'
  return [IO.File]::ReadAllText($MainFile).Replace('__MOD__', (JsStr ([IO.File]::ReadAllText($ModFile)))).Replace('__CSS__', (JsStr (Read-Css))).Replace('__DIR__', (JsStr $Here)).Replace('__STARTUP__', (JsStr $startup))
}
function Get-Targets([int]$p) {
  $h = $(if ($script:DebugHost) { $script:DebugHost } else { '127.0.0.1' })
  $r = Http-Json "http://${h}:$p/json/list" 1500
  if ($r) { return $r } else { return @() }
}
$OnMsg = 'ClaudeStyle is on - click the palette button in Claude (or Ctrl+Shift+Y).'
$script:SaidOn = $false          # the "ClaudeStyle is on" note shows once per Claude session
function Say-On { if (-not $script:SaidOn) { $script:SaidOn = $true; Notify $OnMsg } }

# ---------- route A: theme each window through the remote-debugging port ----------
function Run-RouteA {
  $conns = @{}; $listed = $false; $gone = 0; $stamp = ''
  while ($true) {
    if (Test-Path (Join-Path $Here 'off.flag')) { Log 'Turned off from the ClaudeStyle panel'; break }
    if (@($conns.Values | Where-Object { $_.Ws.State -eq 'Open' }).Count -gt 0) { $gone = 0 }
    elseif ((Get-ClaudeProcs $claude).Count -eq 0) { $gone++ } else { $gone = 0 }
    if ($gone -ge 2) { break }
    $targets = Get-Targets $Port
    if ($targets.Count -gt 0 -and -not $listed) { $listed = $true; foreach ($x in $targets) { Log "Window seen: type=$($x.type) url=$($x.url)" } }
    $views = @($targets | Where-Object { ($_.type -eq 'page' -or $_.type -eq 'webview') -and $_.url -notlike 'devtools://*' })
    $chat  = @($views | Where-Object { $_.url -match 'claude\.ai' })
    if ($chat.Count -gt 0) { $views = $chat }
    $now = Get-Stamp
    $changed = $now -ne $stamp; $stamp = $now
    foreach ($t in $views) {
      if ($t.webSocketDebuggerUrl -and -not $conns.ContainsKey($t.id)) {
        $c = Open-Ws $t.webSocketDebuggerUrl
        if ($c) {
          Send-Cdp $c 'Page.addScriptToEvaluateOnNewDocument' ('{"source":' + (JsStr ([IO.File]::ReadAllText($ModFile))) + '}')
          Send-Cdp $c 'Page.setBypassCSP' '{"enabled":true}'
          Send-Eval $c (Get-PageExpr) $false
          $conns[$t.id] = $c; Log "Themed window: $($t.url)"; Say-On
        } else { Log "Could not connect to window: $($t.url)" }
      }
    }
    foreach ($id in @($conns.Keys)) {
      $c = $conns[$id]; Drain $c
      if ($c.Ws.State -ne 'Open') { $c.Ws.Dispose(); $conns.Remove($id); continue }
      # Re-apply theme.css when it changes, and quietly re-check the page every few seconds.
      if ($changed) { Send-Eval $c (Get-PageExpr) $false }
      else { Send-Eval $c ('window.__claudeMod && window.__claudeMod.setFileCss(' + (JsStr (Read-Css)) + ')') $false }
    }
    Start-Sleep -Milliseconds 1500
  }
  foreach ($c in $conns.Values) { $c.Ws.Dispose() }
}

# ---------- route B: inject from inside Claude's main process ----------
$script:Connects = 0
function Run-RouteB {
  $c = $null; $stamp = $null; $gone = 0
  while ($true) {
    if (Test-Path (Join-Path $Here 'off.flag')) { Log 'Turned off from the ClaudeStyle panel'; break }
    if ($c -and $c.Ws.State -eq 'Open') { $gone = 0 }
    elseif ((Get-ClaudeProcs $claude).Count -eq 0) { $gone++ } else { $gone = 0 }
    if ($gone -ge 2) { break }
    if (-not $c -or $c.Ws.State -ne 'Open') {
      if ($c) { Log "Connection ended (state $($c.Ws.State), close: $($c.Ws.CloseStatus) $($c.Ws.CloseStatusDescription))"; $c.Ws.Dispose(); $c = $null }
      $t = Get-Targets $MainPort | Where-Object { $_.webSocketDebuggerUrl } | Select-Object -First 1
      if ($t) {
        $c = Open-Ws $t.webSocketDebuggerUrl
        if ($c) { $script:Connects++; Log "Connected to Claude main process (connection #$($script:Connects))"; $stamp = $null; Say-On }
      }
    }
    if ($c -and $c.Ws.State -eq 'Open') {
      Drain $c
      $now = Get-Stamp
      if ($now -ne $stamp) {
        Send-Eval $c (Get-MainExpr) $true
        $stamp = $now; Log 'Pushed ClaudeStyle into Claude'
      }
    }
    Start-Sleep -Milliseconds 2000
  }
  if ($c) { $c.Ws.Dispose() }
}

# ---------- on / off ----------
$OffFlag     = Join-Path $Here 'off.flag'
$StartupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'ClaudeStyle (background).lnk'
$PSExe       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
function Start-Watcher { Start-Process $PSExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Here\ClaudeStyle.ps1`" -Watch" -WindowStyle Hidden }
function Set-StartWithWindows([bool]$enable) {
  if (-not $enable) { Remove-Item $StartupLink -ErrorAction SilentlyContinue; return }
  $sh = New-Object -ComObject WScript.Shell
  $l = $sh.CreateShortcut($StartupLink)
  $l.TargetPath = $PSExe
  $l.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Here\ClaudeStyle.ps1`" -Watch"
  $l.WorkingDirectory = $Here; $l.WindowStyle = 7; $l.Description = 'ClaudeStyle background helper'
  if ($claude.Exe -and (Test-Path $claude.Exe)) { $l.IconLocation = "$($claude.Exe),0" }
  $l.Save()
}
function Turn-On {
  Remove-Item $OffFlag -ErrorAction SilentlyContinue
  Set-StartWithWindows $true
  if (@(Get-Helpers | Where-Object { $_.CommandLine -like '*-Watch*' }).Count -eq 0) { Start-Watcher; Start-Sleep -Milliseconds 1200 }
  Wake-InApp
  Log 'Turned on'
}
# If ClaudeStyle was switched off from inside Claude's panel, switch it back on there too.
function Wake-InApp {
  if ((Get-ClaudeProcs $claude).Count -gt 0 -and (Find-Route) -eq 'B') {
    $t = Get-Targets $MainPort | Where-Object { $_.webSocketDebuggerUrl } | Select-Object -First 1
    $c = $(if ($t) { Open-Ws $t.webSocketDebuggerUrl })
    if ($c) {
      $page = "try { localStorage.removeItem('claudeStyleDisabled'); } catch (e) {} if (window.__claudeMod && window.__claudeMod.dormant) window.__claudeMod.wake();"
      $expr = "(() => { const req = typeof require === 'function' ? require : process.mainModule.require.bind(process.mainModule);" +
              " req('electron').webContents.getAllWebContents().forEach(w => { try { if (/claude\.ai/.test(w.getURL())) w.executeJavaScript(" + (JsStr $page) + ", true).catch(() => {}); } catch (e) {} });" +
              " return 'on'; })()"
      Send-Eval $c $expr $true; Start-Sleep -Milliseconds 400; $c.Ws.Dispose()
      Log 'Woke ClaudeStyle inside Claude (if it was off)'
    }
  }
}
function Turn-Off {
  Log 'Turning off'
  Get-Helpers | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
  Set-StartWithWindows $false
  Set-Content -Path $OffFlag -Value 'ClaudeStyle is turned off. Open the ClaudeStyle shortcut to turn it back on.'
  if ((Get-ClaudeProcs $claude).Count -eq 0) { return }
  $route = Find-Route
  if ($route -eq 'B') {
    $t = Get-Targets $MainPort | Where-Object { $_.webSocketDebuggerUrl } | Select-Object -First 1
    $c = $(if ($t) { Open-Ws $t.webSocketDebuggerUrl })
    if ($c) {
      $expr = "(() => { const req = typeof require === 'function' ? require : process.mainModule.require.bind(process.mainModule);" +
              " const { webContents } = req('electron'); const st = globalThis.__claudeStyle; if (st) st.off = true;" +
              " webContents.getAllWebContents().forEach(w => { try { w.executeJavaScript('window.__claudeMod && window.__claudeMod.remove(); window.__csShell && window.__csShell.remove();', true).catch(() => {}); } catch (e) {} });" +
              " return 'off'; })()"
      Send-Eval $c $expr $true; Start-Sleep -Milliseconds 500; $c.Ws.Dispose()
      Log 'Removed ClaudeStyle from the open Claude windows'
    }
  } elseif ($route -eq 'A') {
    foreach ($t in @(Get-Targets $Port | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl })) {
      $c = Open-Ws $t.webSocketDebuggerUrl
      if ($c) { Send-Eval $c 'window.__claudeMod && window.__claudeMod.remove()' $false; Start-Sleep -Milliseconds 200; $c.Ws.Dispose() }
    }
  }
}

# ======================================================================== main
$askText = ("One more click:`n`n" +
            "In Claude, open the menu (top-left), then Developer > Enable Main Process Debugger.`n" +
            "If it already has a tick, click it twice (off, then on again).")

if ($Toggle) { if (Test-Path $OffFlag) { $On = $true } else { $Off = $true } }
if ($Off) {
  Turn-Off; Stop-Tray
  Show-Msg "ClaudeStyle is off.`n`nClaude is back to its normal look, and ClaudeStyle won't start with Windows.`nYour themes and settings are kept.`n`nTo turn it back on, open the ClaudeStyle shortcut."
  exit 0
}
if ($On) {
  Turn-On; Stop-Tray
  if ($Quiet) { exit 0 }
  Show-Msg "ClaudeStyle is ON.`n`nIt connects by itself whenever Claude is open, and starts with Windows again.`n(Keep Developer > Enable Main Process Debugger ticked in Claude.)"
  exit 0
}

if ($Watch) {
  # ---- background mode: one watcher only; connects every time Claude opens ----
  if (Test-Path $OffFlag) { exit 0 }
  if (@(Get-Helpers | Where-Object { $_.CommandLine -like '*-Watch*' }).Count -gt 0) { exit 0 }
  Log 'Watcher started'
  Enable-DevMenu $claude
  $seen = $null; $told = $false
  while ($true) {
    if ((Get-ClaudeProcs $claude).Count -eq 0) { Reset-PortCache; $seen = $null; $told = $false; $script:SaidOn = $false; Start-Sleep -Seconds 3; continue }
    if (-not $seen) { $seen = Get-Date; Log 'Watcher: Claude opened' }
    # a shortcut-started helper is already looking after this Claude session
    if (@(Get-Helpers | Where-Object { Is-ClickHelper $_ }).Count -gt 0) { Start-Sleep -Seconds 3; continue }
    $route = Find-Route
    if ($route) {
      Log "Watcher: connected (route $route)"
      if ($route -eq 'A') { Run-RouteA } else { Run-RouteB }
      if (Test-Path $OffFlag) { Log 'Watcher: ClaudeStyle was turned off; stopping'; Stop-Tray; exit 0 }
      Log 'Watcher: Claude closed'; Reset-PortCache; $seen = $null; $told = $false
      continue
    }
    if (-not $told -and ((Get-Date) - $seen).TotalSeconds -gt 12) {
      Notify 'To use ClaudeStyle: in Claude open Developer > Enable Main Process Debugger.'
      Log 'Watcher: debugger not on; reminded user'; $told = $true
    }
    Start-Sleep -Seconds 2
  }
}

# ---- clicked shortcut ----
if (Test-Path $OffFlag) { Turn-On; Notify 'ClaudeStyle turned back on.' }
$helpers = Get-Helpers
$watcher = @($helpers | Where-Object { $_.CommandLine -like '*-Watch*' })
$clicks  = @($helpers | Where-Object { Is-ClickHelper $_ })
# if two clicks start at once (double-click) the newer one wins; older click-helpers are stopped
$me = Get-CimInstance Win32_Process -Filter "ProcessId = $PID"
if ($me -and @($clicks | Where-Object { $_.CreationDate -gt $me.CreationDate }).Count -gt 0) { exit 0 }
if ($clicks.Count -gt 0) { Log "Stopping $($clicks.Count) older helper(s)"; $clicks | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; Start-Sleep -Milliseconds 400 }

Enable-DevMenu $claude
if ($watcher.Count -gt 0) {
  # The background helper does the connecting; the shortcut just opens Claude and helps if needed.
  if ((Get-ClaudeProcs $claude).Count -eq 0) { Log 'Opening Claude (background helper will connect)'; Start-Claude $claude ''; Notify 'Opening Claude...' }
  for ($i = 0; $i -lt 20 -and -not (Find-Route); $i++) { Start-Sleep -Milliseconds 500 }
  if (Find-Route) { Start-Sleep -Seconds 2; Wake-InApp } else { Log 'Debugger not on; showing how'; Show-Msg $askText }
  Stop-Tray; exit 0
}
if ((Get-ClaudeProcs $claude).Count -eq 0) {
  Log 'Claude not running; starting it'
  Notify 'Opening Claude...'
  Start-Claude $claude "--remote-debugging-port=$Port"
  for ($i = 0; $i -lt 30 -and (Get-ClaudeProcs $claude).Count -eq 0; $i++) { Start-Sleep -Milliseconds 500 }
  for ($i = 0; $i -lt 16 -and -not (Find-Route); $i++) { Start-Sleep -Milliseconds 500 }
} else {
  Notify 'Connecting to Claude...'
}
Get-MainCmdLines $claude | ForEach-Object { Log "Main process: $_" }
Log-ClaudePorts
$route = Find-Route

if (-not $route) {
  Log 'No debugger found yet; asking user to switch on the main process debugger'
  Show-Msg ($askText + "`n`nClick OK here first - ClaudeStyle then waits up to 3 minutes.")
  for ($i = 0; $i -lt 250 -and -not $route; $i++) {
    if ((Get-ClaudeProcs $claude).Count -eq 0) { Log 'Claude was closed while waiting'; Stop-Tray; exit 0 }
    $route = Find-Route
    if (-not $route) { Start-Sleep -Milliseconds 700 }
  }
}
if (-not $route) {
  Log-ClaudePorts; Log 'No debugger found'; Stop-Tray
  Show-Msg ("ClaudeStyle couldn't connect to Claude.`n`nMake sure Developer > Enable Main Process Debugger is ticked in Claude, then try again.`n(Details: %LOCALAPPDATA%\ClaudeStyle\log.txt)")
  exit 1
}
Log "Connected using route $route (window port $Port, main port $MainPort, host $script:DebugHost)"
if ($route -eq 'B') { Wake-InApp }
if ($route -eq 'A') { Run-RouteA } else { Run-RouteB }
Stop-Tray
Log 'Claude closed; helper exiting'


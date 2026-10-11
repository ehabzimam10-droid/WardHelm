param(
  [int]$AgentPid = 0,
  [string]$IconPath = ""
)

$ErrorActionPreference = "Stop"
$logPath = Join-Path $env:LOCALAPPDATA "WardHelm\tray.log"

try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $notify = New-Object System.Windows.Forms.NotifyIcon
  $notify.Text = "WardHelm Guardian"

  if ($IconPath -and (Test-Path $IconPath)) {
    try {
      $notify.Icon = New-Object System.Drawing.Icon($IconPath)
    } catch {
      $notify.Icon = [System.Drawing.SystemIcons]::Shield
    }
  } else {
    $notify.Icon = [System.Drawing.SystemIcons]::Shield
  }

  $contextMenu = New-Object System.Windows.Forms.ContextMenu

  $openItem = New-Object System.Windows.Forms.MenuItem("Show Dashboard / فتح لوحة التحكم")
  $openItem.add_Click({
    try {
      $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
      if (-not (Test-Path $edge)) { $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }
      if (Test-Path $edge) {
        Start-Process $edge -ArgumentList "--app=http://127.0.0.1:48123 --window-size=480,720 --app-id=wardhelm_agent_ui"
      } else {
        Start-Process "http://127.0.0.1:48123"
      }
    } catch {}
  })

  $updateItem = New-Object System.Windows.Forms.MenuItem("Check for Updates / فحص التحديثات")
  $updateItem.add_Click({
    try {
      Invoke-RestMethod -Uri "http://127.0.0.1:48123/check_update" -Method Post -TimeoutSec 3 | Out-Null
      $notify.ShowBalloonTip(3000, "WardHelm", "Checking updates / جاري فحص التحديثات...", [System.Windows.Forms.ToolTipIcon]::Info)
    } catch {}
  })

  $statusItem = New-Object System.Windows.Forms.MenuItem("Active / الحماية تعمل بنشاط")
  $statusItem.Enabled = $false

  $separator = New-Object System.Windows.Forms.MenuItem("-")

  $exitItem = New-Object System.Windows.Forms.MenuItem("Exit WardHelm / إغلاق الحارس")
  $exitItem.add_Click({
    try {
      Invoke-RestMethod -Uri "http://127.0.0.1:48123/exit" -Method Post -TimeoutSec 3 | Out-Null
    } catch {}
    $notify.Visible = $false
    $notify.Dispose()
    [System.Windows.Forms.Application]::Exit()
  })

  $contextMenu.MenuItems.Add($openItem) | Out-Null
  $contextMenu.MenuItems.Add($updateItem) | Out-Null
  $contextMenu.MenuItems.Add($statusItem) | Out-Null
  $contextMenu.MenuItems.Add($separator) | Out-Null
  $contextMenu.MenuItems.Add($exitItem) | Out-Null

  $notify.ContextMenu = $contextMenu

  $notify.add_DoubleClick({
    $openItem.PerformClick()
  })
  $notify.add_Click({
    if ([System.Windows.Forms.Control]::MouseButtons -eq [System.Windows.Forms.MouseButtons]::Left) {
      $openItem.PerformClick()
    }
  })

  $notify.Visible = $true
  $notify.ShowBalloonTip(3000, "WardHelm Guardian", "الحماية نشطة في علبة النظام بجوار الساعة", [System.Windows.Forms.ToolTipIcon]::Info)

  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 3000
  $timer.add_Tick({
    if ($AgentPid -gt 0) {
      $p = Get-Process -Id $AgentPid -ErrorAction SilentlyContinue
      if (-not $p) {
        $notify.Visible = $false
        $notify.Dispose()
        [System.Windows.Forms.Application]::Exit()
      }
    }
  })
  $timer.Start()

  [System.Windows.Forms.Application]::Run()
} catch {
  $_ | Out-File -FilePath $logPath -Append
}

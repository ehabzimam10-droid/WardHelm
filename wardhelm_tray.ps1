# WardHelm Native Windows System Tray (Notification Area) Manager
param(
  [int]$AgentPid = 0,
  [string]$IconPath = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Text = "WardHelm - حارس الحاسوب الذكي (v1.0.2)"

# Load Icon
if ($IconPath -and (Test-Path $IconPath)) {
  try {
    $notify.Icon = New-Object System.Drawing.Icon($IconPath)
  } catch {
    $notify.Icon = [System.Drawing.SystemIcons]::Shield
  }
} else {
  $notify.Icon = [System.Drawing.SystemIcons]::Shield
}

# Context Menu
$contextMenu = New-Object System.Windows.Forms.ContextMenu

$openItem = New-Object System.Windows.Forms.MenuItem("🛡️ فتح لوحة التحكم")
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

$updateItem = New-Object System.Windows.Forms.MenuItem("🔄 فحص التحديثات الآن")
$updateItem.add_Click({
  try {
    Invoke-RestMethod -Uri "http://127.0.0.1:48123/check_update" -Method Post -TimeoutSec 3 | Out-Null
    $notify.ShowBalloonTip(3000, "WardHelm", "جارٍ فحص التحديثات السحابية...", [System.Windows.Forms.ToolTipIcon]::Info)
  } catch {}
})

$statusItem = New-Object System.Windows.Forms.MenuItem("🟢 الحماية نشطة في الخلفية")
$statusItem.Enabled = $false

$separator = New-Object System.Windows.Forms.MenuItem("-")

$exitItem = New-Object System.Windows.Forms.MenuItem("❌ إغلاق الحارس تماماً")
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

# Click and Double Click to Open GUI
$notify.add_DoubleClick({
  $openItem.PerformClick()
})
$notify.add_Click({
  # Open on left click
  if ([System.Windows.Forms.Control]::MouseButtons -eq [System.Windows.Forms.MouseButtons]::Left) {
    $openItem.PerformClick()
  }
})

$notify.Visible = $true
$notify.ShowBalloonTip(3000, "WardHelm - حارس الحاسوب", "البرنامج يعمل الآن في الخلفية لحماية هذا الجهاز.", [System.Windows.Forms.ToolTipIcon]::Info)

# Timer to ensure Tray exits when Agent process exits
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2500
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

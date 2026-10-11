import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:wardhelm/core/constants/app_constants.dart';
import 'package:wardhelm/core/utils/system_info_helper.dart';
import 'package:wardhelm/core/utils/totp_helper.dart';
import 'package:wardhelm/data/models/pairing_code_model.dart';
import 'package:wardhelm/services/device_service.dart';
import 'package:wardhelm/services/session_service.dart';
import 'package:wardhelm/services/windows/process_watchdog_service.dart';
import 'package:wardhelm/services/windows/hosts_firewall_service.dart';
import 'package:wardhelm/services/windows/registry_kiosk_service.dart';
import 'package:wardhelm/services/windows/agent_updater.dart';
import 'package:wardhelm/services/windows/agent_gui_server.dart';

typedef _GetConsoleWindowNative = IntPtr Function();
typedef _GetConsoleWindowDart = int Function();
typedef _ShowWindowNative = Int32 Function(IntPtr hwnd, Int32 nCmdShow);
typedef _ShowWindowDart = int Function(int hwnd, int nCmdShow);

/// Hide console window via Windows Win32 API
void _hideConsoleWindow() {
  if (!Platform.isWindows) return;
  try {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final user32 = DynamicLibrary.open('user32.dll');

    final getConsoleWindow = kernel32
        .lookupFunction<_GetConsoleWindowNative, _GetConsoleWindowDart>('GetConsoleWindow');
    final showWindow = user32
        .lookupFunction<_ShowWindowNative, _ShowWindowDart>('ShowWindow');

    final hwnd = getConsoleWindow();
    if (hwnd != 0) {
      showWindow(hwnd, 0); // SW_HIDE = 0
    }
  } catch (_) {}
}

/// Embedded PowerShell script content for the native System Tray (Notification Area)
const String _embeddedTrayScript = r'''
param(
  [int]$AgentPid = 0,
  [string]$IconPath = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Text = "WardHelm - حارس الحاسوب الذكي (v1.0.3)"

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
''';

/// Ensures Start Menu, Desktop shortcuts, and Auto-Startup registry are configured automatically on ANY machine
Future<void> _ensureSelfInstalled() async {
  if (!Platform.isWindows) return;
  try {
    final exePath = Platform.resolvedExecutable;
    await Process.run('powershell.exe', [
      '-NoProfile',
      '-Command',
      '''
      \$WshShell = New-Object -ComObject WScript.Shell
      \$appData = [Environment]::GetFolderPath('ApplicationData')
      \$startMenu = "\$appData\\Microsoft\\Windows\\Start Menu\\Programs\\WardHelm.lnk"
      \$desktop = [Environment]::GetFolderPath('Desktop') + "\\WardHelm.lnk"

      if (-not (Test-Path \$startMenu)) {
        try {
          \$s1 = \$WshShell.CreateShortcut(\$startMenu)
          \$s1.TargetPath = "$exePath"
          \$s1.Description = "WardHelm Autonomous Cloud Guardian"
          \$s1.Save()
        } catch {}
      }

      if (-not (Test-Path \$desktop)) {
        try {
          \$s2 = \$WshShell.CreateShortcut(\$desktop)
          \$s2.TargetPath = "$exePath"
          \$s2.Description = "WardHelm Autonomous Cloud Guardian"
          \$s2.Save()
        } catch {}
      }

      Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" -Name "WardHelm" -Value '"$exePath"' -ErrorAction SilentlyContinue
      '''
    ]);
  } catch (_) {}
}

/// Spawns native Windows System Tray helper in background, extracting script if missing
void _startSystemTrayIcon() {
  if (!Platform.isWindows) return;
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    var trayScript = '$exeDir\\wardhelm_tray.ps1';
    var iconPath = '$exeDir\\assets\\app_icon.ico';

    if (!File(trayScript).existsSync()) {
      final fallbackDir = Directory.systemTemp.path;
      trayScript = '$fallbackDir\\wardhelm_tray.ps1';
      File(trayScript).writeAsStringSync(_embeddedTrayScript);
    }

    if (!File(iconPath).existsSync()) {
      iconPath = '';
    }

    Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        trayScript,
        '-AgentPid',
        pid.toString(),
        if (iconPath.isNotEmpty) ...['-IconPath', iconPath],
      ],
      mode: ProcessStartMode.detached,
    );
  } catch (_) {}
}

/// Discovers installed software and running user applications on this PC
Future<List<String>> _scanInstalledApplications() async {
  if (!Platform.isWindows) return [];
  final Set<String> apps = {};

  try {
    // 1. Scan running GUI processes
    final tasklist = await Process.run('tasklist', ['/fo', 'csv', '/nh'], runInShell: true);
    if (tasklist.exitCode == 0) {
      final lines = (tasklist.stdout as String).split('\r\n');
      for (final line in lines) {
        final match = RegExp(r'^"([^"]+)"').firstMatch(line.trim());
        if (match != null) {
          final exe = match.group(1)!.trim();
          final lower = exe.toLowerCase();
          if (!AppConstants.protectedSystemProcesses.contains(lower) && lower.endsWith('.exe')) {
            apps.add(exe);
          }
        }
      }
    }

    // 2. Scan Registry for installed user programs
    final regQuery = await Process.run('powershell.exe', [
      '-NoProfile',
      '-Command',
      r'''
      Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                       HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                       HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } |
        Select-Object -ExpandProperty DisplayName |
        Sort-Object -Unique
      '''
    ]);
    if (regQuery.exitCode == 0) {
      final names = (regQuery.stdout as String).split(RegExp(r'\r?\n'));
      for (final name in names) {
        final clean = name.trim();
        if (clean.length > 2 && clean.length < 50 && !clean.startsWith('{')) {
          apps.add(clean);
        }
      }
    }
  } catch (_) {}

  return apps.take(80).toList();
}

/// Standalone Native Windows Agent Executable for WardHelm with Graphical UI Window
void main(List<String> args) async {
  // 1. Instantly hide any allocated console window
  _hideConsoleWindow();

  // 2. Single-instance check: If already running, activate GUI and exit gracefully
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 600);
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:48123/status'));
    final res = await req.close();
    if (res.statusCode == 200) {
      try {
        final openReq = await client.postUrl(Uri.parse('http://127.0.0.1:48123/open_gui'));
        await openReq.close();
      } catch (_) {}
      AgentGuiServer().launchWindow();
      exit(0);
    }
  } catch (_) {}

  // 3. Autonomous self-installation of shortcuts and registry run key
  _ensureSelfInstalled();

  stdout.writeln('====================================================');
  stdout.writeln('  🛡️  WardHelm Autonomous Windows Security Agent    ');
  stdout.writeln('  Version: v${AppConstants.appVersion}            ');
  stdout.writeln('====================================================');

  final deviceService = DeviceService();
  final sessionService = SessionService();
  final watchdog = ProcessWatchdogService();
  final hostsFirewall = HostsFirewallService();
  final registry = RegistryKioskService();

  final deviceId = SystemInfoHelper.generateUniqueDeviceId();
  final deviceName = SystemInfoHelper.defaultDeviceName;

  stdout.writeln('[INFO] Device ID: $deviceId');
  stdout.writeln('[INFO] Hostname: $deviceName');

  bool isPaired = false;
  String currentCode = '';
  bool isUpdating = false;

  // Initialize and start embedded graphical desktop GUI window
  final guiServer = AgentGuiServer();
  guiServer.deviceName = deviceName;
  guiServer.deviceId = deviceId;
  await guiServer.start();
  guiServer.launchWindow();

  // Start background System Tray (Notification Area) Icon
  _startSystemTrayIcon();

  guiServer.onExitRequested = () async {
    stdout.writeln('[SHUTDOWN] Exit requested from System Tray. Restoring policies...');
    watchdog.stopWatchdog();
    await hostsFirewall.removeDomainBlocks();
    await hostsFirewall.restoreInternet();
    await registry.enableTaskManager();
    exit(0);
  };

  /// Routine to check and apply auto-updates
  Future<void> checkAndUpdateAgent({bool silent = false}) async {
    if (isUpdating) return;
    try {
      if (!silent) stdout.writeln('\n[UPDATER] Checking for software updates...');
      final info = await AgentUpdater.checkForUpdates();
      if (info.hasUpdate) {
        stdout.writeln('[UPDATER] Found new update: v${info.latestVersion} (Current: v${info.currentVersion})');
        stdout.writeln('[UPDATER] Notes: ${info.releaseNotes}');
        isUpdating = true;
        // Clean up security rules before upgrading
        watchdog.stopWatchdog();
        await hostsFirewall.removeDomainBlocks();
        await hostsFirewall.restoreInternet();
        await registry.enableTaskManager();

        final applied = await AgentUpdater.downloadAndApplyUpdate(info);
        if (!applied) {
          isUpdating = false;
        }
      } else {
        if (!silent) stdout.writeln('[UPDATER] You are on the latest version (v${info.currentVersion}).');
      }
    } catch (e) {
      if (!silent) stderr.writeln('[UPDATER] Check error: $e');
    }
  }

  guiServer.onCheckUpdateRequested = () => checkAndUpdateAgent(silent: false);

  // Initial update check at launch
  checkAndUpdateAgent(silent: false);

  // Periodic automatic update check every 30 minutes
  Timer.periodic(const Duration(minutes: 30), (_) => checkAndUpdateAgent(silent: true));

  // Check pairing status
  final initialDevice = await deviceService.getDevice(deviceId);
  if (initialDevice != null) {
    isPaired = true;
    guiServer.isPaired = true;
    stdout.writeln('[STATUS] Device is already paired as "${initialDevice.name}".');
  }

  // Scan installed apps and publish to cloud
  _scanInstalledApplications().then((apps) async {
    final dev = await deviceService.getDevice(deviceId);
    if (dev != null) {
      await deviceService.updateDeviceInstalledApps(deviceId, dev, apps);
    }
  });

  // Re-scan apps every 10 minutes
  Timer.periodic(const Duration(minutes: 10), (_) async {
    final apps = await _scanInstalledApplications();
    final dev = await deviceService.getDevice(deviceId);
    if (dev != null) {
      await deviceService.updateDeviceInstalledApps(deviceId, dev, apps);
    }
  });

  int lastInterval = -1;

  // TOTP 60-second loop
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final remaining = TotpHelper.secondsRemaining();
    guiServer.remainingSeconds = remaining;

    if (isPaired) {
      guiServer.isPaired = true;
      return;
    }

    final currentInterval = TotpHelper.currentInterval();

    if (currentCode.isEmpty || currentInterval != lastInterval) {
      lastInterval = currentInterval;
      currentCode = TotpHelper.generatePairingCode(deviceId);
      guiServer.currentCode = currentCode;
      stdout.writeln('\n[PAIRING] New 60s Dynamic Code Generated: >>> $currentCode <<<');
      stdout.writeln('[PAIRING] Enter this code on your mobile dashboard to claim this PC.');

      await deviceService.publishPairingCode(
        PairingCodeModel(
          code: currentCode,
          deviceId: deviceId,
          deviceName: deviceName,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(seconds: remaining)),
        ),
      );
    }
  });

  // Main 5-second agent sync loop
  Timer.periodic(const Duration(seconds: 5), (_) async {
    if (isUpdating) return;

    try {
      // 1. Consolidated fetch
      final dev = await deviceService.getDevice(deviceId);
      if (dev != null) {
        if (!isPaired) {
          isPaired = true;
          guiServer.isPaired = true;
          stdout.writeln('\n[SUCCESS] Device claimed! Now active in fleet.');
        }

        guiServer.isPaired = true;
        guiServer.mode = dev.mode;
        guiServer.isControlled = dev.isControlledMode;

        // Heartbeat with version stamp
        await deviceService.sendHeartbeatDirect(
          deviceId,
          dev,
          currentVersion: AppConstants.appVersion,
        );
      } else {
        // Device record is null in Firestore!
        // If it was paired, it has been unpaired/wiped from the cloud!
        if (isPaired) {
          stdout.writeln('\n[UNPAIRED] Device record removed from cloud. Resetting to initial pairing mode for complete privacy.');
          isPaired = false;
          guiServer.isPaired = false;
          guiServer.mode = 'pairing';
          guiServer.isControlled = false;
          if (watchdog.isRunning) {
            watchdog.stopWatchdog();
            await hostsFirewall.removeDomainBlocks();
            await hostsFirewall.restoreInternet();
            await registry.enableTaskManager();
          }
          currentCode = '';
          lastInterval = -1;
        }
      }

      if (dev != null) {

        // Check for remote commands from dashboard (e.g. check_update)
        if (dev.metadata['pendingCommand'] == 'check_update') {
          stdout.writeln('\n[COMMAND] Remote update command received from dashboard!');
          await deviceService.clearPendingCommand(deviceId, dev);
          await checkAndUpdateAgent(silent: false);
          return;
        }

        // 2. Controlled Session enforcement (supporting Whitelist & Blacklist)
        if (dev.isControlledMode && dev.activeSessionId != null) {
          final session = await sessionService.getSession(dev.activeSessionId!);
          if (session != null && session.isActive) {
            guiServer.sessionMinutesLeft = session.remainingMinutes;
            guiServer.isPrayerPause = session.isPrayerPause;
            guiServer.isInternetBlocked = session.isInternetBlocked;

            // Check expiry
            if (session.isExpired) {
              stdout.writeln('\n[SESSION] Controlled session expired. Ending session and reverting to Owner Mode.');
              await sessionService.endSession(session.id);
              if (watchdog.isRunning) {
                watchdog.stopWatchdog();
                await hostsFirewall.removeDomainBlocks();
                await hostsFirewall.restoreInternet();
                await registry.enableTaskManager();
              }
              guiServer.isControlled = false;
              return;
            }

            if (!watchdog.isRunning) {
              stdout.writeln('[SECURITY] Controlled session engaged (${session.filterMode}). Watchdog ACTIVE.');
              watchdog.startWatchdog(
                allowedApps: session.allowedApps,
                filterMode: session.filterMode,
                blockedApps: session.blockedApps,
                onTerminated: (exe) {
                  stdout.writeln('[BLOCKED] Terminated unauthorized app (${session.filterMode}): $exe');
                  sessionService.logSecurityEvent(
                    deviceId,
                    'process_terminated',
                    'Terminated unauthorized app: $exe (Policy: ${session.filterMode})',
                  );
                },
              );
              await hostsFirewall.applyDomainBlocks();
            } else {
              watchdog.updatePolicy(
                allowedApps: session.allowedApps,
                filterMode: session.filterMode,
                blockedApps: session.blockedApps,
              );
            }

            // Internet killswitch
            if (session.isInternetBlocked) {
              await hostsFirewall.blockInternet();
            } else {
              await hostsFirewall.restoreInternet();
            }

            // Prayer pause
            if (session.isPrayerPause) {
              await registry.disableTaskManager();
            } else {
              await registry.enableTaskManager();
            }
            return;
          }
        } else {
          guiServer.isControlled = false;
        }
      }

      // If no active controlled session, revert to owner mode
      if (watchdog.isRunning) {
        stdout.writeln('[SECURITY] Reverting to Unrestricted Owner Mode.');
        watchdog.stopWatchdog();
        await hostsFirewall.removeDomainBlocks();
        await hostsFirewall.restoreInternet();
        await registry.enableTaskManager();
        guiServer.isControlled = false;
      }
    } catch (e) {
      stderr.writeln('[ERROR] Agent loop error: $e');
    }
  });

  // Handle termination signals
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('\n[SHUTDOWN] Restoring security policies and shutting down...');
    watchdog.stopWatchdog();
    await hostsFirewall.removeDomainBlocks();
    await hostsFirewall.restoreInternet();
    await registry.enableTaskManager();
    exit(0);
  });
}

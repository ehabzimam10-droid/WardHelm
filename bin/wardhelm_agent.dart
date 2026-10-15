import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:wardhelm/core/constants/app_constants.dart';
import 'package:wardhelm/core/constants/app_logo_data.dart';
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

/// Spawns native Windows System Tray helper via compiled wardhelm_tray.exe binary
Future<void> _startSystemTrayIcon() async {
  if (!Platform.isWindows) return;
  try {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\Users\Public';
    final installDir = Directory('$localAppData\\WardHelm');
    final trayExe = File('${installDir.path}\\wardhelm_tray.exe');

    if (!trayExe.existsSync()) {
      final localTrayExe = File('build\\wardhelm_tray.exe');
      if (localTrayExe.existsSync()) {
        localTrayExe.copySync(trayExe.path);
      }
    }

    if (!trayExe.existsSync()) {
      stderr.writeln('[TRAY] wardhelm_tray.exe not found at ${trayExe.path}');
      return;
    }

    final agentPid = pid;
    final proc = await Process.start(
      trayExe.path,
      ['$agentPid'],
      mode: ProcessStartMode.normal,
    );

    proc.stdout.drain().catchError((_) {});
    proc.stderr.drain().catchError((_) {});
    stdout.writeln('[TRAY] Native tray helper started (PID: ${proc.pid}).');
  } catch (e) {
    stderr.writeln('[TRAY] Failed to start system tray helper: $e');
  }
}

/// Ensures permanent installation into %LOCALAPPDATA%\\WardHelm, extracts icon, creates Start Menu/Desktop shortcuts, and configures auto-startup
Future<void> _ensureSelfInstalled() async {
  if (!Platform.isWindows) return;
  try {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\Users\Public';
    final installDir = Directory('$localAppData\\WardHelm');
    if (!installDir.existsSync()) {
      installDir.createSync(recursive: true);
    }
    final permanentExe = File('${installDir.path}\\wardhelm_agent.exe');
    final pngFile = File('${installDir.path}\\wardhelm_logo.png');
    final icoFile = File('${installDir.path}\\wardhelm_logo.ico');

    // Extract PNG icon file if missing or empty
    if (!pngFile.existsSync() || pngFile.lengthSync() == 0) {
      try {
        pngFile.writeAsBytesSync(base64Decode(AppLogoData.logoPngBase64));
      } catch (_) {}
    }

    final ico32File = File('${installDir.path}\\wardhelm_logo_32.ico');
    final ico16File = File('${installDir.path}\\wardhelm_logo_16.ico');

    // Generate real Windows .ICO files (256 for shortcuts, 32 & 16 for System Tray) if missing
    if (!icoFile.existsSync() || !ico32File.existsSync() || !ico16File.existsSync()) {
      try {
        Process.runSync('powershell.exe', [
          '-NoProfile',
          '-Command',
          '''
          Add-Type -AssemblyName System.Drawing
          \$png = "${pngFile.path}"
          \$ico256 = "${icoFile.path}"
          \$ico32 = "${ico32File.path}"
          \$ico16 = "${ico16File.path}"
          if (Test-Path \$png) {
            \$b = New-Object System.Drawing.Bitmap(\$png)
            
            if (-not (Test-Path \$ico256)) {
              \$h256 = \$b.GetHicon()
              \$i256 = [System.Drawing.Icon]::FromHandle(\$h256)
              \$fs = New-Object System.IO.FileStream(\$ico256, [System.IO.FileMode]::Create)
              \$i256.Save(\$fs)
              \$fs.Close()
              \$i256.Dispose()
            }

            if (-not (Test-Path \$ico32)) {
              \$s32 = New-Object System.Drawing.Bitmap(32, 32)
              \$g32 = [System.Drawing.Graphics]::FromImage(\$s32)
              \$g32.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
              \$g32.DrawImage(\$b, 0, 0, 32, 32)
              \$g32.Dispose()
              \$h32 = \$s32.GetHicon()
              \$i32 = [System.Drawing.Icon]::FromHandle(\$h32)
              \$fs32 = New-Object System.IO.FileStream(\$ico32, [System.IO.FileMode]::Create)
              \$i32.Save(\$fs32)
              \$fs32.Close()
              \$i32.Dispose()
              \$s32.Dispose()
            }

            if (-not (Test-Path \$ico16)) {
              \$s16 = New-Object System.Drawing.Bitmap(16, 16)
              \$g16 = [System.Drawing.Graphics]::FromImage(\$s16)
              \$g16.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
              \$g16.DrawImage(\$b, 0, 0, 16, 16)
              \$g16.Dispose()
              \$h16 = \$s16.GetHicon()
              \$i16 = [System.Drawing.Icon]::FromHandle(\$h16)
              \$fs16 = New-Object System.IO.FileStream(\$ico16, [System.IO.FileMode]::Create)
              \$i16.Save(\$fs16)
              \$fs16.Close()
              \$i16.Dispose()
              \$s16.Dispose()
            }

            \$b.Dispose()
          }
          '''
        ]);
      } catch (_) {}
    }

    final currentExe = File(Platform.resolvedExecutable);

    // If running from outside the permanent install folder, copy executable over
    if (currentExe.path.toLowerCase() != permanentExe.path.toLowerCase()) {
      try {
        currentExe.copySync(permanentExe.path);
      } catch (_) {}
    }

    final trayExe = File('${installDir.path}\\wardhelm_tray.exe');
    if (!trayExe.existsSync()) {
      final localTrayExe = File('build\\wardhelm_tray.exe');
      if (localTrayExe.existsSync()) {
        try {
          localTrayExe.copySync(trayExe.path);
        } catch (_) {}
      }
    }

    final targetPath = permanentExe.existsSync() ? permanentExe.path : currentExe.path;
    final iconPath = icoFile.existsSync() ? icoFile.path : targetPath;

    await Process.run('powershell.exe', [
      '-NoProfile',
      '-Command',
      '''
      \$WshShell = New-Object -ComObject WScript.Shell
      \$appData = [Environment]::GetFolderPath('ApplicationData')
      \$startMenu = "\$appData\\Microsoft\\Windows\\Start Menu\\Programs\\WardHelm.lnk"
      \$desktop = [Environment]::GetFolderPath('Desktop') + "\\WardHelm.lnk"

      try {
        \$s1 = \$WshShell.CreateShortcut(\$startMenu)
        \$s1.TargetPath = "$targetPath"
        \$s1.WorkingDirectory = "${installDir.path}"
        \$s1.IconLocation = "$iconPath,0"
        \$s1.Description = "WardHelm Autonomous Cloud Guardian"
        \$s1.Save()
      } catch {}

      try {
        \$s2 = \$WshShell.CreateShortcut(\$desktop)
        \$s2.TargetPath = "$targetPath"
        \$s2.WorkingDirectory = "${installDir.path}"
        \$s2.IconLocation = "$iconPath,0"
        \$s2.Description = "WardHelm Autonomous Cloud Guardian"
        \$s2.Save()
      } catch {}

      Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" -Name "WardHelm" -Value '"$targetPath"' -ErrorAction SilentlyContinue
      '''
    ]);
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
      exit(0);
    }
  } catch (_) {}

  // 3. Autonomous self-installation of shortcuts and registry run key
  await _ensureSelfInstalled();

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
  await _startSystemTrayIcon();

  guiServer.onExitRequested = () async {
    stdout.writeln('[SHUTDOWN] Exit requested from System Tray. Restoring policies...');
    watchdog.stopWatchdog();
    await hostsFirewall.removeDomainBlocks();
    await hostsFirewall.restoreInternet();
    await registry.enableTaskManager();
    exit(0);
  };

  /// Routine to check and apply auto-updates returning status map for GUI
  Future<Map<String, dynamic>> checkAndUpdateAgent({bool silent = false}) async {
    if (isUpdating) {
      return {
        'hasUpdate': true,
        'message': 'جارٍ بالفعل تنزيل التحديث والتثبيت التلقائي في الخلفية...',
      };
    }
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

        // Download and apply asynchronously
        AgentUpdater.downloadAndApplyUpdate(info);

        return {
          'hasUpdate': true,
          'currentVersion': info.currentVersion,
          'latestVersion': info.latestVersion,
          'releaseNotes': info.releaseNotes,
          'message': 'تم العثور على إصدار جديد v${info.latestVersion}! جارٍ التنزيل والتثبيت التلقائي الآن...',
        };
      } else {
        if (!silent) stdout.writeln('[UPDATER] You are on the latest version (v${info.currentVersion}).');
        return {
          'hasUpdate': false,
          'currentVersion': info.currentVersion,
          'latestVersion': info.latestVersion,
          'message': 'أنت تستخدم أحدث إصدار بالفعل (v${info.currentVersion}).',
        };
      }
    } catch (e) {
      if (!silent) stderr.writeln('[UPDATER] Check error: $e');
      return {
        'hasUpdate': false,
        'currentVersion': AppConstants.appVersion,
        'latestVersion': AppConstants.appVersion,
        'message': 'تعذر فحص التحديثات: $e',
      };
    }
  }

  guiServer.onCheckUpdateWithResult = () => checkAndUpdateAgent(silent: false);

  // Initial update check at launch
  checkAndUpdateAgent(silent: true);

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

  // Re-scan apps every 30 minutes to minimize cloud operations
  Timer.periodic(const Duration(minutes: 30), (_) async {
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

  // Main agent sync loop: 30 seconds to conserve daily Firestore read quotas
  int agentHeartbeatCounter = 0;
  Timer.periodic(const Duration(seconds: 30), (_) async {
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

        // Heartbeat with version stamp (throttled to every 48s)
        if (agentHeartbeatCounter++ % 4 == 0) {
          await deviceService.sendHeartbeatDirect(
            deviceId,
            dev,
            currentVersion: AppConstants.appVersion,
          );
        }
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

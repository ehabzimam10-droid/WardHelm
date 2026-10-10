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

/// Spawn native Windows System Tray helper in background
void _startSystemTrayIcon() {
  if (!Platform.isWindows) return;
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    var trayScript = '$exeDir\\wardhelm_tray.ps1';
    var iconPath = '$exeDir\\assets\\app_icon.ico';
    
    if (!File(trayScript).existsSync()) {
      trayScript = '${Directory.current.path}\\wardhelm_tray.ps1';
    }
    if (!File(iconPath).existsSync()) {
      iconPath = '${Directory.current.path}\\assets\\app_icon.ico';
    }

    if (File(trayScript).existsSync()) {
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
          '-IconPath',
          iconPath,
        ],
        mode: ProcessStartMode.detached,
      );
    }
  } catch (_) {}
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

  int lastInterval = -1;

  // TOTP 60-second loop
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final remaining = TotpHelper.secondsRemaining();
    guiServer.remainingSeconds = remaining;

    if (isPaired) {
      guiServer.isPaired = true;
      timer.cancel();
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

        // Check for remote commands from dashboard (e.g. check_update)
        if (dev.metadata['pendingCommand'] == 'check_update') {
          stdout.writeln('\n[COMMAND] Remote update command received from dashboard!');
          await deviceService.clearPendingCommand(deviceId, dev);
          await checkAndUpdateAgent(silent: false);
          return;
        }

        // 2. Controlled Session enforcement
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
              stdout.writeln('[SECURITY] Controlled session engaged. Watchdog ACTIVE.');
              watchdog.startWatchdog(
                allowedApps: session.allowedApps,
                onTerminated: (exe) {
                  stdout.writeln('[BLOCKED] Terminated unauthorized app: $exe');
                  sessionService.logSecurityEvent(
                    deviceId,
                    'process_terminated',
                    'Terminated prohibited app: $exe',
                  );
                },
              );
              await hostsFirewall.applyDomainBlocks();
            } else {
              watchdog.updateAllowedApps(session.allowedApps);
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

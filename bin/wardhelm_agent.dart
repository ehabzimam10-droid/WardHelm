import 'dart:async';
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

/// Standalone Native Windows Agent Executable for WardHelm
/// Can be compiled to a self-contained .exe via:
/// `dart compile exe bin/wardhelm_agent.dart -o build/wardhelm_agent.exe`
void main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln('  🛡️  WardHelm Autonomous Windows Security Agent    ');
  stdout.writeln('  Version: ${AppConstants.appVersion}             ');
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

  // Check pairing status
  final initialDevice = await deviceService.getDevice(deviceId);
  if (initialDevice != null) {
    isPaired = true;
    stdout.writeln('[STATUS] Device is already paired as "${initialDevice.name}".');
  }

  int lastInterval = -1;

  // TOTP 60-second loop if not paired
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isPaired) {
      timer.cancel();
      return;
    }

    final currentInterval = TotpHelper.currentInterval();
    final remaining = TotpHelper.secondsRemaining();

    if (currentCode.isEmpty || currentInterval != lastInterval) {
      lastInterval = currentInterval;
      currentCode = TotpHelper.generatePairingCode(deviceId);
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
    try {
      // 1. Single consolidated fetch (Zero N+1)
      final dev = await deviceService.getDevice(deviceId);
      if (dev != null) {
        if (!isPaired) {
          isPaired = true;
          stdout.writeln('\n[SUCCESS] Device claimed! Now active in fleet.');
        }
        await deviceService.sendHeartbeatDirect(deviceId, dev);

        // 2. Controlled Session enforcement
        if (dev.isControlledMode && dev.activeSessionId != null) {
          final session = await sessionService.getSession(dev.activeSessionId!);
          if (session != null && session.isActive) {
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
        }
      }

      // If no active controlled session, revert to owner mode
      if (watchdog.isRunning) {
        stdout.writeln('[SECURITY] Reverting to Unrestricted Owner Mode.');
        watchdog.stopWatchdog();
        await hostsFirewall.removeDomainBlocks();
        await hostsFirewall.restoreInternet();
        await registry.enableTaskManager();
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

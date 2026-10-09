import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/system_info_helper.dart';
import '../../core/utils/totp_helper.dart';
import '../../data/models/pairing_code_model.dart';
import '../../data/models/session_model.dart';
import '../device_service.dart';
import '../session_service.dart';
import 'process_watchdog_service.dart';
import 'hosts_firewall_service.dart';
import 'registry_kiosk_service.dart';

/// The central controller running on the Windows PC
class WindowsAgentController extends ChangeNotifier {
  final DeviceService _deviceService;
  final SessionService _sessionService;
  final ProcessWatchdogService _watchdog;
  final HostsFirewallService _hostsFirewall;
  final RegistryKioskService _registry;

  Timer? _agentLoopTimer;
  Timer? _totpTimer;

  String _deviceId = '';
  String _deviceName = '';
  bool _isPaired = false;
  String _currentPairingCode = '';
  int _pairingSecondsLeft = 60;
  SessionModel? _activeSession;
  bool _isKioskLocked = false;

  WindowsAgentController({
    DeviceService? deviceService,
    SessionService? sessionService,
    ProcessWatchdogService? watchdog,
    HostsFirewallService? hostsFirewall,
    RegistryKioskService? registry,
  })  : _deviceService = deviceService ?? DeviceService(),
        _sessionService = sessionService ?? SessionService(),
        _watchdog = watchdog ?? ProcessWatchdogService(),
        _hostsFirewall = hostsFirewall ?? HostsFirewallService(),
        _registry = registry ?? RegistryKioskService();

  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  bool get isPaired => _isPaired;
  String get currentPairingCode => _currentPairingCode;
  int get pairingSecondsLeft => _pairingSecondsLeft;
  SessionModel? get activeSession => _activeSession;
  bool get isKioskLocked => _isKioskLocked;

  /// Initializes agent on the PC
  Future<void> initialize() async {
    _deviceId = SystemInfoHelper.generateUniqueDeviceId();
    _deviceName = SystemInfoHelper.defaultDeviceName;

    // Check if device is already registered
    final device = await _deviceService.getDevice(_deviceId);
    if (device != null) {
      _isPaired = true;
      _deviceName = device.name;
    } else {
      _isPaired = false;
      _startTotpRenewalLoop();
    }

    notifyListeners();
    _startAgentLoop();
  }

  /// 60s dynamic TOTP loop for unlinked PC
  void _startTotpRenewalLoop() {
    _refreshPairingCode();
    _totpTimer?.cancel();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pairingSecondsLeft = TotpHelper.secondsRemaining();
      if (_pairingSecondsLeft == TotpHelper.periodSeconds) {
        _refreshPairingCode();
      }
      notifyListeners();
    });
  }

  void _refreshPairingCode() {
    _currentPairingCode = TotpHelper.generatePairingCode(_deviceId);
    _pairingSecondsLeft = TotpHelper.secondsRemaining();

    // Publish to cloud
    final model = PairingCodeModel(
      code: _currentPairingCode,
      deviceId: _deviceId,
      deviceName: _deviceName,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(seconds: _pairingSecondsLeft)),
    );
    _deviceService.publishPairingCode(model);
    notifyListeners();
  }

  /// Central periodic agent loop (heartbeat & session synchronization)
  void _startAgentLoop() {
    _agentLoopTimer?.cancel();
    _agentLoopTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncState());
  }

  Future<void> _syncState() async {
    // 1. Send heartbeat if paired
    if (_isPaired) {
      await _deviceService.sendHeartbeat(_deviceId);
    } else {
      // Check if paired just now
      final dev = await _deviceService.getDevice(_deviceId);
      if (dev != null) {
        _isPaired = true;
        _totpTimer?.cancel();
        notifyListeners();
      }
    }

    // 2. Check active session
    final dev = await _deviceService.getDevice(_deviceId);
    if (dev != null && dev.isControlledMode && dev.activeSessionId != null) {
      final session = await _sessionService.getSession(dev.activeSessionId!);
      if (session != null && session.isActive) {
        _handleActiveSession(session);
        return;
      }
    }

    // If no active session, restore Unrestricted Owner Mode
    if (_activeSession != null) {
      await _revertToOwnerMode();
    }
  }

  void _handleActiveSession(SessionModel session) {
    _activeSession = session;
    _isKioskLocked = session.isPrayerPause;

    // Start watchdog with whitelist
    if (!_watchdog.isRunning) {
      _watchdog.startWatchdog(
        allowedApps: session.allowedApps,
        onTerminated: (exe) {
          _sessionService.logSecurityEvent(
            _deviceId,
            'process_terminated',
            'Terminated prohibited process: $exe',
          );
        },
      );
      _hostsFirewall.applyDomainBlocks();
    } else {
      _watchdog.updateAllowedApps(session.allowedApps);
    }

    // Internet killswitch
    if (session.isInternetBlocked) {
      _hostsFirewall.blockInternet();
    } else {
      _hostsFirewall.restoreInternet();
    }

    // Lock Task Manager during prayer pause
    if (session.isPrayerPause) {
      _registry.disableTaskManager();
    } else {
      _registry.enableTaskManager();
    }

    notifyListeners();
  }

  Future<void> _revertToOwnerMode() async {
    _activeSession = null;
    _isKioskLocked = false;
    _watchdog.stopWatchdog();
    await _hostsFirewall.removeDomainBlocks();
    await _hostsFirewall.restoreInternet();
    await _registry.enableTaskManager();
    notifyListeners();
  }

  @override
  void dispose() {
    _agentLoopTimer?.cancel();
    _totpTimer?.cancel();
    _watchdog.stopWatchdog();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/session_model.dart';
import '../data/models/security_log_model.dart';
import '../services/session_service.dart';

/// Manages active session controls and live actions
class SessionState extends ChangeNotifier {
  final SessionService _service;
  Timer? _syncTimer;

  SessionModel? _activeSession;
  List<SecurityLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  SessionState({SessionService? service}) : _service = service ?? SessionService();

  SessionModel? get activeSession => _activeSession;
  List<SecurityLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startSessionWatcher(String sessionId, String deviceId) {
    loadSession(sessionId);
    loadLogs(deviceId);
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadSession(sessionId, silent: true);
      loadLogs(deviceId, silent: true);
    });
  }

  void stopWatcher() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> loadSession(String sessionId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final session = await _service.getSession(sessionId);
      if (session != null && session.isExpired) {
        await endSession();
        return;
      }
      _activeSession = session;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogs(String deviceId, {bool silent = false}) async {
    try {
      _logs = await _service.getSecurityLogs(deviceId);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> startNewSession({
    required String deviceId,
    required int durationMinutes,
    List<String> allowedApps = const [],
    String filterMode = 'whitelist',
    List<String> blockedApps = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    final session = await _service.startSession(
      deviceId: deviceId,
      durationMinutes: durationMinutes,
      allowedApps: allowedApps,
      filterMode: filterMode,
      blockedApps: blockedApps,
    );
    _isLoading = false;

    if (session != null) {
      _activeSession = session;
      startSessionWatcher(session.id, deviceId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> togglePrayerPause() async {
    if (_activeSession == null) return;
    await _service.togglePrayerPause(_activeSession!.id);
    await loadSession(_activeSession!.id, silent: true);
  }

  Future<void> extendTime(int minutes) async {
    if (_activeSession == null) return;
    await _service.extendSession(_activeSession!.id, minutes);
    await loadSession(_activeSession!.id, silent: true);
  }

  Future<void> toggleKillswitch() async {
    if (_activeSession == null) return;
    await _service.toggleInternetKillswitch(_activeSession!.id);
    await loadSession(_activeSession!.id, silent: true);
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;
    await _service.endSession(_activeSession!.id);
    _activeSession = null;
    stopWatcher();
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatcher();
    super.dispose();
  }
}

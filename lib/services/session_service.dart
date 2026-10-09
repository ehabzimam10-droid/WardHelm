import '../data/dal/firestore_dal.dart';
import '../data/models/session_model.dart';
import '../data/models/security_log_model.dart';
import 'device_service.dart';

/// Manages on-demand controlled sessions and live quick actions
class SessionService {
  final FirestoreDal _dal;
  final DeviceService _deviceService;

  SessionService({FirestoreDal? dal, DeviceService? deviceService})
      : _dal = dal ?? FirestoreDal(),
        _deviceService = deviceService ?? DeviceService(dal: dal);

  /// Start a new controlled session on a device
  Future<SessionModel?> startSession({
    required String deviceId,
    required int durationMinutes,
    required List<String> allowedApps,
  }) async {
    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    final session = SessionModel(
      id: sessionId,
      deviceId: deviceId,
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      remainingMinutes: durationMinutes,
      allowedApps: allowedApps,
      status: 'active',
    );

    final success = await _dal.setDocument('sessions', sessionId, session.toMap());
    if (!success) return null;

    // Switch device mode to controlled
    await _deviceService.setDeviceMode(deviceId, 'controlled', activeSessionId: sessionId);

    // Audit log
    await logSecurityEvent(
      deviceId,
      'session_start',
      'Started $durationMinutes min controlled session with ${allowedApps.length} whitelisted apps',
    );

    return session;
  }

  /// Get active session by ID
  Future<SessionModel?> getSession(String sessionId) async {
    final data = await _dal.getDocument('sessions', sessionId);
    if (data == null) return null;
    return SessionModel.fromMap(data, sessionId);
  }

  /// Toggle prayer pause (locks PC screen and pauses countdown)
  Future<bool> togglePrayerPause(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    final isPausing = !session.isPrayerPause;
    int newTotalPaused = session.totalPausedSeconds;
    DateTime? newPauseStart;

    if (isPausing) {
      newPauseStart = DateTime.now();
    } else {
      if (session.lastPauseStartTime != null) {
        newTotalPaused += DateTime.now().difference(session.lastPauseStartTime!).inSeconds;
      }
      newPauseStart = null;
    }

    final updated = session.copyWith(
      isPrayerPause: isPausing,
      isPaused: isPausing,
      totalPausedSeconds: newTotalPaused,
      lastPauseStartTime: newPauseStart,
    );

    final success = await _dal.setDocument('sessions', sessionId, updated.toMap());
    if (success) {
      await logSecurityEvent(
        session.deviceId,
        'prayer_pause',
        isPausing ? 'Prayer pause engaged. PC screen locked.' : 'Prayer pause released. Session resumed.',
      );
    }
    return success;
  }

  /// Extend session time (+15 or +30 minutes)
  Future<bool> extendSession(String sessionId, int extraMinutes) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    final updated = session.copyWith(
      durationMinutes: session.durationMinutes + extraMinutes,
      remainingMinutes: session.computeRemainingMinutes() + extraMinutes,
    );

    final success = await _dal.setDocument('sessions', sessionId, updated.toMap());
    if (success) {
      await logSecurityEvent(
        session.deviceId,
        'time_extension',
        'Extended session time by +$extraMinutes minutes.',
      );
    }
    return success;
  }

  /// Checks whether an active session has expired and auto-terminates it
  Future<bool> checkAndUpdateSessionExpiry(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null || !session.isActive) return false;

    if (session.isExpired) {
      await endSession(sessionId);
      await logSecurityEvent(
        session.deviceId,
        'session_expired',
        'Session time limit reached. Auto-terminated session and restored Owner Mode.',
      );
      return true;
    }
    return false;
  }

  /// Toggle instant internet killswitch
  Future<bool> toggleInternetKillswitch(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    final newState = !session.isInternetBlocked;
    final updated = session.copyWith(isInternetBlocked: newState);

    final success = await _dal.setDocument('sessions', sessionId, updated.toMap());
    if (success) {
      await logSecurityEvent(
        session.deviceId,
        'internet_killswitch',
        newState ? 'Instant Internet Killswitch ACTIVATED.' : 'Internet restored to normal.',
      );
    }
    return success;
  }

  /// End session and revert device to Unrestricted Owner Mode
  Future<bool> endSession(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    final updated = session.copyWith(
      status: 'completed',
      remainingMinutes: 0,
      endedAt: DateTime.now(),
    );

    await _dal.setDocument('sessions', sessionId, updated.toMap());
    await _deviceService.setDeviceMode(session.deviceId, 'owner', activeSessionId: null);

    await logSecurityEvent(
      session.deviceId,
      'session_end',
      'Session ended. Restored device to Unrestricted Owner Mode.',
    );

    return true;
  }

  /// Log security / audit event
  Future<void> logSecurityEvent(String deviceId, String eventType, String details) async {
    final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
    final log = SecurityLogModel(
      id: logId,
      deviceId: deviceId,
      timestamp: DateTime.now(),
      eventType: eventType,
      details: details,
    );
    await _dal.setDocument('security_logs', logId, log.toMap());
  }

  /// Fetch security logs for a device
  Future<List<SecurityLogModel>> getSecurityLogs(String deviceId) async {
    final allLogs = await _dal.getCollection('security_logs');
    final filtered = allLogs
        .map((m) => SecurityLogModel.fromMap(m))
        .where((l) => l.deviceId == deviceId)
        .toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }
}

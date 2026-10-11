/// Model representing an on-demand controlled session
class SessionModel {
  final String id;
  final String deviceId;
  final DateTime startTime;
  final int durationMinutes;
  final int remainingMinutes;
  final bool isPaused;
  final bool isPrayerPause;
  final bool isInternetBlocked;
  final List<String> allowedApps;
  final String filterMode; // 'whitelist' or 'blacklist'
  final List<String> blockedApps; // Apps explicitly terminated if launched in blacklist mode
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime? endedAt;
  final int totalPausedSeconds;
  final DateTime? lastPauseStartTime;

  const SessionModel({
    required this.id,
    required this.deviceId,
    required this.startTime,
    required this.durationMinutes,
    required this.remainingMinutes,
    this.isPaused = false,
    this.isPrayerPause = false,
    this.isInternetBlocked = false,
    this.allowedApps = const [],
    this.filterMode = 'whitelist',
    this.blockedApps = const [],
    this.status = 'active',
    this.endedAt,
    this.totalPausedSeconds = 0,
    this.lastPauseStartTime,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isWhitelistMode => filterMode == 'whitelist';
  bool get isBlacklistMode => filterMode == 'blacklist';

  /// Computes live remaining minutes taking into account pauses and time elapsed
  int computeRemainingMinutes([DateTime? now]) {
    if (status != 'active') return 0;
    final current = now ?? DateTime.now();

    int totalPause = totalPausedSeconds;
    if (isPaused && lastPauseStartTime != null) {
      totalPause += current.difference(lastPauseStartTime!).inSeconds;
    }

    final elapsedSeconds = current.difference(startTime).inSeconds - totalPause;
    final remainingSeconds = (durationMinutes * 60) - elapsedSeconds;
    if (remainingSeconds <= 0) return 0;
    return (remainingSeconds / 60).ceil();
  }

  /// Whether the session has exceeded its allotted time
  bool get isExpired => isActive && computeRemainingMinutes() <= 0;

  SessionModel copyWith({
    String? id,
    String? deviceId,
    DateTime? startTime,
    int? durationMinutes,
    int? remainingMinutes,
    bool? isPaused,
    bool? isPrayerPause,
    bool? isInternetBlocked,
    List<String>? allowedApps,
    String? filterMode,
    List<String>? blockedApps,
    String? status,
    DateTime? endedAt,
    int? totalPausedSeconds,
    DateTime? lastPauseStartTime,
  }) {
    return SessionModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isPaused: isPaused ?? this.isPaused,
      isPrayerPause: isPrayerPause ?? this.isPrayerPause,
      isInternetBlocked: isInternetBlocked ?? this.isInternetBlocked,
      allowedApps: allowedApps ?? this.allowedApps,
      filterMode: filterMode ?? this.filterMode,
      blockedApps: blockedApps ?? this.blockedApps,
      status: status ?? this.status,
      endedAt: endedAt ?? this.endedAt,
      totalPausedSeconds: totalPausedSeconds ?? this.totalPausedSeconds,
      lastPauseStartTime: lastPauseStartTime ?? this.lastPauseStartTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'remainingMinutes': computeRemainingMinutes(),
      'isPaused': isPaused,
      'isPrayerPause': isPrayerPause,
      'isInternetBlocked': isInternetBlocked,
      'allowedApps': allowedApps,
      'filterMode': filterMode,
      'blockedApps': blockedApps,
      'status': status,
      'endedAt': endedAt?.toIso8601String(),
      'totalPausedSeconds': totalPausedSeconds,
      'lastPauseStartTime': lastPauseStartTime?.toIso8601String(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final st = map['startTime'];
    final parsedStart = st is String ? (DateTime.tryParse(st) ?? DateTime.now()) : DateTime.now();
    final et = map['endedAt'];
    final parsedEnd = et is String ? DateTime.tryParse(et) : null;
    final lpst = map['lastPauseStartTime'];
    final parsedLpst = lpst is String ? DateTime.tryParse(lpst) : null;

    final appsRaw = map['allowedApps'];
    final List<String> parsedApps = appsRaw is List ? appsRaw.map((e) => e.toString()).toList() : [];

    final blockedRaw = map['blockedApps'];
    final List<String> parsedBlocked = blockedRaw is List ? blockedRaw.map((e) => e.toString()).toList() : [];

    final duration = (map['durationMinutes'] as num?)?.toInt() ?? 30;
    final storedRemaining = (map['remainingMinutes'] as num?)?.toInt() ?? duration;

    final totalPaused = (map['totalPausedSeconds'] as num?)?.toInt() ?? 0;
    final isPaused = map['isPaused'] == true;

    final session = SessionModel(
      id: docId ?? map['id'] ?? '',
      deviceId: map['deviceId'] ?? '',
      startTime: parsedStart,
      durationMinutes: duration,
      remainingMinutes: storedRemaining,
      isPaused: isPaused,
      isPrayerPause: map['isPrayerPause'] == true,
      isInternetBlocked: map['isInternetBlocked'] == true,
      allowedApps: parsedApps,
      filterMode: map['filterMode'] ?? 'whitelist',
      blockedApps: parsedBlocked,
      status: map['status'] ?? 'active',
      endedAt: parsedEnd,
      totalPausedSeconds: totalPaused,
      lastPauseStartTime: parsedLpst,
    );

    // If active, compute live remaining time
    if (session.isActive) {
      return session.copyWith(remainingMinutes: session.computeRemainingMinutes());
    }
    return session;
  }
}

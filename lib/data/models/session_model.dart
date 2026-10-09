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
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime? endedAt;

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
    this.status = 'active',
    this.endedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

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
    String? status,
    DateTime? endedAt,
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
      status: status ?? this.status,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'remainingMinutes': remainingMinutes,
      'isPaused': isPaused,
      'isPrayerPause': isPrayerPause,
      'isInternetBlocked': isInternetBlocked,
      'allowedApps': allowedApps,
      'status': status,
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final st = map['startTime'];
    final parsedStart = st is String ? (DateTime.tryParse(st) ?? DateTime.now()) : DateTime.now();
    final et = map['endedAt'];
    final parsedEnd = et is String ? DateTime.tryParse(et) : null;

    final appsRaw = map['allowedApps'];
    final List<String> parsedApps = appsRaw is List ? appsRaw.map((e) => e.toString()).toList() : [];

    return SessionModel(
      id: docId ?? map['id'] ?? '',
      deviceId: map['deviceId'] ?? '',
      startTime: parsedStart,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
      remainingMinutes: (map['remainingMinutes'] as num?)?.toInt() ?? 30,
      isPaused: map['isPaused'] == true,
      isPrayerPause: map['isPrayerPause'] == true,
      isInternetBlocked: map['isInternetBlocked'] == true,
      allowedApps: parsedApps,
      status: map['status'] ?? 'active',
      endedAt: parsedEnd,
    );
  }
}

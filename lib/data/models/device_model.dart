/// Representation of a managed computer or client device in WardHelm
class DeviceModel {
  final String id;
  final String name;
  final String os;
  final bool isOnline;
  final DateTime lastHeartbeat;
  final String mode; // 'owner' or 'controlled'
  final String? activeSessionId;
  final Map<String, dynamic> metadata;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.os,
    required this.isOnline,
    required this.lastHeartbeat,
    required this.mode,
    this.activeSessionId,
    this.metadata = const {},
  });

  bool get isOwnerMode => mode == 'owner';
  bool get isControlledMode => mode == 'controlled';

  /// Computes whether the device is truly active within the last 90 seconds
  bool get isActivelyOnline {
    final diff = DateTime.now().difference(lastHeartbeat);
    return isOnline && diff.inSeconds <= 90;
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? os,
    bool? isOnline,
    DateTime? lastHeartbeat,
    String? mode,
    String? activeSessionId,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      os: os ?? this.os,
      isOnline: isOnline ?? this.isOnline,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      mode: mode ?? this.mode,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'os': os,
      'isOnline': isOnline,
      'lastHeartbeat': lastHeartbeat.toIso8601String(),
      'mode': mode,
      'activeSessionId': activeSessionId,
      'metadata': metadata,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final hb = map['lastHeartbeat'];
    DateTime parsedHeartbeat;
    if (hb is String) {
      parsedHeartbeat = DateTime.tryParse(hb) ?? DateTime.now();
    } else {
      parsedHeartbeat = DateTime.now();
    }

    return DeviceModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Device',
      os: map['os'] ?? 'Windows Desktop',
      isOnline: map['isOnline'] == true,
      lastHeartbeat: parsedHeartbeat,
      mode: map['mode'] ?? 'owner',
      activeSessionId: map['activeSessionId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

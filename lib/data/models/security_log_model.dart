/// Model representing a security event or enforcement audit log
class SecurityLogModel {
  final String id;
  final String deviceId;
  final DateTime timestamp;
  final String eventType;
  final String details;

  const SecurityLogModel({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.eventType,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'details': details,
    };
  }

  factory SecurityLogModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final ts = map['timestamp'];
    return SecurityLogModel(
      id: docId ?? map['id'] ?? '',
      deviceId: map['deviceId'] ?? '',
      timestamp: ts is String ? (DateTime.tryParse(ts) ?? DateTime.now()) : DateTime.now(),
      eventType: map['eventType'] ?? 'general',
      details: map['details'] ?? '',
    );
  }
}

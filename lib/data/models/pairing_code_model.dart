/// Model representing a temporary 60-second device pairing code
class PairingCodeModel {
  final String code;
  final String deviceId;
  final String deviceName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isClaimed;

  const PairingCodeModel({
    required this.code,
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
    required this.expiresAt,
    this.isClaimed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isClaimed': isClaimed,
    };
  }

  factory PairingCodeModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final ca = map['createdAt'];
    final ea = map['expiresAt'];
    return PairingCodeModel(
      code: docId ?? map['code'] ?? '',
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? 'Windows PC',
      createdAt: ca is String ? (DateTime.tryParse(ca) ?? DateTime.now()) : DateTime.now(),
      expiresAt: ea is String ? (DateTime.tryParse(ea) ?? DateTime.now()) : DateTime.now(),
      isClaimed: map['isClaimed'] == true,
    );
  }
}

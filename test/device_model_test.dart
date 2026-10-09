import 'package:flutter_test/flutter_test.dart';
import 'package:wardhelm/data/models/device_model.dart';
import 'package:wardhelm/data/models/pairing_code_model.dart';

void main() {
  group('DeviceModel Tests', () {
    test('serialization roundtrip preserves all properties', () {
      final now = DateTime.now();
      final device = DeviceModel(
        id: 'dev_123',
        name: 'Gaming PC',
        os: 'Windows 11',
        isOnline: true,
        lastHeartbeat: now,
        mode: 'owner',
        activeSessionId: 'sess_999',
        metadata: {'cpu': 'i7'},
      );

      final map = device.toMap();
      final reconstructed = DeviceModel.fromMap(map, 'dev_123');

      expect(reconstructed.id, equals('dev_123'));
      expect(reconstructed.name, equals('Gaming PC'));
      expect(reconstructed.os, equals('Windows 11'));
      expect(reconstructed.isOnline, isTrue);
      expect(reconstructed.mode, equals('owner'));
      expect(reconstructed.isOwnerMode, isTrue);
      expect(reconstructed.activeSessionId, equals('sess_999'));
    });

    test('isActivelyOnline detects active vs expired heartbeat', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      final liveDevice = DeviceModel(
        id: 'dev_1',
        name: 'PC 1',
        os: 'Win',
        isOnline: true,
        lastHeartbeat: recent,
        mode: 'owner',
      );
      expect(liveDevice.isActivelyOnline, isTrue);

      final stale = DateTime.now().subtract(const Duration(minutes: 5));
      final staleDevice = DeviceModel(
        id: 'dev_2',
        name: 'PC 2',
        os: 'Win',
        isOnline: true,
        lastHeartbeat: stale,
        mode: 'owner',
      );
      expect(staleDevice.isActivelyOnline, isFalse);
    });

    test('PairingCodeModel serialization and expiration logic', () {
      final now = DateTime.now();
      final freshCode = PairingCodeModel(
        code: 'WH-ABCD-12',
        deviceId: 'dev_1',
        deviceName: 'Gaming PC',
        createdAt: now,
        expiresAt: now.add(const Duration(seconds: 60)),
      );

      final map = freshCode.toMap();
      final reconstructed = PairingCodeModel.fromMap(map, 'WH-ABCD-12');

      expect(reconstructed.code, equals('WH-ABCD-12'));
      expect(reconstructed.deviceId, equals('dev_1'));
      expect(reconstructed.deviceName, equals('Gaming PC'));
      expect(reconstructed.isExpired, isFalse);

      final expiredCode = PairingCodeModel(
        code: 'WH-EXPD-99',
        deviceId: 'dev_2',
        deviceName: 'Old PC',
        createdAt: now.subtract(const Duration(seconds: 120)),
        expiresAt: now.subtract(const Duration(seconds: 60)),
      );
      expect(expiredCode.isExpired, isTrue);
    });
  });
}

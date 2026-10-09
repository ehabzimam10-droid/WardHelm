import 'package:flutter_test/flutter_test.dart';
import 'package:wardhelm/data/models/device_model.dart';

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
  });
}

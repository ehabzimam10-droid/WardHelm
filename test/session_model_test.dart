import 'package:flutter_test/flutter_test.dart';
import 'package:wardhelm/data/models/session_model.dart';

void main() {
  group('SessionModel Tests', () {
    test('serialization roundtrip preserves session flags and apps', () {
      final now = DateTime.now();
      final session = SessionModel(
        id: 'sess_1',
        deviceId: 'dev_100',
        startTime: now,
        durationMinutes: 45,
        remainingMinutes: 30,
        isPaused: true,
        isPrayerPause: true,
        isInternetBlocked: true,
        allowedApps: ['RobloxPlayerBeta.exe', 'notepad.exe'],
        status: 'active',
      );

      final map = session.toMap();
      final parsed = SessionModel.fromMap(map, 'sess_1');

      expect(parsed.id, equals('sess_1'));
      expect(parsed.deviceId, equals('dev_100'));
      expect(parsed.durationMinutes, equals(45));
      expect(parsed.remainingMinutes, equals(30));
      expect(parsed.isPaused, isTrue);
      expect(parsed.isPrayerPause, isTrue);
      expect(parsed.isInternetBlocked, isTrue);
      expect(parsed.allowedApps, contains('RobloxPlayerBeta.exe'));
      expect(parsed.isActive, isTrue);
    });

    test('copyWith properly mutates remainingMinutes and flags', () {
      final session = SessionModel(
        id: 's1',
        deviceId: 'd1',
        startTime: DateTime.now(),
        durationMinutes: 30,
        remainingMinutes: 30,
      );

      final extended = session.copyWith(
        durationMinutes: 45,
        remainingMinutes: 45,
        isInternetBlocked: true,
      );

      expect(extended.durationMinutes, equals(45));
      expect(extended.remainingMinutes, equals(45));
      expect(extended.isInternetBlocked, isTrue);
      expect(session.isInternetBlocked, isFalse); // immutable
    });
  });
}

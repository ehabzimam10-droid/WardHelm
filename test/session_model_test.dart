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
        remainingMinutes: 45,
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
      expect(parsed.remainingMinutes, equals(45));
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

    test('computeRemainingMinutes counts down with elapsed time and pauses', () {
      final start = DateTime(2026, 10, 10, 12, 0, 0);
      final session = SessionModel(
        id: 'sess_live',
        deviceId: 'dev_1',
        startTime: start,
        durationMinutes: 30,
        remainingMinutes: 30,
        status: 'active',
      );

      // At start (0 min elapsed)
      expect(session.computeRemainingMinutes(start), equals(30));

      // After 10 minutes elapsed
      final tenMinsLater = start.add(const Duration(minutes: 10));
      expect(session.computeRemainingMinutes(tenMinsLater), equals(20));

      // After 30 minutes (expired)
      final thirtyMinsLater = start.add(const Duration(minutes: 30));
      expect(session.computeRemainingMinutes(thirtyMinsLater), equals(0));

      // With prayer pause of 10 minutes (600 seconds)
      final pausedSession = session.copyWith(
        totalPausedSeconds: 600,
      );
      // 10 minutes elapsed, but 10 minutes paused => remaining is still 30!
      expect(pausedSession.computeRemainingMinutes(tenMinsLater), equals(30));
    });
  });
}

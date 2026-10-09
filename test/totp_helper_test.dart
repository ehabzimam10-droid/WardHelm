import 'package:flutter_test/flutter_test.dart';
import 'package:wardhelm/core/utils/totp_helper.dart';

void main() {
  group('TotpHelper Tests', () {
    test('generatePairingCode produces 10-char formatted string', () {
      final code = TotpHelper.generatePairingCode('test-device-123');
      expect(code, startsWith('WH-'));
      expect(code.length, equals(10)); // WH-XXXX-XX
    });

    test('same interval produces identical code', () {
      final fixedTime = DateTime(2026, 10, 10, 12, 0, 0);
      final code1 = TotpHelper.generatePairingCode('device-a', fixedTime);
      final code2 = TotpHelper.generatePairingCode('device-a', fixedTime);
      expect(code1, equals(code2));
    });

    test('different intervals produce different codes', () {
      final time1 = DateTime(2026, 10, 10, 12, 0, 0);
      final time2 = DateTime(2026, 10, 10, 12, 1, 5); // 65 seconds later
      final code1 = TotpHelper.generatePairingCode('device-a', time1);
      final code2 = TotpHelper.generatePairingCode('device-a', time2);
      expect(code1, isNot(equals(code2)));
    });

    test('verifyPairingCode accepts current and 1-interval previous code', () {
      final now = DateTime(2026, 10, 10, 12, 0, 30);
      final currentCode = TotpHelper.generatePairingCode('dev-1', now);
      expect(TotpHelper.verifyPairingCode('dev-1', currentCode, now), isTrue);

      final prevTime = now.subtract(const Duration(seconds: 60));
      final prevCode = TotpHelper.generatePairingCode('dev-1', prevTime);
      expect(TotpHelper.verifyPairingCode('dev-1', prevCode, now), isTrue);

      final oldTime = now.subtract(const Duration(seconds: 180));
      final oldCode = TotpHelper.generatePairingCode('dev-1', oldTime);
      expect(TotpHelper.verifyPairingCode('dev-1', oldCode, now), isFalse);
    });

    test('secondsRemaining returns value between 1 and 60', () {
      final remaining = TotpHelper.secondsRemaining();
      expect(remaining, greaterThanOrEqualTo(1));
      expect(remaining, lessThanOrEqualTo(60));
    });
  });
}

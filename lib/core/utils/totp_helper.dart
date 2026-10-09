import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper to generate 60-second dynamic pairing codes and calculate remaining validity.
class TotpHelper {
  TotpHelper._();

  static const int periodSeconds = 60;
  static const String secretSalt = 'WARDHELM_FLEET_CONTROLLER_SECRET_2026';

  /// Returns current 60-second timestamp interval index
  static int currentInterval([DateTime? now]) {
    final time = now ?? DateTime.now();
    return (time.millisecondsSinceEpoch ~/ 1000) ~/ periodSeconds;
  }

  /// Returns how many seconds remain until the current 60-second code expires (1..60)
  static int secondsRemaining([DateTime? now]) {
    final time = now ?? DateTime.now();
    final elapsedInInterval = (time.millisecondsSinceEpoch ~/ 1000) % periodSeconds;
    return periodSeconds - elapsedInInterval;
  }

  /// Returns a normalized 0.0 to 1.0 progress for the circular timer
  static double progressRemaining([DateTime? now]) {
    return secondsRemaining(now) / periodSeconds;
  }

  /// Generates a human-friendly 10-char pairing code: `WH-XXXX-XX`
  static String generatePairingCode(String deviceId, [DateTime? now]) {
    final interval = currentInterval(now);
    final input = '$deviceId:$interval:$secretSalt';
    final digest = sha256.convert(utf8.encode(input));
    final bytes = digest.bytes;

    // Build characters from hash
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // base32 without ambiguous chars
    final buffer = StringBuffer('WH-');
    for (int i = 0; i < 4; i++) {
      buffer.write(chars[bytes[i] % chars.length]);
    }
    buffer.write('-');
    for (int i = 4; i < 6; i++) {
      buffer.write(chars[bytes[i] % chars.length]);
    }
    return buffer.toString();
  }

  /// Verifies if a given code matches the current or immediately previous interval
  static bool verifyPairingCode(String deviceId, String code, [DateTime? now]) {
    final cleanCode = code.trim().toUpperCase();
    final current = generatePairingCode(deviceId, now);
    if (cleanCode == current) return true;

    // Allow 1 interval of clock drift (previous 60s)
    final prevTime = (now ?? DateTime.now()).subtract(const Duration(seconds: periodSeconds));
    final previous = generatePairingCode(deviceId, prevTime);
    return cleanCode == previous;
  }
}

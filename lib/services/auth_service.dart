import 'package:shared_preferences/shared_preferences.dart';

/// Service managing authentication and owner authorization
class AuthService {
  static const String _authKey = 'wardhelm_authenticated_user';
  static const String _defaultPin = '1234'; // Default initial owner master PIN

  final SharedPreferences? _prefs;

  AuthService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Check if user has an active authenticated session
  Future<bool> isAuthenticated() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  /// Authenticate with PIN / Master Password
  Future<bool> login(String pin) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final savedPin = prefs.getString('wardhelm_master_pin') ?? _defaultPin;
    if (pin.trim() == savedPin) {
      await prefs.setBool(_authKey, true);
      return true;
    }
    return false;
  }

  /// Change master PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final savedPin = prefs.getString('wardhelm_master_pin') ?? _defaultPin;
    if (oldPin.trim() == savedPin && newPin.trim().length >= 4) {
      await prefs.setString('wardhelm_master_pin', newPin.trim());
      return true;
    }
    return false;
  }

  /// Sign out
  Future<void> logout() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
  }
}

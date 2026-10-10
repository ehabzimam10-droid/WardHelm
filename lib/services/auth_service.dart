import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/firebase_config.dart';

/// Service managing authentication and owner authorization
class AuthService {
  static const String _authKey = 'wardhelm_authenticated_user';
  static const String _userEmailKey = 'wardhelm_user_email';
  static const String _userIdKey = 'wardhelm_user_id';
  static const String _idTokenKey = 'wardhelm_id_token';
  static const String _defaultPin = '1234'; // Default initial owner master PIN

  final SharedPreferences? _prefs;
  final http.Client _client;

  AuthService({SharedPreferences? prefs, http.Client? client})
      : _prefs = prefs,
        _client = client ?? http.Client();

  /// Check if user has an active authenticated session
  Future<bool> isAuthenticated() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get current user ID (Firebase UID)
  Future<String?> getCurrentUserId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Sign In with Email and Password via Firebase Auth REST API
  Future<({bool success, String? error, String? userId})> signIn(String email, String password) async {
    final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FirebaseConfig.apiKey}');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        await prefs.setBool(_authKey, true);
        await prefs.setString(_userEmailKey, data['email'] as String? ?? email);
        await prefs.setString(_userIdKey, data['localId'] as String? ?? '');
        await prefs.setString(_idTokenKey, data['idToken'] as String? ?? '');
        return (success: true, error: null, userId: data['localId'] as String?);
      } else {
        final errorMessage = _parseAuthError(data);
        return (success: false, error: errorMessage, userId: null);
      }
    } catch (e) {
      return (success: false, error: 'تعذر الاتصال بخدمة المصادقة: $e', userId: null);
    }
  }

  /// Sign Up with Email and Password via Firebase Auth REST API
  Future<({bool success, String? error, String? userId})> signUp(String email, String password) async {
    final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FirebaseConfig.apiKey}');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        await prefs.setBool(_authKey, true);
        await prefs.setString(_userEmailKey, data['email'] as String? ?? email);
        await prefs.setString(_userIdKey, data['localId'] as String? ?? '');
        await prefs.setString(_idTokenKey, data['idToken'] as String? ?? '');
        return (success: true, error: null, userId: data['localId'] as String?);
      } else {
        final errorMessage = _parseAuthError(data);
        return (success: false, error: errorMessage, userId: null);
      }
    } catch (e) {
      return (success: false, error: 'تعذر الاتصال بخدمة المصادقة: $e', userId: null);
    }
  }

  /// Authenticate with PIN / Master Password (Quick Access)
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
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_idTokenKey);
  }

  String _parseAuthError(Map<String, dynamic> data) {
    final errorObj = data['error'] as Map<String, dynamic>?;
    final code = errorObj?['message'] as String? ?? 'UNKNOWN';

    if (code.contains('EMAIL_EXISTS')) {
      return 'البريد الإلكتروني مسجل مسبقاً. يمكنك تسجيل الدخول به مباشرة.';
    } else if (code.contains('INVALID_LOGIN_CREDENTIALS') ||
        code.contains('EMAIL_NOT_FOUND') ||
        code.contains('INVALID_PASSWORD')) {
      return 'بيانات تسجيل الدخول غير صحيحة. يرجى التحقق من البريد وكلمة المرور.';
    } else if (code.contains('WEAK_PASSWORD')) {
      return 'كلمة المرور ضعيفة. يجب أن تتكون من 6 أحرف أو أرقام على الأقل.';
    } else if (code.contains('INVALID_EMAIL')) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    } else if (code.contains('OPERATION_NOT_ALLOWED')) {
      return 'يرجى تفعيل موفر البريد (Email/Password) في Firebase Console > Authentication.';
    }
    return 'خطأ في المصادقة: $code';
  }
}

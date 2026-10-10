import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (kIsWeb) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setBool(_authKey, true);
          return true;
        }
      } catch (_) {}
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    if (kIsWeb) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user?.email != null) return user!.email;
      } catch (_) {}
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get current user ID (Firebase UID)
  Future<String?> getCurrentUserId() async {
    if (kIsWeb) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) return user.uid;
      } catch (_) {}
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Sign In with Google (Web Popup)
  Future<({bool success, String? error, String? userId})> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user != null) {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setBool(_authKey, true);
          await prefs.setString(_userEmailKey, user.email ?? '');
          await prefs.setString(_userIdKey, user.uid);
          final token = await user.getIdToken();
          if (token != null) await prefs.setString(_idTokenKey, token);
          return (success: true, error: null, userId: user.uid);
        }
      }
      return (
        success: false,
        error: 'تسجيل الدخول عبر Google متاح حالياً عبر واجهة المتصفح (Web)',
        userId: null
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        return (success: false, error: 'تم إغلاق نافذة تسجيل الدخول قبل الإكمال', userId: null);
      }
      return (
        success: false,
        error: 'خطأ أثناء تسجيل الدخول عبر Google: ${_mapFirebaseErrorCode(e.code)}',
        userId: null
      );
    } catch (e) {
      return (success: false, error: 'تعذر الاتصال بخدمة Google: $e', userId: null);
    }
  }

  /// Sign In with Email and Password via Firebase Auth REST API or Web SDK
  Future<({bool success, String? error, String? userId})> signIn(String email, String password) async {
    if (kIsWeb) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final user = credential.user;
        if (user != null) {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setBool(_authKey, true);
          await prefs.setString(_userEmailKey, user.email ?? email);
          await prefs.setString(_userIdKey, user.uid);
          final token = await user.getIdToken();
          if (token != null) await prefs.setString(_idTokenKey, token);
          return (success: true, error: null, userId: user.uid);
        }
      } on FirebaseAuthException catch (e) {
        return (success: false, error: _mapFirebaseErrorCode(e.code), userId: null);
      } catch (_) {
        // Fall through to REST API
      }
    }

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

  /// Sign Up with Email and Password via Firebase Auth REST API or Web SDK
  Future<({bool success, String? error, String? userId})> signUp(String email, String password) async {
    if (kIsWeb) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final user = credential.user;
        if (user != null) {
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setBool(_authKey, true);
          await prefs.setString(_userEmailKey, user.email ?? email);
          await prefs.setString(_userIdKey, user.uid);
          final token = await user.getIdToken();
          if (token != null) await prefs.setString(_idTokenKey, token);
          return (success: true, error: null, userId: user.uid);
        }
      } on FirebaseAuthException catch (e) {
        return (success: false, error: _mapFirebaseErrorCode(e.code), userId: null);
      } catch (_) {
        // Fall through to REST API
      }
    }

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
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_idTokenKey);
  }

  String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة. يرجى التحقق من البريد وكلمة المرور.';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مسجل مسبقاً. يمكنك تسجيل الدخول مباشرة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يجب أن تتكون من 6 أحرف على الأقل.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب. يرجى التواصل مع الإدارة.';
      case 'operation-not-allowed':
        return 'طريقة تسجيل الدخول غير مفعلة في إعدادات المشروع.';
      default:
        return 'خطأ في المصادقة ($code)';
    }
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

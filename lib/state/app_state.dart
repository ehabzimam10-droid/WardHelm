import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_localizations.dart';

enum AppView { dashboard, deviceDetail, agentKiosk, settings }

/// Manages global application settings, themes, and navigation
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isArabic = true;
  AppView _currentView = (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
      ? AppView.agentKiosk
      : AppView.dashboard;
  String? _selectedDeviceId;
  VoidCallback? onLockDashboard;

  ThemeMode get themeMode => _themeMode;
  bool get isArabic => _isArabic;
  AppLocalizations get loc => AppLocalizations(isArabic: _isArabic);
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppView get currentView => _currentView;
  String? get selectedDeviceId => _selectedDeviceId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('wardhelm_dark_mode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isArabic = prefs.getBool('wardhelm_arabic') ?? true;

    // Set initial view based on platform
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      _currentView = AppView.agentKiosk;
    } else {
      _currentView = AppView.dashboard;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wardhelm_dark_mode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isArabic = !_isArabic;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wardhelm_arabic', _isArabic);
    notifyListeners();
  }

  void navigateTo(AppView view, {String? deviceId}) {
    _currentView = view;
    if (deviceId != null) {
      _selectedDeviceId = deviceId;
    }
    notifyListeners();
  }

  void lockDashboard() {
    onLockDashboard?.call();
    notifyListeners();
  }
}

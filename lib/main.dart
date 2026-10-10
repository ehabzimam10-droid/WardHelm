import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/windows/windows_agent_controller.dart';
import 'state/app_state.dart';
import 'state/device_state.dart';
import 'state/session_state.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/device_detail_screen.dart';
import 'presentation/screens/agent_kiosk_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Web
  if (kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          authDomain: FirebaseConfig.authDomain,
          storageBucket: FirebaseConfig.storageBucket,
        ),
      );
    } catch (e) {
      debugPrint('Firebase Web init: $e');
    }
  }

  // Desktop Window Manager initialization
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1100, 780),
        minimumSize: Size(420, 600),
        center: true,
        title: 'WardHelm - Cloud Fleet Controller & Guardian',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }

  runApp(const WardHelmApp());
}

class WardHelmApp extends StatefulWidget {
  const WardHelmApp({super.key});

  @override
  State<WardHelmApp> createState() => _WardHelmAppState();
}

class _WardHelmAppState extends State<WardHelmApp> {
  final AppState _appState = AppState();
  final DeviceState _deviceState = DeviceState();
  final SessionState _sessionState = SessionState();
  final WindowsAgentController _agentController = WindowsAgentController();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _appState.initialize();

    // Check auth status first
    _isAuthenticated = await _authService.isAuthenticated();

    // ONLY start polling if authenticated
    if (_isAuthenticated) {
      _deviceState.startPolling();
    }

    // If running on Windows, also spin up the local PC agent controller
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await _agentController.initialize();
    }

    _appState.onLockDashboard = () async {
      _deviceState.stopPolling();
      await _authService.logout();
      if (mounted) {
        setState(() => _isAuthenticated = false);
      }
    };

    _appState.addListener(() => setState(() {}));
    _deviceState.addListener(() => setState(() {}));
    _sessionState.addListener(() => setState(() {}));
    _agentController.addListener(() => setState(() {}));

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _appState.dispose();
    _deviceState.dispose();
    _sessionState.dispose();
    _agentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'WardHelm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _appState.themeMode,
      builder: (context, child) {
        return Directionality(
          textDirection: _appState.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox(),
        );
      },
      home: _buildMainView(),
    );
  }

  Widget _buildMainView() {
    // STRICT AUTH GUARD:
    // If user is not authenticated, ALWAYS redirect directly to AuthScreen.
    // Impossible to access dashboard or devices without valid login.
    if (!_isAuthenticated) {
      _deviceState.stopPolling();
      return AuthScreen(
        onAuthenticated: () {
          setState(() => _isAuthenticated = true);
          _deviceState.startPolling();
        },
      );
    }

    // On Windows Desktop, owner can switch to local PC agent kiosk
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows && _appState.currentView == AppView.agentKiosk) {
      return AgentKioskScreen(
        agentController: _agentController,
        appState: _appState,
      );
    }

    // Authenticated Views Router
    switch (_appState.currentView) {
      case AppView.deviceDetail:
        final selected = _deviceState.selectedDevice;
        if (selected != null) {
          return DeviceDetailScreen(
            device: selected,
            appState: _appState,
            deviceState: _deviceState,
            sessionState: _sessionState,
          );
        }
        return DashboardScreen(
          appState: _appState,
          deviceState: _deviceState,
          onLogout: () => _appState.lockDashboard(),
        );

      case AppView.agentKiosk:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
          return AgentKioskScreen(
            agentController: _agentController,
            appState: _appState,
          );
        }
        return DashboardScreen(
          appState: _appState,
          deviceState: _deviceState,
          onLogout: () => _appState.lockDashboard(),
        );

      case AppView.settings:
        return SettingsScreen(appState: _appState);

      case AppView.dashboard:
        return DashboardScreen(
          appState: _appState,
          deviceState: _deviceState,
          onLogout: () => _appState.lockDashboard(),
        );
    }
  }
}

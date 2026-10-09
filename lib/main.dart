import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
    _deviceState.startPolling();

    // If running on Windows, also spin up the local PC agent controller
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await _agentController.initialize();
    }

    _isAuthenticated = await _authService.isAuthenticated();

    _appState.onLockDashboard = () {
      setState(() => _isAuthenticated = false);
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
    // If viewing the Windows Agent Kiosk, render directly without requiring owner PIN
    if (_appState.currentView == AppView.agentKiosk) {
      return AgentKioskScreen(
        agentController: _agentController,
        appState: _appState,
      );
    }

    // For Controller Dashboard / Settings / Details, require Owner Authentication
    if (!_isAuthenticated) {
      return AuthScreen(
        onAuthenticated: () => setState(() => _isAuthenticated = true),
      );
    }

    // Check current view route
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
        return DashboardScreen(appState: _appState, deviceState: _deviceState);

      case AppView.agentKiosk:
        return AgentKioskScreen(
          agentController: _agentController,
          appState: _appState,
        );

      case AppView.settings:
        return SettingsScreen(appState: _appState);

      case AppView.dashboard:
        return DashboardScreen(appState: _appState, deviceState: _deviceState);
    }
  }
}

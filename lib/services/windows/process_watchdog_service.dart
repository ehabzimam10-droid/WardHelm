import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/utils/native_io/native_io.dart';

typedef OnProcessTerminatedCallback = void Function(String processName);

/// Process watchdog that inspects active tasks and terminates unauthorized apps
/// Supports dual modes: Whitelist (kill anything not permitted) and Blacklist (kill specifically blocked apps).
class ProcessWatchdogService {
  Timer? _timer;
  bool _isRunning = false;
  String _filterMode = 'whitelist'; // 'whitelist' or 'blacklist'
  List<String> _allowedApps = [];
  List<String> _blockedApps = [];
  OnProcessTerminatedCallback? onProcessTerminated;

  bool get isRunning => _isRunning;
  String get filterMode => _filterMode;

  /// Starts the periodic watchdog loop (every 2 seconds)
  void startWatchdog({
    List<String> allowedApps = const [],
    String filterMode = 'whitelist',
    List<String> blockedApps = const [],
    OnProcessTerminatedCallback? onTerminated,
  }) {
    if (!NativeIo.isWindows) return;

    _filterMode = filterMode;
    _allowedApps = allowedApps.map((e) => e.trim().toLowerCase()).toList();
    _blockedApps = blockedApps.map((e) => e.trim().toLowerCase()).toList();
    onProcessTerminated = onTerminated;
    _isRunning = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _scanAndEnforce());
  }

  /// Stops watchdog
  void stopWatchdog() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Updates current policy dynamically during an active session
  void updatePolicy({
    List<String>? allowedApps,
    String? filterMode,
    List<String>? blockedApps,
  }) {
    if (filterMode != null) _filterMode = filterMode;
    if (allowedApps != null) {
      _allowedApps = allowedApps.map((e) => e.trim().toLowerCase()).toList();
    }
    if (blockedApps != null) {
      _blockedApps = blockedApps.map((e) => e.trim().toLowerCase()).toList();
    }
  }

  /// Backwards-compatible whitelist updater
  void updateAllowedApps(List<String> allowedApps) {
    updatePolicy(allowedApps: allowedApps, filterMode: 'whitelist');
  }

  /// Performs scan of current running tasks
  Future<void> _scanAndEnforce() async {
    if (!_isRunning) return;

    try {
      final result = await NativeIo.runProcess(
        'tasklist',
        ['/fo', 'csv', '/nh'],
        runInShell: true,
      );

      if (result.exitCode != 0) return;

      final output = result.stdout as String;
      final lines = output.split('\r\n');
      final Set<String> killedThisCycle = {};

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final fields = RegExp(r'"([^"]*)"')
            .allMatches(line)
            .map((m) => m.group(1) ?? '')
            .toList();

        if (fields.isEmpty) continue;

        final rawExe = fields[0].toLowerCase().trim();
        if (rawExe.isEmpty) continue;

        // Skip Windows system services (Session 0 / Services)
        if (fields.length >= 4) {
          final sessionName = fields[2].toLowerCase();
          final sessionNum = fields[3];
          if (sessionName == 'services' || sessionNum == '0') {
            continue;
          }
        }

        // Never terminate protected system or WardHelm processes
        if (AppConstants.protectedSystemProcesses.contains(rawExe)) continue;

        if (_filterMode == 'whitelist') {
          // Whitelist Mode: Terminate if NOT explicitly allowed
          final isWhitelisted = _allowedApps.any((app) {
            final normalizedApp = app.toLowerCase().trim();
            final baseName = normalizedApp.replaceAll('.exe', '');
            return rawExe == normalizedApp ||
                rawExe == '$baseName.exe' ||
                rawExe.startsWith(baseName);
          });

          if (!isWhitelisted && !killedThisCycle.contains(rawExe)) {
            killedThisCycle.add(rawExe);
            await _killProcess(rawExe);
          }
        } else {
          // Blacklist Mode: Terminate if specifically present in blocked list
          final isBlacklisted = _blockedApps.any((app) {
            final normalizedApp = app.toLowerCase().trim();
            final baseName = normalizedApp.replaceAll('.exe', '');
            return rawExe == normalizedApp ||
                rawExe == '$baseName.exe' ||
                rawExe.startsWith(baseName);
          });

          if (isBlacklisted && !killedThisCycle.contains(rawExe)) {
            killedThisCycle.add(rawExe);
            await _killProcess(rawExe);
          }
        }
      }
    } catch (_) {}
  }

  /// Force kill unauthorized executable
  Future<void> _killProcess(String exeName) async {
    try {
      await NativeIo.runProcess(
        'taskkill',
        ['/f', '/im', exeName],
        runInShell: true,
      );
      onProcessTerminated?.call(exeName);
    } catch (_) {}
  }
}

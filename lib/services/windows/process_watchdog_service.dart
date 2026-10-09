import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/utils/native_io/native_io.dart';

typedef OnProcessTerminatedCallback = void Function(String processName);

/// Process watchdog that inspects active tasks and terminates unauthorized apps
class ProcessWatchdogService {
  Timer? _timer;
  bool _isRunning = false;
  List<String> _allowedApps = [];
  OnProcessTerminatedCallback? onProcessTerminated;

  bool get isRunning => _isRunning;

  /// Starts the periodic watchdog loop (e.g. every 2 seconds)
  void startWatchdog({
    required List<String> allowedApps,
    OnProcessTerminatedCallback? onTerminated,
  }) {
    if (!NativeIo.isWindows) return;

    _allowedApps = allowedApps.map((e) => e.trim().toLowerCase()).toList();
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

  /// Updates current whitelist dynamically
  void updateAllowedApps(List<String> allowedApps) {
    _allowedApps = allowedApps.map((e) => e.trim().toLowerCase()).toList();
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

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final match = RegExp(r'^"([^"]+)"').firstMatch(line);
        if (match == null) continue;

        final rawExe = match.group(1)?.toLowerCase() ?? '';
        if (rawExe.isEmpty) continue;

        if (AppConstants.protectedSystemProcesses.contains(rawExe)) continue;

        final isWhitelisted = _allowedApps.any((app) =>
            rawExe == app || rawExe.startsWith(app.replaceAll('.exe', '')));

        if (!isWhitelisted) {
          await _killProcess(rawExe);
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

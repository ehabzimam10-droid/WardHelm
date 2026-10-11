import 'dart:io';
import 'package:http/http.dart' as http;
import '../auto_updater_service.dart';

/// Handles autonomous self-updating for the standalone Windows Agent executable
class AgentUpdater {
  static final AutoUpdaterService _updater = AutoUpdaterService();

  /// Check if a new version exists
  static Future<UpdateInfo> checkForUpdates() async {
    return await _updater.checkForUpdates();
  }

  /// Downloads the new agent binary and spawns a background updater script to replace and restart
  static Future<bool> downloadAndApplyUpdate(
    UpdateInfo update, {
    void Function(String step)? onProgress,
  }) async {
    if (!Platform.isWindows) return false;

    stdout.writeln('\n[AUTO-UPDATER] ==========================================');
    stdout.writeln('[AUTO-UPDATER] Downloading update v${update.latestVersion}...');
    stdout.writeln('[AUTO-UPDATER] URL: ${update.downloadUrl}');
    onProgress?.call('جارٍ تنزيل التحديث v${update.latestVersion}...');

    try {
      final client = http.Client();
      final response = await client.get(Uri.parse(update.downloadUrl));

      if (response.statusCode != 200 || response.bodyBytes.length < 50000) {
        stderr.writeln(
          '[AUTO-UPDATER] Error: Downloaded file is invalid (Size: ${response.bodyBytes.length} bytes, HTTP ${response.statusCode})',
        );
        onProgress?.call('فشل التنزيل: استجابة الخادم غير صالحة');
        return false;
      }

      onProgress?.call('تم التنزيل بنجاح (${(response.bodyBytes.length / (1024 * 1024)).toStringAsFixed(1)} MB). جاري استبدال الملف وإعادة التشغيل...');

      final currentExe = Platform.resolvedExecutable;
      final currentDir = File(currentExe).parent.path;
      final updateExePath = '$currentDir\\wardhelm_agent_update.exe';
      final batchScriptPath = '$currentDir\\wardhelm_update.bat';

      final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\Users\Public';
      final permanentExePath = '$localAppData\\WardHelm\\wardhelm_agent.exe';

      // Write downloaded binary
      await File(updateExePath).writeAsBytes(response.bodyBytes);
      stdout.writeln('[AUTO-UPDATER] Update downloaded (${(response.bodyBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB).');

      // Write batch script with robust retry loop to safely replace locked executable and restart
      final batchContent = '''@echo off
title WardHelm Auto-Updater
echo ===================================================
echo   WardHelm Updating to Version ${update.latestVersion}...
echo ===================================================
echo Waiting for existing agent process to release locks...
timeout /t 2 /nobreak > nul

:retry
echo Replacing current executable...
copy /y "$updateExePath" "$currentExe" > nul
if errorlevel 1 (
  echo Binary still locked, retrying in 1 second...
  timeout /t 1 /nobreak > nul
  goto retry
)

if exist "$permanentExePath" (
  copy /y "$updateExePath" "$permanentExePath" > nul
)

if exist "$updateExePath" del "$updateExePath" > nul

echo Restarting updated agent...
start "" "$currentExe"
echo Update complete.
del "%~f0"
''';

      await File(batchScriptPath).writeAsString(batchContent);
      stdout.writeln('[AUTO-UPDATER] Launching update batch script and restarting agent...');

      await Process.start('cmd.exe', ['/c', batchScriptPath], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      stderr.writeln('[AUTO-UPDATER] Failed to apply update: $e');
      onProgress?.call('فشل تثبيت التحديث: $e');
      return false;
    }
  }
}

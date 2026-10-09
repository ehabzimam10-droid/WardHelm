import 'dart:io' as io;

class ProcessRunResult {
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;

  const ProcessRunResult({required this.exitCode, required this.stdout, required this.stderr});
}

/// Native OS implementation using dart:io for Windows, macOS, Linux
class NativeIo {
  NativeIo._();

  static bool get isIoSupported => true;
  static bool get isWindows => io.Platform.isWindows;
  static bool get isWeb => false;

  static String? getEnvironmentVariable(String key) {
    try {
      return io.Platform.environment[key];
    } catch (_) {
      return null;
    }
  }

  static Future<ProcessRunResult> runProcess(
    String executable,
    List<String> arguments, {
    bool runInShell = true,
  }) async {
    try {
      final res = await io.Process.run(executable, arguments, runInShell: runInShell);
      return ProcessRunResult(
        exitCode: res.exitCode,
        stdout: res.stdout,
        stderr: res.stderr,
      );
    } catch (e) {
      return ProcessRunResult(exitCode: -1, stdout: '', stderr: e.toString());
    }
  }

  static Future<bool> fileExists(String path) async {
    try {
      return await io.File(path).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<String?> readFileAsString(String path) async {
    try {
      final file = io.File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> writeFileAsString(String path, String content) async {
    try {
      await io.File(path).writeAsString(content);
      return true;
    } catch (_) {
      return false;
    }
  }
}

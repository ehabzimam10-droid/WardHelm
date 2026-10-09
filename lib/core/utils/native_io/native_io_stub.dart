/// Stub implementation of native OS operations for Web and unsupported platforms
class ProcessRunResult {
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;

  const ProcessRunResult({this.exitCode = -1, this.stdout = '', this.stderr = ''});
}

class NativeIo {
  NativeIo._();

  static bool get isIoSupported => false;
  static bool get isWindows => false;
  static bool get isWeb => true;

  static String? getEnvironmentVariable(String key) => null;

  static Future<ProcessRunResult> runProcess(
    String executable,
    List<String> arguments, {
    bool runInShell = true,
  }) async {
    return const ProcessRunResult(exitCode: -1, stdout: '', stderr: 'Not supported on Web');
  }

  static Future<bool> fileExists(String path) async => false;

  static Future<String?> readFileAsString(String path) async => null;

  static Future<bool> writeFileAsString(String path, String content) async => false;
}

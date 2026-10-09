import '../../core/utils/native_io/native_io.dart';

/// Manages Windows registry policies and Task Manager locking
class RegistryKioskService {
  static const String _systemPolicyKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System';

  /// Disables Task Manager by setting DisableTaskMgr = 1
  Future<bool> disableTaskManager() async {
    if (!NativeIo.isWindows) return true;

    try {
      final res = await NativeIo.runProcess('reg', [
        'add',
        _systemPolicyKey,
        '/v',
        'DisableTaskMgr',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ], runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Re-enables Task Manager by setting DisableTaskMgr = 0
  Future<bool> enableTaskManager() async {
    if (!NativeIo.isWindows) return true;

    try {
      final res = await NativeIo.runProcess('reg', [
        'add',
        _systemPolicyKey,
        '/v',
        'DisableTaskMgr',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ], runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

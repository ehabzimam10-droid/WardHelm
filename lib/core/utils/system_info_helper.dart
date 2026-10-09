import 'native_io/native_io.dart';

/// Helper to safely inspect host hardware and platform info across Web & Windows
class SystemInfoHelper {
  SystemInfoHelper._();

  static bool get isWindowsDesktop => NativeIo.isWindows;

  static String get platformName {
    if (NativeIo.isWeb) return 'Web Browser';
    if (NativeIo.isWindows) return 'Windows Desktop';
    return 'Client Device';
  }

  static String get defaultDeviceName {
    if (NativeIo.isWeb) return 'Web Controller';
    if (NativeIo.isWindows) {
      final envName = NativeIo.getEnvironmentVariable('COMPUTERNAME');
      if (envName != null && envName.isNotEmpty) {
        return envName;
      }
      return 'Windows PC';
    }
    return 'WardHelm Client';
  }

  static String generateUniqueDeviceId() {
    if (NativeIo.isWeb) {
      return 'web_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    }
    if (NativeIo.isWindows) {
      final user = NativeIo.getEnvironmentVariable('USERNAME') ?? 'user';
      final comp = NativeIo.getEnvironmentVariable('COMPUTERNAME') ?? 'pc';
      final clean = '${comp}_$user'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
      return 'win_$clean';
    }
    return 'device_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  }
}

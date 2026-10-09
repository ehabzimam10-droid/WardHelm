import '../../core/constants/app_constants.dart';
import '../../core/utils/native_io/native_io.dart';

/// Manages Windows hosts file domain filtering and Windows Firewall selective killswitch
class HostsFirewallService {
  static const String _hostsPath = r'C:\Windows\System32\drivers\etc\hosts';

  /// Injects domain redirects to 127.0.0.1 in the Windows hosts file
  Future<bool> applyDomainBlocks({List<String>? domains}) async {
    if (!NativeIo.isWindows) return true;

    final blocked = domains ?? AppConstants.defaultBlockedDomains;
    try {
      if (!await NativeIo.fileExists(_hostsPath)) return false;

      String? content = await NativeIo.readFileAsString(_hostsPath);
      if (content == null) return false;

      content = _removeExistingBlocks(content);

      final buffer = StringBuffer(content.trimRight());
      buffer.writeln('\n\n${AppConstants.hostsHeader}');
      for (final domain in blocked) {
        buffer.writeln('127.0.0.1 $domain');
      }
      buffer.writeln(AppConstants.hostsFooter);

      return await NativeIo.writeFileAsString(_hostsPath, buffer.toString());
    } catch (_) {
      return false;
    }
  }

  /// Removes all WardHelm block entries from hosts file
  Future<bool> removeDomainBlocks() async {
    if (!NativeIo.isWindows) return true;

    try {
      if (!await NativeIo.fileExists(_hostsPath)) return false;

      final content = await NativeIo.readFileAsString(_hostsPath);
      if (content == null) return false;

      final cleaned = _removeExistingBlocks(content);
      return await NativeIo.writeFileAsString(_hostsPath, cleaned);
    } catch (_) {
      return false;
    }
  }

  String _removeExistingBlocks(String content) {
    final startIdx = content.indexOf(AppConstants.hostsHeader);
    final endIdx = content.indexOf(AppConstants.hostsFooter);
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      final before = content.substring(0, startIdx).trimRight();
      final after = content.substring(endIdx + AppConstants.hostsFooter.length).trimLeft();
      return '$before\n$after'.trim();
    }
    return content;
  }

  /// Engages Windows Firewall block rules to cut general outbound game (UDP) and web (TCP) traffic
  Future<bool> blockInternet() async {
    if (!NativeIo.isWindows) return true;

    try {
      await restoreInternet();

      // Block all outbound UDP (disconnects online game servers including Roblox, Minecraft, Steam)
      await NativeIo.runProcess('netsh', [
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=${AppConstants.firewallUdpRuleName}',
        'dir=out',
        'action=block',
        'protocol=UDP',
      ], runInShell: true);

      // Block non-secure web traffic (ports 80, 8080)
      await NativeIo.runProcess('netsh', [
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=${AppConstants.firewallTcpRuleName}',
        'dir=out',
        'action=block',
        'protocol=TCP',
        'remoteport=80,8080',
      ], runInShell: true);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes firewall block rules, restoring internet to normal
  Future<bool> restoreInternet() async {
    if (!NativeIo.isWindows) return true;

    try {
      // Delete UDP killswitch rule
      await NativeIo.runProcess('netsh', [
        'advfirewall',
        'firewall',
        'delete',
        'rule',
        'name=${AppConstants.firewallUdpRuleName}',
      ], runInShell: true);

      // Delete TCP killswitch rule
      await NativeIo.runProcess('netsh', [
        'advfirewall',
        'firewall',
        'delete',
        'rule',
        'name=${AppConstants.firewallTcpRuleName}',
      ], runInShell: true);

      // Delete legacy rule name if present
      await NativeIo.runProcess('netsh', [
        'advfirewall',
        'firewall',
        'delete',
        'rule',
        'name=${AppConstants.firewallRuleName}',
      ], runInShell: true);

      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

/// In-app auto-updater service checking GitHub releases and providing one-click upgrades
class AutoUpdaterService {
  final http.Client _client;

  AutoUpdaterService({http.Client? client}) : _client = client ?? http.Client();

  /// Check Firebase Hosting CDN and GitHub repo for the latest published release
  Future<UpdateInfo> checkForUpdates() async {
    final current = AppConstants.appVersion;

    // 1. Check Primary Firebase CDN: https://wardhelm-app.web.app/downloads/version.json
    try {
      final cdnUrl = Uri.parse('https://wardhelm-app.web.app/downloads/version.json');
      final cdnResponse = await _client.get(cdnUrl);
      if (cdnResponse.statusCode == 200) {
        final data = json.decode(cdnResponse.body) as Map<String, dynamic>;
        final latestVersion = (data['version'] as String? ?? '').replaceAll('v', '').trim();
        final downloadUrl = data['downloadUrl'] as String? ?? '';
        final releaseNotes = data['releaseNotes'] as String? ?? 'تحديثات أمان وتحسينات في الأداء.';

        if (latestVersion.isNotEmpty && _compareVersions(latestVersion, current) > 0) {
          return UpdateInfo(
            hasUpdate: true,
            currentVersion: current,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl.isNotEmpty
                ? downloadUrl
                : 'https://wardhelm-app.web.app/downloads/wardhelm_agent.exe',
            releaseNotes: releaseNotes,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback to GitHub Releases API
    final url = Uri.parse('https://api.github.com/repos/${AppConstants.githubRepo}/releases/latest');
    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? 'v1.0.0').replaceAll('v', '').trim();
        final body = data['body'] as String? ?? 'تحديث جديد لبرنامج WardHelm.';
        
        final assets = data['assets'] as List<dynamic>? ?? [];
        String downloadUrl = '';
        if (assets.isNotEmpty) {
          downloadUrl = assets.first['browser_download_url'] as String? ?? '';
        }
        if (downloadUrl.isEmpty) {
          downloadUrl = data['html_url'] as String? ?? 'https://github.com/${AppConstants.githubRepo}/releases';
        }

        final isNewer = _compareVersions(tagName, current) > 0;
        return UpdateInfo(
          hasUpdate: isNewer,
          currentVersion: current,
          latestVersion: tagName,
          downloadUrl: downloadUrl,
          releaseNotes: body,
        );
      }
    } catch (_) {}

    // Fallback if no updates available
    return UpdateInfo(
      hasUpdate: false,
      currentVersion: current,
      latestVersion: current,
      downloadUrl: 'https://wardhelm-app.web.app/downloads/wardhelm_agent.exe',
      releaseNotes: 'أنت تستخدم أحدث إصدار بالفعل (v$current).',
    );
  }

  /// Compares semantic versions (e.g. 1.0.1 vs 1.0.0)
  int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final a = i < p1.length ? p1[i] : 0;
      final b = i < p2.length ? p2[i] : 0;
      if (a > b) return 1;
      if (a < b) return -1;
    }
    return 0;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auto_updater_service.dart';
import '../../state/app_state.dart';
import '../../state/device_state.dart';
import '../widgets/device_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'pairing_dialog.dart';

/// Main fleet controller dashboard
class DashboardScreen extends StatelessWidget {
  final AppState appState;
  final DeviceState deviceState;
  final VoidCallback? onLogout;

  const DashboardScreen({
    super.key,
    required this.appState,
    required this.deviceState,
    this.onLogout,
  });

  void _openPairingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PairingDialog(deviceState: deviceState),
    );
  }

  Future<void> _showUpdateDialog(BuildContext context) async {
    final loc = appState.loc;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(appState.isArabic ? 'جارٍ فحص توفر تحديثات جديدة...' : 'Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    final info = await AutoUpdaterService().checkForUpdates();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              info.hasUpdate ? Icons.new_releases_rounded : Icons.check_circle_rounded,
              color: info.hasUpdate ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 10),
            Text(info.hasUpdate ? loc.updateAvailable : loc.upToDate),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.currentVersion}: v${info.currentVersion}'),
            const SizedBox(height: 4),
            Text('${loc.latestVersion}: v${info.latestVersion}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              info.hasUpdate
                  ? '${appState.isArabic ? "ملاحظات الإصدار" : "Release Notes"}:\n${info.releaseNotes}'
                  : (appState.isArabic
                      ? 'تطبيق الويب وكافة ملفات النظام محدثة بالكامل وتعمل بأحدث التقنيات.'
                      : 'All system binaries and web dashboard are up to date.'),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          if (info.hasUpdate)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                appState.navigateTo(AppView.settings);
              },
              child: Text(appState.isArabic ? 'الانتقال للتحديثات' : 'Go to Updates'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final loc = appState.loc;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.confirmLogoutTitle),
        content: Text(loc.confirmLogoutMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (onLogout != null) {
        onLogout!();
      } else {
        appState.lockDashboard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = appState.loc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = deviceState.devices;
    final onlineCount = devices.where((d) => d.isActivelyOnline).length;
    final controlledCount = devices.where((d) => d.isControlledMode).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wardhelm_logo.png',
              width: 28,
              height: 28,
              errorBuilder: (_, _, _) => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loc.appTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
            IconButton(
              onPressed: () => appState.navigateTo(AppView.agentKiosk),
              icon: const Icon(Icons.monitor_rounded),
              tooltip: loc.agentKiosk,
            ),
          IconButton(
            onPressed: () => _showUpdateDialog(context),
            icon: const Icon(Icons.system_update_rounded),
            tooltip: loc.checkUpdates,
          ),
          // Language Switcher Button (Direct 1-click toggle)
          IconButton(
            onPressed: appState.toggleLanguage,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                appState.isArabic ? 'EN' : 'عربي',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            tooltip: appState.isArabic ? 'Switch to English' : 'التحويل إلى العربية',
          ),
          ThemeToggleButton(
            isDarkMode: appState.isDarkMode,
            onToggle: appState.toggleTheme,
          ),
          IconButton(
            onPressed: () => deviceState.refreshDevices(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.refresh,
          ),
          IconButton(
            onPressed: () => appState.navigateTo(AppView.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.settings,
          ),
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: loc.logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => deviceState.refreshDevices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Fleet Metrics (Adaptive Layout for Mobile & Desktop)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 440;
                  if (isNarrow) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: loc.totalDevices,
                                value: '${devices.length}',
                                icon: Icons.devices_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: loc.onlineNow,
                                value: '$onlineCount',
                                icon: Icons.wifi_rounded,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MetricCard(
                          label: loc.controlledSessions,
                          value: '$controlledCount',
                          icon: Icons.lock_clock_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: loc.totalDevices,
                          value: '${devices.length}',
                          icon: Icons.devices_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: loc.onlineNow,
                          value: '$onlineCount',
                          icon: Icons.wifi_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: loc.controlledSessions,
                          value: '$controlledCount',
                          icon: Icons.lock_clock_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Devices Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.devices,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _openPairingDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(loc.addDevice),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Devices List or Empty State
              if (deviceState.isLoading && devices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (devices.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.laptop_chromebook_rounded,
                          size: 56,
                          color: (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noDevicesTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.noDevicesDesc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openPairingDialog(context),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: Text(loc.pairFirstDevice),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...devices.map(
                  (device) => DeviceCard(
                    device: device,
                    onTap: () {
                      deviceState.selectDevice(device.id);
                      appState.navigateTo(AppView.deviceDetail, deviceId: device.id);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPairingDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.addDevice),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

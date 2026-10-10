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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جارٍ فحص توفر تحديثات جديدة...'),
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
            Text(info.hasUpdate ? 'يتوفر تحديث جديد!' : 'أنت على أحدث إصدار'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الحالي: v${info.currentVersion}'),
            const SizedBox(height: 4),
            Text('أحدث إصدار: v${info.latestVersion}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              info.hasUpdate
                  ? 'ملاحظات الإصدار:\n${info.releaseNotes}'
                  : 'تطبيق الويب وكافة ملفات النظام محدثة بالكامل وتعمل بأحدث التقنيات.',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
          if (info.hasUpdate)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                appState.navigateTo(AppView.settings);
              },
              child: const Text('الانتقال للتحديثات'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = deviceState.devices;
    final onlineCount = devices.where((d) => d.isActivelyOnline).length;
    final controlledCount = devices.where((d) => d.isControlledMode).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'WardHelm',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
            IconButton(
              onPressed: () => appState.navigateTo(AppView.agentKiosk),
              icon: const Icon(Icons.monitor_rounded),
              tooltip: 'شاشة حارس الجهاز (Agent Kiosk)',
            ),
          IconButton(
            onPressed: () => _showUpdateDialog(context),
            icon: const Icon(Icons.system_update_rounded),
            tooltip: 'فحص وجود تحديثات للنظام',
          ),
          ThemeToggleButton(
            isDarkMode: appState.isDarkMode,
            onToggle: appState.toggleTheme,
          ),
          IconButton(
            onPressed: () => deviceState.refreshDevices(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الحالة',
          ),
          IconButton(
            onPressed: () => appState.navigateTo(AppView.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
          ),
          IconButton(
            onPressed: () => onLogout != null ? onLogout!() : appState.lockDashboard(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'تسجيل الخروج',
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
              // Summary Fleet Metrics
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'إجمالي الأجهزة',
                      value: '${devices.length}',
                      icon: Icons.devices_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'متصل الآن',
                      value: '$onlineCount',
                      icon: Icons.wifi_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'جلسات مقيدة',
                      value: '$controlledCount',
                      icon: Icons.lock_clock_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Devices Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الحواسيب المتصلة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _openPairingDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('ربط جهاز جديد'),
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
                          color: AppColors.darkTextMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا يوجد أي حاسوب مرتبط بعد',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اضغط على زر ربط جهاز جديد وأدخل الرمز الظاهر على شاشة الحاسوب لبدء التحكم.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openPairingDialog(context),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('ربط أول جهاز الآن'),
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
        label: const Text('ربط جهاز'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                ),
                Icon(icon, color: color, size: 18),
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

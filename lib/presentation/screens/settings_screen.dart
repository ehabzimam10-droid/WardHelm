import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auto_updater_service.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

/// App settings and One-Click Auto-Updater screen
class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AutoUpdaterService _updater = AutoUpdaterService();
  final AuthService _auth = AuthService();

  bool _isCheckingUpdate = false;
  UpdateInfo? _updateInfo;
  String? _updateStatus;

  Future<void> _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = null;
    });

    final info = await _updater.checkForUpdates();
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateInfo = info;
        _updateStatus = info.hasUpdate
            ? 'يتوفر تحديث جديد: الإصدار ${info.latestVersion}'
            : 'أنت تعمل على أحدث إصدار (${info.currentVersion})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => widget.appState.navigateTo(AppView.dashboard),
        ),
        title: const Text('الإعدادات والتحديثات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Appearance & Theme Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المظهر والتخصيص', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('الوضع الليلي (Dark Mode)'),
                      subtitle: const Text('تصميم داكن مريح للعينين بنمط Slate Obsidian'),
                      value: widget.appState.isDarkMode,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) => widget.appState.toggleTheme(),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('لغة التطبيق'),
                      subtitle: Text(widget.appState.isArabic ? 'العربية' : 'English'),
                      trailing: TextButton(
                        onPressed: widget.appState.toggleLanguage,
                        child: Text(widget.appState.isArabic ? 'Switch to English' : 'التحويل للعربية'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // One-Click Auto-Updater Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.system_update_rounded, color: AppColors.info, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظام التحديث التلقائي الذكي',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'One-Click In-App Auto-Updater',
                              style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الإصدار الحالي: ${AppConstants.appVersion}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يتم فحص التحديثات مباشرة من مستودع GitHub الرسمي وتثبيتها دون فقدان أي إعدادات.',
                      style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                    ),
                    const SizedBox(height: 16),
                    if (_updateStatus != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: (_updateInfo?.hasUpdate ?? false)
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_updateInfo?.hasUpdate ?? false)
                                ? AppColors.warning.withOpacity(0.3)
                                : AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _updateStatus!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (_updateInfo?.hasUpdate ?? false)
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _isCheckingUpdate ? null : _checkUpdate,
                      icon: _isCheckingUpdate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: const Text('فحص وجود تحديث جديد الآن'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About WardHelm Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('حول المشروع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      'WardHelm - نظام الوصاية وإدارة وقفل الحواسيب عن بُعد عبر الجوال والسحابة.\n'
                      'تم بناؤه وتطويره بنظام بيئي موحد وسحابي متكامل.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _auth.logout();
                        widget.appState.lockDashboard();
                      },
                      icon: const Icon(Icons.lock_outline_rounded, color: AppColors.danger, size: 18),
                      label: const Text('قفل لوحة التحكم', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
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

  void _goBack() {
    widget.appState.navigateTo(AppView.dashboard);
  }

  Future<void> _checkUpdate(AppLocalizations loc) async {
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
            ? (widget.appState.isArabic
                ? 'يتوفر تحديث جديد: الإصدار ${info.latestVersion}'
                : 'New update available: v${info.latestVersion}')
            : (widget.appState.isArabic
                ? 'أنت تعمل على أحدث إصدار (${info.currentVersion})'
                : 'You are on the latest version (${info.currentVersion})');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(isArabic: widget.appState.isArabic);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              widget.appState.isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            tooltip: loc.backToDashboard,
            onPressed: _goBack,
          ),
          title: Text(
            widget.appState.isArabic ? 'الإعدادات والتحديثات' : 'Settings & Updates',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                      Text(
                        widget.appState.isArabic ? 'المظهر والتخصيص' : 'Appearance & Personalization',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(widget.appState.isArabic ? 'الوضع الليلي (Dark Mode)' : 'Dark Mode'),
                        subtitle: Text(
                          widget.appState.isArabic
                              ? 'تصميم داكن بنمط Slate Obsidian لحماية العينين'
                              : 'High-contrast obsidian theme for comfortable viewing',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        value: widget.appState.isDarkMode,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) => widget.appState.toggleTheme(),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(loc.language),
                        subtitle: Text(
                          widget.appState.isArabic ? 'العربية' : 'English',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.appState.isArabic ? 'نظام التحديث التلقائي الذكي' : 'Intelligent Auto-Updater',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'One-Click In-App Auto-Updater',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${loc.currentVersion}: v${AppConstants.appVersion}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.appState.isArabic
                            ? 'يتم فحص التحديثات مباشرة من مستودع GitHub الرسمي وتثبيتها دون فقدان أي إعدادات.'
                            : 'Updates are queried directly from official GitHub releases and installed seamlessly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
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
                        onPressed: _isCheckingUpdate ? null : () => _checkUpdate(loc),
                        icon: _isCheckingUpdate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          widget.appState.isArabic ? 'فحص وجود تحديث جديد الآن' : 'Check for Updates Now',
                        ),
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
                      Row(
                        children: [
                          Image.asset(
                            'assets/wardhelm_logo.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (_, _, _) => const Icon(Icons.shield_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.appState.isArabic ? 'حول المشروع' : 'About WardHelm',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.appDescription,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _auth.logout();
                          widget.appState.lockDashboard();
                        },
                        icon: const Icon(Icons.lock_outline_rounded, color: AppColors.danger, size: 18),
                        label: Text(
                          loc.logout,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

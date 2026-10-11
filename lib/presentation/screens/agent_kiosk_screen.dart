import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auto_updater_service.dart';
import '../../services/windows/windows_agent_controller.dart';
import '../../state/app_state.dart';
import '../widgets/circular_totp_timer.dart';
import '../widgets/countdown_timer_widget.dart';

/// Screen displayed when running directly on the Windows Agent PC
class AgentKioskScreen extends StatelessWidget {
  final WindowsAgentController agentController;
  final AppState appState;

  const AgentKioskScreen({
    super.key,
    required this.agentController,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final loc = appState.loc;
    final isPaired = agentController.isPaired;
    final session = agentController.activeSession;
    final isLocked = agentController.isKioskLocked;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Full Screen Prayer Pause Lock Screen
    if (isLocked) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.92),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 72,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.prayerPause,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                appState.isArabic
                    ? 'تم قفل الشاشة مؤقتاً لأداء الصلاة • تم إيقاف عداد الوقت وسيُستأنف لاحقاً'
                    : 'Screen is locked for prayer pause • Countdown timer is paused',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wardhelm_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.shield_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('${loc.appTitle} PC Agent', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appState.isArabic ? 'جارٍ فحص التحديثات للوكيل...' : 'Checking agent updates...')),
              );
              final info = await AutoUpdaterService().checkForUpdates();
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(info.hasUpdate
                      ? '${loc.updateAvailable}: v${info.latestVersion}'
                      : '${loc.upToDate} (v${info.currentVersion})'),
                  content: Text(info.hasUpdate
                      ? info.releaseNotes
                      : (appState.isArabic
                          ? 'ملفات الوكيل محدثة وتتزامن ذاتياً مع السحابة.'
                          : 'Agent binaries are up to date and cloud synced.')),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(loc.cancel)),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.system_update_rounded),
            tooltip: loc.checkUpdates,
          ),
          TextButton.icon(
            onPressed: () => appState.navigateTo(AppView.dashboard),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: Text(loc.dashboard),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPaired) ...[
                      // Dynamic 60s Pairing Screen
                      Text(
                        loc.pairingTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.pairingDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CircularTotpTimer(
                        code: agentController.currentPairingCode,
                        secondsRemaining: agentController.pairingSecondsLeft,
                      ),
                    ] else if (session != null && session.isActive) ...[
                      // Active Controlled Session
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.controlledMode,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CountdownTimerWidget(
                        remainingMinutes: session.remainingMinutes,
                        isPrayerPause: session.isPrayerPause,
                      ),
                      const SizedBox(height: 20),
                      if (session.isInternetBlocked)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  appState.isArabic
                                      ? 'تم قطع الإنترنت عن الألعاب والمتصفحات مؤقتاً'
                                      : 'Internet access is restricted for games & browsers',
                                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        session.isWhitelistMode
                            ? '${loc.allowedApps}: ${session.allowedApps.join(", ")}'
                            : '${loc.blockedApps}: ${session.blockedApps.join(", ")}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ] else ...[
                      // Linked in Owner Mode
                      Image.asset(
                        'assets/wardhelm_logo.png',
                        width: 72,
                        height: 72,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.success,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        agentController.deviceName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.ownerMode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.ownerModeDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

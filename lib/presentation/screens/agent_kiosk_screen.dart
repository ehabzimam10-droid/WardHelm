import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
    final isPaired = agentController.isPaired;
    final session = agentController.activeSession;
    final isLocked = agentController.isKioskLocked;

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
              const Text(
                'استراحة الصلاة',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'تم قفل الشاشة مؤقتاً لأداء الصلاة • تم إيقاف عداد الوقت وسيُستأنف لاحقاً',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WardHelm PC Agent'),
        actions: [
          TextButton.icon(
            onPressed: () => appState.navigateTo(AppView.dashboard),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text('لوحة التحكم'),
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
                      const Text(
                        'ربط هذا الحاسوب بحسابك',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'أدخل الرمز التالي في جوالك أو لوحة التحكم لربط الجهاز فوراً:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted),
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
                          const Text(
                            'جلسة لعب مقيدة نشطة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          child: const Row(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'تم قطع الإنترنت عن الألعاب والمتصفحات مؤقتاً',
                                  style: TextStyle(fontSize: 12, color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'البرامج المسموحة: ${session.allowedApps.join(", ")}',
                        style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                      ),
                    ] else ...[
                      // Linked in Owner Mode
                      Container(
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
                      const SizedBox(height: 20),
                      Text(
                        agentController.deviceName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'وضع المالك الحر (Unrestricted Owner Mode)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'هذا الحاسوب غير مقيد حالياً. يمكنك تفعيل جلسة للأخ من خلال لوحة التحكم في الجوال عند الطلب.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted),
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

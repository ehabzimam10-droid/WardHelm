import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/session_model.dart';

/// Control panel containing the 5 live quick action buttons
class SessionControlPanel extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onPrayerToggle;
  final VoidCallback onExtend15;
  final VoidCallback onExtend30;
  final VoidCallback onKillswitchToggle;
  final VoidCallback onEndSession;

  const SessionControlPanel({
    super.key,
    required this.session,
    required this.onPrayerToggle,
    required this.onExtend15,
    required this.onExtend30,
    required this.onKillswitchToggle,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Row: Prayer Pause & Internet Killswitch
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: session.isPrayerPause
                    ? Icons.play_arrow_rounded
                    : Icons.pause_circle_filled_rounded,
                title: session.isPrayerPause ? 'استئناف اللعب' : 'استراحة الصلاة',
                subtitle: session.isPrayerPause ? 'فك قفل الشاشة' : 'قفل مؤقت للشاشة',
                color: session.isPrayerPause ? AppColors.success : AppColors.warning,
                onTap: onPrayerToggle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: session.isInternetBlocked
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                title: session.isInternetBlocked ? 'إعادة الإنترنت' : 'قطع النت اللحظي',
                subtitle: session.isInternetBlocked ? 'استعادة الاتصال' : 'زر طوارئ فوري',
                color: session.isInternetBlocked ? AppColors.info : AppColors.danger,
                onTap: onKillswitchToggle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Middle Row: Time Extension (+15 & +30)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExtend15,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('+15 دقيقة إضافية'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExtend30,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('+30 دقيقة إضافية'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bottom Row: End Session
        ElevatedButton.icon(
          onPressed: onEndSession,
          icon: const Icon(Icons.stop_circle_rounded, size: 20),
          label: const Text('إنهاء الجلسة واستعادة وضع المالك الحر'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

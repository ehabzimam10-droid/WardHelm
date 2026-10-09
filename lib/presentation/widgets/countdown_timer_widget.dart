import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Clean countdown timer card for active sessions
class CountdownTimerWidget extends StatelessWidget {
  final int remainingMinutes;
  final bool isPaused;
  final bool isPrayerPause;
  final VoidCallback? onPrayerToggle;

  const CountdownTimerWidget({
    super.key,
    required this.remainingMinutes,
    this.isPaused = false,
    this.isPrayerPause = false,
    this.onPrayerToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.success;
    if (isPrayerPause) {
      statusColor = AppColors.warning;
    } else if (remainingMinutes <= 3) {
      statusColor = AppColors.danger;
    } else if (remainingMinutes <= 10) {
      statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPrayerPause ? Icons.pause_circle_filled_rounded : Icons.timer_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPrayerPause ? 'استراحة الصلاة (موقوف مؤقتاً)' : 'الوقت المتبقي',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (onPrayerToggle != null)
                IconButton(
                  onPressed: onPrayerToggle,
                  icon: Icon(
                    isPrayerPause ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: statusColor,
                  ),
                  tooltip: isPrayerPause ? 'استئناف' : 'إيقاف للصلاة',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$remainingMinutes دقيقة',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

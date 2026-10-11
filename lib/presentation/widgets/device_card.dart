import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/device_model.dart';

/// Card showing device fleet status and mode
class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.isActivelyOnline;
    final isOwner = device.isOwnerMode;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onlineText = isRtl
        ? (isOnline ? "متصل الآن" : "غير متصل")
        : (isOnline ? "Online Now" : "Offline");

    final modeBadgeText = isRtl
        ? (isOwner ? "وضع المالك الحر" : "جلسة مقيدة")
        : (isOwner ? "Owner Mode" : "Controlled Session");

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Online Indicator & Device Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.success.withOpacity(0.12)
                      : (isDark ? AppColors.darkBorder.withOpacity(0.4) : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.desktop_windows_rounded,
                  color: isOnline ? AppColors.success : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.success : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.os} • $onlineText',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Mode Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOwner
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOwner
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  modeBadgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOwner ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Smooth theme mode toggle button
class ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ThemeToggleButton({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isDarkMode ? AppColors.warning : AppColors.primary,
      ),
      tooltip: isDarkMode
          ? (isRtl ? 'التحويل للوضع الفاتح' : 'Switch to Light Mode')
          : (isRtl ? 'التحويل للوضع الداكن' : 'Switch to Dark Mode'),
    );
  }
}

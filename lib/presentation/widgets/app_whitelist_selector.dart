import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Interactive selector for session application whitelisting
class AppWhitelistSelector extends StatefulWidget {
  final List<String> selectedApps;
  final ValueChanged<List<String>> onChanged;

  const AppWhitelistSelector({
    super.key,
    required this.selectedApps,
    required this.onChanged,
  });

  @override
  State<AppWhitelistSelector> createState() => _AppWhitelistSelectorState();
}

class _AppWhitelistSelectorState extends State<AppWhitelistSelector> {
  final TextEditingController _customExeController = TextEditingController();

  void _togglePreset(List<String> presetApps) {
    final current = List<String>.from(widget.selectedApps);
    final allIn = presetApps.every((a) => current.contains(a));

    if (allIn) {
      current.removeWhere((a) => presetApps.contains(a));
    } else {
      for (final a in presetApps) {
        if (!current.contains(a)) current.add(a);
      }
    }
    widget.onChanged(current);
  }

  void _addCustomExe() {
    final text = _customExeController.text.trim();
    if (text.isEmpty) return;

    final exeName = text.endsWith('.exe') ? text : '$text.exe';
    final current = List<String>.from(widget.selectedApps);
    if (!current.contains(exeName)) {
      current.add(exeName);
      widget.onChanged(current);
    }
    _customExeController.clear();
  }

  void _removeApp(String app) {
    final current = List<String>.from(widget.selectedApps);
    current.remove(app);
    widget.onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final isRobloxActive = AppConstants.defaultRobloxProcesses
        .every((a) => widget.selectedApps.contains(a));
    final isUtilityActive = AppConstants.defaultUtilityProcesses
        .every((a) => widget.selectedApps.contains(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التطبيقات المسموح بتشغيلها أثناء الجلسة',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        // Quick Preset Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: isRobloxActive,
              label: const Text('🎮 ألعاب روبلوكس (Roblox)'),
              onSelected: (_) => _togglePreset(AppConstants.defaultRobloxProcesses),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
            ),
            FilterChip(
              selected: isUtilityActive,
              label: const Text('📝 الآلة الحاسبة والمفكرة'),
              onSelected: (_) => _togglePreset(AppConstants.defaultUtilityProcesses),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Custom Exe Input Field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customExeController,
                decoration: const InputDecoration(
                  hintText: 'إضافة برنامج مخصص (مثال: game.exe)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addCustomExe(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addCustomExe,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'إضافة للائحة',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected Chips
        if (widget.selectedApps.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedApps.map((app) {
              return Chip(
                label: Text(app, style: const TextStyle(fontSize: 12)),
                onDeleted: () => _removeApp(app),
                deleteIconColor: AppColors.danger,
                side: const BorderSide(color: AppColors.darkBorder),
              );
            }).toList(),
          ),
      ],
    );
  }
}

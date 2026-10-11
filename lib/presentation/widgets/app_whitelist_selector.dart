import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class _AppEntry {
  final String process;
  final String nameAr;
  final String nameEn;
  final String category;
  final IconData icon;

  const _AppEntry({
    required this.process,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.icon,
  });
}

/// Production-grade smart application selector supporting Whitelist & Blacklist modes,
/// dynamic PC-discovered apps, search, category filters, and bulk selection.
class SmartAppSelector extends StatefulWidget {
  final String filterMode; // 'whitelist' or 'blacklist'
  final ValueChanged<String> onFilterModeChanged;
  final List<String> selectedApps;
  final ValueChanged<List<String>> onAppsChanged;
  final List<String> deviceInstalledApps;
  final bool isArabic;

  const SmartAppSelector({
    super.key,
    required this.filterMode,
    required this.onFilterModeChanged,
    required this.selectedApps,
    required this.onAppsChanged,
    this.deviceInstalledApps = const [],
    this.isArabic = true,
  });

  @override
  State<SmartAppSelector> createState() => _SmartAppSelectorState();
}

class _SmartAppSelectorState extends State<SmartAppSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customExeController = TextEditingController();
  String _selectedCategory = 'all';

  static const List<_AppEntry> _knownApps = [
    // Games
    _AppEntry(process: 'RobloxPlayerBeta.exe', nameAr: 'روبلوكس (Roblox)', nameEn: 'Roblox', category: 'games', icon: Icons.sports_esports_rounded),
    _AppEntry(process: 'Minecraft.exe', nameAr: 'ماين كرافت (Minecraft)', nameEn: 'Minecraft', category: 'games', icon: Icons.videogame_asset_rounded),
    _AppEntry(process: 'steam.exe', nameAr: 'منصة ستيم (Steam)', nameEn: 'Steam Platform', category: 'games', icon: Icons.sports_esports_outlined),
    _AppEntry(process: 'EpicGamesLauncher.exe', nameAr: 'إيبك جيمز (Epic Games)', nameEn: 'Epic Games Launcher', category: 'games', icon: Icons.gamepad_rounded),
    _AppEntry(process: 'VALORANT.exe', nameAr: 'فالورانت (Valorant)', nameEn: 'Valorant', category: 'games', icon: Icons.sports_esports_rounded),
    // Social
    _AppEntry(process: 'Discord.exe', nameAr: 'ديسكورد (Discord)', nameEn: 'Discord', category: 'social', icon: Icons.forum_rounded),
    _AppEntry(process: 'Telegram.exe', nameAr: 'تيليجرام (Telegram)', nameEn: 'Telegram', category: 'social', icon: Icons.send_rounded),
    _AppEntry(process: 'WhatsApp.exe', nameAr: 'واتساب (WhatsApp)', nameEn: 'WhatsApp', category: 'social', icon: Icons.chat_rounded),
    // Browsers
    _AppEntry(process: 'chrome.exe', nameAr: 'جوجل كروم (Chrome)', nameEn: 'Google Chrome', category: 'browsers', icon: Icons.language_rounded),
    _AppEntry(process: 'msedge.exe', nameAr: 'مايكروسوفت إيدج (Edge)', nameEn: 'Microsoft Edge', category: 'browsers', icon: Icons.public_rounded),
    _AppEntry(process: 'firefox.exe', nameAr: 'فايرفوكس (Firefox)', nameEn: 'Mozilla Firefox', category: 'browsers', icon: Icons.travel_explore_rounded),
    _AppEntry(process: 'brave.exe', nameAr: 'متصفح بريف (Brave)', nameEn: 'Brave Browser', category: 'browsers', icon: Icons.security_rounded),
    // Tools
    _AppEntry(process: 'notepad.exe', nameAr: 'المفكرة (Notepad)', nameEn: 'Notepad', category: 'tools', icon: Icons.edit_note_rounded),
    _AppEntry(process: 'calc.exe', nameAr: 'الآلة الحاسبة (Calc)', nameEn: 'Calculator', category: 'tools', icon: Icons.calculate_rounded),
    _AppEntry(process: 'mspaint.exe', nameAr: 'الرسام (Paint)', nameEn: 'Paint', category: 'tools', icon: Icons.palette_rounded),
    _AppEntry(process: 'WINWORD.EXE', nameAr: 'مايكروسوفت وورد (Word)', nameEn: 'Microsoft Word', category: 'tools', icon: Icons.description_rounded),
    _AppEntry(process: 'EXCEL.EXE', nameAr: 'مايكروسوفت إكسل (Excel)', nameEn: 'Microsoft Excel', category: 'tools', icon: Icons.table_chart_rounded),
  ];

  List<_AppEntry> _getAllAppEntries() {
    final list = List<_AppEntry>.from(_knownApps);
    final knownProcesses = _knownApps.map((a) => a.process.toLowerCase()).toSet();

    // Dynamically integrate apps detected on the physical PC
    for (final rawApp in widget.deviceInstalledApps) {
      final cleanProcess = rawApp.trim();
      if (cleanProcess.isEmpty) continue;
      final exe = cleanProcess.toLowerCase().endsWith('.exe') ? cleanProcess : '$cleanProcess.exe';
      if (!knownProcesses.contains(exe.toLowerCase())) {
        knownProcesses.add(exe.toLowerCase());
        list.add(
          _AppEntry(
            process: exe,
            nameAr: cleanProcess.replaceAll(RegExp(r'\.exe$', caseSensitive: false), ''),
            nameEn: cleanProcess.replaceAll(RegExp(r'\.exe$', caseSensitive: false), ''),
            category: 'detected',
            icon: Icons.computer_rounded,
          ),
        );
      }
    }

    // Also include any custom apps already in selectedApps
    for (final sel in widget.selectedApps) {
      if (!knownProcesses.contains(sel.toLowerCase())) {
        knownProcesses.add(sel.toLowerCase());
        list.add(
          _AppEntry(
            process: sel,
            nameAr: sel.replaceAll(RegExp(r'\.exe$', caseSensitive: false), ''),
            nameEn: sel,
            category: 'tools',
            icon: Icons.apps_rounded,
          ),
        );
      }
    }

    return list;
  }

  void _toggleApp(String process) {
    final current = List<String>.from(widget.selectedApps);
    if (current.contains(process)) {
      current.remove(process);
    } else {
      current.add(process);
    }
    widget.onAppsChanged(current);
  }

  void _selectAll(List<_AppEntry> visibleEntries) {
    final current = List<String>.from(widget.selectedApps);
    for (final entry in visibleEntries) {
      if (!current.contains(entry.process)) {
        current.add(entry.process);
      }
    }
    widget.onAppsChanged(current);
  }

  void _deselectAll(List<_AppEntry> visibleEntries) {
    final current = List<String>.from(widget.selectedApps);
    for (final entry in visibleEntries) {
      current.remove(entry.process);
    }
    widget.onAppsChanged(current);
  }

  void _invertSelection(List<_AppEntry> visibleEntries) {
    final current = List<String>.from(widget.selectedApps);
    for (final entry in visibleEntries) {
      if (current.contains(entry.process)) {
        current.remove(entry.process);
      } else {
        current.add(entry.process);
      }
    }
    widget.onAppsChanged(current);
  }

  void _addCustomApp() {
    final text = _customExeController.text.trim();
    if (text.isEmpty) return;
    final exe = text.toLowerCase().endsWith('.exe') ? text : '$text.exe';
    final current = List<String>.from(widget.selectedApps);
    if (!current.contains(exe)) {
      current.add(exe);
      widget.onAppsChanged(current);
    }
    _customExeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(isArabic: widget.isArabic);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allEntries = _getAllAppEntries();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allEntries.where((entry) {
      if (_selectedCategory != 'all' && entry.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesProcess = entry.process.toLowerCase().contains(query);
        final matchesAr = entry.nameAr.toLowerCase().contains(query);
        final matchesEn = entry.nameEn.toLowerCase().contains(query);
        if (!matchesProcess && !matchesAr && !matchesEn) return false;
      }
      return true;
    }).toList();

    final isWhitelist = widget.filterMode == 'whitelist';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector (Whitelist vs Blacklist)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => widget.onFilterModeChanged('whitelist'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isWhitelist ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      loc.filterModeWhitelist,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isWhitelist
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => widget.onFilterModeChanged('blacklist'),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isWhitelist ? AppColors.danger : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      loc.filterModeBlacklist,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !isWhitelist
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Explanatory note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isWhitelist ? AppColors.primary : AppColors.danger).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (isWhitelist ? AppColors.primary : AppColors.danger).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isWhitelist ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                size: 16,
                color: isWhitelist ? AppColors.primary : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isWhitelist ? loc.whitelistDesc : loc.blacklistDesc,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar & Add Custom Exe
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: loc.searchAppsHint,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', loc.catAll, isDark),
              const SizedBox(width: 6),
              _buildCategoryChip('games', loc.catGames, isDark),
              const SizedBox(width: 6),
              _buildCategoryChip('social', loc.catSocial, isDark),
              const SizedBox(width: 6),
              _buildCategoryChip('browsers', loc.catBrowsers, isDark),
              const SizedBox(width: 6),
              _buildCategoryChip('tools', loc.catTools, isDark),
              if (widget.deviceInstalledApps.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildCategoryChip('detected', loc.catDetected, isDark),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Bulk Action Buttons (Select All, Deselect All, Invert)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${isWhitelist ? loc.allowedApps : loc.blockedApps}: ${widget.selectedApps.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWhitelist ? AppColors.primary : AppColors.danger,
              ),
            ),
            Row(
              children: [
                _buildQuickActionBtn(loc.selectAll, () => _selectAll(filtered), isDark),
                const SizedBox(width: 6),
                _buildQuickActionBtn(loc.deselectAll, () => _deselectAll(filtered), isDark),
                const SizedBox(width: 6),
                _buildQuickActionBtn(loc.invertSelection, () => _invertSelection(filtered), isDark),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Apps Grid / List with High-Contrast Theming
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              loc.noAppsFound,
              style: const TextStyle(fontSize: 13, color: AppColors.darkTextMuted),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((entry) {
              final isSelected = widget.selectedApps.contains(entry.process);
              final activeColor = isWhitelist ? AppColors.primary : AppColors.danger;

              return InkWell(
                onTap: () => _toggleApp(entry.process),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withOpacity(isDark ? 0.22 : 0.12)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.icon,
                        size: 16,
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isArabic ? entry.nameAr : entry.nameEn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : activeColor)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: activeColor,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 14),

        // Add Custom Exe row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customExeController,
                decoration: InputDecoration(
                  hintText: loc.customAppHint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _addCustomApp(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addCustomApp,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(loc.add, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String catKey, String label, bool isDark) {
    final isSelected = _selectedCategory == catKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = catKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }
}

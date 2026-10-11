import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/device_model.dart';
import '../../state/app_state.dart';
import '../../state/device_state.dart';
import '../../state/session_state.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/session_control_panel.dart';
import '../widgets/app_whitelist_selector.dart';

/// Screen for controlling a specific device and launching/managing sessions
class DeviceDetailScreen extends StatefulWidget {
  final DeviceModel device;
  final AppState appState;
  final DeviceState deviceState;
  final SessionState sessionState;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.appState,
    required this.deviceState,
    required this.sessionState,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  int _selectedDuration = 30;
  String _filterMode = 'whitelist';
  List<String> _selectedApps = List.from(AppConstants.defaultRobloxProcesses);
  bool _isUpdatingDevice = false;
  bool _isUnpairing = false;

  void _goBack() {
    widget.sessionState.stopWatcher();
    widget.appState.navigateTo(AppView.dashboard);
    widget.deviceState.deselectDevice();
  }

  Future<void> _handleUnpairDevice(DeviceModel dev, AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.confirmUnpairTitle)),
          ],
        ),
        content: Text(loc.confirmUnpairMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.link_off_rounded),
            label: Text(loc.unpairDevice),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUnpairing = true);
      final success = await widget.deviceState.unpairAndWipeDevice(dev.id);
      if (!mounted) return;
      setState(() => _isUnpairing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.success : AppColors.danger,
          content: Text(success ? loc.unpairSuccess : loc.unpairFailed),
        ),
      );

      if (success) {
        _goBack();
      }
    }
  }

  Future<void> _triggerRemoteUpdate(DeviceModel dev, AppLocalizations loc) async {
    setState(() => _isUpdatingDevice = true);
    final success = await widget.deviceState.triggerDeviceUpdate(dev.id);
    if (!mounted) return;
    setState(() => _isUpdatingDevice = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.danger,
        content: Text(success ? loc.updateAgentSuccess : loc.updateAgentFail),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.device.isControlledMode && widget.device.activeSessionId != null) {
      widget.sessionState.startSessionWatcher(
        widget.device.activeSessionId!,
        widget.device.id,
      );
    } else {
      widget.sessionState.loadLogs(widget.device.id);
    }
  }

  Future<void> _startSession() async {
    final success = await widget.sessionState.startNewSession(
      deviceId: widget.device.id,
      durationMinutes: _selectedDuration,
      allowedApps: _filterMode == 'whitelist' ? _selectedApps : const [],
      filterMode: _filterMode,
      blockedApps: _filterMode == 'blacklist' ? _selectedApps : const [],
    );
    if (success) {
      await widget.deviceState.refreshDevices(silent: true);
    }
  }

  Future<void> _endSession(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.confirmEndSessionTitle),
        content: Text(loc.confirmEndSessionMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.endSessionNow),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.sessionState.endSession();
      await widget.deviceState.refreshDevices(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(isArabic: widget.appState.isArabic);
    final dev = widget.deviceState.devices.firstWhere(
      (d) => d.id == widget.device.id,
      orElse: () => widget.device,
    );
    final session = widget.sessionState.activeSession;
    final isControlled = dev.isControlledMode && session != null && session.isActive;
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
          title: Text(dev.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.link_off_rounded, color: AppColors.danger),
              tooltip: loc.unpairDevice,
              onPressed: _isUnpairing ? null : () => _handleUnpairDevice(dev, loc),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: dev.isActivelyOnline
                    ? AppColors.success.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dev.isActivelyOnline ? AppColors.success : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dev.isActivelyOnline ? loc.online : loc.offline,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dev.isActivelyOnline ? AppColors.success : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clear Top Breadcrumb / Return Action
              Align(
                alignment: widget.appState.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _goBack,
                  icon: Icon(
                    widget.appState.isArabic
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    size: 18,
                  ),
                  label: Text(
                    loc.backToDashboard,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Mode Banner
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isControlled
                              ? AppColors.warning.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isControlled ? Icons.lock_clock_rounded : Icons.shield_rounded,
                          color: isControlled ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isControlled ? loc.controlledMode : loc.ownerMode,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isControlled ? loc.controlledModeDesc : loc.ownerModeDesc,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Active Session Controls OR Session Launcher
              if (isControlled) ...[
                CountdownTimerWidget(
                  remainingMinutes: session.remainingMinutes,
                  isPrayerPause: session.isPrayerPause,
                  onPrayerToggle: () => widget.sessionState.togglePrayerPause(),
                ),
                const SizedBox(height: 16),
                SessionControlPanel(
                  session: session,
                  onPrayerToggle: () => widget.sessionState.togglePrayerPause(),
                  onExtend15: () => widget.sessionState.extendTime(15),
                  onExtend30: () => widget.sessionState.extendTime(30),
                  onKillswitchToggle: () => widget.sessionState.toggleKillswitch(),
                  onEndSession: () => _endSession(loc),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.startSession,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Duration Selector
                        Text(
                          loc.durationMinutes,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [15, 30, 45, 60, 90].map((mins) {
                            final isSelected = _selectedDuration == mins;
                            return ChoiceChip(
                              label: Text(widget.appState.isArabic ? '$mins دقيقة' : '$mins Min'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedDuration = mins),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Smart App Selector (Whitelist vs Blacklist)
                        SmartAppSelector(
                          filterMode: _filterMode,
                          onFilterModeChanged: (mode) => setState(() => _filterMode = mode),
                          selectedApps: _selectedApps,
                          onAppsChanged: (apps) => setState(() => _selectedApps = apps),
                          deviceInstalledApps: dev.installedApps,
                          isArabic: widget.appState.isArabic,
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.sessionState.isLoading ? null : _startSession,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              widget.appState.isArabic
                                  ? 'بدء الجلسة وتطبيق القيود فوراً'
                                  : 'Start Session & Apply Guard Now',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Agent Version & Auto-Updater Section
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
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.appState.isArabic
                                      ? 'تحديثات برنامج الوكيل (Agent Auto-Updater)'
                                      : 'Agent Auto-Updater',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.appState.isArabic
                                      ? 'التحكم بنسخة البرنامج والتحديث التلقائي عن بُعد'
                                      : 'Remote fleet version control & automatic update',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'v${dev.version}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.appState.isArabic
                            ? 'الوكيل مزود بنظام التحديث الذاتي التلقائي. عند الضغط أدناه سيتم إرسال إشعار فوري للبيسي ليقوم بتحميل أحدث ملف تنفيذي وتثبيته وإعادة تشغيل نفسه دون مقاطعة.'
                            : 'The agent features autonomous self-updating. Triggering an update commands the remote PC to download and install the latest binary seamlessly.',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUpdatingDevice ? null : () => _triggerRemoteUpdate(dev, loc),
                          icon: _isUpdatingDevice
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync_rounded),
                          label: Text(
                            _isUpdatingDevice
                                ? (widget.appState.isArabic ? 'جارٍ إرسال أمر التحديث...' : 'Sending update command...')
                                : (widget.appState.isArabic ? 'فحص وتحديث برنامج هذا البيسي الآن' : 'Check & Update This PC Now'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Security Audit Logs Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.securityLogs,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            onPressed: () => widget.sessionState.loadLogs(widget.device.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.sessionState.logs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              loc.noLogs,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ...widget.sessionState.logs.take(10).map((log) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  log.eventType == 'process_terminated'
                                      ? Icons.block_flipped
                                      : Icons.info_outline_rounded,
                                  color: log.eventType == 'process_terminated'
                                      ? AppColors.danger
                                      : AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    log.details,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Danger Zone: Unpair & Wipe Device
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.danger.withOpacity(0.4), width: 1.2),
                ),
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
                              color: AppColors.danger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.link_off_rounded, color: AppColors.danger, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.unpairDevice,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.unpairDeviceDesc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          onPressed: _isUnpairing ? null : () => _handleUnpairDevice(dev, loc),
                          icon: _isUnpairing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                                )
                              : const Icon(Icons.delete_forever_rounded),
                          label: Text(loc.unpairDevice),
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

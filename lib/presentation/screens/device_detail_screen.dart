import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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
  List<String> _selectedApps = List.from(AppConstants.defaultRobloxProcesses);

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
      allowedApps: _selectedApps,
    );
    if (success) {
      await widget.deviceState.refreshDevices(silent: true);
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة المقيدة'),
        content: const Text('هل أنت متأكد من إنهاء الجلسة واستعادة وضع المالك الحر فوراً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إنهاء الجلسة الآن'),
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
    final dev = widget.deviceState.devices.firstWhere(
      (d) => d.id == widget.device.id,
      orElse: () => widget.device,
    );
    final session = widget.sessionState.activeSession;
    final isControlled = dev.isControlledMode && session != null && session.isActive;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => widget.appState.navigateTo(AppView.dashboard),
        ),
        title: Text(dev.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
                  dev.isActivelyOnline ? 'متصل' : 'غير متصل',
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
                            isControlled ? 'جلسة مقيدة نشطة' : 'وضع المالك الحر (Owner Mode)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isControlled
                                ? 'يتم فرض قيود الوقت والتطبيقات والإنترنت على الحاسوب'
                                : 'الحاسوب مفتوح وطبيعي 100% بدون أي قيود أو مراقبة',
                            style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
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
                onEndSession: _endSession,
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بدء جلسة مقيدة جديدة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Duration Selector
                      const Text(
                        'تحديد مدة الجلسة',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [15, 30, 45, 60, 90].map((mins) {
                          final isSelected = _selectedDuration == mins;
                          return ChoiceChip(
                            label: Text('$mins دقيقة'),
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

                      // Whitelist Selector
                      AppWhitelistSelector(
                        selectedApps: _selectedApps,
                        onChanged: (apps) => setState(() => _selectedApps = apps),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.sessionState.isLoading ? null : _startSession,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('بدء الجلسة وتطبيق القيود فوراً'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                        const Text(
                          'سجل الأمان والتنبيهات الحية',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: () => widget.sessionState.loadLogs(widget.device.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.sessionState.logs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'لا توجد أحداث مسجلة بعد',
                            style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
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
          ],
        ),
      ),
    );
  }
}

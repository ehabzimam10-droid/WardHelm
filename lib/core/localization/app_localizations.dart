/// Simple lightweight localization provider for WardHelm (Arabic & English)
class AppLocalizations {
  final bool isArabic;

  const AppLocalizations({this.isArabic = true});

  String get appTitle => isArabic ? 'وارد هيلم' : 'WardHelm';
  String get appSubtitle => isArabic
      ? 'نظام الوصاية وإدارة وقفل الحواسيب عن بُعد'
      : 'Autonomous Cloud Guardian & PC Fleet Controller';

  // Navigation & Headers
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get devices => isArabic ? 'الأجهزة المتصلة' : 'Connected Devices';
  String get addDevice => isArabic ? 'ربط جهاز جديد' : 'Pair New Device';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get autoUpdater => isArabic ? 'التحديث التلقائي' : 'Auto Updater';

  // Modes
  String get ownerMode => isArabic ? 'وضع المالك الحر' : 'Owner Mode';
  String get controlledMode => isArabic ? 'جلسة مقيدة نشطة' : 'Controlled Session';
  String get offline => isArabic ? 'غير متصل' : 'Offline';
  String get online => isArabic ? 'متصل الآن' : 'Online';

  // Pairing
  String get pairingTitle => isArabic ? 'رمز الربط الذكي' : 'Dynamic Pairing Code';
  String get pairingDesc => isArabic
      ? 'أدخل الرمز التالي في جوالك أو لوحة التحكم لربط هذا الحاسوب بحسابك:'
      : 'Enter this 10-character code in your dashboard to claim this device:';
  String get pairingExpiresIn => isArabic ? 'يتجدد خلال' : 'Refreshes in';
  String get seconds => isArabic ? 'ثانية' : 'sec';
  String get enterCode => isArabic ? 'أدخل رمز الربط' : 'Enter Pairing Code';
  String get pairButton => isArabic ? 'تأكيد الربط فوراً' : 'Pair Device Now';

  // Controls
  String get prayerPause => isArabic ? 'استراحة الصلاة' : 'Prayer Pause';
  String get resumeSession => isArabic ? 'استئناف الجلسة' : 'Resume Session';
  String get extend15 => isArabic ? '+15 دقيقة' : '+15 Min';
  String get extend30 => isArabic ? '+30 دقيقة' : '+30 Min';
  String get killInternet => isArabic ? 'قطع النت اللحظي' : 'Kill Internet';
  String get restoreInternet => isArabic ? 'إعادة الإنترنت' : 'Restore Internet';
  String get endSession => isArabic ? 'إنهاء الجلسة' : 'End Session';
  String get startSession => isArabic ? 'بدء جلسة لعب' : 'Start Session';

  // Form & Labels
  String get durationMinutes => isArabic ? 'مدة الجلسة (بالدقائق)' : 'Duration (Minutes)';
  String get allowedApps => isArabic ? 'التطبيقات المسموحة' : 'Allowed Applications';
  String get securityLogs => isArabic ? 'سجل الأمان والتنبيهات' : 'Security Logs';
  String get deviceName => isArabic ? 'اسم الجهاز' : 'Device Name';
  String get confirmEndSession => isArabic
      ? 'هل أنت متأكد من إنهاء الجلسة واستعادة الوضع الحر؟'
      : 'Are you sure you want to end session and unlock PC?';

  // Messages
  String get successPairing => isArabic ? 'تم ربط الجهاز بنجاح!' : 'Device paired successfully!';
  String get invalidCode => isArabic ? 'رمز الربط غير صالح أو منتهي الصلاحية' : 'Invalid or expired code';
  String get updateAvailable => isArabic ? 'يوجد تحديث جديد متاح' : 'New update available';
  String get upToDate => isArabic ? 'أنت على أحدث إصدار بالفعل' : 'Up to date';
  String get checkUpdates => isArabic ? 'فحص التحديثات الآن' : 'Check for Updates';
}

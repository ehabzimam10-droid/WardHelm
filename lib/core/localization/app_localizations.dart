/// Comprehensive bilingual localization provider for WardHelm (Arabic & English)
class AppLocalizations {
  final bool isArabic;

  const AppLocalizations({this.isArabic = true});

  // App Identity
  String get appTitle => isArabic ? 'وارد هيلم' : 'WardHelm';
  String get appSubtitle => isArabic
      ? 'نظام الوصاية وإدارة وقفل الحواسيب عن بُعد'
      : 'Autonomous Cloud Guardian & PC Fleet Controller';
  String get appDescription => isArabic
      ? 'حماية سحابية متقدمة وتحكم لحظي في أجهزة الكمبيوتر عن بُعد مع عزل كامل للخصوصية'
      : 'Advanced cloud-based guardian and instant remote PC fleet controller with complete privacy isolation';

  // Navigation & Actions
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get devices => isArabic ? 'الأجهزة المتصلة' : 'Connected Devices';
  String get addDevice => isArabic ? 'ربط جهاز جديد' : 'Pair New Device';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get autoUpdater => isArabic ? 'التحديث التلقائي' : 'Auto Updater';
  String get checkUpdates => isArabic ? 'فحص وجود تحديثات' : 'Check for Updates';
  String get refresh => isArabic ? 'تحديث الحالة' : 'Refresh';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Sign Out';
  String get backToDashboard => isArabic ? 'رجوع للوحة التحكم' : 'Back to Dashboard';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get search => isArabic ? 'بحث...' : 'Search...';

  // Fleet & Status
  String get totalDevices => isArabic ? 'إجمالي الأجهزة' : 'Total Devices';
  String get onlineNow => isArabic ? 'متصل الآن' : 'Online Now';
  String get controlledSessions => isArabic ? 'جلسات مقيدة' : 'Controlled Sessions';
  String get online => isArabic ? 'متصل' : 'Online';
  String get offline => isArabic ? 'غير متصل' : 'Offline';
  String get ownerMode => isArabic ? 'وضع المالك الحر (Owner Mode)' : 'Owner Mode (Unrestricted)';
  String get controlledMode => isArabic ? 'جلسة مقيدة نشطة' : 'Controlled Session Active';
  String get ownerModeDesc => isArabic
      ? 'الحاسوب مفتوح وطبيعي 100% بدون أي قيود أو مراقبة'
      : 'PC is 100% normal with zero restrictions or monitoring';
  String get controlledModeDesc => isArabic
      ? 'يتم فرض قيود الوقت والتطبيقات والإنترنت على الحاسوب'
      : 'Enforcing time limits, application guard, and network restrictions';
  String get noDevicesTitle => isArabic ? 'لا يوجد أي حاسوب مرتبط بعد' : 'No computers paired yet';
  String get noDevicesDesc => isArabic
      ? 'اضغط على زر ربط جهاز جديد وأدخل الرمز الظاهر على شاشة الحاسوب لبدء التحكم.'
      : 'Click Pair New Device and enter the code shown on the PC screen to start controlling.';
  String get pairFirstDevice => isArabic ? 'ربط أول جهاز الآن' : 'Pair First Device Now';

  // Session Control
  String get startSession => isArabic ? 'بدء جلسة لعب' : 'Start Session';
  String get endSession => isArabic ? 'إنهاء الجلسة' : 'End Session';
  String get endSessionNow => isArabic ? 'إنهاء الجلسة الآن' : 'End Session Now';
  String get prayerPause => isArabic ? 'استراحة الصلاة' : 'Prayer Pause';
  String get resumeSession => isArabic ? 'استئناف الجلسة' : 'Resume Session';
  String get extend15 => isArabic ? '+15 دقيقة' : '+15 Min';
  String get extend30 => isArabic ? '+30 دقيقة' : '+30 Min';
  String get killInternet => isArabic ? 'قطع النت اللحظي' : 'Kill Internet';
  String get restoreInternet => isArabic ? 'إعادة الإنترنت' : 'Restore Internet';
  String get durationMinutes => isArabic ? 'مدة الجلسة (بالدقائق)' : 'Session Duration (Minutes)';
  String get confirmEndSessionTitle => isArabic ? 'إنهاء الجلسة المقيدة' : 'End Controlled Session';
  String get confirmEndSessionMsg => isArabic
      ? 'هل أنت متأكد من إنهاء الجلسة واستعادة وضع المالك الحر فوراً؟'
      : 'Are you sure you want to end the session and unlock the PC immediately?';
  String get confirmLogoutTitle => isArabic ? 'تسجيل الخروج' : 'Sign Out';
  String get confirmLogoutMsg => isArabic
      ? 'هل تريد تسجيل الخروج من لوحة التحكم وقفل الوصول؟'
      : 'Do you want to sign out and lock access to this dashboard?';

  // App Filter Modes
  String get appControlPolicy => isArabic ? 'سياسة تشغيل التطبيقات' : 'Application Control Policy';
  String get filterModeWhitelist => isArabic ? 'قائمة السماح (Whitelist)' : 'Whitelist Mode';
  String get filterModeBlacklist => isArabic ? 'قائمة الحظر (Blacklist)' : 'Blacklist Mode';
  String get whitelistDesc => isArabic
      ? 'السماح فقط بالتطبيقات المحددة وإغلاق أي برنامج آخر فور فتحه.'
      : 'Allow ONLY selected apps; automatically terminate everything else.';
  String get blacklistDesc => isArabic
      ? 'السماح بجميع البرامج ما عدا البرامج المحددة في القائمة (حظر محدد).'
      : 'Allow ALL apps EXCEPT those selected in the blocked list.';
  String get allowedApps => isArabic ? 'التطبيقات المسموحة' : 'Allowed Applications';
  String get blockedApps => isArabic ? 'التطبيقات المحظورة' : 'Blocked Applications';
  String get searchAppsHint => isArabic ? 'ابحث باسم التطبيق أو البرنامج...' : 'Search by app name or process...';
  String get customAppHint => isArabic ? 'اسم البرنامج (مثال: game.exe)' : 'Process name (e.g. game.exe)';
  String get addCustomApp => isArabic ? 'إضافة تطبيق مخصص' : 'Add Custom App';
  String get selectAll => isArabic ? 'تحديد الكل' : 'Select All';
  String get deselectAll => isArabic ? 'إلغاء التحديد' : 'Deselect All';
  String get invertSelection => isArabic ? 'عكس التحديد' : 'Invert';
  String get catAll => isArabic ? 'الكل' : 'All';
  String get catGames => isArabic ? 'ألعاب' : 'Games';
  String get catSocial => isArabic ? 'تواصل' : 'Social';
  String get catBrowsers => isArabic ? 'متصفحات' : 'Browsers';
  String get catTools => isArabic ? 'أدوات' : 'Tools';
  String get catDetected => isArabic ? 'برامج الحاسوب المكتشفة' : 'Detected PC Apps';
  String get noAppsFound => isArabic ? 'لم يتم العثور على برامج تطابق البحث' : 'No applications found matching search';

  // Pairing
  String get pairingTitle => isArabic ? 'رمز الربط الذكي' : 'Dynamic Pairing Code';
  String get pairingDesc => isArabic
      ? 'أدخل الرمز التالي في جوالك أو لوحة التحكم لربط هذا الحاسوب بحسابك:'
      : 'Enter this 10-character code in your mobile or controller dashboard to claim this PC:';
  String get pairingModalTitle => isArabic ? 'ربط حاسوب جديد' : 'Pair New Computer';
  String get pairingModalDesc => isArabic
      ? 'شغّل برنامج WardHelm على الحاسوب وأدخل رمز الربط المؤقت المكون من 10 خانات:'
      : 'Run WardHelm on the PC and enter the 10-character dynamic code displayed on screen:';
  String get pairingExpiresIn => isArabic ? 'يتجدد الرمز خلال' : 'Refreshes in';
  String get seconds => isArabic ? 'ثانية' : 'sec';
  String get enterCode => isArabic ? 'أدخل رمز الربط' : 'Enter Pairing Code';
  String get pairButton => isArabic ? 'تأكيد الربط فوراً' : 'Pair Device Now';
  String get pairingCodeHint => isArabic ? 'مثال: 7894561230' : 'e.g. 7894561230';
  String get customNameOptional => isArabic ? 'اسم اختياري للحاسوب (مثال: كمبيوتر الصالة)' : 'Optional custom name (e.g. Living Room PC)';
  String get successPairing => isArabic ? 'تم ربط الجهاز بنجاح!' : 'Device paired successfully!';
  String get invalidCode => isArabic ? 'رمز الربط غير صالح أو منتهي الصلاحية' : 'Invalid or expired pairing code';
  String get pairingInProgress => isArabic ? 'جارٍ التحقق وربط الجهاز...' : 'Verifying and pairing device...';

  // Authentication
  String get loginTitle => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get registerTitle => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
  String get loginSubtitle => isArabic ? 'تسجيل الدخول إلى حسابك السحابي المحمي' : 'Sign in to your protected cloud account';
  String get registerSubtitle => isArabic ? 'إنشاء حساب وصي سحابي جديد لإدارة الأجهزة' : 'Create a guardian account to manage your devices';
  String get continueWithGoogle => isArabic ? 'المتابعة باستخدام Google' : 'Continue with Google';
  String get orByEmail => isArabic ? 'أو بالبريد الإلكتروني' : 'or with email';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get enterEmail => isArabic ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter your email';
  String get enterValidEmail => isArabic ? 'يرجى إدخال بريد إلكتروني صحيح' : 'Please enter a valid email';
  String get enterPassword => isArabic ? 'يرجى إدخال كلمة المرور' : 'Please enter your password';
  String get passwordTooShort => isArabic ? 'كلمة المرور يجب أن لا تقل عن 6 خانات' : 'Password must be at least 6 characters';
  String get createAccountBtn => isArabic ? 'إنشاء الحساب' : 'Create Account';
  String get loginBtn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get haveAccount => isArabic ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'Already have an account? Sign In';
  String get noAccount => isArabic ? 'ليس لديك حساب؟ إنشاء حساب جديد' : "Don't have an account? Sign Up";

  // Updates & Maintenance
  String get updateAvailable => isArabic ? 'يوجد تحديث جديد متاح' : 'New update available';
  String get upToDate => isArabic ? 'أنت على أحدث إصدار بالفعل' : 'Up to date';
  String get updating => isArabic ? 'جارٍ التحديث...' : 'Updating...';
  String get updateAgentSuccess => isArabic
      ? 'تم إرسال أمر التحديث إلى الحاسوب بنجاح! سيقوم الوكيل بالفحص والتحديث التلقائي.'
      : 'Update command sent successfully! Agent will check and install the update.';
  String get updateAgentFail => isArabic ? 'تعذر إرسال أمر التحديث إلى الجهاز.' : 'Failed to send update command to device.';
  String get updateCheckSuccess => isArabic ? 'أنت تستخدم أحدث إصدار متوفر بالفعل' : 'You are running the latest version available';
  String get currentVersion => isArabic ? 'الإصدار الحالي' : 'Current Version';
  String get latestVersion => isArabic ? 'أحدث إصدار' : 'Latest Version';

  // Security Logs & Misc
  String get securityLogs => isArabic ? 'سجل الأمان والتنبيهات' : 'Security Logs';
  String get noLogs => isArabic ? 'لا توجد أي تنبيهات أمنية مسجلة' : 'No security events recorded';
  String get timeRemaining => isArabic ? 'الوقت المتبقي' : 'Time Remaining';
  String get internetStatus => isArabic ? 'حالة الإنترنت' : 'Internet Status';
  String get internetActive => isArabic ? 'متصل بالإنترنت' : 'Internet Connected';
  String get internetBlocked => isArabic ? 'الإنترنت مقطوع' : 'Internet Blocked';
  String get agentKiosk => isArabic ? 'حارس الجهاز (Agent Kiosk)' : 'Agent Kiosk';
  String get themeMode => isArabic ? 'المظهر' : 'Appearance';
  String get darkMode => isArabic ? 'الوضع الداكن' : 'Dark Mode';
  String get lightMode => isArabic ? 'الوضع الفاتح' : 'Light Mode';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'English' : 'English';

  // Device Unpairing & Privacy Wiping
  String get unpairDevice => isArabic ? 'فك ربط الجهاز ومسحه' : 'Unpair & Wipe Device';
  String get unpairDeviceDesc => isArabic
      ? 'إنهاء ارتباط هذا الحاسوب بحسابك وحذف جميع سجلاته وبياناته نهائياً لأعلى درجات الخصوصية.'
      : 'Disconnect this PC and permanently wipe all its sessions and logs for maximum privacy.';
  String get confirmUnpairTitle => isArabic ? 'تأكيد فك الربط والمسح الشامل' : 'Confirm Unpair & Data Wipe';
  String get confirmUnpairMsg => isArabic
      ? 'هل أنت متأكد من فك ربط هذا الجهاز؟ سيتم حذف جميع بيانات الجلسات والسجلات الأمنية نهائياً من السحابة، وسيعود الحاسوب لوضع الربط الأولي.'
      : 'Are you sure you want to unpair this device? All session data and security logs will be permanently deleted from the cloud, and the PC will return to pairing mode.';
  String get unpairSuccess => isArabic
      ? 'تم فك ربط الجهاز ومسح كافة بياناته بنجاح.'
      : 'Device unpaired and all data wiped successfully.';
  String get unpairFailed => isArabic
      ? 'فشل فك ربط الجهاز، يرجى المحاولة مرة أخرى.'
      : 'Failed to unpair device, please try again.';
}

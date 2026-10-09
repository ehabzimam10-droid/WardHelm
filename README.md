# 🛡️ WardHelm (وارد هيلم)
### Autonomous Cloud Guardian & PC Fleet Controller

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Web%20%7C%20Android-4F46E5)](#)
[![License](https://img.shields.io/badge/License-MIT-10B981)](#)

---

## 📖 نظرة عامة (Overview)

**WardHelm** هو نظام حماية وإدارة وقفل للحواسيب المتعددة عن بُعد عبر الجوال والسحابة. تم تصميمه بمعمارية نظيفة ثلاثية الطبقات (3-tier Clean Architecture) تجمع بين:
1. **لوحة التحكم المركزية (Controller Dashboard):** واجهة ويب وجوال بتصميم عصري (Fluent Minimalist) تدعم الوضعين الليلي والنهاري وتتيح مراقبة الحواسيب وإطلاق جلسات اللعب والتحكم اللحظي.
2. **عميل ويندوز الأمني المستقل (Windows Native Security Agent):** محرك مراقبة محلي فائق السرعة يُترجم كملف تنفيذي مستقل (`wardhelm_agent.exe`) بدون أي تبعيات لتنفيذ الحظر والمراقبة وتطبيق السياسات.

---

## ✨ المميزات الرئيسية المعتمدة (Key Features)

### 1. إدارة أجهزة متعددة وربط ذكي برمز ديناميكي (Dynamic 60s Pairing Code)
* عند تشغيل البرنامج على أي حاسوب جديد غير مرتبط، يولد كود ربط مؤقت من 10 خانات (مثل: `WH-3PXY-TD`) يتجدد آلياً كل 60 ثانية بحلقة دائرية متحركة.
* إدخال الرمز في الجوال أو لوحة التحكم يربط الحاسوب بحسابك فوراً ويُحذف الرمز نهائياً من قاعدة بيانات Firestore لمنع إعادة الاستخدام.
* إمكانية تسمية كل جهاز ومتابعة نبض الاتصال اللحظي (Heartbeat) ومواصفاته وحالته على حدة.

### 2. وضع المالك الحر مقابل جلسات اللعب عند الطلب (Dual Modes)
* **وضع المالك (Owner Mode):** حاسوبك حر وطبيعي 100% بدون أي مراقبة أو حظر أو قيود عند استخدامك الشخصي.
* **جلسة الأخ المقيدة (Brother / Controlled Session):** تُفعّل عند الطلب مع تحديد المدة الزمنية وقائمة البرامج المسموحة فقط (Roblox).

### 3. أزرار التحكم الحية السريعة (Live Remote Quick Actions)
* ⏸️ **استراحة الصلاة (Prayer Pause):** قفل فوري للشاشة أثناء أوقات الصلاة مع إيقاف عداد اللعب واستئنافه لاحقاً بلمسة زر.
* ➕ **تمديد الوقت (+15 / +30 Min):** إضافة وقت إضافي للجلسة دون الحاجة لإنشائها من جديد.
* 🌐 **قطع الإنترنت اللحظي (Emergency Internet Killswitch):** عزل فوري للإنترنت عن المتصفحات والألعاب عبر جدار حماية ويندوز مع الحفاظ على اتصال السحابة.
* 🛑 **إنهاء الجلسة (End Session):** استعادة الحاسوب فوراً لوضع المالك الحر وفك كافة القيود في ثانية واحدة.

### 4. محرك الحماية والتأمين على ويندوز (Windows Security Engine)
* **Process Watchdog:** مراقب مهام دوري يرصد كافة العمليات الجارية ويُنهي فوراً (`taskkill /F /IM`) أي تطبيق يخرج عن القائمة البيضاء المسموحة.
* **Windows Hosts File Modifier:** تعديل ملف `hosts` لتحويل المواقع المشتتة والمشبوهة إلى `127.0.0.1` مع استعادة تلقائية عند انتهاء الجلسة.
* **Windows Firewall Rules:** قواعد جدار حماية تمنع حركة المرور غير المصرح بها أثناء الحظر.
* **Registry DisableTaskMgr:** تعطيل إدارة المهام (`DisableTaskMgr = 1`) لمنع إيقاف الحارس الأمني أثناء قفل الشاشة.

### 5. نظام التحديث التلقائي بضغطة زر (One-Click In-App Auto-Updater)
* فحص أحدث الإصدارات من مستودع GitHub الرسمي وعرض الملاحظات وإمكانية التحديث بضغطة زر.

---

## 🏛️ المعمارية الهندسية (Architecture)

```text
lib/
├── core/
│   ├── constants/           # AppConstants, AppColors (Anti-AI-slop tokens), FirebaseConfig
│   ├── theme/               # Fluent Material 3 Dark (Slate Obsidian) & Light themes
│   ├── localization/        # Arabic & English localization
│   └── utils/               # TotpHelper (60s dynamic code), SystemInfoHelper, NativeIo
├── data/
│   ├── dal/                 # FirestoreDal (Zero-dependency REST DAL)
│   └── models/              # DeviceModel, SessionModel, PairingCodeModel, SecurityLogModel
├── services/
│   ├── auth_service.dart    # PIN authentication & session caching
│   ├── device_service.dart  # Fleet management & pairing claim logic
│   ├── session_service.dart # Session lifecycle & quick action dispatchers
│   ├── auto_updater_service.dart # GitHub release checker
│   └── windows/             # ProcessWatchdog, HostsFirewall, RegistryKiosk, AgentController
├── state/                   # AppState, DeviceState, SessionState (Reactive ChangeNotifier)
└── presentation/
    ├── screens/             # Dashboard, DeviceDetail, Auth, PairingDialog, AgentKiosk, Settings
    └── widgets/             # DeviceCard, SessionControlPanel, CountdownTimer, CircularTotpTimer
bin/
└── wardhelm_agent.dart      # Native standalone Windows Agent executable
```

---

## 🚀 التشغيل والبناء (Build & Run)

### تشغيل الاختبارات الآلية (Automated Verification)
```powershell
flutter test
```

### بناء لوحة التحكم للويب (Web Controller Dashboard)
```powershell
flutter build web --release
```

### ترجمة عميل ويندوز المستقل (Windows Native Agent EXE)
```powershell
dart compile exe bin/wardhelm_agent.dart -o build/wardhelm_agent.exe
```

### تشغيل عميل ويندوز مباشرة
```powershell
.\run_agent.ps1
```

---

## 🔒 رخصة المشروع ومستودع GitHub
* **المستودع الرسمي:** `https://github.com/ehabzimam10-droid/WardHelm`
* **المطور:** إيهاب زمام (`ehabzimam10-droid`)
* **الترخيص:** MIT License

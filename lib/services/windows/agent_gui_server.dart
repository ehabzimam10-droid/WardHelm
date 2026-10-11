import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_logo_data.dart';

/// Embedded local GUI web server and window launcher for WardHelm Windows Agent
class AgentGuiServer {
  final int port;
  HttpServer? _server;
  bool _isWindowOpen = false;

  String currentCode = '';
  int remainingSeconds = 60;
  bool isPaired = false;
  String deviceName = '';
  String deviceId = '';
  String mode = 'owner';
  bool isControlled = false;
  int sessionMinutesLeft = 0;
  bool isPrayerPause = false;
  bool isInternetBlocked = false;

  Future<Map<String, dynamic>> Function()? onCheckUpdateWithResult;
  Future<void> Function()? onExitRequested;

  AgentGuiServer({this.port = 48123});

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      stdout.writeln('[GUI] Local Graphical UI Server listening on http://127.0.0.1:$port');

      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;

        // Security: Block any cross-origin browser requests from external domains
        final origin = request.headers.value('origin');
        if (origin != null && !origin.contains('127.0.0.1') && !origin.contains('localhost')) {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return;
        }

        if (path == '/logo.png') {
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(base64Decode(AppLogoData.logoPngBase64));
          await request.response.close();
          return;
        }

        if (path == '/status') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(json.encode({
            'code': currentCode,
            'remaining': remainingSeconds,
            'isPaired': isPaired,
            'deviceName': deviceName,
            'deviceId': deviceId,
            'mode': mode,
            'version': AppConstants.appVersion,
            'isControlled': isControlled,
            'sessionMinutesLeft': sessionMinutesLeft,
            'isPrayerPause': isPrayerPause,
            'isInternetBlocked': isInternetBlocked,
          }));
          await request.response.close();
          return;
        }

        if (path == '/open_gui' && request.method == 'POST') {
          request.response.headers.contentType = ContentType.json;
          launchWindow();
          request.response.write(json.encode({'status': 'opened'}));
          await request.response.close();
          return;
        }

        if (path == '/check_update' && request.method == 'POST') {
          request.response.headers.contentType = ContentType.json;
          if (onCheckUpdateWithResult != null) {
            final result = await onCheckUpdateWithResult!.call();
            request.response.write(json.encode(result));
          } else {
            request.response.write(json.encode({
              'hasUpdate': false,
              'currentVersion': AppConstants.appVersion,
              'latestVersion': AppConstants.appVersion,
              'message': 'أنت تستخدم أحدث إصدار بالفعل (v${AppConstants.appVersion}).',
            }));
          }
          await request.response.close();
          return;
        }

        if (path == '/exit' && request.method == 'POST') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(json.encode({'status': 'exiting'}));
          await request.response.close();
          onExitRequested?.call();
          return;
        }

        // Serve Beautiful Embedded Acrylic Obsidian Native Desktop GUI
        request.response.headers.contentType = ContentType.html;
        request.response.write(_buildHtmlTemplate());
        await request.response.close();
      });
    } catch (e) {
      stderr.writeln('[GUI] Failed to bind local GUI server: $e');
    }
  }

  void launchWindow() {
    if (_isWindowOpen) {
      // Bring existing window to front via PowerShell
      try {
        Process.runSync('powershell.exe', [
          '-NoProfile',
          '-Command',
          r'''
          $w = (Get-Process | Where-Object { $_.MainWindowTitle -like "*WardHelm*" } | Select-Object -First 1)
          if ($w) {
            $ws = New-Object -ComObject WScript.Shell
            $ws.AppActivate($w.Id)
          }
          '''
        ]);
        return;
      } catch (_) {}
    }

    final edgePaths = [
      r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
      r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
      r'C:\Program Files\Google\Chrome\Application\chrome.exe',
      r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    ];

    for (final path in edgePaths) {
      if (File(path).existsSync()) {
        try {
          Process.start(
            path,
            [
              '--app=http://127.0.0.1:$port',
              '--window-size=480,720',
              '--app-id=wardhelm_agent_ui',
              '--disable-extensions',
              '--disable-plugins',
            ],
            mode: ProcessStartMode.detached,
          );
          _isWindowOpen = true;
          stdout.writeln('[GUI] Opened native application window via $path');
          return;
        } catch (_) {}
      }
    }

    // Fallback: Default browser
    try {
      Process.start('cmd.exe', ['/c', 'start', 'http://127.0.0.1:$port'], mode: ProcessStartMode.detached);
      _isWindowOpen = true;
    } catch (_) {}
  }

  String _buildHtmlTemplate() {
    return '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WardHelm - حارس الحاسوب الذكي</title>
  <link rel="icon" type="image/png" href="/logo.png">
  <style>
    :root {
      --bg: #090d16;
      --card-bg: #111827;
      --card-border: rgba(255, 255, 255, 0.08);
      --primary: #3b82f6;
      --primary-hover: #2563eb;
      --text: #f9fafb;
      --text-muted: #9ca3af;
      --success: #10b981;
      --warning: #f59e0b;
      --danger: #ef4444;
      --surface-glass: rgba(17, 24, 39, 0.85);
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      user-select: none;
      -webkit-user-select: none;
      -webkit-user-drag: none;
    }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
      overflow-x: hidden;
      background-image: radial-gradient(circle at 50% 0%, rgba(59, 130, 246, 0.12) 0%, transparent 60%);
    }

    /* Native App Window Container */
    .app-window {
      background: var(--surface-glass);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid var(--card-border);
      border-radius: 24px;
      width: 100%;
      max-width: 440px;
      padding: 30px 24px 26px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.65), 0 0 0 1px rgba(255, 255, 255, 0.05);
      text-align: center;
      position: relative;
    }

    .window-header {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-bottom: 20px;
    }
    .logo-glow {
      position: relative;
      margin-bottom: 12px;
    }
    .logo-img {
      width: 80px;
      height: 80px;
      object-fit: contain;
      filter: drop-shadow(0 8px 24px rgba(59, 130, 246, 0.5));
      animation: pulseGlow 4s ease-in-out infinite alternate;
    }
    @keyframes pulseGlow {
      from { filter: drop-shadow(0 6px 16px rgba(59, 130, 246, 0.35)); }
      to { filter: drop-shadow(0 10px 30px rgba(59, 130, 246, 0.65)); }
    }

    h1 {
      font-size: 24px;
      font-weight: 800;
      letter-spacing: 0.5px;
      background: linear-gradient(135deg, #ffffff 0%, #93c5fd 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .subtitle {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 4px;
      font-weight: 500;
    }

    /* Circular Timer */
    .timer-box {
      position: relative;
      width: 170px;
      height: 170px;
      margin: 16px auto;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .svg-ring { transform: rotate(-90deg); width: 170px; height: 170px; }
    .svg-ring circle {
      fill: none;
      stroke-width: 9;
      stroke-linecap: round;
    }
    .ring-bg { stroke: rgba(255, 255, 255, 0.06); }
    .ring-progress {
      stroke: var(--primary);
      stroke-dasharray: 446;
      stroke-dashoffset: 0;
      transition: stroke-dashoffset 0.8s linear, stroke 0.3s;
    }
    .timer-text {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .timer-sec { font-size: 34px; font-weight: 800; color: #fff; line-height: 1; }
    .timer-label { font-size: 11px; color: var(--text-muted); margin-top: 4px; }

    /* Pairing Code Box */
    .code-box {
      background: rgba(0, 0, 0, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 16px;
      padding: 16px 20px;
      margin: 16px 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .code-box:hover {
      border-color: rgba(59, 130, 246, 0.4);
      background: rgba(59, 130, 246, 0.05);
      transform: translateY(-1px);
    }
    .code-title { font-size: 11px; color: var(--text-muted); margin-bottom: 6px; font-weight: 600; }
    .code-val {
      font-size: 28px;
      font-weight: 900;
      letter-spacing: 4px;
      color: #60a5fa;
      direction: ltr;
      font-family: Consolas, "Courier New", monospace;
    }
    .copy-hint { font-size: 11px; color: var(--text-muted); margin-top: 6px; }

    /* Device Info Badges */
    .badges {
      display: flex;
      justify-content: center;
      gap: 8px;
      margin-top: 14px;
      flex-wrap: wrap;
    }
    .badge {
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.07);
      padding: 6px 12px;
      border-radius: 10px;
      font-size: 12px;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .badge strong { color: var(--text); }
    .badge-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--success); box-shadow: 0 0 8px var(--success); }

    /* Paired State */
    .paired-card { display: none; text-align: center; padding: 20px 0; }
    .paired-icon {
      width: 68px;
      height: 68px;
      border-radius: 50%;
      background: rgba(16, 185, 129, 0.12);
      border: 1px solid rgba(16, 185, 129, 0.25);
      color: var(--success);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
    }
    .paired-title { font-size: 20px; font-weight: 800; color: var(--success); margin-bottom: 8px; }
    .paired-desc { font-size: 13px; color: var(--text-muted); line-height: 1.6; }

    /* Controlled Session State */
    .session-card {
      display: none;
      margin: 16px 0;
      padding: 16px;
      background: rgba(245, 158, 11, 0.08);
      border: 1px solid rgba(245, 158, 11, 0.25);
      border-radius: 16px;
    }
    .session-title { color: var(--warning); font-weight: bold; font-size: 14px; margin-bottom: 4px; }
    .session-time { font-size: 26px; font-weight: 800; color: #fff; }

    /* Native Buttons */
    .btn-update {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: var(--text-muted);
      padding: 10px 18px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 20px;
      transition: all 0.2s;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .btn-update:hover {
      border-color: var(--primary);
      color: #fff;
      background: rgba(59, 130, 246, 0.15);
      transform: translateY(-1px);
    }

    /* Native In-App Acrylic Modal Dialog */
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.65);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      opacity: 0;
      pointer-events: none;
      transition: opacity 0.25s ease;
      z-index: 999;
    }
    .modal-overlay.active {
      opacity: 1;
      pointer-events: auto;
    }
    .modal-card {
      background: #131b2e;
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 20px;
      width: 100%;
      max-width: 380px;
      padding: 24px;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.8);
      transform: scale(0.95);
      transition: transform 0.25s ease;
    }
    .modal-overlay.active .modal-card {
      transform: scale(1);
    }
    .modal-icon {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
      font-size: 24px;
    }
    .modal-title { font-size: 17px; font-weight: 800; color: #fff; margin-bottom: 8px; }
    .modal-body { font-size: 13px; color: var(--text-muted); line-height: 1.5; margin-bottom: 20px; }
    .modal-btn {
      background: var(--primary);
      color: #fff;
      border: none;
      padding: 10px 24px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      transition: background 0.2s;
    }
    .modal-btn:hover { background: var(--primary-hover); }

    /* Spinner */
    .spinner {
      width: 28px;
      height: 28px;
      border: 3px solid rgba(255, 255, 255, 0.15);
      border-top-color: var(--primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 14px;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body oncontextmenu="return false;">

<div class="app-window">
  <div class="window-header">
    <div class="logo-glow">
      <img src="/logo.png" class="logo-img" alt="WardHelm Logo">
    </div>
    <h1>WardHelm</h1>
    <div class="subtitle" id="subTitle">حارس الحاسوب الذكي وإدارة الجلسات</div>
  </div>

  <!-- Unpaired Section (TOTP Countdown & Code) -->
  <div id="unpairedSection">
    <div class="timer-box">
      <svg class="svg-ring">
        <circle class="ring-bg" cx="85" cy="85" r="71"></circle>
        <circle id="ringProgress" class="ring-progress" cx="85" cy="85" r="71"></circle>
      </svg>
      <div class="timer-text">
        <span class="timer-sec" id="timerSec">60</span>
        <span class="timer-label">ثانية</span>
      </div>
    </div>

    <div class="code-box" onclick="copyCode()">
      <div class="code-title">رمز الربط الديناميكي السريع (Dynamic 60s)</div>
      <div class="code-val" id="codeVal">••••••••••</div>
      <div class="copy-hint" id="copyHint">اضغط لنسخ الرمز 📋</div>
    </div>
  </div>

  <!-- Paired Section (Owner Mode) -->
  <div class="paired-card" id="pairedSection">
    <div class="paired-icon">
      <svg width="34" height="34" viewBox="0 0 24 24" fill="currentColor">
        <path d="M9 16.17L4.83 12L3.41 13.41L9 19L21 7L19.59 5.59L9 16.17Z"/>
      </svg>
    </div>
    <div class="paired-title">هذا الحاسوب مقترن ومحمي!</div>
    <div class="paired-desc">
      يعمل الآن في <strong>وضع المالك الحر</strong>.<br>
      يمكنك تفعيل جلسة مقيدة أو قفل الإنترنت من لوحة التحكم في الجوال عند الحاجة.
    </div>
  </div>

  <!-- Active Controlled Session Banner -->
  <div class="session-card" id="sessionSection">
    <div class="session-title">⚠️ جلسة لعب مقيدة نشطة</div>
    <div class="session-time" id="sessionTime">0 دقيقة متبقية</div>
    <div style="font-size: 12px; color: var(--text-muted); margin-top: 4px;">يتم حظر الألعاب والتطبيقات غير المصرح بها</div>
  </div>

  <!-- Device Metadata Badges -->
  <div class="badges">
    <div class="badge"><span class="badge-dot"></span> متصل بالسحابة</div>
    <div class="badge">الجهاز: <strong id="devName">...</strong></div>
    <div class="badge">الإصدار: <strong id="verNum">v1.0.7</strong></div>
  </div>

  <button class="btn-update" id="btnUpdate" onclick="checkUpdate()">
    <span>🔄</span>
    <span>فحص التحديثات الآن</span>
  </button>
</div>

<!-- Native Acrylic In-App Modal Dialog (Zero Browser Alerts) -->
<div class="modal-overlay" id="modalOverlay">
  <div class="modal-card">
    <div id="modalLoading" style="display: none;">
      <div class="spinner"></div>
      <div class="modal-title">جارٍ فحص التحديثات...</div>
      <div class="modal-body">يتم الاتصال بالخادم السحابي للتحقق من أحدث إصدار معتمد.</div>
    </div>
    <div id="modalContent">
      <div class="modal-icon" id="modalIcon">🛡️</div>
      <div class="modal-title" id="modalTitle">حالة التحديث</div>
      <div class="modal-body" id="modalBody">رسالة التحديث...</div>
      <button class="modal-btn" onclick="closeModal()">حسناً</button>
    </div>
  </div>
</div>

<script>
  let lastCode = '';
  const circumference = 2 * Math.PI * 71; // ~446

  async function updateStatus() {
    try {
      const res = await fetch('/status');
      const data = await res.json();

      document.getElementById('devName').innerText = data.deviceName || 'EH-PC';
      document.getElementById('verNum').innerText = 'v' + data.version;

      if (!data.isPaired) {
        document.getElementById('unpairedSection').style.display = 'block';
        document.getElementById('pairedSection').style.display = 'none';
        document.getElementById('sessionSection').style.display = 'none';

        document.getElementById('codeVal').innerText = data.code || '---';
        document.getElementById('timerSec').innerText = data.remaining;

        // Animate SVG ring
        const offset = circumference - (data.remaining / 60) * circumference;
        document.getElementById('ringProgress').style.strokeDashoffset = offset;
        if (data.remaining <= 10) {
          document.getElementById('ringProgress').style.stroke = '#ef4444';
        } else {
          document.getElementById('ringProgress').style.stroke = '#3b82f6';
        }
      } else {
        document.getElementById('unpairedSection').style.display = 'none';

        if (data.isControlled) {
          document.getElementById('pairedSection').style.display = 'none';
          document.getElementById('sessionSection').style.display = 'block';
          document.getElementById('sessionTime').innerText = data.sessionMinutesLeft + ' دقيقة متبقية';
        } else {
          document.getElementById('pairedSection').style.display = 'block';
          document.getElementById('sessionSection').style.display = 'none';
        }
      }
    } catch (_) {}
  }

  function copyCode() {
    const code = document.getElementById('codeVal').innerText;
    navigator.clipboard.writeText(code);
    document.getElementById('copyHint').innerText = 'تم النسخ بنجاح! ✅';
    setTimeout(() => {
      document.getElementById('copyHint').innerText = 'اضغط لنسخ الرمز 📋';
    }, 2500);
  }

  // Native In-App Acrylic Dialog (Never calls browser alert)
  function showModal(icon, title, body, bg) {
    document.getElementById('modalLoading').style.display = 'none';
    document.getElementById('modalContent').style.display = 'block';
    const iconEl = document.getElementById('modalIcon');
    iconEl.innerText = icon;
    iconEl.style.background = bg || 'rgba(59, 130, 246, 0.15)';
    document.getElementById('modalTitle').innerText = title;
    document.getElementById('modalBody').innerText = body;
    document.getElementById('modalOverlay').classList.add('active');
  }

  function closeModal() {
    document.getElementById('modalOverlay').classList.remove('active');
  }

  async function checkUpdate() {
    document.getElementById('modalContent').style.display = 'none';
    document.getElementById('modalLoading').style.display = 'block';
    document.getElementById('modalOverlay').classList.add('active');

    try {
      const res = await fetch('/check_update', { method: 'POST' });
      const data = await res.json();

      if (data.hasUpdate) {
        showModal(
          '🚀',
          'تم العثور على تحديث جديد: v' + data.latestVersion,
          data.message || 'جارٍ تنزيل التحديث وتثبيته تلقائياً في الخلفية...',
          'rgba(16, 185, 129, 0.2)'
        );
      } else {
        showModal(
          '✅',
          'أنت على أحدث إصدار بالفعل',
          'البرنامج يعمل بالإصدار v' + data.currentVersion + ' وجميع ملفات الحماية ومحرك المراقبة محدثة لأحدث نسخة معتمدة.',
          'rgba(16, 185, 129, 0.15)'
        );
      }
    } catch (e) {
      showModal(
        '⚠️',
        'تعذر فحص التحديثات',
        'يرجى التأكد من اتصال الإنترنت ثم المحاولة مرة أخرى.',
        'rgba(239, 68, 68, 0.15)'
      );
    }
  }

  // Poll local status every 800ms
  setInterval(updateStatus, 800);
  updateStatus();
</script>
</body>
</html>''';
  }
}

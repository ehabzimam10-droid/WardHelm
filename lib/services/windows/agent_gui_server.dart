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
  Future<void> Function()? onCheckUpdateRequested;
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
          onCheckUpdateRequested?.call();
          request.response.write(json.encode({'status': 'triggered'}));
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

        // Serve Beautiful Embedded Fluent Obsidian Dark Kiosk GUI
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
      --bg: #0d1117;
      --card-bg: #161b22;
      --border: #30363d;
      --primary: #4f46e5;
      --primary-hover: #4338ca;
      --text: #f0f6fc;
      --text-muted: #8b949e;
      --success: #10b981;
      --warning: #f59e0b;
      --danger: #ef4444;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      overflow-x: hidden;
    }
    .container {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 24px;
      width: 100%;
      max-width: 430px;
      padding: 32px 28px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
      text-align: center;
      position: relative;
    }
    .header {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-bottom: 24px;
    }
    .shield-badge {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: rgba(79, 70, 229, 0.15);
      border: 1px solid rgba(79, 70, 229, 0.3);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 12px;
      color: var(--primary);
    }
    h1 { font-size: 24px; font-weight: 800; letter-spacing: 0.5px; }
    .subtitle { font-size: 13px; color: var(--text-muted); margin-top: 4px; }
    
    /* Circular Timer */
    .timer-box {
      position: relative;
      width: 180px;
      height: 180px;
      margin: 20px auto;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .svg-ring { transform: rotate(-90deg); width: 180px; height: 180px; }
    .svg-ring circle {
      fill: none;
      stroke-width: 10;
      stroke-linecap: round;
    }
    .ring-bg { stroke: rgba(255, 255, 255, 0.08); }
    .ring-progress {
      stroke: var(--primary);
      stroke-dasharray: 471;
      stroke-dashoffset: 0;
      transition: stroke-dashoffset 0.8s linear, stroke 0.3s;
    }
    .timer-text {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .timer-sec { font-size: 32px; font-weight: 800; }
    .timer-label { font-size: 11px; color: var(--text-muted); text-transform: uppercase; }

    /* Pairing Code Box */
    .code-box {
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 16px 20px;
      margin: 20px 0 16px;
      display: flex;
      flex-direction: column;
      align-items: center;
      cursor: pointer;
      transition: all 0.2s;
    }
    .code-box:hover { border-color: var(--primary); transform: translateY(-1px); }
    .code-title { font-size: 11px; color: var(--text-muted); margin-bottom: 6px; }
    .code-val {
      font-size: 28px;
      font-weight: 900;
      letter-spacing: 4px;
      color: #60a5fa;
      direction: ltr;
      font-family: Consolas, monospace;
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
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.08);
      padding: 6px 12px;
      border-radius: 10px;
      font-size: 12px;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .badge strong { color: var(--text); }
    .badge-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--success); }

    /* Paired State */
    .paired-card { display: none; text-align: center; padding: 20px 0; }
    .paired-icon {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: rgba(16, 185, 129, 0.15);
      color: var(--success);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
    }
    .paired-title { font-size: 20px; font-weight: 800; color: var(--success); margin-bottom: 8px; }
    .paired-desc { font-size: 13px; color: var(--text-muted); line-height: 1.6; }

    /* Controlled Session State */
    .session-card { display: none; margin: 16px 0; padding: 16px; background: rgba(245, 158, 11, 0.1); border: 1px solid rgba(245, 158, 11, 0.3); border-radius: 14px; }
    .session-title { color: var(--warning); font-weight: bold; font-size: 14px; margin-bottom: 4px; }
    .session-time { font-size: 24px; font-weight: 800; color: #fff; }

    /* Buttons */
    .btn-update {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 8px 16px;
      border-radius: 10px;
      font-size: 12px;
      cursor: pointer;
      margin-top: 20px;
      transition: all 0.2s;
    }
    .btn-update:hover { border-color: var(--primary); color: #fff; }
  </style>
</head>
<body>

<div class="container">
  <div class="header">
    <img src="/logo.png" width="76" height="76" alt="WardHelm Logo" style="margin-bottom: 12px; filter: drop-shadow(0 6px 18px rgba(96, 165, 250, 0.45)); object-fit: contain;">
    <h1>WardHelm</h1>
    <div class="subtitle" id="subTitle">حارس الحاسوب الذكي وإدارة الجلسات</div>
  </div>

  <!-- Unpaired Section (TOTP Countdown & Code) -->
  <div id="unpairedSection">
    <div class="timer-box">
      <svg class="svg-ring">
        <circle class="ring-bg" cx="90" cy="90" r="75"></circle>
        <circle id="ringProgress" class="ring-progress" cx="90" cy="90" r="75"></circle>
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
      <svg width="36" height="36" viewBox="0 0 24 24" fill="currentColor">
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
    <div class="badge">الإصدار: <strong id="verNum">v1.0.0</strong></div>
  </div>

  <button class="btn-update" onclick="checkUpdate()">فحص التحديثات الآن 🔄</button>
</div>

<script>
  let lastCode = '';
  const circumference = 2 * Math.PI * 75; // 471.23

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
          document.getElementById('ringProgress').style.stroke = '#4f46e5';
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

  async function checkUpdate() {
    alert('جارٍ فحص التحديثات عبر السحابة...');
    await fetch('/check_update', { method: 'POST' });
  }

  // Poll status every 800ms
  setInterval(updateStatus, 800);
  updateStatus();
</script>
</body>
</html>''';
  }
}

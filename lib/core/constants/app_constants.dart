/// App constants and predefined presets for WardHelm
class AppConstants {
  AppConstants._();

  static const String appName = 'WardHelm';
  static const String appVersion = '1.0.9';
  static const String appSubtitle = 'Autonomous Cloud Guardian & PC Fleet Controller';
  static const String githubRepo = 'ehabzimam10-droid/WardHelm';

  // Standard whitelist presets
  static const List<String> defaultRobloxProcesses = [
    'RobloxPlayerBeta.exe',
    'RobloxPlayerLauncher.exe',
    'RobloxStudioBeta.exe',
  ];

  static const List<String> defaultUtilityProcesses = [
    'notepad.exe',
    'calc.exe',
    'CalculatorApp.exe',
    'mspaint.exe',
  ];

  static const List<String> defaultBrowserProcesses = [
    'chrome.exe',
    'msedge.exe',
    'firefox.exe',
  ];

  // Core system processes and WardHelm apps that are NEVER terminated
  static const Set<String> protectedSystemProcesses = {
    // Windows Kernel & Core Services
    'system',
    'system idle process',
    'secure system',
    'registry',
    'smss.exe',
    'csrss.exe',
    'wininit.exe',
    'services.exe',
    'lsass.exe',
    'lsaiso.exe',
    'svchost.exe',
    'fontdrvhost.exe',
    'dwm.exe',
    'explorer.exe',
    'taskhostw.exe',
    'sihost.exe',
    'ctfmon.exe',
    'wudfhost.exe',
    'searchindexer.exe',
    'searchhost.exe',
    'searchprotocolhost.exe',
    'startmenuexperiencehost.exe',
    'shellexperiencehost.exe',
    'runtimebroker.exe',
    'applicationframehost.exe',
    'textinputhost.exe',
    'audiodg.exe',
    'spoolsv.exe',
    'securityhealthservice.exe',
    'securityhealthsystray.exe',
    'smartscreen.exe',
    'dashost.exe',
    'dllhost.exe',
    'wmiapsrv.exe',
    'msedgewebview2.exe',
    'lockapp.exe',

    // Command & Script Interpreters / System Utilities
    'conhost.exe',
    'cmd.exe',
    'powershell.exe',
    'pwsh.exe',
    'tasklist.exe',
    'taskkill.exe',
    'reg.exe',
    'netsh.exe',

    // Developer & Build Tools
    'flutter.exe',
    'dart.exe',
    'node.exe',
    'git.exe',
    'code.exe',

    // WardHelm Executables (Never self-terminate)
    'wardhelm_agent.exe',
    'luck pc.exe',
    'luckpc.exe',
    'wardhelm.exe',
  };

  // Malicious / distracting domains blocked in Windows hosts file during session
  static const List<String> defaultBlockedDomains = [
    'tiktok.com',
    'www.tiktok.com',
    'instagram.com',
    'www.instagram.com',
    'facebook.com',
    'www.facebook.com',
    'twitter.com',
    'x.com',
    'discord.com',
    'www.discord.com',
    'youtube.com',
    'www.youtube.com',
    'twitch.tv',
    'www.twitch.tv',
    'reddit.com',
    'www.reddit.com',
    'netflix.com',
    'www.netflix.com',
  ];

  // Firewall Rule Names
  static const String firewallRuleName = 'WardHelm_Internet_Killswitch';
  static const String firewallUdpRuleName = 'WardHelm_Internet_Killswitch_UDP';
  static const String firewallTcpRuleName = 'WardHelm_Internet_Killswitch_TCP';
  static const String hostsHeader = '# --- WARDHELM SECURITY RULES BEGIN ---';
  static const String hostsFooter = '# --- WARDHELM SECURITY RULES END ---';
}

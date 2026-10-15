using System;
using System.Drawing;
using System.IO;
using System.Net;
using System.Windows.Forms;

namespace WardHelmTray
{
    static class Program
    {
        private static NotifyIcon notifyIcon;

        [STAThread]
        static void Main(string[] args)
        {
            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string debugLog = Path.Combine(localAppData, @"WardHelm\tray_csharp.log");

            try
            {
                File.AppendAllText(debugLog, "Entering Main at " + DateTime.Now + "\n");
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);

                notifyIcon = new NotifyIcon();
                notifyIcon.Text = "WardHelm PC Guardian";

                string ico32Path = Path.Combine(localAppData, @"WardHelm\wardhelm_logo_32.ico");
                string icoPath = Path.Combine(localAppData, @"WardHelm\wardhelm_logo.ico");

                if (File.Exists(ico32Path))
                {
                    try { notifyIcon.Icon = new Icon(ico32Path); } catch { notifyIcon.Icon = SystemIcons.Shield; }
                }
                else if (File.Exists(icoPath))
                {
                    try { notifyIcon.Icon = new Icon(icoPath, 32, 32); } catch { notifyIcon.Icon = SystemIcons.Shield; }
                }
                else
                {
                    notifyIcon.Icon = SystemIcons.Shield;
                }

                ContextMenu menu = new ContextMenu();
                MenuItem openItem = new MenuItem("🛡️ فتح لوحة التحكم (Dashboard)", (s, e) => PostApi("open_gui"));
                MenuItem updateItem = new MenuItem("🔄 فحص التحديثات الآن (Check Updates)", (s, e) => PostApi("check_update"));
                MenuItem statusItem = new MenuItem("🟢 الحماية نشطة في الخلفية (Active)") { Enabled = false };
                MenuItem separator = new MenuItem("-");
                MenuItem exitItem = new MenuItem("❌ إغلاق الحارس تماماً (Exit)", (s, e) => {
                    PostApi("exit");
                    notifyIcon.Visible = false;
                    notifyIcon.Dispose();
                    Application.Exit();
                });

                menu.MenuItems.Add(openItem);
                menu.MenuItems.Add(updateItem);
                menu.MenuItems.Add(statusItem);
                menu.MenuItems.Add(separator);
                menu.MenuItems.Add(exitItem);

                notifyIcon.ContextMenu = menu;
                notifyIcon.DoubleClick += (s, e) => PostApi("open_gui");
                notifyIcon.Click += (s, e) => {
                    MouseEventArgs me = e as MouseEventArgs;
                    if (me != null && me.Button == MouseButtons.Left)
                    {
                        PostApi("open_gui");
                    }
                };

                notifyIcon.Visible = true;
                File.AppendAllText(debugLog, "NotifyIcon set to visible\n");

                try
                {
                    notifyIcon.BalloonTipTitle = "WardHelm PC Guardian";
                    notifyIcon.BalloonTipText = "درع الحماية نشط ويعمل في علبة النظام بجانب الساعة.";
                    notifyIcon.BalloonTipIcon = ToolTipIcon.Info;
                    notifyIcon.ShowBalloonTip(3000);
                }
                catch { }

                int parentPid = 0;
                if (args.Length > 0)
                {
                    int.TryParse(args[0], out parentPid);
                }

                File.AppendAllText(debugLog, "Parent PID is: " + parentPid + "\n");

                if (parentPid > 0)
                {
                    Timer timer = new Timer();
                    timer.Interval = 2500;
                    timer.Tick += (s, e) =>
                    {
                        try
                        {
                            var proc = System.Diagnostics.Process.GetProcessById(parentPid);
                            if (proc.HasExited)
                            {
                                File.AppendAllText(debugLog, "Parent exited via HasExited\n");
                                notifyIcon.Visible = false;
                                notifyIcon.Dispose();
                                Application.Exit();
                            }
                        }
                        catch (Exception ex)
                        {
                            File.AppendAllText(debugLog, "Parent check failed: " + ex.Message + "\n");
                            notifyIcon.Visible = false;
                            notifyIcon.Dispose();
                            Application.Exit();
                        }
                    };
                    timer.Start();
                }

                File.AppendAllText(debugLog, "Calling Application.Run\n");
                Application.Run();
                File.AppendAllText(debugLog, "Application.Run returned\n");
            }
            catch (Exception ex)
            {
                File.AppendAllText(debugLog, "FATAL EXCEPTION: " + ex + "\n");
            }
        }

        private static void PostApi(string endpoint)
        {
            try
            {
                WebRequest request = WebRequest.Create("http://127.0.0.1:48123/" + endpoint);
                request.Method = "POST";
                request.Timeout = 2000;
                request.ContentLength = 0;
                using (WebResponse response = request.GetResponse()) { }
            }
            catch { }
        }
    }
}

@echo off
title تثبيت وتهيئة حارس WardHelm لنظام ويندوز
cd /d "%~dp0"

echo ===================================================
echo     🛡️ تثبيت وتكامل WardHelm في نظام ويندوز
echo ===================================================
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] يتطلب التثبيت صلاحيات المسؤول لربط الخدمات...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "APP_DIR=%~dp0"
set "EXE_PATH=%APP_DIR%wardhelm_agent.exe"
if not exist "%EXE_PATH%" set "EXE_PATH=%APP_DIR%build\wardhelm_agent.exe"
set "VBS_PATH=%APP_DIR%WardHelm.vbs"
set "ICON_PATH=%APP_DIR%assets\app_icon.ico"

echo [1/4] إنشاء اختصار قائمة ابدأ (Start Menu)...
powershell -NoProfile -Command "$w = New-Object -ComObject WScript.Shell; $p = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Programs), 'WardHelm.lnk'); $s = $w.CreateShortcut($p); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%APP_DIR%'; $s.IconLocation = '%ICON_PATH%,0'; $s.Description = 'WardHelm - حارس الحاسوب الذكي وإدارة الجلسات'; $s.Save()"

echo [2/4] إنشاء اختصار سطح المكتب (Desktop)...
powershell -NoProfile -Command "$w = New-Object -ComObject WScript.Shell; $p = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop), 'WardHelm.lnk'); $s = $w.CreateShortcut($p); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%APP_DIR%'; $s.IconLocation = '%ICON_PATH%,0'; $s.Description = 'WardHelm - حارس الحاسوب الذكي وإدارة الجلسات'; $s.Save()"

echo [3/4] تفعيل التشغيل التلقائي الصامت عند إقلاع ويندوز...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WardHelm" /t REG_SZ /d "\"%VBS_PATH%\"" /f >nul

echo [4/4] تشغيل WardHelm الآن في الخلفية...
start "" "%VBS_PATH%"

echo.
echo ===================================================
echo   ✅ اكتمل التثبيت بنجاح تام!
echo   - يظهر البرنامج الآن في قائمة (ابدأ) ويمكنك تثبيته في شريط المهام.
echo   - أيقونة الحارس تعمل الآن في علبة النظام (System Tray بجانب الساعة).
echo   - سيعمل البرنامج تلقائياً بصمت مع كل إقلاع للجهاز.
echo ===================================================
echo.
timeout /t 3 >nul
exit

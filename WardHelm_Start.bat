@echo off
title WardHelm - Windows Security Agent
cd /d "%~dp0"

echo ==========================================================
echo        WardHelm Autonomous PC Security Agent
echo ==========================================================
echo.
echo Starting WardHelm Security Agent in Administrator Mode...
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ATTENTION] Requesting Administrator Privileges...
    powershell -Command "Start-Process '%~dp0build\wardhelm_agent.exe' -Verb RunAs"
    exit /b
)

:: Run directly if already elevated
"%~dp0build\wardhelm_agent.exe"
pause

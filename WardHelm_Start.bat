@echo off
title WardHelm - Windows Security Agent
cd /d "%~dp0"

:: Auto-detect location of wardhelm_agent.exe
set "EXE_PATH=%~dp0wardhelm_agent.exe"
if not exist "%EXE_PATH%" (
    if exist "%~dp0build\wardhelm_agent.exe" (
        set "EXE_PATH=%~dp0build\wardhelm_agent.exe"
    )
)

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
    powershell -Command "Start-Process '%EXE_PATH%' -Verb RunAs"
    exit /b
)

:: Run directly if already elevated
"%EXE_PATH%"
pause

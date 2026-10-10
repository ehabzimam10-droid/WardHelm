@echo off
title WardHelm Launcher
cd /d "%~dp0"

:: Check for Administrator privileges and elevate seamlessly
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Launch completely silently via VBScript (zero CMD flicker)
if exist "%~dp0WardHelm.vbs" (
    start "" wscript.exe "%~dp0WardHelm.vbs"
    exit
)

set "EXE_PATH=%~dp0wardhelm_agent.exe"
if not exist "%EXE_PATH%" set "EXE_PATH=%~dp0build\wardhelm_agent.exe"
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process '%EXE_PATH%'"
exit

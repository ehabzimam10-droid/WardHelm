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

:: Check for Administrator privileges and elevate seamlessly
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%EXE_PATH%' -Verb RunAs"
    exit /b
)

:: Launch the WardHelm Agent and its Graphical Desktop UI Window
start "" "%EXE_PATH%"
exit

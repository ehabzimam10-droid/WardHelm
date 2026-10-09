# WardHelm Native Agent Launcher
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  🛡️  Launching WardHelm Security Agent" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan

if (Test-Path ".\build\wardhelm_agent.exe") {
    .\build\wardhelm_agent.exe
} else {
    Write-Host "[INFO] Building agent first..." -ForegroundColor Yellow
    dart compile exe bin/wardhelm_agent.dart -o build/wardhelm_agent.exe
    .\build\wardhelm_agent.exe
}

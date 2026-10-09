# WardHelm Complete Build Pipeline
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  🛡️  Building WardHelm Production Artifacts" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Tests
Write-Host "[1/3] Running Automated Tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Tests failed! Aborting." -ForegroundColor Red
    exit 1
}

# 2. Web Build
Write-Host "[2/3] Building Flutter Web Controller Dashboard..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Web build failed! Aborting." -ForegroundColor Red
    exit 1
}

# 3. Windows Native Agent
Write-Host "[3/3] Compiling Native Windows Agent Executable..." -ForegroundColor Yellow
if (!(Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}
dart compile exe bin/wardhelm_agent.dart -o build/wardhelm_agent.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Agent compilation failed! Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "====================================================" -ForegroundColor Green
Write-Host "  ✅  WardHelm Build Complete!" -ForegroundColor Green
Write-Host "  - Web Dashboard: .\build\web\" -ForegroundColor Cyan
Write-Host "  - Windows Agent: .\build\wardhelm_agent.exe" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Green

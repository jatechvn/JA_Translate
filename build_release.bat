@echo off
cd /d %~dp0
echo [BUILD] Building JA Translate Windows Release...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [PACKAGE] Packaging dist...
powershell -ExecutionPolicy Bypass -File .\package_dist.ps1
echo [SUCCESS] Release build and packaging complete!
pause

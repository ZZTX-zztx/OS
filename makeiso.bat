@echo off
setlocal

set "ROOT=%~dp0"
set "BUILD=%ROOT%build"
set "ISO=%BUILD%\nova-os.iso"
set "BOOT=%BUILD%\nova-os.img"

if not exist "%BOOT%" (
    echo [ERROR] Boot image not found: %BOOT%
    echo Please run build.bat first.
    exit /b 1
)

echo [INFO] Creating ISO image...

rem Try Python script first
where python >nul 2>nul
if %errorlevel%==0 (
    python "%ROOT%makeiso.py" "%BOOT%" "%ISO%"
    if exist "%ISO%" goto success
)

where python3 >nul 2>nul
if %errorlevel%==0 (
    python3 "%ROOT%makeiso.py" "%BOOT%" "%ISO%"
    if exist "%ISO%" goto success
)

rem Try mkisofs
where mkisofs >nul 2>nul
if %errorlevel%==0 (
    echo [INFO] Using mkisofs...
    mkisofs -o "%ISO%" -b boot.img -no-emul-boot -boot-load-size 4 -boot-info-table "%BUILD%"
    if exist "%ISO%" goto success
)

rem Try oscdimg
where oscdimg >nul 2>nul
if %errorlevel%==0 (
    echo [INFO] Using oscdimg...
    oscdimg -n -b"%BOOT%" "%BUILD%" "%ISO%"
    if exist "%ISO%" goto success
)

echo [ERROR] No ISO creation tool found.
echo Please install Python or one of the following:
echo   - mkisofs (part of cdrtools)
echo   - oscdimg (part of Windows ADK)
exit /b 1

:success
echo [OK] ISO created at: %ISO%
echo You can now use this ISO in VMware.
endlocal
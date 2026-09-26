@echo off
setlocal

set "ROOT=%~dp0"
set "OUT=%ROOT%build"
set "OSCDIMG=D:\Download\oscdimg\64bit\oscdimg.exe"
set "ISO=%OUT%\nova-os.iso"
set "SRC=%OUT%\iso_src"

if not exist "%OSCDIMG%" (
    echo [ERROR] oscdimg not found: %OSCDIMG%
    exit /b 1
)

if not exist "%SRC%" mkdir "%SRC%"

echo [1/2] Creating ISO with oscdimg (No Emulation)...
if exist "%ISO%" del "%ISO%"

REM -bootdata:2#p0,e,b = BIOS boot, no emulation, boot image file
REM -bootdata:2#pEF,e,b = UEFI boot, no emulation, boot image file
"%OSCDIMG%" -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%OUT%\nova-os.img"#pEF,e,b"%OUT%\nova-os.img" "%SRC%" "%ISO%"

if errorlevel 1 (
    echo [ERROR] ISO creation failed.
    exit /b 1
)

echo.
echo [OK] Build complete!
echo      ISO: %ISO%
endlocal
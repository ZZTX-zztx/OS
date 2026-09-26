@echo off
setlocal

set "ROOT=%~dp0"
set "QEMU=%ROOT%..\Program\qemu\qemu-system-x86_64.exe"
set "ISO=%ROOT%build\nova-os.iso"

if not exist "%ISO%" call "%ROOT%build.bat"
if errorlevel 1 exit /b 1

if not exist "%QEMU%" (
    echo [ERROR] QEMU not found: %QEMU%
    exit /b 1
)

"%QEMU%" -cdrom "%ISO%" -m 32M -vga std -display gtk,zoom-to-fit=on -device isa-debug-exit,iobase=0x501,iosize=0x01 -boot d
endlocal
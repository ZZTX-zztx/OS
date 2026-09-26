@echo off
setlocal

set "ROOT=%~dp0"
set "QEMU=%ROOT%..\Program\qemu\qemu-system-x86_64.exe"
set "IMAGE=%ROOT%build\nova-os.img"

call "%ROOT%build.bat"

if not exist "%IMAGE%" call "%ROOT%build.bat"
if errorlevel 1 exit /b 1

if not exist "%QEMU%" (
    echo [ERROR] QEMU not found: %QEMU%
    exit /b 1
)

"%QEMU%" -drive format=raw,file="%IMAGE%" -m 32M -vga std -display gtk,zoom-to-fit=on -device isa-debug-exit,iobase=0x501,iosize=0x01
endlocal

@echo off
setlocal

set "ROOT=%~dp0"
set "NASM=%ROOT%..\Program\NASM\nasm.exe"
set "OUT=%ROOT%build"
set "ISO=%OUT%\nova-os.iso"

if not exist "%NASM%" (
    echo [ERROR] NASM not found: %NASM%
    exit /b 1
)

if not exist "%OUT%" mkdir "%OUT%"

echo [1/3] Compiling bootloader...
"%NASM%" "%ROOT%boot.asm" -f bin -o "%OUT%\boot.img"
if errorlevel 1 (
    echo [ERROR] Bootloader build failed.
    exit /b 1
)

echo [2/3] Compiling kernel...
"%NASM%" "%ROOT%kernel.asm" -f bin -o "%OUT%\kernel.bin"
if errorlevel 1 (
    echo [ERROR] Kernel build failed.
    exit /b 1
)

echo [3/4] Creating disk image with MBR...
python "%ROOT%makedisk.py" "%OUT%\boot.img" "%OUT%\kernel.bin" "%OUT%\nova-os.img"
if errorlevel 1 (
    echo [ERROR] Disk image creation failed.
    exit /b 1
)

echo [4/4] Creating ISO...
if exist "%ISO%" del "%ISO%"
python "%ROOT%makeiso.py" "%OUT%\boot.img" "%OUT%\kernel.bin" "%ISO%"
if errorlevel 1 (
    echo [ERROR] ISO creation failed.
    exit /b 1
)

echo.
echo [OK] Build complete!
echo      ISO: %ISO%
endlocal
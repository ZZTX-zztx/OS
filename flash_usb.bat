@echo off
setlocal

echo ========================================
echo   NOVA-OS USB Flash Tool
echo ========================================
echo.
echo Available drives:
echo.

wmic diskdrive get caption,deviceid,size 2>nul | findstr /v "Caption"

echo.
set /p DRIVE=Enter USB drive letter (e.g., E): 

if "%DRIVE%"=="" (
    echo [ERROR] No drive specified.
    exit /b 1
)

set "IMG=%~dp0build\nova-os.img"

if not exist "%IMG%" (
    echo [ERROR] Image not found: %IMG%
    exit /b 1
)

echo.
echo [WARNING] This will erase all data on drive %DRIVE%:
echo.

for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='%DRIVE%:'" get VolumeName /value 2^>nul') do echo   Label: %%a
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='%DRIVE%:'" get Size /value 2^>nul') do echo   Size: %%a bytes

echo.
set /p CONFIRM=Type YES to continue: 

if /i not "%CONFIRM%"=="YES" (
    echo Cancelled.
    exit /b 1
)

echo.
echo Writing image to %DRIVE%:...
echo.

REM Use PowerShell to write raw image
powershell -Command "$img = '%IMG%'; $disk = '\\.\%DRIVE%:'; $bytes = [System.IO.File]::ReadAllBytes($img); $stream = [System.IO.File]::Open($disk, 'Open', 'ReadWrite'); $stream.Write($bytes, 0, $bytes.Length); $stream.Flush(); $stream.Close(); Write-Host 'Done!'"

if errorlevel 1 (
    echo [ERROR] Write failed. Try running as Administrator.
    exit /b 1
)

echo.
echo [OK] NOVA-OS written to %DRIVE%: successfully!
endlocal
pause
@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

REM Python Auto-Installer Script
set "LOGFILE=%USERPROFILE%\python_auto_install.log"
set "PYTHON_VERSION=3.11.9"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-amd64.exe"
set "PYTHON_INSTALLER=%TEMP%\python-%PYTHON_VERSION%-installer.exe"

echo ================================================= > "%LOGFILE%" 2>nul
echo Python Auto-Installer Start: %date% %time% >> "%LOGFILE%" 2>nul
echo Python Version: %PYTHON_VERSION% >> "%LOGFILE%" 2>nul
echo Download URL: %PYTHON_URL% >> "%LOGFILE%" 2>nul
echo Installer Path: %PYTHON_INSTALLER% >> "%LOGFILE%" 2>nul
echo ================================================= >> "%LOGFILE%" 2>nul

echo.
echo 🔄 AUTOMATIC PYTHON INSTALLATION
echo.
echo The system needs Python to run this application.
echo We will now automatically download and install Python %PYTHON_VERSION%
echo.
echo This may take a few minutes depending on your internet connection.
echo.
pause

echo [1/4] Downloading Python %PYTHON_VERSION%...
echo [DEBUG] Starting download... >> "%LOGFILE%" 2>nul

REM Use PowerShell to download Python installer
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%' -UseBasicParsing; Write-Host 'Download completed successfully' } catch { Write-Host 'Download failed:' $_.Exception.Message; exit 1 } }" >> "%LOGFILE%" 2>&1

if !errorlevel! neq 0 (
    echo [ERROR] Failed to download Python installer
    echo [ERROR] Download failed, error code: !errorlevel! >> "%LOGFILE%" 2>nul
    echo.
    echo ❌ Download failed. Please check your internet connection.
    echo.
    echo Manual installation:
    echo 1. Go to: https://www.python.org/downloads/
    echo 2. Download Python 3.10+ for Windows
    echo 3. Run the installer and CHECK "Add Python to PATH"
    echo 4. Restart this installer
    echo.
    pause
    exit /b 1
)

echo [DEBUG] Download completed successfully >> "%LOGFILE%" 2>nul

REM Verify download
if not exist "%PYTHON_INSTALLER%" (
    echo [ERROR] Python installer not found after download
    echo [ERROR] Installer file not found: %PYTHON_INSTALLER% >> "%LOGFILE%" 2>nul
    pause
    exit /b 1
)

echo [2/4] Verifying downloaded file...
for %%A in ("%PYTHON_INSTALLER%") do set "FILE_SIZE=%%~zA"
echo [DEBUG] Downloaded file size: %FILE_SIZE% bytes >> "%LOGFILE%" 2>nul

if %FILE_SIZE% LSS 10000000 (
    echo [ERROR] Downloaded file is too small, possibly corrupted
    echo [ERROR] File size too small: %FILE_SIZE% bytes >> "%LOGFILE%" 2>nul
    del "%PYTHON_INSTALLER%" 2>nul
    pause
    exit /b 1
)

echo [3/4] Installing Python %PYTHON_VERSION%...
echo.
echo ⚠️  IMPORTANT: When the Python installer opens:
echo    - CHECK "Add python.exe to PATH" 
echo    - CHECK "Install launcher for all users"
echo    - Click "Install Now"
echo.
echo [DEBUG] Starting Python installation... >> "%LOGFILE%" 2>nul

REM Run Python installer with silent installation and PATH addition
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >> "%LOGFILE%" 2>&1

set "INSTALL_EXIT_CODE=!errorlevel!"
echo [DEBUG] Python installer exit code: !INSTALL_EXIT_CODE! >> "%LOGFILE%" 2>nul

if !INSTALL_EXIT_CODE! neq 0 (
    echo [WARNING] Silent installation may have failed, trying interactive mode...
    echo [DEBUG] Trying interactive installation... >> "%LOGFILE%" 2>nul
    "%PYTHON_INSTALLER%"
    echo.
    echo Please complete the Python installation manually.
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
)

echo [4/4] Cleaning up and verifying installation...
echo [DEBUG] Cleaning up installer file... >> "%LOGFILE%" 2>nul
del "%PYTHON_INSTALLER%" 2>nul

echo.
echo ⏳ Waiting for PATH update...
timeout /t 3 /nobreak >nul

REM Refresh environment variables
echo [DEBUG] Refreshing environment variables... >> "%LOGFILE%" 2>nul
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYS_PATH=%%B"
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
set "PATH=%SYS_PATH%;%USER_PATH%"

echo [DEBUG] Testing Python installation... >> "%LOGFILE%" 2>nul

REM Test Python installation
py --version > nul 2>&1
if !errorlevel! == 0 (
    echo ✅ Python installation successful!
    py --version >> "%LOGFILE%" 2>nul
    echo [DEBUG] Python py launcher working >> "%LOGFILE%" 2>nul
    goto :success
)

python --version > nul 2>&1
if !errorlevel! == 0 (
    echo ✅ Python installation successful!
    python --version >> "%LOGFILE%" 2>nul
    echo [DEBUG] Python command working >> "%LOGFILE%" 2>nul
    goto :success
)

echo [WARNING] Python may be installed but PATH not updated yet
echo [DEBUG] Python not immediately detected, may need restart >> "%LOGFILE%" 2>nul
echo.
echo ⚠️  Python installation completed but may require:
echo    1. Restart command prompt, OR
echo    2. Restart computer
echo.
echo Please restart this installer after restarting your system.
pause
exit /b 0

:success
echo.
echo 🎉 Python installation completed successfully!
echo.
echo Installation log saved to: %LOGFILE%
echo.
echo You can now continue with the application installation.
pause
exit /b 0

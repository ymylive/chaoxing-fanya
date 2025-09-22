@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

REM Set log file to user directory to avoid permission issues
set "LOGFILE=%USERPROFILE%\chaoxing_install.log"
set PYTHONIOENCODING=utf-8
set PIP_DISABLE_PIP_VERSION_CHECK=1

REM Initialize log file
echo ================================================= > "%LOGFILE%" 2>nul
echo Startup time: %date% %time% >> "%LOGFILE%" 2>nul
echo Current dir: %cd% >> "%LOGFILE%" 2>nul
echo Log file: %LOGFILE% >> "%LOGFILE%" 2>nul
echo ================================================= >> "%LOGFILE%" 2>nul

echo [1/5] Check Python environment...
echo [DEBUG] Check Python environment... >> "%LOGFILE%" 2>nul

REM Set virtual environment path to user data directory
set "VENV_PATH=%USERPROFILE%\chaoxing_venv"

REM Check if virtual environment exists
if exist "%VENV_PATH%\Scripts\python.exe" (
    set "PYEXE=%VENV_PATH%\Scripts\python.exe"
    echo [DEBUG] Found venv Python: !PYEXE! >> "%LOGFILE%" 2>nul
    goto :check_deps
)

REM Find system Python installation
set "PYEXE="
echo [DEBUG] Searching for Python interpreters... >> "%LOGFILE%" 2>nul

REM Try py launcher
where py >> "%LOGFILE%" 2>&1
if !errorlevel! == 0 (
    echo [DEBUG] Testing py launcher... >> "%LOGFILE%" 2>nul
    py --version >> "%LOGFILE%" 2>&1
    if !errorlevel! == 0 (
        set "PYEXE=py"
        echo [DEBUG] Found working py launcher >> "%LOGFILE%" 2>nul
    ) else (
        echo [DEBUG] py launcher exists but version check failed >> "%LOGFILE%" 2>nul
    )
)

REM If py fails, try python command
if "!PYEXE!" == "" (
    where python >> "%LOGFILE%" 2>&1
    if !errorlevel! == 0 (
        echo [DEBUG] Testing python command... >> "%LOGFILE%" 2>nul
        REM Check if it's Microsoft Store placeholder
        python --version > nul 2>&1
        if !errorlevel! == 0 (
            REM Check if output contains real version info
            python --version 2>&1 | findstr /C:"Python" > nul
            if !errorlevel! == 0 (
                set "PYEXE=python"
                echo [DEBUG] Found working python command >> "%LOGFILE%" 2>nul
            ) else (
                echo [DEBUG] python is Microsoft Store placeholder, skipping >> "%LOGFILE%" 2>nul
            )
        ) else (
            echo [DEBUG] python command exists but version check failed >> "%LOGFILE%" 2>nul
        )
    )
)

REM If still fails, try python3 command
if "!PYEXE!" == "" (
    where python3 >> "%LOGFILE%" 2>&1
    if !errorlevel! == 0 (
        echo [DEBUG] Testing python3 command... >> "%LOGFILE%" 2>nul
        REM Check if it's Microsoft Store placeholder
        python3 --version > nul 2>&1
        if !errorlevel! == 0 (
            REM Check if output contains real version info
            python3 --version 2>&1 | findstr /C:"Python" > nul
            if !errorlevel! == 0 (
                set "PYEXE=python3"
                echo [DEBUG] Found working python3 command >> "%LOGFILE%" 2>nul
            ) else (
                echo [DEBUG] python3 is Microsoft Store placeholder, skipping >> "%LOGFILE%" 2>nul
            )
        ) else (
            echo [DEBUG] python3 command exists but version check failed >> "%LOGFILE%" 2>nul
        )
    )
)

if "!PYEXE!"=="" (
    echo Python not found. Installing Python...
    echo [ERROR] No working Python installation found >> "%LOGFILE%" 2>nul
    
    if exist "installer\auto_install_python.bat" (
        echo Starting automatic Python installation...
        call "installer\auto_install_python.bat"
        set "AUTO_RESULT=!errorlevel!"
        
        if !AUTO_RESULT! == 0 (
            echo Python installation completed! Restarting application...
            timeout /t 2 /nobreak >nul
            "%~f0"
            exit /b 0
        ) else (
            echo Automatic installation failed. Please install Python manually.
            goto :manual_install_instructions
        )
    ) else (
        goto :manual_install_instructions
    )
    
    :manual_install_instructions
    echo.
    echo MANUAL INSTALLATION REQUIRED:
    echo 1. Download Python 3.10+ from: https://www.python.org/downloads/
    echo 2. During installation, CHECK "Add Python to PATH"
    echo 3. If you have Microsoft Store Python, DISABLE it:
    echo    - Settings, Apps, Advanced app settings, App execution aliases
    echo    - Turn OFF python.exe and python3.exe
    echo 4. Restart command prompt after installation
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

REM Verify Python version
echo [2/5] Verify Python version...
echo [DEBUG] Testing Python: !PYEXE! >> "%LOGFILE%" 2>nul
!PYEXE! --version >> "%LOGFILE%" 2>&1
if !errorlevel! neq 0 (
    echo Python version check failed
    echo [ERROR] Python version check failed >> "%LOGFILE%" 2>nul
    pause
    exit /b 1
)

REM Create virtual environment
echo [3/5] Create virtual environment if needed...
if not exist "%VENV_PATH%\Scripts\python.exe" (
    echo Creating virtual environment...
    echo [DEBUG] Creating venv: !PYEXE! -m venv "%VENV_PATH%" >> "%LOGFILE%" 2>nul
    !PYEXE! -m venv "%VENV_PATH%" >> "%LOGFILE%" 2>nul
    if !errorlevel! neq 0 (
        echo Failed to create virtual environment
        echo [ERROR] venv creation failed >> "%LOGFILE%" 2>nul
        pause
        exit /b 1
    )
) else (
    echo Virtual environment exists, skip creation
)

REM Switch to virtual environment Python
set "PYEXE=%VENV_PATH%\Scripts\python.exe"

:check_deps
REM Check dependency installation
echo [4/5] Check and install dependencies...
if not exist "chaoxing\requirements.txt" (
    echo [WARNING] chaoxing\requirements.txt not found
    goto :launch_app
)

if exist "%VENV_PATH%\.deps_installed" (
    echo Dependencies already installed, skipping...
    goto :launch_app
)

echo Installing dependencies online...

REM Upgrade pip
echo Upgrading pip...
echo [DEBUG] Upgrading pip with progress... >> "%LOGFILE%" 2>nul
"%PYEXE%" -m pip install --upgrade pip --disable-pip-version-check --no-cache-dir --progress-bar on

REM Install dependencies with enhanced progress display
echo.
echo Installing project dependencies with enhanced progress display...
echo [DEBUG] Attempting to use PowerShell enhanced installer... >> "%LOGFILE%" 2>nul

REM Try to use PowerShell enhanced installer first (if available)
if exist "install_with_progress.ps1" (
    powershell -ExecutionPolicy Bypass -File "install_with_progress.ps1" -PythonExe "%PYEXE%" -RequirementsFile "chaoxing\requirements.txt" 2>nul
    set "PS_RESULT=!errorlevel!"
    echo [DEBUG] PowerShell installer exit code: !PS_RESULT! >> "%LOGFILE%" 2>nul
    
    if !PS_RESULT! == 0 (
        echo [INFO] Enhanced PowerShell installation completed successfully
        echo [DEBUG] Enhanced PowerShell installation completed successfully >> "%LOGFILE%" 2>nul
        goto :ensure_critical
    ) else (
        echo [WARNING] PowerShell enhanced installer failed, falling back to basic installation
        echo [DEBUG] PowerShell installer failed, using fallback method >> "%LOGFILE%" 2>nul
    )
) else (
    echo [DEBUG] PowerShell enhanced installer not found, using basic method >> "%LOGFILE%" 2>nul
)

REM Fallback to basic installation with progress
echo.
echo Installing dependencies with basic progress display...
echo [DEBUG] Installing deps with progress: "%PYEXE%" -m pip install -r chaoxing\requirements.txt >> "%LOGFILE%" 2>nul
echo ===============================================================
echo                  Installing Dependencies                     
echo ===============================================================
"%PYEXE%" -m pip install -r "chaoxing\requirements.txt" --disable-pip-version-check --no-cache-dir --progress-bar on --verbose
set "PIP_RESULT=!errorlevel!"
echo [DEBUG] pip install exit code: !PIP_RESULT! >> "%LOGFILE%" 2>nul

if !PIP_RESULT! neq 0 (
    echo [WARNING] Some dependencies may have failed to install
    echo [DEBUG] Attempting to install core dependencies individually... >> "%LOGFILE%" 2>nul
    
    REM Install core dependencies individually with progress
    echo.
    echo Installing core dependencies individually...
    echo ===============================================================
    echo               Installing Core Dependencies                   
    echo ===============================================================
    "%PYEXE%" -m pip install requests httpx pyaes beautifulsoup4 lxml loguru pycryptodome PySide6 openai urllib3 --disable-pip-version-check --no-cache-dir --progress-bar on --verbose
    if !errorlevel! neq 0 (
        echo [ERROR] Core dependency installation failed, see %LOGFILE%
        echo [ERROR] Core dependencies installation failed >> "%LOGFILE%" 2>nul
        echo.
        echo Check %LOGFILE% for detailed error information
        pause
        exit /b 1
    ) else (
        echo [INFO] Core dependencies installed successfully
        echo [DEBUG] Core dependencies installed successfully >> "%LOGFILE%" 2>nul
    )
)

:ensure_critical

REM Ensure critical modules are installed (fix for missing httpx)
echo Ensuring critical modules are available...
echo [DEBUG] Installing critical modules to fix common issues... >> "%LOGFILE%" 2>nul

REM Force install httpx (most common missing module)
echo Installing httpx with progress...
"%PYEXE%" -m pip install httpx --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
if !errorlevel! == 0 (
    echo [DEBUG] httpx ensured >> "%LOGFILE%" 2>nul
)

REM Ensure openai is available (for AI features)
echo Installing openai with progress...
"%PYEXE%" -m pip install openai --disable-pip-version-check --no-cache-dir --upgrade --progress-bar on
if !errorlevel! == 0 (
    echo [DEBUG] openai ensured >> "%LOGFILE%" 2>nul
)

REM Verify critical dependencies
echo Verifying dependencies...
"%PYEXE%" -c "import Crypto; print('pycryptodome OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo Critical dependency verification failed
    pause
    exit /b 1
)

REM Verify PySide6 specifically (GUI framework)
echo Checking PySide6 module...
"%PYEXE%" -c "import PySide6; print('PySide6 OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] PySide6 not found, installing now...
    echo [DEBUG] PySide6 missing, force installing... >> "%LOGFILE%" 2>nul
    echo Installing PySide6 with progress...
    "%PYEXE%" -m pip install PySide6>=6.7.0 --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to install PySide6
        echo [ERROR] PySide6 installation failed >> "%LOGFILE%" 2>nul
        echo.
        echo PySide6 is required for the GUI. Please install it manually:
        echo "%PYEXE%" -m pip install PySide6
        pause
        exit /b 1
    )
    echo [INFO] PySide6 installed successfully
    echo [DEBUG] PySide6 installed successfully >> "%LOGFILE%" 2>nul
)

REM Verify httpx specifically (most common issue)
echo Checking httpx module...
"%PYEXE%" -c "import httpx; print('httpx OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] httpx not found, installing now...
    echo [DEBUG] httpx missing, force installing... >> "%LOGFILE%" 2>nul
    echo Installing httpx with progress...
    "%PYEXE%" -m pip install httpx --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to install httpx
        echo [ERROR] httpx installation failed >> "%LOGFILE%" 2>nul
        pause
        exit /b 1
    )
    echo [INFO] httpx installed successfully
    echo [DEBUG] httpx installed successfully >> "%LOGFILE%" 2>nul
)

echo Dependencies installed and verified successfully

REM Create installation marker
> "%VENV_PATH%\.deps_installed" echo installed by run_gui at %date% %time%

:launch_app
REM Final critical modules check before starting app
echo [CRITICAL] Final dependency check before starting...
echo [DEBUG] Final critical modules check before app start >> "%LOGFILE%" 2>nul

REM Check httpx
"%PYEXE%" -c "import httpx; print('httpx available')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [EMERGENCY] httpx still missing, force installing now...
    echo [EMERGENCY] httpx missing at startup, emergency install >> "%LOGFILE%" 2>nul
    "%PYEXE%" -m pip install httpx --force-reinstall --no-cache-dir --disable-pip-version-check >> "%LOGFILE%" 2>&1
    if !errorlevel! neq 0 (
        echo [CRITICAL ERROR] Cannot install httpx - application cannot start
        echo [CRITICAL ERROR] Emergency httpx install failed >> "%LOGFILE%" 2>nul
        echo.
        echo Please check your internet connection and try again.
        echo Log file: %LOGFILE%
        pause
        exit /b 1
    )
    echo [SUCCESS] httpx emergency install completed
    echo [DEBUG] httpx emergency install successful >> "%LOGFILE%" 2>nul
)

REM Check openai
"%PYEXE%" -c "import openai; print('openai available')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [EMERGENCY] openai still missing, force installing now...
    echo [EMERGENCY] openai missing at startup, emergency install >> "%LOGFILE%" 2>nul
    "%PYEXE%" -m pip install openai --force-reinstall --no-cache-dir --disable-pip-version-check >> "%LOGFILE%" 2>&1
    if !errorlevel! neq 0 (
        echo [CRITICAL ERROR] Cannot install openai - application cannot start
        echo [CRITICAL ERROR] Emergency openai install failed >> "%LOGFILE%" 2>nul
        echo.
        echo Please check your internet connection and try again.
        echo Log file: %LOGFILE%
        pause
        exit /b 1
    )
    echo [SUCCESS] openai emergency install completed
    echo [DEBUG] openai emergency install successful >> "%LOGFILE%" 2>nul
)

REM Check urllib3
"%PYEXE%" -c "import urllib3; print('urllib3 available')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [EMERGENCY] urllib3 still missing, force installing now...
    echo [EMERGENCY] urllib3 missing at startup, emergency install >> "%LOGFILE%" 2>nul
    "%PYEXE%" -m pip install urllib3 --force-reinstall --no-cache-dir --disable-pip-version-check >> "%LOGFILE%" 2>&1
    if !errorlevel! neq 0 (
        echo [CRITICAL ERROR] Cannot install urllib3 - application cannot start
        echo [CRITICAL ERROR] Emergency urllib3 install failed >> "%LOGFILE%" 2>nul
        echo.
        echo Please check your internet connection and try again.
        echo Log file: %LOGFILE%
        pause
        exit /b 1
    )
    echo [SUCCESS] urllib3 emergency install completed
    echo [DEBUG] urllib3 emergency install successful >> "%LOGFILE%" 2>nul
)

REM Start application
echo [5/5] Starting application...
echo [DEBUG] Starting app: "%PYEXE%" -m chaoxing.run_gui >> "%LOGFILE%" 2>nul
"%PYEXE%" -m chaoxing.run_gui
set "EXIT_CODE=!errorlevel!"

if !EXIT_CODE! neq 0 (
    echo Application exited with error code: !EXIT_CODE!
    pause
)

exit /b !EXIT_CODE!
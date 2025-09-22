@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

REM Set log file to user directory to avoid permission issues
set "LOGFILE=%USERPROFILE%\chaoxing_post_install.log"

REM Initialize log file
echo ================================================= > "%LOGFILE%" 2>nul
echo Post-install start time: %date% %time% >> "%LOGFILE%" 2>nul
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
    goto :upgrade_pip
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
    echo [ERROR] No working Python installation found
    echo [ERROR] Searched for: py, python, python3 >> "%LOGFILE%" 2>nul
    echo [ERROR] Common causes: >> "%LOGFILE%" 2>nul
    echo [ERROR] 1. Python not installed >> "%LOGFILE%" 2>nul
    echo [ERROR] 2. Python not added to PATH >> "%LOGFILE%" 2>nul
    echo [ERROR] 3. Microsoft Store Python placeholder detected >> "%LOGFILE%" 2>nul
    echo [ERROR] 4. Corrupt Python installation >> "%LOGFILE%" 2>nul
    echo.
    echo ❌ PYTHON NOT FOUND
    echo.
    echo This application requires Python to run.
    echo.
    echo 🤖 AUTOMATIC INSTALLATION AVAILABLE
    echo.
    echo We can automatically download and install Python for you.
    echo This will install Python 3.11.9 with proper PATH configuration.
    echo.
    set /p "AUTO_INSTALL=Do you want to automatically install Python? (Y/N): "
    
    if /i "!AUTO_INSTALL!"=="Y" (
        echo [DEBUG] User chose automatic Python installation >> "%LOGFILE%" 2>nul
        if exist "auto_install_python.bat" (
            echo.
            echo Starting automatic Python installation...
            call "auto_install_python.bat"
            set "AUTO_RESULT=!errorlevel!"
            
            if !AUTO_RESULT! == 0 (
                echo [DEBUG] Automatic installation completed, retrying detection >> "%LOGFILE%" 2>nul
                echo.
                echo 🔄 Retrying Python detection after installation...
                goto :retry_python_detection
            ) else (
                echo [DEBUG] Automatic installation failed with code: !AUTO_RESULT! >> "%LOGFILE%" 2>nul
                goto :manual_install_instructions
            )
        ) else (
            echo [ERROR] Auto-installer not found: auto_install_python.bat >> "%LOGFILE%" 2>nul
            goto :manual_install_instructions
        )
    ) else (
        echo [DEBUG] User chose manual Python installation >> "%LOGFILE%" 2>nul
        goto :manual_install_instructions
    )
    
    :manual_install_instructions
    echo.
    echo 🔧 MANUAL INSTALLATION REQUIRED:
    echo 1. Download Python 3.10+ from: https://www.python.org/downloads/
    echo 2. During installation, CHECK "Add Python to PATH"
    echo 3. If you have Microsoft Store Python, DISABLE it:
    echo    - Settings ^> Apps ^> Advanced app settings ^> App execution aliases
    echo    - Turn OFF "python.exe" and "python3.exe"
    echo 4. Restart command prompt after installation
    echo 5. Run this installer again
    echo.
    echo Full diagnostic saved to: %LOGFILE%
    pause
    exit /b 1
    
    :retry_python_detection
    REM Reset PYEXE and retry detection
    set "PYEXE="
    echo [DEBUG] Retrying Python detection after auto-install... >> "%LOGFILE%" 2>nul
    
    REM Refresh PATH from registry
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYS_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
    set "PATH=%SYS_PATH%;%USER_PATH%"
    
    REM Try py launcher again
    where py >> "%LOGFILE%" 2>&1
    if !errorlevel! == 0 (
        py --version >> "%LOGFILE%" 2>&1
        if !errorlevel! == 0 (
            set "PYEXE=py"
            echo [DEBUG] Found py launcher after auto-install >> "%LOGFILE%" 2>nul
            goto :continue_with_python
        )
    )
    
    REM Try python command again
    where python >> "%LOGFILE%" 2>&1
    if !errorlevel! == 0 (
        python --version > nul 2>&1
        if !errorlevel! == 0 (
            python --version 2>&1 | findstr /C:"Python" > nul
            if !errorlevel! == 0 (
                set "PYEXE=python"
                echo [DEBUG] Found python command after auto-install >> "%LOGFILE%" 2>nul
                goto :continue_with_python
            )
        )
    )
    
    REM If still no Python found
    if "!PYEXE!"=="" (
        echo [WARNING] Python may be installed but not detected yet
        echo [WARNING] Python still not detected after auto-install >> "%LOGFILE%" 2>nul
        echo.
        echo ⚠️  Python installation may require a system restart.
        echo    Please restart your computer and run this installer again.
        echo.
        pause
        exit /b 1
    )
    
    :continue_with_python
    echo ✅ Python detected successfully after installation!
    echo [DEBUG] Continuing with Python: !PYEXE! >> "%LOGFILE%" 2>nul
)

REM Verify Python version
echo [2/5] Verify Python version...
echo [DEBUG] Verify Python version... >> "%LOGFILE%" 2>nul
echo [DEBUG] Testing Python: !PYEXE! >> "%LOGFILE%" 2>nul
!PYEXE! --version >> "%LOGFILE%" 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Python version check failed with error code: !errorlevel!
    echo [ERROR] Python version check failed with error code: !errorlevel! >> "%LOGFILE%" 2>nul
    echo [DEBUG] Trying alternative version check... >> "%LOGFILE%" 2>nul
    !PYEXE! -c "import sys; print('Python', sys.version)" >> "%LOGFILE%" 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Alternative Python check also failed
        echo [ERROR] Alternative Python check also failed >> "%LOGFILE%" 2>nul
        pause
        exit /b 1
    ) else (
        echo [INFO] Alternative Python check succeeded
        echo [INFO] Alternative Python check succeeded >> "%LOGFILE%" 2>nul
    )
) else (
    echo [DEBUG] Python version check succeeded >> "%LOGFILE%" 2>nul
)

REM Create virtual environment
echo [3/5] Create virtual environment...
if not exist "%VENV_PATH%\Scripts\python.exe" (
    echo Creating virtual environment, please wait...
    echo [DEBUG] Creating venv: !PYEXE! -m venv "%VENV_PATH%" >> "%LOGFILE%" 2>nul
    !PYEXE! -m venv "%VENV_PATH%" >> "%LOGFILE%" 2>nul
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to create virtual environment
        echo [ERROR] venv creation failed, error code: !errorlevel! >> "%LOGFILE%" 2>nul
        pause
        exit /b 1
    )
    echo [DEBUG] Virtual environment created successfully >> "%LOGFILE%" 2>nul
) else (
    echo Virtual environment already exists
    echo [DEBUG] Venv already exists >> "%LOGFILE%" 2>nul
)

REM Switch to virtual environment Python
set "PYEXE=%VENV_PATH%\Scripts\python.exe"

:upgrade_pip
REM Upgrade pip
echo [4/5] Upgrading pip and installing dependencies...
echo Upgrading pip with progress display...
echo [DEBUG] Upgrading pip with progress... >> "%LOGFILE%" 2>nul
"%PYEXE%" -m pip install --upgrade pip --disable-pip-version-check --no-cache-dir --progress-bar on
if !errorlevel! neq 0 (
    echo [WARNING] pip upgrade failed, continue with installation
    echo [WARNING] pip upgrade failed, error code: !errorlevel! >> "%LOGFILE%" 2>nul
)

if not exist "chaoxing\requirements.txt" (
    echo [WARNING] chaoxing\requirements.txt not found
    echo [WARNING] requirements.txt not found >> "%LOGFILE%" 2>nul
    goto :verify_env
)

REM Install dependencies with enhanced progress display
echo.
echo [5/5] Installing dependencies with enhanced progress display...
echo [DEBUG] Attempting to use PowerShell enhanced installer... >> "%LOGFILE%" 2>nul

REM Try to use PowerShell enhanced installer first
powershell -ExecutionPolicy Bypass -File "post_install_progress.ps1" -PythonExe "%PYEXE%" -RequirementsFile "chaoxing\requirements.txt" -LogFile "%LOGFILE%" 2>nul
set "PS_RESULT=!errorlevel!"
echo [DEBUG] PowerShell installer exit code: !PS_RESULT! >> "%LOGFILE%" 2>nul

if !PS_RESULT! == 0 (
    echo [INFO] Enhanced PowerShell installation completed successfully
    echo [DEBUG] Enhanced PowerShell installation completed successfully >> "%LOGFILE%" 2>nul
    goto :verify_env
) else (
    echo [WARNING] PowerShell enhanced installer failed, falling back to basic installation
    echo [DEBUG] PowerShell installer failed, using fallback method >> "%LOGFILE%" 2>nul
)

REM Fallback to basic installation with progress
echo.
echo Installing dependencies with basic progress display...
echo ===============================================================
echo                  Installing Dependencies                     
echo ===============================================================
echo [DEBUG] Installing deps with progress: "%PYEXE%" -m pip install -r chaoxing\requirements.txt >> "%LOGFILE%" 2>nul
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
        echo [ERROR] Core dependency installation failed
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

REM Ensure critical modules are installed (fix for missing httpx)
echo Ensuring critical modules are installed...
echo [DEBUG] Installing critical modules to fix common issues... >> "%LOGFILE%" 2>nul

REM Force install httpx (most common missing module)
"%PYEXE%" -m pip install httpx --disable-pip-version-check --no-cache-dir --force-reinstall >> "%LOGFILE%" 2>&1
if !errorlevel! == 0 (
    echo [DEBUG] httpx installed/updated successfully >> "%LOGFILE%" 2>nul
)

REM Force install openai (for AI features)
"%PYEXE%" -m pip install openai --disable-pip-version-check --no-cache-dir --upgrade >> "%LOGFILE%" 2>&1
if !errorlevel! == 0 (
    echo [DEBUG] openai installed/updated successfully >> "%LOGFILE%" 2>nul
)

REM Force install urllib3 (HTTP dependency)
"%PYEXE%" -m pip install urllib3 --disable-pip-version-check --no-cache-dir --upgrade >> "%LOGFILE%" 2>&1
if !errorlevel! == 0 (
    echo [DEBUG] urllib3 installed/updated successfully >> "%LOGFILE%" 2>nul
)

REM Create installation marker
> "%VENV_PATH%\.deps_installed" echo installed by post_install at %date% %time%
echo [DEBUG] Created installation marker file >> "%LOGFILE%" 2>nul

:verify_env
REM Verify environment
echo [5/5] Verifying installation...
echo [DEBUG] Verifying environment... >> "%LOGFILE%" 2>nul

REM Test Python version
"%PYEXE%" -c "import sys; print('Python version:', sys.version)" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [ERROR] Python environment verification failed
    echo [ERROR] Python environment verification failed >> "%LOGFILE%" 2>nul
    pause
    exit /b 1
)

REM Verify critical dependencies
echo Verifying critical dependencies...
"%PYEXE%" -c "import Crypto; print('pycryptodome OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] pycryptodome verification failed
    echo [WARNING] Crypto module import failed >> "%LOGFILE%" 2>nul
)

echo Verifying PySide6 module...
"%PYEXE%" -c "import PySide6; print('PySide6 OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] PySide6 verification failed, reinstalling...
    echo [WARNING] PySide6 import failed, reinstalling... >> "%LOGFILE%" 2>nul
    echo Installing PySide6 with progress...
    "%PYEXE%" -m pip install PySide6>=6.7.0 --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! == 0 (
        echo [INFO] PySide6 reinstalled successfully
        echo [DEBUG] PySide6 reinstalled successfully >> "%LOGFILE%" 2>nul
    ) else (
        echo [ERROR] PySide6 reinstallation failed
        echo [ERROR] PySide6 reinstallation failed >> "%LOGFILE%" 2>nul
    )
)

REM Specifically verify critical modules (common login issues)
echo Verifying httpx module...
"%PYEXE%" -c "import httpx; print('httpx OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] httpx verification failed, reinstalling...
    echo [WARNING] httpx import failed, reinstalling... >> "%LOGFILE%" 2>nul
    echo Installing httpx with progress...
    "%PYEXE%" -m pip install httpx --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! == 0 (
        echo [INFO] httpx reinstalled successfully
        echo [DEBUG] httpx reinstalled successfully >> "%LOGFILE%" 2>nul
    ) else (
        echo [ERROR] httpx reinstallation failed
        echo [ERROR] httpx reinstallation failed >> "%LOGFILE%" 2>nul
    )
)

echo Verifying openai module...
"%PYEXE%" -c "import openai; print('openai OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] openai verification failed, reinstalling...
    echo [WARNING] openai import failed, reinstalling... >> "%LOGFILE%" 2>nul
    echo Installing openai with progress...
    "%PYEXE%" -m pip install openai --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! == 0 (
        echo [INFO] openai reinstalled successfully
        echo [DEBUG] openai reinstalled successfully >> "%LOGFILE%" 2>nul
    ) else (
        echo [ERROR] openai reinstallation failed
        echo [ERROR] openai reinstallation failed >> "%LOGFILE%" 2>nul
    )
)

echo Verifying urllib3 module...
"%PYEXE%" -c "import urllib3; print('urllib3 OK')" >> "%LOGFILE%" 2>nul
if !errorlevel! neq 0 (
    echo [WARNING] urllib3 verification failed, reinstalling...
    echo [WARNING] urllib3 import failed, reinstalling... >> "%LOGFILE%" 2>nul
    echo Installing urllib3 with progress...
    "%PYEXE%" -m pip install urllib3 --disable-pip-version-check --no-cache-dir --force-reinstall --progress-bar on
    if !errorlevel! == 0 (
        echo [INFO] urllib3 reinstalled successfully
        echo [DEBUG] urllib3 reinstalled successfully >> "%LOGFILE%" 2>nul
    ) else (
        echo [ERROR] urllib3 reinstallation failed
        echo [ERROR] urllib3 reinstallation failed >> "%LOGFILE%" 2>nul
    )
)

echo Installation completed successfully!
echo [DEBUG] Post-install completed successfully >> "%LOGFILE%" 2>nul
echo.
echo You can now run the application using the desktop shortcut
echo or by running run_gui.bat in the installation folder.
echo.
echo Installation log saved to: %LOGFILE%
pause
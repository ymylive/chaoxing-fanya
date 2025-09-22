@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ================================================
echo      Python Environment Cleanup Tool
echo ================================================
echo.

REM Get current timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD% %HH%:%Min%:%Sec%"

echo [%timestamp%] Starting Python environment cleanup...
echo.

REM 1. Clean project virtual environment
echo [1/6] Cleaning project virtual environment...
if exist "%USERPROFILE%\chaoxing_venv" (
    echo   Removing virtual environment: %USERPROFILE%\chaoxing_venv
    rmdir /s /q "%USERPROFILE%\chaoxing_venv" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Virtual environment removed successfully
    ) else (
        echo   ✗ Failed to remove virtual environment
    )
) else (
    echo   ✓ No virtual environment found
)

REM 2. Clean installation logs
echo.
echo [2/6] Cleaning installation logs...
set "log_cleaned=0"

if exist "%USERPROFILE%\chaoxing_install.log" (
    del /f /q "%USERPROFILE%\chaoxing_install.log" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Removed chaoxing_install.log
        set /a log_cleaned+=1
    )
)

if exist "%USERPROFILE%\chaoxing_post_install.log" (
    del /f /q "%USERPROFILE%\chaoxing_post_install.log" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Removed chaoxing_post_install.log
        set /a log_cleaned+=1
    )
)

if exist "%USERPROFILE%\python_auto_install.log" (
    del /f /q "%USERPROFILE%\python_auto_install.log" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Removed python_auto_install.log
        set /a log_cleaned+=1
    )
)

if exist "%USERPROFILE%\python_debug.log" (
    del /f /q "%USERPROFILE%\python_debug.log" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Removed python_debug.log
        set /a log_cleaned+=1
    )
)

if !log_cleaned! == 0 (
    echo   ✓ No installation logs found
) else (
    echo   ✓ Cleaned !log_cleaned! log files
)

REM 3. Clean saved credentials
echo.
echo [3/6] Cleaning saved credentials...
if exist "%USERPROFILE%\.chaoxing_gui" (
    echo   Removing saved login credentials...
    rmdir /s /q "%USERPROFILE%\.chaoxing_gui" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Saved credentials removed
    ) else (
        echo   ✗ Failed to remove credentials
    )
) else (
    echo   ✓ No saved credentials found
)

REM 4. Clean pip cache
echo.
echo [4/6] Cleaning pip cache...
pip cache purge >nul 2>&1
if !errorlevel! == 0 (
    echo   ✓ pip cache purged successfully
) else (
    echo   ⚠ pip cache purge failed (pip may not be available)
)

REM Manual pip cache cleanup
if exist "%LOCALAPPDATA%\pip\cache" (
    echo   Removing manual pip cache...
    rmdir /s /q "%LOCALAPPDATA%\pip\cache" >nul 2>&1
    if !errorlevel! == 0 (
        echo   ✓ Manual pip cache removed
    ) else (
        echo   ⚠ Manual pip cache removal failed
    )
) else (
    echo   ✓ No manual pip cache found
)

REM 5. Clean Python compiled cache
echo.
echo [5/6] Cleaning Python compiled cache...
set "pycache_count=0"

REM Count and remove __pycache__ directories
for /f %%i in ('dir /s /b /ad __pycache__ 2^>nul ^| find /c /v ""') do set pycache_count=%%i
if !pycache_count! gtr 0 (
    echo   Found !pycache_count! __pycache__ directories, removing...
    for /f "delims=" %%i in ('dir /s /b /ad __pycache__ 2^>nul') do (
        rmdir /s /q "%%i" >nul 2>&1
    )
    echo   ✓ __pycache__ directories removed
) else (
    echo   ✓ No __pycache__ directories found
)

REM Count and remove .pyc files
set "pyc_count=0"
for /f %%i in ('dir /s /b *.pyc 2^>nul ^| find /c /v ""') do set pyc_count=%%i
if !pyc_count! gtr 0 (
    echo   Found !pyc_count! .pyc files, removing...
    del /s /q *.pyc >nul 2>&1
    echo   ✓ .pyc files removed
) else (
    echo   ✓ No .pyc files found
)

REM 6. Clean temporary files
echo.
echo [6/6] Cleaning temporary files...
if exist "%TEMP%\pip-*" (
    echo   Removing pip temporary files...
    rmdir /s /q "%TEMP%\pip-*" >nul 2>&1
    echo   ✓ pip temporary files cleaned
) else (
    echo   ✓ No pip temporary files found
)

REM Summary
echo.
echo ================================================
echo              Cleanup Summary
echo ================================================
echo ✓ Virtual environment cleaned
echo ✓ Installation logs cleaned
echo ✓ Saved credentials cleaned
echo ✓ pip cache cleaned
echo ✓ Python compiled cache cleaned
echo ✓ Temporary files cleaned
echo.
echo [%timestamp%] Python environment cleanup completed!
echo.
echo Note: You may need to reinstall dependencies next time you run the application.
echo.
pause




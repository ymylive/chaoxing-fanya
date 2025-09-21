@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

REM Environment hygiene
set "PYTHONIOENCODING=utf-8"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"

REM Prefer virtual environment if present
if exist ".venv\Scripts\python.exe" (
  set "PYEXE=.venv\Scripts\python.exe"
) else (
  where py >nul 2>nul && (set "PYEXE=py") || (
    where python >nul 2>nul && (set "PYEXE=python") || (
      where python3 >nul 2>nul && (set "PYEXE=python3") || (set "PYEXE=")
    )
  )
)

if "%PYEXE%"=="" (
  echo 未找到 Python，請先安裝 Python 3.10+ 並配置 PATH。
  pause
  exit /b 1
)

REM Install dependencies on first run if missing
if exist "chaoxing\requirements.txt" (
  REM Ensure critical deps (including newly added ones) are present
  %PYEXE% -m pip show pycryptodome >nul 2>nul || %PYEXE% -m pip install -r "chaoxing\requirements.txt" --no-input
)

REM Launch GUI
%PYEXE% -m chaoxing.run_gui
exit /b %errorlevel%



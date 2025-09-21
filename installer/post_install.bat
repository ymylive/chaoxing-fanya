@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

echo [1/4] 检查 Python...
set PYEXE=
if exist ".venv\Scripts\python.exe" (
  set "PYEXE=.venv\Scripts\python.exe"
) else (
  where py >nul 2>nul && (set "PYEXE=py") || (
    where python >nul 2>nul && (set "PYEXE=python") || (
      where python3 >nul 2>nul && (set "PYEXE=python3")
    )
  )
)
if "%PYEXE%"=="" (
  echo 未检测到 Python，请安装 Python 3.10+ 后重试。
  exit /b 1
)

echo [2/4] 创建虚拟环境 .venv（若不存在）...
if not exist ".venv\Scripts\activate.bat" (
  %PYEXE% -m venv .venv
)
set "PYEXE=.venv\Scripts\python.exe"

echo [3/4] 升级 pip...
"%PYEXE%" -m pip install --upgrade pip --disable-pip-version-check

echo [4/4] 安装依赖（在线）...
if exist "chaoxing\requirements.txt" (
  "%PYEXE%" -m pip install -r "chaoxing\requirements.txt" --disable-pip-version-check
) else (
  echo 未找到 chaoxing\requirements.txt，跳过依赖安装
)

echo 依赖安装完成。
exit /b 0



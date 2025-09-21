@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0\.."

echo [1/3] 定位 Inno Setup 编译器(ISCC)...
set "ISCC="
where iscc.exe >nul 2>nul
if %ERRORLEVEL%==0 (
  set "ISCC=iscc.exe"
)
if not defined ISCC (
  if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
  )
)
if not defined ISCC (
  if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
  )
)
if not defined ISCC (
  echo 未找到 Inno Setup (ISCC)。请安装 Inno Setup 6 后重试: https://jrsoftware.org/isinfo.php
  exit /b 1
)
echo 使用编译器: %ISCC%

echo [2/3] 环境检查...
if not exist "chaoxing\gui\main_gui.py" (
  echo 未找到 chaoxing 目录，请在项目根目录执行本脚本。
  exit /b 1
)
if not exist "installer\chaoxing_installer.iss" (
  echo 未找到 installer\chaoxing_installer.iss
  exit /b 1
)

echo [3/3] 编译安装包...
"%ISCC%" "installer\chaoxing_installer.iss"
echo.

if exist "installer\Chaoxing-Setup.exe" (
  echo 成功: 安装包已生成 -> installer\Chaoxing-Setup.exe
) else (
  echo 失败: 未生成安装包，请查看 ISCC 输出信息。
)

exit /b %ERRORLEVEL%



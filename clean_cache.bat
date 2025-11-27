@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════════════════════════════╗
echo ║           超星学习通自动化工具 - 清理缓存                   ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set "SCRIPT_DIR=%~dp0"
set "COUNT=0"

echo 正在清理缓存文件...
echo.

REM 清理 __pycache__ 目录
echo [1] 清理 __pycache__ 目录...
for /d /r "%SCRIPT_DIR%" %%d in (__pycache__) do (
    if exist "%%d" (
        echo    删除: %%d
        rd /s /q "%%d" 2>nul
        set /a COUNT+=1
    )
)

REM 清理 .pyc 文件
echo [2] 清理 .pyc 文件...
for /r "%SCRIPT_DIR%" %%f in (*.pyc) do (
    if exist "%%f" (
        echo    删除: %%f
        del /q "%%f" 2>nul
        set /a COUNT+=1
    )
)

REM 清理日志文件
echo [3] 清理日志文件...
if exist "%SCRIPT_DIR%chaoxing.log" (
    echo    删除: chaoxing.log
    del /q "%SCRIPT_DIR%chaoxing.log" 2>nul
    set /a COUNT+=1
)
for %%f in ("%SCRIPT_DIR%*.log") do (
    if exist "%%f" (
        echo    删除: %%f
        del /q "%%f" 2>nul
        set /a COUNT+=1
    )
)

REM 清理缓存JSON
echo [4] 清理缓存文件...
if exist "%SCRIPT_DIR%cache.json" (
    echo    删除: cache.json
    del /q "%SCRIPT_DIR%cache.json" 2>nul
    set /a COUNT+=1
)

REM 清理 cookies (用户敏感信息)
echo [5] 清理用户敏感信息...
if exist "%SCRIPT_DIR%cookies.txt" (
    echo    删除: cookies.txt
    del /q "%SCRIPT_DIR%cookies.txt" 2>nul
    set /a COUNT+=1
)

REM 清理配置文件中的敏感信息
if exist "%SCRIPT_DIR%config.ini" (
    echo    删除: config.ini
    del /q "%SCRIPT_DIR%config.ini" 2>nul
    set /a COUNT+=1
)

REM 清理旧的便携版
echo [6] 清理旧的便携版...
if exist "%SCRIPT_DIR%chaoxing_portable" (
    echo    删除: chaoxing_portable 目录
    rd /s /q "%SCRIPT_DIR%chaoxing_portable" 2>nul
    set /a COUNT+=1
)
if exist "%SCRIPT_DIR%chaoxing_portable.zip" (
    echo    删除: chaoxing_portable.zip
    del /q "%SCRIPT_DIR%chaoxing_portable.zip" 2>nul
    set /a COUNT+=1
)
if exist "%SCRIPT_DIR%portable_build" (
    echo    删除: portable_build 目录
    rd /s /q "%SCRIPT_DIR%portable_build" 2>nul
    set /a COUNT+=1
)

REM 清理前端临时文件
echo [7] 清理前端临时文件...
if exist "%SCRIPT_DIR%web\.vite" (
    echo    删除: web\.vite
    rd /s /q "%SCRIPT_DIR%web\.vite" 2>nul
    set /a COUNT+=1
)
if exist "%SCRIPT_DIR%web\node_modules\.cache" (
    echo    删除: web\node_modules\.cache
    rd /s /q "%SCRIPT_DIR%web\node_modules\.cache" 2>nul
    set /a COUNT+=1
)

REM 清理 .pytest_cache
if exist "%SCRIPT_DIR%.pytest_cache" (
    echo    删除: .pytest_cache
    rd /s /q "%SCRIPT_DIR%.pytest_cache" 2>nul
    set /a COUNT+=1
)

REM 清理 .mypy_cache
if exist "%SCRIPT_DIR%.mypy_cache" (
    echo    删除: .mypy_cache
    rd /s /q "%SCRIPT_DIR%.mypy_cache" 2>nul
    set /a COUNT+=1
)

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                      清理完成！                              ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  已清理项目: !COUNT! 项                                       ║
echo ║                                                              ║
echo ║  清理内容:                                                   ║
echo ║    - __pycache__ 目录                                        ║
echo ║    - *.pyc 编译文件                                          ║
echo ║    - *.log 日志文件                                          ║
echo ║    - cache.json 缓存文件                                     ║
echo ║    - cookies.txt 登录信息                                    ║
echo ║    - config.ini 配置文件                                     ║
echo ║    - chaoxing_portable 目录和 zip                            ║
echo ║    - 前端临时缓存                                            ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
pause

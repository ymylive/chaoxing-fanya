@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════════════════════════════╗
echo ║         超星学习通自动化工具 - 便携版打包工具               ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set "SCRIPT_DIR=%~dp0"
set "BUILD_DIR=%SCRIPT_DIR%portable_build"
set "DIST_DIR=%SCRIPT_DIR%chaoxing_portable"
set "PYTHON_VERSION=3.11.9"
set "PYTHON_EMBED_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"

echo [1/7] 清理旧的构建目录...
if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rd /s /q "%DIST_DIR%"
mkdir "%BUILD_DIR%"
mkdir "%DIST_DIR%"

echo [2/7] 下载嵌入式 Python %PYTHON_VERSION%...
set "PYTHON_ZIP=%BUILD_DIR%\python-embed.zip"
set "PYTHON_DIR=%DIST_DIR%\python"

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_EMBED_URL%' -OutFile '%PYTHON_ZIP%'}" 2>nul
if errorlevel 1 (
    echo    ❌ 下载 Python 失败，请检查网络连接
    echo    您也可以手动下载: %PYTHON_EMBED_URL%
    pause
    exit /b 1
)
echo    ✅ Python 下载完成

echo [3/7] 解压 Python 运行时...
mkdir "%PYTHON_DIR%"
powershell -Command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath '%PYTHON_DIR%' -Force"
if errorlevel 1 (
    echo    ❌ 解压失败
    pause
    exit /b 1
)

REM 修改 python311._pth 以启用 pip
set "PTH_FILE=%PYTHON_DIR%\python311._pth"
if exist "%PTH_FILE%" (
    echo python311.zip> "%PTH_FILE%"
    echo .>> "%PTH_FILE%"
    echo Lib>> "%PTH_FILE%"
    echo Lib\site-packages>> "%PTH_FILE%"
    echo import site>> "%PTH_FILE%"
)
echo    ✅ Python 解压完成

echo [4/7] 安装 pip 和依赖包...
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"
set "GET_PIP=%BUILD_DIR%\get-pip.py"

REM 下载 get-pip.py
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '%GET_PIP%'}" 2>nul
if errorlevel 1 (
    echo    ❌ 下载 get-pip.py 失败
    pause
    exit /b 1
)

REM 安装 pip
"%PYTHON_EXE%" "%GET_PIP%" --no-warn-script-location
if errorlevel 1 (
    echo    ❌ 安装 pip 失败
    pause
    exit /b 1
)

REM 安装项目依赖
echo    正在安装项目依赖，这可能需要几分钟...
"%PYTHON_EXE%" -m pip install --no-warn-script-location -r "%SCRIPT_DIR%requirements.txt"
if errorlevel 1 (
    echo    ⚠️  部分依赖安装可能失败，继续打包...
)

REM 安装 Flask-CORS
"%PYTHON_EXE%" -m pip install --no-warn-script-location flask-cors

"%PYTHON_EXE%" -m pip install --no-warn-script-location paddlepaddle -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
if errorlevel 1 (
    echo    ⚠️  OCR 依赖 paddlepaddle 安装失败，便携版将无法使用本地 OCR
) else (
    echo    ✅ OCR 依赖 paddlepaddle 安装成功
)
"%PYTHON_EXE%" -m pip install --no-warn-script-location "paddlex[ocr-core]"
if errorlevel 1 (
    echo    ⚠️  OCR 依赖 paddlex 安装失败，便携版将无法使用本地 OCR
) else (
    echo    ✅ OCR 依赖 paddlex 安装成功
)

echo    ✅ 依赖安装完成

echo [5/7] 构建前端...
cd /d "%SCRIPT_DIR%web"
if exist "node_modules" (
    echo    正在构建前端...
    call npm run build
    if errorlevel 1 (
        echo    ⚠️  前端构建失败，将跳过前端
    ) else (
        echo    ✅ 前端构建完成
        xcopy /E /I /Y "dist" "%DIST_DIR%\web\dist" >nul
    )
) else (
    echo    ⚠️  未找到 node_modules，跳过前端构建
    echo    请先在 web 目录运行 npm install
)
cd /d "%SCRIPT_DIR%"

echo [6/7] 复制项目文件...
REM 复制 Python 源码
xcopy /E /I /Y "%SCRIPT_DIR%api" "%DIST_DIR%\api" >nul
xcopy /E /I /Y "%SCRIPT_DIR%resource" "%DIST_DIR%\resource" >nul

REM 复制主要文件
copy "%SCRIPT_DIR%app.py" "%DIST_DIR%\" >nul
copy "%SCRIPT_DIR%main.py" "%DIST_DIR%\" >nul
copy "%SCRIPT_DIR%requirements.txt" "%DIST_DIR%\" >nul

REM 复制配置文件模板
if exist "%SCRIPT_DIR%config.ini" copy "%SCRIPT_DIR%config.ini" "%DIST_DIR%\" >nul
if exist "%SCRIPT_DIR%web_config.json" copy "%SCRIPT_DIR%web_config.json" "%DIST_DIR%\" >nul

REM 复制 PaddleOCR (如果存在且需要)
if exist "%SCRIPT_DIR%PaddleOCR" (
    echo    正在复制 PaddleOCR...
    xcopy /E /I /Y "%SCRIPT_DIR%PaddleOCR" "%DIST_DIR%\PaddleOCR" >nul
)

echo    ✅ 文件复制完成

echo [7/7] 创建启动脚本...

REM 创建便携版启动脚本
(
echo @echo off
echo chcp 65001 ^>nul 2^>^&1
echo setlocal enabledelayedexpansion
echo.
echo set "SCRIPT_DIR=%%~dp0"
echo set "PYTHON_EXE=%%SCRIPT_DIR%%python\python.exe"
echo set "CHAOXING_ENABLE_OCR=1"
echo.
echo pushd "%%SCRIPT_DIR%%"
echo.
echo echo.
echo echo ========================================================
echo echo           超星学习通自动化工具 - 便携版
echo echo ========================================================
echo echo.
echo.
echo if exist "web\dist\index.html" ^(
echo     echo [INFO] 检测到前端构建，将启动 Web 模式...
echo     echo [INFO] 正在打开浏览器: http://localhost:5000
echo     echo.
echo     start "" cmd /c "ping -n 3 127.0.0.1 ^>nul ^&^& start http://localhost:5000"
echo     "%%PYTHON_EXE%%" app.py
echo ^) else ^(
echo     echo [INFO] 未检测到前端，将启动命令行模式...
echo     echo.
echo     "%%PYTHON_EXE%%" main.py
echo ^)
echo.
echo popd
echo pause
) > "%DIST_DIR%\启动.bat"

REM 创建命令行版启动脚本
(
echo @echo off
echo chcp 65001 ^>nul 2^>^&1
echo setlocal
echo.
echo set "SCRIPT_DIR=%%~dp0"
echo set "PYTHON_EXE=%%SCRIPT_DIR%%python\python.exe"
echo set "CHAOXING_ENABLE_OCR=1"
echo.
echo pushd "%%SCRIPT_DIR%%"
echo.
echo echo.
echo echo ========================================================
echo echo         超星学习通自动化工具 - 命令行模式
echo echo ========================================================
echo echo.
echo "%%PYTHON_EXE%%" main.py
echo.
echo popd
echo pause
) > "%DIST_DIR%\命令行启动.bat"

REM 创建 Web 版启动脚本
(
echo @echo off
echo chcp 65001 ^>nul 2^>^&1
echo setlocal
echo.
echo set "SCRIPT_DIR=%%~dp0"
echo set "PYTHON_EXE=%%SCRIPT_DIR%%python\python.exe"
echo set "CHAOXING_ENABLE_OCR=1"
echo.
echo pushd "%%SCRIPT_DIR%%"
echo.
echo echo.
echo echo ========================================================
echo echo           超星学习通自动化工具 - Web 模式
echo echo ========================================================
echo echo.
echo echo [INFO] 正在打开浏览器: http://localhost:5000
echo echo.
echo start "" cmd /c "ping -n 3 127.0.0.1 ^>nul ^&^& start http://localhost:5000"
echo "%%PYTHON_EXE%%" app.py
echo.
echo popd
echo pause
) > "%DIST_DIR%\Web启动.bat"

REM 创建 README
(
echo # 超星学习通自动化工具 - 便携版
echo.
echo ## 使用方法
echo.
echo 1. **双击 `启动.bat`** - 自动选择合适的启动模式
echo 2. **双击 `Web启动.bat`** - 启动 Web 界面模式，在浏览器打开 http://localhost:5000
echo 3. **双击 `命令行启动.bat`** - 启动命令行模式
echo.
echo ## 配置说明
echo.
echo - 编辑 `config.ini` 配置账号密码和学习参数
echo - 编辑 `web_config.json` 配置 Web 模式的题库等设置
echo.
echo ## 注意事项
echo.
echo - 首次运行可能需要较长时间加载 OCR 模型
echo - 请确保网络连接正常
echo - 如遇问题，请查看控制台输出的错误信息
echo.
echo ## 目录结构
echo.
echo ```
echo chaoxing_portable/
echo ├── python/          # 嵌入式 Python 运行时
echo ├── api/             # 后端 API 模块
echo ├── web/dist/        # 前端静态文件
echo ├── resource/        # 资源文件
echo ├── PaddleOCR/       # OCR 模块（如果有）
echo ├── 启动.bat         # 主启动脚本
echo ├── Web启动.bat      # Web 模式启动
echo └── 命令行启动.bat   # 命令行模式启动
echo ```
) > "%DIST_DIR%\README.md"

echo    ✅ 启动脚本创建完成

REM 清理临时文件
rd /s /q "%BUILD_DIR%" 2>nul

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                      打包完成！                              ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  输出目录: chaoxing_portable                                 ║
echo ║                                                              ║
echo ║  使用方法:                                                   ║
echo ║    1. 将 chaoxing_portable 文件夹复制到任意位置              ║
echo ║    2. 双击 "启动.bat" 运行程序                               ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM 询问是否打包为 zip
set /p CREATE_ZIP="是否将便携版打包为 ZIP 文件? (Y/N): "
if /i "%CREATE_ZIP%"=="Y" (
    echo 正在创建 ZIP 文件...
    powershell -Command "Compress-Archive -Path '%DIST_DIR%\*' -DestinationPath '%SCRIPT_DIR%chaoxing_portable.zip' -Force"
    if errorlevel 1 (
        echo    ❌ ZIP 创建失败
    ) else (
        echo    ✅ 已创建: chaoxing_portable.zip
    )
)

echo.
pause

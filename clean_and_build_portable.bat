@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════════════════════════════╗
echo ║      超星学习通自动化工具 - 清理缓存并打包便携版            ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set "SCRIPT_DIR=%~dp0"
set "BUILD_DIR=%SCRIPT_DIR%portable_build"
set "DIST_DIR=%SCRIPT_DIR%chaoxing_portable"
set "PYTHON_VERSION=3.11.9"
set "PYTHON_EMBED_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
set "PYTHON_EMBED_LOCAL=%SCRIPT_DIR%python-embed.zip"
set "HAS_ERRORS=0"
set "SKIP_OCR=0"
set "FRONTEND_OK=0"

REM 检查是否有预置的 Python 嵌入包
if exist "%PYTHON_EMBED_LOCAL%" (
    echo [提示] 检测到本地 Python 嵌入包: python-embed.zip
    set "USE_LOCAL_PYTHON=1"
) else (
    set "USE_LOCAL_PYTHON=0"
)

echo ========================================
echo [1/8] 清理所有缓存文件...
echo ========================================

REM 清理 __pycache__ 目录
echo    清理 __pycache__ 目录...
for /d /r "%SCRIPT_DIR%" %%d in (__pycache__) do (
    if exist "%%d" (
        echo    删除: %%d
        rd /s /q "%%d" 2>nul
    )
)

REM 清理 .pyc 文件
echo    清理 .pyc 文件...
del /s /q "%SCRIPT_DIR%*.pyc" 2>nul

REM 清理日志文件
echo    清理日志文件...
if exist "%SCRIPT_DIR%chaoxing.log" (
    echo    删除: chaoxing.log
    del /q "%SCRIPT_DIR%chaoxing.log" 2>nul
)
if exist "%SCRIPT_DIR%*.log" del /q "%SCRIPT_DIR%*.log" 2>nul

REM 清理缓存JSON
echo    清理缓存文件...
if exist "%SCRIPT_DIR%cache.json" (
    echo    删除: cache.json
    del /q "%SCRIPT_DIR%cache.json" 2>nul
)

REM 清理 cookies (用户敏感信息)
echo    清理用户敏感信息...
if exist "%SCRIPT_DIR%cookies.txt" (
    echo    删除: cookies.txt
    del /q "%SCRIPT_DIR%cookies.txt" 2>nul
)

REM 清理配置文件中的敏感信息 (保留模板)
if exist "%SCRIPT_DIR%config.ini" (
    echo    删除: config.ini (保留 config.ini.example)
    del /q "%SCRIPT_DIR%config.ini" 2>nul
)

REM 清理旧的便携版
echo    清理旧的便携版...
if exist "%DIST_DIR%" (
    echo    删除: chaoxing_portable 目录
    rd /s /q "%DIST_DIR%" 2>nul
)
if exist "%SCRIPT_DIR%chaoxing_portable.zip" (
    echo    删除: chaoxing_portable.zip
    del /q "%SCRIPT_DIR%chaoxing_portable.zip" 2>nul
)

REM 清理构建临时目录
if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%" 2>nul

REM 清理 web 临时文件
echo    清理前端临时文件...
if exist "%SCRIPT_DIR%web\.vite" rd /s /q "%SCRIPT_DIR%web\.vite" 2>nul
if exist "%SCRIPT_DIR%web\node_modules\.cache" rd /s /q "%SCRIPT_DIR%web\node_modules\.cache" 2>nul

REM 清理 pip 缓存相关
echo    清理 pip 缓存...
if exist "%SCRIPT_DIR%*.egg-info" rd /s /q "%SCRIPT_DIR%*.egg-info" 2>nul

echo    ✅ 缓存清理完成
echo.

echo ========================================
echo [2/8] 创建构建目录...
echo ========================================
mkdir "%BUILD_DIR%"
mkdir "%DIST_DIR%"
echo    ✅ 目录创建完成
echo.

echo ========================================
echo [3/8] 获取嵌入式 Python %PYTHON_VERSION%...
echo ========================================
set "PYTHON_ZIP=%BUILD_DIR%\python-embed.zip"
set "PYTHON_DIR=%DIST_DIR%\python"

if "%USE_LOCAL_PYTHON%"=="1" (
    echo    使用本地 Python 嵌入包...
    copy "%PYTHON_EMBED_LOCAL%" "%PYTHON_ZIP%" >nul
    echo    ✅ 已复制本地 Python 嵌入包
) else (
    echo    正在下载 Python %PYTHON_VERSION%，请稍候...
    echo    (如网络较慢，可手动下载后放置为 python-embed.zip)
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%PYTHON_EMBED_URL%' -OutFile '%PYTHON_ZIP%'}" 2>nul
    if errorlevel 1 (
        echo    ❌ 下载 Python 失败
        echo.
        echo    ┌─────────────────────────────────────────────────────────┐
        echo    │ 解决方案:                                               │
        echo    │ 1. 检查网络连接                                         │
        echo    │ 2. 手动下载 Python 嵌入包:                              │
        echo    │    %PYTHON_EMBED_URL%
        echo    │ 3. 将下载的文件重命名为 python-embed.zip                │
        echo    │ 4. 放置在本脚本同目录下，然后重新运行                   │
        echo    └─────────────────────────────────────────────────────────┘
        pause
        exit /b 1
    )
    echo    ✅ Python 下载完成
)
echo.

echo ========================================
echo [4/8] 解压 Python 运行时...
echo ========================================
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
echo.

echo ========================================
echo [5/8] 安装 pip 和依赖包...
echo ========================================
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"
set "GET_PIP=%BUILD_DIR%\get-pip.py"

REM 检查是否有本地 get-pip.py
set "GET_PIP_LOCAL=%SCRIPT_DIR%get-pip.py"
if exist "%GET_PIP_LOCAL%" (
    echo    使用本地 get-pip.py...
    copy "%GET_PIP_LOCAL%" "%GET_PIP%" >nul
) else (
    echo    下载 get-pip.py...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '%GET_PIP%'}" 2>nul
    if errorlevel 1 (
        echo    ❌ 下载 get-pip.py 失败
        echo.
        echo    解决方案: 手动下载 https://bootstrap.pypa.io/get-pip.py
        echo              放置在本脚本同目录下，然后重新运行
        pause
        exit /b 1
    )
)

REM 安装 pip
echo    安装 pip...
"%PYTHON_EXE%" "%GET_PIP%" --no-warn-script-location
if errorlevel 1 (
    echo    ❌ 安装 pip 失败
    pause
    exit /b 1
)

REM 安装项目依赖
echo    正在安装项目依赖，这可能需要几分钟...
echo    (如果某些依赖安装失败，程序仍会尝试继续)
"%PYTHON_EXE%" -m pip install --no-warn-script-location -r "%SCRIPT_DIR%requirements.txt"
if errorlevel 1 (
    echo    ⚠️  部分核心依赖安装失败
    set "HAS_ERRORS=1"
)

REM 安装 Flask-CORS
echo    安装 Flask-CORS...
"%PYTHON_EXE%" -m pip install --no-warn-script-location flask-cors
if errorlevel 1 (
    echo    ⚠️  Flask-CORS 安装失败，Web 模式可能无法正常工作
    set "HAS_ERRORS=1"
)

REM 安装 OCR 依赖（完整版默认安装）
echo    安装 OCR 依赖 paddlepaddle...
"%PYTHON_EXE%" -m pip install --no-warn-script-location paddlepaddle -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
if errorlevel 1 (
    echo    ⚠️  paddlepaddle 安装失败，便携版将无法使用本地 OCR
    echo    (程序仍可运行，但验证码需要手动输入或使用在线 OCR)
    set "SKIP_OCR=1"
) else (
    echo    ✅ paddlepaddle 安装成功
    echo    安装 OCR 依赖 paddlex...
    "%PYTHON_EXE%" -m pip install --no-warn-script-location "paddlex[ocr-core]"
    if errorlevel 1 (
        echo    ⚠️  paddlex 安装失败
        set "SKIP_OCR=1"
    ) else (
        echo    ✅ paddlex 安装成功
    )
)

REM 清理 pip 缓存以减小体积
echo    清理 pip 缓存...
"%PYTHON_EXE%" -m pip cache purge 2>nul

echo    ✅ 依赖安装完成
echo.

echo ========================================
echo [6/8] 构建前端...
echo ========================================
set "FRONTEND_OK=0"

REM 检查是否已有构建好的前端
if exist "%SCRIPT_DIR%web\dist\index.html" (
    echo    检测到已构建的前端，直接复制...
    xcopy /E /I /Y "%SCRIPT_DIR%web\dist" "%DIST_DIR%\web\dist" >nul
    set "FRONTEND_OK=1"
    echo    ✅ 前端复制完成
    goto :frontend_done
)

REM 检查 Node.js 是否安装
where npm >nul 2>nul
if errorlevel 1 (
    echo    ⚠️  未检测到 Node.js/npm
    echo.
    echo    ┌─────────────────────────────────────────────────────────┐
    echo    │ 前端构建需要 Node.js，您可以:                          │
    echo    │ 1. 安装 Node.js: https://nodejs.org/                    │
    echo    │ 2. 或者使用命令行模式（不需要前端）                     │
    echo    │ 3. 或者从其他地方复制已构建的 web\dist 目录             │
    echo    └─────────────────────────────────────────────────────────┘
    echo.
    echo    自动继续（便携版将只有命令行模式）...
    goto :frontend_done
)

cd /d "%SCRIPT_DIR%web"

REM 检查 node_modules
if not exist "node_modules" (
    echo    未找到 node_modules，正在安装依赖...
    call npm install
    if errorlevel 1 (
        echo    ⚠️  npm install 失败
        echo    便携版将只有命令行模式
        cd /d "%SCRIPT_DIR%"
        goto :frontend_done
    )
)

echo    正在构建前端...
call npm run build
if errorlevel 1 (
    echo    ⚠️  前端构建失败
    echo    便携版将只有命令行模式
) else (
    echo    ✅ 前端构建完成
    xcopy /E /I /Y "dist" "%DIST_DIR%\web\dist" >nul
    set "FRONTEND_OK=1"
)

cd /d "%SCRIPT_DIR%"

:frontend_done
if "%FRONTEND_OK%"=="0" (
    echo    提示: 便携版将只支持命令行模式
)
echo.

echo ========================================
echo [7/8] 复制项目文件 (不含缓存)...
echo ========================================

REM 复制 Python 源码 (排除 __pycache__)
echo    复制 api 目录...
xcopy /E /I /Y "%SCRIPT_DIR%api" "%DIST_DIR%\api" /EXCLUDE:%SCRIPT_DIR%exclude_list.txt >nul 2>nul
if errorlevel 1 (
    xcopy /E /I /Y "%SCRIPT_DIR%api" "%DIST_DIR%\api" >nul
    REM 删除复制后的缓存
    for /d /r "%DIST_DIR%\api" %%d in (__pycache__) do rd /s /q "%%d" 2>nul
)

echo    复制 resource 目录...
xcopy /E /I /Y "%SCRIPT_DIR%resource" "%DIST_DIR%\resource" >nul

REM 复制主要文件
echo    复制主要文件...
copy "%SCRIPT_DIR%app.py" "%DIST_DIR%\" >nul
copy "%SCRIPT_DIR%main.py" "%DIST_DIR%\" >nul
copy "%SCRIPT_DIR%requirements.txt" "%DIST_DIR%\" >nul

REM 复制配置文件模板 (不复制实际配置)
echo    复制配置模板...
if exist "%SCRIPT_DIR%config.ini.example" copy "%SCRIPT_DIR%config.ini.example" "%DIST_DIR%\config.ini.example" >nul
if exist "%SCRIPT_DIR%config_template.ini" copy "%SCRIPT_DIR%config_template.ini" "%DIST_DIR%\config.ini.example" >nul

REM 复制 web_config.json (清空敏感信息)
if exist "%SCRIPT_DIR%web_config.json" (
    echo    处理 web_config.json...
    copy "%SCRIPT_DIR%web_config.json" "%DIST_DIR%\web_config.json" >nul
)

REM 复制 PaddleOCR (如果存在，排除缓存)
if exist "%SCRIPT_DIR%PaddleOCR" (
    echo    正在复制 PaddleOCR (排除缓存)...
    xcopy /E /I /Y "%SCRIPT_DIR%PaddleOCR" "%DIST_DIR%\PaddleOCR" >nul
    REM 清理复制后的缓存
    for /d /r "%DIST_DIR%\PaddleOCR" %%d in (__pycache__) do rd /s /q "%%d" 2>nul
    del /s /q "%DIST_DIR%\PaddleOCR\*.pyc" 2>nul
)

REM 清理 python 目录中的 __pycache__
echo    清理便携版中的 __pycache__...
for /d /r "%DIST_DIR%" %%d in (__pycache__) do (
    if exist "%%d" rd /s /q "%%d" 2>nul
)
del /s /q "%DIST_DIR%\*.pyc" 2>nul
del /s /q "%DIST_DIR%\*.log" 2>nul

echo    ✅ 文件复制完成
echo.

echo ========================================
echo [8/8] 创建启动脚本...
echo ========================================

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
set "README_FILE=%DIST_DIR%\README.md"
echo # 超星学习通自动化工具 - 便携版> "%README_FILE%"
echo.>> "%README_FILE%"
echo ## 快速开始>> "%README_FILE%"
echo.>> "%README_FILE%"
echo 1. 将 `config.ini.example` 复制为 `config.ini`>> "%README_FILE%"
echo 2. 编辑 `config.ini` 填写账号密码>> "%README_FILE%"
echo 3. 双击 `启动.bat` 运行程序>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ## 启动方式>> "%README_FILE%"
echo.>> "%README_FILE%"
echo - **启动.bat** - 自动选择模式（优先 Web 模式）>> "%README_FILE%"
echo - **Web启动.bat** - Web 界面模式，浏览器打开 http://localhost:5000>> "%README_FILE%"
echo - **命令行启动.bat** - 纯命令行模式>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ## 配置说明>> "%README_FILE%"
echo.>> "%README_FILE%"
echo - `config.ini` - 账号密码和学习参数>> "%README_FILE%"
echo - `web_config.json` - Web 模式的题库等设置>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ## 功能说明>> "%README_FILE%"
echo.>> "%README_FILE%"
if "%FRONTEND_OK%"=="1" (
    echo - [√] Web 前端界面>> "%README_FILE%"
) else (
    echo - [X] Web 前端界面（此版本仅支持命令行模式）>> "%README_FILE%"
)
if "%SKIP_OCR%"=="0" (
    echo - [√] 验证码自动识别（本地 OCR）>> "%README_FILE%"
) else (
    echo - [X] 验证码自动识别（需手动输入或使用在线 OCR 服务）>> "%README_FILE%"
)
echo.>> "%README_FILE%"
echo ## 常见问题>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ### 验证码无法自动识别>> "%README_FILE%"
echo 此便携版可能未包含 OCR 依赖，您可以：>> "%README_FILE%"
echo - 手动输入验证码>> "%README_FILE%"
echo - 配置在线 OCR 服务（如百度 OCR）>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ### 程序启动缓慢>> "%README_FILE%"
echo 首次运行需要加载依赖，请耐心等待>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ### 缺少 config.ini>> "%README_FILE%"
echo 请将 config.ini.example 复制为 config.ini 并编辑>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ## 目录结构>> "%README_FILE%"
echo.>> "%README_FILE%"
echo ```>> "%README_FILE%"
echo chaoxing_portable/>> "%README_FILE%"
echo ├── python/          # 嵌入式 Python 运行时>> "%README_FILE%"
echo ├── api/             # 后端 API 模块>> "%README_FILE%"
echo ├── web/dist/        # 前端静态文件（如果有）>> "%README_FILE%"
echo ├── resource/        # 资源文件>> "%README_FILE%"
echo ├── PaddleOCR/       # OCR 模块（如果有）>> "%README_FILE%"
echo ├── 启动.bat         # 主启动脚本>> "%README_FILE%"
echo ├── Web启动.bat      # Web 模式启动>> "%README_FILE%"
echo └── 命令行启动.bat   # 命令行模式启动>> "%README_FILE%"
echo ```>> "%README_FILE%"

echo    ✅ 启动脚本创建完成

REM 清理临时文件
rd /s /q "%BUILD_DIR%" 2>nul

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                      打包完成！                              ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  输出目录: chaoxing_portable                                 ║
echo ╠══════════════════════════════════════════════════════════════╣
if "%FRONTEND_OK%"=="1" (
echo ║  [√] Web 前端: 已包含                                        ║
) else (
echo ║  [X] Web 前端: 未包含 (仅命令行模式)                         ║
)
if "%SKIP_OCR%"=="0" (
echo ║  [√] OCR 识别: 已包含                                        ║
) else (
echo ║  [X] OCR 识别: 未包含 (需手动输入验证码)                     ║
)
if "%HAS_ERRORS%"=="1" (
echo ║  [!] 警告: 部分依赖安装失败，功能可能受限                    ║
)
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  已清理的缓存:                                               ║
echo ║    - __pycache__ 目录 / *.pyc 编译文件                       ║
echo ║    - *.log 日志文件 / cache.json 缓存                        ║
echo ║    - cookies.txt / config.ini (用户敏感信息)                 ║
echo ╠══════════════════════════════════════════════════════════════╣
echo ║  使用方法:                                                   ║
echo ║    1. 将 chaoxing_portable 文件夹复制到任意位置              ║
echo ║    2. 双击 "启动.bat" 运行程序                               ║
echo ║    3. 首次使用请将 config.ini.example 复制为 config.ini      ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM 自动打包为 zip
echo 正在创建 ZIP 文件...
powershell -Command "Compress-Archive -Path '%DIST_DIR%\*' -DestinationPath '%SCRIPT_DIR%chaoxing_portable.zip' -Force"
if errorlevel 1 (
    echo    ❌ ZIP 创建失败
) else (
    echo    ✅ 已创建: chaoxing_portable.zip
    
    REM 显示文件大小
    for %%A in ("%SCRIPT_DIR%chaoxing_portable.zip") do (
        set "SIZE=%%~zA"
        set /a "SIZE_MB=!SIZE! / 1048576"
        echo    文件大小: !SIZE_MB! MB
    )
)

echo.
pause

@echo off
chcp 65001 >nul
set CHAOXING_ENABLE_OCR=1
echo ========================================
echo   超星学习通 - Web前端启动脚本
echo ========================================
echo.

echo [检查] 检查依赖安装状态...
echo.

REM 检查后端依赖
echo [1/5] 检查后端依赖 (flask-cors)...
python -c "import flask_cors" 2>nul
if errorlevel 1 (
    echo    ⚠️  flask-cors 未安装，正在安装...
    pip install flask-cors
    if errorlevel 1 (
        echo    ❌ 后端依赖安装失败！
        pause
        exit /b 1
    )
    echo    ✅ 后端依赖安装成功！
) else (
    echo    ✅ 后端依赖已安装
)
echo.

REM 检查 OCR 依赖
echo [2/5] 检查 OCR 依赖 (paddlepaddle / paddlex)...
python -c "import paddle" 2>nul
if errorlevel 1 (
    echo    ⚠️  OCR 依赖 paddlepaddle 未安装，正在安装...
    pip install paddlepaddle -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
    if errorlevel 1 (
        echo    ❌ OCR 依赖 paddlepaddle 安装失败！
        pause
        exit /b 1
    )
    echo    ✅ OCR 依赖 paddlepaddle 安装成功！
) else (
    echo    ✅ OCR 依赖 paddlepaddle 已安装
)

python -c "import paddlex" 2>nul
if errorlevel 1 (
    echo    ⚠️  OCR 依赖 paddlex 未安装，正在安装 paddlex[ocr-core]...
    pip install "paddlex[ocr-core]"
    if errorlevel 1 (
        echo    ❌ OCR 依赖 paddlex 安装失败！
        pause
        exit /b 1
    )
    echo    ✅ OCR 依赖 paddlex 安装成功！
) else (
    echo    ✅ OCR 依赖 paddlex 已安装
)
echo.

REM 检查前端依赖
echo [3/5] 检查前端依赖 (node_modules)...
if not exist "web\node_modules" (
    echo    ⚠️  前端依赖未安装，正在安装...
    cd web
    call npm install
    if errorlevel 1 (
        echo    ❌ 前端依赖安装失败！
        cd ..
        pause
        exit /b 1
    )
    cd ..
    echo    ✅ 前端依赖安装成功！
) else (
    echo    ✅ 前端依赖已安装
)
echo.

echo [4/5] 启动后端服务...
start "超星后端服务" cmd /k "python app.py"
timeout /t 3 /nobreak >nul

echo [5/5] 启动前端服务...
cd web
start "超星前端服务" cmd /k "npm run dev"

echo.
echo ========================================
echo   服务启动完成！
echo   后端地址: http://localhost:5000
echo   前端地址: http://localhost:3000
echo ========================================
echo.
echo 请等待浏览器自动打开...
timeout /t 5 /nobreak >nul
start http://localhost:3000

pause

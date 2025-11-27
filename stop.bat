@echo off
chcp 65001 >nul
echo ========================================
echo   超星学习通 - 停止服务脚本
echo ========================================
echo.

echo [1/2] 尝试关闭后端服务窗口(超星后端服务)...
taskkill /F /FI "WINDOWTITLE eq 超星后端服务" >nul 2>&1

echo [2/2] 尝试关闭前端服务窗口(超星前端服务)...
taskkill /F /FI "WINDOWTITLE eq 超星前端服务" >nul 2>&1

echo.
echo 所有关联的命令窗口已尝试关闭，如有残留请手动检查。
echo.
pause

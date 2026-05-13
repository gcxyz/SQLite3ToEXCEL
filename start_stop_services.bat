@echo off
chcp 65001 >nul 2>&1
title Python & Node.js 服务启停脚本
color 0A

set "PYTHON_CMD=python app.py"
set "NODE_CMD=npm run dev"
set "PYTHON_PROC=python.exe"
set "NODE_PROC=node.exe"  :: 这里必须是 node.exe，不是 Node.js

:: 检查Python服务
tasklist | findstr /i "%PYTHON_PROC%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [提示] 检测到Python服务正在运行，准备停止...
    taskkill /f /im "%PYTHON_PROC%" >nul 2>&1
    echo [成功] Python服务已停止！
) else (
    echo [提示] 未检测到Python服务，准备启动...
    start "Python服务" cmd /k "%PYTHON_CMD%"
    echo [成功] Python服务已启动！
)

:: 检查Node.js服务
tasklist | findstr /i "%NODE_PROC%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [提示] 检测到Node.js服务正在运行，准备停止...
    taskkill /f /im "%NODE_PROC%" >nul 2>&1
    echo [成功] Node.js服务已停止！
) else (
    echo [提示] 未检测到Node.js服务，准备启动...
    start "Node.js服务" cmd /k "%NODE_CMD%"
    echo [成功] Node.js服务已启动！
)

echo.
echo [完成] 操作结束，按任意键退出...
pause >nul
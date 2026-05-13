@echo off

echo 正在停止服务...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1

echo 服务已停止
pause
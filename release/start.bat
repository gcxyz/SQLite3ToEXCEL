@echo off

echo 正在启动后端服务...
start python app.py

echo 等待3秒...
ping 127.0.0.1 -n 3 >nul

echo 正在启动前端服务...
start npm run preview

echo 等待5秒...
ping 127.0.0.1 -n 5 >nul

echo 正在打开前端页面...
start http://localhost:5173

echo 正在打开后端API文档...
start http://127.0.0.1:5000

echo 服务已启动
pause
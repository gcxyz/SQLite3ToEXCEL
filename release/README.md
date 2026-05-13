# SQLite3_EXCEL_分析工具 安装指南

## 项目简介

SQLite3_EXCEL_分析工具是一个基于Web的SQLite数据库操作和Excel数据导入/导出工具，支持SQL语句执行、数据可视化、Excel数据导入导出等功能。

## 系统要求

- Windows 7/8/10/11
- Python 3.7+
- Node.js 16+

## 安装步骤

### 1. 安装Python

1. 从 [Python官网](https://www.python.org/downloads/) 下载最新版本的Python安装包
2. 运行安装包，勾选「Add Python to PATH」选项
3. 点击「Install Now」完成安装
4. 打开命令提示符，输入 `python --version` 验证Python安装成功

### 2. 安装Node.js

1. 从 [Node.js官网](https://nodejs.org/en/download/) 下载最新版本的Node.js安装包
2. 运行安装包，按照默认选项完成安装
3. 打开命令提示符，输入 `node --version` 验证Node.js安装成功
4. 输入 `npm --version` 验证npm安装成功

### 3. 安装项目依赖

1. 解压发布包到任意目录
2. 打开命令提示符，进入解压后的目录
3. 安装Python依赖：
   ```
   pip install -r requirements.txt
   ```
4. 安装Node.js依赖：
   ```
   npm install
   ```

### 4. 启动服务

1. 双击运行 `start.bat` 文件
2. 系统会自动启动后端服务和前端服务
3. 浏览器会自动打开前端页面（http://localhost:5173）和后端API文档（http://127.0.0.1:5000）

### 5. 停止服务

1. 双击运行 `stop.bat` 文件
2. 系统会自动停止所有相关服务

## 功能说明

- **SQL语句执行**：支持执行各种SQL语句，包括SELECT、INSERT、UPDATE、DELETE等
- **Excel数据导入**：支持将Excel文件导入到SQLite数据库中
- **数据导出**：支持将查询结果导出为Excel文件
- **表管理**：支持查看和删除数据库表
- **数据库压缩**：支持压缩SQLite数据库，减少数据库文件大小

## 注意事项

- 首次启动服务可能需要较长时间，因为需要下载和安装依赖
- 请确保端口5000（后端服务）和5173（前端服务）未被占用
- 如果服务启动失败，请检查命令提示符中的错误信息
- 本工具使用SQLite数据库，所有数据存储在本地文件中

## 作者信息

- 软件名：SQLite3_EXCEL_分析工具
- 作者：XCF.g

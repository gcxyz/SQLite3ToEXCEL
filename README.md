# SQLite3_EXCEL_分析工具

一款功能强大的 SQLite3 数据库操作工具，支持 SQL 查询、数据可视化、Excel 导出等功能。

## 功能特性

### 📊 核心功能
- **SQL 编辑器**：支持语法高亮、行号显示、SQL 美化
- **数据查询**：支持分页显示查询结果，首行置顶
- **数据可视化**：支持多种图表类型（柱状图、折线图、饼图等）
- **Excel 导出**：一键导出查询结果到 Excel 文件
- **数据库管理**：支持数据库备份和恢复

### ✨ 高级功能
- SQL 语句历史记录
- SQL 语法检查
- 查询结果缓存
- SQL 注入防护
- 字段选择和排序聚合
- 图表样式选择

## 技术栈

### 前端
- **Vue 3** - 渐进式 JavaScript 框架
- **Element Plus** - Vue 3 UI 组件库
- **CodeMirror 6** - 代码编辑器组件
- **ECharts** - 数据可视化图表库
- **sql-formatter** - SQL 语句美化工具

### 后端
- **Flask** - Python Web 框架
- **SQLite3** - 轻量级数据库
- **pandas** - 数据处理库
- **openpyxl** - Excel 文件处理库

## 快速开始

### 环境要求
- Python 3.8+
- Node.js 16+

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/gcxyz/SQLite3ToEXCEL.git
cd SQLite3ToEXCEL
```

2. **安装后端依赖**
```bash
pip install -r requirements.txt
```

3. **安装前端依赖**
```bash
npm install
```

4. **启动服务**

运行 `start.bat`（Windows）或手动启动：

```bash
# 启动后端服务
python app.py

# 启动前端服务（新终端）
npm run dev
```

5. **访问应用**

打开浏览器访问：`http://localhost:5173`

## 使用说明

### SQL 编辑器
- 输入 SQL 语句，支持语法高亮
- 点击「美化」按钮格式化 SQL
- 点击「复制」按钮复制 SQL 语句
- 支持选中文本执行

### 数据可视化
1. 执行 SQL 查询获取数据
2. 点击「可视化」按钮
3. 选择 X 轴、Y 轴字段
4. 选择图表类型和聚合方式
5. 点击「生成图表」查看结果

### Excel 导出
- 执行 SQL 查询后，点击「导出 Excel」按钮
- 选择导出路径，保存 .xlsx 文件

## 项目结构

```
SQLite3ToEXCEL/
├── src/                    # 前端源代码
│   ├── App.vue            # 主应用组件
│   └── main.js            # 入口文件
├── app.py                 # 后端 Flask 应用
├── index.html             # HTML 模板
├── package.json           # 前端依赖配置
├── requirements.txt       # 后端依赖配置
├── vite.config.js         # Vite 配置
├── start.bat              # 启动脚本
├── stop.bat               # 停止脚本
└── .gitignore            # Git 忽略配置
```

## 作者

**XCF.g**

## 许可证

MIT License

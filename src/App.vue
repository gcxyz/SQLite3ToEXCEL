<template>
  <div class="app-container">
    <!-- 顶部导航 -->
    <header class="app-header">
      <div class="header-content">
        <h1 class="app-title">
          <span class="title-icon">📊</span>
          SQLite3_EXCEL_分析工具
        </h1>
        <div class="header-actions">

          <el-button type="info" @click="showMonitor" size="small">
            <span class="icon">📈</span> 监控
          </el-button>
          <el-button type="primary" @click="showImportDialog" size="small">
            <span class="icon">📤</span> 导入Excel
          </el-button>
          <el-button type="success" @click="refreshTables" size="small">
            <span class="icon">🔄</span> 刷新
          </el-button>
          <el-button type="danger" @click="showDeleteTableDialog" size="small">
            <span class="icon">🗑️</span> 删除表
          </el-button>
          <el-button type="warning" @click="vacuumDatabase" size="small" :loading="vacuumLoading">
            <span class="icon">📦</span> 压缩数据库
          </el-button>
          <el-button type="info" @click="backupDatabase" size="small" :loading="backupLoading">
            <span class="icon">💾</span> 备份数据库
          </el-button>
          <el-button type="info" @click="showRestoreDialog" size="small">
            <span class="icon">🔄</span> 恢复数据库
          </el-button>
        </div>
      </div>
    </header>

    <!-- 主要内容 -->
    <main class="app-main">
      <div class="main-content">
        <!-- SQL输入区域 -->
        <div class="sql-section">
          <div class="section-card">
            <div class="sql-input-wrapper">
              <div class="sql-input-header">
                <label class="sql-input-label">SQL 语句</label>
              </div>
              <div class="sql-input-container">
                <div class="sql-editor-container">
                  <codemirror
                    v-model="form.sql"
                    placeholder="输入 SQL 语句..."
                    :style="{ height: editorHeight }"
                    :autofocus="true"
                    :indent-with-tab="true"
                    :tab-size="2"
                    :extensions="extensions"
                    @ready="handleReady"
                    @change="handleChange"
                  />
                </div>
                <button 
                  type="button" 
                  @click="beautifySql"
                  class="beautify-btn"
                >
                  <span class="icon">✨</span> 美化
                </button>
              </div>
              <!-- SQL语法错误提示 -->
              <div v-if="sqlSyntaxError" class="sql-syntax-error">
                <el-alert
                  :title="sqlSyntaxError"
                  type="error"
                  show-icon
                  :closable="false"
                />
              </div>
              <div class="sql-actions">
                <el-button 
                  type="primary" 
                  @click="executeSql"
                  :loading="loading"
                  size="small"
                  class="execute-button"
                >
                  <span class="icon">⚡</span> 执行
                </el-button>
                <el-button 
                  type="info" 
                  @click="copySql"
                  size="small"
                  class="copy-button"
                >
                  <span class="icon">📋</span> 复制
                </el-button>
                <el-button 
                  type="info" 
                  @click="pasteSql"
                  size="small"
                  class="paste-button"
                >
                  <span class="icon">📄</span> 粘贴
                </el-button>
                <el-button 
                  type="info" 
                  @click="showHistoryDialog"
                  size="small"
                  class="history-button"
                >
                  <span class="icon">🕒</span> 历史
                </el-button>
                <el-button 
                  type="info" 
                  @click="showChartDialog"
                  size="small"
                  class="chart-button"
                  :disabled="!hasResults"
                >
                  <span class="icon">📊</span> 可视化
                </el-button>
                <el-button 
                  type="success" 
                  @click="exportCurrentPage"
                  :disabled="!hasResults"
                  size="small"
                  class="export-button"
                >
                  <span class="icon">📄</span> 导出当前页
                </el-button>
                <el-button 
                  type="success" 
                  @click="exportAllData" 
                  :disabled="!hasResults"
                  size="small"
                  class="export-button"
                >
                  <span class="icon">📥</span> 导出全部数据
                </el-button>
              </div>
            </div>
          </div>
        </div>

        <!-- 错误提示 -->
        <el-alert
          v-if="error"
          type="error"
          :title="'错误: ' + error"
          class="error-alert"
          show-icon
          :closable="true"
        />

        <!-- 结果区域 -->
        <div v-if="hasResults" class="results-section">
          <div class="section-card">
            <div class="section-header">
              <h2 class="section-title">执行结果</h2>
              <div class="section-description">共 {{ tableData.length }} 条记录</div>
            </div>
            
            <div class="table-container">
              <el-table 
                :data="currentPageData" 
                style="width: 100%" 
                class="result-table"
                border
                stripe
                size="small"
                highlight-current-row
                :header-cell-style="{ backgroundColor: '#f5f7fa', color: '#303133', position: 'sticky', top: '0', zIndex: '10' }"
                height="280"
              >
                <el-table-column
                  type="index"
                  label="行号"
                  width="80"
                  :index="indexMethod"
                  fixed="left"
                />
                <el-table-column
                  v-for="column in columns"
                  :key="column"
                  :prop="column"
                  :label="column"
                  show-overflow-tooltip
                  min-width="100"
                />
              </el-table>
            </div>
            
            <div class="pagination-container">
              <el-pagination
                @size-change="handleSizeChange"
                @current-change="handleCurrentChange"
                :current-page="currentPage"
                :page-sizes="[10, 20, 30, 50, 100]"
                :page-size="pageSize"
                layout="total, sizes, prev, pager, next, jumper"
                :total="totalCount"
                prev-text="上一页"
                next-text="下一页"
                :page-size-options="['10条/页', '20条/页', '30条/页', '50条/页', '100条/页']"
                class="custom-pagination"
                background
              />
            </div>
          </div>
        </div>

        <!-- 空状态 -->
        <div v-else-if="!error" class="empty-state">
          <div class="empty-card">
            <div class="empty-icon">🔍</div>
            <h3 class="empty-title">准备就绪</h3>
            <p class="empty-description">输入 SQL 语句并点击执行按钮开始查询</p>
            <div class="empty-samples">
              <el-button 
                link 
                v-for="(sample, index) in sampleQueries" 
                :key="index"
                @click="loadSampleQuery(sample.sql)"
                class="sample-btn"
              >
                {{ sample.name }}
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 页脚 -->
    <footer class="app-footer">
      <div class="footer-content">
        <div class="footer-info">
          SQLite3_EXCEL_分析工具 © {{ new Date().getFullYear() }} 作者: XCF.g
        </div>
        <div class="footer-links">
          <a href="#" @click.prevent="showMonitor" class="footer-link">监控</a>
          <span class="footer-divider">|</span>
          <a href="https://www.sqlite.org" target="_blank" class="footer-link">SQLite 官方文档</a>
        </div>
      </div>
    </footer>
  </div>

    <!-- 导入Excel对话框 -->
    <el-dialog
      v-model="importDialogVisible"
      :title="importForm.importType === 'create' ? '导入Excel到数据库' : '增量导入到现有表'"
      width="700px"
      center
      draggable
      @closed="resetImportForm"
    >
      <el-form :model="importForm" label-width="100px" class="import-form">
        <el-form-item label="导入类型">
          <el-radio-group v-model="importForm.importType" @change="handleImportTypeChange">
            <el-radio label="create">新建表</el-radio>
            <el-radio label="append">增量导入</el-radio>
          </el-radio-group>
        </el-form-item>
        
        <!-- 新建表模式 -->
        <el-form-item v-if="importForm.importType === 'create'" label="表名">
          <el-input
            v-model="importForm.tableName"
            placeholder="请输入要创建的表名"
            class="table-name-input"
          />
        </el-form-item>
        
        <!-- 增量导入模式 -->
        <el-form-item v-else label="选择表">
          <el-select v-model="importForm.targetTable" placeholder="请选择要导入的表" class="table-select" @change="handleTableChange">
            <el-option
              v-for="table in tables"
              :key="table.name"
              :label="table.name"
              :value="table.name"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="Excel文件">
          <el-upload
            ref="excelUpload"
            class="upload-demo"
            :on-change="handleFileChange"
            :auto-upload="false"
            :limit="1"
            accept=".xlsx,.xls"
          >
            <el-button type="primary" size="small">
              <span class="icon">📁</span> 选择文件
            </el-button>
            <template #tip>
              <div class="el-upload__tip">
                请选择Excel文件（.xlsx或.xls格式）
              </div>
            </template>
          </el-upload>
          <div v-if="selectedFile" class="selected-file">
            <span class="file-name">{{ selectedFile.name }}</span>
            <el-button link size="small" @click="removeFile">
              <span class="icon">❌</span> 移除
            </el-button>
          </div>
        </el-form-item>
        
        <!-- 字段映射 -->
        <el-form-item v-if="showFieldMapping" label="字段映射">
          <div v-if="fieldMappings.length === 0" class="no-mappings">
            <el-empty description="未生成字段映射" />
          </div>
          <div v-else class="mappings-count">
            已映射 {{ fieldMappings.filter(mapping => mapping.dbField).length }} 列，共 {{ fieldMappings.length }} 列
          </div>
          <div class="field-mapping-container">
            <el-table 
              :data="fieldMappings" 
              style="width: 100%" 
              border
              :max-height="350"
              size="small"
            >
              <el-table-column prop="excelColumn" label="Excel列" min-width="120" />
              <el-table-column prop="dbField" label="数据库字段" min-width="120">
                <template v-slot="{ row }">
                  <el-select v-model="row.dbField" placeholder="请选择字段" clearable size="small">
                    <el-option
                      v-for="field in tableFields"
                      :key="field"
                      :label="field"
                      :value="field"
                    />
                  </el-select>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-form-item>
        
        <!-- 导入进度条 -->
        <el-form-item v-if="importLoading">
          <div class="import-progress-container">
            <el-progress 
              :percentage="importProgress" 
              :status="importProgress === 100 ? 'success' : ''"
              :stroke-width="15"
              class="progress-bar"
            />
            <div class="progress-info">
              <span>导入进度: {{ importProgress }}%</span>
              <span v-if="importStats.total > 0">
                ({{ importStats.processed }}/{{ importStats.total }} 条)
              </span>
            </div>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button size="small" @click="importDialogVisible = false">取消</el-button>
          <el-button 
            type="primary" 
            size="small"
            @click="importExcel" 
            :loading="importLoading"
            :disabled="!canImport"
          >
            {{ importForm.importType === 'create' ? '导入' : '增量导入' }}
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 删除表对话框 -->
    <el-dialog
      v-model="deleteTableDialogVisible"
      title="删除表"
      width="500px"
      center
    >
      <div class="delete-table-content">
        <div v-if="tables.length === 0" class="no-tables">
          <el-empty description="当前数据库中没有表" />
        </div>
        <div v-else class="table-container">
          <el-table
            :data="tables"
            style="width: 100%"
            @selection-change="handleTableSelectionChange"
            border
            stripe
            size="small"
          >
            <el-table-column
              type="selection"
              width="55"
            />
            <el-table-column
              prop="name"
              label="表名"
              min-width="150"
            />
          </el-table>
        </div>
        <div v-if="deleteForm.tableNames.length > 0" class="warning-message">
          <el-alert
            type="warning"
            :title="`警告：删除选中的 ${deleteForm.tableNames.length} 个表将永久删除表中的所有数据！`"
            show-icon
          />
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button size="small" @click="deleteTableDialogVisible = false">取消</el-button>
          <el-button type="danger" size="small" @click="deleteTable" :loading="deleteLoading" :disabled="deleteForm.tableNames.length === 0">
            确认删除 ({{ deleteForm.tableNames.length }})
          </el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 导出加载对话框 -->
    <el-dialog
      v-model="exportLoading"
      title="导出数据"
      width="350px"
      center
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="false"
    >
      <div class="export-loading-content">
        <el-icon class="is-loading"><Loading /></el-icon>
        <p>正在导出数据，请稍候...</p>
      </div>
    </el-dialog>
    
    <!-- 数据库恢复对话框 -->
    <el-dialog
      v-model="restoreDialogVisible"
      title="恢复数据库"
      width="500px"
      center
    >
      <div class="restore-content">
        <el-alert
          :title="'警告：恢复数据库将覆盖当前数据库内容，请确保已备份重要数据！'"
          type="warning"
          show-icon
          :closable="false"
        />
        <div class="file-upload-section">
          <el-upload
            class="restore-upload"
            action=""
            :auto-upload="false"
            :on-change="handleRestoreFileChange"
            :file-list="[restoreFile]"
            accept=".db"
            :limit="1"
          >
            <el-button type="primary" size="small">
              <el-icon><Upload /></el-icon> 选择备份文件
            </el-button>
            <template #tip>
              <div class="el-upload__tip">
                请选择 SQLite 数据库备份文件 (*.db)
              </div>
            </template>
          </el-upload>
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button size="small" @click="restoreDialogVisible = false">取消</el-button>
          <el-button type="primary" size="small" @click="restoreDatabase" :loading="restoreLoading" :disabled="!restoreFile">
            确认恢复
          </el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- SQL语句历史记录对话框 -->
    <el-dialog
      v-model="historyDialogVisible"
      title="SQL语句历史记录"
      width="800px"
      center
    >
      <div class="history-content">
        <div v-if="sqlHistory.length === 0" class="no-history">
          <el-empty description="暂无历史记录" />
        </div>
        <div v-else class="history-list">
          <el-table
            :data="sqlHistory"
            style="width: 100%"
            border
            stripe
            size="small"
            @row-click="selectHistoryItem"
          >
            <el-table-column
              prop="timestamp"
              label="执行时间"
              width="180"
              sortable
            >
              <template #default="scope">
                {{ formatTimestamp(scope.row.timestamp) }}
              </template>
            </el-table-column>
            <el-table-column
              prop="sql"
              label="SQL语句"
              min-width="400"
            >
              <template #default="scope">
                <div class="sql-history-item" :title="scope.row.sql">
                  {{ scope.row.sql.length > 100 ? scope.row.sql.substring(0, 100) + '...' : scope.row.sql }}
                </div>
              </template>
            </el-table-column>
            <el-table-column
              label="操作"
              width="120"
              fixed="right"
            >
              <template #default="scope">
                <el-button 
                  type="primary" 
                  size="small" 
                  @click.stop="useHistoryItem(scope.row)"
                >
                  使用
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button size="small" @click="historyDialogVisible = false">关闭</el-button>
          <el-button type="danger" size="small" @click="clearHistory" :disabled="sqlHistory.length === 0">
            清空历史
          </el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 数据可视化对话框 -->
    <el-dialog
      v-model="chartDialogVisible"
      title="📊 数据可视化"
      width="1000px"
      center
      class="chart-dialog draggable-dialog"
      :close-on-click-modal="false"
    >
      <div class="chart-content">
        <div class="chart-controls">
          <div class="control-row">
            <div class="control-item">
              <label class="control-label">📊 图表类型</label>
              <el-select v-model="chartType" @change="updateChart" placeholder="请选择图表类型">
                <el-option label="📊 柱状图" value="bar" />
                <el-option label="📈 折线图" value="line" />
                <el-option label="🥧 饼图" value="pie" />
              </el-select>
            </div>
            <div class="control-item">
              <label class="control-label">📍 X 轴字段</label>
              <el-select v-model="chartXField" @change="updateChart" placeholder="选择 X 轴字段">
                <el-option 
                  v-for="col in availableColumns" 
                  :key="col" 
                  :label="col" 
                  :value="col" 
                />
              </el-select>
            </div>
            <div class="control-item">
              <label class="control-label">📏 Y 轴字段</label>
              <el-select v-model="chartYField" @change="updateChart" placeholder="选择 Y 轴字段">
                <el-option 
                  v-for="col in availableColumns" 
                  :key="col" 
                  :label="col" 
                  :value="col" 
                />
              </el-select>
            </div>
          </div>
          <div class="control-row" style="margin-top: 15px;">
            <div class="control-item">
              <label class="control-label">📈 汇总方式</label>
              <el-select v-model="chartAggregation" @change="updateChart" placeholder="选择汇总方式">
                <el-option label="求和 (sum)" value="sum" />
                <el-option label="平均值 (avg)" value="avg" />
                <el-option label="最大值 (max)" value="max" />
                <el-option label="最小值 (min)" value="min" />
                <el-option label="计数 (count)" value="count" />
              </el-select>
            </div>
            <div class="control-item">
              <label class="control-label">🔄 排序字段</label>
              <el-select v-model="chartSortField" @change="updateChart" placeholder="选择排序字段">
                <el-option label="X 轴" value="x" />
                <el-option label="Y 轴" value="y" />
              </el-select>
            </div>
            <div class="control-item">
              <label class="control-label">📋 排序顺序</label>
              <el-select v-model="chartSortOrder" @change="updateChart" placeholder="选择排序顺序">
                <el-option label="升序" value="asc" />
                <el-option label="降序" value="desc" />
              </el-select>
            </div>
            <div class="control-item">
              <label class="control-label">🎨 图表样式</label>
              <el-select v-model="chartStyle" @change="updateChart" placeholder="选择图表样式">
                <el-option label="默认" value="default" />
                <el-option label="活力" value="vibrant" />
                <el-option label="商务" value="business" />
                <el-option label="科技" value="tech" />
              </el-select>
            </div>
          </div>
        </div>
        <div class="chart-wrapper">
          <div id="chart-container"></div>
        </div>
        <div v-if="chartData.length > 0" class="chart-summary">
          <div class="summary-item">
            <span class="summary-label">数据条数：</span>
            <span class="summary-value">{{ chartData.length }}</span>
          </div>
          <div class="summary-item">
            <span class="summary-label">X 轴字段：</span>
            <span class="summary-value">{{ chartXField }}</span>
          </div>
          <div class="summary-item">
            <span class="summary-label">Y 轴字段：</span>
            <span class="summary-value">{{ chartYField }}</span>
          </div>
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button size="small" @click="chartDialogVisible = false">关闭</el-button>
        </span>
      </template>
    </el-dialog>
  </template>

<script>
import axios from 'axios'
import { Codemirror } from 'vue-codemirror'
import { sql } from '@codemirror/lang-sql'

import { format } from 'sql-formatter'
import { Loading } from '@element-plus/icons-vue'
import * as echarts from 'echarts'

export default {
  name: 'App',
  components: {
    Codemirror,
    Loading
  },
  data() {
    return {
      form: {
        sql: ''
      },
      editorHeight: '200px',
      tableData: [],
      columns: [],
      error: '',
      lastSql: '',
      currentPage: 1,
      pageSize: 10,
      totalCount: 0,
      loading: false,
      sampleQueries: [
        { name: '查看所有表', sql: 'SELECT * FROM sqlite_master WHERE type="table"' },
        { name: '查看表结构', sql: 'PRAGMA table_info(shjl)' },
        { name: '查询前10条数据', sql: 'SELECT * FROM shjl LIMIT 10' }
      ],

      // 导入Excel相关
      importDialogVisible: false,
      importForm: {
        importType: 'create', // create: 新建表, append: 增量导入
        tableName: '',
        targetTable: ''
      },
      selectedFile: null,
      importLoading: false,
      importProgress: 0,
      importStats: {
        processed: 0,
        total: 0
      },
      exportLoading: false,
      showFieldMapping: false,
      fieldMappings: [],
      tableFields: [],
      // 删除表相关
      deleteTableDialogVisible: false,
      deleteForm: {
        tableNames: []
      },
      deleteLoading: false,
      tables: [],
      // 压缩数据库相关
      vacuumLoading: false,
      // 数据库备份和恢复相关
      backupLoading: false,
      restoreDialogVisible: false,
      restoreFile: null,
      restoreLoading: false,
      // 查询结果缓存相关
      queryCache: {},
      maxCacheSize: 10, // 最大缓存条数
      // SQL语法检查相关
      sqlSyntaxError: '',
      syntaxCheckTimer: null,
      // SQL语句历史记录相关
      sqlHistory: [],
      maxHistorySize: 50, // 最大历史记录条数
      historyDialogVisible: false,
      // 数据可视化相关
      chartDialogVisible: false,
      chartType: 'bar', // 图表类型：bar, line, pie
      chartOptions: {},
      chartData: [],
      allChartData: [], // 全部数据用于图表分析
      chartXField: '', // X轴字段
      chartYField: '', // Y轴字段
      chartSortField: '', // 排序字段
      chartSortOrder: 'asc', // 排序顺序：asc, desc
      chartAggregation: 'sum', // 汇总方式：sum, avg, max, min, count
      chartStyle: 'default', // 图表样式
    }
  },
  mounted() {
    // CodeMirror会自动处理初始化
    
    // 为数据可视化对话框添加拖动功能
    this.$nextTick(() => {
      this.makeDialogDraggable()
    })
  },
  computed: {
    hasResults() {
      return this.tableData.length > 0 || this.columns.length > 0
    },
    currentPageData() {
      const start = (this.currentPage - 1) * this.pageSize
      const end = start + this.pageSize
      return this.tableData.slice(start, end)
    },
    canImport() {
      if (this.importForm.importType === 'create') {
        return this.importForm.tableName && this.selectedFile
      } else {
        return this.importForm.targetTable && this.selectedFile && this.fieldMappings.length > 0
      }
    },
    extensions() {
      return [sql()]
    },
    availableColumns() {
      if (!this.columns || this.columns.length === 0) return []
      
      if (typeof this.columns[0] === 'string') {
        // columns是列名数组
        return this.columns
      } else {
        // columns是对象数组，带有prop属性
        return this.columns.map(col => col.prop)
      }
    }
  },
  methods: {
    makeDialogDraggable() {
      const dialog = document.querySelector('.chart-dialog')
      if (!dialog) return
      
      const header = dialog.querySelector('.el-dialog__header')
      if (!header) return
      
      let isDragging = false
      let startX, startY, startLeft, startTop
      
      header.addEventListener('mousedown', (e) => {
        isDragging = true
        startX = e.clientX
        startY = e.clientY
        
        const rect = dialog.getBoundingClientRect()
        startLeft = rect.left
        startTop = rect.top
        
        header.style.cursor = 'grabbing'
      })
      
      document.addEventListener('mousemove', (e) => {
        if (!isDragging) return
        
        const deltaX = e.clientX - startX
        const deltaY = e.clientY - startY
        
        dialog.style.left = `${startLeft + deltaX}px`
        dialog.style.top = `${startTop + deltaY}px`
        dialog.style.marginLeft = '0'
        dialog.style.marginTop = '0'
      })
      
      document.addEventListener('mouseup', () => {
        if (isDragging) {
          isDragging = false
          header.style.cursor = 'grab'
        }
      })
    },
    handleReady(payload) {
      this.view = payload.view
    },
    handleChange(value) {
      this.form.sql = value
      // 触发SQL语法检查
      this.checkSqlSyntax(value)
    },
    
    checkSqlSyntax(sql) {
      // 清除之前的定时器
      if (this.syntaxCheckTimer) {
        clearTimeout(this.syntaxCheckTimer)
      }
      
      // 设置新的定时器，实现防抖
      this.syntaxCheckTimer = setTimeout(() => {
        if (!sql.trim()) {
          this.sqlSyntaxError = ''
          return
        }
        
        try {
          // 使用sql-formatter的parse方法检查语法
          // 注意：sql-formatter主要用于格式化，不是专门的语法检查器
          // 这里我们使用try-catch来捕获格式化过程中的错误
          format(sql, {
            language: 'sqlite'
          })
          this.sqlSyntaxError = ''
        } catch (error) {
          this.sqlSyntaxError = `语法错误: ${error.message}`
        }
      }, 500) // 500ms防抖
    },
    async executeSql() {
      // 获取要执行的SQL语句（优先使用选中文本）
      let sqlToExecute = this.form.sql
      
      // 检查是否有选中文本
      if (this.view) {
        const selection = this.view.state.selection.main
        if (!selection.empty) {
          sqlToExecute = this.view.state.doc.sliceString(selection.from, selection.to)
        }
      }
      
      if (!sqlToExecute.trim()) {
        this.error = '请输入 SQL 语句'
        return
      }
      
      this.error = ''
      
      // 生成缓存键（使用SQL语句和分页参数）
      const cacheKey = `${sqlToExecute.trim()}_${this.currentPage}_${this.pageSize}`
      
      // 检查缓存中是否存在结果
      if (this.queryCache[cacheKey]) {
        console.log('使用缓存的查询结果')
        const cachedResult = this.queryCache[cacheKey]
        this.tableData = cachedResult.data
        this.columns = cachedResult.columns
        this.totalCount = cachedResult.total_count
        this.lastSql = sqlToExecute
        this.loading = false
        
        // 显示缓存提示
        this.$message({
          message: '使用缓存结果，查询速度更快！',
          type: 'info',
          duration: 2000,
          showClose: true
        })
        return
      }
      
      this.loading = true
      try {
        console.log('开始执行SQL:', sqlToExecute)
        const response = await axios.post('http://127.0.0.1:5000/api/execute', {
          sql: sqlToExecute,
          page: this.currentPage,
          page_size: this.pageSize
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        })
        console.log('SQL执行响应:', response.data)
        if (response.data.success) {
          this.tableData = response.data.data
          this.columns = response.data.columns || []
          this.totalCount = response.data.total_count || 0
          this.lastSql = sqlToExecute
          this.currentPage = 1 // 重置到第一页
          
          // 检测 SQL 语句类型，显示执行结果提示
          const sql = sqlToExecute.trim().toUpperCase()
          if (sql.startsWith('INSERT') || sql.startsWith('DELETE') || sql.startsWith('UPDATE')) {
            // 显示执行结果提示（使用 Element Plus 的消息提示）
            this.$message({
              message: `执行成功！<br>影响行数: ${response.data.affected_rows || 0}<br>执行时间: ${response.data.execution_time || '未知'}`,
              type: 'success',
              duration: 5000,
              showClose: true,
              dangerouslyUseHTMLString: true
            })
            
            // 对于修改操作，清空缓存
            this.clearQueryCache()
          } else {
            // 对于查询操作，缓存结果
            this.cacheQueryResult(cacheKey, response.data)
          }
          
          // 将SQL语句添加到历史记录
          this.addToHistory(sqlToExecute)
        } else {
          // 处理后端返回的错误
          const errorMsg = response.data.error
          console.error('SQL执行错误:', errorMsg)
          this.$message({
            message: `SQL执行失败: ${errorMsg}`,
            type: 'error',
            duration: 5000,
            showClose: true
          })
          this.error = errorMsg
        }
      } catch (error) {
        // 处理网络错误等前端错误
        console.error('执行请求失败:', error)
        let errorMsg = '执行请求失败'
        if (error.message) {
          errorMsg += ': ' + error.message
        }
        this.$message({
          message: errorMsg,
          type: 'error',
          duration: 5000,
          showClose: true
        })
        this.error = errorMsg
      } finally {
        console.log('执行完成，重置loading状态')
        this.loading = false
      }
    },
    
    cacheQueryResult(key, result) {
      // 检查缓存大小，如果超过最大限制，删除最旧的缓存
      const cacheKeys = Object.keys(this.queryCache)
      if (cacheKeys.length >= this.maxCacheSize) {
        // 删除第一个缓存（最旧的）
        delete this.queryCache[cacheKeys[0]]
      }
      
      // 缓存结果
      this.queryCache[key] = {
        data: result.data,
        columns: result.columns || [],
        total_count: result.total_count || 0,
        timestamp: Date.now()
      }
      
      console.log('查询结果已缓存:', key)
    },
    
    clearQueryCache() {
      this.queryCache = {}
      console.log('查询缓存已清空')
    },
    beautifySql() {
      try {
        this.form.sql = format(this.form.sql, {
          language: 'sqlite',
          indent: '  ',
          uppercase: false,
          linesBetweenQueries: 2
        })
        this.$message.success('SQL语句已美化')
      } catch (error) {
        this.$message.error('SQL美化失败: ' + error.message)
      }
    },
    async copySql() {
      try {
        // 获取要复制的SQL语句（优先使用选中文本）
        let sqlToCopy = this.form.sql
        
        // 检查是否有选中文本
        if (this.view) {
          const selection = this.view.state.selection.main
          if (!selection.empty) {
            sqlToCopy = this.view.state.doc.sliceString(selection.from, selection.to)
          }
        }
        
        await navigator.clipboard.writeText(sqlToCopy)
        this.$message.success('SQL语句已复制到剪贴板')
      } catch (error) {
        this.$message.error('复制失败: ' + error.message)
      }
    },
    async pasteSql() {
      try {
        const text = await navigator.clipboard.readText()
        this.form.sql = text
        this.$message.success('已从剪贴板粘贴SQL语句')
      } catch (error) {
        this.$message.error('粘贴失败: ' + error.message)
      }
    },

    formatDate() {
      const date = new Date()
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const seconds = String(date.getSeconds()).padStart(2, '0')
      return `${year}${month}${day}${hours}${minutes}${seconds}`
    },
    async exportCurrentPage() {
      if (!this.lastSql) {
        this.$message.warning('请先执行SQL查询')
        return
      }
      
      try {
        this.exportLoading = true
        // 构建导出当前页的SQL
        const currentPageSql = `${this.lastSql} LIMIT ${this.pageSize} OFFSET ${(this.currentPage - 1) * this.pageSize}`
        
        const response = await axios.post('http://127.0.0.1:5000/api/export', {
          sql: currentPageSql
        }, {
          headers: {
            'Content-Type': 'application/json'
          },
          responseType: 'blob'
        })
        
        // 处理导出文件
        this.handleExportResponse(response, 'current_page')
        
        // 显示成功提示
        this.$message.success('当前页数据导出成功')
      } catch (error) {
        console.error('导出失败:', error)
        this.$message.error('导出失败: ' + error.message)
      } finally {
        this.exportLoading = false
      }
    },
    
    async exportAllData() {
      if (!this.lastSql) {
        this.$message.warning('请先执行SQL查询')
        return
      }
      
      try {
        this.exportLoading = true
        const response = await axios.post('http://127.0.0.1:5000/api/export', {
          sql: this.lastSql
        }, {
          headers: {
            'Content-Type': 'application/json'
          },
          responseType: 'blob'
        })
        
        // 处理导出文件
        this.handleExportResponse(response, 'all')
        
        // 显示成功提示
        this.$message.success('全部数据导出成功')
      } catch (error) {
        console.error('导出失败:', error)
        this.$message.error('导出失败: ' + error.message)
      } finally {
        this.exportLoading = false
      }
    },
    
    // 处理导出响应
    handleExportResponse(response, type) {
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `${this.formatDate()}_${type}.xlsx`)
      document.body.appendChild(link)
      link.click()
      // 清理
      setTimeout(() => {
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
      }, 100)
    },
    handleSizeChange(val) {
      this.pageSize = val
      this.currentPage = 1 // 重置到第一页
      this.executeSql()
    },
    handleCurrentChange(val) {
      this.currentPage = val
      this.executeSql()
    },
    showMonitor() {
      window.open('http://127.0.0.1:5000/', '_blank')
    },
    loadSampleQuery(sql) {
      this.form.sql = sql
    },
    // 导入Excel相关方法
    showImportDialog() {
      console.log('点击了导入Excel按钮')
      try {
        // 先重置表单数据
        this.importForm = {
          importType: 'create',
          tableName: '',
          targetTable: ''
        }
        this.selectedFile = null
        this.error = ''
        this.importLoading = false
        this.importProgress = 0
        this.importStats = {
          processed: 0,
          total: 0
        }
        this.showFieldMapping = false
        this.fieldMappings = []
        this.tableFields = []
        
        // 加载表列表
        console.log('开始加载表列表')
        this.loadTables().then(() => {
          console.log('表列表加载完成')
          // 表列表加载完成后再显示对话框
          console.log('设置importDialogVisible为true')
          this.importDialogVisible = true
          // 清除文件上传组件的状态
          this.$nextTick(() => {
            try {
              const uploadComponent = this.$refs.excelUpload
              if (uploadComponent) {
                uploadComponent.clearFiles()
                console.log('清除文件上传组件状态')
              }
            } catch (error) {
              console.error('清除文件上传组件状态失败:', error)
            }
          })
        }).catch((error) => {
          console.error('加载表列表失败:', error)
          // 即使表列表加载失败，也显示对话框
          this.importDialogVisible = true
        })
      } catch (error) {
        console.error('showImportDialog方法执行失败:', error)
        // 即使方法执行失败，也显示对话框
        this.importDialogVisible = true
      }
    },
    resetImportForm() {
      try {
        // 对话框关闭时重置表单
        this.importForm = {
          importType: 'create',
          tableName: '',
          targetTable: ''
        }
        this.selectedFile = null
        this.error = ''
        this.importLoading = false
        this.importProgress = 0
        this.importStats = {
          processed: 0,
          total: 0
        }
        this.showFieldMapping = false
        this.fieldMappings = []
        this.tableFields = []
        
        // 清除文件上传组件的状态
        if (this.$refs.excelUpload) {
          try {
            this.$refs.excelUpload.clearFiles()
          } catch (error) {
            console.log('清除文件上传组件状态失败:', error)
          }
        }
      } catch (error) {
        console.error('重置导入表单失败:', error)
      }
    },
    handleImportTypeChange() {
      this.showFieldMapping = false
      this.fieldMappings = []
      this.tableFields = []
      // 切换到增量导入模式时重新加载表列表
      if (this.importForm.importType === 'append') {
        this.loadTables()
      }
    },
    async handleTableChange() {
      if (this.importForm.targetTable) {
        // 获取表结构
        try {
          const response = await axios.post('http://127.0.0.1:5000/api/execute', {
            sql: `PRAGMA table_info(${this.importForm.targetTable})`
          })
          if (response.data.success) {
            // 排除系统字段 sysdbID 和 sysdbDate
            this.tableFields = response.data.data
              .map(field => field.name)
              .filter(field => !['sysdbID', 'sysdbDate'].includes(field))
            console.log('获取到的表字段:', this.tableFields)
            // 检查是否已选择文件
            if (this.selectedFile) {
              this.analyzeExcelFile()
            }
          }
        } catch (error) {
          this.error = '获取表结构失败: ' + error.message
          console.error('获取表结构失败:', error)
        }
      }
    },
    removeFile() {
      this.selectedFile = null
      // 清除文件上传组件的状态
      this.$nextTick(() => {
        try {
          const uploadComponent = this.$refs.excelUpload
          if (uploadComponent) {
            uploadComponent.clearFiles()
            console.log('清除文件上传组件状态')
          }
        } catch (error) {
          console.error('清除文件上传组件状态失败:', error)
        }
      })
      // 重置字段映射信息
      this.fieldMappings = []
      this.showFieldMapping = false
      console.log('文件已移除，字段映射已重置')
    },
    async handleFileChange(file) {
      this.selectedFile = file.raw
      // 分析Excel文件，获取列名
      if (this.importForm.importType === 'append' && this.importForm.targetTable) {
        await this.analyzeExcelFile()
      }
    },
    async analyzeExcelFile() {
      if (!this.selectedFile || this.tableFields.length === 0) {
        console.log('分析Excel文件失败：未选择文件或未获取表字段')
        return
      }
      
      try {
        const formData = new FormData()
        formData.append('file', this.selectedFile)
        
        // 发送请求获取Excel列名
        const response = await axios.post('http://127.0.0.1:5000/api/analyze_excel', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        if (response.data.success) {
          const excelColumns = response.data.columns
          console.log('Excel列名:', excelColumns)
          console.log('表字段:', this.tableFields)
          
          // 确保excelColumns是数组
          if (!Array.isArray(excelColumns)) {
            console.error('Excel列名不是数组:', excelColumns)
            this.error = '分析Excel文件失败: 列名格式错误'
            return
          }
          
          // 生成字段映射
          this.fieldMappings = excelColumns.map(column => {
            // 尝试自动匹配字段名
            const matchedField = this.tableFields.find(field => {
              const fieldStr = String(field).toLowerCase()
              const columnStr = String(column).toLowerCase().replace(/\s+/g, '')
              return fieldStr === columnStr
            })
            return {
              excelColumn: column,
              dbField: matchedField || ''
            }
          })
          
          console.log('生成的字段映射:', this.fieldMappings)
          console.log('字段映射长度:', this.fieldMappings.length)
          this.showFieldMapping = true
        } else {
          const errorMsg = response.data.error
          console.error('分析Excel文件失败:', errorMsg)
          this.$message({
            message: `分析Excel文件失败: ${errorMsg}`,
            type: 'error',
            duration: 5000,
            showClose: true
          })
          this.error = errorMsg
        }
      } catch (error) {
        const errorMsg = '分析Excel文件失败: ' + error.message
        console.error('分析Excel文件异常:', error)
        this.$message({
          message: errorMsg,
          type: 'error',
          duration: 5000,
          showClose: true
        })
        this.error = errorMsg
      }
    },
    importExcel() {
      if (this.importForm.importType === 'create') {
        if (!this.importForm.tableName) {
          this.$message({
            message: '请输入表名',
            type: 'warning',
            duration: 3000,
            showClose: true
          })
          this.error = '请输入表名'
          return
        }
      } else {
        if (!this.importForm.targetTable) {
          this.$message({
            message: '请选择要导入的表',
            type: 'warning',
            duration: 3000,
            showClose: true
          })
          this.error = '请选择要导入的表'
          return
        }
        // 检查是否至少有一个字段映射
        const hasMapped = this.fieldMappings.some(mapping => mapping.dbField)
        if (!hasMapped) {
          this.$message({
            message: '请至少映射一个字段',
            type: 'warning',
            duration: 3000,
            showClose: true
          })
          this.error = '请至少映射一个字段'
          return
        }
      }
      
      if (!this.selectedFile) {
        this.$message({
          message: '请选择Excel文件',
          type: 'warning',
          duration: 3000,
          showClose: true
        })
        this.error = '请选择Excel文件'
        return
      }
      
      // 提示用户大文件可能需要较长时间
      if (this.selectedFile.size > 10 * 1024 * 1024) {
        if (!confirm('文件较大，导入可能需要较长时间，确定继续吗？')) {
          return
        }
      }
      
      // 清理表名
      let tableName = ''
      if (this.importForm.importType === 'create') {
        tableName = this.sanitizeTableName(this.importForm.tableName)
      } else {
        tableName = this.importForm.targetTable
      }
      
      // 重置进度
      this.importLoading = true
      this.importProgress = 0
      this.importStats = {
        processed: 0,
        total: 0
      }
      
      const formData = new FormData()
      formData.append('file', this.selectedFile)
      
      if (this.importForm.importType === 'create') {
        formData.append('table_name', tableName)
        formData.append('import_type', 'create')
      } else {
        formData.append('table_name', tableName)
        formData.append('import_type', 'append')
        formData.append('field_mappings', JSON.stringify(this.fieldMappings))
      }
      
      // 使用XMLHttpRequest发送请求，支持SSE实时进度更新
      const xhr = new XMLHttpRequest()
      xhr.open('POST', 'http://127.0.0.1:5000/api/import')
      
      // 用于跟踪已经处理的响应数据长度
      let lastResponseLength = 0
      
      // 处理SSE响应
      xhr.onreadystatechange = () => {
        if (xhr.readyState === 3 && xhr.status === 200) {
          // 读取新的响应数据
          const responseText = xhr.responseText
          const newData = responseText.substring(lastResponseLength)
          const lines = newData.split('\n')
          
          // 更新已处理的响应数据长度
          lastResponseLength = responseText.length
          
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              try {
                const data = JSON.parse(line.substring(6))
                
                if (data.status === 'processing') {
                  // 更新进度
                  this.importProgress = data.progress || 0
                  // 更新导入统计信息
                  if (data.processed !== undefined) {
                    this.importStats.processed = data.processed
                  }
                  if (data.total !== undefined) {
                    this.importStats.total = data.total
                  }
                } else if (data.status === 'completed') {
                  // 导入完成
                  this.importLoading = false
                  this.importProgress = 100
                  // 更新导入统计信息
                  if (data.processed !== undefined) {
                    this.importStats.processed = data.processed
                  }
                  if (data.total !== undefined) {
                    this.importStats.total = data.total
                  }
                  
                  // 先显示导入完成对话框
                  this.$alert(
                    `<div style="font-size: 14px;">
                      <p>导入成功！</p>
                      <p>表名: ${tableName}</p>
                      <p>导入记录数: ${data.processed || 0} 条</p>
                      <p>导入时间: ${data.time_taken || '未知'}</p>
                      <p>导入完成，请点击刷新按钮更新表列表</p>
                    </div>`,
                    '导入完成',
                    {
                      dangerouslyUseHTMLString: true,
                      confirmButtonText: '确定',
                      callback: () => {
                        // 对话框关闭后再关闭导入对话框并重置表单
                        this.importDialogVisible = false
                        this.resetImportForm()
                      }
                    }
                  )
                  return
                } else if (data.status === 'error') {
                  // 导入失败
                  this.importLoading = false
                  this.error = '导入失败: ' + data.error
                  return
                }
              } catch (e) {
                console.error('解析SSE数据失败:', e)
              }
            }
          }
        } else if (xhr.readyState === 4) {
          // 请求完成但没有收到completed消息
          if (xhr.status !== 200) {
            this.importLoading = false
            this.error = '导入失败: 服务器返回错误 ' + xhr.status
          }
        }
      }
      
      // 处理请求错误
      xhr.onerror = () => {
        this.importLoading = false
        this.error = '导入失败: 网络错误'
      }
      
      // 发送请求
      xhr.send(formData)
    },
    // 清理表名，确保符合SQLite要求
    sanitizeTableName(name) {
      if (!name) return ''
      // 清理特殊字符，只保留字母、数字和下划线
      let sanitized = name.replace(/[^\w]/g, '_')
      // 确保不以数字开头，如果是则加前缀
      if (sanitized && /^\d/.test(sanitized)) {
        sanitized = 'table_' + sanitized
      }
      // 如果表名为空，使用默认名称
      if (!sanitized) {
        sanitized = 'imported_table'
      }
      return sanitized
    },
    // 删除表相关方法
    async showDeleteTableDialog() {
      await this.loadTables()
      this.deleteTableDialogVisible = true
      this.deleteForm.tableNames = []
    },
    async loadTables() {
      try {
        const response = await axios.post('http://127.0.0.1:5000/api/execute', {
          sql: 'SELECT name FROM sqlite_master WHERE type="table"'
        })
        if (response.data.success) {
          this.tables = response.data.data
        } else {
          console.error('加载表列表失败:', response.data.error)
        }
        return true
      } catch (error) {
        console.error('加载表列表失败:', error)
        return false
      }
    },
    
    // 刷新表列表（和浏览器刷新按钮功能一样）
    refreshTables() {
      // 直接刷新整个页面
      location.reload()
    },
    handleTableSelectionChange(selection) {
      // 将选中的表名转换为数组
      this.deleteForm.tableNames = selection.map(item => item.name)
    },
    async deleteTable() {
      if (this.deleteForm.tableNames.length === 0) {
        this.$message({
          message: '请选择要删除的表',
          type: 'warning',
          duration: 3000,
          showClose: true
        })
        this.error = '请选择要删除的表'
        return
      }
      
      if (!confirm('确定要删除选中的 ' + this.deleteForm.tableNames.length + ' 个表吗？此操作不可恢复！')) {
        return
      }
      
      this.deleteLoading = true
      try {
        const response = await axios.post('http://127.0.0.1:5000/api/delete_table', {
          table_names: this.deleteForm.tableNames
        })
        
        if (response.data.success) {
          this.$message.success(response.data.message)
          this.deleteTableDialogVisible = false
          // 重新加载表列表
          this.loadTables()
        } else {
          const errorMsg = response.data.error
          console.error('删除表失败:', errorMsg)
          this.$message({
            message: `删除失败: ${errorMsg}`,
            type: 'error',
            duration: 5000,
            showClose: true
          })
          this.error = errorMsg
        }
      } catch (error) {
        const errorMsg = '删除失败: ' + error.message
        console.error('删除表异常:', error)
        this.$message({
          message: errorMsg,
          type: 'error',
          duration: 5000,
          showClose: true
        })
        this.error = errorMsg
      } finally {
        this.deleteLoading = false
      }
    },
    // 计算行号的方法，确保换页时不重新计数
    indexMethod(index) {
      return (this.currentPage - 1) * this.pageSize + index + 1
    },
    // 更新行号

    async vacuumDatabase() {
      // 使用 Element Plus 的确认对话框
      this.$confirm('确定要压缩数据库吗？此操作可能需要一些时间。', '压缩数据库', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async () => {
        // 显示加载状态
        this.vacuumLoading = true
        try {
          const response = await axios.post('http://127.0.0.1:5000/api/vacuum')
          
          if (response.data.success) {
            const details = response.data.details
            // 显示成功提示
            this.$message({
              message: response.data.message,
              type: 'success',
              duration: 5000,
              showClose: true
            })
            // 显示详细信息（压缩前后对比）
            this.$alert(
              `<div style="font-size: 14px;">
                <h3 style="margin-bottom: 16px; color: #409EFF;">压缩前后对比</h3>
                <table style="width: 100%; border-collapse: collapse; margin-bottom: 16px;">
                  <tr style="border-bottom: 1px solid #e4e7ed;">
                    <td style="padding: 8px; font-weight: 500;">压缩时间:</td>
                    <td style="padding: 8px;">${details.time_taken}</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #e4e7ed;">
                    <td style="padding: 8px; font-weight: 500;">压缩前大小:</td>
                    <td style="padding: 8px; color: #e74c3c;">${details.size_before}</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #e4e7ed;">
                    <td style="padding: 8px; font-weight: 500;">压缩后大小:</td>
                    <td style="padding: 8px; color: #27ae60;">${details.size_after}</td>
                  </tr>
                  <tr>
                    <td style="padding: 8px; font-weight: 500;">节省空间:</td>
                    <td style="padding: 8px; color: #f39c12;">${details.space_saved}</td>
                  </tr>
                </table>
              </div>`,
              '压缩详情',
              {
                dangerouslyUseHTMLString: true,
                confirmButtonText: '确定',
                customClass: 'vacuum-details-dialog'
              }
            )
          } else {
            this.$message.error(response.data.error)
          }
        } catch (error) {
          console.error('压缩数据库失败:', error)
          this.$message.error('压缩数据库失败: ' + error.message)
        } finally {
          this.vacuumLoading = false
        }
      }).catch(() => {
        // 用户取消压缩
        this.$message({
          type: 'info',
          message: '已取消压缩操作'
        })
      })
    },
    
    async backupDatabase() {
      // 使用 Element Plus 的确认对话框
      this.$confirm('确定要备份数据库吗？', '备份数据库', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }).then(async () => {
        // 显示加载状态
        this.backupLoading = true
        try {
          const response = await axios.post('http://127.0.0.1:5000/api/backup')
          
          if (response.data.success) {
            // 显示成功提示
            this.$message({
              message: `备份成功！备份文件: ${response.data.backup_file}`,
              type: 'success',
              duration: 5000,
              showClose: true
            })
          } else {
            this.$message.error(`备份失败: ${response.data.error}`)
          }
        } catch (error) {
          console.error('备份数据库失败:', error)
          this.$message.error('备份数据库失败: ' + error.message)
        } finally {
          this.backupLoading = false
        }
      }).catch(() => {
        // 用户取消备份
        this.$message({
          type: 'info',
          message: '已取消备份操作'
        })
      })
    },
    
    showRestoreDialog() {
      this.restoreFile = null
      this.restoreDialogVisible = true
    },
    
    handleRestoreFileChange(file) {
      this.restoreFile = file
    },
    
    async restoreDatabase() {
      if (!this.restoreFile) {
        this.$message({
          message: '请选择备份文件',
          type: 'warning'
        })
        return
      }
      
      // 使用 Element Plus 的确认对话框
      this.$confirm('确定要恢复数据库吗？此操作将覆盖当前数据库内容！', '恢复数据库', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'danger'
      }).then(async () => {
        // 显示加载状态
        this.restoreLoading = true
        try {
          const formData = new FormData()
          formData.append('file', this.restoreFile.raw)
          
          const response = await axios.post('http://127.0.0.1:5000/api/restore', formData, {
            headers: {
              'Content-Type': 'multipart/form-data'
            }
          })
          
          if (response.data.success) {
            // 显示成功提示
            this.$message({
              message: response.data.message,
              type: 'success',
              duration: 5000,
              showClose: true
            })
            this.restoreDialogVisible = false
            this.refreshTables() // 刷新表列表
          } else {
            this.$message.error(`恢复失败: ${response.data.error}`)
          }
        } catch (error) {
          console.error('恢复数据库失败:', error)
          this.$message.error('恢复数据库失败: ' + error.message)
        } finally {
          this.restoreLoading = false
        }
      }).catch(() => {
        // 用户取消恢复
        this.$message({
          type: 'info',
          message: '已取消恢复操作'
        })
      })
    },
    
    // SQL语句历史记录相关方法
    showHistoryDialog() {
      this.historyDialogVisible = true
    },
    
    addToHistory(sql) {
      if (!sql.trim()) return
      
      // 检查是否已经存在相同的SQL语句（最近的10条）
      const recentHistory = this.sqlHistory.slice(0, 10)
      const isDuplicate = recentHistory.some(item => item.sql === sql)
      
      if (isDuplicate) return
      
      // 添加到历史记录的开头
      this.sqlHistory.unshift({
        id: Date.now(),
        sql: sql,
        timestamp: Date.now()
      })
      
      // 限制历史记录数量
      if (this.sqlHistory.length > this.maxHistorySize) {
        this.sqlHistory = this.sqlHistory.slice(0, this.maxHistorySize)
      }
      
      console.log('SQL语句已添加到历史记录:', sql)
    },
    
    selectHistoryItem(row) {
      // 点击行时使用该历史记录
      this.useHistoryItem(row)
    },
    
    useHistoryItem(row) {
      this.form.sql = row.sql
      this.historyDialogVisible = false
      // 触发语法检查
      this.checkSqlSyntax(row.sql)
      this.$message({
        message: '已加载历史SQL语句',
        type: 'success',
        duration: 2000
      })
    },
    
    clearHistory() {
      this.$confirm('确定要清空所有SQL语句历史记录吗？', '清空历史记录', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.sqlHistory = []
        this.$message({
          message: '历史记录已清空',
          type: 'success'
        })
      }).catch(() => {
        // 用户取消清空
      })
    },
    
    formatTimestamp(timestamp) {
      const date = new Date(timestamp)
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    },
    
    // 数据可视化相关方法
    showChartDialog() {
      this.chartDialogVisible = true
      // 延迟初始化图表，确保DOM已经渲染
      setTimeout(() => {
        this.getAllDataForChart()
      }, 100)
    },
    
    async getAllDataForChart() {
      if (!this.lastSql) {
        this.$message.warning('请先执行SQL查询')
        this.chartDialogVisible = false
        return
      }
      
      this.loading = true
      try {
        // 发送请求获取全部数据（不分页）
        const response = await axios.post('http://127.0.0.1:5000/api/execute', {
          sql: this.lastSql,
          page: 1,
          page_size: 10000 // 设置一个足够大的值来获取全部数据
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        })
        
        if (response.data.success) {
          // 保存全部数据用于图表分析
          this.allChartData = response.data.data
          this.initChart()
        } else {
          this.$message.error('获取数据失败: ' + response.data.error)
          this.chartDialogVisible = false
        }
      } catch (error) {
        this.$message.error('获取数据失败: ' + error.message)
        this.chartDialogVisible = false
      } finally {
        this.loading = false
      }
    },
    
    initChart() {
      // 准备图表数据
      this.prepareChartData()
      
      // 初始化ECharts实例
      const chartDom = document.getElementById('chart-container')
      if (!chartDom) return
      
      const myChart = echarts.init(chartDom)
      
      // 设置图表选项
      const option = this.getChartOption()
      
      // 渲染图表
      myChart.setOption(option)
      
      // 监听窗口大小变化，自动调整图表大小
      window.addEventListener('resize', () => {
        myChart.resize()
      })
    },
    
    updateChart() {
      // 重新初始化图表
      this.initChart()
    },
    
    prepareChartData() {
      // 从allChartData中提取数据
      this.chartData = []
      
      if (this.allChartData.length === 0 || this.columns.length === 0) return
      
      // 检查是否已选择字段
      let xAxisField, yAxisField
      if (this.chartXField && this.chartYField) {
        // 使用用户选择的字段
        xAxisField = this.chartXField
        yAxisField = this.chartYField
      } else {
        // 自动选择字段
        if (typeof this.columns[0] === 'string') {
          // columns是列名数组
          xAxisField = this.columns[0]
          yAxisField = this.columns.length > 1 ? this.columns[1] : this.columns[0]
        } else {
          // columns是对象数组，带有prop属性
          xAxisField = this.columns[0].prop
          yAxisField = this.columns.length > 1 ? this.columns[1].prop : this.columns[0].prop
        }
        // 设置默认选择
        this.chartXField = xAxisField
        this.chartYField = yAxisField
        // 设置默认排序字段
        this.chartSortField = 'x'
      }
      
      // 按X轴分类汇总Y轴字段
      const aggregatedData = {}
      
      this.allChartData.forEach(row => {
        const xValue = row[xAxisField]
        const yValue = parseFloat(row[yAxisField]) || 0
        
        if (!aggregatedData[xValue]) {
          aggregatedData[xValue] = []
        }
        aggregatedData[xValue].push(yValue)
      })
      
      // 计算汇总值
      for (const [xValue, yValues] of Object.entries(aggregatedData)) {
        let aggregatedValue
        
        switch (this.chartAggregation) {
          case 'sum':
            aggregatedValue = yValues.reduce((sum, val) => sum + val, 0)
            break
          case 'avg':
            aggregatedValue = yValues.reduce((sum, val) => sum + val, 0) / yValues.length
            break
          case 'max':
            aggregatedValue = Math.max(...yValues)
            break
          case 'min':
            aggregatedValue = Math.min(...yValues)
            break
          case 'count':
            aggregatedValue = yValues.length
            break
          default:
            aggregatedValue = yValues.reduce((sum, val) => sum + val, 0)
        }
        
        // 保留2位小数（除了计数）
        if (this.chartAggregation !== 'count') {
          aggregatedValue = parseFloat(aggregatedValue.toFixed(2))
        }
        
        this.chartData.push({
          name: xValue,
          value: aggregatedValue
        })
      }
      
      // 排序
      if (this.chartSortField) {
        this.chartData.sort((a, b) => {
          let aValue, bValue
          
          if (this.chartSortField === 'x') {
            aValue = a.name
            bValue = b.name
          } else {
            aValue = a.value
            bValue = b.value
          }
          
          if (this.chartSortOrder === 'asc') {
            return aValue > bValue ? 1 : -1
          } else {
            return aValue < bValue ? 1 : -1
          }
        })
      }
    },
    
    getChartOption() {
      // 图表样式配置
      const styles = {
        default: {
          color: '#4361ee',
          background: '#ffffff'
        },
        vibrant: {
          color: '#ec4899',
          background: '#fdf2f8'
        },
        business: {
          color: '#3b82f6',
          background: '#eff6ff'
        },
        tech: {
          color: '#10b981',
          background: '#ecfdf5'
        }
      }
      
      const style = styles[this.chartStyle] || styles.default
      
      const option = {
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            type: 'shadow'
          }
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          containLabel: true
        }
      }
      
      if (this.chartType === 'pie') {
        // 饼图配置
        option.series = [{
          name: '数据',
          type: 'pie',
          radius: '50%',
          data: this.chartData,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          },
          itemStyle: {
            color: function(params) {
              const colors = [
                style.color,
                '#8b5cf6',
                '#ec4899',
                '#10b981',
                '#f59e0b'
              ]
              return colors[params.dataIndex % colors.length]
            }
          }
        }]
      } else {
        // 柱状图或折线图配置
        const xAxisData = this.chartData.map(item => item.name)
        const yAxisData = this.chartData.map(item => item.value)
        
        option.xAxis = {
          type: 'category',
          data: xAxisData,
          axisLabel: {
            rotate: 45
          }
        }
        
        option.yAxis = {
          type: 'value'
        }
        
        option.series = [{
          name: '数据',
          type: this.chartType,
          data: yAxisData,
          itemStyle: {
            color: style.color
          }
        }]
      }
      
      return option
    },
    

  }
}
</script>

<style>
:root {
  --primary-color: #4361ee;
  --success-color: #3a0ca3;
  --warning-color: #f72585;
  --error-color: #4cc9f0;
  --info-color: #4895ef;
  --border-radius: 8px;
  --shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  --shadow-hover: 0 4px 20px rgba(0, 0, 0, 0.15);
  --transition: all 0.3s ease;
  --background: linear-gradient(135deg, #4361ee 0%, #3a0ca3 100%);
  --card-bg: rgba(255, 255, 255, 0.95);
  --text-primary: #2b2d42;
  --text-secondary: #4a4e69;
  --text-light: #8d99ae;
  --border-color: #e0e0e0;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: var(--background);
}

#app {
  height: 100%;
  overflow: hidden;
}

/* 主容器 */
.app-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--background);
  overflow: hidden;
}

/* 顶部导航 */
.app-header {
  background: var(--card-bg);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  box-shadow: var(--shadow);
  z-index: 100;
  height: 50px;
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 16px;
  height: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.app-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: 6px;
}

.title-icon {
  font-size: 18px;
}

.header-actions {
  display: flex;
  gap: 6px;
}

.header-actions .el-button {
  border-radius: var(--border-radius);
  padding: 6px 12px;
  font-size: 12px;
  transition: var(--transition);
}

.header-actions .el-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
}

/* 主要内容 */
.app-main {
  flex: 1;
  overflow: hidden;
  padding: 12px;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  height: 100%;
  overflow-y: auto;
  padding-right: 6px;
}

/* 滚动条样式 */
.main-content::-webkit-scrollbar {
  width: 6px;
}

.main-content::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}

.main-content::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

.main-content::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}

/* 区域卡片 */
.section-card {
  background: var(--card-bg);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  transition: var(--transition);
  overflow: hidden;
  backdrop-filter: blur(10px);
}

.section-card:hover {
  box-shadow: var(--shadow-hover);
  transform: translateY(-1px);
}

.section-header {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
}

.section-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 1px;
}

.section-description {
  font-size: 11px;
  color: var(--text-light);
}

/* SQL输入区域 */
.sql-section {
  width: 100%;
}

.sql-input-wrapper {
  padding: 12px 16px 0;
}

.sql-input-header {
  margin-bottom: 6px;
}

.sql-input-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-primary);
}

.sql-input-container {
  position: relative;
  width: 100%;
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  background: #f8f9fa;
  overflow: hidden;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.08);
  display: flex;
}

.sql-editor-container {
  flex: 1;
  position: relative;
  min-height: 100px;
}



/* CodeMirror样式覆盖 */
.sql-editor-container .cm-editor {
  font-family: 'Courier New', monospace;
  font-size: 15px;
  line-height: 1.5;
  height: 100%;
  min-height: 200px;
  position: relative;
  z-index: 1;
}

.sql-editor-container .cm-focused {
  outline: none;
}

.sql-editor-container .cm-gutters {
  background: #e9ecef;
  border-right: 1px solid #dee2e6;
}

.sql-editor-container .cm-lineNumbers .cm-gutterElement {
  color: #6c757d;
  padding: 0 8px;
}

.sql-editor-container .cm-activeLineGutter {
  background: #dee2e6;
}

.sql-editor-container .cm-content {
  padding: 8px 0;
}

.sql-editor-container .cm-line {
  padding: 0 4px;
}

/* 确保CodeMirror文本颜色与浅色背景匹配 */
.sql-editor-container .cm-editor .cm-content {
  color: #212529;
}

/* 关键词高亮 */
.sql-editor-container .cm-editor .cm-keyword {
  color: #007bff;
  font-weight: 600;
}

/* 字符串高亮 */
.sql-editor-container .cm-editor .cm-string {
  color: #28a745;
}

/* 数字高亮 */
.sql-editor-container .cm-editor .cm-number {
  color: #dc3545;
}

/* 注释高亮 */
.sql-editor-container .cm-editor .cm-comment {
  color: #6c757d;
  font-style: italic;
}

.beautify-btn {
  position: absolute;
  top: 6px;
  right: 6px;
  z-index: 10;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  font-size: 11px;
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  background: white;
  cursor: pointer;
  transition: var(--transition);
}

.beautify-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(144, 147, 153, 0.3);
  border-color: var(--primary-color);
  color: var(--primary-color);
}

.sql-syntax-error {
  margin-top: 8px;
  margin-bottom: 8px;
}

.sql-actions {
  display: flex;
  gap: 6px;
  margin-top: 8px;
  margin-bottom: 12px;
}

.execute-button {
  margin-right: 4px;
  border-radius: var(--border-radius);
  font-weight: 500;
  transition: all 0.3s ease;
  flex: 0 0 auto;
}

.execute-button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(67, 97, 238, 0.4);
}

.execute-button:disabled {
  box-shadow: none;
}

.export-button {
  margin-left: 4px;
  border-radius: var(--border-radius);
  font-weight: 500;
  transition: all 0.3s ease;
  flex: 0 0 auto;
}

.export-button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(58, 12, 163, 0.4);
}

.export-button:disabled {
  box-shadow: none;
}

.copy-button,
.paste-button {
  margin: 0 4px;
  border-radius: var(--border-radius);
  font-weight: 500;
  transition: all 0.3s ease;
  flex: 0 0 auto;
}

.copy-button:hover:not(:disabled),
.paste-button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.4);
}

.copy-button:disabled,
.paste-button:disabled {
  box-shadow: none;
}

.export-loading-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 30px 0;
}

.export-loading-content .el-icon {
  font-size: 36px;
  margin-bottom: 16px;
  color: var(--primary-color);
  animation: spin 1s linear infinite;
}

.export-loading-content p {
  font-size: 14px;
  color: var(--text-secondary);
  margin: 0;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.vacuum-details-dialog {
  .el-dialog__body {
    padding: 20px;
  }
  
  h3 {
    margin-top: 0;
    font-size: 16px;
    color: var(--text-primary);
  }
  
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12px;
  }
  
  td {
    padding: 6px;
    font-size: 13px;
  }
  
  tr {
    border-bottom: 1px solid var(--border-color);
  }
  
  tr:last-child {
    border-bottom: none;
  }
}

.icon {
  font-size: 14px;
}

/* 错误提示 */
.error-alert {
  border-radius: var(--border-radius);
  margin: 0;
}

/* 结果区域 */
.results-section {
  width: 100%;
}

.table-container {
  padding: 0 16px;
  max-height: 320px;
  overflow: auto;
  overflow-x: scroll;
  border-radius: var(--border-radius);
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.08);
}

.table-container::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.table-container::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.table-container::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

.table-container::-webkit-scrollbar-thumb:hover {
  background: #555;
}

.result-table {
  border-radius: var(--border-radius);
  overflow: hidden;
  width: 100%;
  table-layout: fixed;
  border-collapse: collapse;
}

.result-table th {
  background: #fafafa !important;
  font-weight: 600 !important;
  color: var(--text-primary) !important;
  font-size: 12px !important;
  height: 36px !important;
  position: sticky;
  top: 0;
  z-index: 10;
  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.1);
  border-bottom: 1px solid #f0f0f0 !important;
}

.result-table td {
  font-size: 12px !important;
  height: 32px !important;
}

.result-table tr:hover {
  background: #f5f7fa !important;
}

.pagination-container {
  padding: 12px 16px;
  border-top: 1px solid #f0f0f0;
  display: flex;
  justify-content: flex-end;
  background: #fafafa;
}

.custom-pagination {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

/* 空状态 */
.empty-state {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
}

.empty-card {
  background: var(--card-bg);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  padding: 40px 30px;
  text-align: center;
  max-width: 400px;
  width: 100%;
  backdrop-filter: blur(10px);
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.6;
}

.empty-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.empty-description {
  font-size: 13px;
  color: var(--text-light);
  margin-bottom: 20px;
}

.empty-samples {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}

.sample-btn {
  border: 1px solid var(--border-color);
  border-radius: 16px;
  padding: 4px 12px;
  font-size: 12px;
  transition: var(--transition);
}

.sample-btn:hover {
  border-color: var(--primary-color);
  color: var(--primary-color);
  background: rgba(67, 97, 238, 0.1);
}

/* 页脚 */
.app-footer {
  background: var(--card-bg);
  backdrop-filter: blur(10px);
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  padding: 8px 0;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.1);
  height: 36px;
}

.footer-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11px;
}

.footer-info {
  font-size: 11px;
  color: var(--text-light);
}

.footer-links {
  display: flex;
  align-items: center;
  gap: 12px;
}

.footer-link {
  font-size: 11px;
  color: var(--primary-color);
  text-decoration: none;
  transition: var(--transition);
}

.footer-link:hover {
  color: #667eea;
  text-decoration: underline;
}

.footer-divider {
  color: var(--border-color);
  font-size: 11px;
}

/* 导入导出相关样式 */
.import-form {
  margin-top: 12px;
}

.table-name-input {
  width: 100%;
  border-radius: var(--border-radius);
  transition: all 0.3s ease;
}

.table-name-input:hover {
  box-shadow: 0 0 0 2px rgba(67, 97, 238, 0.2);
}

.table-select {
  width: 100%;
  border-radius: var(--border-radius);
  transition: all 0.3s ease;
}

.table-select:hover {
  box-shadow: 0 0 0 2px rgba(67, 97, 238, 0.2);
}

.selected-file {
  margin-top: 6px;
  padding: 6px 10px;
  background: linear-gradient(135deg, #f5f7fa 0%, #e4e9f2 100%);
  border-radius: var(--border-radius);
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
}

.file-name {
  font-size: 12px;
  color: var(--text-secondary);
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 500;
}

.selected-file .el-button {
  transition: all 0.3s ease;
  font-size: 11px;
  padding: 3px 6px;
}

.selected-file .el-button:hover {
  color: var(--error-color);
  border-color: var(--error-color);
}

.dialog-footer {
  width: 100%;
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

.dialog-footer .el-button {
  border-radius: var(--border-radius);
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.dialog-footer .el-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12);
}

.dialog-footer .el-button--primary {
  background: linear-gradient(135deg, #4361ee 0%, #3a0ca3 100%);
  border: none;
}

.dialog-footer .el-button--primary:hover {
  box-shadow: 0 2px 8px rgba(67, 97, 238, 0.4);
}

.field-mapping-container {
  margin-top: 8px;
  max-height: 180px;
  overflow: auto;
  border-radius: var(--border-radius);
  box-shadow: 0 1px 8px 0 rgba(0, 0, 0, 0.1);
  background: white;
  width: 100%;
}

.field-mapping-container :deep(.el-table) {
  border-radius: var(--border-radius);
  overflow: hidden;
  border: none !important;
  width: 100% !important;
}

.field-mapping-container :deep(.el-table__header-wrapper),
.field-mapping-container :deep(.el-table__body-wrapper) {
  width: 100% !important;
}

.field-mapping-container :deep(.el-table th) {
  background: linear-gradient(135deg, #4361ee 0%, #3a0ca3 100%) !important;
  font-weight: 600 !important;
  color: white !important;
  text-align: center;
  height: 28px;
  font-size: 10px;
  position: sticky;
  top: 0;
  z-index: 10;
}

.field-mapping-container :deep(.el-table td) {
  height: 26px;
  text-align: center;
  vertical-align: middle;
  border-bottom: 1px solid #f0f0f0;
  font-size: 10px !important;
}

.field-mapping-container :deep(.el-table .cell) {
  font-size: 10px !important;
}

.field-mapping-container :deep(.el-table tr:hover) {
  background-color: #f5f7fa !important;
}

.field-mapping-container :deep(.el-select) {
  width: 100%;
  max-width: 120px;
  font-size: 10px;
}

.field-mapping-container :deep(.el-select:hover) {
  box-shadow: 0 0 0 2px rgba(67, 97, 238, 0.2) !important;
}

.field-mapping-container :deep(.el-select .el-input__inner) {
  font-size: 10px;
  height: 22px;
}

.mappings-count {
  margin-bottom: 6px;
  font-size: 10px;
  color: var(--primary-color);
  text-align: left;
  padding: 3px 8px;
  background: linear-gradient(135deg, #f5f7fa 0%, #e4e9f2 100%);
  border-radius: 4px;
  font-weight: 600;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  display: inline-block;
}

.import-progress-container {
  width: 100%;
  margin: 8px 0;
}

.progress-info {
  margin-top: 4px;
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: var(--text-secondary);
}

.warning-message {
  margin-top: 16px;
}

.delete-table-content {
  margin-bottom: 16px;
  max-height: 350px;
  overflow: auto;
}

.table-container {
  margin-bottom: 16px;
}

.table-container :deep(.el-table) {
  border-radius: var(--border-radius);
  overflow: hidden;
}

.table-container :deep(.el-table th) {
  background: #fafafa !important;
  font-weight: 600 !important;
  color: var(--text-primary) !important;
}

.no-tables {
  padding: 30px 0;
  text-align: center;
}

.dialog-footer {
  width: 100%;
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

/* 响应式设计 */
/* 大屏幕设备（>= 1200px） */
@media (min-width: 1200px) {
  .main-content {
    max-width: 1400px;
    margin: 0 auto;
  }
}

/* 中等屏幕设备（768px - 1199px） */
@media (min-width: 768px) and (max-width: 1199px) {
  .main-content {
    max-width: 100%;
  }
  
  .app-title {
    font-size: 16px;
  }
  
  .header-actions {
    gap: 6px;
  }
  
  .sql-editor-container {
    height: 300px;
  }
}

/* 小屏幕设备（< 768px） */
@media (max-width: 767px) {
  .app-main {
    padding: 12px;
  }
  
  .header-content {
    padding: 0 12px;
  }
  
  .app-title {
    font-size: 14px;
  }
  
  .header-actions {
    gap: 4px;
    flex-wrap: wrap;
  }
  
  .header-actions .el-button {
    padding: 4px 8px;
    font-size: 11px;
  }
  
  .section-header {
    padding: 12px 16px;
  }
  
  .sql-input-wrapper {
    padding: 12px 16px 0;
  }
  
  .sql-input-container {
    flex-direction: column;
    gap: 8px;
  }
  
  .sql-editor-container {
    margin-right: 0;
    height: 250px;
  }
  
  .beautify-btn {
    align-self: flex-start;
  }
  
  .table-container {
    padding: 0 16px;
  }
  
  .pagination-container {
    padding: 12px 16px;
  }
  
  .sql-actions {
    flex-direction: column;
    align-items: stretch;
  }
  
  .execute-button,
  .copy-button,
  .paste-button,
  .export-button {
    width: 100%;
    margin-right: 0;
    margin-left: 0;
    margin-top: 6px;
  }
  
  .footer-content {
    flex-direction: column;
    gap: 4px;
    text-align: center;
  }
  
  .empty-card {
    padding: 30px 20px;
  }
  
  /* 表格响应式调整 */
  .el-table {
    font-size: 12px;
  }
  
  .el-table th,
  .el-table td {
    padding: 8px;
  }
  
  /* 对话框响应式调整 */
  .el-dialog {
    width: 90% !important;
    margin: 10vh auto !important;
  }
}

/* 超小屏幕设备（< 480px） */
@media (max-width: 479px) {
  .header-content {
    flex-direction: column;
    gap: 8px;
    align-items: flex-start;
  }
  
  .header-actions {
    width: 100%;
    justify-content: space-between;
  }
  
  .app-title {
    font-size: 12px;
  }
  
  .sql-editor-container {
    height: 200px;
  }
  
  .el-table {
    font-size: 11px;
  }
  
  .el-table th,
  .el-table td {
    padding: 6px;
  }
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}



/* 数据可视化对话框样式 */
.chart-dialog .el-dialog__header {
  padding: 20px 20px 15px;
  background: linear-gradient(135deg, #4361ee 0%, #3a0ca3 100%);
  border-radius: 8px 8px 0 0;
}

.chart-dialog .el-dialog__title {
  color: white;
  font-size: 18px;
  font-weight: 600;
}

.chart-dialog .el-dialog__body {
  padding: 20px;
  background-color: #f8f9fa;
}

.chart-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.chart-controls {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.control-row {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.control-item {
  flex: 1;
  min-width: 200px;
}

.control-label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #495057;
  font-size: 14px;
}

.control-item .el-select {
  width: 100%;
}

.chart-wrapper {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  min-height: 500px;
  position: relative;
}

#chart-container {
  width: 100%;
  height: 500px;
  cursor: move;
}





.chart-summary {
  background: white;
  padding: 15px 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  display: flex;
  gap: 30px;
  flex-wrap: wrap;
}

.summary-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.summary-label {
  color: #6c757d;
  font-size: 14px;
}

.summary-value {
  font-weight: 600;
  color: #4361ee;
  font-size: 14px;
}



/* 响应式设计 */
@media (max-width: 768px) {
  .control-row {
    flex-direction: column;
  }
  
  .control-item {
    min-width: 100%;
  }
  
  .chart-summary {
    flex-direction: column;
    gap: 10px;
  }
  
  .chart-dialog {
    width: 95% !important;
  }
}
</style>

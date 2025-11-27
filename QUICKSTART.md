# 🚀 快速启动指南

## 前提条件

- Python 3.8+
- Node.js 16+
- npm 或 yarn

## 一键启动（Windows）

最简单的方式！⭐

1. 双击项目根目录下的 `start.bat` 文件
2. 等待依赖检查和服务启动
3. 等待浏览器自动打开
4. 开始使用

**✨ 智能启动特性**：
- ✅ **自动检查依赖**：检查flask-cors和node_modules
- ✅ **自动安装依赖**：如果缺失，自动安装
- ✅ **自动启动后端**：Flask服务运行在5000端口
- ✅ **自动启动前端**：Vite服务运行在3000端口
- ✅ **自动打开浏览器**：访问 http://localhost:3000

**首次运行**：
- 后端依赖安装：~10秒
- 前端依赖安装：~30-60秒（根据网速）
- 后续运行：直接启动，无需等待

## 手动启动

### 步骤 1: 安装后端依赖

```bash
pip install -r requirements.txt
```

### 步骤 2: 启动后端服务

```bash
python app.py
```

服务启动在: http://localhost:5000

### 步骤 3: 安装前端依赖

```bash
cd web
npm install
```

### 步骤 4: 启动前端服务

```bash
npm run dev
```

前端启动在: http://localhost:3000

### 步骤 5: 开始使用

在浏览器中打开 http://localhost:3000

## 使用流程

1. 📱 **登录** - 输入超星学习通手机号和密码
2. 📚 **选课** - 选择要学习的课程（可多选）
3. ⚙️ **配置** - 设置播放倍速、并发数等参数
4. 🎯 **开始** - 点击"开始学习"按钮
5. 📊 **监控** - 实时查看学习进度和日志

## 功能特性

✨ **现代化UI** - 基于React + TailwindCSS的美观界面  
🎨 **响应式设计** - 支持桌面和移动端  
⚡ **实时更新** - 学习进度和日志实时刷新  
🔒 **安全可靠** - 密码仅用于验证，不保存  
📈 **进度可视** - 直观的进度条和状态显示  
📝 **日志查看** - 详细的执行日志输出  

## 配置说明

### 播放倍速
- 范围：1.0 - 2.0
- 推荐：1.0 - 1.5
- 影响：视频播放速度

### 并发章节数
- 范围：1 - 10
- 推荐：4 - 8
- 影响：同时处理的章节数量

### 未开放章节处理
- **retry** - 重试上一个任务点
- **ask** - 询问用户是否继续
- **continue** - 自动跳过

## 目录结构

```
chaoxing/
├── app.py              # Flask后端
├── main.py            # 命令行版本
├── start.bat          # 启动脚本
├── requirements.txt   # Python依赖
├── api/               # API模块
└── web/               # Web前端
    ├── src/
    │   ├── components/
    │   │   ├── Login.jsx
    │   │   ├── CourseSelection.jsx
    │   │   └── StudyProgress.jsx
    │   └── App.jsx
    └── package.json
```

## 故障排除

### 后端无法启动
```bash
# 检查Python版本
python --version

# 重新安装依赖
pip install -r requirements.txt --force-reinstall
```

### 前端无法启动
```bash
# 检查Node.js版本
node --version

# 清除缓存并重新安装
cd web
rm -rf node_modules package-lock.json
npm install
```

### 端口被占用
```bash
# Windows查看端口占用
netstat -ano | findstr :5000
netstat -ano | findstr :3000

# 结束进程
taskkill /PID <进程ID> /F
```

## 更多信息

- 详细文档：[WEB_FRONTEND_GUIDE.md](WEB_FRONTEND_GUIDE.md)
- 命令行版本：[README.md](README.md)
- 问题反馈：GitHub Issues

---

💡 **提示**：首次运行需要下载依赖，请耐心等待。

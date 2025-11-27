# 🚀 启动指南

## ✅ 依赖已安装

- ✅ 后端依赖：flask-cors 已安装
- ✅ 前端依赖：201个包已安装

---

## 🎯 现在可以启动了！

### 方式一：自动启动（推荐）⭐

**双击运行：**
```
start.bat
```

✨ **智能特性：**
- ✅ 自动检查后端依赖（flask-cors）
- ✅ 自动检查前端依赖（node_modules）
- ✅ 如果依赖缺失，自动安装
- ✅ 自动启动前后端服务
- ✅ 自动打开浏览器

### 方式二：手动启动

**1. 启动后端（在项目根目录）：**
```bash
python app.py
```
后端将运行在：http://localhost:5000

**2. 启动前端（新开一个终端，进入web目录）：**
```bash
cd web
npm run dev
```
前端将运行在：http://localhost:3000

**3. 打开浏览器访问：**
```
http://localhost:3000
```

---

## 📝 使用步骤

1. **登录** - 输入超星学习通手机号和密码
2. **选课** - 选择要学习的课程
3. **配置** - 设置播放倍速等参数
4. **高级配置**（可选）：
   - 点击"显示高级配置"
   - 配置题库（用于章节检测）
   - 配置通知（任务完成推送）
5. **开始** - 点击"开始学习"按钮
6. **监控** - 查看实时进度和日志

---

## ⚠️ 如果遇到问题

### 后端启动失败
```bash
# 重新安装依赖
pip install -r requirements.txt
```

### 前端启动失败
```bash
# 进入web目录
cd web

# 重新安装依赖
npm install
```

### 端口被占用
- 后端默认端口：5000
- 前端默认端口：3000

检查端口占用：
```bash
netstat -ano | findstr :5000
netstat -ano | findstr :3000
```

---

## 📚 完整文档

- [WEB_FRONTEND_GUIDE.md](WEB_FRONTEND_GUIDE.md) - 详细使用指南
- [QUICKSTART.md](QUICKSTART.md) - 快速开始
- [FEATURE_COMPARISON.md](FEATURE_COMPARISON.md) - 功能对照表
- [DEPENDENCIES.md](DEPENDENCIES.md) - 依赖清单（包含所有依赖信息）

---

**现在就开始使用吧！** 🎉

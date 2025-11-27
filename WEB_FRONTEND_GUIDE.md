# 超星学习通 Web 前端使用指南

## 📦 项目结构

```
chaoxing/
├── app.py                 # Flask后端API服务
├── main.py               # 命令行版本主程序
├── requirements.txt      # Python依赖
├── start.bat            # Windows快速启动脚本
├── api/                 # API模块
└── web/                 # Web前端目录
    ├── package.json     # Node.js依赖配置
    ├── vite.config.js   # Vite构建配置
    ├── tailwind.config.js  # TailwindCSS配置
    ├── index.html       # HTML入口
    ├── public/          # 静态资源
    └── src/             # 源代码
        ├── main.jsx     # React入口
        ├── App.jsx      # 主应用组件
        ├── index.css    # 全局样式
        ├── api/         # API请求封装
        │   └── axios.js
        ├── components/  # React组件
        │   ├── Login.jsx              # 登录页面
        │   ├── CourseSelection.jsx    # 课程选择页面
        │   ├── StudyProgress.jsx      # 学习进度页面
        │   └── ui/                    # UI组件库
        │       ├── Button.jsx
        │       ├── Card.jsx
        │       ├── Input.jsx
        │       └── Label.jsx
        └── lib/
            └── utils.js  # 工具函数
```

## 🚀 快速开始

### 方法一：使用启动脚本（推荐）

Windows用户可直接双击 `start.bat` 文件，脚本会自动：
1. 启动Flask后端服务（端口5000）
2. 启动Vite前端服务（端口3000）
3. 自动打开浏览器访问应用

### 方法二：手动启动

#### 1. 启动后端

```bash
# 安装Python依赖（首次运行）
pip install -r requirements.txt

# 启动后端服务
python app.py
```

后端将运行在 `http://localhost:5000`

#### 2. 启动前端

```bash
# 进入前端目录
cd web

# 安装Node.js依赖（首次运行）
npm install

# 启动开发服务器
npm run dev
```

前端将运行在 `http://localhost:3000`

## 🎨 界面功能

### 1. 登录页面
- 输入超星学习通手机号和密码
- 支持错误提示
- 现代化的UI设计

### 2. 课程选择页面
- 展示所有可用课程
- 支持单选或全选课程
- 可配置学习参数：
  - **播放倍速**：1.0 - 2.0倍速
  - **并发章节数**：同时处理的章节数量
  - **未开放章节处理**：retry/ask/continue
  
- **高级配置**（可折叠）：
  - **题库配置**：
    - 支持5种题库：言溪题库、LIKE知识库、TikuAdapter、AI大模型、硅基流动AI
    - Token配置（支持多个token）
    - 自动提交开关
    - 题库覆盖率设置
    - 查询延迟设置
    - AI模型配置（Endpoint、Key、Model）
  
  - **通知配置**：
    - 支持4种通知服务：Server酱、Qmsg酱、Bark、Telegram
    - 通知URL配置
    - Telegram专用Chat ID配置
    - 任务完成和错误自动推送

### 3. 学习进度页面
- 实时显示学习进度
- 展示当前正在学习的课程
- 实时日志输出
- 任务状态监控

## 🔧 技术栈

### 后端
- **Flask**: Web框架
- **Flask-CORS**: 跨域支持
- **Threading**: 异步任务处理

### 前端
- **React 18**: UI框架
- **Vite**: 构建工具
- **TailwindCSS**: CSS框架
- **Axios**: HTTP客户端
- **Lucide React**: 图标库

## 📡 API接口

### POST /api/login
登录验证

**请求体:**
```json
{
  "username": "手机号",
  "password": "密码",
  "use_cookies": false
}
```

**响应:**
```json
{
  "status": true,
  "msg": "登录成功",
  "data": {
    "username": "手机号"
  }
}
```

### POST /api/courses
获取课程列表

**请求体:**
```json
{
  "username": "手机号",
  "password": "密码"
}
```

**响应:**
```json
{
  "status": true,
  "data": [
    {
      "courseId": "课程ID",
      "title": "课程名称",
      "clazzId": "班级ID",
      "cpi": "课程信息"
    }
  ]
}
```

### POST /api/start
开始学习任务

**请求体:**
```json
{
  "username": "手机号",
  "password": "密码",
  "course_list": ["课程ID1", "课程ID2"],
  "speed": 1.5,
  "jobs": 4,
  "notopen_action": "retry",
  "tiku_config": {}
}
```

**响应:**
```json
{
  "status": true,
  "data": {
    "task_id": "任务ID"
  }
}
```

### GET /api/task/{task_id}
获取任务状态

**响应:**
```json
{
  "status": true,
  "data": {
    "status": "running",
    "progress": 1,
    "total": 5,
    "current_course": "当前课程名称",
    "start_time": 1234567890
  }
}
```

### GET /api/logs/{task_id}
获取任务日志

**响应:**
```json
{
  "status": true,
  "data": ["日志1", "日志2", "日志3"]
}
```

## 🎯 使用流程

1. **启动服务** - 运行后端和前端服务
2. **打开浏览器** - 访问 http://localhost:3000
3. **登录账号** - 输入超星学习通账号密码（可选使用Cookie登录）
4. **选择课程** - 在课程列表中选择要学习的课程
5. **配置参数** - 设置播放倍速、并发数等基础参数
6. **配置高级功能**（可选）：
   - 点击"显示高级配置"展开
   - 配置题库（用于章节检测自动答题）
   - 配置通知（任务完成后推送消息）
7. **开始学习** - 点击"开始学习"按钮
8. **查看进度** - 实时监控学习进度和日志
9. **完成任务** - 等待所有任务完成（如配置通知会收到推送）

## ⚠️ 注意事项

### 基础设置
1. **首次使用**需要安装Python和Node.js依赖
2. **网络环境**：建议在稳定的网络环境下使用
3. **账号安全**：密码仅用于登录验证，不会保存
4. **合理使用**：请遵守学校规定，合理使用本工具
5. **并发设置**：并发章节数建议设置为4-8，过高可能导致请求频繁
6. **播放倍速**：范围1.0-2.0，建议不超过1.5倍速

### Cookie登录
- 使用Cookie登录需要在项目根目录放置 `cookies.txt` 文件
- Cookie登录时密码字段会自动禁用

### 题库配置
- **章节检测必备**：如果课程有章节检测且需要解锁，必须配置题库
- **Token获取**：需要到对应题库平台注册获取
- **自动提交**：设置为true会在达到覆盖率后自动提交，false则仅保存
- **覆盖率**：建议设置0.9，即90%的题目能搜到答案
- **AI配置**：使用AI题库需要配置Endpoint、Key和Model

### 通知配置
- **可选功能**：不配置通知也不影响学习任务
- **URL格式**：需要完整的通知URL，包含你的key
- **Telegram**：需要额外配置Chat ID
- **推送时机**：任务完成或出错时会自动推送

## 🐛 常见问题

### Q: 无法启动后端服务？
A: 确保已安装所有Python依赖：`pip install -r requirements.txt`，并检查5000端口是否被占用。

### Q: 无法启动前端服务？
A: 确保已安装Node.js和npm，运行 `cd web && npm install` 安装依赖。

### Q: 登录失败？
A: 检查账号密码是否正确，确保网络连接正常。

### Q: 课程列表为空？
A: 确认账号下有可用课程，检查后端日志是否有错误信息。

### Q: 学习进度不更新？
A: 刷新页面或检查后端服务是否正常运行。

## 📝 开发说明

### 构建生产版本

```bash
cd web
npm run build
```

构建产物将输出到 `web/dist` 目录。

### 预览生产构建

```bash
cd web
npm run preview
```

### 代码风格

- React组件使用函数式组件
- 使用TailwindCSS编写样式
- API请求统一通过axios实例
- 遵循React Hooks最佳实践

## 📄 许可证

本项目遵循 GPL-3.0 License 协议。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**免责声明**：本代码仅用于学习讨论，禁止用于盈利。使用本代码产生的任何问题与开发者无关。

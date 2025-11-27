# 超星学习通自动化刷课工具（Web + CLI 全量可视化）

<p align="center">
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank">
    <img src="https://img.shields.io/github/stars/ymylive/chaoxing-fanya" alt="GitHub Stars" />
  </a>
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank">
    <img src="https://img.shields.io/github/forks/ymylive/chaoxing-fanya" alt="GitHub Forks" />
  </a>
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank">
    <img src="https://img.shields.io/github/license/ymylive/chaoxing-fanya" alt="License" />
  </a>
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank">
    <img src="https://img.shields.io/github/languages/code-size/ymylive/chaoxing-fanya" alt="Code Size" />
  </a>
</p>

> 基于 [Samueli924/chaoxing](https://github.com/Samueli924/chaoxing) 二次开发：补全 Web 可视化、OCR、题库、外部通知与便携打包能力，向原作者致敬。

## 功能亮点

- **可视化覆盖 100% 功能**：React + TailwindCSS 前端，桌面/移动自适应，实时日志与进度
- **一键上手**：Windows `start.bat` 检查依赖后即启动前后端；支持 Docker 与便携打包
- **题库全家桶**：Yanxi / LIKE / TikuAdapter / AI / SiliconFlow，可调覆盖率与自动提交
- **OCR 多方案**：内置 PaddleOCR 或外部大模型（OpenAI / Claude / Qwen / SiliconFlow 等）
- **通知渠道**：Server酱 / Qmsg / Bark / Telegram 等完成 & 错误推送
- **CLI 同步**：命令行模式与 Web 功能一致，便于集成与自动化

## 快速开始（推荐一键）

```bash
git clone --depth=1 https://github.com/ymylive/chaoxing-fanya
cd chaoxing-fanya
start.bat  # Windows 双击或命令行运行
```

启动后浏览器会自动打开 `http://localhost:3000`，按界面提示登录并开始学习。

### 其他运行方式

**手动启动（前后端分开）**
```bash
# 后端
pip install -r requirements.txt
python app.py        # 默认 http://localhost:5000

# 前端（新终端）
cd web
npm install
npm run dev          # 默认 http://localhost:3000
```

**Docker**
```bash
docker build -t chaoxing .

# 使用默认模板
docker run -it chaoxing

# 挂载自定义配置
docker run -it -v /本地路径/config.ini:/config/config.ini chaoxing
```
- 首次运行会将 `config_template.ini` 复制到 `/config/config.ini`，可自行覆盖挂载。

**便携打包**
```bash
clean_and_build_portable.bat
```
生成 `chaoxing_portable` 目录，免安装 Python 直接分发。

**命令行模式**
```bash
python main.py                               # 使用默认配置模板
python main.py -c config.ini                 # 指定配置
python main.py -u 手机号 -p 密码 -l 课程ID1,课程ID2 -a [retry|ask|continue]
```

## 配置要点（config.ini）

- **登录**：支持账号密码或 cookies.txt（同后端配置说明）
- **题库 `[tiku]`**：`provider=Yanxi|Like|TikuAdapter|AI|SiliconFlow`；`cover_rate=0.0-1.0`；`submit=true|false`
- **未开放任务处理 `[common]`**：`notopen_action=retry|ask|continue`（命令行可用 `-a/--notopen-action` 覆盖）
- **通知 `[notify]`**：`provider=ServerChan|Qmsg|Bark|Telegram`，按注释填写 `url` / `token` / `chat_id` 等
- **OCR**：
  - 本地 PaddleOCR：安装 `paddlepaddle`、`paddlex`，并设置 `CHAOXING_ENABLE_OCR=1`
  - 外部大模型（推荐）：
    ```bash
    export CHAOXING_VISION_OCR_PROVIDER=openai
    export CHAOXING_VISION_OCR_KEY=sk-your-api-key
    export CHAOXING_VISION_OCR_MODEL=gpt-4o
    # 可选：CHAOXING_VISION_OCR_ENDPOINT, CHAOXING_VISION_OCR_PROMPT
    ```

更多详细说明见 `WEB_FRONTEND_GUIDE.md`、`QUICKSTART.md`、`FEATURE_COMPARISON.md`、`WEB_FEATURES.md`。

## 使用流程

1) 登录：手机号+密码或上传 cookies  
2) 选课：多选或默认全部课程  
3) 配置：倍速、并发、题库、通知、OCR  
4) 开始：一键启动任务，实时查看进度/日志  
5) 监控：完成/异常自动推送（如启用通知）

## 目录速览

```
chaoxing/
├── app.py                      # Flask 后端入口
├── main.py                     # 命令行入口
├── start.bat                   # Windows 一键启动
├── clean_and_build_portable.bat
├── config_template.ini         # 配置模板
├── api/                        # 后端接口
├── web/                        # 前端（React + Vite + TailwindCSS）
└── resource/                   # 静态资源、模型等
```

## 常见问题

- 端口被占用：`netstat -ano | findstr :5000` / `:3000`，结束占用进程后重试
- 依赖安装失败：后端 `pip install -r requirements.txt --force-reinstall`；前端删除 `node_modules` 与锁文件后重新 `npm install`
- 浏览器未自动打开：手动访问 `http://localhost:3000`，查看启动脚本输出
- Docker 配置未生效：确认挂载路径正确，或在容器内检查 `/config/config.ini`

## 致谢

- 原项目：[Samueli924/chaoxing](https://github.com/Samueli924/chaoxing)
- 社区贡献者与所有用户

## 许可与声明

- 许可证：GPL-3.0，仅允许在相同许可证下开源免费使用与再分发，禁止闭源商业化及任何盈利行为
- 本项目仅供学习交流，使用者需自行承担法律与合规责任

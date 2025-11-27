# 超星学习通自动化刷课工具（精美 Web 界面版）

<p align="center">
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank" style="margin-right: 20px; font-style: normal; text-decoration: none;">
    <img src="https://img.shields.io/github/stars/ymylive/chaoxing-fanya" alt="Github Stars" />
  </a>
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank" style="margin-right: 20px; font-style: normal; text-decoration: none;">
    <img src="https://img.shields.io/github/forks/ymylive/chaoxing-fanya" alt="Github Forks" />
  </a>
  <a href="https://github.com/ymylive/chaoxing-fanya" target="_blank" style="margin-right: 20px; font-style: normal; text-decoration: none;">
    <img src="https://img.shields.io/github/languages/code-size/ymylive/chaoxing-fanya" alt="Code-size" />
  </a>
</p>

> 基于 [Samueli924/chaoxing](https://github.com/Samueli924/chaoxing) 二次开发，增加完整 Web 界面与便携打包能力，向原作者致敬。

## 主要亮点

- 现代化 React + TailwindCSS Web 界面，100% 覆盖命令行全部功能
- 一键启动脚本（Windows）与 Docker 支持，开箱即用
- 集成本地 PaddleOCR 与外部视觉大模型，图片/验证码均可识别
- 题库（言溪、LIKE、TikuAdapter、AI、硅基流动）与通知（Server 酱、Qmsg、Bark、Telegram）全量支持
- 便携版打包脚本，免 Python 环境即可分发

## 快速开始（推荐）

```bash
git clone --depth=1 https://github.com/ymylive/chaoxing-fanya
cd chaoxing-fanya
start.bat  # Windows 双击或命令行运行，一键检查依赖并启动前后端
```

启动后浏览器自动打开 http://localhost:3000，按界面提示登录并开始学习。

## 运行方式

### 1) Windows 一键启动（推荐）
- 双击或运行 `start.bat`，自动检查/安装 Python 与前端依赖，依次启动后端 (5000) 与前端 (3000)，并自动打开浏览器。

### 2) 手动启动（前后端分开）
```bash
# 克隆仓库
git clone --depth=1 https://github.com/ymylive/chaoxing-fanya
cd chaoxing-fanya

# 后端
pip install -r requirements.txt
python app.py            # 默认 http://localhost:5000

# 前端（新终端窗口）
cd web
npm install
npm run dev              # 默认 http://localhost:3000
```

### 3) Docker
```bash
docker build -t chaoxing .

# 使用默认模板
docker run -it chaoxing

# 指定自定义配置文件
docker run -it -v /本地路径/config.ini:/config/config.ini chaoxing
```
- 首次运行自动将 `config_template.ini` 复制到 `/config/config.ini`；可挂载自定义配置。

### 4) 便携版打包
```bash
clean_and_build_portable.bat
```
生成的 `chaoxing_portable` 可直接分发，无需安装 Python。

### 5) 命令行模式
```bash
python main.py                               # 使用默认配置模板
python main.py -c config.ini                 # 指定配置文件
python main.py -u 手机号 -p 密码 -l 课程ID1,课程ID2 -a [retry|ask|continue]
```

## 配置要点

### 题库 `[tiku]`
- provider：`Yanxi` / `Like` / `TikuAdapter` / `AI` / `SiliconFlow`（大小写保持与实现类一致）
- 题库覆盖率：0.0-1.0；提交模式 `submit=true|false`
- 不配置题库则跳过需答题的章节检测；有章节解锁需求的课程必须配置题库。

### 已关闭任务点处理 `[common]`
- `notopen_action=retry|ask|continue`
- 命令行可用 `-a` 或 `--notopen-action` 覆盖。

### 外部通知 `[notify]`
- provider：`ServerChan` / `Qmsg` / `Bark` / `Telegram` 等，按注释填入 `url` 等参数。

### 图片 OCR
1) 本地 PaddleOCR：安装 `paddlepaddle`、`paddlex`，并设置 `CHAOXING_ENABLE_OCR=1`。
2) 外部视觉大模型（推荐）：环境变量示例：
   ```bash
   export CHAOXING_VISION_OCR_PROVIDER=openai
   export CHAOXING_VISION_OCR_KEY=sk-your-api-key
   export CHAOXING_VISION_OCR_MODEL=gpt-4o
   # 可选：CHAOXING_VISION_OCR_ENDPOINT, CHAOXING_VISION_OCR_PROMPT
   ```
   内置支持 `openai` / `claude` / `qwen` / `siliconflow` / `openai_compatible`。

## 目录速览

```
chaoxing/
├── app.py                # Flask 后端（Web 入口）
├── main.py               # 命令行入口
├── start.bat             # 一键启动脚本
├── clean_and_build_portable.bat
├── config_template.ini   # 配置模板
├── api/                  # 后端接口
├── web/                  # 前端（React + Vite + TailwindCSS）
└── resource/             # 静态资源、模型等
```

更多细节请参见：`WEB_FRONTEND_GUIDE.md`、`QUICKSTART.md`、`FEATURE_COMPARISON.md`、`WEB_FEATURES.md`、`DEPENDENCIES.md`。

## 常见问题

- 端口被占用：`netstat -ano | findstr :5000` / `findstr :3000`，结束占用进程后重试。
- 依赖安装失败：后端 `pip install -r requirements.txt --force-reinstall`；前端删除 `node_modules` 与 `package-lock.json` 后 `npm install`。
- 浏览器未自动打开：手动访问 http://localhost:3000 或检查启动脚本输出。

## 致谢

- 原项目作者 [Samueli924/chaoxing](https://github.com/Samueli924/chaoxing)
- 社区贡献者与所有使用者

## 许可证与声明

- 许可证：GPL-3.0，仅允许在相同许可证下开源/免费使用与再分发；禁止闭源商业化与任何盈利行为。
- 本项目仅供学习交流，使用者须自行承担法律与合规责任。

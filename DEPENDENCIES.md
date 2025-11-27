# 📦 依赖清单

## 系统要求

### 必需软件
- **Python** 3.8 或更高版本
- **Node.js** 16.0 或更高版本
- **npm** 或 **yarn** 包管理器

### 操作系统
- ✅ Windows 10/11
- ✅ macOS 10.15+
- ✅ Linux (Ubuntu 18.04+)

---

## Python 后端依赖

### 核心依赖（必需）

| 包名 | 版本要求 | 用途 | 安装状态 |
|------|---------|------|---------|
| `flask` | >=3.1.2 | Web框架 | ✅ 已在requirements.txt |
| `flask-cors` | >=5.0.0 | CORS跨域支持 | ✅ 已在requirements.txt |
| `requests` | >=2.32.3 | HTTP请求 | ✅ 已在requirements.txt |
| `beautifulsoup4` | >=4.12.3 | HTML解析 | ✅ 已在requirements.txt |
| `lxml` | >=5.3.0 | XML解析 | ✅ 已在requirements.txt |
| `loguru` | >=0.7.3 | 日志系统 | ✅ 已在requirements.txt |
| `pycryptodome` | >=3.21.0 | 加密支持 | ✅ 已在requirements.txt |

### 可选依赖

| 包名 | 版本要求 | 用途 | 安装状态 |
|------|---------|------|---------|
| `celery` | >=5.5.3 | 异步任务队列 | ✅ 已在requirements.txt |
| `fonttools` | >=4.60.1 | 字体处理 | ✅ 已在requirements.txt |

### 安装后端依赖

```bash
# 完整安装
pip install -r requirements.txt

# 仅安装核心依赖
pip install flask>=3.1.2 flask-cors>=5.0.0 requests>=2.32.3 beautifulsoup4>=4.12.3 lxml>=5.3.0 loguru>=0.7.3 pycryptodome>=3.21.0
```

---

## Node.js 前端依赖

### 核心依赖（必需）

| 包名 | 版本 | 用途 | 安装位置 |
|------|------|------|---------|
| `react` | 18.3.1 | UI框架 | web/package.json |
| `react-dom` | 18.3.1 | React DOM | web/package.json |
| `axios` | 1.7.2 | HTTP客户端 | web/package.json |
| `lucide-react` | 0.263.1 | 图标库 | web/package.json |

### 样式依赖（必需）

| 包名 | 版本 | 用途 | 安装位置 |
|------|------|------|---------|
| `tailwindcss` | 3.4.4 | CSS框架 | web/package.json |
| `clsx` | 2.1.1 | 类名工具 | web/package.json |
| `tailwind-merge` | 2.3.0 | 类名合并 | web/package.json |
| `autoprefixer` | 10.4.19 | CSS前缀 | web/package.json |
| `postcss` | 8.4.38 | CSS处理 | web/package.json |

### 构建工具（必需）

| 包名 | 版本 | 用途 | 安装位置 |
|------|------|------|---------|
| `vite` | 5.3.1 | 构建工具 | web/package.json |
| `@vitejs/plugin-react` | 4.3.1 | Vite React插件 | web/package.json |

### 开发依赖

| 包名 | 版本 | 用途 | 安装位置 |
|------|------|------|---------|
| `@types/react` | 18.3.3 | React类型定义 | web/package.json |
| `@types/react-dom` | 18.3.0 | React DOM类型 | web/package.json |
| `eslint` | 8.57.0 | 代码检查 | web/package.json |
| `eslint-plugin-react` | 7.34.2 | React规则 | web/package.json |

### 安装前端依赖

```bash
# 进入前端目录
cd web

# 使用npm安装
npm install

# 或使用yarn安装
yarn install
```

---

## 依赖总览

### 统计信息
- **Python包总数**: 7个核心包 + 2个可选包
- **Node.js包总数**: 约201个包（包含所有依赖和子依赖）
- **总安装大小**: 
  - Python: ~50MB
  - Node.js: ~200MB

### 安装时间估算
- **Python依赖**: ~30秒 - 2分钟
- **Node.js依赖**: ~30秒 - 3分钟（根据网络速度）

---

## 自动依赖管理

### start.bat 自动检查

启动脚本会自动检查以下依赖：

```batch
1. 检查 flask-cors (Python后端)
   - 如果缺失：自动运行 pip install flask-cors
   
2. 检查 node_modules (Node.js前端)
   - 如果缺失：自动运行 npm install
```

### 检查逻辑

```batch
# Python依赖检查
python -c "import flask_cors" 2>nul
if errorlevel 1 (
    echo 安装 flask-cors...
    pip install flask-cors
)

# Node.js依赖检查
if not exist "web\node_modules" (
    echo 安装前端依赖...
    cd web && npm install
)
```

---

## 手动依赖检查

### 检查Python环境

```bash
# 检查Python版本
python --version

# 检查pip版本
pip --version

# 检查已安装的包
pip list

# 检查特定包
pip show flask-cors
```

### 检查Node.js环境

```bash
# 检查Node.js版本
node --version

# 检查npm版本
npm --version

# 检查已安装的包
npm list --depth=0

# 检查特定包
npm list react
```

---

## 依赖更新

### 更新Python依赖

```bash
# 更新所有包
pip install -r requirements.txt --upgrade

# 更新特定包
pip install flask-cors --upgrade
```

### 更新Node.js依赖

```bash
cd web

# 更新所有包
npm update

# 更新特定包
npm update react

# 检查过期的包
npm outdated
```

---

## 常见依赖问题

### 问题1: flask-cors 安装失败

**解决方案**:
```bash
# 使用国内镜像
pip install flask-cors -i https://pypi.tuna.tsinghua.edu.cn/simple

# 或使用阿里云镜像
pip install flask-cors -i https://mirrors.aliyun.com/pypi/simple/
```

### 问题2: npm install 速度慢

**解决方案**:
```bash
# 使用淘宝镜像
npm install --registry=https://registry.npmmirror.com

# 或配置npm镜像
npm config set registry https://registry.npmmirror.com
npm install
```

### 问题3: Python版本不兼容

**解决方案**:
```bash
# 使用虚拟环境
python -m venv venv

# Windows激活
venv\Scripts\activate

# Linux/Mac激活
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 问题4: Node.js版本过低

**解决方案**:
- 下载并安装最新的 Node.js LTS 版本
- 官网: https://nodejs.org/
- 推荐版本: 18.x 或 20.x

---

## 依赖验证清单

### ✅ 后端依赖验证

运行以下命令验证所有后端依赖:

```bash
python -c "
import flask
import flask_cors
import requests
import bs4
import lxml
import loguru
import Crypto
print('✅ 所有后端依赖已安装')
"
```

### ✅ 前端依赖验证

运行以下命令验证前端依赖:

```bash
cd web
npm list react react-dom axios lucide-react tailwindcss vite
```

---

## 生产环境依赖

### 最小化依赖

如果只运行Web前端，需要以下依赖:

**Python (后端)**:
```txt
flask>=3.1.2
flask-cors>=5.0.0
requests>=2.32.3
beautifulsoup4>=4.12.3
lxml>=5.3.0
loguru>=0.7.3
pycryptodome>=3.21.0
```

**Node.js (前端)**:
```bash
# 开发环境
npm install

# 生产构建
npm run build
# 生成的 dist/ 目录可部署到任何静态服务器
```

---

## 依赖许可证

所有使用的依赖包都是开源软件，遵循以下许可证:

- **Flask**: BSD-3-Clause
- **React**: MIT
- **TailwindCSS**: MIT
- **Axios**: MIT
- **其他**: 大多为 MIT 或 BSD 许可证

---

## 总结

### ✅ 依赖管理最佳实践

1. **使用 start.bat**: 自动检查和安装依赖
2. **虚拟环境**: Python使用venv隔离依赖
3. **镜像加速**: 配置国内镜像加快下载
4. **定期更新**: 保持依赖包为最新稳定版
5. **最小化安装**: 生产环境只安装必需依赖

### 📞 获取帮助

- 依赖问题: 查看本文档的常见问题部分
- 技术支持: 提交 GitHub Issue
- 文档查看: [WEB_FRONTEND_GUIDE.md](WEB_FRONTEND_GUIDE.md)

---

**更新时间**: 2024-11-25  
**维护状态**: ✅ 活跃维护

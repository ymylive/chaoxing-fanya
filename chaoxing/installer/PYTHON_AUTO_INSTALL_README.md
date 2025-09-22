# Python 自动安装功能说明

## 🚀 功能概述

本安装包现在包含 **Python 自动安装功能**，当系统检测不到有效的 Python 安装时，会自动提供 Python 安装选项。

## 🔧 工作原理

### 1. Python 检测流程
安装包会按以下顺序检测 Python：
1. 检查虚拟环境 `.venv\Scripts\python.exe`
2. 测试 `py` launcher (推荐)
3. 测试 `python` 命令 (跳过 Microsoft Store 占位符)
4. 测试 `python3` 命令 (跳过 Microsoft Store 占位符)

### 2. 自动安装触发
当所有检测都失败时，系统会：
- 显示 "PYTHON NOT FOUND" 错误
- 提供自动安装选项
- 询问用户是否要自动下载和安装 Python

### 3. 自动安装过程
如果用户选择自动安装 (Y)，系统会：
1. **下载 Python 3.11.9**：从官方源下载最新稳定版
2. **验证文件**：检查下载文件的完整性
3. **自动安装**：使用静默安装模式，自动配置 PATH
4. **验证安装**：检测 Python 是否正确安装并可用
5. **重试检测**：重新执行 Python 检测流程

## 📋 支持的场景

### ✅ 完全支持
- **无 Python 系统**：全新系统无任何 Python 安装
- **Microsoft Store 占位符**：系统有 MS Store 的假 python.exe
- **损坏的 Python**：已安装但无法正常工作的 Python
- **PATH 未配置**：Python 已安装但未添加到 PATH

### ⚠️ 需要手动处理
- **权限限制**：企业环境或受限系统
- **网络限制**：无法访问互联网下载
- **防火墙阻止**：安全软件阻止下载或安装

## 🛠️ 安装详情

### 自动安装的 Python 配置
- **版本**：Python 3.11.9 (64位)
- **安装选项**：
  - ✅ Add Python to PATH
  - ✅ Install launcher for all users  
  - ✅ Include pip
  - ✅ Include standard library
  - ❌ Include test modules (节省空间)

### 安装位置
- **默认位置**：`C:\Users\[用户名]\AppData\Local\Programs\Python\Python311\`
- **PATH 添加**：自动添加到系统 PATH 环境变量
- **启动器**：安装 `py` 启动器，推荐使用

## 📝 用户操作指南

### 首次安装时
1. 运行 `Chaoxing-Setup.exe`
2. 如果提示 "PYTHON NOT FOUND"
3. 选择 `Y` 进行自动安装
4. 等待下载和安装完成
5. 系统会自动重试检测并继续安装

### 如果自动安装失败
1. 手动访问：https://www.python.org/downloads/
2. 下载 Python 3.10+ 版本
3. 安装时务必勾选 "Add Python to PATH"
4. 如有 Microsoft Store Python，请禁用：
   - 设置 > 应用 > 高级应用设置 > 应用执行别名
   - 关闭 "python.exe" 和 "python3.exe"
5. 重新运行安装包

## 🔍 故障排除

### 常见问题

#### 1. 下载失败
**错误**：`Download failed`
**解决**：
- 检查网络连接
- 关闭防火墙/杀毒软件
- 手动下载并安装 Python

#### 2. 安装后仍检测不到
**错误**：`Python still not detected after auto-install`
**解决**：
- 重启命令提示符
- 重启计算机
- 手动检查 PATH 环境变量

#### 3. Microsoft Store 占位符问题
**错误**：`Microsoft Store Python placeholder detected`
**解决**：
- 设置 > 应用 > 高级应用设置 > 应用执行别名
- 关闭 "python.exe" 和 "python3.exe"
- 重新运行安装

## 📊 日志文件

### 安装日志位置
- **主安装日志**：`[安装目录]\chaoxing_post_install.log`
- **Python 安装日志**：`[安装目录]\python_auto_install.log`
- **启动日志**：`[安装目录]\chaoxing_install.log`

### 日志内容
包含详细的：
- Python 检测过程
- 下载进度和结果
- 安装过程和错误
- 环境变量配置
- 验证结果

## 🎯 最佳实践

### 推荐流程
1. **优先自动安装**：首次安装时选择自动安装
2. **检查日志**：如有问题查看日志文件
3. **重启系统**：安装后重启确保 PATH 生效
4. **验证安装**：命令行运行 `py --version` 验证

### 企业环境
- 可能需要管理员权限
- 可能需要预安装 Python
- 建议手动配置 Python 环境

## 🔄 更新说明

### v3.1.3 新功能
- ✅ 集成 Python 自动安装器
- ✅ Microsoft Store 占位符检测
- ✅ 智能 PATH 刷新
- ✅ 安装后自动重试检测
- ✅ 详细的用户指导界面

### 兼容性
- **Windows 10/11**：完全支持
- **Windows 7/8**：基本支持（可能需要手动安装）
- **Python 版本**：自动安装 3.11.9，兼容 3.8+

---

**技术支持**：如遇问题请查看日志文件，或提交 Issue 到项目仓库。

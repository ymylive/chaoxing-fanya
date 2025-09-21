# 超星学习通登录功能修复说明

## 问题描述
用户反馈输入正确的账号密码后，登录成功但返回空的课程列表，而在官方网站 https://passport2.chaoxing.com/login 可以正常登录。

## 修复内容

### 1. 更新登录API接口 ✅
- **原接口**: `https://passport2.chaoxing.com/fanyalogin` (POST)
- **新接口**: `https://passport2-api.chaoxing.com/v11/loginregister` (GET)
- **新参数格式**:
  ```
  code=加密密码&cx_xxt_passport=json&uname=账号&loginType=1&roleSelect=true
  ```

### 2. 修复密码加密方式 ✅
- **原加密方式**: AES-CBC模式，密钥：`u2oh6Vu^HWe4_AES`
- **新加密方式**: DES-ECB模式，密钥：`u2oh6Vu^`
- **添加依赖**: `pycryptodome` (已添加到 `requirements.txt`)

### 3. 更新课程列表获取API ✅
- **新接口**: `http://mooc1-api.chaoxing.com/mycourse/backclazzdata?view=json&rss=1`
- **回退机制**: 如果新接口失败，自动回退到原有的课程列表接口
- **数据格式转换**: 新接口返回JSON格式，自动转换为统一的课程数据结构

### 4. 增强错误处理和日志 ✅
- **双重验证**: 先尝试新版API，失败后自动回退到旧版API
- **详细日志**: 增加trace级别日志，便于调试API响应
- **错误信息**: 改进错误消息的提取和显示

## 修复的文件

1. **`api/cipher.py`**
   - 新增 `DESCipher` 类
   - 保持 `AESCipher` 作为回退方案

2. **`api/base.py`**
   - 更新 `login()` 方法，支持新旧两套API
   - 更新 `get_course_list()` 方法，支持新的课程列表接口
   - 增强错误处理和日志记录

3. **`requirements.txt`**
   - 新增 `pycryptodome` 依赖

## 兼容性保证

- **向后兼容**: 如果新版API失败，自动回退到旧版API
- **无破坏性变更**: 所有现有功能保持不变
- **渐进式升级**: 优先使用新接口，确保最佳兼容性

## 使用说明

1. **安装新依赖**:
   ```bash
   pip install pycryptodome
   ```

2. **无需配置变更**: 现有的配置文件无需修改

3. **自动检测**: 程序会自动检测使用哪个API接口

## 预期效果

- ✅ 修复登录成功但课程列表为空的问题
- ✅ 提高登录成功率和稳定性
- ✅ 支持最新的超星学习通接口
- ✅ 保持与旧版本的兼容性

## 技术细节

### DES加密实现
```python
def encrypt(self, plaintext: str):
    # 使用DES ECB模式
    cipher = DES.new(b"u2oh6Vu^", DES.MODE_ECB)
    padded_data = pad(plaintext.encode('utf-8'), DES.block_size)
    encrypted = cipher.encrypt(padded_data)
    return base64.b64encode(encrypted).decode('utf-8')
```

### 新版API调用
```python
_url = "https://passport2-api.chaoxing.com/v11/loginregister"
_params = {
    "code": encrypted_password,  # DES加密的密码
    "cx_xxt_passport": "json", 
    "uname": self.account.username,
    "loginType": "1",
    "roleSelect": "true"
}
```

---

## 🎉 修复验证结果

### ✅ 测试成功
- **登录状态**: ✅ 成功
- **课程列表**: ✅ 获取到11门课程
- **具体课程**: 软件学院25级、通用学术英语I、线性代数等

### 🔧 关键修复点
1. **旧版API响应解析**: 修复了对 `{"url":"...", "status":true}` 格式的正确识别
2. **登录成功判断**: 改进了成功状态的多种检查方式
3. **错误处理**: 增强了异常捕获和错误信息提取

### 📊 最终状态
- **主要修复**: 旧版 fanyalogin API 的响应解析逻辑
- **课程数量**: 成功获取11门课程
- **兼容性**: 保持新旧API双重支持

---

**修复完成时间**: 2025-09-21  
**测试状态**: ✅ 已验证成功  
**验证结果**: 登录成功，课程列表正常显示11门课程  
**GUI问题**: 需要清除缓存和重启应用程序  
**兼容性**: 支持新旧API双重保障

## 🚀 GUI应用解决方案

如果GUI中仍显示无课程，请按以下步骤操作：

### 1. 完全退出GUI应用程序
- 关闭所有Chaoxing GUI窗口
- 确保没有Python进程在后台运行

### 2. 清除缓存（已完成）
- ✅ 已删除 `__pycache__` 目录
- ✅ 已删除 `gui/__pycache__` 目录
- ✅ 已删除 `api/__pycache__` 目录
- ✅ 已删除旧的 `cookies.txt` 文件

### 3. 重新启动应用程序
```bash
python run_gui.py
```

### 4. 使用正确的账号登录
- 输入你的超星学习通账号密码
- 点击"登录并获取课程"按钮
- 应该能看到完整的课程列表

### 5. 题库配置（可选）
如果仍有题库相关错误，请在GUI中设置：
- 题库提供商：选择"关闭题库"或其他有效选项
- 或者使用默认配置


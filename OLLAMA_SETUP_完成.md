# ✅ Ollama 本地大模型搭建完成

## 已完成的工作

### 1. Ollama 安装 ✅
- **版本**: Ollama 0.13.5
- **安装方式**: 使用 Homebrew (macOS)
- **服务状态**: 已启动并运行

```bash
# 验证安装
ollama --version
# 输出: ollama version is 0.13.5
```

### 2. 模型下载 ✅
- **模型名称**: llama3.2:3b
- **模型大小**: 2.0 GB
- **参数量**: 3B (30亿参数)
- **适用场景**: 轻量级本地运行，适合对话和推理任务

```bash
# 查看已安装模型
ollama list
# 输出:
# NAME           ID              SIZE      MODIFIED       
# llama3.2:3b    a80c4f17acd5    2.0 GB    刚刚下载
```

### 3. 模型测试 ✅
测试查询：`你好，请用一句话介绍你自己`

模型回复：`我是一位人工智能语言模型，能帮助回答问题、提供信息和解决问题。`

✅ **测试通过！模型运行正常**

### 4. Microverse 配置更新 ✅
已将默认模型从 `qwen2.5:1.5b` 更新为 `llama3.2:3b`

修改文件：`script/ui/SettingsManager.gd`

```gdscript
var current_settings = {
    "api_type": "Ollama",
    "model": "llama3.2:3b",  // 已更新
    "api_key": "",
    "show_ai_model_label": true,
}
```

## 使用方法

### 在游戏中使用

1. **启动 Microverse 游戏**
   ```bash
   # 在 Godot 中打开项目
   open -a Godot /Users/yiqix/Documents/Microverse/project.godot
   ```

2. **配置确认**
   - 按 `ESC` 打开设置
   - 检查 AI 配置：
     - API 类型: `Ollama`
     - 模型: `llama3.2:3b`
   - 如果显示其他模型，请在下拉菜单中选择 `llama3.2:3b`

3. **开始使用**
   - 选择一个角色与之对话
   - AI 将使用本地的 llama3.2:3b 模型响应

### 命令行测试

```bash
# 直接在终端测试模型
ollama run llama3.2:3b "你好"

# 查看运行中的模型
ollama ps

# 停止模型（释放内存）
ollama stop llama3.2:3b
```

## 性能预期

根据 llama3.2:3b 的特性：

| 指标 | 预期值 |
|------|--------|
| **响应时间** | 2-5 秒 |
| **内存占用** | ~2-3 GB |
| **质量** | 适合日常对话 |
| **速度** | 快速 |

## Ollama 服务管理

### 启动服务
```bash
brew services start ollama
```

### 停止服务
```bash
brew services stop ollama
```

### 查看服务状态
```bash
brew services list | grep ollama
```

### 重启服务
```bash
brew services restart ollama
```

## 其他可用模型

如果需要下载其他模型，可以使用：

```bash
# 更小的模型（1B 参数，速度更快）
ollama pull llama3.2:1b

# Qwen 模型（中文更好）
ollama pull qwen2.5:1.5b
ollama pull qwen2.5:3b

# Gemma 模型（Google 出品）
ollama pull gemma2:2b

# 更大的模型（质量更好，但更慢）
ollama pull llama3.2:8b
ollama pull qwen2.5:7b
```

## API 端点信息

**Ollama API 地址**: `http://localhost:11434/api/generate`

可以用于：
- Microverse 游戏
- 自定义脚本调用
- 第三方应用集成

## 故障排查

### 问题1：模型响应很慢
```bash
# 检查是否有其他模型在运行
ollama ps

# 停止不需要的模型
ollama stop <model-name>
```

### 问题2：服务未运行
```bash
# 重启 Ollama 服务
brew services restart ollama

# 等待几秒后测试
ollama list
```

### 问题3：游戏中显示错误的模型名
- 删除游戏配置文件重新生成：
```bash
# macOS 用户配置位置
rm ~/Library/Application\ Support/Godot/app_userdata/Microverse/settings.cfg

# 重新启动游戏，将使用新的默认配置
```

## 下一步

✅ **环境已完全配置好，可以开始使用！**

建议操作：
1. 启动 Microverse 游戏
2. 测试 AI 对话功能
3. 观察模型响应质量和速度
4. 根据需要调整模型选择

## 技术支持

如遇到问题，可以：
1. 查看 Ollama 日志：`ollama logs`
2. 参考项目文档：`experiment_tools/README.md`
3. 测试脚本：`experiment_tools/quick_test.sh`

---

**配置完成时间**: 2026年1月4日  
**系统**: macOS (darwin 25.1.0)  
**Ollama 版本**: 0.13.5  
**默认模型**: llama3.2:3b (2.0 GB)  
**状态**: ✅ 运行正常


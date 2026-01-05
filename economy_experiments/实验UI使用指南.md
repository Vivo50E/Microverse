# 🎮 实验UI使用指南

## 🚀 5分钟快速上手

### 第一步：添加实验按钮

最简单的方式 - 只需3行代码！

```gdscript
# 在你的主场景脚本中添加
func _ready():
    var exp_btn = Button.new()
    exp_btn.text = "🧪 实验"
    exp_btn.set_script(load("res://script/ui/ExperimentMenuButton.gd"))
    add_child(exp_btn)
```

### 第二步：运行游戏

按 `F5` 运行游戏，你会看到一个"🧪 实验"按钮。

### 第三步：开始实验

1. 点击实验按钮
2. 快速面板会出现在右侧
3. 选择一个实验（如"快速测试 5分钟"）
4. 点击"开始"
5. 观察实验运行

**完成！** 就这么简单。

---

## 📱 三种UI面板对比

### 快速选择指南

| 你的需求 | 推荐面板 | 理由 |
|---------|---------|------|
| 快速测试 | 快速面板 | 轻量级，不影响游戏 |
| 深度研究 | 完整仪表板 | 功能全面，数据详细 |
| 实时监控 | 监控面板 | 可视化强，便于观察 |
| 游戏内嵌入 | 快速面板 | UI小巧，体验友好 |

### 详细对比

#### 🎯 快速面板（ExperimentQuickPanel）

**优点**：
- ✅ 界面简洁，上手快
- ✅ 不占用太多屏幕空间
- ✅ 适合游戏内使用
- ✅ 预设实验一键启动

**缺点**：
- ❌ 功能相对简单
- ❌ 无法自定义代理
- ❌ 结果显示有限

**适用场景**：
- 玩家体验实验功能
- 快速测试
- 游戏过程中运行后台实验

**使用示例**：
```gdscript
var panel = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn").instantiate()
panel.position = Vector2(900, 50)
add_child(panel)
```

---

#### 📊 完整仪表板（ExperimentDashboardUI）

**优点**：
- ✅ 功能完整，控制全面
- ✅ 可选择任意实验配置
- ✅ 支持多代理选择
- ✅ 详细的结果展示
- ✅ 实时指标可视化

**缺点**：
- ❌ 界面较大，占用空间多
- ❌ 功能多，学习曲线稍陡

**适用场景**：
- 研究人员使用
- 需要完整控制的实验
- 数据分析和导出

**使用示例**：
```gdscript
get_tree().change_scene_to_file("res://economy_experiments/scene/ExperimentDashboardUI.tscn")
```

---

#### 👁️ 监控面板（ExperimentMonitorPanel）

**优点**：
- ✅ 实时数据更新
- ✅ 代理状态可视化
- ✅ 游戏日志滚动显示
- ✅ 适合观察实验过程

**缺点**：
- ❌ 不能控制实验
- ❌ 需要配合其他面板使用

**适用场景**：
- 观察实验进展
- 调试实验逻辑
- 演示和展示

**使用示例**：
```gdscript
var monitor = load("res://economy_experiments/scene/ExperimentMonitorPanel.tscn").instantiate()
add_child(monitor)
monitor.connect_to_experiment(experiment_manager)
```

---

## 🎨 界面操作详解

### 完整仪表板操作

#### 左侧：实验配置列表

```
┌─────────────────────┐
│ Phase 1: 行为游戏    │ ← 点击选择
│ Phase 2: 市场动态    │
│ Phase 3: 模型对比    │
└─────────────────────┘
```

**操作**：
1. 单击选择一个实验
2. 下方会显示实验详情
3. 可以看到实验时长、代理数等信息

#### 右侧：代理选择

```
┌─────────────────────┐
│ □ Alice             │ ← Ctrl+点击多选
│ ☑ Jack              │
│ ☑ Grace             │
│ □ Joe               │
└─────────────────────┘
```

**操作**：
1. 点击复选框选择代理
2. 支持多选（Ctrl+点击）
3. 至少选择实验所需的最小代理数

#### 中间：控制区域

```
状态: 运行中 | 代理: 4 | 游戏: 2/5
[====================] 65%
运行时间: 12:34

[开始] [暂停] [停止]
```

**按钮说明**：
- **开始**：启动选中的实验
- **暂停**：暂停/恢复实验运行
- **停止**：强制停止实验

**状态指示**：
- 进度条显示实验完成度
- 时间显示实际运行时间
- 实时更新代理和游戏信息

#### 底部：结果显示

左侧文本区域显示详细结果：
- 实验基本信息
- 统计数据
- 不平等指标
- 行为指标

右侧显示关键指标：
- 基尼系数
- 平均财富
- 合作度
- 信任度

---

### 快速面板操作

```
┌──────────────────────┐
│   🧪 经济实验         │
├──────────────────────┤
│ [快速测试 (5分钟) ▼] │ ← 下拉选择
├──────────────────────┤
│ 运行中 | 游戏: 2/5   │ ← 状态显示
├──────────────────────┤
│ [开始] [暂停] [结果] │ ← 控制按钮
└──────────────────────┘
```

**操作流程**：
1. **选择实验**：点击下拉菜单，选择预设实验
2. **开始实验**：点击"开始"按钮
3. **监控进度**：观察状态显示
4. **控制运行**：
   - 点击"暂停"可暂停/恢复
   - 点击"结果"查看详细结果（打开完整仪表板）

---

## 💡 使用技巧

### 技巧1：快捷键加速操作

为实验面板添加快捷键：

```gdscript
func _input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F9:  # 打开/关闭实验面板
                toggle_experiment_panel()
            KEY_F10:  # 快速开始实验
                start_default_experiment()
            KEY_ESCAPE:  # 关闭所有面板
                close_all_panels()
```

### 技巧2：保存常用配置

创建自定义实验配置：

```json
{
  "name": "我的快速测试",
  "duration_minutes": 5,
  "agents": [
    {"name": "Alice", "profile": "risk_averse", "initial_cash": 200},
    {"name": "Jack", "profile": "risk_seeking", "initial_cash": 200}
  ],
  "games": [
    {
      "type": "ultimatum",
      "rounds": 3,
      "schedule": "start"
    }
  ]
}
```

保存到 `configs/experiments/my_test.json`，然后在UI中选择。

### 技巧3：多窗口监控

同时打开多个面板进行监控：

```gdscript
func setup_multi_monitor():
    # 左侧：控制面板
    var quick_panel = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn").instantiate()
    quick_panel.position = Vector2(20, 20)
    add_child(quick_panel)
    
    # 右侧：监控面板
    var monitor = load("res://economy_experiments/scene/ExperimentMonitorPanel.tscn").instantiate()
    monitor.position = Vector2(500, 20)
    add_child(monitor)
    
    # 连接到同一个实验管理器
    monitor.connect_to_experiment(quick_panel.experiment_manager)
```

### 技巧4：自动保存状态

实验完成后自动保存：

```gdscript
func _ready():
    experiment_manager.experiment_finished.connect(func(results):
        # 自动保存到自定义位置
        var save_path = "user://my_experiments/%s.json" % Time.get_datetime_string_from_system()
        var file = FileAccess.open(save_path, FileAccess.WRITE)
        file.store_string(JSON.stringify(results, "\t"))
        file.close()
        
        print("实验结果已保存: ", save_path)
    )
```

---

## 🔧 常见问题排查

### 问题1：点击开始没反应

**可能原因**：
- Ollama未运行
- 实验配置文件不存在
- 代理数量不足

**解决步骤**：
1. 打开终端，运行 `ollama list` 确认Ollama运行
2. 检查控制台错误信息
3. 确认至少选择了所需数量的代理

### 问题2：UI卡顿

**可能原因**：
- 更新频率太高
- 代理数量过多
- 实验太复杂

**解决方案**：
```gdscript
# 降低更新频率
var update_interval: float = 2.0  # 从1秒改为2秒

# 或者暂停实时更新
set_process(false)  # 停止_process更新
```

### 问题3：面板显示不全

**解决方案**：
```gdscript
# 调整面板大小
$ExperimentPanel.custom_minimum_size = Vector2(800, 600)

# 或使用全屏模式
$ExperimentPanel.anchors_preset = Control.PRESET_FULL_RECT
```

### 问题4：结果数据丢失

**解决方案**：
```gdscript
# 确保实验管理器在场景树中
if not experiment_manager.is_inside_tree():
    add_child(experiment_manager)

# 等待实验完全结束
await experiment_manager.experiment_finished
# 再进行操作
```

---

## 📊 实验流程示意图

```
┌─────────────┐
│  打开UI     │
└──────┬──────┘
       ↓
┌─────────────┐
│  选择实验   │ ← 浏览配置列表
└──────┬──────┘
       ↓
┌─────────────┐
│  选择代理   │ ← 多选参与者（可选）
└──────┬──────┘
       ↓
┌─────────────┐
│  点击开始   │
└──────┬──────┘
       ↓
┌─────────────┐
│  实验运行   │ ← 可暂停/恢复
│  实时更新   │
└──────┬──────┘
       ↓
┌─────────────┐
│  查看结果   │ ← 自动显示
│  导出数据   │
└─────────────┘
```

---

## 🎯 最佳实践

### 1. 实验前准备

```gdscript
# 检查清单
func check_experiment_ready() -> bool:
    # 检查Ollama
    if not _is_ollama_running():
        push_error("Ollama未运行")
        return false
    
    # 检查配置文件
    if not FileAccess.file_exists(experiment_config_path):
        push_error("配置文件不存在")
        return false
    
    # 检查磁盘空间
    if _get_free_disk_space() < 100:  # MB
        push_warning("磁盘空间不足")
        return false
    
    return true
```

### 2. 实验进行中

```gdscript
# 监控实验状态
func _monitor_experiment():
    var status = experiment_manager.get_status()
    
    # 如果出现异常，自动暂停
    if status.active_games > 10:  # 游戏堆积
        experiment_manager.pause_experiment()
        push_warning("游戏堆积，已自动暂停")
    
    # 定期保存检查点
    if int(experiment_manager.virtual_time) % 300 == 0:  # 每5分钟
        _save_checkpoint()
```

### 3. 实验完成后

```gdscript
func _on_experiment_finished(results: Dictionary):
    # 1. 保存结果
    _save_results(results)
    
    # 2. 清理资源
    _cleanup_temp_files()
    
    # 3. 生成报告
    _generate_report(results)
    
    # 4. 通知用户
    _show_completion_notification(results)
```

---

## 📚 相关资源

### 文档
- [UI系统说明.md](UI系统说明.md) - 技术文档
- [如何集成实验UI到游戏.md](如何集成实验UI到游戏.md) - 集成指南
- [API_REFERENCE.md](docs/API_REFERENCE.md) - API参考

### 示例
- `scene/ExperimentDashboardUI.tscn` - 完整仪表板示例
- `scene/ExperimentQuickPanel.tscn` - 快速面板示例
- `script/ui/ExperimentMenuButton.gd` - 按钮示例

---

## 🎉 开始使用

1. **新手**：从快速面板开始，运行预设实验
2. **进阶**：使用完整仪表板，尝试自定义配置
3. **专家**：创建自己的UI组件，深度定制

选择适合你的起点，开始探索经济实验的世界！🚀

---

**提示**：遇到问题？查看 [故障排查](#常见问题排查) 章节，或查阅完整文档。

**祝实验顺利！** 🧪💰🤖


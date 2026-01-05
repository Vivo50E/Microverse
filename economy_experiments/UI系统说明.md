# 🎨 经济实验UI系统

## 📋 系统组件概览

经济实验系统提供了**完整的UI解决方案**，包含3个主要面板和1个入口按钮，可灵活集成到游戏中。

### 组件列表

| 组件 | 文件 | 用途 | 复杂度 |
|------|------|------|--------|
| **完整仪表板** | `ExperimentDashboardUI.tscn` | 完整的实验管理界面 | ⭐⭐⭐ |
| **快速面板** | `ExperimentQuickPanel.tscn` | 游戏内嵌入式简化面板 | ⭐⭐ |
| **监控面板** | `ExperimentMonitorPanel.tscn` | 实时数据监控 | ⭐⭐ |
| **入口按钮** | `ExperimentMenuButton.gd` | 快速访问入口 | ⭐ |

---

## 🎯 快速开始

### 最简单的方式（3步）

1. **打开主游戏UI场景**（如 `scene/ui/GodUI.tscn`）

2. **添加实验按钮**：
   - 添加一个 `Button` 节点
   - 附加脚本：`res://script/ui/ExperimentMenuButton.gd`
   - 设置文本：`🧪 实验室`

3. **运行游戏**：
   - 点击按钮打开实验面板
   - 选择实验并启动

**完成！** 就这么简单。

---

## 📦 组件详解

### 1️⃣ ExperimentDashboardUI（完整仪表板）

**路径**：`economy_experiments/scene/ExperimentDashboardUI.tscn`

#### 功能特性

✅ **实验管理**
- 浏览所有可用实验配置
- 查看实验详情和描述
- 一键加载实验

✅ **代理选择**
- 多选模式支持
- 显示所有可用代理
- 可自定义参与代理

✅ **实验控制**
- 开始/暂停/停止按钮
- 实时进度条
- 运行时间显示

✅ **结果展示**
- 详细的统计信息
- 不平等指标（基尼系数等）
- 行为指标（合作、信任等）
- 自动保存到文件

#### 界面布局

```
┌─────────────────────────────────────────────┐
│     经济行为实验仪表板                       │
├─────────────────┬───────────────────────────┤
│ 实验配置列表    │  代理选择（多选）          │
│ • Phase 1      │  □ Alice                   │
│ • Phase 2      │  □ Jack                    │
│ • Phase 3      │  □ Grace                   │
│                │  □ Joe                     │
├─────────────────┴───────────────────────────┤
│ 状态: 运行中 | 代理: 4 | 游戏: 2/5          │
│ [====================] 65%                  │
│ [开始] [暂停] [停止]                        │
├─────────────────┬───────────────────────────┤
│ 实验结果        │  关键指标                  │
│ 详细文本显示    │  基尼系数: 0.3245         │
│                │  合作度: 67%               │
└─────────────────┴───────────────────────────┘
```

#### 使用示例

```gdscript
# 方式1：独立运行
get_tree().change_scene_to_file("res://economy_experiments/scene/ExperimentDashboardUI.tscn")

# 方式2：作为弹窗
var dashboard = load("res://economy_experiments/scene/ExperimentDashboardUI.tscn").instantiate()
add_child(dashboard)

# 方式3：监听信号
dashboard.experiment_selected.connect(func(config_path):
    print("选择了实验: ", config_path)
)
```

---

### 2️⃣ ExperimentQuickPanel（快速面板）

**路径**：`economy_experiments/scene/ExperimentQuickPanel.tscn`

#### 功能特性

✅ **精简设计**
- 紧凑的界面
- 预设实验快速选择
- 最小化干扰

✅ **核心控制**
- 开始/暂停按钮
- 实时状态显示
- 查看详细结果

✅ **游戏集成友好**
- 小尺寸（400x250）
- 可定位到屏幕任意位置
- 透明背景支持

#### 界面布局

```
┌──────────────────────┐
│   🧪 经济实验         │
├──────────────────────┤
│ 选择实验:            │
│ [快速测试 (5分钟) ▼] │
│                      │
│ 运行中 | 游戏: 2/5   │
├──────────────────────┤
│ [开始] [暂停] [结果] │
└──────────────────────┘
```

#### 使用示例

```gdscript
# 创建快速面板
var quick_panel = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn").instantiate()

# 定位到右上角
quick_panel.position = Vector2(
    get_viewport().size.x - 420,
    20
)

add_child(quick_panel)

# 监听状态变化
quick_panel.experiment_state_changed.connect(func(is_running):
    if is_running:
        print("实验开始运行")
        # 可以禁用其他游戏功能
    else:
        print("实验已停止")
        # 恢复游戏功能
)
```

---

### 3️⃣ ExperimentMonitorPanel（监控面板）

**路径**：`economy_experiments/scene/ExperimentMonitorPanel.tscn`

#### 功能特性

✅ **实时监控**
- 代理状态网格显示
- 每个代理的当前财富
- 活跃状态指示

✅ **游戏日志**
- 最近完成的游戏
- 时间戳记录
- 自动滚动

✅ **数据可视化**
- 事件计数器
- 游戏进度
- 财富分布图（预留）

#### 界面布局

```
┌─────────────────────────────────────┐
│      📊 实验实时监控                 │
├─────────────────────────────────────┤
│ 状态概览                             │
│ 事件: 15 | 活跃: 2 | 完成: 8        │
├─────────────────────────────────────┤
│ 代理状态                             │
│ ┌───────┐ ┌───────┐ ┌───────┐      │
│ │ Alice │ │ Jack  │ │ Grace │      │
│ │ 💰245 │ │ 💰189 │ │ 💰312 │      │
│ │ 活跃  │ │ 活跃  │ │ 活跃  │      │
│ └───────┘ └───────┘ └───────┘      │
├─────────────────────────────────────┤
│ 游戏日志                             │
│ [10:32] Ultimatum 完成              │
│ [10:31] Trust 完成                  │
│ [10:29] Public Goods 完成           │
└─────────────────────────────────────┘
```

#### 使用示例

```gdscript
# 创建监控面板
var monitor = load("res://economy_experiments/scene/ExperimentMonitorPanel.tscn").instantiate()
add_child(monitor)

# 连接到实验管理器
var exp_manager = get_node("ExperimentManager")
monitor.connect_to_experiment(exp_manager)

# 监控面板会自动更新显示
```

---

### 4️⃣ ExperimentMenuButton（入口按钮）

**路径**：`script/ui/ExperimentMenuButton.gd`

#### 功能特性

✅ **简单易用**
- 附加到任何按钮
- 自动管理面板生命周期
- 两种模式可选

✅ **灵活配置**
- 选择打开完整仪表板或快速面板
- 自定义按钮文本
- 自动定位

#### 使用方式

**方式1：在编辑器中**

1. 添加 `Button` 节点
2. 附加脚本 `ExperimentMenuButton.gd`
3. 在检查器中设置：
   - `Panel Type`: QUICK_PANEL 或 FULL_DASHBOARD
   - `Button Text`: 自定义文字

**方式2：代码创建**

```gdscript
var button = Button.new()
button.text = "🧪 实验室"
var script = load("res://script/ui/ExperimentMenuButton.gd")
button.set_script(script)
button.panel_type = ExperimentMenuButton.PanelType.QUICK_PANEL
add_child(button)
```

---

## 🎮 集成方案

### 方案A：快速嵌入（推荐新手）

**适用**：快速测试、原型开发

```gdscript
# 在主场景的 _ready() 中
func _ready():
    var button = Button.new()
    button.text = "🧪 实验"
    button.position = Vector2(10, 10)
    button.set_script(load("res://script/ui/ExperimentMenuButton.gd"))
    add_child(button)
```

### 方案B：集成到现有UI（推荐生产环境）

**适用**：完整项目、产品发布

1. 打开主UI场景（如 `GodUI.tscn`）
2. 在合适位置添加按钮
3. 附加 `ExperimentMenuButton.gd`
4. 调整样式和位置

### 方案C：自定义集成（高级用户）

**适用**：需要深度定制

```gdscript
# 自定义实验启动器
extends Control

var experiment_manager: ExperimentManager
var custom_ui: Control

func _ready():
    experiment_manager = ExperimentManager.new()
    add_child(experiment_manager)
    
    # 创建你的自定义UI
    custom_ui = create_custom_ui()
    add_child(custom_ui)
    
    # 连接信号
    experiment_manager.experiment_finished.connect(_on_exp_finished)

func create_custom_ui() -> Control:
    # 你的UI逻辑
    pass

func start_experiment(config_name: String):
    var path = "res://economy_experiments/configs/experiments/%s.json" % config_name
    experiment_manager.load_experiment(path)
    experiment_manager.setup_experiment()
    experiment_manager.start_experiment()
```

---

## 🎨 样式自定义

### 修改主题颜色

```gdscript
# 在场景的 _ready() 中
func _ready():
    # 修改标题颜色
    $TitleLabel.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
    
    # 修改面板背景
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    $Panel.add_theme_stylebox_override("panel", style)
```

### 应用自定义主题

创建主题资源 `.tres` 文件：

```gdscript
# experiment_theme.tres
[gd_resource type="Theme"]

[resource]
default_font_size = 16
Button/colors/font_color = Color(0.9, 0.9, 0.9)
Button/colors/font_hover_color = Color(1, 1, 1)
Panel/styles/panel = SubResource("StyleBoxFlat_xxxxx")
```

然后应用：

```gdscript
$ExperimentPanel.theme = load("res://asset/ui/theme/experiment_theme.tres")
```

---

## 📱 响应式设计

所有UI组件都支持响应式布局：

### 自动调整大小

```gdscript
# UI会根据窗口大小自动调整
func _ready():
    get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized():
    # 快速面板始终在右上角
    if quick_panel:
        quick_panel.position = Vector2(
            get_viewport().size.x - quick_panel.size.x - 20,
            20
        )
```

### 移动端适配

```gdscript
# 检测平台并调整UI
func _ready():
    if OS.has_feature("mobile"):
        # 使用全屏模式
        $ExperimentPanel.anchors_preset = Control.PRESET_FULL_RECT
    else:
        # 使用窗口模式
        $ExperimentPanel.size = Vector2(800, 600)
```

---

## 🔧 高级功能

### 1. 多语言支持

```gdscript
# 创建翻译字典
var translations = {
    "en": {
        "start": "Start",
        "pause": "Pause",
        "stop": "Stop"
    },
    "zh": {
        "start": "开始",
        "pause": "暂停",
        "stop": "停止"
    }
}

# 应用翻译
func set_language(lang: String):
    start_button.text = translations[lang]["start"]
    pause_button.text = translations[lang]["pause"]
    stop_button.text = translations[lang]["stop"]
```

### 2. 键盘快捷键

```gdscript
func _input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F9:  # 打开实验面板
                toggle_experiment_panel()
            KEY_F10:  # 开始实验
                if not is_running:
                    start_experiment()
            KEY_F11:  # 暂停/恢复
                if is_running:
                    toggle_pause()
            KEY_F12:  # 停止实验
                if is_running:
                    stop_experiment()
```

### 3. 数据持久化

```gdscript
# 保存UI状态
func save_ui_state():
    var state = {
        "selected_experiment": selected_experiment_path,
        "panel_position": quick_panel.position,
        "window_size": $ExperimentPanel.size
    }
    
    var file = FileAccess.open("user://experiment_ui_state.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(state))
    file.close()

# 恢复UI状态
func load_ui_state():
    var file = FileAccess.open("user://experiment_ui_state.json", FileAccess.READ)
    if file:
        var json = JSON.parse_string(file.get_as_text())
        selected_experiment_path = json.selected_experiment
        quick_panel.position = json.panel_position
        # ...
```

---

## 📊 性能优化

### 1. 延迟加载

```gdscript
# 只在需要时加载UI场景
var dashboard_scene: PackedScene = null

func open_dashboard():
    if not dashboard_scene:
        dashboard_scene = load("res://economy_experiments/scene/ExperimentDashboardUI.tscn")
    
    var dashboard = dashboard_scene.instantiate()
    add_child(dashboard)
```

### 2. 更新频率控制

```gdscript
# 控制监控面板的更新频率
var update_timer: float = 0.0
var update_interval: float = 1.0  # 每秒更新一次

func _process(delta: float):
    update_timer += delta
    if update_timer >= update_interval:
        update_timer = 0.0
        update_display()  # 只在需要时更新
```

### 3. 对象池

```gdscript
# 为代理卡片使用对象池
var agent_card_pool: Array[Control] = []

func get_agent_card() -> Control:
    if agent_card_pool.is_empty():
        return create_agent_card()
    else:
        return agent_card_pool.pop_back()

func return_agent_card(card: Control):
    card.visible = false
    agent_card_pool.append(card)
```

---

## 🐛 调试工具

### 启用调试模式

```gdscript
# 在 ExperimentDashboardUI.gd 顶部添加
const DEBUG_MODE = true

func _show_debug_info(message: String):
    if DEBUG_MODE:
        print("[ExperimentUI DEBUG] ", message)
        # 可以在UI上显示调试信息
```

### 性能监控

```gdscript
# 添加FPS显示
func _process(_delta):
    if DEBUG_MODE:
        $DebugLabel.text = "FPS: %d | 代理: %d | 内存: %.2f MB" % [
            Engine.get_frames_per_second(),
            experiment_manager.economic_agents.size(),
            OS.get_static_memory_usage() / 1024.0 / 1024.0
        ]
```

---

## 📚 完整示例

### 示例：在 Office 场景中添加实验功能

```gdscript
# scene/maps/Office.gd（或你的主场景脚本）
extends Node2D

@onready var ui_layer: CanvasLayer = $UILayer
var experiment_button: Button
var quick_panel: ExperimentQuickPanel

func _ready():
    _setup_experiment_ui()

func _setup_experiment_ui():
    # 创建UI层（如果不存在）
    if not ui_layer:
        ui_layer = CanvasLayer.new()
        ui_layer.name = "UILayer"
        ui_layer.layer = 10  # 确保在最上层
        add_child(ui_layer)
    
    # 添加实验按钮
    experiment_button = Button.new()
    experiment_button.text = "🧪 实验室"
    experiment_button.position = Vector2(10, 10)
    experiment_button.custom_minimum_size = Vector2(120, 40)
    
    # 附加脚本
    var script = load("res://script/ui/ExperimentMenuButton.gd")
    experiment_button.set_script(script)
    experiment_button.panel_type = 1  # QUICK_PANEL
    
    ui_layer.add_child(experiment_button)
    
    print("✅ 实验UI已添加到 Office 场景")

func _input(event: InputEvent):
    # F9快捷键
    if event is InputEventKey and event.keycode == KEY_F9 and event.pressed:
        experiment_button.emit_signal("pressed")
```

---

## ✅ 测试清单

完成集成后，请确保测试以下功能：

### 基础功能
- [ ] 按钮可以正常显示
- [ ] 点击按钮打开面板
- [ ] 面板显示完整无遮挡
- [ ] 可以选择实验配置
- [ ] 可以启动实验

### 实验控制
- [ ] 开始按钮正常工作
- [ ] 暂停/恢复功能正常
- [ ] 停止按钮正常工作
- [ ] 状态显示正确更新

### 结果显示
- [ ] 实验完成后显示结果
- [ ] 统计信息正确
- [ ] 指标计算准确
- [ ] 数据保存成功

### UI交互
- [ ] 面板可以正常关闭
- [ ] 多次打开/关闭正常
- [ ] 不影响游戏其他功能
- [ ] 快捷键正常工作（如有）

### 性能测试
- [ ] UI不卡顿
- [ ] 内存使用正常
- [ ] FPS保持稳定
- [ ] 实验运行流畅

---

## 🆘 常见问题

### Q: UI显示不出来？
A: 检查Z-index和CanvasLayer设置，确保在可见层。

### Q: 按钮点击没反应？
A: 确认按钮已连接pressed信号，检查脚本路径是否正确。

### Q: 实验启动失败？
A: 检查Ollama是否运行，API设置是否正确，配置文件是否存在。

### Q: 面板被其他UI遮挡？
A: 增大CanvasLayer的layer值，或设置z_index = 100。

### Q: 性能下降明显？
A: 减少同时运行的代理数量，降低更新频率，使用快速面板而非完整仪表板。

---

## 📖 相关文档

- [如何集成实验UI到游戏.md](如何集成实验UI到游戏.md) - 详细集成指南
- [API_REFERENCE.md](docs/API_REFERENCE.md) - 完整API文档
- [EXPERIMENT_GUIDE.md](docs/EXPERIMENT_GUIDE.md) - 实验设计指南

---

## 🎉 总结

UI系统提供了从简单到复杂的完整解决方案：

1. **入门**：使用 `ExperimentMenuButton` + `ExperimentQuickPanel`
2. **进阶**：使用 `ExperimentDashboardUI` 获得完整功能
3. **专业**：结合 `ExperimentMonitorPanel` 实现实时监控
4. **定制**：基于提供的组件创建自己的UI

选择最适合你的方式，开始实验吧！🚀

---

**版本**: 1.0.0  
**更新日期**: 2025-01-05  
**兼容性**: Godot 4.3+


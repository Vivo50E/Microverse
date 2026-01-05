# 🎮 如何集成实验UI到游戏

## 概述

实验系统提供了三种UI组件，可以灵活集成到Microverse游戏中：

1. **完整仪表板** (`ExperimentDashboardUI`) - 功能最全面
2. **快速面板** (`ExperimentQuickPanel`) - 简化版，适合游戏内使用
3. **监控面板** (`ExperimentMonitorPanel`) - 实时数据显示

---

## 方法一：添加实验入口按钮（推荐）

### 步骤 1：在主UI添加按钮

在你的主游戏UI场景（如 `GodUI.tscn`）中：

1. 打开场景文件
2. 添加一个新的 `Button` 节点
3. 设置按钮属性：
   - **Text**: "🧪 快速实验"
   - **Script**: `res://script/ui/ExperimentMenuButton.gd`

### 步骤 2：配置按钮类型

选择按钮节点，在检查器中设置：

- **Panel Type**: 
  - `QUICK_PANEL` - 快速面板（推荐游戏内使用）
  - `FULL_DASHBOARD` - 完整仪表板
- **Button Text**: 自定义按钮文字

### 完成！

运行游戏，点击按钮即可打开实验面板。

---

## 方法二：作为游戏内标签页

### 整合到现有UI系统

如果你的游戏有标签页系统（如设置界面），可以将实验面板作为一个标签页：

```gdscript
# 在你的主UI脚本中
extends Control

@onready var tab_container: TabContainer = $TabContainer
var experiment_panel_scene = preload("res://economy_experiments/scene/ExperimentQuickPanel.tscn")

func _ready():
    # 添加实验标签页
    var experiment_tab = experiment_panel_scene.instantiate()
    tab_container.add_child(experiment_tab)
    tab_container.set_tab_title(tab_container.get_tab_count() - 1, "实验室")
```

---

## 方法三：场景替换方式

### 直接运行实验场景

适合独立的实验环境：

```gdscript
# 从主菜单切换到实验场景
func _on_experiment_button_pressed():
    get_tree().change_scene_to_file("res://economy_experiments/scene/ExperimentDashboardUI.tscn")
```

---

## 各UI组件详解

### 1. ExperimentDashboardUI（完整仪表板）

**功能**：
- ✅ 实验配置选择
- ✅ 多代理选择
- ✅ 完整的实验控制
- ✅ 详细结果显示
- ✅ 实时指标可视化

**适用场景**：
- 研究人员使用
- 需要完整控制的场合
- 独立的实验界面

**使用示例**：
```gdscript
# 直接加载完整仪表板
var dashboard = load("res://economy_experiments/scene/ExperimentDashboardUI.tscn").instantiate()
add_child(dashboard)
```

---

### 2. ExperimentQuickPanel（快速面板）

**功能**：
- ✅ 快速实验启动
- ✅ 简化的控制
- ✅ 状态显示
- ✅ 轻量级UI

**适用场景**：
- 游戏内嵌入使用
- 快速测试
- 玩家体验优先

**使用示例**：
```gdscript
# 添加快速面板到游戏UI
var quick_panel = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn").instantiate()
quick_panel.position = Vector2(900, 50)  # 定位到右上角
add_child(quick_panel)

# 监听实验状态变化
quick_panel.experiment_state_changed.connect(func(is_running):
    print("实验运行状态: ", is_running)
)
```

---

### 3. ExperimentMonitorPanel（监控面板）

**功能**：
- ✅ 实时代理状态
- ✅ 游戏日志
- ✅ 事件计数
- ✅ 财富分布可视化

**适用场景**：
- 实验进行中的监控
- 调试和分析
- 数据可视化展示

**使用示例**：
```gdscript
# 创建监控面板并连接到实验管理器
var monitor = load("res://economy_experiments/scene/ExperimentMonitorPanel.tscn").instantiate()
add_child(monitor)

# 连接到运行中的实验
var experiment_manager = get_node("ExperimentManager")
monitor.connect_to_experiment(experiment_manager)
```

---

## 完整集成示例

### 示例：在主游戏添加实验功能

假设你的主游戏有 `GodUI.tscn`（上帝视角UI）：

#### 方案A：快速面板（最简单）

1. **打开 `GodUI.tscn`**

2. **添加实验按钮**：
   - 在UI合适位置添加 `Button` 节点
   - 命名为 `ExperimentButton`
   - 附加脚本 `ExperimentMenuButton.gd`
   - 设置 `panel_type = QUICK_PANEL`

3. **完成！** 运行游戏测试

#### 方案B：集成到现有面板（更美观）

修改你的 `GodUI.gd` 脚本：

```gdscript
extends Control

# 现有的节点
@onready var settings_button: Button = $SettingsButton
@onready var save_button: Button = $SaveButton
# ... 其他按钮 ...

# 新增：实验按钮和面板
@onready var experiment_button: Button = $ExperimentButton
var experiment_quick_panel: ExperimentQuickPanel = null

func _ready():
    # 现有的连接
    settings_button.pressed.connect(_on_settings_pressed)
    save_button.pressed.connect(_on_save_pressed)
    
    # 新增：实验按钮连接
    experiment_button.pressed.connect(_on_experiment_pressed)

func _on_experiment_pressed():
    if experiment_quick_panel == null:
        # 首次打开，创建面板
        var panel_scene = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn")
        experiment_quick_panel = panel_scene.instantiate()
        
        # 定位面板
        experiment_quick_panel.position = Vector2(
            get_viewport().size.x - 420,  # 右侧
            100  # 顶部偏移
        )
        
        add_child(experiment_quick_panel)
    else:
        # 切换显示/隐藏
        experiment_quick_panel.visible = not experiment_quick_panel.visible
```

---

## 样式自定义

### 修改面板主题

你可以为实验UI应用自定义主题：

```gdscript
# 在场景的 _ready() 中
var custom_theme = load("res://asset/ui/theme/experiment_theme.tres")
$ExperimentPanel.theme = custom_theme
```

### 调整颜色和字体

编辑场景文件，选择节点后在检查器中修改：
- **Label** → Theme Overrides → Colors → Font Color
- **Panel** → Theme Overrides → Styles → Panel
- **Button** → Theme Overrides → Colors/Styles

---

## 快捷键支持

### 添加键盘快捷键打开实验面板

在主场景脚本中：

```gdscript
func _input(event: InputEvent):
    # 按 F9 打开/关闭实验面板
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F9:
            _toggle_experiment_panel()

func _toggle_experiment_panel():
    if experiment_quick_panel:
        experiment_quick_panel.visible = not experiment_quick_panel.visible
    else:
        _on_experiment_pressed()  # 创建面板
```

---

## 多场景支持

### 在多个场景中使用实验UI

创建一个自动加载（Autoload）脚本：

```gdscript
# ExperimentUIManager.gd - 添加到项目设置 → Autoload
extends Node

var quick_panel_scene = preload("res://economy_experiments/scene/ExperimentQuickPanel.tscn")
var current_panel: ExperimentQuickPanel = null

func open_quick_panel():
    if current_panel == null:
        current_panel = quick_panel_scene.instantiate()
        get_tree().root.add_child(current_panel)
        current_panel.z_index = 100
    current_panel.visible = true

func close_quick_panel():
    if current_panel:
        current_panel.visible = false

func toggle_quick_panel():
    if current_panel and current_panel.visible:
        close_quick_panel()
    else:
        open_quick_panel()
```

然后在任何场景中调用：

```gdscript
# 任意脚本中
func _ready():
    $ExperimentButton.pressed.connect(func():
        ExperimentUIManager.toggle_quick_panel()
    )
```

---

## 最佳实践

### 1. 性能考虑

实验系统可能占用较多资源，建议：

- ✅ 使用快速面板而不是完整仪表板
- ✅ 限制同时运行的代理数量（4-8个）
- ✅ 在暂停游戏时运行实验
- ✅ 使用 `time_scale` 加速实验

### 2. 用户体验

- ✅ 提供清晰的状态提示
- ✅ 允许用户随时暂停/停止实验
- ✅ 在实验运行时禁用其他游戏操作
- ✅ 实验完成后显示通知

### 3. 数据管理

- ✅ 定期清理旧的实验数据
- ✅ 提供导出功能
- ✅ 自动保存实验进度

---

## 测试清单

集成完成后，测试以下功能：

- [ ] 实验按钮可以正常打开面板
- [ ] 可以选择实验配置
- [ ] 可以启动/暂停/停止实验
- [ ] 状态显示正常更新
- [ ] 实验完成后显示结果
- [ ] 面板可以正常关闭
- [ ] 多次打开/关闭正常工作
- [ ] 不影响游戏其他功能

---

## 故障排除

### 问题：点击按钮没反应

**检查**：
1. 按钮是否连接了 `pressed` 信号
2. 场景路径是否正确
3. 查看 Godot 控制台的错误信息

### 问题：面板显示不完整

**解决**：
1. 检查面板的 `anchors_preset` 设置
2. 确保父节点有足够空间
3. 调整 `custom_minimum_size`

### 问题：实验无法启动

**检查**：
1. Ollama 是否运行
2. API 设置是否正确
3. 实验配置文件是否存在
4. 查看实验管理器的错误日志

---

## 进阶：自定义实验UI

### 创建你自己的实验面板

```gdscript
extends Control

var experiment_manager: ExperimentManager

func _ready():
    experiment_manager = ExperimentManager.new()
    add_child(experiment_manager)
    
    # 自定义你的UI逻辑
    setup_ui()
    connect_signals()

func setup_ui():
    # 创建你的UI元素
    pass

func start_custom_experiment():
    # 使用代码配置实验
    experiment_manager.load_experiment("res://your_config.json")
    experiment_manager.setup_experiment()
    experiment_manager.start_experiment()
```

---

## 总结

- **快速集成**：使用 `ExperimentMenuButton` + `ExperimentQuickPanel`
- **完整功能**：使用 `ExperimentDashboardUI`
- **实时监控**：使用 `ExperimentMonitorPanel`
- **自定义**：基于提供的组件创建自己的UI

选择最适合你游戏的集成方式，开始实验！🚀


extends Control
class_name ExperimentQuickPanel

## 快速实验面板 - 可以作为游戏内的子面板使用
## 提供简化的实验控制界面

@onready var experiment_selector: OptionButton = $PanelContainer/VBox/ExperimentSelector
@onready var status_label: Label = $PanelContainer/VBox/StatusLabel
@onready var start_btn: Button = $PanelContainer/VBox/ButtonContainer/StartButton
@onready var pause_btn: Button = $PanelContainer/VBox/ButtonContainer/PauseButton
@onready var results_btn: Button = $PanelContainer/VBox/ButtonContainer/ResultsButton

var experiment_manager: ExperimentManager
var current_experiment_config: String = ""
var is_running: bool = false
var lab_manager: ExperimentLabManager  # 添加对实验室管理器的引用

# 预设实验配置
var quick_experiments: Array[Dictionary] = [
	{
		"name": "快速测试 (5分钟)",
		"path": "res://economy_experiments/configs/experiments/phase1_behavioral.json"
	},
	{
		"name": "市场模拟 (10分钟)",
		"path": "res://economy_experiments/configs/experiments/phase2_market.json"
	},
	{
		"name": "模型对比 (15分钟)",
		"path": "res://economy_experiments/configs/experiments/phase3_comparison.json"
	}
]

signal experiment_state_changed(is_running: bool)
signal experiment_completed(results: Dictionary)  # 新增：实验完成信号

func _ready():
	# 初始化实验管理器
	experiment_manager = ExperimentManager.new()
	add_child(experiment_manager)
	
	# 获取实验室管理器
	lab_manager = get_node_or_null("/root/ExperimentLabManager")
	if not lab_manager:
		lab_manager = ExperimentLabManager.new()
		lab_manager.name = "ExperimentLabManager"
		get_tree().root.call_deferred("add_child", lab_manager)
		print("ExperimentQuickPanel: 创建实验室管理器")
	
	# 连接信号
	experiment_manager.experiment_started.connect(_on_experiment_started)
	experiment_manager.experiment_finished.connect(_on_experiment_finished)
	
	start_btn.pressed.connect(_on_start_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	results_btn.pressed.connect(_on_results_pressed)
	
	# 填充实验选择器
	_populate_experiments()
	
	_update_ui_state()

func _populate_experiments():
	experiment_selector.clear()
	for i in range(quick_experiments.size()):
		experiment_selector.add_item(quick_experiments[i].name, i)

func _on_start_pressed():
	var selected_id = experiment_selector.selected
	if selected_id < 0 or selected_id >= quick_experiments.size():
		status_label.text = "请选择一个实验"
		return
	
	current_experiment_config = quick_experiments[selected_id].path
	
	# 加载并启动实验
	if experiment_manager.load_experiment(current_experiment_config):
		if experiment_manager.setup_experiment():
			if experiment_manager.start_experiment():
				is_running = true
				_update_ui_state()
				experiment_state_changed.emit(true)
			else:
				status_label.text = "❌ 启动失败"
		else:
			status_label.text = "❌ 设置失败"
	else:
		status_label.text = "❌ 加载失败"

func _on_pause_pressed():
	if is_running:
		if experiment_manager.state == ExperimentManager.ExperimentState.PAUSED:
			experiment_manager.resume_experiment()
			pause_btn.text = "暂停"
		else:
			experiment_manager.pause_experiment()
			pause_btn.text = "恢复"

func _on_results_pressed():
	# 创建CanvasLayer确保在最上层
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128  # 最高层级
	canvas_layer.name = "ResultsDashboardLayer"
	get_tree().root.add_child(canvas_layer)
	
	# 创建半透明背景遮罩
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)  # 半透明黑色
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(background)
	
	# 加载结果面板
	var dashboard = load("res://economy_experiments/scene/ExperimentDashboardUI.tscn").instantiate()
	
	# 使用锚点让面板填满整个屏幕（或居中）
	dashboard.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 添加边距（可选，让面板不要完全填满屏幕）
	var margin = 50
	dashboard.offset_left = margin
	dashboard.offset_right = -margin
	dashboard.offset_top = margin
	dashboard.offset_bottom = -margin
	
	# 确保可以接收鼠标事件
	dashboard.mouse_filter = Control.MOUSE_FILTER_STOP
	dashboard.z_index = 100
	
	# 添加到CanvasLayer
	canvas_layer.add_child(dashboard)
	
	# 添加关闭按钮
	var close_btn = Button.new()
	close_btn.text = "✖ 关闭"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.tooltip_text = "关闭结果面板"
	
	# 定位到右上角
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -90
	close_btn.offset_right = -10
	close_btn.offset_top = 10
	close_btn.offset_bottom = 50
	close_btn.z_index = 110
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接关闭信号
	close_btn.pressed.connect(func():
		canvas_layer.queue_free()
		print("✅ 结果面板已关闭")
	)
	
	dashboard.add_child(close_btn)
	
	# 点击背景关闭
	background.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			canvas_layer.queue_free()
			print("✅ 结果面板已关闭（点击背景）")
	)
	
	print("✅ 结果面板已创建在层级 128")

func _on_experiment_started(exp_name: String):
	status_label.text = "▶ 运行中: " + exp_name

func _on_experiment_finished(results: Dictionary):
	is_running = false
	_update_ui_state()
	
	var stats = results.get("statistics", {})
	status_label.text = "✅ 完成 | 游戏: %d" % stats.get("games_played", 0)
	
	# 通知实验室管理器更新agent财富
	if lab_manager:
		var experiment_data = {
			"cost": 0.0,  # 可以根据实验类型设置成本
			"data_points": stats.get("total_decisions", 0),
			"results": results
		}
		lab_manager.on_experiment_completed(experiment_data)
		print("ExperimentQuickPanel: 实验结果已传递给实验室管理器")
	
	experiment_state_changed.emit(false)
	experiment_completed.emit(results)

func _update_ui_state():
	start_btn.disabled = is_running
	pause_btn.disabled = not is_running
	experiment_selector.disabled = is_running
	
	if not is_running:
		status_label.text = "等待启动..."
		pause_btn.text = "暂停"

func _process(_delta):
	if is_running:
		var status = experiment_manager.get_status()
		status_label.text = "运行中 | 代理: %d | 游戏: %d/%d" % [
			status.agents_count,
			status.active_games,
			status.completed_games
		]


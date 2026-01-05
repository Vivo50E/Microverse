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

func _ready():
	# 初始化实验管理器
	experiment_manager = ExperimentManager.new()
	add_child(experiment_manager)
	
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
	# 打开完整的结果面板
	var dashboard = load("res://economy_experiments/scene/ExperimentDashboardUI.tscn").instantiate()
	get_tree().root.add_child(dashboard)

func _on_experiment_started(exp_name: String):
	status_label.text = "▶ 运行中: " + exp_name

func _on_experiment_finished(results: Dictionary):
	is_running = false
	_update_ui_state()
	
	var stats = results.get("statistics", {})
	status_label.text = "✅ 完成 | 游戏: %d" % stats.get("games_played", 0)
	experiment_state_changed.emit(false)

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


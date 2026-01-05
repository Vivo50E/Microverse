extends Control
class_name ExperimentDashboardUI

## 经济实验仪表板UI
## 提供完整的实验管理界面

# UI 节点引用
@onready var experiment_list: ItemList = $Panel/MarginContainer/VBoxContainer/TopSection/LeftPanel/ExperimentList
@onready var agent_list: ItemList = $Panel/MarginContainer/VBoxContainer/TopSection/RightPanel/AgentList
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/ControlSection/StatusPanel/StatusLabel
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/ControlSection/StatusPanel/ProgressBar
@onready var start_button: Button = $Panel/MarginContainer/VBoxContainer/ControlSection/ButtonPanel/StartButton
@onready var pause_button: Button = $Panel/MarginContainer/VBoxContainer/ControlSection/ButtonPanel/PauseButton
@onready var stop_button: Button = $Panel/MarginContainer/VBoxContainer/ControlSection/ButtonPanel/StopButton
@onready var results_text: TextEdit = $Panel/MarginContainer/VBoxContainer/ResultsSection/ResultsPanel/ResultsText
@onready var time_label: Label = $Panel/MarginContainer/VBoxContainer/ControlSection/StatusPanel/TimeLabel
@onready var metrics_display: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ResultsSection/MetricsPanel/MetricsDisplay

# 实验管理器
var experiment_manager: ExperimentManager = null

# 可用的实验配置
var available_experiments: Array[Dictionary] = []

# 可用的代理
var available_agents: Array[String] = ["Alice", "Jack", "Grace", "Joe", "Lea", "Monica", "Stephen", "Tom"]

# 当前选中的实验和代理
var selected_experiment_path: String = ""
var selected_agents: Array[String] = []

# 运行时状态
var is_running: bool = false
var is_paused: bool = false
var start_time: float = 0.0

# 信号
signal experiment_selected(config_path: String)
signal agents_selected(agent_names: Array)

func _ready():
	# 初始化实验管理器
	_initialize_experiment_manager()
	
	# 加载可用实验
	_load_available_experiments()
	
	# 初始化代理列表
	_initialize_agent_list()
	
	# 连接信号
	_connect_signals()
	
	# 更新UI状态
	_update_ui_state()
	
	print("✅ ExperimentDashboardUI 初始化完成")

func _initialize_experiment_manager():
	experiment_manager = ExperimentManager.new()
	add_child(experiment_manager)
	
	# 连接实验管理器信号
	experiment_manager.experiment_started.connect(_on_experiment_started)
	experiment_manager.experiment_finished.connect(_on_experiment_finished)
	experiment_manager.experiment_paused.connect(_on_experiment_paused)
	experiment_manager.experiment_resumed.connect(_on_experiment_resumed)

func _load_available_experiments():
	# 扫描实验配置文件
	var experiments_dir = "res://economy_experiments/configs/experiments/"
	var dir = DirAccess.open(experiments_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var full_path = experiments_dir + file_name
				var config = _load_json_file(full_path)
				if config:
					config["_path"] = full_path
					available_experiments.append(config)
					
					# 添加到列表
					var display_name = config.get("name", file_name)
					experiment_list.add_item(display_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	print("加载了 %d 个实验配置" % available_experiments.size())

func _initialize_agent_list():
	agent_list.select_mode = ItemList.SELECT_MULTI
	
	for agent_name in available_agents:
		agent_list.add_item(agent_name)

func _connect_signals():
	# 实验列表选择
	experiment_list.item_selected.connect(_on_experiment_list_item_selected)
	
	# 代理列表选择（多选）
	agent_list.multi_selected.connect(_on_agent_multi_selected)
	
	# 控制按钮
	start_button.pressed.connect(_on_start_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	stop_button.pressed.connect(_on_stop_button_pressed)

func _process(delta: float):
	if is_running and not is_paused:
		# 更新时间显示
		var elapsed = Time.get_unix_time_from_system() - start_time
		time_label.text = "运行时间: %s" % _format_time(elapsed)
		
		# 更新进度条
		if experiment_manager.current_experiment.has("duration_minutes"):
			var duration = experiment_manager.current_experiment.duration_minutes * 60.0
			var progress = (experiment_manager.virtual_time / duration) * 100.0
			progress_bar.value = min(progress, 100.0)
		
		# 更新状态
		_update_status_display()

func _on_experiment_list_item_selected(index: int):
	if index >= 0 and index < available_experiments.size():
		var config = available_experiments[index]
		selected_experiment_path = config.get("_path", "")
		
		# 显示实验描述
		var description = config.get("description", "无描述")
		var duration = config.get("duration_minutes", 0)
		var agent_count = config.get("agents", []).size()
		
		status_label.text = "已选择: %s\n时长: %d 分钟 | 代理数: %d\n\n%s" % [
			config.get("name", "未命名"),
			duration,
			agent_count,
			description
		]
		
		emit_signal("experiment_selected", selected_experiment_path)

func _on_agent_multi_selected(_index: int, selected: bool):
	# 更新选中的代理列表
	selected_agents.clear()
	for i in range(agent_list.item_count):
		if agent_list.is_selected(i):
			selected_agents.append(agent_list.get_item_text(i))
	
	emit_signal("agents_selected", selected_agents)

func _on_start_button_pressed():
	if selected_experiment_path.is_empty():
		_show_message("请先选择一个实验配置")
		return
	
	# 加载实验
	if not experiment_manager.load_experiment(selected_experiment_path):
		_show_message("❌ 实验配置加载失败")
		return
	
	# 如果有选中的代理，可以在这里修改配置
	# (暂时使用配置文件中的代理设置)
	
	# 设置实验
	if not experiment_manager.setup_experiment():
		_show_message("❌ 实验设置失败")
		return
	
	# 启动实验
	if experiment_manager.start_experiment():
		is_running = true
		is_paused = false
		start_time = Time.get_unix_time_from_system()
		_update_ui_state()
		_show_message("✅ 实验已启动")
	else:
		_show_message("❌ 实验启动失败")

func _on_pause_button_pressed():
	if is_running:
		if is_paused:
			experiment_manager.resume_experiment()
			is_paused = false
			_show_message("▶ 实验已恢复")
		else:
			experiment_manager.pause_experiment()
			is_paused = true
			_show_message("⏸ 实验已暂停")
		
		_update_ui_state()

func _on_stop_button_pressed():
	if is_running:
		experiment_manager.finish_experiment()
		is_running = false
		is_paused = false
		_update_ui_state()
		_show_message("⏹ 实验已停止")

func _on_experiment_started(exp_name: String):
	_show_message("🎉 实验开始: " + exp_name)
	status_label.text = "运行中: " + exp_name

func _on_experiment_finished(results: Dictionary):
	is_running = false
	is_paused = false
	_update_ui_state()
	
	# 显示结果
	_display_results(results)
	_show_message("🎊 实验完成！")

func _on_experiment_paused():
	_show_message("⏸ 实验已暂停")

func _on_experiment_resumed():
	_show_message("▶ 实验已恢复")

func _update_ui_state():
	# 更新按钮状态
	start_button.disabled = is_running
	pause_button.disabled = not is_running
	stop_button.disabled = not is_running
	
	if is_paused:
		pause_button.text = "恢复"
	else:
		pause_button.text = "暂停"
	
	# 更新进度条
	if not is_running:
		progress_bar.value = 0
		time_label.text = "运行时间: 00:00"

func _update_status_display():
	if experiment_manager:
		var status = experiment_manager.get_status()
		
		# 更新状态文本
		var state_text = status.get("state", "UNKNOWN")
		var agents_count = status.get("agents_count", 0)
		var active_games = status.get("active_games", 0)
		var completed_games = status.get("completed_games", 0)
		
		status_label.text = "状态: %s\n代理: %d | 进行中: %d | 已完成: %d" % [
			state_text,
			agents_count,
			active_games,
			completed_games
		]

func _display_results(results: Dictionary):
	# 清空之前的结果
	results_text.text = ""
	
	# 显示基本信息
	results_text.text += "=" .repeat(60) + "\n"
	results_text.text += "实验结果\n"
	results_text.text += "=" .repeat(60) + "\n\n"
	
	results_text.text += "实验名称: %s\n" % results.get("experiment_name", "未知")
	results_text.text += "会话ID: %s\n" % results.get("session_id", "未知")
	results_text.text += "持续时间: %.2f 秒\n\n" % results.get("duration", 0.0)
	
	# 显示统计信息
	if results.has("statistics"):
		var stats = results.statistics
		results_text.text += "统计信息:\n"
		results_text.text += "  代理数: %d\n" % stats.get("agents", 0)
		results_text.text += "  游戏场次: %d\n" % stats.get("games_played", 0)
		results_text.text += "  总事件: %d\n" % stats.get("total_events", 0)
		results_text.text += "  总决策: %d\n" % stats.get("total_decisions", 0)
		results_text.text += "  总交易: %d\n\n" % stats.get("total_transactions", 0)
	
	# 显示指标
	if results.has("metrics"):
		_display_metrics(results.metrics)
	
	results_text.text += "\n" + "=" .repeat(60) + "\n"
	results_text.text += "详细数据已保存到: data/exports/\n"

func _display_metrics(metrics: Dictionary):
	# 清空指标显示
	for child in metrics_display.get_children():
		child.queue_free()
	
	# 不平等指标
	if metrics.has("inequality"):
		var ineq = metrics.inequality
		results_text.text += "不平等指标:\n"
		results_text.text += "  基尼系数: %.4f\n" % ineq.get("gini_coefficient", 0.0)
		results_text.text += "  总财富: %.2f\n" % ineq.get("total_wealth", 0.0)
		results_text.text += "  平均财富: %.2f\n" % ineq.get("mean_wealth", 0.0)
		results_text.text += "  中位数财富: %.2f\n\n" % ineq.get("median_wealth", 0.0)
		
		# 创建可视化标签
		_add_metric_label("基尼系数", "%.4f" % ineq.get("gini_coefficient", 0.0))
		_add_metric_label("平均财富", "%.2f" % ineq.get("mean_wealth", 0.0))
	
	# 行为指标
	if metrics.has("behavioral"):
		var behav = metrics.behavioral
		results_text.text += "行为指标:\n"
		results_text.text += "  平均合作: %.4f\n" % behav.get("average_cooperation", 0.0)
		results_text.text += "  平均信任: %.4f\n" % behav.get("average_trust", 0.0)
		results_text.text += "  平均互惠: %.4f\n" % behav.get("average_reciprocity", 0.0)
		results_text.text += "  平均公平: %.4f\n\n" % behav.get("average_fairness", 0.0)
		
		_add_metric_label("合作度", "%.2f%%" % (behav.get("average_cooperation", 0.0) * 100))
		_add_metric_label("信任度", "%.2f%%" % (behav.get("average_trust", 0.0) * 100))

func _add_metric_label(metric_name: String, value: String):
	var hbox = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = metric_name + ":"
	name_label.custom_minimum_size = Vector2(120, 0)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	
	hbox.add_child(name_label)
	hbox.add_child(value_label)
	metrics_display.add_child(hbox)

func _show_message(message: String):
	print(message)
	# 可以添加一个消息提示UI

func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

func _load_json_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return {}
	
	return json.data if json.data is Dictionary else {}


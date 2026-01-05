extends Control
class_name EconomicControlPanel

## 经济系统控制面板
## 允许开关自动交易、调整参数等

var panel_container: PanelContainer
var settings_vbox: VBoxContainer

# 控制开关
var auto_trade_checkbox: CheckBox
var trade_frequency_slider: HSlider
var trade_frequency_label: Label

# 统计显示
var stats_label: Label
var stats_timer: Timer

# 引用
var scene_tracker: Node = null

func _ready():
	scene_tracker = get_node_or_null("/root/SceneExperimentTracker")
	_create_ui()
	_create_stats_timer()
	
	print("✅ EconomicControlPanel: 经济控制面板已初始化")

func _create_ui():
	"""创建UI界面"""
	# 主面板
	panel_container = PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_container.position = Vector2(10, 150)
	panel_container.custom_minimum_size = Vector2(250, 200)
	add_child(panel_container)
	
	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.7, 0.5, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel_container.add_theme_stylebox_override("panel", style)
	
	# VBox容器
	settings_vbox = VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 8)
	panel_container.add_child(settings_vbox)
	
	# 标题
	var title = Label.new()
	title.text = "💰 经济系统控制"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.6))
	settings_vbox.add_child(title)
	
	# 分隔线
	var separator1 = HSeparator.new()
	settings_vbox.add_child(separator1)
	
	# 自动交易开关
	auto_trade_checkbox = CheckBox.new()
	auto_trade_checkbox.text = "启用自动交易"
	auto_trade_checkbox.button_pressed = true
	auto_trade_checkbox.toggled.connect(_on_auto_trade_toggled)
	settings_vbox.add_child(auto_trade_checkbox)
	
	# 交易频率控制
	var freq_label = Label.new()
	freq_label.text = "交易频率（秒）:"
	settings_vbox.add_child(freq_label)
	
	var freq_hbox = HBoxContainer.new()
	settings_vbox.add_child(freq_hbox)
	
	trade_frequency_slider = HSlider.new()
	trade_frequency_slider.min_value = 10.0
	trade_frequency_slider.max_value = 60.0
	trade_frequency_slider.step = 5.0
	trade_frequency_slider.value = 20.0
	trade_frequency_slider.custom_minimum_size = Vector2(150, 0)
	trade_frequency_slider.value_changed.connect(_on_frequency_changed)
	freq_hbox.add_child(trade_frequency_slider)
	
	trade_frequency_label = Label.new()
	trade_frequency_label.text = "20s"
	trade_frequency_label.custom_minimum_size = Vector2(40, 0)
	freq_hbox.add_child(trade_frequency_label)
	
	# 分隔线
	var separator2 = HSeparator.new()
	settings_vbox.add_child(separator2)
	
	# 统计信息
	stats_label = Label.new()
	stats_label.text = "📊 交易统计:\n等待数据..."
	stats_label.add_theme_font_size_override("font_size", 12)
	settings_vbox.add_child(stats_label)

func _create_stats_timer():
	"""创建统计更新定时器"""
	stats_timer = Timer.new()
	stats_timer.wait_time = 2.0
	stats_timer.timeout.connect(_update_stats)
	add_child(stats_timer)
	stats_timer.start()

func _update_stats():
	"""更新统计显示"""
	if not scene_tracker:
		return
	
	var stats = scene_tracker.get_statistics_summary()
	
	var text = "📊 交易统计:\n"
	text += "💳 交易次数: %d\n" % stats.get("total_transactions", 0)
	text += "🤝 交互次数: %d\n" % stats.get("total_interactions", 0)
	text += "💰 总财富: ¥%.0f\n" % stats.get("total_wealth", 0)
	text += "📈 平均财富: ¥%.0f" % stats.get("average_wealth", 0)
	
	stats_label.text = text

func _on_auto_trade_toggled(enabled: bool):
	"""切换自动交易"""
	var ai_agents = get_tree().get_nodes_in_group("controllable_characters")
	
	for character in ai_agents:
		# 找到AIAgent子节点
		for child in character.get_children():
			if child is AIAgent:
				var ai_agent = child as AIAgent
				if ai_agent.economic_decision_timer:
					if enabled:
						ai_agent.economic_decision_timer.start()
						print("✅ 已启用 %s 的自动交易" % character.name)
					else:
						ai_agent.economic_decision_timer.stop()
						print("⏸️ 已暂停 %s 的自动交易" % character.name)
	
	if enabled:
		print("✅ 经济系统：自动交易已启用")
	else:
		print("⏸️ 经济系统：自动交易已暂停")

func _on_frequency_changed(value: float):
	"""调整交易频率"""
	trade_frequency_label.text = "%ds" % int(value)
	
	# 更新所有AI agent的经济决策频率
	var ai_agents = get_tree().get_nodes_in_group("controllable_characters")
	
	for character in ai_agents:
		for child in character.get_children():
			if child is AIAgent:
				var ai_agent = child as AIAgent
				if ai_agent.economic_decision_timer:
					ai_agent.economic_decision_timer.wait_time = value
					print("⏱️ 已调整 %s 的交易频率为 %ds" % [character.name, int(value)])
	
	print("⏱️ 经济系统：交易频率已调整为 %ds" % int(value))

## 显示/隐藏面板
func toggle_visibility():
	panel_container.visible = not panel_container.visible


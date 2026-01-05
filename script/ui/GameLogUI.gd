extends Control
class_name GameLogUI

## 游戏日志UI显示组件
## 实时显示交易、交互、事件等日志

# UI元素
var log_panel: PanelContainer
var log_text: RichTextLabel
var title_bar: HBoxContainer
var title_label: Label
var clear_button: Button
var toggle_button: Button
var close_button: Button

# 日志设置
var max_log_lines: int = 100  # 最大日志行数
var auto_scroll: bool = true  # 自动滚动到底部
var is_collapsed: bool = false  # 是否折叠

# 拖动相关
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var panel_start_position: Vector2 = Vector2.ZERO

# 日志颜色
var color_transaction: Color = Color.LIGHT_GREEN  # 交易
var color_interaction: Color = Color.LIGHT_BLUE   # 交互
var color_experiment: Color = Color.YELLOW        # 实验
var color_event: Color = Color.ORANGE             # 事件
var color_system: Color = Color.GRAY              # 系统
var color_error: Color = Color.RED                # 错误
var color_time: Color = Color.DIM_GRAY            # 时间戳

# 统计
var total_logs: int = 0
var transaction_count: int = 0
var interaction_count: int = 0

func _ready():
	_setup_ui()
	_connect_signals()
	_add_welcome_message()
	
	print("✅ GameLogUI: 游戏日志UI已初始化")

func _setup_ui():
	"""设置UI布局"""
	# 主面板
	log_panel = PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(400, 300)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # 确保可以点击
	add_child(log_panel)
	
	# 延迟设置位置（等待viewport准备好）
	call_deferred("_set_initial_position")
	
	# 垂直容器
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	log_panel.add_child(vbox)
	
	# 标题栏（添加背景以便拖动）
	var title_bar_bg = PanelContainer.new()
	title_bar_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(title_bar_bg)
	
	# 标题栏背景样式
	var title_bg_style = StyleBoxFlat.new()
	title_bg_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	title_bg_style.content_margin_left = 5
	title_bg_style.content_margin_right = 5
	title_bg_style.content_margin_top = 5
	title_bg_style.content_margin_bottom = 5
	title_bar_bg.add_theme_stylebox_override("panel", title_bg_style)
	
	# 标题栏容器
	title_bar = HBoxContainer.new()
	title_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	title_bar_bg.add_child(title_bar)
	
	# 拖动区域（不可见，用于接收鼠标事件）
	var drag_area = Control.new()
	drag_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_area.custom_minimum_size = Vector2(0, 30)
	drag_area.tooltip_text = "拖动以移动面板"
	drag_area.mouse_default_cursor_shape = Control.CURSOR_MOVE  # 显示移动光标
	drag_area.gui_input.connect(_on_title_bar_input)
	title_bar.add_child(drag_area)
	
	# 标题（在拖动区域上层显示）
	title_label = Label.new()
	title_label.text = "📜 交互日志"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 穿透到拖动区域
	
	# 使用MarginContainer来放置标题（覆盖在拖动区域上）
	var title_container = MarginContainer.new()
	title_container.add_theme_constant_override("margin_left", 5)
	title_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_container.add_child(title_label)
	drag_area.add_child(title_container)
	
	# 清空按钮
	clear_button = Button.new()
	clear_button.text = "🗑️"
	clear_button.custom_minimum_size = Vector2(32, 32)
	clear_button.tooltip_text = "清空日志"
	clear_button.mouse_filter = Control.MOUSE_FILTER_STOP
	clear_button.pressed.connect(_on_clear_pressed)
	title_bar.add_child(clear_button)
	
	# 折叠/展开按钮
	toggle_button = Button.new()
	toggle_button.text = "▼"
	toggle_button.custom_minimum_size = Vector2(32, 32)
	toggle_button.tooltip_text = "折叠/展开"
	toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_button.pressed.connect(_on_toggle_pressed)
	title_bar.add_child(toggle_button)
	
	# 关闭按钮
	close_button = Button.new()
	close_button.text = "✖"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.tooltip_text = "隐藏日志"
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(_on_close_pressed)
	title_bar.add_child(close_button)
	
	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS  # 允许滚动
	vbox.add_child(scroll)
	
	# 日志文本
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.fit_content = true
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.mouse_filter = Control.MOUSE_FILTER_STOP  # 可以选择文本
	scroll.add_child(log_text)
	
	# 应用样式
	_apply_style()

func _apply_style():
	"""应用样式"""
	# 面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.5, 0.7, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 5
	panel_style.content_margin_right = 5
	panel_style.content_margin_top = 5
	panel_style.content_margin_bottom = 5
	log_panel.add_theme_stylebox_override("panel", panel_style)
	
	# 日志文本样式
	log_text.add_theme_color_override("default_color", Color.WHITE)
	log_text.add_theme_font_size_override("normal_font_size", 12)

func _connect_signals():
	"""连接信号"""
	# 连接场景实验追踪器信号
	var scene_tracker = get_node_or_null("/root/SceneExperimentTracker")
	if scene_tracker:
		if scene_tracker.has_signal("wealth_changed"):
			scene_tracker.wealth_changed.connect(_on_wealth_changed)
		print("✅ 已连接场景实验追踪器")
	
	# 连接时间系统信号
	var time_system = get_node_or_null("/root/GameTimeSystem")
	if time_system:
		if time_system.has_signal("day_changed"):
			time_system.day_changed.connect(_on_day_changed)
		if time_system.has_signal("hour_changed"):
			time_system.hour_changed.connect(_on_hour_changed)
		print("✅ 已连接时间系统")

func _add_welcome_message():
	"""添加欢迎消息"""
	add_log("系统", "游戏日志系统已启动", "system")
	add_log("系统", "将显示所有交易、交互和事件记录", "system")

## 添加日志
func add_log(category: String, message: String, log_type: String = "event"):
	"""添加日志条目
	
	Args:
		category: 类别（如"交易"、"对话"等）
		message: 日志内容
		log_type: 日志类型（transaction/interaction/experiment/event/system/error）
	"""
	total_logs += 1
	
	# 获取颜色
	var log_color = _get_log_color(log_type)
	
	# 获取时间
	var time_str = _get_time_string()
	
	# 格式化日志
	var log_line = "[color=#%s]%s[/color] [color=#%s][%s][/color] %s\n" % [
		color_time.to_html(false),
		time_str,
		log_color.to_html(false),
		category,
		message
	]
	
	# 添加到日志文本
	log_text.append_text(log_line)
	
	# 限制日志行数
	_trim_logs()
	
	# 更新统计
	match log_type:
		"transaction":
			transaction_count += 1
		"interaction":
			interaction_count += 1
	
	# 自动滚动
	if auto_scroll:
		log_text.scroll_to_line(log_text.get_line_count())

func _get_log_color(log_type: String) -> Color:
	"""获取日志类型对应的颜色"""
	match log_type:
		"transaction":
			return color_transaction
		"interaction":
			return color_interaction
		"experiment":
			return color_experiment
		"event":
			return color_event
		"system":
			return color_system
		"error":
			return color_error
		_:
			return Color.WHITE

func _get_time_string() -> String:
	"""获取当前时间字符串"""
	var time_system = get_node_or_null("/root/GameTimeSystem")
	if time_system:
		return time_system.get_time_string()
	else:
		var time = Time.get_time_dict_from_system()
		return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

func _trim_logs():
	"""限制日志行数"""
	var line_count = log_text.get_line_count()
	if line_count > max_log_lines:
		# 获取所有文本
		var text = log_text.text
		var lines = text.split("\n")
		
		# 保留最后的max_log_lines行
		var keep_lines = lines.slice(line_count - max_log_lines, line_count)
		
		# 清空并重新添加
		log_text.clear()
		log_text.append_text("\n".join(keep_lines))

## 信号回调

func _on_wealth_changed(agent_name: String, new_wealth: float):
	"""财富变化回调"""
	add_log("财富", "%s 的财富变为 ¥%.2f" % [agent_name, new_wealth], "transaction")

func _on_day_changed(new_day: int):
	"""天数变化回调"""
	add_log("时间", "新的一天开始！第%d天" % new_day, "event")

func _on_hour_changed(new_hour: int):
	"""小时变化回调"""
	var time_system = get_node_or_null("/root/GameTimeSystem")
	if time_system:
		var period = time_system.get_time_period()
		add_log("时间", "%02d:00 - %s" % [new_hour, period], "event")

func _on_clear_pressed():
	"""清空按钮"""
	log_text.clear()
	total_logs = 0
	transaction_count = 0
	interaction_count = 0
	add_log("系统", "日志已清空", "system")

func _on_toggle_pressed():
	"""折叠/展开按钮"""
	is_collapsed = !is_collapsed
	
	if is_collapsed:
		log_panel.custom_minimum_size.y = 50
		toggle_button.text = "▲"
		log_text.visible = false
		clear_button.visible = false
	else:
		log_panel.custom_minimum_size.y = 300
		toggle_button.text = "▼"
		log_text.visible = true
		clear_button.visible = true

func _on_close_pressed():
	"""关闭按钮"""
	log_panel.visible = false
	print("📜 GameLogUI: 日志面板已隐藏")

func _set_initial_position():
	"""设置面板初始位置（左下角）"""
	var viewport_size = get_viewport_rect().size
	log_panel.position = Vector2(10, viewport_size.y - log_panel.custom_minimum_size.y - 10)

## 拖动处理

func _on_title_bar_input(event: InputEvent):
	"""标题栏输入事件处理"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# 开始拖动
				is_dragging = true
				drag_start_position = get_viewport().get_mouse_position()
				panel_start_position = log_panel.position
			else:
				# 结束拖动
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		# 拖动中
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta = current_mouse_pos - drag_start_position
		log_panel.position = panel_start_position + delta

## 公共方法

## 切换可见性
func toggle_visibility():
	"""切换日志面板的可见性"""
	log_panel.visible = !log_panel.visible
	if log_panel.visible:
		print("📜 GameLogUI: 日志面板已显示")
	else:
		print("📜 GameLogUI: 日志面板已隐藏")

## 显示面板
func show_panel():
	"""显示日志面板"""
	log_panel.visible = true

## 隐藏面板
func hide_panel():
	"""隐藏日志面板"""
	log_panel.visible = false

## 记录交易
func log_transaction(from_agent: String, to_agent: String, amount: float, reason: String = ""):
	"""记录交易"""
	var msg = "%s → %s: ¥%.2f" % [from_agent, to_agent, amount]
	if reason:
		msg += " (%s)" % reason
	add_log("💰交易", msg, "transaction")

## 记录交互
func log_interaction(agent1: String, agent2: String, interaction_type: String, details: String = ""):
	"""记录交互"""
	var msg = "%s ↔ %s: %s" % [agent1, agent2, interaction_type]
	if details:
		msg += " - %s" % details
	add_log("🤝交互", msg, "interaction")

## 记录对话
func log_dialog(speaker: String, listener: String, topic: String = ""):
	"""记录对话"""
	var msg = "%s 与 %s 对话" % [speaker, listener]
	if topic:
		msg += " (主题: %s)" % topic
	add_log("💬对话", msg, "interaction")

## 记录实验
func log_experiment(experiment_type: String, participants: Array, result: String = ""):
	"""记录实验"""
	var msg = "%s 实验 - 参与者: %s" % [experiment_type, ", ".join(participants)]
	if result:
		msg += " | %s" % result
	add_log("🔬实验", msg, "experiment")

## 记录事件
func log_event(event_name: String, description: String = ""):
	"""记录事件"""
	var msg = event_name
	if description:
		msg += ": %s" % description
	add_log("📌事件", msg, "event")

## 记录错误
func log_error(error_message: String):
	"""记录错误"""
	add_log("❌错误", error_message, "error")

## 设置位置预设
func set_position_preset(preset: String):
	"""设置UI位置"""
	match preset:
		"bottom_left":
			log_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			log_panel.position = Vector2(10, -310)
		"bottom_right":
			log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			log_panel.position = Vector2(-410, -310)
		"top_left":
			log_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
			log_panel.position = Vector2(10, 60)
		"top_right":
			log_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			log_panel.position = Vector2(-410, 60)

## 显示/隐藏
func show_log():
	"""显示日志"""
	visible = true

func hide_log():
	"""隐藏日志"""
	visible = false

func toggle_log():
	"""切换显示"""
	visible = !visible

## 获取统计
func get_statistics() -> Dictionary:
	"""获取日志统计"""
	return {
		"total_logs": total_logs,
		"transaction_count": transaction_count,
		"interaction_count": interaction_count,
		"current_lines": log_text.get_line_count()
	}

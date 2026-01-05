extends Control
class_name LabDashboardUI

## 场景实验监控面板
## 实时显示主游戏场景中所有agent的状态
## 追踪财富变化、心理状态、交互记录

signal dashboard_closed  # 当仪表板关闭时发出信号

@onready var status_panel = $MarginContainer/VBoxContainer/ContentHBox/LeftPanel/StatusPanelContainer/StatusPanel
@onready var quick_experiment_button = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/ActionPanel/QuickExperimentButton
@onready var view_report_button = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/ActionPanel/ViewReportButton
@onready var agent_wealth_list = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/AgentWealthPanelContainer/AgentWealthPanel/WealthList
@onready var daily_goals_panel = $MarginContainer/VBoxContainer/ContentHBox/LeftPanel/DailyGoalsPanelContainer/DailyGoalsPanel
@onready var notification_label = $MarginContainer/VBoxContainer/NotificationLabel

var scene_tracker: SceneExperimentTracker  # 场景实验追踪器
var close_button: Button

# 经济控制UI元素
var auto_trade_checkbox: CheckBox
var trade_frequency_slider: HSlider
var trade_frequency_label: Label

func _ready():
	# 应用统一主题样式
	_apply_lab_theme()
	
	# 延迟添加关闭按钮
	call_deferred("_add_close_button")
	
	# 设置经济控制UI
	call_deferred("_setup_economic_controls")
	
	# 获取场景实验追踪器
	scene_tracker = get_node_or_null("/root/SceneExperimentTracker")
	if not scene_tracker:
		print("⚠️ 场景实验追踪器未找到，将创建新实例")
		scene_tracker = SceneExperimentTracker.new()
		scene_tracker.name = "SceneExperimentTracker"
		get_tree().root.call_deferred("add_child", scene_tracker)
	
	# 修改按钮文本
	if quick_experiment_button:
		quick_experiment_button.text = "📊 生成报告"
		quick_experiment_button.pressed.connect(_on_generate_report)
	
	if view_report_button:
		view_report_button.text = "📁 打开报告文件夹"
		view_report_button.pressed.connect(_on_open_reports_folder)
	
	# 连接追踪器信号
	call_deferred("_connect_tracker_signals")
	
	# 初始化显示
	call_deferred("_update_display")
	
	# 定期更新
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_update_display)
	call_deferred("add_child", timer)
	await get_tree().process_frame
	timer.start()

func _connect_tracker_signals():
	"""连接场景追踪器信号"""
	if scene_tracker:
		scene_tracker.wealth_changed.connect(_on_wealth_changed)
		scene_tracker.report_generated.connect(_on_report_generated)

func _update_display():
	if not scene_tracker:
		return
	
	var stats = scene_tracker.get_statistics_summary()
	
	# 更新状态面板
	_update_status_panel(stats)
	
	# 更新财富榜
	_update_wealth_leaderboard()

func _update_status_panel(stats: Dictionary):
	if not status_panel:
		return
	
	var text = ""
	text += "📅 第 %d 天 | 场景实验\n" % stats.get("scene_day", 1)
	text += "⏱️ 运行时间: %s\n" % stats.get("running_time_formatted", "0秒")
	text += "💰 总财富: ¥%.2f\n" % stats.get("total_wealth", 0.0)
	text += "📊 平均财富: ¥%.2f\n" % stats.get("average_wealth", 0.0)
	text += "🤝 交互次数: %d 次\n" % stats.get("total_interactions", 0)
	text += "💳 交易次数: %d 次\n" % stats.get("total_transactions", 0)
	text += "👥 追踪Agent: %d 个" % stats.get("total_agents", 0)
	
	if status_panel is Label:
		status_panel.text = text
	elif status_panel.has_node("StatusLabel"):
		status_panel.get_node("StatusLabel").text = text

func _update_wealth_leaderboard():
	if not agent_wealth_list or not scene_tracker:
		return
	
	agent_wealth_list.clear()
	
	var leaderboard = scene_tracker.get_wealth_leaderboard()
	for i in range(min(8, leaderboard.size())):
		var entry = leaderboard[i]
		var medal = ""
		match i:
			0: medal = "🥇 "
			1: medal = "🥈 "
			2: medal = "🥉 "
			_: medal = "   "
		
		var psych = entry.get("psychological_state", {})
		var mood_icon = _get_mood_icon(psych.get("mood", 0.5))
		
		var text = "%s%s: ¥%.2f %s" % [medal, entry.name, entry.wealth, mood_icon]
		agent_wealth_list.add_item(text)

func _get_mood_icon(mood: float) -> String:
	"""根据心情值返回表情图标"""
	if mood >= 0.8:
		return "😊"
	elif mood >= 0.6:
		return "🙂"
	elif mood >= 0.4:
		return "😐"
	elif mood >= 0.2:
		return "😟"
	else:
		return "😢"

func _on_generate_report():
	"""生成当前场景的实验报告"""
	if not scene_tracker:
		_show_notification("⚠️ 场景追踪器未初始化")
		return
	
	var report_path = scene_tracker.generate_scene_report()
	_show_notification("📊 场景报告已生成！")
	print("✅ 场景报告已生成: %s" % report_path)

func _on_open_reports_folder():
	"""打开报告文件夹"""
	var reports_path = "user://experiment_reports"
	var absolute_path = ProjectSettings.globalize_path(reports_path)
	
	# 确保目录存在
	if not DirAccess.dir_exists_absolute(reports_path):
		DirAccess.make_dir_absolute(reports_path)
	
	# 尝试打开文件夹
	OS.shell_open(absolute_path)
	_show_notification("📁 已打开报告文件夹")

func _on_wealth_changed(agent_name: String, new_wealth: float):
	"""财富变化回调"""
	# 刷新显示
	_update_display()

func _on_report_generated(report_path: String):
	"""报告生成回调"""
	_show_notification("📊 自动报告已生成")


func _show_report_dialog(report: String):
	var dialog = AcceptDialog.new()
	dialog.title = "场景实验日报"
	dialog.dialog_text = report
	dialog.size = Vector2(600, 400)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())

func _on_daily_goal_completed():
	_show_notification("🎉 所有每日目标完成！")

func _on_achievement_earned(achievement: String):
	var message = "🏆 成就解锁: " + _translate_achievement(achievement)
	_show_notification(message)

func _translate_achievement(achievement: String) -> String:
	match achievement:
		"first_experiment": return "第一个实验"
		"win_win": return "双赢结局"
		"perfect_trust": return "完美信任"
		"nobel_candidate": return "诺贝尔候选人"
		_: return achievement

func _show_notification(message: String):
	if notification_label:
		notification_label.text = message
		notification_label.modulate.a = 1.0
		
		# 淡出动画
		var tween = create_tween()
		tween.tween_interval(3.0)
		tween.tween_property(notification_label, "modulate:a", 0.0, 1.0)
	
	print("[通知] " + message)

func _add_close_button():
	"""添加关闭按钮到右上角"""
	if close_button:
		return  # 已经添加过了
	
	close_button = Button.new()
	close_button.text = "✖ 关闭"
	close_button.custom_minimum_size = Vector2(80, 40)
	close_button.tooltip_text = "关闭场景实验"
	
	# 定位到右上角
	close_button.position = Vector2(size.x - 100, 10)
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.anchor_top = 0.0
	close_button.offset_left = -100
	close_button.offset_right = -10
	close_button.offset_top = 10
	close_button.offset_bottom = 50
	
	# 连接信号
	close_button.pressed.connect(_on_close_pressed)
	
	add_child(close_button)
	
	# 移到最上层
	move_child(close_button, get_child_count() - 1)
	
	print("✅ 关闭按钮已添加到场景实验")

func _on_close_pressed():
	"""关闭按钮点击处理"""
	visible = false
	dashboard_closed.emit()  # 发送关闭信号
	print("✅ 场景实验已关闭")

func _add_close_button_to_panel(panel: Control, canvas_layer: CanvasLayer):
	"""为快速实验面板添加关闭按钮"""
	# 应用统一主题到快速面板
	_apply_lab_theme_to_panel(panel)
	
	var panel_close_btn = Button.new()
	panel_close_btn.text = "✖ 关闭"
	panel_close_btn.custom_minimum_size = Vector2(80, 32)
	panel_close_btn.tooltip_text = "关闭快速实验面板"
	
	# 使用锚点定位到右上角
	panel_close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel_close_btn.offset_left = -90  # 从右边偏移
	panel_close_btn.offset_right = -10
	panel_close_btn.offset_top = 10
	panel_close_btn.offset_bottom = 42
	
	# 确保按钮在最上层
	panel_close_btn.z_index = 10
	panel_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接关闭信号
	panel_close_btn.pressed.connect(func():
		canvas_layer.queue_free()  # 删除整个CanvasLayer
		print("✅ 快速实验面板已关闭")
	)
	
	panel.add_child(panel_close_btn)
	panel.move_child(panel_close_btn, panel.get_child_count() - 1)

func _apply_lab_theme():
	"""应用场景实验主题样式到当前面板"""
	# 尝试加载现有主题
	var theme_path = "res://panel_container_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
		print("✅ 场景实验主题已加载")
	else:
		# 创建自定义样式
		_create_custom_lab_style()

func _apply_lab_theme_to_panel(panel: Control):
	"""应用场景实验主题到快速实验面板"""
	# 尝试加载现有主题
	var theme_path = "res://panel_container_theme.tres"
	if ResourceLoader.exists(theme_path):
		panel.theme = load(theme_path)
	else:
		# 应用自定义样式
		_apply_custom_style_to_panel(panel)

func _create_custom_lab_style():
	"""创建自定义场景实验样式"""
	var custom_theme = Theme.new()
	
	# Panel样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.094, 0.11, 0.18, 0.86)  # 深蓝色半透明
	panel_style.border_color = Color(0.2, 0.6, 0.9, 0.5)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	
	custom_theme.set_stylebox("panel", "PanelContainer", panel_style)
	custom_theme.set_stylebox("panel", "Panel", panel_style)
	
	theme = custom_theme
	print("✅ 自定义场景实验主题已创建")

func _setup_economic_controls():
	"""设置经济控制UI - 替换DailyGoalsPanel"""
	if not daily_goals_panel:
		return
	
	# 清空原有内容
	daily_goals_panel.text = ""
	
	# 获取DailyGoalsPanelContainer的父容器
	var goals_container = daily_goals_panel.get_parent()
	if not goals_container:
		return
	
	# 移除Label，创建VBoxContainer
	daily_goals_panel.queue_free()
	
	var econ_vbox = VBoxContainer.new()
	econ_vbox.add_theme_constant_override("separation", 10)
	goals_container.add_child(econ_vbox)
	
	# 标题
	var title = Label.new()
	title.text = "💰 经济系统控制"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	econ_vbox.add_child(title)
	
	# 分隔线
	var sep1 = HSeparator.new()
	econ_vbox.add_child(sep1)
	
	# 自动交易开关
	auto_trade_checkbox = CheckBox.new()
	auto_trade_checkbox.text = "✅ 启用自动交易"
	auto_trade_checkbox.button_pressed = true
	auto_trade_checkbox.toggled.connect(_on_auto_trade_toggled)
	econ_vbox.add_child(auto_trade_checkbox)
	
	# 交易频率标签
	var freq_label = Label.new()
	freq_label.text = "⏱️ 交易频率（秒）:"
	freq_label.add_theme_font_size_override("font_size", 13)
	econ_vbox.add_child(freq_label)
	
	# 频率滑块容器
	var freq_hbox = HBoxContainer.new()
	econ_vbox.add_child(freq_hbox)
	
	trade_frequency_slider = HSlider.new()
	trade_frequency_slider.min_value = 10.0
	trade_frequency_slider.max_value = 60.0
	trade_frequency_slider.step = 5.0
	trade_frequency_slider.value = 20.0
	trade_frequency_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_frequency_slider.value_changed.connect(_on_frequency_changed)
	freq_hbox.add_child(trade_frequency_slider)
	
	trade_frequency_label = Label.new()
	trade_frequency_label.text = "20s"
	trade_frequency_label.custom_minimum_size = Vector2(45, 0)
	trade_frequency_label.add_theme_font_size_override("font_size", 14)
	trade_frequency_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	freq_hbox.add_child(trade_frequency_label)
	
	# 分隔线
	var sep2 = HSeparator.new()
	econ_vbox.add_child(sep2)
	
	# 说明文本
	var info_label = Label.new()
	info_label.text = "💡 提示:\n• Agent将根据个性自主交易\n• 低频率=更谨慎决策\n• 高频率=更活跃市场"
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color.GRAY)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	econ_vbox.add_child(info_label)
	
	print("✅ 经济控制UI已添加到场景实验")

func _on_auto_trade_toggled(enabled: bool):
	"""切换自动交易"""
	var ai_agents = get_tree().get_nodes_in_group("controllable_characters")
	
	for character in ai_agents:
		# 找到AIAgent子节点
		for child in character.get_children():
			if child.get_script() and child.get_script().get_global_name() == "AIAgent":
				if child.has("economic_decision_timer"):
					if enabled:
						child.economic_decision_timer.start()
						print("✅ 已启用 %s 的自动交易" % character.name)
					else:
						child.economic_decision_timer.stop()
						print("⏸️ 已暂停 %s 的自动交易" % character.name)
	
	if enabled:
		_show_notification("✅ 自动交易已启用")
		if auto_trade_checkbox:
			auto_trade_checkbox.text = "✅ 启用自动交易"
	else:
		_show_notification("⏸️ 自动交易已暂停")
		if auto_trade_checkbox:
			auto_trade_checkbox.text = "⏸️ 启用自动交易"

func _on_frequency_changed(value: float):
	"""调整交易频率"""
	if trade_frequency_label:
		trade_frequency_label.text = "%ds" % int(value)
	
	# 更新所有AI agent的经济决策频率
	var ai_agents = get_tree().get_nodes_in_group("controllable_characters")
	
	for character in ai_agents:
		for child in character.get_children():
			if child.get_script() and child.get_script().get_global_name() == "AIAgent":
				if child.has("economic_decision_timer"):
					child.economic_decision_timer.wait_time = value
	
	print("⏱️ 经济系统：交易频率已调整为 %ds" % int(value))

func _apply_custom_style_to_panel(panel: Control):
	"""应用自定义样式到面板"""
	var panel_container = panel.get_node_or_null("PanelContainer")
	if panel_container:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.094, 0.11, 0.18, 0.86)
		panel_style.border_color = Color(0.2, 0.6, 0.9, 0.5)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
		
		panel_container.add_theme_stylebox_override("panel", panel_style)
		print("✅ 快速面板样式已应用")

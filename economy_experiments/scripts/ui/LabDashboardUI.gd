extends Control
class_name LabDashboardUI

## 实验室主仪表板UI
## 集成了实验控制、状态显示、数据分析

signal dashboard_closed  # 新增：当仪表板关闭时发出信号

@onready var status_panel = $MarginContainer/VBoxContainer/ContentHBox/LeftPanel/StatusPanelContainer/StatusPanel
@onready var quick_experiment_button = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/ActionPanel/QuickExperimentButton
@onready var view_report_button = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/ActionPanel/ViewReportButton
@onready var agent_wealth_list = $MarginContainer/VBoxContainer/ContentHBox/RightPanel/AgentWealthPanelContainer/AgentWealthPanel/WealthList
@onready var daily_goals_panel = $MarginContainer/VBoxContainer/ContentHBox/LeftPanel/DailyGoalsPanelContainer/DailyGoalsPanel
@onready var notification_label = $MarginContainer/VBoxContainer/NotificationLabel

var lab_manager: ExperimentLabManager
var experiment_manager: ExperimentManager
var close_button: Button

func _ready():
	# 应用统一主题样式
	_apply_lab_theme()
	
	# 延迟添加关闭按钮，避免在父节点设置子节点时添加
	call_deferred("_add_close_button")
	
	# 获取或创建实验室管理器
	lab_manager = get_node_or_null("/root/ExperimentLabManager")
	if not lab_manager:
		lab_manager = ExperimentLabManager.new()
		lab_manager.name = "ExperimentLabManager"
		get_tree().root.call_deferred("add_child", lab_manager)
	
	# 连接信号
	quick_experiment_button.pressed.connect(_on_quick_experiment)
	view_report_button.pressed.connect(_on_view_report)
	
	# 延迟连接实验室管理器的信号，确保它已经添加到场景树
	call_deferred("_connect_lab_manager_signals")
	
	# 初始化显示
	call_deferred("_update_display")
	
	# 定期更新
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_update_display)
	call_deferred("add_child", timer)
	await get_tree().process_frame
	timer.start()

func _connect_lab_manager_signals():
	"""延迟连接实验室管理器信号"""
	if lab_manager:
		lab_manager.daily_goal_completed.connect(_on_daily_goal_completed)
		lab_manager.achievement_earned.connect(_on_achievement_earned)

func _update_display():
	if not lab_manager:
		return
	
	var status = lab_manager.get_status_summary()
	
	# 更新状态面板
	_update_status_panel(status)
	
	# 更新财富榜
	_update_wealth_leaderboard()
	
	# 更新每日目标
	_update_daily_goals(status.daily_goals)

func _update_status_panel(status: Dictionary):
	if not status_panel:
		return
	
	var text = ""
	text += "📅 第 %d 天 | Lv.%d 研究员\n" % [status.day, status.level]
	text += "💰 经费: ¥%.2f\n" % status.funding
	text += "🧪 总实验: %d 次\n" % status.total_experiments
	text += "📊 总数据: %d 条\n" % status.total_data
	
	if status_panel is Label:
		status_panel.text = text
	elif status_panel.has_node("StatusLabel"):
		status_panel.get_node("StatusLabel").text = text

func _update_wealth_leaderboard():
	if not agent_wealth_list or not lab_manager:
		return
	
	agent_wealth_list.clear()
	
	var leaderboard = lab_manager.get_wealth_leaderboard()
	for i in range(min(8, leaderboard.size())):
		var agent = leaderboard[i]
		var medal = ""
		match i:
			0: medal = "🥇 "
			1: medal = "🥈 "
			2: medal = "🥉 "
		
		var text = "%s%s: ¥%.2f" % [medal, agent.name, agent.wealth]
		agent_wealth_list.add_item(text)

func _update_daily_goals(goals: Dictionary):
	if not daily_goals_panel:
		return
	
	var text = "📋 今日目标:\n"
	for goal_key in goals.keys():
		var goal = goals[goal_key]
		var status_icon = "✅" if goal.current >= goal.target else "⬜"
		var goal_name = _translate_goal_name(goal_key)
		text += "%s %s: %d/%d\n" % [status_icon, goal_name, goal.current, goal.target]
	
	if daily_goals_panel is Label:
		daily_goals_panel.text = text
	elif daily_goals_panel.has_node("GoalsLabel"):
		daily_goals_panel.get_node("GoalsLabel").text = text

func _translate_goal_name(key: String) -> String:
	match key:
		"experiments": return "完成实验"
		"data_points": return "收集数据"
		"special_events": return "特殊发现"
		_: return key

func _on_quick_experiment():
	# 创建CanvasLayer确保在最上层
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128  # 使用更高的层级确保在最上面
	canvas_layer.name = "QuickExperimentLayer"
	get_tree().root.add_child(canvas_layer)
	
	# 创建半透明背景遮罩（可选，帮助阻挡底层点击）
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)  # 半透明黑色
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻挡底层点击
	canvas_layer.add_child(background)
	
	# 打开快速实验面板
	var quick_panel = load("res://economy_experiments/scene/ExperimentQuickPanel.tscn").instantiate()
	
	# 使用锚点居中，而不是position
	quick_panel.set_anchors_preset(Control.PRESET_CENTER)
	quick_panel.position = Vector2.ZERO  # 重置position
	
	# 设置面板大小（如果需要）
	if quick_panel.custom_minimum_size == Vector2.ZERO:
		quick_panel.custom_minimum_size = Vector2(500, 350)
	
	# 使用偏移来微调位置（居中）
	quick_panel.offset_left = -quick_panel.custom_minimum_size.x / 2
	quick_panel.offset_right = quick_panel.custom_minimum_size.x / 2
	quick_panel.offset_top = -quick_panel.custom_minimum_size.y / 2
	quick_panel.offset_bottom = quick_panel.custom_minimum_size.y / 2
	
	# 确保可以接收鼠标事件
	quick_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	quick_panel.z_index = 100  # 确保在前面
	
	# 添加到CanvasLayer
	canvas_layer.add_child(quick_panel)
	
	# 连接背景点击关闭（可选）
	background.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 点击背景关闭面板
			canvas_layer.queue_free()
			print("✅ 快速实验面板已关闭（点击背景）")
	)
	
	# 添加关闭按钮
	_add_close_button_to_panel(quick_panel, canvas_layer)
	
	# 连接实验完成信号
	if quick_panel.has_signal("experiment_state_changed"):
		quick_panel.experiment_state_changed.connect(_on_experiment_state_changed)
	if quick_panel.has_signal("experiment_completed"):
		quick_panel.experiment_completed.connect(_on_experiment_completed_with_results)
	
	print("✅ 快速实验面板已创建在层级 128，居中显示")

func _on_experiment_state_changed(is_running: bool):
	if not is_running:
		# 实验完成
		_show_notification("✅ 实验完成！")
		# 刷新显示
		_update_display()

func _on_experiment_completed_with_results(results: Dictionary):
	"""处理实验完成并接收结果"""
	print("LabDashboardUI: 收到实验结果，包含 %d 个agent的wallet数据" % results.get("wallets", {}).size())
	
	# 显示实验统计
	var stats = results.get("statistics", {})
	var message = "✅ 实验完成！游戏: %d, 决策: %d" % [
		stats.get("games_played", 0),
		stats.get("total_decisions", 0)
	]
	_show_notification(message)
	
	# 立即刷新显示以更新财富榜
	_update_display()

func _on_view_report():
	# 生成并显示报告
	var report = lab_manager.generate_daily_report()
	_show_report_dialog(report)

func _show_report_dialog(report: String):
	var dialog = AcceptDialog.new()
	dialog.title = "实验室日报"
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
	close_button.tooltip_text = "关闭实验室模式"
	
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
	
	print("✅ 关闭按钮已添加到实验室模式")

func _on_close_pressed():
	"""关闭按钮点击处理"""
	visible = false
	dashboard_closed.emit()  # 发送关闭信号
	print("✅ 实验室模式已关闭")

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
	"""应用实验室主题样式到当前面板"""
	# 尝试加载现有主题
	var theme_path = "res://panel_container_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
		print("✅ 实验室主题已加载")
	else:
		# 创建自定义样式
		_create_custom_lab_style()

func _apply_lab_theme_to_panel(panel: Control):
	"""应用实验室主题到快速实验面板"""
	# 尝试加载现有主题
	var theme_path = "res://panel_container_theme.tres"
	if ResourceLoader.exists(theme_path):
		panel.theme = load(theme_path)
	else:
		# 应用自定义样式
		_apply_custom_style_to_panel(panel)

func _create_custom_lab_style():
	"""创建自定义实验室样式"""
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
	print("✅ 自定义实验室主题已创建")

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

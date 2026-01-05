extends Control
class_name GameTimeUI

## 游戏时间UI显示组件
## 显示当前游戏时间，支持时间控制

@onready var time_system: Node = null

# UI元素
var time_label: Label
var period_label: Label
var time_container: PanelContainer  # 添加面板容器引用
var control_panel: Control
var pause_button: Button
var speed_button: Button
var speed_options: PopupMenu

# 时间流速选项
var speed_presets: Array = [0.5, 1.0, 2.0, 5.0, 10.0]
var current_speed_index: int = 1  # 默认1.0x

# 样式
var normal_color: Color = Color.WHITE
var paused_color: Color = Color.ORANGE_RED
var fast_color: Color = Color.LIGHT_GREEN

func _ready():
	# 获取时间系统
	time_system = get_node_or_null("/root/GameTimeSystem")
	if not time_system:
		push_error("GameTimeUI: GameTimeSystem not found!")
		return
	
	# 创建UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 初始更新
	_update_display()
	
	print("✅ GameTimeUI: 时间UI已初始化")

func _setup_ui():
	"""设置UI布局"""
	# 主容器 - VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	vbox.position = Vector2(10, 10)
	add_child(vbox)
	
	# 时间显示容器
	time_container = PanelContainer.new()
	vbox.add_child(time_container)
	
	var time_vbox = VBoxContainer.new()
	time_container.add_child(time_vbox)
	
	# 主时间标签
	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 24)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_vbox.add_child(time_label)
	
	# 时间段标签
	period_label = Label.new()
	period_label.add_theme_font_size_override("font_size", 14)
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_vbox.add_child(period_label)
	
	# 控制面板
	control_panel = HBoxContainer.new()
	vbox.add_child(control_panel)
	
	# 暂停/继续按钮
	pause_button = Button.new()
	pause_button.text = "⏸️"
	pause_button.custom_minimum_size = Vector2(40, 40)
	pause_button.tooltip_text = "暂停/继续时间"
	pause_button.pressed.connect(_on_pause_pressed)
	control_panel.add_child(pause_button)
	
	# 时间流速按钮
	speed_button = Button.new()
	speed_button.text = "1.0x"
	speed_button.custom_minimum_size = Vector2(60, 40)
	speed_button.tooltip_text = "调整时间流速"
	speed_button.pressed.connect(_on_speed_pressed)
	control_panel.add_child(speed_button)
	
	# 创建速度选项菜单
	_setup_speed_menu()
	
	# 应用样式
	_apply_style()

func _setup_speed_menu():
	"""设置时间流速选项菜单"""
	speed_options = PopupMenu.new()
	speed_options.name = "SpeedOptions"
	add_child(speed_options)
	
	for i in range(speed_presets.size()):
		var speed = speed_presets[i]
		speed_options.add_item("%.1fx" % speed, i)
	
	speed_options.id_pressed.connect(_on_speed_selected)

func _apply_style():
	"""应用样式"""
	# 设置时间标签样式
	time_label.add_theme_color_override("font_color", normal_color)
	
	# 设置面板样式
	if time_container:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
		# 分别设置每个边的宽度
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.5, 0.7, 1.0)
		# 分别设置每个角的圆角
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		time_container.add_theme_stylebox_override("panel", style)

func _connect_signals():
	"""连接时间系统信号"""
	if time_system:
		time_system.time_changed.connect(_on_time_changed)
		time_system.day_changed.connect(_on_day_changed)
		time_system.time_paused.connect(_on_time_paused)
		time_system.time_resumed.connect(_on_time_resumed)
		time_system.time_speed_changed.connect(_on_time_speed_changed)

func _update_display():
	"""更新显示"""
	if not time_system:
		return
	
	var stats = time_system.get_statistics()
	
	# 更新时间显示
	time_label.text = "📅 %s" % stats.time_string
	period_label.text = "%s (%s)" % [stats.time_period, stats.weekday]
	
	# 根据暂停状态更新颜色
	if stats.is_paused:
		time_label.add_theme_color_override("font_color", paused_color)
	elif stats.time_speed > 1.0:
		time_label.add_theme_color_override("font_color", fast_color)
	else:
		time_label.add_theme_color_override("font_color", normal_color)

func _on_time_changed(day: int, hour: int, minute: int):
	"""时间变化回调"""
	_update_display()

func _on_day_changed(new_day: int):
	"""天数变化回调"""
	# 可以在这里添加特殊效果，比如闪烁动画
	pass

func _on_time_paused():
	"""时间暂停回调"""
	pause_button.text = "▶️"
	pause_button.tooltip_text = "继续时间"
	_update_display()

func _on_time_resumed():
	"""时间恢复回调"""
	pause_button.text = "⏸️"
	pause_button.tooltip_text = "暂停时间"
	_update_display()

func _on_time_speed_changed(new_speed: float):
	"""时间流速变化回调"""
	speed_button.text = "%.1fx" % new_speed
	_update_display()

func _on_pause_pressed():
	"""暂停按钮点击"""
	if time_system:
		time_system.toggle_pause()

func _on_speed_pressed():
	"""时间流速按钮点击"""
	if speed_options:
		var button_pos = speed_button.global_position
		var button_size = speed_button.size
		speed_options.popup(Rect2(button_pos + Vector2(0, button_size.y), Vector2(100, 0)))

func _on_speed_selected(id: int):
	"""时间流速选择"""
	if time_system and id >= 0 and id < speed_presets.size():
		var speed = speed_presets[id]
		time_system.set_time_speed(speed)
		current_speed_index = id

## 设置位置
func set_position_preset(preset: String):
	"""设置UI位置预设"""
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	match preset:
		"top_left":
			vbox.position = Vector2(10, 10)
		"top_right":
			vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			vbox.position = Vector2(-200, 10)
		"top_center":
			vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
			vbox.position = Vector2(0, 10)

## 显示/隐藏控制面板
func set_controls_visible(visible: bool):
	"""显示或隐藏控制按钮"""
	if control_panel:
		control_panel.visible = visible

## 设置紧凑模式
func set_compact_mode(compact: bool):
	"""切换紧凑显示模式"""
	if compact:
		time_label.add_theme_font_size_override("font_size", 18)
		period_label.visible = false
		control_panel.visible = false
	else:
		time_label.add_theme_font_size_override("font_size", 24)
		period_label.visible = true
		control_panel.visible = true

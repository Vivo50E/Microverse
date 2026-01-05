extends Button

## 游戏内的实验入口按钮
## 用于从主游戏界面打开实验面板

var experiment_dashboard_scene = preload("res://economy_experiments/scene/ExperimentDashboardUI.tscn")
var quick_panel_scene = preload("res://economy_experiments/scene/ExperimentQuickPanel.tscn")

var dashboard_instance: Control = null
var quick_panel_instance: Control = null

enum PanelType {
	FULL_DASHBOARD,  # 完整仪表板
	QUICK_PANEL      # 快速面板
}

@export var panel_type: PanelType = PanelType.QUICK_PANEL
@export var button_text: String = "🧪 实验室"

func _ready():
	text = button_text
	pressed.connect(_on_pressed)

# 为面板添加关闭按钮
func _add_close_button_to_panel(panel: Control):
	# 创建关闭按钮
	var close_button = Button.new()
	close_button.text = "✖"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.tooltip_text = "关闭面板"
	
	# 定位到右上角
	close_button.position = Vector2(panel.size.x - 40, 8)
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.offset_left = -40
	close_button.offset_right = -8
	close_button.offset_top = 8
	close_button.offset_bottom = 40
	
	# 连接关闭信号
	close_button.pressed.connect(func():
		if panel_type == PanelType.QUICK_PANEL:
			if quick_panel_instance:
				quick_panel_instance.visible = false
		else:
			if dashboard_instance:
				dashboard_instance.get_parent().queue_free()  # 删除 CanvasLayer
				dashboard_instance = null
	)
	
	panel.add_child(close_button)
	
	# 移动到最上层
	panel.move_child(close_button, panel.get_child_count() - 1)

func _on_pressed():
	match panel_type:
		PanelType.FULL_DASHBOARD:
			_open_full_dashboard()
		PanelType.QUICK_PANEL:
			_open_quick_panel()

func _open_full_dashboard():
	if dashboard_instance:
		# 如果已经打开，关闭
		dashboard_instance.queue_free()
		dashboard_instance = null
	else:
		# 创建 CanvasLayer
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		canvas_layer.name = "ExperimentDashboardLayer"
		get_tree().root.add_child(canvas_layer)
		
		# 创建新实例
		dashboard_instance = experiment_dashboard_scene.instantiate()
		dashboard_instance.mouse_filter = Control.MOUSE_FILTER_STOP
		canvas_layer.add_child(dashboard_instance)
		
		# 添加关闭按钮
		_add_close_button_to_panel(dashboard_instance)
		
		print("✅ 实验仪表板已创建在层级 100")

func _open_quick_panel():
	if quick_panel_instance:
		# 切换显示/隐藏
		quick_panel_instance.visible = not quick_panel_instance.visible
	else:
		# 创建 CanvasLayer 确保在最上层
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100  # 很高的层级，确保在最上面
		canvas_layer.name = "ExperimentPanelLayer"
		get_tree().root.add_child(canvas_layer)
		
		# 创建快速面板
		quick_panel_instance = quick_panel_scene.instantiate()
		
		# 定位到屏幕右侧
		quick_panel_instance.position = Vector2(
			get_viewport().size.x - 420,
			20
		)
		
		# 确保可以接收鼠标事件
		quick_panel_instance.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 添加到 CanvasLayer
		canvas_layer.add_child(quick_panel_instance)
		
		# 添加关闭按钮
		_add_close_button_to_panel(quick_panel_instance)
		
		print("✅ 实验快速面板已创建在层级 100")


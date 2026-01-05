extends Node

## 自动初始化游戏日志UI
## 在场景加载时自动添加日志显示

func _ready():
	# 延迟执行，确保场景完全加载
	call_deferred("_add_game_log_ui")

func _add_game_log_ui():
	# 检查是否已存在日志UI
	var existing_layer = get_tree().root.get_node_or_null("GameLogLayer")
	if existing_layer:
		print("⚠️ 游戏日志UI已存在")
		return
	
	# 创建CanvasLayer（确保在最上层）
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "GameLogLayer"
	canvas_layer.layer = 105  # 高于时间UI(100)和经济面板(100)
	
	# 创建日志UI
	var log_ui_script = load("res://script/ui/GameLogUI.gd")
	if not log_ui_script:
		push_error("❌ 无法加载GameLogUI.gd")
		return
	
	var log_ui = log_ui_script.new()
	log_ui.name = "GameLogUI"
	log_ui.set_anchors_preset(Control.PRESET_FULL_RECT)  # 全屏铺开
	log_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 让空白区域不拦截鼠标
	
	# 添加到场景树
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(log_ui)
	
	# 连接到全局访问
	_setup_global_logging(log_ui)
	
	print("✅ 游戏日志UI已添加到场景 (CanvasLayer: %d)" % canvas_layer.layer)

func _setup_global_logging(log_ui: Node):
	"""设置全局日志访问"""
	# 可以将日志UI设置为全局单例或提供便捷访问方法
	pass


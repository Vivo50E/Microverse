extends Node

## 自动初始化时间UI
## 在场景加载时自动添加时间显示

func _ready():
	# 延迟执行，确保场景完全加载
	call_deferred("_add_time_ui")

func _add_time_ui():
	# 检查是否已存在时间UI
	var existing_ui = get_tree().root.get_node_or_null("GameTimeUI")
	if existing_ui:
		print("⚠️ 时间UI已存在")
		return
	
	# 检查GameTimeSystem是否存在
	var time_system = get_node_or_null("/root/GameTimeSystem")
	if not time_system:
		print("❌ GameTimeSystem未找到！请在项目设置中添加为自动加载")
		print("   路径: res://script/GameTimeSystem.gd")
		print("   名称: GameTimeSystem")
		return
	
	# 创建时间UI
	var time_ui_script = load("res://script/ui/GameTimeUI.gd")
	if not time_ui_script:
		push_error("❌ 无法加载GameTimeUI.gd")
		return
	
	var time_ui = time_ui_script.new()
	time_ui.name = "GameTimeUI"
	
	# 添加到根节点
	get_tree().root.call_deferred("add_child", time_ui)
	
	# 等待一帧后设置位置
	await get_tree().process_frame
	if time_ui.has_method("set_position_preset"):
		time_ui.set_position_preset("top_right")
	
	print("✅ 时间UI已添加到场景")


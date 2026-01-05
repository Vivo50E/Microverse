extends Node

## 初始化经济控制面板
## 自动加载脚本，用于创建和管理经济控制UI

var economic_panel: EconomicControlPanel

func _ready():
	# 等待场景树准备好
	await get_tree().process_frame
	
	# 创建经济控制面板
	economic_panel = EconomicControlPanel.new()
	economic_panel.name = "EconomicControlPanel"
	
	# 添加到根节点的CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "EconomicPanelLayer"
	canvas_layer.layer = 100  # 确保在最上层
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(economic_panel)
	
	print("✅ InitializeEconomicPanel: 经济控制面板已创建")

## 切换面板可见性
func toggle_panel():
	if economic_panel:
		economic_panel.toggle_visibility()


extends Control
class_name ExperimentMonitorPanel

## 实时实验监控面板
## 显示实验进行中的详细信息

@onready var agent_grid: GridContainer = $ScrollContainer/VBox/AgentsSection/AgentGrid
@onready var game_log: RichTextLabel = $ScrollContainer/VBox/GamesSection/GameLog
@onready var wealth_chart: Control = $ScrollContainer/VBox/MetricsSection/WealthChart
@onready var event_counter: Label = $ScrollContainer/VBox/StatusSection/EventCounter

var experiment_manager: ExperimentManager
var update_timer: float = 0.0
var update_interval: float = 1.0  # 每秒更新一次

func _ready():
	pass

func connect_to_experiment(manager: ExperimentManager):
	experiment_manager = manager
	
	# 连接信号
	if experiment_manager:
		experiment_manager.agent_created.connect(_on_agent_created)

func _process(delta: float):
	if not experiment_manager or experiment_manager.state != ExperimentManager.ExperimentState.RUNNING:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()

func _update_display():
	_update_agents()
	_update_game_log()
	_update_event_counter()

func _update_agents():
	# 清空现有显示
	for child in agent_grid.get_children():
		child.queue_free()
	
	# 为每个代理创建显示卡片
	for agent_id in experiment_manager.economic_agents.keys():
		var agent = experiment_manager.economic_agents[agent_id]
		var card = _create_agent_card(agent_id, agent)
		agent_grid.add_child(card)

func _create_agent_card(agent_id: String, agent: EconomicAgent) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 100)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# 名称
	var name_label = Label.new()
	name_label.text = agent_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# 财富
	var balance_label = Label.new()
	balance_label.text = "💰 %.2f" % agent.wallet.balance
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(balance_label)
	
	# 状态
	var status_label = Label.new()
	status_label.text = "活跃"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	vbox.add_child(status_label)
	
	return panel

func _update_game_log():
	# 显示最近完成的游戏
	game_log.clear()
	
	var recent_games = experiment_manager.completed_games.slice(-5)  # 最近5个
	for game in recent_games:
		var game_type = game.game_type if game.has("game_type") else "unknown"
		var timestamp = Time.get_datetime_string_from_system()
		game_log.append_text("[%s] %s 完成\n" % [timestamp, game_type])

func _update_event_counter():
	var status = experiment_manager.get_status()
	event_counter.text = "事件: %d | 活跃游戏: %d | 已完成: %d" % [
		status.get("scheduled_events", 0),
		status.get("active_games", 0),
		status.get("completed_games", 0)
	]

func _on_agent_created(agent_name: String):
	print("新代理创建: ", agent_name)
	_update_agents()


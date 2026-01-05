extends Window
class_name GameExperimentPanel

## 游戏内实验控制面板
## 允许在正常游戏模式下运行经济实验

# 导入实验系统类
const ExperimentManager = preload("res://economy_experiments/scripts/managers/ExperimentManager.gd")
const EconomicAgent = preload("res://economy_experiments/scripts/economic_system/EconomicAgent.gd")
const GameBase = preload("res://economy_experiments/scripts/behavioral_games/GameBase.gd")
const TrustGame = preload("res://economy_experiments/scripts/behavioral_games/TrustGame.gd")
const UltimatumGame = preload("res://economy_experiments/scripts/behavioral_games/UltimatumGame.gd")
const PublicGoodsGame = preload("res://economy_experiments/scripts/behavioral_games/PublicGoodsGame.gd")
const DictatorGame = preload("res://economy_experiments/scripts/behavioral_games/DictatorGame.gd")

# UI节点
var experiment_type_selector: OptionButton
var agent_selector: ItemList
var rounds_spinbox: SpinBox
var endowment_spinbox: SpinBox
var multiplier_spinbox: SpinBox
var start_button: Button
var status_label: Label
var results_text: RichTextLabel
var log_text: RichTextLabel  # 新增：日志显示
var pause_game_checkbox: CheckBox  # 新增：暂停游戏选项

# 实验管理
var experiment_manager: ExperimentManager
var game_economic_agents: Dictionary = {}  # character_name -> EconomicAgent
var is_running: bool = false
var current_games: Array = []  # 当前运行的游戏列表
var game_was_paused: bool = false  # 记录游戏原本是否暂停
var experiment_start_time: float = 0.0  # 实验开始时间戳
var current_experiment_type: String = ""  # 当前实验类型
var current_experiment_config: Dictionary = {}  # 当前实验配置

# 实验类型配置
var experiment_configs: Dictionary = {
	"trust": {
		"name": "信任游戏",
		"required_players": 2,
		"params": ["rounds", "endowment", "multiplier"]
	},
	"ultimatum": {
		"name": "最后通牒游戏",
		"required_players": 2,
		"params": ["rounds", "endowment"]
	},
	"public_goods": {
		"name": "公共物品游戏",
		"required_players": 4,
		"params": ["rounds", "endowment", "multiplier"]
	},
	"dictator": {
		"name": "独裁者游戏",
		"required_players": 2,
		"params": ["rounds", "endowment"]
	}
}

func _ready():
	title = "🧪 游戏实验控制台"
	size = Vector2(900, 700)  # 增大窗口以容纳日志
	popup_window = false
	
	_create_ui()
	_initialize_experiment_manager()
	_load_game_characters()
	
	print("✅ 游戏实验控制面板已初始化")

func _create_ui():
	"""创建UI布局"""
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)
	
	# 标题
	var title_label = Label.new()
	title_label.text = "游戏内经济实验"
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)
	
	# 实验类型选择
	var type_hbox = HBoxContainer.new()
	vbox.add_child(type_hbox)
	
	var type_label = Label.new()
	type_label.text = "实验类型:"
	type_label.custom_minimum_size = Vector2(100, 0)
	type_hbox.add_child(type_label)
	
	experiment_type_selector = OptionButton.new()
	for exp_type in experiment_configs.keys():
		var config = experiment_configs[exp_type]
		experiment_type_selector.add_item(config.name)
		experiment_type_selector.set_item_metadata(experiment_type_selector.get_item_count() - 1, exp_type)
	experiment_type_selector.selected = 0
	experiment_type_selector.item_selected.connect(_on_experiment_type_changed)
	type_hbox.add_child(experiment_type_selector)
	
	# 参与者选择
	var agent_label = Label.new()
	agent_label.text = "选择参与者（多选）:"
	vbox.add_child(agent_label)
	
	agent_selector = ItemList.new()
	agent_selector.custom_minimum_size = Vector2(0, 150)
	agent_selector.select_mode = ItemList.SELECT_MULTI
	agent_selector.allow_reselect = true
	vbox.add_child(agent_selector)
	
	# 参数设置
	var params_label = Label.new()
	params_label.text = "实验参数:"
	vbox.add_child(params_label)
	
	var params_grid = GridContainer.new()
	params_grid.columns = 2
	vbox.add_child(params_grid)
	
	# 回合数
	var rounds_label = Label.new()
	rounds_label.text = "回合数:"
	params_grid.add_child(rounds_label)
	
	rounds_spinbox = SpinBox.new()
	rounds_spinbox.min_value = 1
	rounds_spinbox.max_value = 10
	rounds_spinbox.value = 1
	params_grid.add_child(rounds_spinbox)
	
	# 初始禀赋
	var endowment_label = Label.new()
	endowment_label.text = "初始禀赋:"
	params_grid.add_child(endowment_label)
	
	endowment_spinbox = SpinBox.new()
	endowment_spinbox.min_value = 10
	endowment_spinbox.max_value = 1000
	endowment_spinbox.value = 100
	endowment_spinbox.step = 10
	params_grid.add_child(endowment_spinbox)
	
	# 乘数
	var multiplier_label = Label.new()
	multiplier_label.text = "乘数:"
	params_grid.add_child(multiplier_label)
	
	multiplier_spinbox = SpinBox.new()
	multiplier_spinbox.min_value = 1
	multiplier_spinbox.max_value = 5
	multiplier_spinbox.value = 2
	multiplier_spinbox.step = 0.5
	params_grid.add_child(multiplier_spinbox)
	
	# 游戏暂停选项
	var pause_option_hbox = HBoxContainer.new()
	vbox.add_child(pause_option_hbox)
	
	pause_game_checkbox = CheckBox.new()
	pause_game_checkbox.text = "实验期间暂停游戏场景"
	pause_game_checkbox.tooltip_text = "勾选后，实验运行时会暂停游戏中的角色移动和AI"
	pause_game_checkbox.button_pressed = false  # 默认不暂停
	pause_option_hbox.add_child(pause_game_checkbox)
	
	var hint_label = Label.new()
	hint_label.text = "ℹ️ 取消勾选可以同时观察游戏和实验"
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	pause_option_hbox.add_child(hint_label)
	
	# 控制按钮
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	start_button = Button.new()
	start_button.text = "▶ 开始实验"
	start_button.custom_minimum_size = Vector2(150, 40)
	start_button.pressed.connect(_on_start_pressed)
	button_hbox.add_child(start_button)
	
	var close_button = Button.new()
	close_button.text = "✖ 关闭"
	close_button.custom_minimum_size = Vector2(100, 40)
	close_button.pressed.connect(_on_close_pressed)
	button_hbox.add_child(close_button)
	
	# 状态显示
	status_label = Label.new()
	status_label.text = "等待开始..."
	vbox.add_child(status_label)
	
	# 创建水平分割容器（日志和结果）
	var hsplit = HSplitContainer.new()
	hsplit.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(hsplit)
	
	# 左侧：实验日志
	var log_container = VBoxContainer.new()
	hsplit.add_child(log_container)
	
	var log_label = Label.new()
	log_label.text = "📜 实验日志:"
	log_container.add_child(log_label)
	
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true  # 自动滚动到底部
	log_container.add_child(log_text)
	
	var log_buttons = HBoxContainer.new()
	log_container.add_child(log_buttons)
	
	var clear_log_btn = Button.new()
	clear_log_btn.text = "清空日志"
	clear_log_btn.pressed.connect(_on_clear_log_pressed)
	log_buttons.add_child(clear_log_btn)
	
	# 右侧：结果显示
	var results_container = VBoxContainer.new()
	hsplit.add_child(results_container)
	
	var results_label = Label.new()
	results_label.text = "📊 实验结果:"
	results_container.add_child(results_label)
	
	results_text = RichTextLabel.new()
	results_text.bbcode_enabled = true
	results_container.add_child(results_text)

func _initialize_experiment_manager():
	"""初始化实验管理器"""
	experiment_manager = ExperimentManager.new()
	experiment_manager.name = "GameExperimentManager"
	add_child(experiment_manager)
	
	# 连接信号
	experiment_manager.experiment_started.connect(_on_experiment_started)
	experiment_manager.experiment_finished.connect(_on_experiment_finished)
	experiment_manager.agent_created.connect(_on_agent_created)
	
	print("✅ 实验管理器已初始化")

func _load_game_characters():
	"""加载游戏角色作为潜在参与者"""
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	
	agent_selector.clear()
	game_economic_agents.clear()
	
	for character in characters:
		var char_name = character.name
		agent_selector.add_item(char_name)
		
		# 为每个角色创建EconomicAgent（如果还没有）
		if not game_economic_agents.has(char_name):
			var agent = EconomicAgent.new(char_name, 0.0)  # 初始金钱为0
			
			# 根据角色名称设置性格
			_set_agent_personality(agent, char_name)
			
			game_economic_agents[char_name] = agent
			
			print("✅ 已为 %s 创建经济代理" % char_name)
	
	_on_experiment_type_changed(0)  # 更新UI

func _set_agent_personality(agent: EconomicAgent, char_name: String):
	"""根据角色名称设置经济性格"""
	match char_name:
		"Alice":  # 项目经理 - 合作倾向
			agent.altruism = 0.6
			agent.trust_level = 0.7
			agent.fairness_concern = 0.7
			agent.risk_aversion = 0.5
		"Jack":  # 设计师 - 风险寻求
			agent.risk_aversion = 0.3
			agent.altruism = 0.5
			agent.trust_level = 0.6
		"Grace":  # 数据分析师 - 理性
			agent.risk_aversion = 0.6
			agent.fairness_concern = 0.8
			agent.decision_style = EconomicAgent.DecisionStyle.RATIONAL
		"Joe":  # 技术专家 - 理性最优化
			agent.risk_aversion = 0.5
			agent.decision_style = EconomicAgent.DecisionStyle.RATIONAL
		"Lea":  # 市场营销 - 利他
			agent.altruism = 0.7
			agent.trust_level = 0.8
			agent.reciprocity = 0.7
		"Monica":  # HR - 公平偏好
			agent.fairness_concern = 0.8
			agent.altruism = 0.6
		"Stephen":  # 财务 - 风险厌恶
			agent.risk_aversion = 0.7
			agent.fairness_concern = 0.6
		"Tom":  # 工程师 - 随机
			agent.decision_style = EconomicAgent.DecisionStyle.HEURISTIC

func _on_experiment_type_changed(index: int):
	"""实验类型改变时的处理"""
	var exp_type = experiment_type_selector.get_item_metadata(index)
	var config = experiment_configs[exp_type]
	
	# 更新提示信息
	var hint = "需要选择 %d 名参与者" % config.required_players
	status_label.text = hint

func _on_start_pressed():
	"""开始实验按钮"""
	if is_running:
		status_label.text = "❌ 实验正在进行中"
		return
	
	# 获取选中的参与者
	var selected_indices = agent_selector.get_selected_items()
	if selected_indices.is_empty():
		status_label.text = "❌ 请至少选择一名参与者"
		return
	
	# 获取实验类型
	var exp_type = experiment_type_selector.get_item_metadata(experiment_type_selector.selected)
	var config = experiment_configs[exp_type]
	
	# 检查参与者数量
	if selected_indices.size() < config.required_players:
		status_label.text = "❌ 需要至少 %d 名参与者，当前选择了 %d 名" % [
			config.required_players,
			selected_indices.size()
		]
		return
	
	# 获取参与者代理
	var participants = []
	for idx in selected_indices:
		var agent_name = agent_selector.get_item_text(idx)
		if game_economic_agents.has(agent_name):
			participants.append(agent_name)
	
	# 准备实验配置
	var game_config = {
		"rounds": int(rounds_spinbox.value),
		"endowment": endowment_spinbox.value
	}
	
	if "multiplier" in config.params:
		game_config["multiplier"] = multiplier_spinbox.value
	
	# 创建临时实验配置
	var temp_config = {
		"name": config.name,
		"agents": []
	}
	
	for agent_name in participants:
		temp_config.agents.append({
			"name": agent_name,
			"initial_cash": 0.0
		})
	
	# 设置实验管理器的agents
	experiment_manager.economic_agents.clear()
	for agent_name in participants:
		experiment_manager.economic_agents[agent_name] = game_economic_agents[agent_name]
	
	# 清空之前的日志和结果
	log_text.clear()
	results_text.clear()
	
	# 记录实验开始时间和配置
	experiment_start_time = Time.get_unix_time_from_system()
	current_experiment_type = exp_type
	current_experiment_config = {
		"type": exp_type,
		"name": config.name,
		"participants": participants.duplicate(),
		"game_config": game_config.duplicate()
	}
	
	# 记录实验开始
	_add_log("[color=cyan][b]=== 实验开始 ===[/b][/color]")
	_add_log("[color=white]实验类型: %s[/color]" % config.name)
	_add_log("[color=white]参与者: %s[/color]" % ", ".join(participants))
	_add_log("[color=white]回合数: %d | 禀赋: ¥%.0f[/color]" % [game_config.rounds, game_config.endowment])
	if "multiplier" in game_config:
		_add_log("[color=white]乘数: %.1f[/color]" % game_config.multiplier)
	_add_log("")
	
	# 先创建游戏实例（但不启动）
	var game: GameBase = null
	
	match exp_type:
		"ultimatum":
			game = UltimatumGame.new(game_config)
		"trust":
			game = TrustGame.new(game_config)
		"public_goods":
			game = PublicGoodsGame.new(game_config)
		"dictator":
			game = DictatorGame.new(game_config)
		_:
			_add_log("[color=red]❌ 未知的游戏类型: %s[/color]" % exp_type)
			return
	
	if not game:
		status_label.text = "❌ 游戏创建失败"
		_add_log("[color=red]❌ 游戏创建失败[/color]")
		return
	
	# 先连接信号（在启动之前！）
	_connect_game_signals(game)
	_add_log("[color=green]✅ 游戏信号已连接[/color]")
	
	# 添加参与者
	for agent_name in participants:
		if game_economic_agents.has(agent_name):
			game.add_player(game_economic_agents[agent_name])
			_add_log("[color=gray]👤 添加参与者: %s[/color]" % agent_name)
	
	# 检查是否需要暂停游戏场景
	if pause_game_checkbox.button_pressed:
		_pause_game_scene()
		_add_log("[color=yellow]⏸️ 游戏场景已暂停[/color]")
	
	# 现在启动游戏
	if game.start_game():
		is_running = true
		start_button.disabled = true
		status_label.text = "▶ 实验正在进行中..."
		current_games.append(game)
		
		_add_log("[color=green]✅ 游戏已启动[/color]")
		_add_log("")
	else:
		status_label.text = "❌ 游戏启动失败"
		_add_log("[color=red]❌ 游戏启动失败 - 检查参与者数量是否足够[/color]")
		
		# 如果启动失败，恢复游戏
		if pause_game_checkbox.button_pressed:
			_resume_game_scene()

func _on_experiment_started(exp_name: String):
	"""实验开始回调"""
	_add_log("[color=yellow]🎬 实验 '%s' 已启动[/color]" % exp_name)
	print("GameExperimentPanel: 实验开始 - " + exp_name)

func _on_experiment_finished(results: Dictionary):
	"""实验完成回调"""
	is_running = false
	start_button.disabled = false
	status_label.text = "✅ 实验完成"
	current_games.clear()
	
	# 恢复游戏场景
	if pause_game_checkbox.button_pressed:
		_resume_game_scene()
		_add_log("[color=green]▶️ 游戏场景已恢复[/color]")
	
	_add_log("")
	_add_log("[color=cyan][b]=== 实验完成 ===[/b][/color]")
	_display_results(results)
	
	print("GameExperimentPanel: 实验完成")

func _on_agent_created(agent_name: String):
	"""代理创建回调"""
	_add_log("[color=gray]👤 代理 %s 已加入实验[/color]" % agent_name)

func _display_results(results: Dictionary):
	"""显示实验结果"""
	results_text.clear()
	
	results_text.append_text("[color=green][b]实验结果[/b][/color]\n\n")
	
	# 显示统计信息
	var stats = results.get("statistics", {})
	results_text.append_text("[color=cyan]总游戏数:[/color] %d\n" % stats.get("games_played", 0))
	results_text.append_text("[color=cyan]总决策数:[/color] %d\n\n" % stats.get("total_decisions", 0))
	
	# 显示钱包信息
	results_text.append_text("[color=yellow][b]参与者财富变化:[/b][/color]\n")
	var wallets = results.get("wallets", {})
	
	for agent_name in wallets.keys():
		var wallet_data = wallets[agent_name]
		var cash = wallet_data.get("cash", 0.0)
		var net_worth = wallet_data.get("net_worth", cash)
		
		var color = "green" if cash > 0 else ("red" if cash < 0 else "white")
		results_text.append_text("  [color=%s]%s: ¥%.2f[/color]\n" % [color, agent_name, cash])
		
		# 注意：钱包已经在游戏执行过程中被正确更新了，无需重新赋值
	
	results_text.append_text("\n[color=gray]提示：可以再次运行实验继续累积财富[/color]")

## === 日志系统 ===

func _add_log(message: String):
	"""添加日志消息"""
	var timestamp = Time.get_time_string_from_system()
	log_text.append_text("[color=gray][%s][/color] %s\n" % [timestamp, message])

func _on_clear_log_pressed():
	"""清空日志"""
	log_text.clear()
	_add_log("[color=cyan]日志已清空[/color]")

func _connect_game_signals(game: GameBase):
	"""连接游戏信号以获取详细事件"""
	# 连接游戏事件信号
	game.game_started.connect(func(): _on_game_started(game))
	game.round_started.connect(func(round_num): _on_round_started(game, round_num))
	game.round_finished.connect(func(round_num, results): _on_round_finished(game, round_num, results))
	game.decision_made.connect(func(player_id, decision): _on_decision_made(game, player_id, decision))
	game.game_finished.connect(func(final_results): _on_game_finished(game, final_results))
	
	print("GameExperimentPanel: 游戏信号已连接 - %s" % game.game_type)

func _on_game_started(game: GameBase):
	"""游戏开始"""
	_add_log("[color=green]🎮 游戏 '%s' 开始[/color]" % game.game_type)
	print("GameExperimentPanel: 游戏开始事件触发 - %s" % game.game_type)

func _on_round_started(game: GameBase, round_num: int):
	"""回合开始"""
	_add_log("")
	_add_log("[color=yellow]━━━ 第 %d 回合 ━━━[/color]" % round_num)
	print("GameExperimentPanel: 回合开始 - %d" % round_num)

func _on_round_finished(game: GameBase, round_num: int, results: Dictionary):
	"""回合结束"""
	_add_log("[color=cyan]✓ 第 %d 回合完成[/color]" % round_num)
	
	# 根据游戏类型显示回合结果
	match game.game_type:
		"trust":
			_log_trust_round(results)
		"ultimatum":
			_log_ultimatum_round(results)
		"public_goods":
			_log_public_goods_round(results)
		"dictator":
			_log_dictator_round(results)

func _on_decision_made(game: GameBase, player_id: String, decision: Dictionary):
	"""决策被做出"""
	var action = decision.get("action", "unknown")
	print("GameExperimentPanel: 决策 - %s by %s" % [action, player_id])
	
	match action:
		"send":
			var amount = decision.get("amount_sent", 0)
			_add_log("[color=white]  💸 %s 发送了 ¥%.2f[/color]" % [player_id, amount])
		"return":
			var amount = decision.get("returned", 0)
			_add_log("[color=white]  🔄 %s 返还了 ¥%.2f[/color]" % [player_id, amount])
		"propose":
			var offer = decision.get("offer", 0)
			_add_log("[color=white]  📋 %s 提议分配 ¥%.2f[/color]" % [player_id, offer])
		"respond":
			var accepted = decision.get("accepted", false)
			var status = "✅ 接受" if accepted else "❌ 拒绝"
			_add_log("[color=white]  %s %s 了提议[/color]" % [status, player_id])
		"contribute":
			var amount = decision.get("contribution", 0)
			_add_log("[color=white]  🏛️ %s 贡献了 ¥%.2f[/color]" % [player_id, amount])
		"allocate":
			var gift = decision.get("gift", 0)
			_add_log("[color=white]  🎁 %s 给出了 ¥%.2f[/color]" % [player_id, gift])

func _on_game_finished(game: GameBase, final_results: Dictionary):
	"""游戏完成"""
	_add_log("[color=green]🏁 游戏 '%s' 完成[/color]" % game.game_type)
	print("GameExperimentPanel: 游戏完成 - %s" % game.game_type)
	
	# 游戏完成后，手动收集结果并触发完成流程
	await get_tree().process_frame  # 等待一帧确保所有信号处理完成
	_finalize_experiment()

## === 回合结果日志 ===

func _log_trust_round(results: Dictionary):
	"""记录信任游戏回合"""
	var amount_sent = results.get("amount_sent", 0)
	var amount_returned = results.get("amount_returned", 0)
	var multiplied = amount_sent * results.get("multiplier", 1)
	
	_add_log("[color=aqua]  📊 发送金额: ¥%.2f → 乘数后: ¥%.2f → 返还: ¥%.2f[/color]" % [
		amount_sent, multiplied, amount_returned
	])

func _log_ultimatum_round(results: Dictionary):
	"""记录最后通牒游戏回合"""
	var offer = results.get("offer", 0)
	var accepted = results.get("accepted", false)
	var proposer_payoff = results.get("proposer_payoff", 0)
	var responder_payoff = results.get("responder_payoff", 0)
	
	var status = "接受 ✅" if accepted else "拒绝 ❌"
	_add_log("[color=aqua]  📊 提议: ¥%.2f (%s) → 提议者: ¥%.2f | 响应者: ¥%.2f[/color]" % [
		offer, status, proposer_payoff, responder_payoff
	])

func _log_public_goods_round(results: Dictionary):
	"""记录公共物品游戏回合"""
	var total_contribution = results.get("total_contribution", 0)
	var avg_contribution = results.get("average_contribution", 0)
	var pool_after = results.get("pool_after_multiplier", 0)
	var cooperation_rate = results.get("cooperation_rate", 0) * 100
	
	_add_log("[color=aqua]  📊 总贡献: ¥%.2f | 平均: ¥%.2f | 乘数后: ¥%.2f | 合作率: %.1f%%[/color]" % [
		total_contribution, avg_contribution, pool_after, cooperation_rate
	])
	
	# 显示搭便车者
	var free_riders = results.get("free_riders", [])
	if not free_riders.is_empty():
		_add_log("[color=orange]  ⚠️ 搭便车者: %s[/color]" % ", ".join(free_riders))

func _log_dictator_round(results: Dictionary):
	"""记录独裁者游戏回合"""
	var gift = results.get("gift", 0)
	var dictator_payoff = results.get("dictator_payoff", 0)
	var recipient_payoff = results.get("recipient_payoff", 0)
	var gift_ratio = results.get("gift_ratio", 0) * 100
	
	_add_log("[color=aqua]  📊 给出: ¥%.2f (%.1f%%) → 独裁者: ¥%.2f | 接收者: ¥%.2f[/color]" % [
		gift, gift_ratio, dictator_payoff, recipient_payoff
	])

## === 游戏场景控制 ===

func _pause_game_scene():
	"""暂停游戏场景"""
	game_was_paused = get_tree().paused
	
	# 暂停除了UI以外的所有节点
	get_tree().paused = true
	
	# 设置当前面板为PROCESS_MODE_ALWAYS，确保它不受暂停影响
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 暂停所有AI角色的决策
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	for character in characters:
		var ai_agent = character.get_node_or_null("AIAgent")
		if ai_agent and ai_agent.has_method("toggle_player_control"):
			# 临时禁用AI决策
			ai_agent.decision_timer.paused = true
	
	print("GameExperimentPanel: 游戏场景已暂停")

func _resume_game_scene():
	"""恢复游戏场景"""
	# 恢复到原来的暂停状态
	get_tree().paused = game_was_paused
	
	# 恢复AI角色的决策
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	for character in characters:
		var ai_agent = character.get_node_or_null("AIAgent")
		if ai_agent and ai_agent.has_method("toggle_player_control"):
			ai_agent.decision_timer.paused = false
	
	print("GameExperimentPanel: 游戏场景已恢复")

func _on_close_pressed():
	"""关闭按钮处理"""
	# 如果实验正在运行，先恢复游戏
	if is_running and pause_game_checkbox.button_pressed:
		_resume_game_scene()
	
	hide()

func _finalize_experiment():
	"""完成实验并收集结果"""
	if not is_running:
		return
	
	print("GameExperimentPanel: 开始收集实验结果")
	
	is_running = false
	start_button.disabled = false
	status_label.text = "✅ 实验完成"
	
	# 恢复游戏场景
	if pause_game_checkbox.button_pressed:
		_resume_game_scene()
		_add_log("[color=green]▶️ 游戏场景已恢复[/color]")
	
	_add_log("")
	_add_log("[color=cyan][b]=== 实验完成 ===[/b][/color]")
	
	# 收集所有游戏的结果
	var all_results = {
		"wallets": {},
		"statistics": {
			"games_played": current_games.size(),
			"total_decisions": 0,
			"total_rounds": 0
		}
	}
	
	# 从所有游戏收集数据
	for game in current_games:
		if game and game.final_results:
			# 统计游戏数据
			all_results.statistics.total_rounds += game.final_results.get("total_rounds", 0)
			
			var player_results = game.final_results.get("player_results", {})
			for player_id in player_results.keys():
				var player_data = player_results[player_id]
				all_results.statistics.total_decisions += player_data.get("rounds_played", 0)
	
	# 收集钱包状态
	for agent_name in game_economic_agents.keys():
		var agent = game_economic_agents[agent_name]
		if agent and agent.wallet:
			all_results.wallets[agent_name] = agent.wallet.to_dict()
	
	print("GameExperimentPanel: 收集了 %d 个钱包的数据" % all_results.wallets.size())
	
	# 显示结果
	_display_results(all_results)
	
	# 生成本地报告
	_generate_report(all_results)
	
	# 清空当前游戏列表
	current_games.clear()
	
	print("GameExperimentPanel: 实验完成")

## === 报告生成 ===

func _generate_report(results: Dictionary):
	"""生成并保存实验报告"""
	var end_time = Time.get_unix_time_from_system()
	var duration = end_time - experiment_start_time
	
	# 创建报告数据结构
	var report_data = {
		"experiment_metadata": {
			"type": current_experiment_type,
			"name": current_experiment_config.get("name", "未知实验"),
			"start_time": experiment_start_time,
			"end_time": end_time,
			"duration_seconds": duration,
			"timestamp": Time.get_datetime_string_from_system()
		},
		"configuration": current_experiment_config.get("game_config", {}),
		"participants": current_experiment_config.get("participants", []),
		"results": {
			"statistics": results.get("statistics", {}),
			"wallets": results.get("wallets", {}),
			"games": []
		}
	}
	
	# 收集每个游戏的详细结果
	for game in current_games:
		if game and game.final_results:
			report_data.results.games.append(game.final_results)
	
	# 生成唯一的报告文件名
	var datetime = Time.get_datetime_dict_from_system()
	var filename_base = "experiment_report_%s_%04d%02d%02d_%02d%02d%02d" % [
		current_experiment_type,
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	# 保存JSON格式
	_save_json_report(filename_base, report_data)
	
	# 保存Markdown格式
	_save_markdown_report(filename_base, report_data)
	
	_add_log("")
	_add_log("[color=green]📊 报告已生成并保存到: user://experiment_reports/[/color]")
	_add_log("[color=gray]  • %s.json[/color]" % filename_base)
	_add_log("[color=gray]  • %s.md[/color]" % filename_base)

func _save_json_report(filename: String, data: Dictionary):
	"""保存JSON格式的报告"""
	var dir_path = "user://experiment_reports"
	
	# 确保目录存在
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)
	
	var file_path = "%s/%s.json" % [dir_path, filename]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("GameExperimentPanel: JSON报告已保存 - %s" % file_path)
	else:
		push_error("GameExperimentPanel: 无法保存JSON报告 - %s" % file_path)

func _save_markdown_report(filename: String, data: Dictionary):
	"""保存Markdown格式的报告"""
	var dir_path = "user://experiment_reports"
	
	# 确保目录存在
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)
	
	var file_path = "%s/%s.md" % [dir_path, filename]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("GameExperimentPanel: 无法保存Markdown报告 - %s" % file_path)
		return
	
	# 元数据部分
	var metadata = data.get("experiment_metadata", {})
	file.store_line("# 实验报告：%s" % metadata.get("name", "未知实验"))
	file.store_line("")
	file.store_line("## 实验信息")
	file.store_line("")
	file.store_line("- **实验类型**: %s" % metadata.get("type", "未知"))
	file.store_line("- **开始时间**: %s" % metadata.get("timestamp", "未知"))
	file.store_line("- **实验时长**: %.2f 秒" % metadata.get("duration_seconds", 0.0))
	file.store_line("")
	
	# 参与者
	file.store_line("## 参与者")
	file.store_line("")
	var participants = data.get("participants", [])
	for participant in participants:
		file.store_line("- %s" % participant)
	file.store_line("")
	
	# 实验配置
	file.store_line("## 实验配置")
	file.store_line("")
	var config = data.get("configuration", {})
	file.store_line("- **回合数**: %d" % config.get("rounds", 0))
	file.store_line("- **初始禀赋**: ¥%.2f" % config.get("endowment", 0.0))
	if "multiplier" in config:
		file.store_line("- **乘数**: %.2f" % config.get("multiplier", 1.0))
	file.store_line("")
	
	# 统计数据
	file.store_line("## 实验统计")
	file.store_line("")
	var stats = data.results.get("statistics", {})
	file.store_line("- **游戏场次**: %d" % stats.get("games_played", 0))
	file.store_line("- **总回合数**: %d" % stats.get("total_rounds", 0))
	file.store_line("- **总决策数**: %d" % stats.get("total_decisions", 0))
	file.store_line("")
	
	# 参与者财务状况
	file.store_line("## 参与者财务状况")
	file.store_line("")
	file.store_line("| 参与者 | 现金 | 净资产 | 交易数 |")
	file.store_line("|--------|------|---------|--------|")
	
	var wallets = data.results.get("wallets", {})
	for agent_name in wallets.keys():
		var wallet_data = wallets[agent_name]
		var cash = wallet_data.get("cash", 0.0)
		var net_worth = wallet_data.get("net_worth", cash)
		var tx_count = wallet_data.get("transaction_history", []).size()
		file.store_line("| %s | ¥%.2f | ¥%.2f | %d |" % [agent_name, cash, net_worth, tx_count])
	
	file.store_line("")
	
	# 详细游戏结果
	file.store_line("## 详细游戏结果")
	file.store_line("")
	
	var games = data.results.get("games", [])
	for i in range(games.size()):
		var game_result = games[i]
		file.store_line("### 游戏 %d" % (i + 1))
		file.store_line("")
		file.store_line("- **游戏ID**: %s" % game_result.get("game_id", "未知"))
		file.store_line("- **游戏类型**: %s" % game_result.get("game_type", "未知"))
		file.store_line("- **总回合数**: %d" % game_result.get("total_rounds", 0))
		file.store_line("- **游戏时长**: %.4f 秒" % game_result.get("duration", 0.0))
		file.store_line("")
		
		# 玩家结果
		var player_results = game_result.get("player_results", {})
		if player_results.size() > 0:
			file.store_line("**玩家表现**:")
			file.store_line("")
			for player_id in player_results.keys():
				var player_data = player_results[player_id]
				file.store_line("- **%s**:" % player_id)
				file.store_line("  - 总收益: ¥%.2f" % player_data.get("total_payoff", 0.0))
				file.store_line("  - 平均收益: ¥%.2f" % player_data.get("average_payoff", 0.0))
				file.store_line("  - 参与回合: %d" % player_data.get("rounds_played", 0))
			file.store_line("")
	
	# 交易历史
	file.store_line("## 交易历史")
	file.store_line("")
	
	for agent_name in wallets.keys():
		var wallet_data = wallets[agent_name]
		var transactions = wallet_data.get("transaction_history", [])
		
		if transactions.size() > 0:
			file.store_line("### %s 的交易" % agent_name)
			file.store_line("")
			file.store_line("| 类型 | 金额 | 来源/原因 | 余额 |")
			file.store_line("|------|------|-----------|------|")
			
			for tx in transactions:
				var tx_type = tx.get("type", "未知")
				var amount = tx.get("amount", 0.0)
				var source = tx.get("source", tx.get("reason", "未知"))
				var balance = tx.get("balance_after", 0.0)
				file.store_line("| %s | ¥%.2f | %s | ¥%.2f |" % [tx_type, amount, source, balance])
			
			file.store_line("")
	
	# 报告生成信息
	file.store_line("---")
	file.store_line("")
	file.store_line("*报告生成时间: %s*" % Time.get_datetime_string_from_system())
	file.store_line("*生成工具: Microverse 游戏内实验系统*")
	
	file.close()
	print("GameExperimentPanel: Markdown报告已保存 - %s" % file_path)

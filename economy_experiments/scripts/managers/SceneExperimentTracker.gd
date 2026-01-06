extends Node

## 场景实验追踪器
## 在主游戏场景中持续追踪所有agent的财富和心理状态
## 这是一个自动加载的单例，在后台持续运行
## 通过 /root/SceneExperimentTracker 访问

# 信号
signal agent_state_updated(agent_name: String, state: Dictionary)
signal wealth_changed(agent_name: String, new_wealth: float)
signal psychological_state_changed(agent_name: String, psych_state: Dictionary)
signal report_generated(report_path: String)

# 场景中的经济代理
var scene_agents: Dictionary = {}  # character_name -> EconomicAgent

# 追踪统计
var tracking_start_time: float = 0.0
var total_interactions: int = 0
var total_transactions: int = 0
var scene_day: int = 1

# 定时器
var update_timer: Timer
var autosave_timer: Timer

# 配置
var update_interval: float = 5.0  # 每5秒更新一次心理状态
var autosave_interval: float = 300.0  # 每5分钟自动保存一次
var auto_report_enabled: bool = true
var enable_auto_transactions: bool = true  # 是否启用自动交易模拟
var transaction_interval: float = 15.0  # 自动交易间隔（秒）

# 交易定时器
var transaction_timer: Timer

func _ready():
	tracking_start_time = Time.get_unix_time_from_system()
	
	# 创建更新定时器
	update_timer = Timer.new()
	update_timer.wait_time = update_interval
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()
	
	# 创建自动保存定时器
	autosave_timer = Timer.new()
	autosave_timer.wait_time = autosave_interval
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)
	autosave_timer.start()
	
	# 创建交易模拟定时器
	if enable_auto_transactions:
		transaction_timer = Timer.new()
		transaction_timer.wait_time = transaction_interval
		transaction_timer.timeout.connect(_on_transaction_timer_timeout)
		add_child(transaction_timer)
		transaction_timer.start()
	
	# 延迟初始化agent
	call_deferred("_initialize_scene_agents")
	
	print("✅ SceneExperimentTracker: 场景实验追踪器已启动")
	if enable_auto_transactions:
		print("✅ SceneExperimentTracker: 自动交易模拟已启用 (间隔: %.0f秒)" % transaction_interval)

## 初始化场景中的所有agent
func _initialize_scene_agents():
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	
	for character in characters:
		var char_name = character.name
		
		# 为每个角色创建EconomicAgent
		if not scene_agents.has(char_name):
			var agent = EconomicAgent.new(char_name, 10000.0)  # 初始财富为10000
			
			# 设置个性（可以从配置文件加载）
			_set_agent_personality(agent, char_name)
			
			scene_agents[char_name] = agent
			
			# 同步角色节点的meta数据（用于GodUI显示）
			character.set_meta("money", 10000)
			
			# 连接钱包信号
			if agent.wallet:
				agent.wallet.balance_changed.connect(func(new_balance): _on_wallet_changed(char_name, new_balance))
				agent.wallet.transaction_recorded.connect(func(tx): _on_transaction_recorded(char_name, tx))
				print("✅ SceneExperimentTracker: %s 的钱包信号已连接" % char_name)
			else:
				push_error("❌ SceneExperimentTracker: %s 的钱包为空，无法连接信号！" % char_name)
			
			print("✅ SceneExperimentTracker: 已为 %s 创建经济代理，初始财富 ¥10,000" % char_name)
	
	print("✅ SceneExperimentTracker: 共追踪 %d 个agent" % scene_agents.size())

## 设置agent个性
func _set_agent_personality(agent: EconomicAgent, char_name: String):
	"""根据角色名称设置个性特征"""
	var personality = {
		"risk_aversion": randf_range(0.3, 0.7),
		"time_preference": randf_range(0.3, 0.7),
		"altruism": randf_range(0.3, 0.7),
		"fairness_concern": randf_range(0.3, 0.7),
		"trust_level": randf_range(0.3, 0.7),
		"reciprocity": randf_range(0.3, 0.7),
		"decision_style": "bounded_rational"
	}
	
	# 可以根据角色名称定制个性
	match char_name.to_lower():
		"alice":
			personality.trust_level = 0.7
			personality.altruism = 0.7
		"bob":
			personality.risk_aversion = 0.7
		"charlie":
			personality.fairness_concern = 0.8
	
	agent.load_personality(personality)

## 定时更新所有agent的状态
func _on_update_timer_timeout():
	_update_all_agents()

## 定时触发交易模拟
func _on_transaction_timer_timeout():
	print("⏰ SceneExperimentTracker: 定时器触发 - 开始模拟交易")
	_simulate_random_transaction()

## 更新所有agent的心理状态
func _update_all_agents():
	var all_agents = scene_agents.values()
	
	for agent_name in scene_agents.keys():
		var agent = scene_agents[agent_name]
		if agent:
			# 更新心理状态
			agent.update_psychological_state(all_agents)
			
			# 发出信号
			agent_state_updated.emit(agent_name, agent.to_dict())
			psychological_state_changed.emit(agent_name, agent.get_psychological_summary())

## 钱包余额变化回调
func _on_wallet_changed(agent_name: String, new_balance: float):
	wealth_changed.emit(agent_name, new_balance)
	print("💰 SceneExperimentTracker: %s 的财富变为 ¥%.2f" % [agent_name, new_balance])
	
	# 同步更新角色节点的meta数据（用于GodUI显示）
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	for character in characters:
		if character.name == agent_name:
			character.set_meta("money", int(new_balance))
			break
	
	# 记录到游戏日志
	_log_to_game_ui("wealth_changed", agent_name, new_balance) # 暂时注释掉财富变化日志，避免刷屏

## 交易记录回调
func _on_transaction_recorded(agent_name: String, transaction: Dictionary):
	total_transactions += 1
	var tx_type = transaction.get("type", "unknown")
	var amount = transaction.get("amount", 0.0)
	var source = transaction.get("source", "未知")
	
	# 过滤掉初始化交易，避免刷屏
	if tx_type == "initialization":
		return
	
	print("📝 SceneExperimentTracker: %s 进行了交易: [%s] ¥%.2f (来源: %s)" % [agent_name, tx_type, amount, source])
	
	# 记录到游戏日志
	_log_to_game_ui("transaction", agent_name, amount, tx_type, source)

## 记录一次交互
func record_interaction(agent_names: Array, interaction_type: String, details: Dictionary = {}):
	"""记录agent之间的交互"""
	total_interactions += 1
	
	var interaction = {
		"timestamp": Time.get_unix_time_from_system(),
		"agents": agent_names,
		"type": interaction_type,
		"details": details
	}
	
	print("🤝 SceneExperimentTracker: 记录交互 - %s (%s)" % [interaction_type, ", ".join(agent_names)])
	
	# 记录到游戏日志
	_log_to_game_ui("interaction", agent_names, interaction_type, details)

## 获取agent
func get_agent(agent_name: String) -> EconomicAgent:
	return scene_agents.get(agent_name)

## 获取所有agent
func get_all_agents() -> Dictionary:
	return scene_agents

## 获取统计摘要
func get_statistics_summary() -> Dictionary:
	var total_wealth = 0.0
	var wealth_distribution = []
	
	for agent in scene_agents.values():
		if agent and agent.wallet:
			var wealth = agent.wallet.get_net_worth()
			total_wealth += wealth
			wealth_distribution.append({
				"name": agent.character_name,
				"wealth": wealth
			})
	
	# 排序
	wealth_distribution.sort_custom(func(a, b): return a.wealth > b.wealth)
	
	var running_time = Time.get_unix_time_from_system() - tracking_start_time
	
	return {
		"scene_day": scene_day,
		"running_time_seconds": running_time,
		"running_time_formatted": _format_duration(running_time),
		"total_agents": scene_agents.size(),
		"total_wealth": total_wealth,
		"average_wealth": total_wealth / max(1, scene_agents.size()),
		"total_interactions": total_interactions,
		"total_transactions": total_transactions,
		"wealth_distribution": wealth_distribution
	}

## 获取财富排行榜
func get_wealth_leaderboard() -> Array:
	var leaderboard = []
	
	for agent_name in scene_agents.keys():
		var agent = scene_agents[agent_name]
		if agent and agent.wallet:
			leaderboard.append({
				"name": agent_name,
				"wealth": agent.wallet.get_net_worth(),
				"psychological_state": agent.get_psychological_summary()
			})
	
	# 按财富排序
	leaderboard.sort_custom(func(a, b): return a.wealth > b.wealth)
	
	return leaderboard

## 获取心理状态摘要
func get_psychological_summary() -> Dictionary:
	var summary = {}
	
	for agent_name in scene_agents.keys():
		var agent = scene_agents[agent_name]
		if agent:
			summary[agent_name] = agent.get_psychological_summary()
	
	return summary

## 生成场景实验报告
func generate_scene_report() -> String:
	"""生成当前场景状态的详细报告"""
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "scene_report_%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var report_data = {
		"report_metadata": {
			"type": "scene_experiment",
			"timestamp": Time.get_datetime_string_from_system(),
			"scene_day": scene_day,
			"tracking_start_time": tracking_start_time,
			"report_time": Time.get_unix_time_from_system()
		},
		"statistics": get_statistics_summary(),
		"agents": {},
		"psychological_summary": get_psychological_summary()
	}
	
	# 收集所有agent的详细数据
	for agent_name in scene_agents.keys():
		var agent = scene_agents[agent_name]
		if agent:
			report_data.agents[agent_name] = agent.to_dict()
	
	# 保存JSON和Markdown报告
	_save_json_report(filename, report_data)
	_save_markdown_report(filename, report_data)
	
	var report_path = "user://experiment_reports/%s.md" % filename
	report_generated.emit(report_path)
	
	print("📊 SceneExperimentTracker: 场景报告已生成 - %s" % filename)
	return report_path

## 自动保存回调
func _on_autosave_timer_timeout():
	if auto_report_enabled:
		generate_scene_report()

## 保存JSON报告
func _save_json_report(filename: String, data: Dictionary):
	var dir_path = "user://experiment_reports"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)
	
	var file_path = "%s/%s.json" % [dir_path, filename]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("SceneExperimentTracker: JSON报告已保存 - %s" % file_path)
	else:
		push_error("SceneExperimentTracker: 无法保存JSON报告 - %s" % file_path)

## 保存Markdown报告
func _save_markdown_report(filename: String, data: Dictionary):
	var dir_path = "user://experiment_reports"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)
	
	var file_path = "%s/%s.md" % [dir_path, filename]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("SceneExperimentTracker: 无法保存Markdown报告 - %s" % file_path)
		return
	
	# 报告标题
	var metadata = data.get("report_metadata", {})
	file.store_line("# 场景实验报告")
	file.store_line("")
	file.store_line("## 报告信息")
	file.store_line("")
	file.store_line("- **报告时间**: %s" % metadata.get("timestamp", "未知"))
	file.store_line("- **场景天数**: 第 %d 天" % metadata.get("scene_day", 1))
	file.store_line("")
	
	# 统计摘要
	var stats = data.get("statistics", {})
	file.store_line("## 场景统计")
	file.store_line("")
	file.store_line("- **运行时长**: %s" % stats.get("running_time_formatted", "未知"))
	file.store_line("- **追踪Agent数**: %d" % stats.get("total_agents", 0))
	file.store_line("- **交互次数**: %d" % stats.get("total_interactions", 0))
	file.store_line("- **交易次数**: %d" % stats.get("total_transactions", 0))
	file.store_line("- **总财富**: ¥%.2f" % stats.get("total_wealth", 0.0))
	file.store_line("- **平均财富**: ¥%.2f" % stats.get("average_wealth", 0.0))
	file.store_line("")
	
	# 财富排行榜
	file.store_line("## 财富排行榜")
	file.store_line("")
	file.store_line("| 排名 | Agent | 财富 | 心情 | 满意度 | 压力 |")
	file.store_line("|------|-------|------|------|--------|------|")
	
	var wealth_dist = stats.get("wealth_distribution", [])
	for i in range(wealth_dist.size()):
		var entry = wealth_dist[i]
		var psych = data.psychological_summary.get(entry.name, {})
		var medal = ""
		match i:
			0: medal = "🥇"
			1: medal = "🥈"
			2: medal = "🥉"
		
		file.store_line("| %s %d | %s | ¥%.2f | %s | %.0f%% | %s |" % [
			medal, i + 1,
			entry.name,
			entry.wealth,
			psych.get("mood_label", "未知"),
			psych.get("satisfaction", 0.0) * 100,
			psych.get("stress_label", "未知")
		])
	
	file.store_line("")
	
	# 详细心理状态
	file.store_line("## Agent心理状态详情")
	file.store_line("")
	
	var psych_summary = data.get("psychological_summary", {})
	for agent_name in psych_summary.keys():
		var psych = psych_summary[agent_name]
		file.store_line("### %s" % agent_name)
		file.store_line("")
		file.store_line("- **心情**: %s (%.2f/1.0)" % [psych.get("mood_label", "未知"), psych.get("mood", 0.0)])
		file.store_line("- **满意度**: %.0f%%" % (psych.get("satisfaction", 0.0) * 100))
		file.store_line("- **压力**: %s (%.2f/1.0)" % [psych.get("stress_label", "未知"), psych.get("stress", 0.0)])
		file.store_line("- **自信心**: %.0f%%" % (psych.get("confidence", 0.0) * 100))
		file.store_line("- **社会地位感**: %.0f%%" % (psych.get("social_standing", 0.0) * 100))
		file.store_line("- **动机水平**: %.0f%%" % (psych.get("motivation", 0.0) * 100))
		
		if psych.get("envy", 0.0) > 0.3:
			file.store_line("- **嫉妒程度**: %.0f%% ⚠️" % (psych.get("envy", 0.0) * 100))
		if psych.get("gratitude", 0.0) > 0.3:
			file.store_line("- **感激程度**: %.0f%% ✨" % (psych.get("gratitude", 0.0) * 100))
		
		file.store_line("")
	
	# Agent详细数据
	file.store_line("## Agent详细数据")
	file.store_line("")
	
	var agents = data.get("agents", {})
	for agent_name in agents.keys():
		var agent_data = agents[agent_name]
		var wallet = agent_data.get("wallet", {})
		
		file.store_line("### %s" % agent_name)
		file.store_line("")
		file.store_line("**财务状况**:")
		file.store_line("- 现金: ¥%.2f" % wallet.get("cash", 0.0))
		file.store_line("- 净资产: ¥%.2f" % wallet.get("net_worth", 0.0))
		file.store_line("- 交易数: %d" % wallet.get("transaction_history", []).size())
		file.store_line("")
		
		file.store_line("**经验统计**:")
		file.store_line("- 经验数: %d" % agent_data.get("experience_count", 0))
		file.store_line("- 最近收益: ¥%.2f" % agent_data.get("recent_gains", 0.0))
		file.store_line("- 最近损失: ¥%.2f" % agent_data.get("recent_losses", 0.0))
		file.store_line("")
	
	# 报告尾部
	file.store_line("---")
	file.store_line("")
	file.store_line("*报告生成时间: %s*" % Time.get_datetime_string_from_system())
	file.store_line("*生成工具: Microverse 场景实验追踪系统*")
	
	file.close()
	print("SceneExperimentTracker: Markdown报告已保存 - %s" % file_path)

## 格式化时长
func _format_duration(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	var secs = int(seconds - hours * 3600 - minutes * 60)
	
	if hours > 0:
		return "%d小时%d分钟%d秒" % [hours, minutes, secs]
	elif minutes > 0:
		return "%d分钟%d秒" % [minutes, secs]
	else:
		return "%d秒" % secs

## 重置追踪器
func reset_tracker():
	"""重置所有追踪数据"""
	scene_agents.clear()
	total_interactions = 0
	total_transactions = 0
	tracking_start_time = Time.get_unix_time_from_system()
	_initialize_scene_agents()
	print("✅ SceneExperimentTracker: 追踪器已重置")

## === 交易模拟系统 ===

## 手动触发测试交易（调试用）
func test_transaction():
	"""手动触发一次测试交易 - 用于调试"""
	print("🧪 手动触发测试交易...")
	if scene_agents.size() < 2:
		print("❌ 测试失败: agent数量不足")
		return
	
	var agent_names = scene_agents.keys()
	print("📋 可用agents: %s" % str(agent_names))
	_simulate_gift(agent_names[0], agent_names[1])

## 模拟一次随机交易
func _simulate_random_transaction():
	"""模拟agents之间的随机经济活动"""
	if scene_agents.size() < 2:
		print("⚠️ SceneExperimentTracker: agent数量不足，无法模拟交易 (当前: %d)" % scene_agents.size())
		return  # 至少需要2个agent才能交易
	
	var agent_names = scene_agents.keys()
	agent_names.shuffle()
	
	# 随机选择交易类型
	var transaction_types = [
		"gift",           # 礼物
		"trade",          # 交易
		"loan",           # 借贷
		"investment",     # 投资
		"service_payment" # 服务付款
	]
	
	var tx_type = transaction_types[randi() % transaction_types.size()]
	print("🎲 SceneExperimentTracker: 随机选择交易类型: %s (参与者: %s)" % [tx_type, agent_names[0] if agent_names.size() > 0 else "无"])
	
	match tx_type:
		"gift":
			_simulate_gift(agent_names[0], agent_names[1])
		"trade":
			_simulate_trade(agent_names[0], agent_names[1])
		"loan":
			_simulate_loan(agent_names[0], agent_names[1])
		"investment":
			_simulate_investment(agent_names[0])
		"service_payment":
			_simulate_service_payment(agent_names[0], agent_names[1])

## 模拟赠予
func _simulate_gift(from_name: String, to_name: String):
	print("🎁 尝试模拟赠予: %s -> %s" % [from_name, to_name])
	var from_agent = scene_agents.get(from_name)
	var to_agent = scene_agents.get(to_name)
	
	if not from_agent or not to_agent:
		print("❌ 赠予失败: agent不存在 (from: %s, to: %s)" % [from_agent != null, to_agent != null])
		return
	
	# 赠予金额为财富的1-5%
	var gift_amount = from_agent.wallet.cash * randf_range(0.01, 0.05)
	gift_amount = clamp(gift_amount, 10.0, 500.0)
	
	print("💵 赠予金额: ¥%.2f (from %s 的现金: ¥%.2f)" % [gift_amount, from_name, from_agent.wallet.cash])
	
	if from_agent.wallet.can_afford(gift_amount):
		print("✅ 执行赠予交易...")
		from_agent.wallet.withdraw(gift_amount, "赠予给 " + to_name)
		to_agent.wallet.deposit(gift_amount, "收到 " + from_name + " 的赠予")
		
		record_interaction([from_name, to_name], "gift", {
			"amount": gift_amount,
			"reason": "友好赠予"
		})
	else:
		print("❌ 赠予失败: 资金不足")

## 模拟交易
func _simulate_trade(buyer_name: String, seller_name: String):
	var buyer = scene_agents.get(buyer_name)
	var seller = scene_agents.get(seller_name)
	
	if not buyer or not seller:
		return
	
	var trade_amount = randf_range(50.0, 300.0)
	
	if buyer.wallet.can_afford(trade_amount):
		buyer.wallet.withdraw(trade_amount, "购买商品/服务 from " + seller_name)
		seller.wallet.deposit(trade_amount, "出售商品/服务 to " + buyer_name)
		
		record_interaction([buyer_name, seller_name], "trade", {
			"amount": trade_amount,
			"reason": "商品交易"
		})

## 模拟借贷
func _simulate_loan(lender_name: String, borrower_name: String):
	var lender = scene_agents.get(lender_name)
	var borrower = scene_agents.get(borrower_name)
	
	if not lender or not borrower:
		return
	
	var loan_amount = randf_range(100.0, 500.0)
	
	if lender.wallet.can_afford(loan_amount):
		lender.wallet.withdraw(loan_amount, "借出给 " + borrower_name)
		borrower.wallet.deposit(loan_amount, "借入自 " + lender_name)
		
		record_interaction([lender_name, borrower_name], "loan", {
			"amount": loan_amount,
			"reason": "短期借贷"
		})

## 模拟投资收益
func _simulate_investment(agent_name: String):
	var agent = scene_agents.get(agent_name)
	
	if not agent:
		return
	
	# 随机投资回报（可能是收益或损失）
	var return_amount = randf_range(-50.0, 150.0)
	
	if return_amount > 0:
		agent.wallet.deposit(return_amount, "投资收益")
	else:
		if agent.wallet.can_afford(abs(return_amount)):
			agent.wallet.withdraw(abs(return_amount), "投资损失")
	
	record_interaction([agent_name], "investment", {
		"amount": abs(return_amount),
		"type": "收益" if return_amount > 0 else "损失",
		"reason": "市场投资回报"
	})

## 模拟服务付款
func _simulate_service_payment(payer_name: String, provider_name: String):
	var payer = scene_agents.get(payer_name)
	var provider = scene_agents.get(provider_name)
	
	if not payer or not provider:
		return
	
	var payment = randf_range(30.0, 200.0)
	
	if payer.wallet.can_afford(payment):
		payer.wallet.withdraw(payment, "服务费用支付给 " + provider_name)
		provider.wallet.deposit(payment, "提供服务收入 from " + payer_name)
		
		record_interaction([payer_name, provider_name], "service_payment", {
			"amount": payment,
			"reason": "专业服务"
		})

## === 游戏日志集成 ===

func _log_to_game_ui(event_type: String, arg1 = null, arg2 = null, arg3 = null, arg4 = null):
	"""将事件记录到游戏日志UI"""
	# 正确的路径：GameLogUI 在 GameLogLayer 下
	var log_ui = get_tree().root.get_node_or_null("GameLogLayer/GameLogUI")
	if not log_ui:
		# 仅在第一次提示即可，避免刷屏
		if not has_meta("log_ui_warning_shown"):
			print("⚠️ SceneExperimentTracker: 无法找到游戏日志UI (路径: GameLogLayer/GameLogUI)")
			set_meta("log_ui_warning_shown", true)
		return  # 日志UI未初始化
	
	match event_type:
		"wealth_changed":
			var agent_name = arg1
			var new_wealth = arg2
			if log_ui.has_method("add_log"):
				log_ui.add_log("💰财富", "%s 的财富变为 ¥%.2f" % [agent_name, new_wealth], "transaction")
		
		"transaction":
			var agent_name = arg1
			var amount = arg2
			var tx_type = arg3
			var source = arg4
			if log_ui.has_method("add_log"):
				var msg = "%s: ¥%.2f" % [agent_name, amount]
				if source:
					msg += " (%s)" % source
				log_ui.add_log("💳交易", msg, "transaction")
		
		"interaction":
			var agent_names = arg1
			var interaction_type = arg2
			var details = arg3
			
			# 特殊处理涉及金额的交互
			if interaction_type in ["trade", "gift", "help", "invest"] and agent_names.size() >= 2:
				var amount = details.get("amount", 0.0)
				var reason = details.get("reason", "")
				if log_ui.has_method("log_transaction"):
					log_ui.log_transaction(agent_names[0], agent_names[1], amount, reason)
				return
				
			if log_ui.has_method("log_interaction") and agent_names.size() >= 2:
				var details_str = ""
				if details and not details.is_empty():
					# 尝试从details中提取有用信息
					if details.has("amount"):
						details_str += "¥%.2f " % details.get("amount")
					if details.has("reason"):
						details_str += "(%s) " % details.get("reason")
					if details.has("investment"):
						details_str += "投入¥%.2f " % details.get("investment")
					if details.has("return"):
						details_str += "回报¥%.2f " % details.get("return")
					if details.has("description"):
						details_str += str(details.get("description", ""))
						
				log_ui.log_interaction(agent_names[0], agent_names[1], interaction_type, details_str)
			elif log_ui.has_method("add_log"):
				log_ui.add_log("🤝交互", "%s - %s" % [", ".join(agent_names), interaction_type], "interaction")

extends Node
class_name EconomicDecisionMaker

## 经济决策模块
## 让AI agent能够自主进行经济决策：交易、投资、合作等

# 决策类型
enum DecisionType {
	NONE,           # 不采取行动
	TRADE,          # 发起交易
	REQUEST_HELP,   # 请求帮助
	OFFER_HELP,     # 提供帮助
	COOPERATE,      # 发起合作
	INVEST          # 投资
}

# 引用
var scene_tracker: Node = null
var character_node: CharacterBody2D = null
var economic_agent: EconomicAgent = null

# 决策参数
var decision_cooldown: float = 15.0  # 决策冷却时间（秒）
var last_decision_time: float = 0.0
var nearby_distance: float = 300.0  # 感知范围

func _init(char_node: CharacterBody2D):
	character_node = char_node
	scene_tracker = get_node_or_null("/root/SceneExperimentTracker")

func _ready():
	if not scene_tracker:
		scene_tracker = get_node_or_null("/root/SceneExperimentTracker")

## 评估是否应该做出经济决策
func should_make_decision() -> bool:
	var current_time = Time.get_unix_time_from_system()
	return (current_time - last_decision_time) >= decision_cooldown

## 主决策函数
func make_economic_decision() -> Dictionary:
	"""
	基于agent的状态和个性做出经济决策
	返回决策结果 {type: DecisionType, target: String, details: Dictionary}
	"""
	if not should_make_decision():
		return {"type": DecisionType.NONE}
	
	# 获取经济代理
	if not economic_agent and scene_tracker:
		economic_agent = scene_tracker.get_agent(character_node.name)
	
	if not economic_agent:
		return {"type": DecisionType.NONE}
	
	# 评估自身状态
	var self_assessment = _assess_self_state()
	
	# 感知周围的agent
	var nearby_agents = _perceive_nearby_agents()
	
	if nearby_agents.is_empty():
		return {"type": DecisionType.NONE}
	
	# 根据状态和个性做决策
	var decision = _decide_action(self_assessment, nearby_agents)
	
	if decision.type != DecisionType.NONE:
		last_decision_time = Time.get_unix_time_from_system()
	
	return decision

## 评估自身状态
func _assess_self_state() -> Dictionary:
	"""评估agent的经济和心理状态"""
	var wealth = economic_agent.wallet.get_net_worth()
	var psych = economic_agent.get_psychological_summary()
	
	return {
		"wealth": wealth,
		"wealth_level": _categorize_wealth(wealth),
		"mood": psych.get("mood", 0.5),
		"stress": psych.get("stress_level", 0.5),
		"satisfaction": psych.get("satisfaction", 0.5),
		"confidence": psych.get("confidence", 0.5),
		"altruism": economic_agent.altruism,
		"trust_level": economic_agent.trust_level,
		"risk_aversion": economic_agent.risk_aversion
	}

## 感知周围的agent
func _perceive_nearby_agents() -> Array:
	"""获取附近的其他agent"""
	if not scene_tracker:
		return []
	
	var all_agents = scene_tracker.get_all_agents()
	var nearby = []
	
	for agent_name in all_agents.keys():
		if agent_name == character_node.name:
			continue
		
		# 获取对应的CharacterBody2D节点
		var target_character = _get_character_by_name(agent_name)
		if not target_character:
			continue
		
		# 计算距离
		var distance = character_node.global_position.distance_to(target_character.global_position)
		if distance <= nearby_distance:
			var agent = all_agents[agent_name]
			nearby.append({
				"name": agent_name,
				"character": target_character,
				"agent": agent,
				"distance": distance,
				"wealth": agent.wallet.get_net_worth() if agent.wallet else 0.0
			})
	
	return nearby

## 决策主逻辑
func _decide_action(self_state: Dictionary, nearby_agents: Array) -> Dictionary:
	"""根据状态和周围agent决定行动"""
	
	# 1. 如果心情很差或压力很大，可能寻求帮助
	if self_state.stress > 0.7 and self_state.altruism > 0.4:
		var helper = _find_wealthiest_agent(nearby_agents)
		if helper and helper.wealth > self_state.wealth * 1.5:
			return {
				"type": DecisionType.REQUEST_HELP,
				"target": helper.name,
				"amount": min(500.0, self_state.wealth * 0.1),
				"reason": "需要帮助度过困难时期"
			}
	
	# 2. 如果富裕且利他，可能提供帮助
	if self_state.wealth_level >= 3 and self_state.altruism > 0.6:
		var needy = _find_poorest_agent(nearby_agents)
		if needy and needy.wealth < self_state.wealth * 0.5:
			return {
				"type": DecisionType.OFFER_HELP,
				"target": needy.name,
				"amount": min(1000.0, self_state.wealth * 0.05),
				"reason": "帮助有需要的人"
			}
	
	# 3. 如果信任度高且满意度高，发起合作交易
	if self_state.trust_level > 0.6 and self_state.satisfaction > 0.5:
		var partner = _find_suitable_trade_partner(nearby_agents, self_state)
		if partner:
			return {
				"type": DecisionType.TRADE,
				"target": partner.name,
				"amount": _calculate_trade_amount(self_state, partner),
				"reason": "互惠互利的交易"
			}
	
	# 4. 如果风险厌恶低且有钱，可能进行投资交易
	if self_state.risk_aversion < 0.4 and self_state.wealth_level >= 3 and self_state.confidence > 0.6:
		var investment_target = _find_random_agent(nearby_agents)
		if investment_target:
			return {
				"type": DecisionType.INVEST,
				"target": investment_target.name,
				"amount": _calculate_investment_amount(self_state),
				"reason": "投资合作"
			}
	
	return {"type": DecisionType.NONE}

## 执行决策
func execute_decision(decision: Dictionary) -> bool:
	"""执行经济决策"""
	if decision.type == DecisionType.NONE:
		return false
	
	var target_name = decision.get("target", "")
	if target_name.is_empty():
		return false
	
	# 获取目标agent
	var target_agent = scene_tracker.get_agent(target_name) if scene_tracker else null
	if not target_agent:
		return false
	
	match decision.type:
		DecisionType.TRADE, DecisionType.INVEST:
			return _execute_trade(target_agent, decision)
		DecisionType.OFFER_HELP:
			return _execute_gift(target_agent, decision)
		DecisionType.REQUEST_HELP:
			return _request_help_from(target_agent, decision)
		DecisionType.COOPERATE:
			return _propose_cooperation(target_agent, decision)
	
	return false

## 执行交易
func _execute_trade(target_agent: EconomicAgent, decision: Dictionary) -> bool:
	"""执行与另一个agent的交易"""
	var amount = decision.get("amount", 0.0)
	var reason = decision.get("reason", "交易")
	
	if amount <= 0 or amount > economic_agent.wallet.cash:
		return false
	
	# 转账
	var success = economic_agent.wallet.transfer(target_agent.wallet, amount, reason)
	
	if success:
		print("💱 %s 向 %s 交易了 ¥%.2f (%s)" % [character_node.name, target_agent.character_name, amount, reason])
		
		# 记录交互
		if scene_tracker:
			scene_tracker.record_interaction(
				[character_node.name, target_agent.character_name],
				"trade",
				{"amount": amount, "reason": reason}
			)
		
		# 对方也给予回报（基于对方的reciprocity）
		if randf() < target_agent.reciprocity:
			var return_amount = amount * randf_range(0.5, 1.2)
			return_amount = min(return_amount, target_agent.wallet.cash)
			if return_amount > 0:
				target_agent.wallet.transfer(economic_agent.wallet, return_amount, "回报交易")
				print("💱 %s 回报了 %s ¥%.2f" % [target_agent.character_name, character_node.name, return_amount])
	
	return success

## 执行赠予
func _execute_gift(target_agent: EconomicAgent, decision: Dictionary) -> bool:
	"""赠予金钱给目标agent"""
	var amount = decision.get("amount", 0.0)
	var reason = decision.get("reason", "赠予")
	
	if amount <= 0 or amount > economic_agent.wallet.cash:
		return false
	
	var success = economic_agent.wallet.transfer(target_agent.wallet, amount, reason)
	
	if success:
		print("🎁 %s 赠予了 %s ¥%.2f (%s)" % [character_node.name, target_agent.character_name, amount, reason])
		
		if scene_tracker:
			scene_tracker.record_interaction(
				[character_node.name, target_agent.character_name],
				"gift",
				{"amount": amount, "reason": reason}
			)
	
	return success

## 请求帮助
func _request_help_from(target_agent: EconomicAgent, decision: Dictionary) -> bool:
	"""向目标agent请求帮助"""
	var amount = decision.get("amount", 0.0)
	
	# 基于目标的利他性和信任度决定是否提供帮助
	var help_probability = target_agent.altruism * 0.6 + target_agent.trust_level * 0.4
	
	if randf() < help_probability:
		var actual_amount = min(amount, target_agent.wallet.cash * 0.1)
		if actual_amount > 0:
			var success = target_agent.wallet.transfer(economic_agent.wallet, actual_amount, "提供帮助")
			if success:
				print("🤝 %s 帮助了 %s ¥%.2f" % [target_agent.character_name, character_node.name, actual_amount])
				
				if scene_tracker:
					scene_tracker.record_interaction(
						[character_node.name, target_agent.character_name],
						"help",
						{"amount": actual_amount, "requester": character_node.name}
					)
				return true
	
	return false

## 提议合作
func _propose_cooperation(target_agent: EconomicAgent, decision: Dictionary) -> bool:
	"""提议合作项目"""
	# 简化实现：双方各出一部分钱，然后平分收益
	var investment = decision.get("amount", 0.0)
	
	if investment <= 0 or investment > economic_agent.wallet.cash:
		return false
	
	# 目标agent根据信任度决定是否参与
	if randf() < target_agent.trust_level:
		var target_investment = min(investment, target_agent.wallet.cash)
		var total_pool = investment + target_investment
		var return_multiplier = randf_range(1.1, 1.5)
		var total_return = total_pool * return_multiplier
		
		# 扣除投资
		economic_agent.wallet.withdraw(investment, "合作投资")
		target_agent.wallet.withdraw(target_investment, "合作投资")
		
		# 分配收益
		var share_a = total_return * 0.5
		var share_b = total_return * 0.5
		
		economic_agent.wallet.deposit(share_a, "合作收益")
		target_agent.wallet.deposit(share_b, "合作收益")
		
		print("🤝 %s 和 %s 合作投资，各得 ¥%.2f" % [character_node.name, target_agent.character_name, share_a])
		
		if scene_tracker:
			scene_tracker.record_interaction(
				[character_node.name, target_agent.character_name],
				"cooperation",
				{"investment": investment, "return": share_a}
			)
		
		return true
	
	return false

## 辅助函数

func _categorize_wealth(wealth: float) -> int:
	"""将财富分类为等级 1-5"""
	if wealth < 5000:
		return 1
	elif wealth < 10000:
		return 2
	elif wealth < 15000:
		return 3
	elif wealth < 25000:
		return 4
	else:
		return 5

func _find_wealthiest_agent(agents: Array):
	"""找到最富有的agent"""
	if agents.is_empty():
		return null
	
	var wealthiest = agents[0]
	for agent_data in agents:
		if agent_data.wealth > wealthiest.wealth:
			wealthiest = agent_data
	
	return wealthiest

func _find_poorest_agent(agents: Array):
	"""找到最贫穷的agent"""
	if agents.is_empty():
		return null
	
	var poorest = agents[0]
	for agent_data in agents:
		if agent_data.wealth < poorest.wealth:
			poorest = agent_data
	
	return poorest

func _find_suitable_trade_partner(agents: Array, self_state: Dictionary):
	"""找到合适的交易伙伴"""
	# 找财富相近的agent
	var suitable = []
	for agent_data in agents:
		var wealth_ratio = agent_data.wealth / self_state.wealth if self_state.wealth > 0 else 1.0
		if wealth_ratio > 0.5 and wealth_ratio < 2.0:
			suitable.append(agent_data)
	
	if suitable.is_empty():
		return null
	
	return suitable[randi() % suitable.size()]

func _find_random_agent(agents: Array):
	"""随机选择一个agent"""
	if agents.is_empty():
		return null
	return agents[randi() % agents.size()]

func _calculate_trade_amount(self_state: Dictionary, partner) -> float:
	"""计算交易金额"""
	var base_amount = self_state.wealth * 0.05  # 5%的财富
	var risk_factor = 1.0 - self_state.risk_aversion * 0.5
	return base_amount * risk_factor

func _calculate_investment_amount(self_state: Dictionary) -> float:
	"""计算投资金额"""
	var base_amount = self_state.wealth * 0.1  # 10%的财富
	var confidence_factor = self_state.confidence
	return base_amount * confidence_factor

func _get_character_by_name(char_name: String) -> CharacterBody2D:
	"""根据名字获取角色节点"""
	var characters = get_tree().get_nodes_in_group("controllable_characters")
	for char in characters:
		if char.name == char_name:
			return char
	return null


extends Node
class_name EconomicAgent

## Economic agent with financial decision-making capabilities
##
## Extends base character with economic behaviors including:
## - Wallet management and budgeting
## - Market participation (buying/selling)
## - Game participation (ultimatum, trust, etc.)
## - Risk assessment and utility maximization

# Reference to character and core systems
var character_name: String = ""
var wallet: Wallet = null

# Economic personality traits (0.0 to 1.0)
var risk_aversion: float = 0.5      # Higher = more risk averse
var time_preference: float = 0.5    # Higher = prefers future rewards
var altruism: float = 0.5           # Higher = more generous
var fairness_concern: float = 0.5   # Higher = values fairness
var trust_level: float = 0.5        # Higher = more trusting
var reciprocity: float = 0.5        # Higher = reciprocates more

# Learning and adaptation
var learning_rate: float = 0.1
var memory_decay: float = 0.95
var experience_history: Array = []

# Current state
var current_utility: float = 0.0
var recent_gains: float = 0.0
var recent_losses: float = 0.0

# Psychological state tracking (for scene experiments)
var psychological_state: Dictionary = {
	"satisfaction": 0.5,      # 满意度 (0-1)
	"stress": 0.0,            # 压力水平 (0-1)
	"confidence": 0.5,        # 自信心 (0-1)
	"social_standing": 0.5,   # 社会地位感 (0-1)
	"mood": 0.5,              # 心情 (0-1, 0=消极, 1=积极)
	"motivation": 0.5,        # 动机水平 (0-1)
	"envy": 0.0,              # 嫉妒程度 (0-1)
	"gratitude": 0.0          # 感激程度 (0-1)
}
var psychological_history: Array = []  # 心理状态历史记录

# Decision style
enum DecisionStyle { RATIONAL, BOUNDED_RATIONAL, HEURISTIC, EMOTIONAL }
var decision_style: DecisionStyle = DecisionStyle.BOUNDED_RATIONAL

## Initialize agent
func _init(p_name: String = "", initial_cash: float = 100.0):
	character_name = p_name
	wallet = Wallet.new(initial_cash, p_name)
	
	# Connect wallet signals
	wallet.balance_changed.connect(_on_wallet_balance_changed)
	wallet.transaction_recorded.connect(_on_transaction_recorded)

## Load personality from configuration
func load_personality(config: Dictionary):
	risk_aversion = config.get("risk_aversion", 0.5)
	time_preference = config.get("time_preference", 0.5)
	altruism = config.get("altruism", 0.5)
	fairness_concern = config.get("fairness_concern", 0.5)
	trust_level = config.get("trust_level", 0.5)
	reciprocity = config.get("reciprocity", 0.5)
	learning_rate = config.get("learning_rate", 0.1)
	
	var style_str = config.get("decision_style", "bounded_rational")
	match style_str.to_lower():
		"rational": decision_style = DecisionStyle.RATIONAL
		"bounded_rational": decision_style = DecisionStyle.BOUNDED_RATIONAL
		"heuristic": decision_style = DecisionStyle.HEURISTIC
		"emotional": decision_style = DecisionStyle.EMOTIONAL

## Calculate utility from current wealth
func calculate_utility(wealth: float) -> float:
	# Use utility function based on risk aversion
	if risk_aversion > 0.7:
		# Risk averse: logarithmic utility
		return log(max(1.0, wealth)) / log(10.0)
	elif risk_aversion < 0.3:
		# Risk seeking: exponential utility
		return pow(wealth / 100.0, 1.2)
	else:
		# Risk neutral: linear utility
		return wealth / 100.0

## Evaluate a risky choice (expected utility theory)
func evaluate_risky_choice(outcomes: Array, probabilities: Array) -> float:
	if outcomes.size() != probabilities.size():
		push_error("EconomicAgent: Outcomes and probabilities must have same size")
		return 0.0
	
	var expected_utility = 0.0
	for i in range(outcomes.size()):
		var outcome_utility = calculate_utility(outcomes[i])
		expected_utility += probabilities[i] * outcome_utility
	
	return expected_utility

## Decide whether to accept a risky gamble
func should_accept_gamble(gain: float, loss: float, prob_gain: float) -> bool:
	var current_wealth = wallet.get_net_worth()
	
	# Calculate expected utilities
	var current_utility = calculate_utility(current_wealth)
	var gain_utility = calculate_utility(current_wealth + gain)
	var loss_utility = calculate_utility(current_wealth - loss)
	
	var expected_gamble_utility = prob_gain * gain_utility + (1.0 - prob_gain) * loss_utility
	
	# Add noise based on decision style
	var noise = 0.0
	match decision_style:
		DecisionStyle.RATIONAL:
			noise = 0.0
		DecisionStyle.BOUNDED_RATIONAL:
			noise = randf_range(-0.1, 0.1)
		DecisionStyle.HEURISTIC:
			noise = randf_range(-0.2, 0.2)
		DecisionStyle.EMOTIONAL:
			noise = randf_range(-0.3, 0.3)
	
	return expected_gamble_utility + noise > current_utility

## Make an offer in Ultimatum Game
func make_ultimatum_offer(total_amount: float) -> float:
	# Base offer on fairness concern and altruism
	var fair_offer = total_amount * 0.5
	var selfish_offer = total_amount * 0.2
	
	# Weight by personality
	var offer = fair_offer * (fairness_concern + altruism) / 2.0 + selfish_offer * (1.0 - (fairness_concern + altruism) / 2.0)
	
	# Add bounded rationality noise
	if decision_style != DecisionStyle.RATIONAL:
		var noise_range = total_amount * 0.1
		offer += randf_range(-noise_range, noise_range)
	
	return clamp(offer, 0.0, total_amount)

## Decide whether to accept an offer in Ultimatum Game
func should_accept_ultimatum(offer: float, total: float) -> bool:
	var offer_ratio = offer / total
	
	# Fairness threshold based on fairness concern
	var min_acceptable = 0.5 - (1.0 - fairness_concern) * 0.3  # Range: 0.2 to 0.5
	
	# Risk aversion factor (more risk averse = more likely to accept)
	var risk_adjustment = risk_aversion * 0.1
	
	# Emotional noise
	var noise = 0.0
	if decision_style == DecisionStyle.EMOTIONAL:
		noise = randf_range(-0.15, 0.15)
	
	var threshold = min_acceptable - risk_adjustment + noise
	
	var will_accept = offer_ratio >= threshold
	
	# Record decision for learning
	_record_experience({
		"game": "ultimatum_responder",
		"offer_ratio": offer_ratio,
		"accepted": will_accept,
		"threshold": threshold
	})
	
	return will_accept

## Decide trust amount in Trust Game (as trustor)
func decide_trust_amount(initial_endowment: float, multiplier: float) -> float:
	# Expected return if trustee reciprocates
	var expected_return = initial_endowment * multiplier * reciprocity
	
	# Discount by trust level and risk aversion
	var trust_factor = trust_level * (1.0 - risk_aversion * 0.5)
	
	var send_amount = initial_endowment * trust_factor
	
	# Bounded rationality
	if decision_style != DecisionStyle.RATIONAL:
		send_amount += randf_range(-initial_endowment * 0.2, initial_endowment * 0.2)
	
	return clamp(send_amount, 0.0, initial_endowment)

## Decide return amount in Trust Game (as trustee)
func decide_return_amount(received_amount: float, multiplier: float) -> float:
	var total_available = received_amount * multiplier
	
	# Base return on reciprocity and fairness
	var fair_return = total_available * 0.5
	var reciprocal_return = received_amount  # Return what was sent
	
	var return_amount = fair_return * fairness_concern + reciprocal_return * reciprocity
	return_amount /= (fairness_concern + reciprocity) if (fairness_concern + reciprocity) > 0 else 1.0
	
	# Adjust for altruism vs selfishness
	return_amount = return_amount * (0.5 + altruism * 0.5)
	
	# Add noise
	if decision_style != DecisionStyle.RATIONAL:
		return_amount += randf_range(-total_available * 0.15, total_available * 0.15)
	
	return clamp(return_amount, 0.0, total_available)

## Decide contribution to public goods
func decide_public_goods_contribution(endowment: float, group_size: int, multiplier: float) -> float:
	# Calculate incentive to free-ride
	var free_ride_payoff = endowment  # Keep everything
	
	# Calculate cooperative payoff (assuming others contribute average)
	var expected_others_contrib = endowment * 0.5 * (group_size - 1)
	var my_contrib = endowment * 0.5
	var total_pool = (expected_others_contrib + my_contrib) * multiplier
	var coop_payoff = (endowment - my_contrib) + (total_pool / group_size)
	
	# Weight by altruism and fairness concern
	var cooperation_tendency = (altruism + fairness_concern) / 2.0
	
	var contribution = endowment * cooperation_tendency * 0.7
	
	# Past experience influence
	if experience_history.size() > 0:
		var recent_coop_success = _get_recent_cooperation_success()
		contribution += endowment * 0.2 * recent_coop_success
	
	# Add noise
	if decision_style != DecisionStyle.RATIONAL:
		contribution += randf_range(-endowment * 0.2, endowment * 0.2)
	
	return clamp(contribution, 0.0, endowment)

## Decide market purchase price (maximum willing to pay)
func decide_max_purchase_price(good_id: String, market: Market, urgency: float = 0.5) -> float:
	var current_price = market.get_current_price(good_id)
	var best_ask = market.get_best_ask(good_id)
	
	# Base price on current market price
	var base_price = current_price if current_price > 0 else best_ask
	
	# Adjust for urgency and patience
	var premium = base_price * urgency * 0.2
	
	# Risk averse agents pay more to ensure purchase
	premium += base_price * risk_aversion * 0.1
	
	var max_price = base_price + premium
	
	# Can't pay more than available cash
	max_price = min(max_price, wallet.cash)
	
	return max_price

## Decide market sale price (minimum willing to accept)
func decide_min_sale_price(good_id: String, market: Market, urgency: float = 0.5) -> float:
	var current_price = market.get_current_price(good_id)
	var best_bid = market.get_best_bid(good_id)
	
	# Base price on current market price
	var base_price = current_price if current_price > 0 else best_bid
	
	# Discount for urgency (need to sell quickly)
	var discount = base_price * urgency * 0.15
	
	var min_price = base_price - discount
	
	return max(min_price, market.min_price)

## Update preferences based on experience (reinforcement learning)
func update_from_experience(outcome: Dictionary):
	var reward = outcome.get("reward", 0.0)
	var action_type = outcome.get("action_type", "")
	
	# Update utility
	var wealth_change = reward
	recent_gains += max(0, wealth_change)
	recent_losses += abs(min(0, wealth_change))
	
	# Update trait based on outcome
	match action_type:
		"trust":
			if reward > 0:
				trust_level = min(1.0, trust_level + learning_rate * 0.1)
			else:
				trust_level = max(0.0, trust_level - learning_rate * 0.2)
			# preference_updated.emit("trust_level", trust_level)
		
		"cooperation":
			if reward > 0:
				altruism = min(1.0, altruism + learning_rate * 0.1)
			else:
				altruism = max(0.0, altruism - learning_rate * 0.15)
			# preference_updated.emit("altruism", altruism)
		
		"risk_taking":
			if reward > 0:
				risk_aversion = max(0.0, risk_aversion - learning_rate * 0.1)
			else:
				risk_aversion = min(1.0, risk_aversion + learning_rate * 0.15)
			# preference_updated.emit("risk_aversion", risk_aversion)
	
	# Record experience
	_record_experience(outcome)

## Get personality summary
func get_personality() -> Dictionary:
	return {
		"character_name": character_name,
		"risk_aversion": risk_aversion,
		"time_preference": time_preference,
		"altruism": altruism,
		"fairness_concern": fairness_concern,
		"trust_level": trust_level,
		"reciprocity": reciprocity,
		"decision_style": DecisionStyle.keys()[decision_style]
	}

## Export agent data
func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"personality": get_personality(),
		"wallet": wallet.to_dict(),
		"current_utility": current_utility,
		"recent_gains": recent_gains,
		"recent_losses": recent_losses,
		"experience_count": experience_history.size(),
		"psychological_state": psychological_state.duplicate()
	}

## Private: Record experience for learning
func _record_experience(experience: Dictionary):
	experience["timestamp"] = Time.get_unix_time_from_system()
	experience_history.append(experience)
	
	# Limit history size
	if experience_history.size() > 100:
		experience_history.remove_at(0)

## Private: Get recent cooperation success rate
func _get_recent_cooperation_success() -> float:
	var coop_experiences = []
	for exp in experience_history:
		if exp.get("game", "") in ["public_goods", "trust"]:
			coop_experiences.append(exp)
	
	if coop_experiences.is_empty():
		return 0.0
	
	var success_count = 0
	for exp in coop_experiences.slice(max(0, coop_experiences.size() - 10)):
		if exp.get("reward", 0.0) > 0:
			success_count += 1
	
	return float(success_count) / min(10, coop_experiences.size())

## Private: Wallet balance changed callback
func _on_wallet_balance_changed(new_balance: float):
	current_utility = calculate_utility(wallet.get_net_worth())
	# utility_changed.emit(current_utility)

## Private: Transaction recorded callback
func _on_transaction_recorded(transaction: Dictionary):
	"""处理交易记录，更新收益/损失统计"""
	var tx_type = transaction.get("type", "unknown")
	var amount = transaction.get("amount", 0.0)
	var source = transaction.get("source", "")
	var reason = transaction.get("reason", "")
	
	# 更新收益和损失
	match tx_type:
		"deposit", "transfer_in", "interest_earned", "borrow":
			# 这些是收入类型
			recent_gains += amount
			print("📈 %s: 收益 +¥%.2f (总收益: ¥%.2f)" % [character_name, amount, recent_gains])
		
		"withdraw", "transfer_out", "interest_charged", "repay":
			# 这些是支出类型
			recent_losses += amount
			print("📉 %s: 损失 -¥%.2f (总损失: ¥%.2f)" % [character_name, amount, recent_losses])
		
		"initialization", "reset":
			# 初始化和重置不算收益或损失
			pass
	
	# 记录到经验历史
	if tx_type not in ["initialization", "reset"]:
		experience_history.append({
			"type": "transaction",
			"transaction_type": tx_type,
			"amount": amount,
			"timestamp": Time.get_unix_time_from_system(),
			"balance_after": wallet.cash
		})
		
		# 添加到角色记忆系统
		_add_transaction_to_memory(tx_type, amount, source, reason)

## 将交易添加到角色记忆
func _add_transaction_to_memory(tx_type: String, amount: float, source: String, reason: String):
	"""将交易记录添加到角色的记忆系统中"""
	# 获取角色节点（通过CharacterManager查找）
	var character_node = _get_character_node()
	if not character_node:
		# 如果无法获取角色节点，静默失败（可能在实验场景中）
		# print("⚠️ EconomicAgent: 无法获取角色节点 %s，跳过记忆添加" % character_name)
		return
	
	# 构建记忆文本
	var memory_text = _format_transaction_memory(tx_type, amount, source, reason)
	if memory_text.is_empty():
		return
	
	# 确定记忆重要性
	var importance = MemoryManager.MemoryImportance.NORMAL
	if amount > 1000:
		importance = MemoryManager.MemoryImportance.CRITICAL
	elif amount > 500:
		importance = MemoryManager.MemoryImportance.HIGH
	
	# 添加到记忆系统
	if MemoryManager:
		MemoryManager.add_memory(character_node, memory_text, MemoryManager.MemoryType.PERSONAL, importance)
		# print("💭 %s: 记忆已添加 - \"%s\"" % [character_name, memory_text])

## 格式化交易记忆文本
func _format_transaction_memory(tx_type: String, amount: float, source: String, reason: String) -> String:
	"""根据交易类型格式化记忆文本"""
	var memory_text = ""
	
	match tx_type:
		"deposit":
			if source.contains("transfer_in"):
				# 从其他人转账收到
				var from_name = _extract_name_from_source(source)
				memory_text = "收到了来自%s的转账 ¥%.2f" % [from_name, amount]
			elif source.contains("赠予"):
				var from_name = _extract_name_from_source(source)
				memory_text = "收到了%s赠予的 ¥%.2f" % [from_name, amount]
			elif source.contains("借入"):
				var from_name = _extract_name_from_source(source)
				memory_text = "向%s借入了 ¥%.2f" % [from_name, amount]
			elif source.contains("投资收益"):
				memory_text = "获得投资收益 ¥%.2f" % amount
			elif source.contains("出售"):
				var to_name = _extract_name_from_source(source)
				memory_text = "向%s出售商品/服务获得 ¥%.2f" % [to_name, amount]
			else:
				memory_text = "收入 ¥%.2f (%s)" % [amount, source if not source.is_empty() else "未知来源"]
		
		"withdraw":
			if reason.contains("transfer_out"):
				var to_name = _extract_name_from_source(reason)
				memory_text = "向%s转账 ¥%.2f" % [to_name, amount]
			elif reason.contains("赠予"):
				var to_name = _extract_name_from_source(reason)
				memory_text = "赠予了%s ¥%.2f" % [to_name, amount]
			elif reason.contains("借出"):
				var to_name = _extract_name_from_source(reason)
				memory_text = "借给%s ¥%.2f" % [to_name, amount]
			elif reason.contains("投资损失"):
				memory_text = "投资损失 ¥%.2f" % amount
			elif reason.contains("购买"):
				var from_name = _extract_name_from_source(reason)
				memory_text = "向%s购买商品/服务花费 ¥%.2f" % [from_name, amount]
			elif reason.contains("服务费用"):
				var to_name = _extract_name_from_source(reason)
				memory_text = "向%s支付服务费用 ¥%.2f" % [to_name, amount]
			else:
				memory_text = "支出 ¥%.2f (%s)" % [amount, reason if not reason.is_empty() else "未知原因"]
		
		"transfer_in":
			var from_name = _extract_name_from_source(source)
			memory_text = "收到来自%s的转账 ¥%.2f" % [from_name, amount]
		
		"transfer_out":
			var to_name = _extract_name_from_source(reason)
			memory_text = "向%s转账 ¥%.2f" % [to_name, amount]
		
		"borrow":
			memory_text = "借入资金 ¥%.2f" % amount
		
		"repay":
			memory_text = "偿还借款 ¥%.2f" % amount
		
		"interest_earned":
			memory_text = "获得利息收入 ¥%.2f" % amount
		
		"interest_charged":
			memory_text = "支付利息 ¥%.2f" % amount
	
	return memory_text

## 从source/reason中提取人名
func _extract_name_from_source(text: String) -> String:
	"""从交易来源或原因文本中提取人名"""
	# 常见的人名列表
	var names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", 
				 "Grace", "Henry", "Ivy", "Jack", "Kate", "Leo", 
				 "Monica", "Nancy", "Oliver", "Peter", "Quinn", "Rose",
				 "Stephen", "Tom", "Uma", "Victor", "Wendy", "Xavier",
				 "Yolanda", "Zack", "Joe", "Lea"]
	
	for name in names:
		if text.contains(name):
			return name
	
	return "某人"

## 获取角色节点
func _get_character_node() -> Node:
	"""通过CharacterManager获取角色节点"""
	# EconomicAgent不在场景树中，需要通过其他方式获取SceneTree
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null
	
	# 尝试通过角色名称获取节点
	var characters = scene_tree.get_nodes_in_group("controllable_characters")
	for character in characters:
		if character.name == character_name:
			return character
	
	return null

## === Psychological State Management (for Scene Experiments) ===

## Update psychological state based on recent experiences
func update_psychological_state(other_agents: Array = []):
	"""更新心理状态，考虑财富变化、社会比较等因素"""
	
	# 先衰减过去的收益和损失（模拟"遗忘"和时间流逝）
	var decay_rate = 0.90  # 每次更新保留90%，让情绪逐渐恢复
	recent_gains *= decay_rate
	recent_losses *= decay_rate
	
	# 如果太小就清零，避免浮点数累积
	if recent_gains < 0.5:
		recent_gains = 0.0
	if recent_losses < 0.5:
		recent_losses = 0.0
	
	var wealth = wallet.get_net_worth()
	var wealth_change = recent_gains - recent_losses
	
	# 1. 满意度 - 基于财富和最近收益（调整阈值）
	# 考虑平均财富，避免固定阈值
	var avg_wealth = _calculate_average_wealth(other_agents) if other_agents.size() > 0 else 5000.0
	var target_wealth = max(avg_wealth, 5000.0)  # 目标财富为平均值或5000，取较大值
	var wealth_satisfaction = clamp(wealth / target_wealth, 0.0, 1.0)
	
	# 变化满意度：考虑相对变化而非绝对值
	var wealth_change_ratio = wealth_change / max(wealth, 100.0)  # 变化占当前财富的比例
	var change_satisfaction = clamp(wealth_change_ratio * 5.0 + 0.5, 0.0, 1.0)  # -10%变化=-0.5, +10%变化=+0.5
	
	psychological_state.satisfaction = (wealth_satisfaction * 0.6 + change_satisfaction * 0.4)
	
	# 2. 压力 - 基于损失率而非绝对值
	var loss_ratio = recent_losses / max(wealth, 100.0)  # 损失占财富的比例
	var loss_stress = clamp(loss_ratio * 3.0, 0.0, 0.8)  # 损失超过27%财富才会极度压力
	var debt_stress = clamp(wallet.debt / max(wealth * 0.5, 500.0), 0.0, 0.8)  # 债务超过50%财富才会极度压力
	psychological_state.stress = max(loss_stress, debt_stress)
	
	# 3. 自信心 - 基于最近成功率和财富
	var success_rate = _calculate_recent_success_rate()
	var wealth_confidence = clamp(wealth / 300.0, 0.0, 0.5)
	psychological_state.confidence = clamp(success_rate * 0.7 + wealth_confidence, 0.0, 1.0)
	
	# 4. 社会地位感 - 基于与他人的财富比较
	if other_agents.size() > 0:
		var my_rank = _calculate_wealth_rank(other_agents)
		psychological_state.social_standing = 1.0 - (float(my_rank) / float(other_agents.size()))
		
		# 5. 嫉妒 - 如果排名靠后
		if my_rank > other_agents.size() * 0.6:
			psychological_state.envy = clamp((float(my_rank) / float(other_agents.size()) - 0.5) * 2.0, 0.0, 1.0)
		else:
			psychological_state.envy = 0.0
	
	# 6. 心情 - 综合满意度和压力
	psychological_state.mood = clamp(
		psychological_state.satisfaction * 0.6 - psychological_state.stress * 0.4,
		0.0, 1.0
	)
	
	# 7. 动机 - 基于心情和自信
	psychological_state.motivation = clamp(
		(psychological_state.mood + psychological_state.confidence) / 2.0,
		0.0, 1.0
	)
	
	# 8. 感激 - 如果最近有正收益且信任/合作成功
	if wealth_change > 0 and _had_recent_positive_interaction():
		psychological_state.gratitude = clamp(wealth_change / 100.0, 0.0, 1.0)
	else:
		psychological_state.gratitude *= 0.9  # 逐渐衰减
	
	# 记录心理状态历史
	_record_psychological_state()

## Get psychological state summary
func get_psychological_summary() -> Dictionary:
	"""获取心理状态摘要"""
	return {
		"character_name": character_name,
		"satisfaction": psychological_state.satisfaction,
		"stress": psychological_state.stress,
		"confidence": psychological_state.confidence,
		"social_standing": psychological_state.social_standing,
		"mood": psychological_state.mood,
		"motivation": psychological_state.motivation,
		"envy": psychological_state.envy,
		"gratitude": psychological_state.gratitude,
		"mood_label": _get_mood_label(),
		"stress_label": _get_stress_label()
	}

## Get psychological trend over time
func get_psychological_trend(metric: String, recent_count: int = 10) -> Array:
	"""获取某个心理指标的历史趋势"""
	var trend = []
	var start_index = max(0, psychological_history.size() - recent_count)
	
	for i in range(start_index, psychological_history.size()):
		var record = psychological_history[i]
		if record.has(metric):
			trend.append({
				"timestamp": record.timestamp,
				"value": record[metric]
			})
	
	return trend

## Private: Calculate recent success rate
func _calculate_recent_success_rate() -> float:
	if experience_history.size() == 0:
		return 0.5  # 默认中等
	
	var recent_experiences = experience_history.slice(max(0, experience_history.size() - 10))
	var success_count = 0
	
	for exp in recent_experiences:
		if exp.get("reward", 0.0) > 0:
			success_count += 1
	
	return float(success_count) / float(recent_experiences.size())

## Private: Calculate average wealth among agents
func _calculate_average_wealth(agents: Array) -> float:
	"""计算所有agent的平均财富"""
	if agents.size() == 0:
		return 0.0
	
	var total_wealth = 0.0
	for agent in agents:
		if agent and agent.wallet:
			total_wealth += agent.wallet.get_net_worth()
	
	return total_wealth / agents.size()

## Private: Calculate wealth rank among other agents
func _calculate_wealth_rank(other_agents: Array) -> int:
	var my_wealth = wallet.get_net_worth()
	var rank = 1
	
	for agent in other_agents:
		if agent != self and agent.wallet.get_net_worth() > my_wealth:
			rank += 1
	
	return rank

## Private: Check if had recent positive interaction
func _had_recent_positive_interaction() -> bool:
	if experience_history.size() == 0:
		return false
	
	var recent = experience_history.slice(max(0, experience_history.size() - 5))
	for exp in recent:
		var game_type = exp.get("game", "")
		if game_type in ["trust", "public_goods", "cooperation"] and exp.get("reward", 0.0) > 0:
			return true
	
	return false

## Private: Record psychological state to history
func _record_psychological_state():
	var record = psychological_state.duplicate()
	record["timestamp"] = Time.get_unix_time_from_system()
	record["wealth"] = wallet.get_net_worth()
	
	psychological_history.append(record)
	
	# 限制历史记录大小
	if psychological_history.size() > 100:
		psychological_history.remove_at(0)

## Private: Get mood label
func _get_mood_label() -> String:
	var mood = psychological_state.mood
	if mood >= 0.8:
		return "非常愉快"
	elif mood >= 0.6:
		return "愉快"
	elif mood >= 0.4:
		return "平静"
	elif mood >= 0.2:
		return "低落"
	else:
		return "沮丧"

## Private: Get stress label
func _get_stress_label() -> String:
	var stress = psychological_state.stress
	if stress >= 0.8:
		return "极度压力"
	elif stress >= 0.6:
		return "高压力"
	elif stress >= 0.4:
		return "中等压力"
	elif stress >= 0.2:
		return "轻微压力"
	else:
		return "放松"

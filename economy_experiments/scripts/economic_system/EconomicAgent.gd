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
		"experience_count": experience_history.size()
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
	# Could track spending patterns here
	pass

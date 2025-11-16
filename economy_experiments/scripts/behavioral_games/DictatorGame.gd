extends GameBase
class_name DictatorGame

## Dictator Game implementation
##
## Two players: Dictator and Recipient
## Dictator receives endowment and decides how much to give to Recipient
## Recipient has no choice, must accept
## Tests pure altruism (no strategic incentive)

# Game-specific state
var endowment: float = 100.0
var dictator_id: String = ""
var recipient_id: String = ""
var gift_amount: float = 0.0

## Initialize
func _init(p_config: Dictionary = {}):
	super("dictator", p_config)
	game_name = "Dictator Game"
	required_players = 2
	max_players = 2

## Load configuration
func _load_config():
	super()
	endowment = config.get("endowment", 100.0)
	
	if config.has("dictator"):
		dictator_id = config.dictator
	if config.has("recipient"):
		recipient_id = config.recipient

## Add player with role assignment
func add_player(agent: EconomicAgent, role: String = "player") -> bool:
	if players.is_empty():
		if dictator_id.is_empty():
			role = "dictator"
			dictator_id = agent.character_name
		else:
			role = "dictator" if agent.character_name == dictator_id else "recipient"
	else:
		if recipient_id.is_empty():
			role = "recipient"
			recipient_id = agent.character_name
		else:
			role = "recipient" if agent.character_name == recipient_id else "dictator"
	
	return super(agent, role)

## Execute round logic
func _execute_round():
	# Get agents
	var dictator = _get_agent_by_role("dictator")
	var recipient = _get_agent_by_role("recipient")
	
	if not dictator or not recipient:
		push_error("DictatorGame: Missing players")
		finish_round({"error": "missing_players"})
		return
	
	# Dictator decides gift amount (pure altruism measure)
	# Since there's no strategic component, this directly reflects altruism
	gift_amount = endowment * dictator.altruism
	
	# Add some bounded rationality noise
	if dictator.decision_style != EconomicAgent.DecisionStyle.RATIONAL:
		var noise = randf_range(-endowment * 0.15, endowment * 0.15)
		gift_amount += noise
	
	gift_amount = clamp(gift_amount, 0.0, endowment)
	
	record_decision(dictator.character_name, {
		"action": "allocate",
		"gift": gift_amount,
		"kept": endowment - gift_amount,
		"gift_ratio": gift_amount / endowment
	})
	
	record_decision(recipient.character_name, {
		"action": "receive",
		"received": gift_amount
	})
	
	# Calculate payoffs
	var dictator_payoff = endowment - gift_amount
	var recipient_payoff = gift_amount
	
	record_payoff(dictator.character_name, dictator_payoff)
	record_payoff(recipient.character_name, recipient_payoff)
	
	# Update agent experiences
	dictator.update_from_experience({
		"game": "dictator_giver",
		"action_type": "altruism",
		"gift": gift_amount,
		"reward": dictator_payoff
	})
	
	recipient.update_from_experience({
		"game": "dictator_receiver",
		"action_type": "passive",
		"received": gift_amount,
		"reward": recipient_payoff
	})
	
	# Finish round with results
	var round_results = {
		"round": round_number,
		"endowment": endowment,
		"dictator": dictator.character_name,
		"recipient": recipient.character_name,
		"gift": gift_amount,
		"gift_ratio": gift_amount / endowment,
		"dictator_payoff": dictator_payoff,
		"recipient_payoff": recipient_payoff,
		"dictator_altruism": dictator.altruism
	}
	
	finish_round(round_results)

## Calculate final results
func _calculate_final_results() -> Dictionary:
	var base_results = super()
	
	# Add game-specific statistics
	var total_gift_ratio = 0.0
	var total_altruism = 0.0
	
	for result in results:
		total_gift_ratio += result.get("gift_ratio", 0.0)
		total_altruism += result.get("dictator_altruism", 0.0)
	
	base_results["average_gift_ratio"] = total_gift_ratio / results.size() if results.size() > 0 else 0.0
	base_results["average_altruism_trait"] = total_altruism / results.size() if results.size() > 0 else 0.0
	
	return base_results

## Helper: Get agent by role
func _get_agent_by_role(role: String) -> EconomicAgent:
	for player in players:
		if player.role == role:
			return player.agent
	return null


extends GameBase
class_name TrustGame

## Trust Game (Investment Game) implementation
##
## Two players: Trustor and Trustee
## Phase 1: Trustor decides how much to send (gets multiplied)
## Phase 2: Trustee decides how much to return
## Tests trust formation and reciprocity

# Game-specific state
var initial_endowment: float = 100.0
var multiplier: float = 3.0
var trustor_id: String = ""
var trustee_id: String = ""
var amount_sent: float = 0.0
var amount_returned: float = 0.0

## Initialize
func _init(p_config: Dictionary = {}):
	super("trust", p_config)
	game_name = "Trust Game"
	required_players = 2
	max_players = 2

## Load configuration
func _load_config():
	super()
	initial_endowment = config.get("endowment", 100.0)
	multiplier = config.get("multiplier", 3.0)
	
	if config.has("trustor"):
		trustor_id = config.trustor
	if config.has("trustee"):
		trustee_id = config.trustee

## Add player with role assignment
func add_player(agent: EconomicAgent, role: String = "player") -> bool:
	if players.is_empty():
		if trustor_id.is_empty():
			role = "trustor"
			trustor_id = agent.character_name
		else:
			role = "trustor" if agent.character_name == trustor_id else "trustee"
	else:
		if trustee_id.is_empty():
			role = "trustee"
			trustee_id = agent.character_name
		else:
			role = "trustee" if agent.character_name == trustee_id else "trustor"
	
	return super(agent, role)

## Execute round logic
func _execute_round():
	# Get agents
	var trustor = _get_agent_by_role("trustor")
	var trustee = _get_agent_by_role("trustee")
	
	if not trustor or not trustee:
		push_error("TrustGame: Missing players")
		finish_round({"error": "missing_players"})
		return
	
	# Phase 1: Trustor sends amount
	amount_sent = trustor.decide_trust_amount(initial_endowment, multiplier)
	amount_sent = clamp(amount_sent, 0.0, initial_endowment)
	
	record_decision(trustor.character_name, {
		"action": "send",
		"amount_sent": amount_sent,
		"amount_kept": initial_endowment - amount_sent,
		"send_ratio": amount_sent / initial_endowment
	})
	
	# Calculate multiplied amount
	var multiplied_amount = amount_sent * multiplier
	
	# Phase 2: Trustee returns amount
	amount_returned = trustee.decide_return_amount(amount_sent, multiplier)
	amount_returned = clamp(amount_returned, 0.0, multiplied_amount)
	
	record_decision(trustee.character_name, {
		"action": "return",
		"received": multiplied_amount,
		"returned": amount_returned,
		"kept": multiplied_amount - amount_returned,
		"return_ratio": amount_returned / multiplied_amount if multiplied_amount > 0 else 0.0
	})
	
	# Calculate payoffs
	var trustor_payoff = (initial_endowment - amount_sent) + amount_returned
	var trustee_payoff = initial_endowment + (multiplied_amount - amount_returned)
	
	record_payoff(trustor.character_name, trustor_payoff - initial_endowment)  # Net gain
	record_payoff(trustee.character_name, trustee_payoff - initial_endowment)  # Net gain
	
	# Update agent experiences
	var trust_rewarded = amount_returned > amount_sent
	
	trustor.update_from_experience({
		"game": "trust_trustor",
		"action_type": "trust",
		"amount_sent": amount_sent,
		"amount_returned": amount_returned,
		"trust_rewarded": trust_rewarded,
		"reward": trustor_payoff - initial_endowment
	})
	
	trustee.update_from_experience({
		"game": "trust_trustee",
		"action_type": "reciprocity",
		"received": multiplied_amount,
		"returned": amount_returned,
		"reward": trustee_payoff - initial_endowment
	})
	
	# Finish round with results
	var round_results = {
		"round": round_number,
		"initial_endowment": initial_endowment,
		"multiplier": multiplier,
		"trustor": trustor.character_name,
		"trustee": trustee.character_name,
		"amount_sent": amount_sent,
		"send_ratio": amount_sent / initial_endowment,
		"multiplied_amount": multiplied_amount,
		"amount_returned": amount_returned,
		"return_ratio": amount_returned / multiplied_amount if multiplied_amount > 0 else 0.0,
		"trustor_final": trustor_payoff,
		"trustee_final": trustee_payoff,
		"trustor_gain": trustor_payoff - initial_endowment,
		"trustee_gain": trustee_payoff - initial_endowment,
		"trust_rewarded": trust_rewarded
	}
	
	finish_round(round_results)

## Calculate final results
func _calculate_final_results() -> Dictionary:
	var base_results = super()
	
	# Add game-specific statistics
	var total_send_ratio = 0.0
	var total_return_ratio = 0.0
	var trust_rewarded_count = 0
	
	for result in results:
		total_send_ratio += result.get("send_ratio", 0.0)
		total_return_ratio += result.get("return_ratio", 0.0)
		if result.get("trust_rewarded", false):
			trust_rewarded_count += 1
	
	base_results["average_send_ratio"] = total_send_ratio / results.size() if results.size() > 0 else 0.0
	base_results["average_return_ratio"] = total_return_ratio / results.size() if results.size() > 0 else 0.0
	base_results["trust_success_rate"] = float(trust_rewarded_count) / results.size() if results.size() > 0 else 0.0
	
	return base_results

## Helper: Get agent by role
func _get_agent_by_role(role: String) -> EconomicAgent:
	for player in players:
		if player.role == role:
			return player.agent
	return null


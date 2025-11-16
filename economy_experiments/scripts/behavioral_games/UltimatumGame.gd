extends GameBase
class_name UltimatumGame

## Ultimatum Game implementation
##
## Two players: Proposer and Responder
## - Proposer receives endowment and offers split to Responder
## - Responder can accept (both get split) or reject (both get nothing)
## Tests fairness preferences and rejection behavior

# Game-specific state
var endowment: float = 100.0
var proposer_id: String = ""
var responder_id: String = ""
var offer_amount: float = 0.0
var accepted: bool = false

## Initialize
func _init(p_config: Dictionary = {}):
	super("ultimatum", p_config)
	game_name = "Ultimatum Game"
	required_players = 2
	max_players = 2

## Load configuration
func _load_config():
	super()
	endowment = config.get("endowment", 100.0)
	
	# Assign roles if specified
	if config.has("proposer"):
		proposer_id = config.proposer
	if config.has("responder"):
		responder_id = config.responder

## Add player with role assignment
func add_player(agent: EconomicAgent, role: String = "player") -> bool:
	# Auto-assign roles if not specified
	if players.is_empty():
		if proposer_id.is_empty():
			role = "proposer"
			proposer_id = agent.character_name
		else:
			role = "proposer" if agent.character_name == proposer_id else "responder"
	else:
		if responder_id.is_empty():
			role = "responder"
			responder_id = agent.character_name
		else:
			role = "responder" if agent.character_name == responder_id else "proposer"
	
	return super(agent, role)

## Execute round logic
func _execute_round():
	# Get agents
	var proposer = _get_agent_by_role("proposer")
	var responder = _get_agent_by_role("responder")
	
	if not proposer or not responder:
		push_error("UltimatumGame: Missing players")
		finish_round({"error": "missing_players"})
		return
	
	# Phase 1: Proposer makes offer
	offer_amount = proposer.make_ultimatum_offer(endowment)
	offer_amount = clamp(offer_amount, 0.0, endowment)
	
	record_decision(proposer.character_name, {
		"action": "propose",
		"offer": offer_amount,
		"keep": endowment - offer_amount,
		"offer_ratio": offer_amount / endowment
	})
	
	# Phase 2: Responder accepts or rejects
	accepted = responder.should_accept_ultimatum(offer_amount, endowment)
	
	record_decision(responder.character_name, {
		"action": "respond",
		"offer_received": offer_amount,
		"accepted": accepted
	})
	
	# Calculate payoffs
	var proposer_payoff = 0.0
	var responder_payoff = 0.0
	
	if accepted:
		proposer_payoff = endowment - offer_amount
		responder_payoff = offer_amount
	# else both get 0
	
	record_payoff(proposer.character_name, proposer_payoff)
	record_payoff(responder.character_name, responder_payoff)
	
	# Update agent experiences
	proposer.update_from_experience({
		"game": "ultimatum_proposer",
		"action_type": "fairness",
		"offer": offer_amount,
		"accepted": accepted,
		"reward": proposer_payoff
	})
	
	responder.update_from_experience({
		"game": "ultimatum_responder",
		"action_type": "fairness",
		"offer_received": offer_amount,
		"accepted": accepted,
		"reward": responder_payoff
	})
	
	# Finish round with results
	var round_results = {
		"round": round_number,
		"endowment": endowment,
		"proposer": proposer.character_name,
		"responder": responder.character_name,
		"offer": offer_amount,
		"offer_ratio": offer_amount / endowment,
		"accepted": accepted,
		"proposer_payoff": proposer_payoff,
		"responder_payoff": responder_payoff
	}
	
	finish_round(round_results)

## Calculate final results
func _calculate_final_results() -> Dictionary:
	var base_results = super()
	
	# Add game-specific statistics
	var total_offers = 0.0
	var acceptance_count = 0
	var rejection_count = 0
	
	for result in results:
		total_offers += result.get("offer_ratio", 0.0)
		if result.get("accepted", false):
			acceptance_count += 1
		else:
			rejection_count += 1
	
	base_results["average_offer_ratio"] = total_offers / results.size() if results.size() > 0 else 0.0
	base_results["acceptance_rate"] = float(acceptance_count) / results.size() if results.size() > 0 else 0.0
	base_results["rejection_rate"] = float(rejection_count) / results.size() if results.size() > 0 else 0.0
	base_results["total_accepted"] = acceptance_count
	base_results["total_rejected"] = rejection_count
	
	return base_results

## Helper: Get agent by role
func _get_agent_by_role(role: String) -> EconomicAgent:
	for player in players:
		if player.role == role:
			return player.agent
	return null

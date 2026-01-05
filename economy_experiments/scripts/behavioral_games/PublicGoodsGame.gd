extends GameBase
class_name PublicGoodsGame

## Public Goods Game implementation
##
## N players each receive endowment
## Simultaneously decide how much to contribute to public pool
## Pool is multiplied and distributed equally
## Tests cooperation vs. free-riding

# Game-specific state
var endowment: float = 100.0
var multiplier: float = 2.0
var resource_pool: ResourcePool = null
var contributions: Dictionary = {}  # player_id -> contribution

## Initialize
func _init(p_config: Dictionary = {}):
	super("public_goods", p_config)
	game_name = "Public Goods Game"
	required_players = 2
	max_players = 8

## Load configuration
func _load_config():
	super()
	endowment = config.get("endowment", 100.0)
	multiplier = config.get("multiplier", 2.0)
	required_players = config.get("group_size", 4)
	max_players = config.get("group_size", 4)

## Start game - initialize resource pool
func start_game() -> bool:
	resource_pool = ResourcePool.new(game_id + "_pool", "money")
	resource_pool.multiplier = multiplier
	resource_pool.equal_distribution = true
	
	return super()

## Execute round logic
func _execute_round():
	contributions.clear()
	
	# Phase 1: Collect contributions from all players
	for player in players:
		var agent: EconomicAgent = player.agent
		var contribution = agent.decide_public_goods_contribution(
			endowment,
			players.size(),
			multiplier
		)
		contribution = clamp(contribution, 0.0, endowment)
		
		contributions[agent.character_name] = contribution
		
		# Add to resource pool (only if contribution is positive)
		if contribution > 0:
			resource_pool.contribute(agent.character_name, contribution)
		
		record_decision(agent.character_name, {
			"action": "contribute",
			"contribution": contribution,
			"kept": endowment - contribution,
			"contribution_ratio": contribution / endowment
		})
	
	# Phase 2: Apply multiplier and distribute
	resource_pool.apply_multiplier()
	
	var player_ids = []
	for player in players:
		player_ids.append(player.agent.character_name)
	
	var distribution = resource_pool.distribute(player_ids)
	
	# Phase 3: Calculate payoffs
	for player in players:
		var agent: EconomicAgent = player.agent
		var player_id = agent.character_name
		
		var contribution = contributions.get(player_id, 0.0)
		var share = distribution.get(player_id, 0.0)
		var payoff = (endowment - contribution) + share
		var net_gain = payoff - endowment
		
		record_payoff(player_id, net_gain)
		
		# Update agent experience
		var contributed_more_than_average = contribution > (endowment * 0.5)
		var gained = net_gain > 0
		
		agent.update_from_experience({
			"game": "public_goods",
			"action_type": "cooperation",
			"contribution": contribution,
			"share_received": share,
			"cooperated": contributed_more_than_average,
			"reward": net_gain
		})
	
	# Calculate statistics
	var total_contributions = 0.0
	for contrib in contributions.values():
		total_contributions += contrib
	
	var avg_contribution = total_contributions / players.size()
	var cooperation_rate = resource_pool.get_cooperation_rate(players.size())
	var free_riders = resource_pool.get_free_riders(player_ids)
	
	# Finish round with results
	var round_results = {
		"round": round_number,
		"endowment": endowment,
		"multiplier": multiplier,
		"group_size": players.size(),
		"contributions": contributions.duplicate(),
		"total_contribution": total_contributions,
		"average_contribution": avg_contribution,
		"average_contribution_ratio": avg_contribution / endowment,
		"pool_after_multiplier": total_contributions * multiplier,
		"distribution": distribution.duplicate(),
		"cooperation_rate": cooperation_rate,
		"free_riders": free_riders.duplicate(),
		"free_rider_count": free_riders.size()
	}
	
	finish_round(round_results)

## Calculate final results
func _calculate_final_results() -> Dictionary:
	var base_results = super()
	
	# Add game-specific statistics
	var total_cooperation_rate = 0.0
	var total_contribution_ratio = 0.0
	var total_free_riders = 0
	
	for result in results:
		total_cooperation_rate += result.get("cooperation_rate", 0.0)
		total_contribution_ratio += result.get("average_contribution_ratio", 0.0)
		total_free_riders += result.get("free_rider_count", 0)
	
	var round_count = results.size()
	
	base_results["average_cooperation_rate"] = total_cooperation_rate / round_count if round_count > 0 else 0.0
	base_results["average_contribution_ratio"] = total_contribution_ratio / round_count if round_count > 0 else 0.0
	base_results["average_free_riders"] = float(total_free_riders) / round_count if round_count > 0 else 0.0
	base_results["pool_statistics"] = resource_pool.get_statistics() if resource_pool else {}
	
	return base_results


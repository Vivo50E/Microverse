extends Node
class_name ResourcePool

## Public resource pool for common goods management
##
## Manages shared resources that multiple agents can contribute to
## and withdraw from. Used for Public Goods Game and commons scenarios.

# Pool state
var total_resources: float = 0.0
var resource_type: String = "generic"
var pool_id: String = ""

# Multiplier for public goods (contributions are multiplied before distribution)
var multiplier: float = 2.0

# Contributors tracking
var contributors: Dictionary = {}  # agent_id -> contribution_amount
var withdrawals: Dictionary = {}   # agent_id -> withdrawal_amount

# History
var contribution_history: Array = []
var withdrawal_history: Array = []
var distribution_history: Array = []

# Settings
var allow_withdrawal: bool = false
var equal_distribution: bool = true
var max_capacity: float = -1.0  # -1 means unlimited

# Signals
signal resource_contributed
signal resource_withdrawn
signal resources_distributed
signal pool_depleted
signal pool_capacity_reached

## Initialize pool
func _init(p_pool_id: String = "", p_resource_type: String = "generic"):
	pool_id = p_pool_id if p_pool_id else _generate_id()
	resource_type = p_resource_type

## Generate unique pool ID
func _generate_id() -> String:
	return "POOL_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

## Contribute resources to pool
func contribute(agent_id: String, amount: float) -> bool:
	if amount <= 0:
		push_error("ResourcePool: Cannot contribute non-positive amount")
		return false
	
	# Check capacity
	if max_capacity > 0 and total_resources + amount > max_capacity:
		pool_capacity_reached.emit()
		return false
	
	# Add to pool
	total_resources += amount
	
	# Track contributor
	if not contributors.has(agent_id):
		contributors[agent_id] = 0.0
	contributors[agent_id] += amount
	
	# Record history
	contribution_history.append({
		"agent_id": agent_id,
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system(),
		"pool_total_after": total_resources
	})
	
	resource_contributed.emit(agent_id, amount)
	return true

## Withdraw resources from pool (if allowed)
func withdraw(agent_id: String, amount: float) -> bool:
	if not allow_withdrawal:
		push_error("ResourcePool: Withdrawals not allowed for this pool")
		return false
	
	if amount <= 0:
		push_error("ResourcePool: Cannot withdraw non-positive amount")
		return false
	
	if amount > total_resources:
		push_error("ResourcePool: Insufficient resources in pool")
		return false
	
	# Remove from pool
	total_resources -= amount
	
	# Track withdrawal
	if not withdrawals.has(agent_id):
		withdrawals[agent_id] = 0.0
	withdrawals[agent_id] += amount
	
	# Record history
	withdrawal_history.append({
		"agent_id": agent_id,
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system(),
		"pool_total_after": total_resources
	})
	
	resource_withdrawn.emit(agent_id, amount)
	
	if total_resources <= 0:
		pool_depleted.emit()
	
	return true

## Distribute resources to agents
func distribute(agents: Array) -> Dictionary:
	if agents.is_empty():
		return {}
	
	var distribution = {}
	
	if equal_distribution:
		# Equal share for all agents
		var share = total_resources / agents.size()
		for agent_id in agents:
			distribution[agent_id] = share
	else:
		# Proportional to contribution
		var total_contributions = 0.0
		for agent_id in agents:
			total_contributions += contributors.get(agent_id, 0.0)
		
		if total_contributions > 0:
			for agent_id in agents:
				var contribution = contributors.get(agent_id, 0.0)
				var share = (contribution / total_contributions) * total_resources
				distribution[agent_id] = share
		else:
			# No contributions, equal distribution
			var share = total_resources / agents.size()
			for agent_id in agents:
				distribution[agent_id] = share
	
	# Record distribution
	distribution_history.append({
		"distribution": distribution.duplicate(),
		"total_distributed": total_resources,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Clear pool
	total_resources = 0.0
	
	resources_distributed.emit(distribution)
	return distribution

## Apply multiplier to pool (for public goods game)
func apply_multiplier():
	total_resources *= multiplier

## Get contribution percentage for agent
func get_contribution_percentage(agent_id: String) -> float:
	var total_contributions = 0.0
	for contrib in contributors.values():
		total_contributions += contrib
	
	if total_contributions == 0:
		return 0.0
	
	var agent_contrib = contributors.get(agent_id, 0.0)
	return (agent_contrib / total_contributions) * 100.0

## Get free-riders (agents who received but didn't contribute)
func get_free_riders(participants: Array) -> Array:
	var free_riders = []
	for agent_id in participants:
		if contributors.get(agent_id, 0.0) == 0.0:
			free_riders.append(agent_id)
	return free_riders

## Get cooperators (agents who contributed)
func get_cooperators() -> Array:
	var cooperators = []
	for agent_id in contributors.keys():
		if contributors[agent_id] > 0.0:
			cooperators.append(agent_id)
	return cooperators

## Calculate cooperation rate
func get_cooperation_rate(total_participants: int) -> float:
	if total_participants == 0:
		return 0.0
	var cooperator_count = get_cooperators().size()
	return float(cooperator_count) / float(total_participants)

## Get pool statistics
func get_statistics() -> Dictionary:
	var total_contributions = 0.0
	for contrib in contributors.values():
		total_contributions += contrib
	
	var avg_contribution = 0.0
	if contributors.size() > 0:
		avg_contribution = total_contributions / contributors.size()
	
	return {
		"pool_id": pool_id,
		"resource_type": resource_type,
		"current_total": total_resources,
		"total_contributions": total_contributions,
		"contributor_count": contributors.size(),
		"avg_contribution": avg_contribution,
		"contribution_count": contribution_history.size(),
		"withdrawal_count": withdrawal_history.size(),
		"distribution_count": distribution_history.size(),
		"multiplier": multiplier
	}

## Export pool data
func to_dict() -> Dictionary:
	return {
		"pool_id": pool_id,
		"resource_type": resource_type,
		"total_resources": total_resources,
		"multiplier": multiplier,
		"allow_withdrawal": allow_withdrawal,
		"equal_distribution": equal_distribution,
		"max_capacity": max_capacity,
		"contributors": contributors.duplicate(),
		"withdrawals": withdrawals.duplicate(),
		"contribution_history": contribution_history.duplicate(),
		"withdrawal_history": withdrawal_history.duplicate(),
		"distribution_history": distribution_history.duplicate(),
		"statistics": get_statistics()
	}

## Reset pool to initial state
func reset():
	total_resources = 0.0
	contributors.clear()
	withdrawals.clear()
	contribution_history.clear()
	withdrawal_history.clear()
	distribution_history.clear()

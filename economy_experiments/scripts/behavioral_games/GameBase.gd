extends Node
class_name GameBase

## Base class for all behavioral economics games
##
## Provides common functionality for game management, player tracking,
## data logging, and result calculation. Extend this for specific games.

# Game identification
var game_id: String = ""
var game_type: String = "base"
var game_name: String = "Base Game"

# Game state
enum GameState { SETUP, WAITING, ACTIVE, FINISHED, CANCELLED }
var state: GameState = GameState.SETUP

# Players
var players: Array = []  # Array of player dictionaries
var required_players: int = 2
var max_players: int = 2

# Timing
var start_time: float = 0.0
var end_time: float = 0.0
var round_number: int = 0
var max_rounds: int = 1

# Results
var results: Array = []  # Array of result dictionaries per round
var final_results: Dictionary = {}

# Configuration
var config: Dictionary = {}
var logger: Node = null  # Reference to ExperimentLogger

# Signals
signal game_started
signal game_finished
signal round_started
signal round_finished
signal player_joined
signal player_left
signal decision_made

## Initialize game
func _init(p_game_type: String = "base", p_config: Dictionary = {}):
	game_id = _generate_id()
	game_type = p_game_type
	config = p_config
	_load_config()

## Load configuration
func _load_config():
	max_rounds = config.get("rounds", 1)
	required_players = config.get("required_players", 2)
	max_players = config.get("max_players", 2)

## Generate unique game ID
func _generate_id() -> String:
	return "GAME_" + game_type.to_upper() + "_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

## Add player to game
func add_player(agent: EconomicAgent, role: String = "player") -> bool:
	if players.size() >= max_players:
		push_error("GameBase: Maximum players reached")
		return false
	
	if state != GameState.SETUP and state != GameState.WAITING:
		push_error("GameBase: Cannot add players after game started")
		return false
	
	# Check if already in game
	for p in players:
		if p.agent == agent:
			return false
	
	var player_data = {
		"agent": agent,
		"player_id": agent.character_name,
		"role": role,
		"joined_time": Time.get_unix_time_from_system(),
		"decisions": [],
		"payoffs": []
	}
	
	players.append(player_data)
	player_joined.emit(agent.character_name)
	
	# Auto-start if enough players
	if players.size() == required_players and state == GameState.SETUP:
		state = GameState.WAITING
	
	return true

## Remove player from game
func remove_player(player_id: String) -> bool:
	for i in range(players.size()):
		if players[i].player_id == player_id:
			players.remove_at(i)
			player_left.emit(player_id)
			return true
	return false

## Get player data
func get_player(player_id: String) -> Dictionary:
	for p in players:
		if p.player_id == player_id:
			return p
	return {}

## Check if game is ready to start
func is_ready() -> bool:
	return players.size() >= required_players and state == GameState.WAITING

## Start the game
func start_game() -> bool:
	if not is_ready():
		push_error("GameBase: Game not ready to start")
		return false
	
	state = GameState.ACTIVE
	start_time = Time.get_unix_time_from_system()
	round_number = 0
	
	_log_event("game_started", {
		"game_id": game_id,
		"game_type": game_type,
		"players": _get_player_ids(),
		"config": config
	})
	
	game_started.emit()
	
	# Start first round
	start_next_round()
	
	return true

## Start next round
func start_next_round() -> bool:
	if round_number >= max_rounds:
		finish_game()
		return false
	
	round_number += 1
	
	_log_event("round_started", {
		"game_id": game_id,
		"round": round_number
	})
	
	round_started.emit(round_number)
	
	# Override in subclass to implement round logic
	_execute_round()
	
	return true

## Execute round logic (override in subclass)
func _execute_round():
	# Subclasses should implement specific game logic
	push_warning("GameBase: _execute_round not implemented, finishing round immediately")
	finish_round({})

## Finish current round
func finish_round(round_results: Dictionary):
	results.append(round_results)
	
	_log_event("round_finished", {
		"game_id": game_id,
		"round": round_number,
		"results": round_results
	})
	
	round_finished.emit(round_number, round_results)
	
	# Check if more rounds
	if round_number < max_rounds:
		# Small delay before next round
		if is_inside_tree():
			await get_tree().create_timer(0.5).timeout
		start_next_round()
	else:
		finish_game()

## Finish the game
func finish_game():
	state = GameState.FINISHED
	end_time = Time.get_unix_time_from_system()
	
	# Calculate final results
	final_results = _calculate_final_results()
	
	_log_event("game_finished", {
		"game_id": game_id,
		"final_results": final_results,
		"duration": end_time - start_time
	})
	
	game_finished.emit(final_results)

## Calculate final results (override in subclass)
func _calculate_final_results() -> Dictionary:
	# Default: sum payoffs per player
	var player_totals = {}
	
	for player in players:
		var total_payoff = 0.0
		for payoff in player.payoffs:
			total_payoff += payoff
		player_totals[player.player_id] = {
			"total_payoff": total_payoff,
			"average_payoff": total_payoff / max(1, player.payoffs.size()),
			"rounds_played": player.payoffs.size()
		}
	
	return {
		"game_id": game_id,
		"game_type": game_type,
		"total_rounds": round_number,
		"player_results": player_totals,
		"start_time": start_time,
		"end_time": end_time,
		"duration": end_time - start_time
	}

## Record player decision
func record_decision(player_id: String, decision: Dictionary):
	var player = get_player(player_id)
	if player.is_empty():
		push_error("GameBase: Player not found: " + player_id)
		return
	
	decision["timestamp"] = Time.get_unix_time_from_system()
	decision["round"] = round_number
	player.decisions.append(decision)
	
	_log_event("decision_made", {
		"game_id": game_id,
		"player_id": player_id,
		"round": round_number,
		"decision": decision
	})
	
	decision_made.emit(player_id, decision)

## Record player payoff
func record_payoff(player_id: String, payoff: float):
	var player = get_player(player_id)
	if player.is_empty():
		push_error("GameBase: Player not found: " + player_id)
		return
	
	player.payoffs.append(payoff)
	
	# Update agent's wallet if in real economy mode
	if player.agent and player.agent.wallet:
		player.agent.wallet.deposit(payoff, "game_payout: " + game_type)

## Get game summary
func get_summary() -> Dictionary:
	return {
		"game_id": game_id,
		"game_type": game_type,
		"game_name": game_name,
		"state": GameState.keys()[state],
		"round": round_number,
		"max_rounds": max_rounds,
		"players": _get_player_ids(),
		"start_time": start_time,
		"end_time": end_time
	}

## Export game data
func to_dict() -> Dictionary:
	var export_data = get_summary()
	export_data["config"] = config.duplicate()
	export_data["results"] = results.duplicate()
	export_data["final_results"] = final_results.duplicate()
	
	# Export player data (without agent references)
	var players_data = []
	for player in players:
		players_data.append({
			"player_id": player.player_id,
			"role": player.role,
			"joined_time": player.joined_time,
			"decisions": player.decisions.duplicate(),
			"payoffs": player.payoffs.duplicate()
		})
	export_data["players_detailed"] = players_data
	
	return export_data

## Cancel game
func cancel_game():
	state = GameState.CANCELLED
	_log_event("game_cancelled", {"game_id": game_id})

## Private: Get player IDs
func _get_player_ids() -> Array:
	var ids = []
	for p in players:
		ids.append(p.player_id)
	return ids

## Private: Log event
func _log_event(event_type: String, data: Dictionary):
	if logger and logger.has_method("log_event"):
		logger.log_event(event_type, data)
	else:
		print("[%s] %s: %s" % [game_id, event_type, JSON.stringify(data)])

## Set logger
func set_logger(p_logger: Node):
	logger = p_logger

extends Node
class_name ExperimentManager

## Central manager for running economic experiments
##
## Orchestrates experiments, manages game sessions, collects data,
## and coordinates with other managers (EconomyManager, CharacterManager, etc.)

# Core references
var logger: ExperimentLogger = null
var metrics_calc: MetricsCalculator = null
var exporter: DataExporter = null
var economy_manager: Node = null

# Experiment state
enum ExperimentState { IDLE, SETUP, RUNNING, PAUSED, FINISHED }
var state: ExperimentState = ExperimentState.IDLE

# Current experiment config
var current_experiment: Dictionary = {}
var experiment_name: String = ""
var experiment_start_time: float = 0.0

# Agents and games
var economic_agents: Dictionary = {}  # agent_id -> EconomicAgent
var active_games: Array = []  # Currently running games
var completed_games: Array = []  # Finished games

# Scheduling
var scheduled_events: Array = []  # Array of {time, type, data}
var virtual_time: float = 0.0  # Virtual time in seconds
var time_scale: float = 1.0  # 1.0 = real-time, >1 = faster

# Signals
signal experiment_started
signal experiment_finished
signal experiment_paused
signal experiment_resumed
signal game_scheduled
signal agent_created

## Initialize
func _ready():
	logger = ExperimentLogger.new()
	add_child(logger)
	
	metrics_calc = MetricsCalculator.new()
	exporter = DataExporter.new()

## Load experiment configuration from JSON
func load_experiment(config_path: String) -> bool:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("ExperimentManager: Failed to load config: " + config_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("ExperimentManager: JSON parse error in: " + config_path)
		return false
	
	current_experiment = json.data
	experiment_name = current_experiment.get("name", "Unnamed Experiment")
	
	print("ExperimentManager: Loaded experiment: " + experiment_name)
	return true

## Setup experiment (create agents, initialize systems)
func setup_experiment() -> bool:
	if current_experiment.is_empty():
		push_error("ExperimentManager: No experiment loaded")
		return false
	
	state = ExperimentState.SETUP
	
	# Create economic agents
	var agents_config = current_experiment.get("agents", [])
	for agent_config in agents_config:
		var agent_name = agent_config.get("name", "")
		var profile_name = agent_config.get("profile", "risk_neutral")
		var initial_cash = agent_config.get("initial_cash", 100.0)
		
		# Load personality profile
		var profile = _load_agent_profile(profile_name)
		
		# Create agent
		var agent = EconomicAgent.new(agent_name, initial_cash)
		agent.load_personality(profile)
		
		economic_agents[agent_name] = agent
		agent_created.emit(agent_name)
		
		print("ExperimentManager: Created agent: " + agent_name + " with profile: " + profile_name)
	
	# Schedule games
	var games_config = current_experiment.get("games", [])
	for game_config in games_config:
		_schedule_games(game_config)
	
	# Setup market (if enabled)
	if current_experiment.get("market", {}).get("enabled", false):
		_setup_market(current_experiment.market)
	
	print("ExperimentManager: Experiment setup complete")
	return true

## Start experiment
func start_experiment() -> bool:
	if state != ExperimentState.SETUP:
		push_error("ExperimentManager: Must setup experiment first")
		return false
	
	state = ExperimentState.RUNNING
	experiment_start_time = Time.get_unix_time_from_system()
	virtual_time = 0.0
	
	# Start logger session
	logger.start_session(experiment_name + "_" + str(experiment_start_time))
	
	logger.log_event("experiment_started", {
		"name": experiment_name,
		"agents": economic_agents.keys(),
		"config": current_experiment
	})
	
	experiment_started.emit(experiment_name)
	
	print("ExperimentManager: Experiment started: " + experiment_name)
	return true

## Update experiment (call each frame when running)
func _process(delta: float):
	if state != ExperimentState.RUNNING:
		return
	
	# Update virtual time
	virtual_time += delta * time_scale
	
	# Check for scheduled events
	_process_scheduled_events()
	
	# Check for experiment completion
	var duration_minutes = current_experiment.get("duration_minutes", 30)
	if virtual_time >= duration_minutes * 60.0:
		finish_experiment()

## Pause experiment
func pause_experiment():
	if state == ExperimentState.RUNNING:
		state = ExperimentState.PAUSED
		logger.log_event("experiment_paused", {"virtual_time": virtual_time})
		experiment_paused.emit()

## Resume experiment
func resume_experiment():
	if state == ExperimentState.PAUSED:
		state = ExperimentState.RUNNING
		logger.log_event("experiment_resumed", {"virtual_time": virtual_time})
		experiment_resumed.emit()

## Finish experiment and generate results
func finish_experiment():
	if state != ExperimentState.RUNNING:
		return
	
	state = ExperimentState.FINISHED
	
	logger.log_event("experiment_finished", {
		"virtual_time": virtual_time,
		"real_duration": Time.get_unix_time_from_system() - experiment_start_time
	})
	
	# Collect all data
	var results = _collect_results()
	
	# Calculate metrics
	results["metrics"] = MetricsCalculator.calculate_all_metrics(results)
	
	# Export data
	exporter.export_dataset(results, experiment_name)
	exporter.export_for_analysis(results, experiment_name + "_analysis")
	exporter.generate_summary_report(results, experiment_name + "_summary")
	
	# End logger session
	logger.end_session()
	
	experiment_finished.emit(results)
	
	print("ExperimentManager: Experiment finished. Results exported.")

## Run a specific game
func run_game(game_type: String, participants: Array, config: Dictionary = {}) -> GameBase:
	var game: GameBase = null
	
	# Create game instance
	match game_type:
		"ultimatum":
			game = UltimatumGame.new(config)
		"trust":
			game = TrustGame.new(config)
		"public_goods":
			game = PublicGoodsGame.new(config)
		"dictator":
			game = DictatorGame.new(config)
		_:
			push_error("ExperimentManager: Unknown game type: " + game_type)
			return null
	
	# Set logger
	game.set_logger(logger)
	
	# Add participants
	for agent_name in participants:
		if economic_agents.has(agent_name):
			game.add_player(economic_agents[agent_name])
		else:
			push_error("ExperimentManager: Agent not found: " + agent_name)
	
	# Start game
	if game.start_game():
		active_games.append(game)
		logger.log_event("game_started", game.get_summary())
		
		# Connect finish signal
		game.game_finished.connect(_on_game_finished.bind(game))
		
		print("ExperimentManager: Started game: " + game_type)
		return game
	else:
		push_error("ExperimentManager: Failed to start game: " + game_type)
		return null

## Get experiment status
func get_status() -> Dictionary:
	return {
		"state": ExperimentState.keys()[state],
		"experiment_name": experiment_name,
		"virtual_time": virtual_time,
		"agents_count": economic_agents.size(),
		"active_games": active_games.size(),
		"completed_games": completed_games.size(),
		"scheduled_events": scheduled_events.size()
	}

## Private: Load agent profile from file
func _load_agent_profile(profile_name: String) -> Dictionary:
	var profile_path = "res://economy_experiments/configs/agents/" + profile_name + ".json"
	var file = FileAccess.open(profile_path, FileAccess.READ)
	
	if not file:
		push_warning("ExperimentManager: Profile not found: " + profile_name + ", using defaults")
		return {
			"risk_aversion": 0.5,
			"time_preference": 0.5,
			"altruism": 0.5,
			"fairness_concern": 0.5,
			"trust_level": 0.5,
			"reciprocity": 0.5
		}
	
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	
	return json.data.get("parameters", {})

## Private: Schedule games based on config
func _schedule_games(game_config: Dictionary):
	var game_type = game_config.get("type", "")
	var rounds = game_config.get("rounds", 1)
	var schedule = game_config.get("schedule", "start")  # start, every_X_minutes, specific_times
	
	if schedule == "start":
		# Schedule at experiment start
		scheduled_events.append({
			"time": 0.0,
			"type": "game",
			"game_type": game_type,
			"config": game_config,
			"rounds": rounds
		})
	elif schedule.begins_with("every_"):
		# Parse interval
		var interval_str = schedule.replace("every_", "").replace("_minutes", "")
		var interval = float(interval_str) * 60.0
		
		# Schedule multiple instances
		var duration = current_experiment.get("duration_minutes", 30) * 60.0
		var time = 0.0
		while time < duration:
			scheduled_events.append({
				"time": time,
				"type": "game",
				"game_type": game_type,
				"config": game_config,
				"rounds": rounds
			})
			time += interval
	
	# Sort by time
	scheduled_events.sort_custom(func(a, b): return a.time < b.time)

## Private: Process scheduled events
func _process_scheduled_events():
	var executed = []
	
	for event in scheduled_events:
		if event.time <= virtual_time:
			_execute_scheduled_event(event)
			executed.append(event)
	
	# Remove executed events
	for event in executed:
		scheduled_events.erase(event)

## Private: Execute a scheduled event
func _execute_scheduled_event(event: Dictionary):
	match event.type:
		"game":
			# Select random participants
			var agent_ids = economic_agents.keys()
			var required = event.config.get("group_size", 2)
			var participants = []
			
			# Shuffle and select
			agent_ids.shuffle()
			for i in range(min(required, agent_ids.size())):
				participants.append(agent_ids[i])
			
			# Run game
			run_game(event.game_type, participants, event.config)

## Private: Setup market
func _setup_market(market_config: Dictionary):
	# Create market (implementation depends on EconomyManager)
	if economy_manager and economy_manager.has_method("setup_market"):
		economy_manager.setup_market(market_config)
	else:
		print("ExperimentManager: Market setup skipped (EconomyManager not available)")

## Private: Collect all results
func _collect_results() -> Dictionary:
	# Collect wallet states
	var wallets = {}
	for agent_id in economic_agents.keys():
		wallets[agent_id] = economic_agents[agent_id].wallet.to_dict()
	
	# Collect game results
	var games = []
	for game in completed_games:
		games.append(game.to_dict())
	
	# Get logs
	var logs = logger.get_logs_dict()
	
	return {
		"experiment_name": experiment_name,
		"session_id": logger.session_id,
		"start_time": experiment_start_time,
		"end_time": Time.get_unix_time_from_system(),
		"duration": Time.get_unix_time_from_system() - experiment_start_time,
		"virtual_time": virtual_time,
		"config": current_experiment,
		"wallets": wallets,
		"games": games,
		"events": logs.events,
		"decisions": logs.decisions,
		"transactions": logs.transactions,
		"statistics": {
			"agents": economic_agents.size(),
			"games_played": completed_games.size(),
			"total_events": logs.events.size(),
			"total_decisions": logs.decisions.size(),
			"total_transactions": logs.transactions.size()
		}
	}

## Private: Game finished callback
func _on_game_finished(results: Dictionary, game: GameBase):
	active_games.erase(game)
	completed_games.append(game)
	
	logger.log_game(game.to_dict())
	
	print("ExperimentManager: Game finished: " + game.game_type)

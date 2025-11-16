extends Node

## Controller script to integrate ExperimentManager into any scene
##
## This is a bridge between the main game and the experiment system.
## Attach this script to a Node in your scene to run economic experiments.

func _ready():
	print("\n")
	print("=".repeat(80))
	print("🎯 Economic Experiment Controller Started!")
	print("=".repeat(80))
	print("\n")
	
	print("1️⃣ Creating ExperimentManager...")
	var experiment_manager = ExperimentManager.new()
	add_child(experiment_manager)
	print("✅ ExperimentManager created successfully\n")
	
	print("2️⃣ Loading configuration...")
	if experiment_manager.load_experiment("res://economy_experiments/configs/experiments/phase1_behavioral.json"):
		print("✅ Configuration loaded successfully\n")
		
		print("3️⃣ Setting up experiment...")
		if experiment_manager.setup_experiment():
			print("✅ Setup successful, agents: %d\n" % experiment_manager.economic_agents.size())
			
			print("4️⃣ Starting experiment...")
			if experiment_manager.start_experiment():
				print("✅ Experiment is now running!\n")
			else:
				print("❌ Failed to start experiment\n")
		else:
			print("❌ Setup failed\n")
	else:
		print("❌ Configuration loading failed\n")

func _process(_delta):
	# ExperimentManager will handle its own _process
	pass


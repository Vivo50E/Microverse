extends Node

func _ready():
	print("\n")
	print("=".repeat(80))
	print("🎯 实验控制器已启动！")
	print("=".repeat(80))
	print("\n")
	
	print("1️⃣ 尝试创建 ExperimentManager...")
	var experiment_manager = ExperimentManager.new()
	add_child(experiment_manager)
	print("✅ ExperimentManager 创建成功\n")
	
	print("2️⃣ 加载配置...")
	if experiment_manager.load_experiment("res://economy_experiments/configs/experiments/phase1_behavioral.json"):
		print("✅ 配置加载成功\n")
		
		print("3️⃣ 设置实验...")
		if experiment_manager.setup_experiment():
			print("✅ 设置成功，智能体数量: %d\n" % experiment_manager.economic_agents.size())
			
			print("4️⃣ 启动实验...")
			if experiment_manager.start_experiment():
				print("✅ 实验已启动！\n")
			else:
				print("❌ 启动失败\n")
		else:
			print("❌ 设置失败\n")
	else:
		print("❌ 配置加载失败\n")

extends Node
class_name ExperimentLabManager

## 经济行为实验室管理器
## 将游戏转变为实验室模拟

signal daily_goal_completed
signal experiment_unlocked(experiment_type: String)
signal achievement_earned(achievement: String)

# 游戏状态
var game_day: int = 1
var research_funding: float = 10000.0  # 研究经费
var researcher_level: int = 1
var total_experiments_run: int = 0
var total_data_collected: int = 0

# 每日目标
var daily_goals: Dictionary = {
	"experiments": {"target": 3, "current": 0, "reward": 500},
	"data_points": {"target": 100, "current": 0, "reward": 200},
	"special_events": {"target": 1, "current": 0, "reward": 1000}
}

# 解锁状态
var unlocked_experiments: Array[String] = ["trust", "ultimatum"]
var unlocked_features: Array[String] = ["basic_analysis"]

# 代理财富追踪
var agent_wealth: Dictionary = {}

# 成就系统
var achievements: Dictionary = {
	"first_experiment": false,
	"win_win": false,  # 双方都盈利
	"perfect_trust": false,  # 100%信任
	"nobel_candidate": false  # 运行100个实验
}

func _ready():
	_initialize_agents()
	_load_progress()

## 初始化代理财富
func _initialize_agents():
	var agent_names = ["Alice", "Jack", "Grace", "Joe", "Lea", "Monica", "Stephen", "Tom"]
	for agent_name in agent_names:
		if not agent_wealth.has(agent_name):
			agent_wealth[agent_name] = 200.0

## 开始新的一天
func start_new_day():
	game_day += 1
	_reset_daily_goals()
	print("📅 第 %d 天 - 实验室开门营业！" % game_day)
	print("💰 研究经费: ¥%.2f" % research_funding)

## 重置每日目标
func _reset_daily_goals():
	for goal_key in daily_goals.keys():
		daily_goals[goal_key].current = 0

## 实验完成回调
func on_experiment_completed(experiment_data: Dictionary):
	total_experiments_run += 1
	daily_goals.experiments.current += 1
	
	# 扣除实验经费
	var cost = experiment_data.get("cost", 0.0)
	spend_funding(cost)
	
	# 收集数据
	var data_count = experiment_data.get("data_points", 0)
	collect_data(data_count)
	
	# 更新代理财富
	var results = experiment_data.get("results", {})
	_update_agent_wealth(results)
	
	# 检查成就
	_check_achievements(experiment_data)
	
	# 检查目标
	_check_daily_goals()
	
	print("✅ 实验完成！总实验数: %d" % total_experiments_run)

## 收集数据
func collect_data(count: int):
	total_data_collected += count
	daily_goals.data_points.current += count

## 花费经费
func spend_funding(amount: float) -> bool:
	if research_funding >= amount:
		research_funding -= amount
		return true
	else:
		push_warning("ExperimentLab: 经费不足！需要: %.2f, 当前: %.2f" % [amount, research_funding])
		return false

## 获得经费
func gain_funding(amount: float, source: String = "unknown"):
	research_funding += amount
	print("💰 获得经费 +%.2f (来源: %s)" % [amount, source])

## 更新代理财富
func _update_agent_wealth(results: Dictionary):
	var wallets = results.get("wallets", {})
	if wallets.is_empty():
		print("ExperimentLabManager: 警告 - 没有找到wallet数据")
		return
	
	for agent_id in wallets.keys():
		var wallet_data = wallets[agent_id]
		# wallet.to_dict()返回的数据包含cash, savings, debt等
		var cash = wallet_data.get("cash", 0.0)
		var savings = wallet_data.get("savings", 0.0)
		var debt = wallet_data.get("debt", 0.0)
		var net_worth = wallet_data.get("net_worth", cash + savings - debt)
		
		# 更新agent财富（使用现金余额）
		agent_wealth[agent_id] = cash
		
		print("ExperimentLabManager: 更新 %s 财富 -> ¥%.2f (现金:%.2f, 储蓄:%.2f, 债务:%.2f)" % [
			agent_id, net_worth, cash, savings, debt
		])

## 检查每日目标
func _check_daily_goals():
	var all_completed = true
	for goal_key in daily_goals.keys():
		var goal = daily_goals[goal_key]
		if goal.current >= goal.target and goal.get("completed", false) == false:
			goal.completed = true
			gain_funding(goal.reward, "daily_goal: " + goal_key)
			print("🎯 每日目标完成: %s (+¥%d)" % [goal_key, goal.reward])
		
		if goal.current < goal.target:
			all_completed = false
	
	if all_completed:
		emit_signal("daily_goal_completed")
		print("🎉 所有每日目标完成！")

## 检查成就
func _check_achievements(experiment_data: Dictionary):
	# 第一个实验
	if total_experiments_run == 1 and not achievements.first_experiment:
		achievements.first_experiment = true
		emit_signal("achievement_earned", "first_experiment")
		gain_funding(1000, "achievement: first_experiment")
	
	# 双赢结局
	var all_profit = true
	var results = experiment_data.get("results", {})
	var wallets = results.get("wallets", {})
	for agent_id in wallets.keys():
		var total_income = wallets[agent_id].get("total_income", 0.0)
		var total_expenses = wallets[agent_id].get("total_expenses", 0.0)
		if total_income <= total_expenses:
			all_profit = false
			break
	
	if all_profit and wallets.size() >= 2 and not achievements.win_win:
		achievements.win_win = true
		emit_signal("achievement_earned", "win_win")
		gain_funding(500, "achievement: win_win")
	
	# 诺贝尔候选人
	if total_experiments_run >= 100 and not achievements.nobel_candidate:
		achievements.nobel_candidate = true
		emit_signal("achievement_earned", "nobel_candidate")
		gain_funding(10000, "achievement: nobel_candidate")
		print("🏆 成就解锁: 诺贝尔候选人！")

## 解锁新实验
func unlock_experiment(experiment_type: String):
	if not unlocked_experiments.has(experiment_type):
		unlocked_experiments.append(experiment_type)
		emit_signal("experiment_unlocked", experiment_type)
		print("🔓 解锁新实验: %s" % experiment_type)

## 检查是否解锁
func is_experiment_unlocked(experiment_type: String) -> bool:
	return unlocked_experiments.has(experiment_type)

## 升级研究员等级
func level_up():
	researcher_level += 1
	print("⬆️ 研究员等级提升至 Lv.%d" % researcher_level)
	
	# 根据等级解锁新内容
	match researcher_level:
		5:
			unlock_experiment("public_goods")
			unlock_experiment("dictator")
		10:
			unlock_experiment("auction")
		15:
			unlock_experiment("market")

## 获取状态摘要
func get_status_summary() -> Dictionary:
	return {
		"day": game_day,
		"funding": research_funding,
		"level": researcher_level,
		"total_experiments": total_experiments_run,
		"total_data": total_data_collected,
		"daily_goals": daily_goals,
		"unlocked_experiments": unlocked_experiments,
		"achievements": achievements,
		"agent_wealth": agent_wealth
	}

## 保存进度
func save_progress():
	var save_data = get_status_summary()
	var file = FileAccess.open("user://experiment_lab_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("💾 进度已保存")

## 加载进度
func _load_progress():
	var file = FileAccess.open("user://experiment_lab_progress.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data is Dictionary:
			var data = json.data
			game_day = data.get("day", 1)
			research_funding = data.get("funding", 10000.0)
			researcher_level = data.get("level", 1)
			total_experiments_run = data.get("total_experiments", 0)
			total_data_collected = data.get("total_data", 0)
			if data.has("agent_wealth"):
				agent_wealth = data.agent_wealth
			print("📂 进度已加载")
		file.close()

## 生成每日报告
func generate_daily_report() -> String:
	var report = ""
	report += "=" .repeat(50) + "\n"
	report += "第 %d 天 - 实验室日报\n" % game_day
	report += "=" .repeat(50) + "\n\n"
	
	report += "📊 今日统计:\n"
	report += "  实验次数: %d/%d\n" % [daily_goals.experiments.current, daily_goals.experiments.target]
	report += "  数据收集: %d/%d 条\n" % [daily_goals.data_points.current, daily_goals.data_points.target]
	report += "  特殊事件: %d/%d 个\n\n" % [daily_goals.special_events.current, daily_goals.special_events.target]
	
	report += "💰 经费状况:\n"
	report += "  当前余额: ¥%.2f\n\n" % research_funding
	
	report += "👥 代理财富排行:\n"
	var sorted_agents = _get_sorted_agents_by_wealth()
	for i in range(min(5, sorted_agents.size())):
		var agent = sorted_agents[i]
		report += "  %d. %s: ¥%.2f\n" % [i + 1, agent.name, agent.wealth]
	
	report += "\n" + "=" .repeat(50) + "\n"
	return report

## 按财富排序代理
func _get_sorted_agents_by_wealth() -> Array:
	var agents = []
	for agent_name in agent_wealth.keys():
		agents.append({"name": agent_name, "wealth": agent_wealth[agent_name]})
	
	agents.sort_custom(func(a, b): return a.wealth > b.wealth)
	return agents

## 获取富豪榜
func get_wealth_leaderboard() -> Array:
	return _get_sorted_agents_by_wealth()


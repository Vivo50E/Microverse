extends Node

## 游戏时间系统
## 管理游戏内的时间流逝，支持加速、暂停等功能

# 信号
signal time_changed(day: int, hour: int, minute: int)
signal day_changed(new_day: int)
signal hour_changed(new_hour: int)
signal time_paused
signal time_resumed
signal time_speed_changed(new_speed: float)

# 时间设置
var current_day: int = 1  # 当前天数
var current_hour: int = 8  # 当前小时 (0-23)
var current_minute: int = 0  # 当前分钟 (0-59)
var current_second: float = 0.0  # 当前秒数 (用于精确计算)

# 时间流速
var time_speed: float = 1.0  # 时间流速倍数 (1.0 = 正常, 2.0 = 2倍速)
var is_paused: bool = false  # 是否暂停

# 配置
var minutes_per_real_second: float = 1.0  # 每现实秒对应的游戏分钟数
var start_day: int = 1
var start_hour: int = 8  # 游戏开始时间：早上8点
var start_minute: int = 0

# 统计
var total_game_minutes: int = 0  # 总游戏时间（分钟）
var real_time_elapsed: float = 0.0  # 现实经过时间（秒）
var game_start_time: float = 0.0  # 游戏启动时间戳

func _ready():
	# 初始化
	game_start_time = Time.get_unix_time_from_system()
	_reset_to_start_time()
	
	print("⏰ GameTimeSystem: 游戏时间系统已启动")
	print("📅 开始日期: 第%d天 %02d:%02d" % [current_day, current_hour, current_minute])
	print("⚡ 时间流速: %.1fx (每现实秒 = %.1f游戏分钟)" % [time_speed, minutes_per_real_second])

func _process(delta: float):
	if is_paused:
		return
	
	# 记录现实时间
	real_time_elapsed += delta
	
	# 计算游戏时间增量
	var game_minutes_delta = delta * minutes_per_real_second * time_speed
	current_second += game_minutes_delta * 60.0  # 转换为秒
	
	# 更新时间
	while current_second >= 60.0:
		current_second -= 60.0
		_advance_minute()

## 前进一分钟
func _advance_minute():
	current_minute += 1
	total_game_minutes += 1
	
	if current_minute >= 60:
		current_minute = 0
		_advance_hour()
	
	# 发出时间变化信号
	time_changed.emit(current_day, current_hour, current_minute)

## 前进一小时
func _advance_hour():
	var old_hour = current_hour
	current_hour += 1
	
	if current_hour >= 24:
		current_hour = 0
		_advance_day()
	
	# 发出小时变化信号
	hour_changed.emit(current_hour)
	
	# 如果跨越了某些重要时间点，可以发出特殊事件
	_check_time_events(old_hour, current_hour)

## 前进一天
func _advance_day():
	current_day += 1
	
	# 发出天数变化信号
	day_changed.emit(current_day)
	
	print("📅 新的一天开始！第%d天" % current_day)

## 检查时间事件
func _check_time_events(old_hour: int, new_hour: int):
	"""检查是否触发特定时间事件"""
	# 早上8点 - 工作日开始
	if old_hour < 8 and new_hour >= 8:
		print("🌅 早上8点 - 工作日开始")
	
	# 中午12点 - 午餐时间
	if old_hour < 12 and new_hour >= 12:
		print("🍱 中午12点 - 午餐时间")
	
	# 下午6点 - 工作日结束
	if old_hour < 18 and new_hour >= 18:
		print("🌆 下午6点 - 工作日结束")
	
	# 晚上10点 - 睡眠时间
	if old_hour < 22 and new_hour >= 22:
		print("🌙 晚上10点 - 睡眠时间")

## 暂停时间
func pause_time():
	if not is_paused:
		is_paused = true
		time_paused.emit()
		print("⏸️ 游戏时间已暂停")

## 恢复时间
func resume_time():
	if is_paused:
		is_paused = false
		time_resumed.emit()
		print("▶️ 游戏时间已恢复")

## 切换暂停状态
func toggle_pause():
	if is_paused:
		resume_time()
	else:
		pause_time()

## 设置时间流速
func set_time_speed(speed: float):
	"""设置时间流速倍数"""
	time_speed = clamp(speed, 0.1, 10.0)  # 限制在0.1x到10x之间
	time_speed_changed.emit(time_speed)
	print("⚡ 时间流速已设置为: %.1fx" % time_speed)

## 设置每秒对应的游戏分钟数
func set_minutes_per_second(minutes: float):
	"""设置时间流速（每现实秒对应多少游戏分钟）"""
	minutes_per_real_second = clamp(minutes, 0.1, 60.0)
	print("⚡ 时间流速已调整: 每现实秒 = %.1f游戏分钟" % minutes_per_real_second)

## 设置具体时间
func set_time(day: int, hour: int, minute: int):
	"""设置游戏内的具体时间"""
	current_day = max(1, day)
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)
	current_second = 0.0
	
	time_changed.emit(current_day, current_hour, current_minute)
	print("⏰ 时间已设置为: 第%d天 %02d:%02d" % [current_day, current_hour, current_minute])

## 快进到指定时间
func fast_forward_to(target_hour: int):
	"""快进到今天的指定小时"""
	target_hour = clampi(target_hour, 0, 23)
	
	if target_hour <= current_hour:
		# 如果目标时间已过，快进到明天的该时间
		_advance_day()
	
	current_hour = target_hour
	current_minute = 0
	current_second = 0.0
	
	time_changed.emit(current_day, current_hour, current_minute)
	print("⏩ 已快进到: 第%d天 %02d:00" % [current_day, current_hour])

## 获取当前时间字符串
func get_time_string() -> String:
	"""返回格式化的时间字符串"""
	return "第%d天 %02d:%02d" % [current_day, current_hour, current_minute]

## 获取详细时间字符串
func get_detailed_time_string() -> String:
	"""返回详细的时间字符串，包含星期"""
	var weekday = _get_weekday_name(current_day)
	return "第%d天 (%s) %02d:%02d" % [current_day, weekday, current_hour, current_minute]

## 获取时间段描述
func get_time_period() -> String:
	"""返回时间段描述（早晨、上午、中午等）"""
	if current_hour >= 6 and current_hour < 9:
		return "早晨"
	elif current_hour >= 9 and current_hour < 12:
		return "上午"
	elif current_hour >= 12 and current_hour < 14:
		return "中午"
	elif current_hour >= 14 and current_hour < 18:
		return "下午"
	elif current_hour >= 18 and current_hour < 22:
		return "傍晚"
	else:
		return "夜晚"

## 获取星期几
func _get_weekday_name(day: int) -> String:
	var weekday_index = (day - 1) % 7
	var weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	return weekdays[weekday_index]

## 获取统计信息
func get_statistics() -> Dictionary:
	"""返回时间统计信息"""
	return {
		"current_day": current_day,
		"current_hour": current_hour,
		"current_minute": current_minute,
		"time_string": get_time_string(),
		"time_period": get_time_period(),
		"weekday": _get_weekday_name(current_day),
		"total_game_minutes": total_game_minutes,
		"total_game_hours": total_game_minutes / 60.0,
		"total_game_days": current_day - start_day,
		"real_time_elapsed": real_time_elapsed,
		"time_speed": time_speed,
		"is_paused": is_paused
	}

## 重置到开始时间
func _reset_to_start_time():
	current_day = start_day
	current_hour = start_hour
	current_minute = start_minute
	current_second = 0.0
	total_game_minutes = 0
	real_time_elapsed = 0.0

## 重置时间系统
func reset():
	"""完全重置时间系统"""
	_reset_to_start_time()
	is_paused = false
	time_speed = 1.0
	game_start_time = Time.get_unix_time_from_system()
	
	time_changed.emit(current_day, current_hour, current_minute)
	print("🔄 时间系统已重置")

## 保存时间数据
func save_data() -> Dictionary:
	"""保存时间数据用于存档"""
	return {
		"current_day": current_day,
		"current_hour": current_hour,
		"current_minute": current_minute,
		"total_game_minutes": total_game_minutes,
		"real_time_elapsed": real_time_elapsed,
		"time_speed": time_speed,
		"game_start_time": game_start_time
	}

## 加载时间数据
func load_data(data: Dictionary):
	"""从存档加载时间数据"""
	current_day = data.get("current_day", start_day)
	current_hour = data.get("current_hour", start_hour)
	current_minute = data.get("current_minute", start_minute)
	total_game_minutes = data.get("total_game_minutes", 0)
	real_time_elapsed = data.get("real_time_elapsed", 0.0)
	time_speed = data.get("time_speed", 1.0)
	game_start_time = data.get("game_start_time", Time.get_unix_time_from_system())
	current_second = 0.0
	
	time_changed.emit(current_day, current_hour, current_minute)
	print("📁 时间数据已加载: %s" % get_time_string())


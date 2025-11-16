extends Control

# Ollama 测试场景
# 用于在 Godot 中直接测试 Ollama 连接

@onready var output_label = $VBoxContainer/ScrollContainer/OutputLabel
@onready var test_button = $VBoxContainer/TestButton
@onready var model_option = $VBoxContainer/ModelOption
@onready var api_url_input = $VBoxContainer/APIUrlInput
@onready var progress_bar = $VBoxContainer/ProgressBar

var http_request: HTTPRequest
var test_results = []
var available_models = []
var current_test_index = 0

func _ready():
	# 设置默认值
	api_url_input.text = "http://localhost:11434"
	
	# 连接信号
	test_button.pressed.connect(_on_test_button_pressed)
	
	# 创建 HTTP 请求节点
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	log_output("=== Ollama 测试工具 ===")
	log_output("点击'开始测试'按钮开始")
	log_output("")

func _on_test_button_pressed():
	test_button.disabled = true
	output_label.text = ""
	test_results.clear()
	current_test_index = 0
	progress_bar.value = 0
	
	log_output("=== 开始测试 Ollama 环境 ===\n")
	
	# 开始测试流程
	await test_connection()
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout
	
	if test_results[-1]["success"]:
		await test_get_models()
		if is_inside_tree():
			await get_tree().create_timer(0.5).timeout
		
		if available_models.size() > 0:
			await test_inference(available_models[0])
			if is_inside_tree():
				await get_tree().create_timer(0.5).timeout
			
			await test_openai_api(available_models[0])
			if is_inside_tree():
				await get_tree().create_timer(0.5).timeout
			
			await test_microverse_compatibility(available_models[0])
	
	# 显示总结
	show_summary()
	test_button.disabled = false

func test_connection():
	log_output("【测试 1】检查 API 连接...")
	progress_bar.value = 10
	
	var url = api_url_input.text + "/api/tags"
	http_request.request(url)
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var body = result[3]
	
	if response_code == 200:
		log_success("✅ API 连接成功")
		test_results.append({"name": "连接测试", "success": true})
	else:
		log_error("❌ API 连接失败，状态码: " + str(response_code))
		log_error("请确保 Ollama 服务正在运行：ollama serve")
		test_results.append({"name": "连接测试", "success": false})
	
	progress_bar.value = 20

func test_get_models():
	log_output("\n【测试 2】获取模型列表...")
	progress_bar.value = 30
	
	var url = api_url_input.text + "/api/tags"
	http_request.request(url)
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var body = result[3]
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("models"):
			available_models.clear()
			model_option.clear()
			
			for model in json.models:
				var model_name = model.name
				available_models.append(model_name)
				model_option.add_item(model_name)
				log_output("  • " + model_name)
			
			if available_models.size() > 0:
				log_success("✅ 找到 " + str(available_models.size()) + " 个模型")
				test_results.append({"name": "模型列表", "success": true})
			else:
				log_warning("⚠️ 未找到已安装的模型")
				log_output("\n推荐安装：")
				log_output("  ollama pull mistral:7b-instruct-q4_K_M")
				test_results.append({"name": "模型列表", "success": false})
		else:
			log_error("❌ 无法解析模型列表")
			test_results.append({"name": "模型列表", "success": false})
	else:
		log_error("❌ 获取模型列表失败")
		test_results.append({"name": "模型列表", "success": false})
	
	progress_bar.value = 40

func test_inference(model_name: String):
	log_output("\n【测试 3】推理测试 - " + model_name)
	progress_bar.value = 50
	
	var url = api_url_input.text + "/api/generate"
	var data = {
		"model": model_name,
		"prompt": "Say hello in one word",
		"stream": false
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data)
	
	var start_time = Time.get_ticks_msec()
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json and json.has("response"):
			var reply = json.response.strip_edges()
			log_success("✅ 推理成功")
			log_output("  响应时间: %.2fs" % elapsed)
			log_output("  模型回复: " + reply)
			
			# 性能评级
			if elapsed < 3:
				log_output("  性能评级: 🚀 优秀")
			elif elapsed < 5:
				log_output("  性能评级: ✅ 良好")
			elif elapsed < 10:
				log_output("  性能评级: ⚠️ 一般")
			else:
				log_output("  性能评级: ❌ 较慢")
			
			test_results.append({"name": "推理测试", "success": true, "time": elapsed})
		else:
			log_error("❌ 无法解析响应")
			test_results.append({"name": "推理测试", "success": false})
	else:
		log_error("❌ 推理失败，状态码: " + str(response_code))
		test_results.append({"name": "推理测试", "success": false})
	
	progress_bar.value = 65

func test_openai_api(model_name: String):
	log_output("\n【测试 4】OpenAI 兼容接口测试 - " + model_name)
	progress_bar.value = 75
	
	var url = api_url_input.text + "/v1/chat/completions"
	var data = {
		"model": model_name,
		"messages": [
			{"role": "user", "content": "Say hi"}
		],
		"max_tokens": 10
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data)
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json and json.has("choices"):
			var content = json.choices[0].message.content
			log_success("✅ OpenAI API 正常")
			log_output("  模型回复: " + content)
			test_results.append({"name": "OpenAI API", "success": true})
		else:
			log_error("❌ 响应格式错误")
			test_results.append({"name": "OpenAI API", "success": false})
	else:
		log_error("❌ OpenAI API 失败，状态码: " + str(response_code))
		test_results.append({"name": "OpenAI API", "success": false})
	
	progress_bar.value = 85

func test_microverse_compatibility(model_name: String):
	log_output("\n【测试 5】Microverse 兼容性测试 - " + model_name)
	progress_bar.value = 90
	
	# 模拟 Microverse 的实际 prompt
	var test_prompt = """你是一个办公室员工，名字是Alice。
你的职位是：项目经理。
你的性格是：友善、专业。

当前状态：
- 心情：愉快
- 健康：良好

请根据你的性格，选择一个行动：
1. 去会议室
2. 去休息区

请只回复数字1或2，不要有任何其他文字。"""
	
	var url = api_url_input.text + "/v1/chat/completions"
	var data = {
		"model": model_name,
		"messages": [
			{"role": "user", "content": test_prompt}
		],
		"max_tokens": 10,
		"temperature": 0.7
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data)
	
	var start_time = Time.get_ticks_msec()
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json and json.has("choices"):
			var reply = json.choices[0].message.content.strip_edges()
			log_output("  模型回复: " + reply)
			log_output("  响应时间: %.2fs" % elapsed)
			
			# 检查是否符合 Microverse 的要求
			if "1" in reply or "2" in reply:
				log_success("✅ Microverse 兼容性良好")
				log_output("  ✓ 能够理解结构化提示")
				log_output("  ✓ 能够按要求返回数字")
				test_results.append({"name": "Microverse兼容", "success": true})
			else:
				log_warning("⚠️ 模型理解力需要调整")
				log_output("  未严格遵循指令格式")
				test_results.append({"name": "Microverse兼容", "success": false})
		else:
			log_error("❌ 响应格式错误")
			test_results.append({"name": "Microverse兼容", "success": false})
	else:
		log_error("❌ 兼容性测试失败")
		test_results.append({"name": "Microverse兼容", "success": false})
	
	progress_bar.value = 100

func show_summary():
	log_output("\n" + "=".repeat(50))
	log_output("测试总结")
	log_output("=".repeat(50))
	
	var passed = 0
	var failed = 0
	
	for result in test_results:
		if result.success:
			passed += 1
		else:
			failed += 1
	
	log_output("通过: %d" % passed)
	log_output("失败: %d" % failed)
	log_output("")
	
	if failed == 0:
		log_success("🎉 恭喜！所有测试通过！")
		log_output("\n下一步操作：")
		log_output("1. 按 ESC 打开游戏设置")
		log_output("2. 配置 API：")
		log_output("   - API类型: Ollama")
		log_output("   - API地址: " + api_url_input.text + "/v1/chat/completions")
		if available_models.size() > 0:
			log_output("   - 模型名称: " + available_models[0])
		log_output("3. 开始游戏测试！")
	else:
		log_error("❌ 存在 %d 个失败项，请检查配置" % failed)

func log_output(text: String):
	output_label.text += text + "\n"
	# 自动滚动到底部
	if is_inside_tree():
		await get_tree().process_frame
		if has_node("VBoxContainer/ScrollContainer"):
			var scroll = get_node("VBoxContainer/ScrollContainer")
			scroll.scroll_vertical = 99999

func log_success(text: String):
	log_output("[color=green]" + text + "[/color]")

func log_error(text: String):
	log_output("[color=red]" + text + "[/color]")

func log_warning(text: String):
	log_output("[color=yellow]" + text + "[/color]")


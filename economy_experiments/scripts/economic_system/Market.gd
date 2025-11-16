extends Node
class_name Market

## Market system for agent trading and price discovery
##
## Implements a marketplace where agents can buy/sell goods with dynamic pricing.
## Supports multiple goods types, order matching, and price history tracking.

# Market state
var market_id: String = ""
var market_name: String = "General Market"
var is_open: bool = true

# Goods available in market
var goods_catalog: Dictionary = {}  # good_id -> Good info dict

# Order books
var buy_orders: Array = []   # Array of buy order dictionaries
var sell_orders: Array = []  # Array of sell order dictionaries

# Transaction history
var completed_trades: Array = []

# Price tracking
var price_history: Dictionary = {}  # good_id -> Array of price points

# Market settings
var transaction_fee_percent: float = 0.0  # 0-100
var min_price: float = 0.01
var max_price: float = 10000.0

# Signals
signal trade_completed
signal order_placed
signal order_cancelled
signal price_updated
signal market_opened
signal market_closed

## Initialize market
func _init(p_market_id: String = "", p_name: String = "Market"):
	market_id = p_market_id if p_market_id else _generate_id()
	market_name = p_name

## Generate unique market ID
func _generate_id() -> String:
	return "MKT_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

## Register a good in the market catalog
func register_good(good_id: String, good_name: String, initial_price: float, category: String = "general"):
	goods_catalog[good_id] = {
		"id": good_id,
		"name": good_name,
		"current_price": initial_price,
		"category": category,
		"total_traded": 0,
		"last_trade_time": 0.0
	}
	price_history[good_id] = [{
		"price": initial_price,
		"timestamp": Time.get_unix_time_from_system(),
		"type": "initial"
	}]

## Place buy order
func place_buy_order(agent_id: String, good_id: String, quantity: int, max_price: float, wallet: Wallet = null) -> String:
	if not is_open:
		push_error("Market: Market is closed")
		return ""
	
	if not goods_catalog.has(good_id):
		push_error("Market: Good not found in catalog")
		return ""
	
	# Check if agent can afford
	var total_cost = max_price * quantity
	if wallet and not wallet.can_afford(total_cost):
		push_error("Market: Agent cannot afford this purchase")
		return ""
	
	# Create order
	var order_id = _generate_order_id()
	var order = {
		"order_id": order_id,
		"type": "buy",
		"agent_id": agent_id,
		"good_id": good_id,
		"quantity": quantity,
		"price": max_price,
		"remaining_quantity": quantity,
		"timestamp": Time.get_unix_time_from_system(),
		"status": "active"
	}
	
	buy_orders.append(order)
	order_placed.emit(order)
	
	# Try to match immediately
	_match_orders(good_id)
	
	return order_id

## Place sell order
func place_sell_order(agent_id: String, good_id: String, quantity: int, min_price: float) -> String:
	if not is_open:
		push_error("Market: Market is closed")
		return ""
	
	if not goods_catalog.has(good_id):
		push_error("Market: Good not found in catalog")
		return ""
	
	# Create order
	var order_id = _generate_order_id()
	var order = {
		"order_id": order_id,
		"type": "sell",
		"agent_id": agent_id,
		"good_id": good_id,
		"quantity": quantity,
		"price": min_price,
		"remaining_quantity": quantity,
		"timestamp": Time.get_unix_time_from_system(),
		"status": "active"
	}
	
	sell_orders.append(order)
	order_placed.emit(order)
	
	# Try to match immediately
	_match_orders(good_id)
	
	return order_id

## Cancel an order
func cancel_order(order_id: String, agent_id: String) -> bool:
	# Check buy orders
	for i in range(buy_orders.size()):
		if buy_orders[i].order_id == order_id:
			if buy_orders[i].agent_id != agent_id:
				return false  # Not owner
			buy_orders[i].status = "cancelled"
			buy_orders.remove_at(i)
			order_cancelled.emit(order_id)
			return true
	
	# Check sell orders
	for i in range(sell_orders.size()):
		if sell_orders[i].order_id == order_id:
			if sell_orders[i].agent_id != agent_id:
				return false  # Not owner
			sell_orders[i].status = "cancelled"
			sell_orders.remove_at(i)
			order_cancelled.emit(order_id)
			return true
	
	return false

## Get current market price for a good (last traded price or average of best bid/ask)
func get_current_price(good_id: String) -> float:
	if not goods_catalog.has(good_id):
		return 0.0
	
	# Return last traded price if available
	var history = price_history.get(good_id, [])
	if history.size() > 0:
		return history[-1].price
	
	return goods_catalog[good_id].current_price

## Get best bid (highest buy order price)
func get_best_bid(good_id: String) -> float:
	var best = 0.0
	for order in buy_orders:
		if order.good_id == good_id and order.status == "active":
			best = max(best, order.price)
	return best

## Get best ask (lowest sell order price)
func get_best_ask(good_id: String) -> float:
	var best = INF
	for order in sell_orders:
		if order.good_id == good_id and order.status == "active":
			best = min(best, order.price)
	return best if best != INF else 0.0

## Get bid-ask spread
func get_spread(good_id: String) -> float:
	var bid = get_best_bid(good_id)
	var ask = get_best_ask(good_id)
	if ask == 0.0:
		return 0.0
	return ask - bid

## Get order book summary for a good
func get_order_book(good_id: String) -> Dictionary:
	var buy_book = []
	var sell_book = []
	
	for order in buy_orders:
		if order.good_id == good_id and order.status == "active":
			buy_book.append({
				"price": order.price,
				"quantity": order.remaining_quantity,
				"agent": order.agent_id
			})
	
	for order in sell_orders:
		if order.good_id == good_id and order.status == "active":
			sell_book.append({
				"price": order.price,
				"quantity": order.remaining_quantity,
				"agent": order.agent_id
			})
	
	# Sort
	buy_book.sort_custom(func(a, b): return a.price > b.price)  # Descending
	sell_book.sort_custom(func(a, b): return a.price < b.price)  # Ascending
	
	return {
		"good_id": good_id,
		"bids": buy_book,
		"asks": sell_book,
		"best_bid": get_best_bid(good_id),
		"best_ask": get_best_ask(good_id),
		"spread": get_spread(good_id),
		"last_price": get_current_price(good_id)
	}

## Get all active orders for an agent
func get_agent_orders(agent_id: String) -> Array:
	var orders = []
	for order in buy_orders:
		if order.agent_id == agent_id and order.status == "active":
			orders.append(order.duplicate())
	for order in sell_orders:
		if order.agent_id == agent_id and order.status == "active":
			orders.append(order.duplicate())
	return orders

## Get price history for a good
func get_price_history(good_id: String, limit: int = 50) -> Array:
	var history = price_history.get(good_id, [])
	if limit > 0 and history.size() > limit:
		return history.slice(history.size() - limit)
	return history.duplicate()

## Calculate price volatility (standard deviation of recent prices)
func get_price_volatility(good_id: String, window: int = 10) -> float:
	var history = get_price_history(good_id, window)
	if history.size() < 2:
		return 0.0
	
	var prices = []
	for point in history:
		prices.append(point.price)
	
	# Calculate mean
	var mean = 0.0
	for price in prices:
		mean += price
	mean /= prices.size()
	
	# Calculate variance
	var variance = 0.0
	for price in prices:
		variance += pow(price - mean, 2)
	variance /= prices.size()
	
	return sqrt(variance)

## Get market statistics
func get_statistics() -> Dictionary:
	return {
		"market_id": market_id,
		"market_name": market_name,
		"is_open": is_open,
		"goods_count": goods_catalog.size(),
		"active_buy_orders": buy_orders.size(),
		"active_sell_orders": sell_orders.size(),
		"completed_trades": completed_trades.size(),
		"transaction_fee": transaction_fee_percent
	}

## Open market for trading
func open_market():
	is_open = true
	market_opened.emit()

## Close market
func close_market():
	is_open = false
	market_closed.emit()

## Export market data
func to_dict() -> Dictionary:
	return {
		"market_id": market_id,
		"market_name": market_name,
		"is_open": is_open,
		"goods_catalog": goods_catalog.duplicate(),
		"buy_orders": buy_orders.duplicate(),
		"sell_orders": sell_orders.duplicate(),
		"completed_trades": completed_trades.duplicate(),
		"price_history": price_history.duplicate(),
		"statistics": get_statistics()
	}

## Private: Generate unique order ID
func _generate_order_id() -> String:
	return "ORD_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)

## Private: Match buy and sell orders
func _match_orders(good_id: String):
	# Get active orders for this good
	var buys = []
	var sells = []
	
	for order in buy_orders:
		if order.good_id == good_id and order.status == "active":
			buys.append(order)
	
	for order in sell_orders:
		if order.good_id == good_id and order.status == "active":
			sells.append(order)
	
	# Sort: buys descending (highest price first), sells ascending (lowest price first)
	buys.sort_custom(func(a, b): return a.price > b.price)
	sells.sort_custom(func(a, b): return a.price < b.price)
	
	# Match orders
	for buy in buys:
		for sell in sells:
			if buy.remaining_quantity == 0 or sell.remaining_quantity == 0:
				continue
			
			# Check if prices match (buy price >= sell price)
			if buy.price >= sell.price:
				# Execute trade at sell price (price discovery)
				var trade_price = sell.price
				var trade_quantity = min(buy.remaining_quantity, sell.remaining_quantity)
				
				# Record trade
				var trade = {
					"trade_id": _generate_trade_id(),
					"good_id": good_id,
					"buyer": buy.agent_id,
					"seller": sell.agent_id,
					"quantity": trade_quantity,
					"price": trade_price,
					"total": trade_price * trade_quantity,
					"timestamp": Time.get_unix_time_from_system(),
					"buy_order_id": buy.order_id,
					"sell_order_id": sell.order_id
				}
				
				completed_trades.append(trade)
				
				# Update quantities
				buy.remaining_quantity -= trade_quantity
				sell.remaining_quantity -= trade_quantity
				
				# Update price history
				if not price_history.has(good_id):
					price_history[good_id] = []
				price_history[good_id].append({
					"price": trade_price,
					"timestamp": Time.get_unix_time_from_system(),
					"quantity": trade_quantity,
					"type": "trade"
				})
				
				# Update catalog
				goods_catalog[good_id].current_price = trade_price
				goods_catalog[good_id].total_traded += trade_quantity
				goods_catalog[good_id].last_trade_time = Time.get_unix_time_from_system()
				
				# Emit signals
				trade_completed.emit(trade)
				price_updated.emit(good_id, trade_price)
				
				# Mark orders as completed if fully filled
				if buy.remaining_quantity == 0:
					buy.status = "completed"
				if sell.remaining_quantity == 0:
					sell.status = "completed"

## Private: Generate unique trade ID
func _generate_trade_id() -> String:
	return "TRD_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)

## Reset market
func reset():
	buy_orders.clear()
	sell_orders.clear()
	completed_trades.clear()
	
	# Reset price history but keep catalog
	for good_id in goods_catalog.keys():
		var initial_price = goods_catalog[good_id].current_price
		price_history[good_id] = [{
			"price": initial_price,
			"timestamp": Time.get_unix_time_from_system(),
			"type": "reset"
		}]
		goods_catalog[good_id].total_traded = 0


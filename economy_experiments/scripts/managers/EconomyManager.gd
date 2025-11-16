extends Node
class_name EconomyManager

## Manages the overall economic system
##
## Coordinates markets, resource pools, currency, and economic policies.
## Acts as central authority for economic transactions and regulations.

# Market system
var markets: Dictionary = {}  # market_id -> Market
var global_market: Market = null

# Resource pools
var resource_pools: Dictionary = {}  # pool_id -> ResourcePool

# Transaction tracking
var all_transactions: Array = []

# Economic policies
var inflation_rate: float = 0.0
var interest_rate: float = 0.05
var tax_rate: float = 0.0

# Currency
var currency_name: String = "USD"
var currency_symbol: String = "$"

# Statistics
var total_money_supply: float = 0.0
var total_wealth: float = 0.0
var economic_activity_index: float = 1.0

# Signals
signal transaction_completed
signal market_created
signal economic_crisis
signal wealth_milestone

## Initialize
func _ready():
	# Create global market
	global_market = Market.new("global_market", "Global Marketplace")
	markets["global_market"] = global_market
	
	# Connect market signals
	global_market.trade_completed.connect(_on_trade_completed)

## Setup market from configuration
func setup_market(config: Dictionary):
	var goods_types = config.get("goods_types", ["generic"])
	var price_range = config.get("price_range", [10, 100])
	
	# Register goods
	for good_type in goods_types:
		var initial_price = randf_range(price_range[0], price_range[1])
		global_market.register_good(
			good_type,
			good_type.capitalize(),
			initial_price,
			"economy"
		)
	
	global_market.open_market()
	
	print("EconomyManager: Market setup complete with " + str(goods_types.size()) + " goods")

## Create custom market
func create_market(market_id: String, market_name: String) -> Market:
	if markets.has(market_id):
		push_warning("EconomyManager: Market already exists: " + market_id)
		return markets[market_id]
	
	var market = Market.new(market_id, market_name)
	markets[market_id] = market
	
	market.trade_completed.connect(_on_trade_completed)
	market_created.emit(market_id)
	
	return market

## Get market by ID
func get_market(market_id: String = "global_market") -> Market:
	return markets.get(market_id, null)

## Create resource pool
func create_resource_pool(pool_id: String, resource_type: String, multiplier: float = 1.0) -> ResourcePool:
	if resource_pools.has(pool_id):
		return resource_pools[pool_id]
	
	var pool = ResourcePool.new(pool_id, resource_type)
	pool.multiplier = multiplier
	resource_pools[pool_id] = pool
	
	return pool

## Get resource pool by ID
func get_resource_pool(pool_id: String) -> ResourcePool:
	return resource_pools.get(pool_id, null)

## Execute transaction between agents
func execute_transaction(
	from_wallet: Wallet,
	to_wallet: Wallet,
	amount: float,
	transaction_type: Transaction.Type,
	description: String = ""
) -> Transaction:
	
	# Create transaction record
	var transaction = Transaction.new(
		transaction_type,
		from_wallet.owner_id,
		to_wallet.owner_id,
		amount,
		description
	)
	
	# Execute transfer
	var success = from_wallet.transfer(to_wallet, amount, description)
	transaction.success = success
	
	if not success:
		transaction.error_message = "Insufficient funds"
		push_warning("EconomyManager: Transaction failed - insufficient funds")
	
	# Record transaction
	all_transactions.append(transaction)
	transaction_completed.emit(transaction)
	
	return transaction

## Calculate total money supply
func calculate_money_supply(agent_wallets: Dictionary) -> float:
	var total = 0.0
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			total += wallet.cash + wallet.savings
	
	total_money_supply = total
	return total

## Calculate total wealth (including assets, minus debts)
func calculate_total_wealth(agent_wallets: Dictionary) -> float:
	var total = 0.0
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			total += wallet.get_net_worth()
	
	total_wealth = total
	return total

## Calculate wealth distribution metrics
func calculate_wealth_distribution(agent_wallets: Dictionary) -> Dictionary:
	var wealths = []
	var agent_wealths = {}
	
	for agent_id in agent_wallets.keys():
		var wallet = agent_wallets[agent_id]
		if wallet is Wallet:
			var wealth = wallet.get_net_worth()
			wealths.append(wealth)
			agent_wealths[agent_id] = wealth
	
	if wealths.is_empty():
		return {}
	
	# Calculate statistics
	var gini = MetricsCalculator.calculate_gini_coefficient(wealths)
	var lorenz = MetricsCalculator.calculate_lorenz_curve(wealths)
	
	wealths.sort()
	var median = wealths[wealths.size() / 2]
	var total = 0.0
	for w in wealths:
		total += w
	var mean = total / wealths.size()
	
	# Find richest and poorest
	var richest_id = ""
	var poorest_id = ""
	var max_wealth = -INF
	var min_wealth = INF
	
	for agent_id in agent_wealths.keys():
		var wealth = agent_wealths[agent_id]
		if wealth > max_wealth:
			max_wealth = wealth
			richest_id = agent_id
		if wealth < min_wealth:
			min_wealth = wealth
			poorest_id = agent_id
	
	return {
		"gini_coefficient": gini,
		"lorenz_curve": lorenz,
		"mean_wealth": mean,
		"median_wealth": median,
		"min_wealth": min_wealth,
		"max_wealth": max_wealth,
		"richest_agent": richest_id,
		"poorest_agent": poorest_id,
		"wealth_ratio": max_wealth / max(min_wealth, 0.01)
	}

## Apply inflation (reduce purchasing power)
func apply_inflation(agent_wallets: Dictionary, time_fraction: float = 1.0):
	if inflation_rate == 0.0:
		return
	
	# Inflation reduces real value of cash
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			var inflation_loss = wallet.cash * inflation_rate * time_fraction
			# Optionally deduct from cash to simulate loss of purchasing power
			# For now, we just track it
			pass

## Apply universal basic income
func apply_ubi(agent_wallets: Dictionary, ubi_amount: float):
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			wallet.deposit(ubi_amount, "universal_basic_income")

## Apply tax on wealth
func apply_wealth_tax(agent_wallets: Dictionary, tax_rate_param: float = -1.0) -> float:
	var rate = tax_rate_param if tax_rate_param >= 0 else tax_rate
	if rate == 0.0:
		return 0.0
	
	var total_tax = 0.0
	
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			var wealth = wallet.get_net_worth()
			if wealth > 0:
				var tax = wealth * rate
				if wallet.withdraw(tax, "wealth_tax"):
					total_tax += tax
	
	return total_tax

## Redistribute wealth (e.g., from taxes)
func redistribute_wealth(agent_wallets: Dictionary, total_amount: float):
	if total_amount <= 0 or agent_wallets.is_empty():
		return
	
	var amount_per_agent = total_amount / agent_wallets.size()
	
	for wallet in agent_wallets.values():
		if wallet is Wallet:
			wallet.deposit(amount_per_agent, "redistribution")

## Get economic statistics
func get_statistics(agent_wallets: Dictionary = {}) -> Dictionary:
	var stats = {
		"markets_count": markets.size(),
		"resource_pools_count": resource_pools.size(),
		"total_transactions": all_transactions.size(),
		"inflation_rate": inflation_rate,
		"interest_rate": interest_rate,
		"tax_rate": tax_rate,
		"economic_activity_index": economic_activity_index
	}
	
	if not agent_wallets.is_empty():
		stats["money_supply"] = calculate_money_supply(agent_wallets)
		stats["total_wealth"] = calculate_total_wealth(agent_wallets)
		stats.merge(calculate_wealth_distribution(agent_wallets))
	
	# Market statistics
	if global_market:
		stats["global_market"] = global_market.get_statistics()
	
	return stats

## Get transaction history filtered by criteria
func get_transactions(filter: Dictionary = {}) -> Array:
	if filter.is_empty():
		return all_transactions.duplicate()
	
	var filtered = []
	for trans in all_transactions:
		if trans.matches_filter(filter):
			filtered.append(trans)
	
	return filtered

## Private: Handle trade completion
func _on_trade_completed(trade: Dictionary):
	# Create transaction record
	var transaction = Transaction.new(
		Transaction.Type.TRADE,
		trade.get("seller", ""),
		trade.get("buyer", ""),
		trade.get("total", 0.0),
		"Market trade: " + trade.get("good_id", "")
	)
	
	transaction.metadata["trade_id"] = trade.get("trade_id", "")
	transaction.metadata["good_id"] = trade.get("good_id", "")
	transaction.metadata["quantity"] = trade.get("quantity", 0)
	transaction.metadata["price"] = trade.get("price", 0.0)
	
	all_transactions.append(transaction)
	transaction_completed.emit(transaction)

## Export economy data
func export_data() -> Dictionary:
	return {
		"statistics": get_statistics(),
		"markets": _export_markets(),
		"resource_pools": _export_resource_pools(),
		"transactions": _export_transactions()
	}

## Private: Export markets data
func _export_markets() -> Dictionary:
	var markets_data = {}
	for market_id in markets.keys():
		markets_data[market_id] = markets[market_id].to_dict()
	return markets_data

## Private: Export resource pools data
func _export_resource_pools() -> Dictionary:
	var pools_data = {}
	for pool_id in resource_pools.keys():
		pools_data[pool_id] = resource_pools[pool_id].to_dict()
	return pools_data

## Private: Export transactions
func _export_transactions() -> Array:
	var transactions_data = []
	for trans in all_transactions:
		transactions_data.append(trans.to_dict())
	return transactions_data


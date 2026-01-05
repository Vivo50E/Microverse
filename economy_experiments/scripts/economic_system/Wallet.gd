extends Resource
class_name Wallet

## Wallet system for managing agent's financial resources
##
## This class handles all financial operations including cash management,
## savings, debt tracking, and transaction history. Each agent has one wallet.
##
## @tutorial: See docs/API_REFERENCE.md for usage examples

# Financial balances
var cash: float = 10000.0
var savings: float = 0.0
var debt: float = 0.0
var assets: Array = []  # Array of asset dictionaries

# Transaction history (limited to recent transactions for memory efficiency)
var transaction_history: Array = []
const MAX_HISTORY_SIZE = 1000

# Configuration
var overdraft_limit: float = 0.0  # How much can go negative
var interest_rate: float = 0.05   # Annual interest on debt/savings
var owner_id: String = ""         # Character name/ID

# Signals for reactive updates
signal balance_changed
signal transaction_recorded
signal debt_changed
signal low_balance_warning

## Constructor
func _init(initial_cash: float = 10000.0, p_owner_id: String = ""):
	cash = initial_cash
	owner_id = p_owner_id
	_record_transaction({
		"type": "initialization",
		"amount": initial_cash,
		"source": "system",
		"timestamp": Time.get_unix_time_from_system(),
		"balance_after": cash
	})

## Deposit money into wallet
## @param amount: Amount to deposit (must be positive)
## @param source: Description of where money came from
## @return: true if successful, false otherwise
func deposit(amount: float, source: String = "unknown") -> bool:
	if amount <= 0:
		push_error("Wallet: Cannot deposit non-positive amount")
		return false
	
	cash += amount
	_record_transaction({
		"type": "deposit",
		"amount": amount,
		"source": source,
		"timestamp": Time.get_unix_time_from_system(),
		"balance_after": cash
	})
	balance_changed.emit(cash)
	return true

## Withdraw money from wallet
## @param amount: Amount to withdraw (must be positive)
## @param reason: Description of why withdrawing
## @return: true if successful, false if insufficient funds
func withdraw(amount: float, reason: String = "unknown") -> bool:
	if amount <= 0:
		push_error("Wallet: Cannot withdraw non-positive amount")
		return false
	
	# Check if sufficient funds (including overdraft limit)
	if cash + overdraft_limit < amount:
		_record_transaction({
			"type": "withdraw_failed",
			"amount": amount,
			"reason": reason,
			"error": "insufficient_funds",
			"timestamp": Time.get_unix_time_from_system(),
			"balance_after": cash
		})
		return false
	
	cash -= amount
	_record_transaction({
		"type": "withdraw",
		"amount": amount,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system(),
		"balance_after": cash
	})
	balance_changed.emit(cash)
	
	# Emit warning if balance is low
	if cash < 20.0:
		low_balance_warning.emit(cash)
	
	return true

## Transfer money to another wallet
## @param recipient: The wallet to receive money
## @param amount: Amount to transfer
## @param description: Optional description
## @return: true if successful, false if insufficient funds
func transfer(recipient: Wallet, amount: float, description: String = "") -> bool:
	if not is_instance_valid(recipient):
		push_error("Wallet: Invalid recipient wallet")
		return false
	
	if not withdraw(amount, "transfer_out: " + description):
		return false
	
	recipient.deposit(amount, "transfer_in: " + description + " from " + owner_id)
	return true

## Move money from cash to savings
func save(amount: float) -> bool:
	if amount <= 0 or cash < amount:
		return false
	
	cash -= amount
	savings += amount
	_record_transaction({
		"type": "save",
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system(),
		"cash_after": cash,
		"savings_after": savings
	})
	balance_changed.emit(cash)
	return true

## Move money from savings to cash
func unsave(amount: float) -> bool:
	if amount <= 0 or savings < amount:
		return false
	
	savings -= amount
	cash += amount
	_record_transaction({
		"type": "unsave",
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system(),
		"cash_after": cash,
		"savings_after": savings
	})
	balance_changed.emit(cash)
	return true

## Borrow money (increases debt)
func borrow(amount: float, lender: String = "system") -> bool:
	if amount <= 0:
		return false
	
	cash += amount
	debt += amount
	_record_transaction({
		"type": "borrow",
		"amount": amount,
		"lender": lender,
		"timestamp": Time.get_unix_time_from_system(),
		"debt_after": debt
	})
	balance_changed.emit(cash)
	debt_changed.emit(debt)
	return true

## Repay debt
func repay(amount: float) -> bool:
	if amount <= 0 or amount > cash:
		return false
	
	var actual_repay = min(amount, debt)
	cash -= actual_repay
	debt -= actual_repay
	_record_transaction({
		"type": "repay",
		"amount": actual_repay,
		"timestamp": Time.get_unix_time_from_system(),
		"debt_after": debt
	})
	balance_changed.emit(cash)
	debt_changed.emit(debt)
	return true

## Apply interest to savings and debt
func apply_interest(time_fraction: float = 1.0):
	# Positive interest on savings
	if savings > 0:
		var interest = savings * interest_rate * time_fraction
		savings += interest
		_record_transaction({
			"type": "interest_earned",
			"amount": interest,
			"timestamp": Time.get_unix_time_from_system(),
			"savings_after": savings
		})
	
	# Negative interest on debt
	if debt > 0:
		var interest = debt * interest_rate * time_fraction
		debt += interest
		_record_transaction({
			"type": "interest_charged",
			"amount": interest,
			"timestamp": Time.get_unix_time_from_system(),
			"debt_after": debt
		})
		debt_changed.emit(debt)

## Get total net worth (assets - liabilities)
func get_net_worth() -> float:
	var asset_value = 0.0
	for asset in assets:
		if asset.has("value"):
			asset_value += asset.value
	return cash + savings + asset_value - debt

## Get liquid assets (cash + savings)
func get_liquid_assets() -> float:
	return cash + savings

## Check if can afford amount
func can_afford(amount: float) -> bool:
	return cash >= amount

## Get financial summary as dictionary
func get_summary() -> Dictionary:
	return {
		"owner_id": owner_id,
		"cash": cash,
		"savings": savings,
		"debt": debt,
		"net_worth": get_net_worth(),
		"liquid_assets": get_liquid_assets(),
		"assets_count": assets.size(),
		"transaction_count": transaction_history.size(),
		"last_transaction": transaction_history[-1] if transaction_history.size() > 0 else null
	}

## Get recent transactions
func get_recent_transactions(count: int = 10) -> Array:
	var start = max(0, transaction_history.size() - count)
	return transaction_history.slice(start)

## Get transactions of specific type
func get_transactions_by_type(type: String) -> Array:
	var filtered = []
	for trans in transaction_history:
		if trans.get("type", "") == type:
			filtered.append(trans)
	return filtered

## Calculate total spending in time period
func get_spending_in_period(start_time: float, end_time: float) -> float:
	var total = 0.0
	for trans in transaction_history:
		var time = trans.get("timestamp", 0.0)
		if time >= start_time and time <= end_time:
			if trans.get("type", "") in ["withdraw", "transfer_out"]:
				total += trans.get("amount", 0.0)
	return total

## Calculate total income in time period
func get_income_in_period(start_time: float, end_time: float) -> float:
	var total = 0.0
	for trans in transaction_history:
		var time = trans.get("timestamp", 0.0)
		if time >= start_time and time <= end_time:
			if trans.get("type", "") in ["deposit", "transfer_in"]:
				total += trans.get("amount", 0.0)
	return total

## Export wallet data to dictionary for saving/analysis
func to_dict() -> Dictionary:
	return {
		"owner_id": owner_id,
		"cash": cash,
		"savings": savings,
		"debt": debt,
		"assets": assets.duplicate(),
		"overdraft_limit": overdraft_limit,
		"interest_rate": interest_rate,
		"transaction_history": transaction_history.duplicate(),
		"net_worth": get_net_worth()
	}

## Load wallet data from dictionary
func from_dict(data: Dictionary):
	owner_id = data.get("owner_id", "")
	cash = data.get("cash", 0.0)
	savings = data.get("savings", 0.0)
	debt = data.get("debt", 0.0)
	assets = data.get("assets", [])
	overdraft_limit = data.get("overdraft_limit", 0.0)
	interest_rate = data.get("interest_rate", 0.05)
	transaction_history = data.get("transaction_history", [])

## Private: Record transaction to history
func _record_transaction(transaction: Dictionary):
	transaction_history.append(transaction)
	transaction_recorded.emit(transaction)
	
	# Limit history size for memory efficiency
	if transaction_history.size() > MAX_HISTORY_SIZE:
		transaction_history.remove_at(0)

## Reset wallet to initial state
func reset(initial_cash: float = 100.0):
	cash = initial_cash
	savings = 0.0
	debt = 0.0
	assets.clear()
	transaction_history.clear()
	_record_transaction({
		"type": "reset",
		"amount": initial_cash,
		"timestamp": Time.get_unix_time_from_system(),
		"balance_after": cash
	})
	balance_changed.emit(cash)

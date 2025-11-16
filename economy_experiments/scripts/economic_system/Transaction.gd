extends Resource
class_name Transaction

## Transaction record for economic exchanges
##
## Represents a single transaction between agents or with the system.
## Immutable once created - use for logging and analysis.

# Transaction types
enum Type {
	TRADE,          # Agent-to-agent trade
	PAYMENT,        # Simple payment
	GIFT,           # No reciprocation expected
	LOAN,           # Debt creation
	REPAYMENT,      # Debt reduction
	REWARD,         # From system/experiment
	PENALTY,        # Fine/cost from system
	MARKET_BUY,     # Purchase from market
	MARKET_SELL,    # Sale to market
	GAME_PAYOUT     # From behavioral game
}

# Core transaction data
var transaction_id: String
var type: Type
var timestamp: float

# Parties involved
var from_agent: String  # Sender/payer
var to_agent: String    # Receiver/payee

# Financial details
var amount: float
var currency: String = "USD"

# Item details (for trades)
var items_exchanged: Array = []  # Array of item dictionaries

# Context
var description: String = ""
var game_id: String = ""         # If from behavioral game
var market_id: String = ""       # If from market
var related_transaction_id: String = ""  # For linked transactions

# Metadata
var success: bool = true
var error_message: String = ""
var metadata: Dictionary = {}

## Constructor
func _init(
	p_type: Type,
	p_from: String,
	p_to: String,
	p_amount: float,
	p_description: String = ""
):
	transaction_id = _generate_id()
	type = p_type
	from_agent = p_from
	to_agent = p_to
	amount = p_amount
	description = p_description
	timestamp = Time.get_unix_time_from_system()

## Generate unique transaction ID
func _generate_id() -> String:
	var time_str = str(Time.get_unix_time_from_system())
	var random_str = str(randi() % 10000)
	return "TXN_" + time_str + "_" + random_str

## Check if transaction involves specific agent
func involves_agent(agent_id: String) -> bool:
	return from_agent == agent_id or to_agent == agent_id

## Get the other party in transaction
func get_other_party(agent_id: String) -> String:
	if from_agent == agent_id:
		return to_agent
	elif to_agent == agent_id:
		return from_agent
	return ""

## Check if this is an incoming transaction for agent
func is_incoming(agent_id: String) -> bool:
	return to_agent == agent_id

## Check if this is an outgoing transaction for agent
func is_outgoing(agent_id: String) -> bool:
	return from_agent == agent_id

## Get net change for specific agent
func get_net_change(agent_id: String) -> float:
	if to_agent == agent_id:
		return amount
	elif from_agent == agent_id:
		return -amount
	return 0.0

## Get human-readable type name
func get_type_name() -> String:
	match type:
		Type.TRADE: return "Trade"
		Type.PAYMENT: return "Payment"
		Type.GIFT: return "Gift"
		Type.LOAN: return "Loan"
		Type.REPAYMENT: return "Repayment"
		Type.REWARD: return "Reward"
		Type.PENALTY: return "Penalty"
		Type.MARKET_BUY: return "Market Purchase"
		Type.MARKET_SELL: return "Market Sale"
		Type.GAME_PAYOUT: return "Game Payout"
	return "Unknown"

## Get summary string
func get_summary() -> String:
	var summary = "%s: %s → %s ($%.2f)" % [
		get_type_name(),
		from_agent if from_agent else "System",
		to_agent if to_agent else "System",
		amount
	]
	if description:
		summary += " - " + description
	return summary

## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"transaction_id": transaction_id,
		"type": Type.keys()[type],
		"timestamp": timestamp,
		"datetime": Time.get_datetime_string_from_unix_time(timestamp),
		"from_agent": from_agent,
		"to_agent": to_agent,
		"amount": amount,
		"currency": currency,
		"items_exchanged": items_exchanged.duplicate(),
		"description": description,
		"game_id": game_id,
		"market_id": market_id,
		"related_transaction_id": related_transaction_id,
		"success": success,
		"error_message": error_message,
		"metadata": metadata.duplicate()
	}

## Create from dictionary
static func from_dict(data: Dictionary) -> Transaction:
	var type_val = Type.get(data.get("type", "PAYMENT"))
	var trans = Transaction.new(
		type_val,
		data.get("from_agent", ""),
		data.get("to_agent", ""),
		data.get("amount", 0.0),
		data.get("description", "")
	)
	trans.transaction_id = data.get("transaction_id", trans.transaction_id)
	trans.timestamp = data.get("timestamp", trans.timestamp)
	trans.currency = data.get("currency", "USD")
	trans.items_exchanged = data.get("items_exchanged", [])
	trans.game_id = data.get("game_id", "")
	trans.market_id = data.get("market_id", "")
	trans.related_transaction_id = data.get("related_transaction_id", "")
	trans.success = data.get("success", true)
	trans.error_message = data.get("error_message", "")
	trans.metadata = data.get("metadata", {})
	return trans

## Check if transaction matches filter criteria
func matches_filter(filter: Dictionary) -> bool:
	if filter.has("type") and filter.type != type:
		return false
	if filter.has("from_agent") and filter.from_agent != from_agent:
		return false
	if filter.has("to_agent") and filter.to_agent != to_agent:
		return false
	if filter.has("min_amount") and amount < filter.min_amount:
		return false
	if filter.has("max_amount") and amount > filter.max_amount:
		return false
	if filter.has("start_time") and timestamp < filter.start_time:
		return false
	if filter.has("end_time") and timestamp > filter.end_time:
		return false
	return true


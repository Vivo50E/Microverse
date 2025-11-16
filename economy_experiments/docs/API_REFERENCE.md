# API Reference

Complete API documentation for Economy Experiments module.

## Table of Contents

- [Economic System](#economic-system)
  - [Wallet](#wallet)
  - [Transaction](#transaction)
  - [Market](#market)
  - [ResourcePool](#resourcepool)
  - [EconomicAgent](#economicagent)
- [Behavioral Games](#behavioral-games)
  - [GameBase](#gamebase)
  - [UltimatumGame](#ultimatumgame)
  - [TrustGame](#trustgame)
  - [PublicGoodsGame](#publicgoodsgame)
  - [DictatorGame](#dictatorgame)
- [Managers](#managers)
  - [ExperimentManager](#experimentmanager)
  - [EconomyManager](#economymanager)
- [Data Collection](#data-collection)
  - [ExperimentLogger](#experimentlogger)
  - [MetricsCalculator](#metricscalculator)
  - [DataExporter](#dataexporter)

---

## Economic System

### Wallet

**File**: `scripts/economic_system/Wallet.gd`

Manages agent's financial resources including cash, savings, and debt.

#### Properties

```gdscript
var cash: float                    # Available cash
var savings: float                 # Saved money
var debt: float                    # Owed amount
var assets: Array                  # Owned assets
var overdraft_limit: float         # Maximum negative balance
var interest_rate: float           # Interest on savings/debt
var owner_id: String               # Agent identifier
```

#### Key Methods

```gdscript
# Basic operations
func deposit(amount: float, source: String) -> bool
func withdraw(amount: float, reason: String) -> bool
func transfer(recipient: Wallet, amount: float, description: String) -> bool

# Savings & debt
func save(amount: float) -> bool
func unsave(amount: float) -> bool
func borrow(amount: float, lender: String) -> bool
func repay(amount: float) -> bool
func apply_interest(time_fraction: float)

# Queries
func get_net_worth() -> float
func get_liquid_assets() -> float
func can_afford(amount: float) -> bool
func get_summary() -> Dictionary
func get_recent_transactions(count: int) -> Array
```

#### Signals

```gdscript
signal balance_changed(new_balance: float)
signal transaction_recorded(transaction: Dictionary)
signal debt_changed(new_debt: float)
signal low_balance_warning(current_balance: float)
```

#### Usage Example

```gdscript
var wallet = Wallet.new(100.0, "Alice")
wallet.deposit(50.0, "reward")
wallet.withdraw(30.0, "purchase")
print(wallet.get_net_worth())  # 120.0
```

---

### EconomicAgent

**File**: `scripts/economic_system/EconomicAgent.gd`

AI agent with economic decision-making capabilities.

#### Properties

```gdscript
var character_name: String
var wallet: Wallet

# Personality traits (0.0 to 1.0)
var risk_aversion: float           # Higher = more risk averse
var time_preference: float         # Higher = prefers future rewards
var altruism: float                # Higher = more generous
var fairness_concern: float        # Higher = values fairness
var trust_level: float             # Higher = more trusting
var reciprocity: float             # Higher = reciprocates more

# Learning
var learning_rate: float
var experience_history: Array
```

#### Key Methods

```gdscript
# Configuration
func load_personality(config: Dictionary)

# Utility theory
func calculate_utility(wealth: float) -> float
func evaluate_risky_choice(outcomes: Array, probabilities: Array) -> float
func should_accept_gamble(gain: float, loss: float, prob_gain: float) -> bool

# Game strategies
func make_ultimatum_offer(total_amount: float) -> float
func should_accept_ultimatum(offer: float, total: float) -> bool
func decide_trust_amount(initial_endowment: float, multiplier: float) -> float
func decide_return_amount(received_amount: float, multiplier: float) -> float
func decide_public_goods_contribution(endowment: float, group_size: int, multiplier: float) -> float

# Market decisions
func decide_max_purchase_price(good_id: String, market: Market, urgency: float) -> float
func decide_min_sale_price(good_id: String, market: Market, urgency: float) -> float

# Learning
func update_from_experience(outcome: Dictionary)

# Queries
func get_personality() -> Dictionary
func to_dict() -> Dictionary
```

#### Usage Example

```gdscript
var agent = EconomicAgent.new("Alice", 200.0)
agent.load_personality({
    "risk_aversion": 0.3,
    "altruism": 0.8,
    "trust_level": 0.7
})

var offer = agent.make_ultimatum_offer(100.0)
print("Alice offers: $", offer)
```

---

## Behavioral Games

### GameBase

**File**: `scripts/behavioral_games/GameBase.gd`

Base class for all behavioral economics games.

#### Properties

```gdscript
var game_id: String
var game_type: String
var state: GameState                # SETUP, WAITING, ACTIVE, FINISHED, CANCELLED
var players: Array
var round_number: int
var max_rounds: int
var results: Array
var config: Dictionary
```

#### Key Methods

```gdscript
# Player management
func add_player(agent: EconomicAgent, role: String) -> bool
func remove_player(player_id: String) -> bool
func get_player(player_id: String) -> Dictionary

# Game flow
func is_ready() -> bool
func start_game() -> bool
func start_next_round() -> bool
func finish_round(round_results: Dictionary)
func finish_game()

# Data recording
func record_decision(player_id: String, decision: Dictionary)
func record_payoff(player_id: String, payoff: float)

# Queries
func get_summary() -> Dictionary
func to_dict() -> Dictionary
```

#### Signals

```gdscript
signal game_started()
signal game_finished(results: Dictionary)
signal round_started(round_num: int)
signal round_finished(round_num: int, results: Dictionary)
signal player_joined(player_id: String)
signal decision_made(player_id: String, decision: Dictionary)
```

---

### UltimatumGame

**File**: `scripts/behavioral_games/UltimatumGame.gd`

Tests fairness preferences and rejection behavior.

#### Game Flow

1. **Proposer** receives endowment and offers split to **Responder**
2. **Responder** accepts (both get split) or rejects (both get nothing)

#### Configuration

```gdscript
{
    "endowment": 100.0,
    "rounds": 3,
    "proposer": "Alice",  # Optional, auto-assigned if not specified
    "responder": "Jack"   # Optional
}
```

#### Results

```gdscript
{
    "offer": 40.0,
    "offer_ratio": 0.4,
    "accepted": true,
    "proposer_payoff": 60.0,
    "responder_payoff": 40.0
}
```

---

## Managers

### ExperimentManager

**File**: `scripts/managers/ExperimentManager.gd`

Central orchestrator for experiments.

#### Key Methods

```gdscript
# Setup
func load_experiment(config_path: String) -> bool
func setup_experiment() -> bool

# Execution
func start_experiment() -> bool
func pause_experiment()
func resume_experiment()
func finish_experiment()

# Game management
func run_game(game_type: String, participants: Array, config: Dictionary) -> GameBase

# Queries
func get_status() -> Dictionary
```

#### Usage Example

```gdscript
var manager = ExperimentManager.new()
manager.load_experiment("res://economy_experiments/configs/experiments/phase1_behavioral.json")
manager.setup_experiment()
manager.start_experiment()
```

---

### EconomyManager

**File**: `scripts/managers/EconomyManager.gd`

Manages markets, resources, and economic policies.

#### Key Methods

```gdscript
# Market management
func setup_market(config: Dictionary)
func create_market(market_id: String, market_name: String) -> Market
func get_market(market_id: String) -> Market

# Transactions
func execute_transaction(from_wallet: Wallet, to_wallet: Wallet, amount: float, type: Transaction.Type, description: String) -> Transaction

# Economic metrics
func calculate_money_supply(agent_wallets: Dictionary) -> float
func calculate_total_wealth(agent_wallets: Dictionary) -> float
func calculate_wealth_distribution(agent_wallets: Dictionary) -> Dictionary

# Policies
func apply_inflation(agent_wallets: Dictionary, time_fraction: float)
func apply_ubi(agent_wallets: Dictionary, ubi_amount: float)
func apply_wealth_tax(agent_wallets: Dictionary, tax_rate: float) -> float
func redistribute_wealth(agent_wallets: Dictionary, total_amount: float)

# Queries
func get_statistics(agent_wallets: Dictionary) -> Dictionary
func get_transactions(filter: Dictionary) -> Array
```

---

## Data Collection

### MetricsCalculator

**File**: `scripts/data_collection/MetricsCalculator.gd`

Static class for calculating economic and behavioral metrics.

#### Key Methods

```gdscript
# Wealth distribution
static func calculate_gini_coefficient(wealths: Array) -> float
static func calculate_lorenz_curve(wealths: Array) -> Array
static func calculate_wealth_mobility(initial_wealths: Dictionary, final_wealths: Dictionary) -> float

# Behavioral metrics
static func calculate_cooperation_rate(game_data: Array) -> float
static func calculate_fairness_score(game_data: Array) -> float
static func calculate_trust_level(game_data: Array) -> float
static func calculate_reciprocity_level(game_data: Array) -> float

# Market metrics
static func calculate_price_volatility(price_history: Array) -> float
static func calculate_market_efficiency(price_history: Array) -> float

# Agent metrics
static func calculate_decision_consistency(decisions: Array) -> float

# All-in-one
static func calculate_all_metrics(data: Dictionary) -> Dictionary
```

#### Usage Example

```gdscript
var gini = MetricsCalculator.calculate_gini_coefficient([100, 150, 200, 300])
print("Gini coefficient: ", gini)  # ~0.18
```

---

## Configuration Format

### Experiment Config

```json
{
  "name": "My Experiment",
  "description": "Description here",
  "duration_minutes": 30,
  "agents": [
    {
      "name": "Alice",
      "profile": "risk_seeking",
      "initial_cash": 500.0
    }
  ],
  "games": [
    {
      "type": "ultimatum",
      "rounds": 5,
      "endowment": 100.0,
      "schedule": "every_5_minutes",
      "group_size": 2
    }
  ],
  "market": {
    "enabled": true,
    "goods_types": ["food", "tools"],
    "price_range": [10, 100]
  },
  "logging": {
    "level": "info",
    "save_dialogues": true
  }
}
```

### Agent Profile Config

```json
{
  "name": "risk_averse",
  "description": "High risk aversion agent",
  "parameters": {
    "risk_aversion": 0.8,
    "time_preference": 0.6,
    "altruism": 0.5,
    "fairness_concern": 0.7,
    "trust_level": 0.4,
    "reciprocity": 0.6,
    "learning_rate": 0.05
  },
  "decision_style": "bounded_rational"
}
```

---

## Data Formats

### Transaction Log

```json
{
  "transaction_id": "TXN_1234567890_5678",
  "type": "TRADE",
  "timestamp": 1699123456.789,
  "from_agent": "Alice",
  "to_agent": "Jack",
  "amount": 50.0,
  "description": "Market trade",
  "success": true
}
```

### Game Results

```json
{
  "game_id": "GAME_ULTIMATUM_1699123456_123",
  "game_type": "ultimatum",
  "total_rounds": 3,
  "results": [...],
  "final_results": {
    "average_offer_ratio": 0.45,
    "acceptance_rate": 0.85
  }
}
```

---

**For more examples, see the source code comments and EXPERIMENT_GUIDE.md**


# Integration Guide

How to integrate Economy Experiments with your Microverse project.

## Overview

The Economy Experiments module is designed to work seamlessly with Microverse's existing systems:
- Uses existing **CharacterManager** for character references
- Uses existing **DialogManager** and **MemoryManager** for AI interactions
- Uses existing **APIManager** for LLM calls
- Adds economic behaviors on top of existing social behaviors

---

## Integration Architecture

```
Microverse (Existing)
├── CharacterManager ──────┐
├── DialogManager    ──────┼──> Used by Economy Experiments
├── MemoryManager    ──────┤
├── APIManager       ──────┘
└── GameSaveManager

Economy Experiments (New)
├── ExperimentManager ──────> Orchestrates experiments
├── EconomyManager    ──────> Manages economic systems
├── EconomicAgent     ──────> Wraps existing characters with economic logic
└── Games, Data Collection  > Independent modules
```

---

## Step 1: Connect to Existing Characters

### Method A: Extend Existing Character Script

Add economic capabilities to existing characters:

```gdscript
# In your existing Character.gd script
extends CharacterBody2D

var economic_agent: EconomicAgent = null

func _ready():
    # Existing character setup...
    
    # Add economic agent
    economic_agent = EconomicAgent.new(character_name, 200.0)
    economic_agent.load_personality({
        "risk_aversion": 0.5,
        "altruism": 0.6,
        # ... other traits
    })
    
    # Connect wallet signals to UI updates
    economic_agent.wallet.balance_changed.connect(_on_balance_changed)

func _on_balance_changed(new_balance: float):
    # Update UI to show current cash
    print("%s now has $%.2f" % [character_name, new_balance])
```

### Method B: Use ExperimentManager to Create Agents

Let ExperimentManager create agents from config:

```gdscript
# In your experiment setup
var exp_manager = ExperimentManager.new()
exp_manager.load_experiment("res://economy_experiments/configs/experiments/phase1_behavioral.json")
exp_manager.setup_experiment()

# Access created agents
var alice_agent = exp_manager.economic_agents["Alice"]
print("Alice's personality: ", alice_agent.get_personality())
```

---

## Step 2: Integrate with Dialog System

Make economic decisions influence dialogues:

```gdscript
# In DialogManager or similar
func generate_dialogue_context(character_name: String) -> String:
    var context = super.generate_dialogue_context(character_name)
    
    # Add economic status if EconomicAgent exists
    var econ_agent = _get_economic_agent(character_name)
    if econ_agent:
        var wallet_summary = econ_agent.wallet.get_summary()
        context += "\n\nFinancial Status:\n"
        context += "- Cash: $%.2f\n" % wallet_summary.cash
        context += "- Net Worth: $%.2f\n" % wallet_summary.net_worth
        
        # Recent transactions
        var recent_trans = econ_agent.wallet.get_recent_transactions(3)
        if not recent_trans.is_empty():
            context += "- Recent: "
            for trans in recent_trans:
                context += "%s ($%.0f), " % [trans.type, trans.amount]
    
    return context
```

---

## Step 3: Connect to Memory System

Store economic decisions in character memories:

```gdscript
# After a game finishes
func _on_game_finished(results: Dictionary, game: GameBase):
    for player in game.players:
        var agent_id = player.player_id
        var payoff = player.payoffs[-1] if not player.payoffs.is_empty() else 0.0
        
        # Add to Microverse MemoryManager
        MemoryManager.add_memory(
            agent_id,
            "Played %s game. My payoff was $%.0f" % [game.game_type, payoff],
            MemoryManager.MemoryType.PERSONAL,
            MemoryManager.MemoryImportance.NORMAL
        )
        
        # This memory will influence future decisions!
```

---

## Step 4: Create Economy-Aware Scenes

### Example: Office with Trading Desk

```
Office.tscn (Existing)
├── Characters (Alice, Jack, Grace, Joe)
├── Desks
├── Chairs
└── [ADD] TradingTerminal (New)
    ├── MarketDisplay
    ├── OrderBookUI
    └── TransactionHistory
```

Add economic interaction points:

```gdscript
# TradingTerminal.gd
extends Node2D

var market: Market = null

func _ready():
    # Get market from EconomyManager
    if EconomyManager:
        market = EconomyManager.get_market("global_market")
        _update_display()

func _on_character_interacted(character_name: String):
    # Show trading UI for this character
    var agent = _get_economic_agent(character_name)
    if agent:
        show_trading_ui(agent)

func show_trading_ui(agent: EconomicAgent):
    # Display:
    # - Agent's cash
    # - Current market prices
    # - Buy/Sell buttons
    # - Order history
    pass
```

---

## Step 5: Autoload Managers

Add economy managers to autoload (optional, for global access):

**Project Settings → Autoload:**

```
ExperimentManager: res://economy_experiments/scripts/managers/ExperimentManager.gd
EconomyManager: res://economy_experiments/scripts/managers/EconomyManager.gd
```

Then access from anywhere:

```gdscript
# From any script
var market = EconomyManager.get_market()
var gini = EconomyManager.calculate_wealth_distribution(agent_wallets).gini_coefficient
```

---

## Step 6: UI Integration Examples

### A. Character Status Panel

Add economic info to character panel:

```gdscript
# CharacterStatusPanel.gd
func update_display(character_name: String):
    # Existing info (name, mood, location)...
    
    # Add economic info
    var econ_agent = _get_economic_agent(character_name)
    if econ_agent:
        $WealthLabel.text = "Wealth: $%.2f" % econ_agent.wallet.get_net_worth()
        $CashLabel.text = "Cash: $%.2f" % econ_agent.wallet.cash
        
        # Show personality traits
        var personality = econ_agent.get_personality()
        $RiskLabel.text = "Risk Aversion: %.1f" % personality.risk_aversion
        $AltruismLabel.text = "Altruism: %.1f" % personality.altruism
```

### B. Market Dashboard

Real-time market visualization:

```gdscript
# MarketDashboard.gd
extends Control

var market: Market
var update_timer: Timer

func _ready():
    market = EconomyManager.get_market()
    
    update_timer = Timer.new()
    update_timer.timeout.connect(_update_display)
    update_timer.wait_time = 1.0
    add_child(update_timer)
    update_timer.start()

func _update_display():
    # Update price charts
    for good_id in market.goods_catalog.keys():
        var price = market.get_current_price(good_id)
        _update_price_chart(good_id, price)
    
    # Update order book
    var order_book = market.get_order_book("food")
    _display_order_book(order_book)
```

### C. Game Results Popup

Show results after behavioral games:

```gdscript
# GameResultsPopup.gd
extends PopupPanel

func show_results(game: GameBase):
    var results = game.final_results
    
    $Title.text = "%s Results" % game.game_name
    $Summary.text = "Rounds Played: %d\n" % results.total_rounds
    
    # Game-specific displays
    if game is UltimatumGame:
        $Summary.text += "Acceptance Rate: %.1f%%\n" % (results.acceptance_rate * 100)
        $Summary.text += "Avg Offer: %.1f%%\n" % (results.average_offer_ratio * 100)
    
    # Player payoffs
    var payoff_text = "\nPayoffs:\n"
    for player_id in results.player_results.keys():
        var player_result = results.player_results[player_id]
        payoff_text += "  %s: $%.2f\n" % [player_id, player_result.total_payoff]
    $Payoffs.text = payoff_text
    
    popup_centered()
```

---

## Step 7: Save/Load Integration

Integrate with Microverse's save system:

```gdscript
# In GameSaveManager.gd or similar

func save_game(save_name: String):
    var save_data = {}
    
    # Existing Microverse data...
    save_data["characters"] = _save_characters()
    save_data["dialogues"] = _save_dialogues()
    
    # Add economy data
    save_data["economy"] = _save_economy_data()
    
    # Save to file
    _write_save_file(save_name, save_data)

func _save_economy_data() -> Dictionary:
    var econ_data = {}
    
    # Save all agent wallets
    econ_data["wallets"] = {}
    for agent_name in ExperimentManager.economic_agents.keys():
        var agent = ExperimentManager.economic_agents[agent_name]
        econ_data["wallets"][agent_name] = agent.wallet.to_dict()
    
    # Save markets
    if EconomyManager:
        econ_data["economy_state"] = EconomyManager.export_data()
    
    return econ_data

func load_game(save_name: String):
    var save_data = _read_save_file(save_name)
    
    # Load existing Microverse data...
    
    # Load economy data
    if save_data.has("economy"):
        _load_economy_data(save_data.economy)

func _load_economy_data(econ_data: Dictionary):
    # Restore wallets
    for agent_name in econ_data.get("wallets", {}).keys():
        var wallet_data = econ_data.wallets[agent_name]
        var agent = ExperimentManager.economic_agents.get(agent_name)
        if agent:
            agent.wallet.from_dict(wallet_data)
```

---

## Step 8: Event-Driven Integration

Use signals to keep systems synchronized:

```gdscript
# In your main game controller
func _ready():
    # Connect economic events to game events
    
    # When agent makes economic decision, update memories
    ExperimentManager.connect("decision_made", _on_economic_decision)
    
    # When wealth changes significantly, trigger dialogues
    for agent in ExperimentManager.economic_agents.values():
        agent.wallet.connect("balance_changed", _on_wealth_changed.bind(agent))
        agent.wallet.connect("low_balance_warning", _on_low_balance.bind(agent))

func _on_economic_decision(agent_id: String, decision: Dictionary):
    # Add to memory
    MemoryManager.add_memory(
        agent_id,
        "I decided to %s" % decision.get("action", "do something"),
        MemoryManager.MemoryType.PERSONAL,
        MemoryManager.MemoryImportance.NORMAL
    )

func _on_wealth_changed(new_balance: float, agent: EconomicAgent):
    if new_balance > 1000:
        # Trigger celebration dialogue
        DialogManager.trigger_dialogue(agent.character_name, "feeling_rich")
    elif new_balance < 50:
        # Trigger concern dialogue
        DialogManager.trigger_dialogue(agent.character_name, "worried_about_money")

func _on_low_balance(current_balance: float, agent: EconomicAgent):
    # Character might ask others for loan
    _trigger_loan_request(agent)
```

---

## Advanced Integration: LLM-Driven Economic Decisions

Instead of using built-in decision methods, query the LLM:

```gdscript
# In EconomicAgent.gd (custom version)

func make_ultimatum_offer_with_llm(total_amount: float) -> float:
    # Build prompt with economic context
    var prompt = """
You are %s. You're playing the Ultimatum Game.

Your Personality:
- Risk Aversion: %.1f/1.0
- Altruism: %.1f/1.0
- Fairness Concern: %.1f/1.0

Your Current Wealth: $%.2f

Game Rules:
- You have $%.0f to split with another player
- You propose a split
- If they reject, neither of you get anything
- If they accept, you both get your proposed amounts

How much will you offer them? Reply with just a number.
""" % [
        character_name,
        risk_aversion,
        altruism,
        fairness_concern,
        wallet.get_net_worth(),
        total_amount
    ]
    
    # Call LLM via APIManager
    var response = await APIManager.call_ai_sync(character_name, prompt)
    
    # Parse response
    var offer = _parse_offer_from_response(response, total_amount)
    
    # Learn from decision
    record_decision({
        "game": "ultimatum",
        "offer": offer,
        "reasoning": response
    })
    
    return offer
```

---

## Testing Integration

### Simple Integration Test

```gdscript
# test_integration.gd
extends Node

func _ready():
    test_character_economic_integration()

func test_character_economic_integration():
    print("=== Testing Integration ===")
    
    # 1. Create economic agent
    var alice = EconomicAgent.new("Alice", 100.0)
    alice.load_personality({"altruism": 0.8, "risk_aversion": 0.3})
    
    # 2. Make economic decision
    var offer = alice.make_ultimatum_offer(100.0)
    print("Alice offers: $", offer)
    assert(offer > 30 and offer < 70, "Offer should be reasonable")
    
    # 3. Update wallet
    alice.wallet.deposit(50.0, "test_reward")
    print("Alice's new balance: $", alice.wallet.cash)
    
    # 4. Add to memory (if MemoryManager available)
    if MemoryManager:
        MemoryManager.add_memory(
            "Alice",
            "I just earned $50",
            MemoryManager.MemoryType.PERSONAL,
            MemoryManager.MemoryImportance.NORMAL
        )
        var memories = MemoryManager.get_character_memories("Alice", 5)
        print("Alice's recent memories: ", memories.size())
    
    print("=== Integration Test Passed ===")
```

---

## Common Patterns

### Pattern 1: Character Makes Economic Decision → Updates Memory

```gdscript
func on_trade_completed(agent: EconomicAgent, trade: Dictionary):
    var memory_text = "I traded %s for $%.2f" % [trade.good_id, trade.total]
    MemoryManager.add_memory(
        agent.character_name,
        memory_text,
        MemoryManager.MemoryType.PERSONAL,
        MemoryManager.MemoryImportance.NORMAL
    )
```

### Pattern 2: Wealth Influences Mood

```gdscript
func update_character_mood(character_name: String):
    var agent = _get_economic_agent(character_name)
    if agent:
        var wealth = agent.wallet.get_net_worth()
        if wealth > 500:
            CharacterManager.set_mood(character_name, "happy")
        elif wealth < 50:
            CharacterManager.set_mood(character_name, "worried")
```

### Pattern 3: Time-Based Economic Events

```gdscript
func _on_daily_timer_timeout():
    # Daily economic events
    for agent in ExperimentManager.economic_agents.values():
        # Pay daily expenses
        agent.wallet.withdraw(10.0, "daily_expenses")
        
        # Apply interest
        agent.wallet.apply_interest(1.0 / 365.0)
        
        # Check for bankruptcies
        if agent.wallet.get_net_worth() < 0:
            _trigger_bankruptcy(agent)
```

---

## Troubleshooting

### Issue: Economic agents not connected to visual characters

**Solution**: Store reference in character scene:

```gdscript
# In character scene script
@export var character_name: String = "Alice"
var economic_agent: EconomicAgent

func _ready():
    # Get or create economic agent
    if ExperimentManager and ExperimentManager.economic_agents.has(character_name):
        economic_agent = ExperimentManager.economic_agents[character_name]
    else:
        economic_agent = EconomicAgent.new(character_name, 100.0)
```

### Issue: Games not triggering

**Solution**: Ensure ExperimentManager is in scene tree:

```gdscript
# In main scene
func _ready():
    var exp_manager = ExperimentManager.new()
    add_child(exp_manager)
    exp_manager.load_experiment("...")
    exp_manager.setup_experiment()
    exp_manager.start_experiment()
```

### Issue: Data not saving

**Solution**: Check user:// directory permissions and paths.

---

**You're now ready to fully integrate economy experiments with Microverse! 🚀**


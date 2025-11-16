# Experiment Design Guide

Complete guide to designing and running economic behavior experiments with LLM-based agents.

## Table of Contents

1. [Experiment Design Principles](#experiment-design-principles)
2. [Designing Your First Experiment](#designing-your-first-experiment)
3. [Game Selection Guide](#game-selection-guide)
4. [Agent Configuration](#agent-configuration)
5. [Data Collection Strategy](#data-collection-strategy)
6. [Common Experiment Patterns](#common-experiment-patterns)
7. [Advanced Techniques](#advanced-techniques)
8. [Analysis Best Practices](#analysis-best-practices)

---

## Experiment Design Principles

### 1. Define Clear Research Questions

Good research questions:
- ✅ "How does risk aversion affect cooperation in public goods games?"
- ✅ "Do LLM agents exhibit loss aversion similar to humans?"
- ✅ "How does model size (7B vs 13B) affect economic rationality?"

Bad research questions:
- ❌ "What happens when agents interact?" (too vague)
- ❌ "Which model is better?" (undefined criteria)

### 2. Control Variables

**Independent Variables** (what you manipulate):
- Agent personality traits
- Game parameters (endowment, multiplier)
- Market conditions
- LLM model/temperature

**Dependent Variables** (what you measure):
- Cooperation rates
- Wealth distribution
- Decision consistency
- Trading volume

**Control Variables** (keep constant):
- Number of rounds
- Initial wealth
- Game sequence
- Prompt format

### 3. Sample Size

Recommendations:
- **Minimum**: 4 agents per condition
- **Better**: 8 agents per condition  
- **Best**: 16+ agents with multiple runs

Multiple runs increase statistical power:
- 1 run: Anecdotal evidence
- 3 runs: Basic patterns
- 10+ runs: Publishable results

---

## Designing Your First Experiment

### Step 1: Choose Your Focus

Pick ONE primary focus:

**Option A: Behavioral Economics**
- Focus on fairness, trust, cooperation
- Use: Ultimatum, Trust, Public Goods, Dictator games
- Duration: 15-30 minutes
- Agents: 4-6

**Option B: Market Dynamics**
- Focus on trading, price discovery, wealth accumulation
- Use: Market simulation with occasional games
- Duration: 30-60 minutes
- Agents: 6-8

**Option C: Model Comparison**
- Focus on comparing different LLMs
- Use: Fixed game sequence
- Duration: 15 minutes (run multiple times)
- Agents: 4 (same personalities across runs)

### Step 2: Create Config File

Start with a template:

```json
{
  "name": "My Experiment: [descriptive name]",
  "description": "Testing [hypothesis] using [method]",
  "duration_minutes": 20,
  
  "agents": [
    {
      "name": "Alice",
      "profile": "risk_averse",
      "initial_cash": 200.0
    },
    {
      "name": "Jack",
      "profile": "risk_seeking",
      "initial_cash": 200.0
    },
    {
      "name": "Grace",
      "profile": "altruistic",
      "initial_cash": 200.0
    },
    {
      "name": "Joe",
      "profile": "selfish",
      "initial_cash": 200.0
    }
  ],
  
  "games": [
    {
      "type": "public_goods",
      "rounds": 5,
      "endowment": 100.0,
      "multiplier": 2.0,
      "schedule": "every_4_minutes",
      "group_size": 4
    }
  ],
  
  "market": {
    "enabled": false
  },
  
  "logging": {
    "level": "info",
    "save_dialogues": true,
    "save_memories": true
  }
}
```

### Step 3: Run Pilot Test

Before full experiment:
1. Run with 2-4 agents
2. Duration: 5 minutes
3. Check:
   - Games trigger correctly
   - Data is logged
   - No errors in console
   - Results make sense

### Step 4: Full Experiment

Once pilot works:
1. Increase to full agent count
2. Full duration
3. Run 3-5 replications
4. Vary one condition per replication

### Step 5: Analyze

Use provided Python scripts:
```bash
python scripts/analyze_games.py --session ../data/sessions/[session_id]/
```

---

## Game Selection Guide

### Ultimatum Game

**Use when studying:**
- Fairness preferences
- Rejection behavior (spite)
- Minimum acceptable offers

**Parameters to vary:**
- `endowment`: Total pie size (50-200)
- `rounds`: Number of rounds (1-10)

**Expected results:**
- Human average: 40% offer, 80% acceptance
- LLM agents: Often higher fairness, but varies by model

**Analysis tips:**
- Plot offer distribution
- Calculate rejection threshold
- Compare by personality type

---

### Trust Game

**Use when studying:**
- Trust formation
- Reciprocity
- Repeated interaction effects

**Parameters to vary:**
- `multiplier`: Return on trust (2.0-4.0)
- `rounds`: Build trust over time (3-10)

**Expected results:**
- Trustors: 50-70% send
- Trustees: 30-50% return
- Trust increases with positive experiences

**Analysis tips:**
- Correlation: send_ratio vs return_ratio
- Track trust evolution over rounds
- Identify trust types (always trust, never trust, conditional)

---

### Public Goods Game

**Use when studying:**
- Cooperation
- Free-riding
- Group dynamics

**Parameters to vary:**
- `group_size`: 2-8 agents
- `multiplier`: 1.5-3.0 (higher = more incentive to cooperate)
- `rounds`: Watch cooperation decay (5-10)

**Expected results:**
- Initial cooperation: 40-60%
- Decay over rounds (30-50% by final round)
- Free-riders: 10-30% of agents

**Analysis tips:**
- Track contribution over time
- Identify cooperators vs free-riders
- Test if altruistic agents maintain cooperation

---

### Dictator Game

**Use when studying:**
- Pure altruism (no strategic incentive)
- Baseline generosity

**Parameters to vary:**
- `endowment`: Amount to share (50-200)

**Expected results:**
- Human average: 20-30% given
- LLM agents: Often higher (40-60%)

**Analysis tips:**
- Compare to Ultimatum offers (should be lower)
- Direct measure of altruism parameter
- Baseline for other games

---

## Agent Configuration

### Personality Archetypes

**The Rational Optimizer**
```json
{
  "risk_aversion": 0.5,
  "altruism": 0.3,
  "fairness_concern": 0.3,
  "trust_level": 0.5,
  "decision_style": "rational"
}
```
- Makes mathematically optimal decisions
- Low variance across runs
- Good control condition

**The Social Cooperator**
```json
{
  "risk_aversion": 0.6,
  "altruism": 0.8,
  "fairness_concern": 0.8,
  "trust_level": 0.7,
  "decision_style": "emotional"
}
```
- High cooperation
- Generous offers
- Reciprocates strongly

**The Self-Interested Defector**
```json
{
  "risk_aversion": 0.4,
  "altruism": 0.1,
  "fairness_concern": 0.2,
  "trust_level": 0.3,
  "decision_style": "rational"
}
```
- Maximizes personal gain
- Free-rides
- Low offers

**The Risk-Taker**
```json
{
  "risk_aversion": 0.2,
  "altruism": 0.4,
  "fairness_concern": 0.4,
  "trust_level": 0.7,
  "decision_style": "heuristic"
}
```
- Bold decisions
- High variance
- Trusts readily

### Balanced Groups

For 4-agent experiments:
1. Risk Averse + Altruistic
2. Risk Seeking + Selfish
3. Risk Neutral + Risk Neutral

For 8-agent experiments:
1. 2× Risk Averse (one altruistic, one selfish)
2. 2× Risk Seeking (one altruistic, one selfish)
3. 4× Risk Neutral (varied altruism)

---

## Data Collection Strategy

### What to Log

**Minimum** (always log):
- Game decisions
- Final payoffs
- Wallet states

**Standard** (recommended):
- All decisions with timestamps
- Transaction history
- Game-by-game results

**Detailed** (for deep analysis):
- LLM prompts and responses
- Reasoning traces
- Memory updates
- Social interactions

### Logging Configuration

```json
"logging": {
  "level": "info",           // debug, info, warning, error
  "save_dialogues": true,    // For qualitative analysis
  "save_memories": true,     // Track long-term effects
  "save_prompts": false,     // Large files, use only if needed
  "auto_save_interval": 60   // Seconds between auto-saves
}
```

### Storage Tips

- Each session: ~1-10 MB depending on duration
- Keep raw logs for reproducibility
- Export to CSV for statistical analysis
- Archive completed experiments regularly

---

## Common Experiment Patterns

### Pattern 1: Baseline → Treatment

**Design:**
1. Run baseline (all agents risk-neutral)
2. Run treatment (varied personalities)
3. Compare outcomes

**Example:**
```json
// Baseline run
"agents": [
  {"name": "Alice", "profile": "risk_neutral"},
  {"name": "Jack", "profile": "risk_neutral"},
  ...
]

// Treatment run
"agents": [
  {"name": "Alice", "profile": "risk_seeking"},
  {"name": "Jack", "profile": "risk_averse"},
  ...
]
```

### Pattern 2: Within-Subjects

**Design:**
- Same agents play multiple game types
- Measure consistency across contexts

**Example:**
```json
"games": [
  {"type": "ultimatum", "schedule": "start"},
  {"type": "trust", "schedule": "every_5_minutes"},
  {"type": "public_goods", "schedule": "every_5_minutes"}
]
```

### Pattern 3: Repeated Interactions

**Design:**
- Many rounds of same game
- Track learning and adaptation

**Example:**
```json
{
  "type": "trust",
  "rounds": 20,
  "schedule": "start"
}
```

### Pattern 4: Environment Change

**Design:**
- Change market conditions mid-experiment
- Measure adaptation

**Implementation:**
```gdscript
# In custom experiment controller
func _on_timer_halfway():
    # Introduce economic shock
    EconomyManager.apply_wealth_tax(agent_wallets, 0.5)  # 50% tax
    # or
    EconomyManager.apply_ubi(agent_wallets, 100.0)  # $100 UBI
```

---

## Advanced Techniques

### 1. Dynamic Difficulty

Adjust game parameters based on performance:

```gdscript
func adjust_public_goods_difficulty(cooperation_rate: float):
    if cooperation_rate > 0.8:
        # Make cooperation less attractive
        current_multiplier -= 0.2
    elif cooperation_rate < 0.3:
        # Encourage cooperation
        current_multiplier += 0.3
```

### 2. Network Effects

Create social networks:

```gdscript
var social_network = {
    "Alice": ["Jack", "Grace"],
    "Jack": ["Alice"],
    "Grace": ["Alice", "Joe"],
    "Joe": ["Grace"]
}

# Only allow interactions between connected agents
func can_interact(agent_a: String, agent_b: String) -> bool:
    return agent_b in social_network.get(agent_a, [])
```

### 3. Information Asymmetry

Give some agents privileged information:

```gdscript
func generate_agent_context(agent_name: String) -> String:
    var context = base_context
    
    if agent_name in informed_agents:
        context += "\nPrivileged Info: The market will crash soon."
    
    return context
```

### 4. Evolutionary Dynamics

Let successful strategies propagate:

```gdscript
func evolve_population():
    # Identify top performers
    var ranked_agents = rank_by_wealth()
    var top_third = ranked_agents.slice(0, ranked_agents.size() / 3)
    
    # Copy their personalities to bottom third
    var bottom_third = ranked_agents.slice(2 * ranked_agents.size() / 3)
    for i in range(bottom_third.size()):
        bottom_third[i].load_personality(top_third[i].get_personality())
```

---

## Analysis Best Practices

### 1. Descriptive Statistics First

Always start with:
- Mean, median, std dev
- Histograms
- Time series plots

```python
import pandas as pd
df = pd.read_csv('session_data.csv')
print(df.describe())
df.hist(bins=20, figsize=(12, 8))
```

### 2. Statistical Tests

For comparing conditions:
- **t-test**: Compare two groups
- **ANOVA**: Compare multiple groups
- **Mann-Whitney**: Non-parametric alternative

```python
from scipy import stats

# Compare cooperation rates
group_a = df[df['condition'] == 'baseline']['cooperation_rate']
group_b = df[df['condition'] == 'treatment']['cooperation_rate']

t_stat, p_value = stats.ttest_ind(group_a, group_b)
print(f"t={t_stat:.3f}, p={p_value:.3f}")
```

### 3. Regression Analysis

Understand what predicts outcomes:

```python
import statsmodels.api as sm

# Predict cooperation from personality
X = df[['risk_aversion', 'altruism', 'trust_level']]
y = df['cooperation_rate']

model = sm.OLS(y, sm.add_constant(X)).fit()
print(model.summary())
```

### 4. Visualization

Create publication-quality plots:

```python
import seaborn as sns

# Cooperation by personality type
sns.boxplot(data=df, x='personality_type', y='cooperation_rate')
plt.title('Cooperation Rate by Personality Type')
plt.savefig('cooperation_by_type.png', dpi=300)
```

---

## Experiment Checklist

Before running:
- [ ] Clear research question defined
- [ ] Config file created and validated
- [ ] Pilot test completed successfully
- [ ] Ollama running with correct model
- [ ] Sufficient disk space for logs
- [ ] Analysis scripts prepared

During experiment:
- [ ] Monitor console for errors
- [ ] Check agents are making decisions
- [ ] Verify data is being logged
- [ ] Note any anomalies

After experiment:
- [ ] Save raw data before analyzing
- [ ] Run automated analysis scripts
- [ ] Generate summary report
- [ ] Archive session data

---

## Troubleshooting

**Agents not behaving as expected:**
- Check personality parameters loaded correctly
- Verify LLM is responding (check API logs)
- Reduce temperature for more consistent behavior

**Games not triggering:**
- Check schedule syntax
- Verify sufficient agents for group_size
- Check experiment duration vs schedule

**Data looks random:**
- Increase sample size (more agents or runs)
- Check if personality differences are large enough
- Verify decisions are being made by agents, not random

**Out of memory errors:**
- Reduce logging detail
- Decrease experiment duration
- Use smaller LLM model

---

## Example: Complete Experiment Workflow

### 1. Research Question
"Do altruistic agents maintain cooperation better than selfish agents in repeated public goods games?"

### 2. Hypothesis
Altruistic agents will show less cooperation decay over rounds.

### 3. Design
- 8 agents: 4 altruistic (altruism=0.9), 4 selfish (altruism=0.1)
- Public Goods Game: 10 rounds
- All other traits equal (risk_aversion=0.5)
- Initial wealth: $200

### 4. Implementation
Create config: `experiment_altruism_cooperation.json`

### 5. Execution
- Run 5 replications
- Each: 15 minutes virtual time
- Record all contributions

### 6. Analysis
```python
# Load data
sessions = ['session1', 'session2', 'session3', 'session4', 'session5']
all_data = pd.concat([load_session(s) for s in sessions])

# Group by personality and round
grouped = all_data.groupby(['personality', 'round'])['contribution_ratio'].mean()

# Plot
grouped.unstack(level=0).plot(figsize=(10, 6))
plt.title('Cooperation Decay: Altruistic vs Selfish')
plt.xlabel('Round')
plt.ylabel('Average Contribution Ratio')
plt.legend(['Altruistic', 'Selfish'])
plt.savefig('results.png')

# Statistical test
final_round = all_data[all_data['round'] == 10]
altruistic = final_round[final_round['altruism'] > 0.5]['contribution_ratio']
selfish = final_round[final_round['altruism'] < 0.5]['contribution_ratio']
t_stat, p_value = stats.ttest_ind(altruistic, selfish)
print(f"Final round difference: t={t_stat:.2f}, p={p_value:.4f}")
```

### 7. Interpret
- If p < 0.05: Significant difference
- If altruistic > selfish: Hypothesis supported
- Report effect size (Cohen's d)

### 8. Document
Write up findings with:
- Methods (exact config used)
- Results (statistics + visualization)
- Discussion (what does this mean?)
- Limitations (sample size, model choice)

---

**Happy experimenting! 🔬💰🤖**


# Quick Start Guide

Get your economy experiments running in **15 minutes**! 🚀

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Godot Engine 4.3+** installed and working
- [ ] **Ollama** running locally (see `../experiment_tools/SETUP_SUCCESS.md`)
- [ ] **Python 3.8+** (for analysis tools, optional for basic experiments)
- [ ] **Microverse** project opened in Godot
- [ ] At least one LLM model pulled in Ollama (e.g., `mistral:7b-instruct`)

### Quick Ollama Check

```powershell
# Test if Ollama is running
ollama list

# Expected output: List of installed models
# If not working, see ../experiment_tools/quick_test.bat
```

## 🎮 Part 1: Basic Setup (5 minutes)

### Step 1: Configure Microverse API Settings

1. **Launch Microverse**
   - Open Godot Editor
   - Press `F5` to run the main scene
   - Wait for the game to load

2. **Open Settings Panel**
   - Press `ESC` key
   - Navigate to **"Settings"** tab
   - Click on **"API Settings"**

3. **Configure Ollama Connection**
   ```
   API Type:     Ollama
   API Address:  http://localhost:11434/v1/chat/completions
   Model Name:   mistral:7b-instruct
   API Key:      [leave blank]
   Temperature:  0.7
   Max Tokens:   2000
   ```

4. **Save and Close**
   - Click **"Save Settings"**
   - Close the settings panel

### Step 2: Verify Character Setup

1. **Check Character Manager**
   - In Godot Editor, open `script/CharacterManager.gd`
   - Verify all 8 characters are defined:
     - Alice, Jack, Grace, Joe, Lea, Monica, Stephen, Tom

2. **Test Character Interaction** (Optional)
   - Run the main Office scene
   - Click on any character
   - Try talking to them
   - If they respond, your setup is working! ✅

## 🔬 Part 2: Run Your First Experiment (10 minutes)

### Option A: Quick Behavioral Game Test

1. **Open Game Lab Scene**
   ```
   In Godot: economy_experiments/scenes/BehavioralGameLab.tscn
   ```

2. **Run the Scene**
   - Press `F6` (Run Current Scene)
   - You'll see the Behavioral Game Lab interface

3. **Select a Game**
   - Click **"Ultimatum Game"**
   - Choose 2 agents (e.g., Alice as Proposer, Jack as Responder)
   - Set initial endowment: `$100`
   - Click **"Start Game"**

4. **Observe Results**
   - Watch agents make decisions
   - See offers and responses in real-time
   - Results are logged to `data/sessions/`

### Option B: Market Simulation

1. **Open Market Scene**
   ```
   In Godot: economy_experiments/scenes/MarketSimulation.tscn
   ```

2. **Configure Market**
   - Set number of traders: `4`
   - Initial goods: `10 items`
   - Initial cash per agent: `$500`
   - Market duration: `5 minutes` (virtual time)

3. **Run Simulation**
   - Press `F6`
   - Watch agents buy, sell, and negotiate
   - Price discovery happens automatically

4. **Check Results**
   - Final wealth distribution displayed
   - Transaction history saved
   - Price chart shown

### Option C: Load Predefined Experiment

1. **Use Experiment Manager**
   - Open `economy_experiments/scenes/ExperimentDashboard.tscn`
   - Press `F6` to run

2. **Load Configuration**
   - Click **"Load Experiment"**
   - Select `configs/experiments/phase1_behavioral.json`
   - Review experiment parameters

3. **Execute Experiment**
   - Click **"Start Experiment"**
   - Experiment runs automatically
   - Progress shown in real-time

4. **View Results**
   - Results saved to `data/sessions/[timestamp]/`
   - Summary displayed on dashboard

## 📊 Part 3: Analyze Results (Optional)

### Setup Python Environment

```bash
# Navigate to analysis folder
cd economy_experiments/analysis

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Mac/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Run Analysis

```bash
# Analyze behavioral games
python scripts/analyze_games.py --session data/sessions/[your_session]/

# Visualize market data
python scripts/visualize_market.py --session data/sessions/[your_session]/

# Calculate all metrics
python scripts/calculate_metrics.py --session data/sessions/[your_session]/
```

### Open Jupyter Notebooks

```bash
# Start Jupyter
jupyter notebook

# Open notebooks/01_behavioral_analysis.ipynb
# Follow step-by-step analysis
```

## 🎯 Part 4: Customize Your Experiment

### Modify Agent Personalities

Edit agent profiles in `configs/agents/`:

```json
// configs/agents/risk_seeking.json
{
  "name": "risk_seeking",
  "description": "Agent with high risk tolerance",
  "parameters": {
    "risk_aversion": 0.2,
    "time_preference": 0.8,
    "altruism": 0.3,
    "fairness_concern": 0.4,
    "trust_level": 0.6
  },
  "decision_style": "aggressive",
  "learning_rate": 0.7
}
```

Apply to characters:
- Open `ExperimentDashboard.tscn`
- Assign profiles: Alice → risk_seeking, Jack → risk_averse, etc.

### Create Custom Experiment

Create new file `configs/experiments/my_experiment.json`:

```json
{
  "name": "My Custom Experiment",
  "description": "Testing wealth inequality",
  "duration_minutes": 30,
  "agents": [
    {"name": "Alice", "profile": "risk_seeking", "initial_cash": 1000},
    {"name": "Jack", "profile": "risk_averse", "initial_cash": 1000},
    {"name": "Grace", "profile": "altruistic", "initial_cash": 500},
    {"name": "Joe", "profile": "selfish", "initial_cash": 500}
  ],
  "games": [
    {
      "type": "UltimatumGame",
      "rounds": 5,
      "endowment": 100,
      "schedule": "every_5_minutes"
    },
    {
      "type": "PublicGoodsGame",
      "rounds": 3,
      "group_size": 4,
      "multiplier": 2.0
    }
  ],
  "market": {
    "enabled": true,
    "goods_types": ["food", "tools", "luxury"],
    "price_range": [10, 100]
  },
  "logging": {
    "level": "detailed",
    "save_dialogues": true,
    "save_memories": true
  }
}
```

Load in `ExperimentDashboard`:
- Click "Load Experiment"
- Select your JSON file
- Run!

## 🔧 Troubleshooting

### Issue: Agents Not Responding

**Symptoms**: Agents don't make decisions or dialogue is empty

**Solutions**:
1. Check Ollama is running: `ollama list`
2. Verify API settings in Microverse (ESC → Settings)
3. Check Godot output console for errors
4. Ensure model has enough VRAM (run `nvidia-smi`)

### Issue: Experiment Freezes

**Symptoms**: Simulation stops or hangs

**Solutions**:
1. Reduce number of agents (try 4 instead of 8)
2. Increase max response time in `ExperimentManager.gd`
3. Check for infinite loops in game logic
4. Monitor system resources (CPU, GPU, RAM)

### Issue: Data Not Saving

**Symptoms**: No files in `data/sessions/`

**Solutions**:
1. Check folder permissions on `data/` directory
2. Verify `ExperimentLogger` is attached to scene
3. Check Godot console for file write errors
4. Ensure disk has free space

### Issue: Python Analysis Fails

**Symptoms**: Scripts throw errors or charts don't generate

**Solutions**:
1. Verify all dependencies installed: `pip install -r requirements.txt`
2. Check Python version: `python --version` (need 3.8+)
3. Ensure data files are valid JSON
4. Check file paths in scripts

## 📚 Next Steps

Now that you're set up:

1. **Read the Documentation**
   - [API Reference](docs/API_REFERENCE.md) - Understand the code
   - [Experiment Guide](docs/EXPERIMENT_GUIDE.md) - Design better experiments
   - [Integration Guide](docs/INTEGRATION_GUIDE.md) - Add new features

2. **Run Example Experiments**
   - Phase 1: Behavioral Games (`configs/experiments/phase1_behavioral.json`)
   - Phase 2: Market Dynamics (`configs/experiments/phase2_market.json`)
   - Phase 3: Model Comparison (`configs/experiments/phase3_comparison.json`)

3. **Extend the System**
   - Add new behavioral games
   - Implement auction mechanisms
   - Create custom metrics
   - Design novel experiments

4. **Publish Your Research**
   - Collect data from multiple runs
   - Analyze with provided tools
   - Write up findings
   - Share with community!

## 🆘 Get Help

- **Documentation Issues**: Check `docs/` folder
- **Technical Problems**: Review Godot output console
- **Research Questions**: See example experiments in `configs/`
- **Bug Reports**: Check if similar issues exist

## ✅ Success Checklist

You're ready to go when:

- [ ] Ollama responds to API calls
- [ ] Microverse connects to Ollama successfully
- [ ] At least one behavioral game runs without errors
- [ ] Data files are created in `data/sessions/`
- [ ] Python analysis scripts execute (if using)
- [ ] You understand the basic experiment workflow

---

**Ready to discover how AI agents handle money? Let's experiment! 🚀💰**


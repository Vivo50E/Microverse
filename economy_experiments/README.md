# Economy Experiments

**Multi-Agent Economic Behavior and Financial Decision-Making Research Platform**

[![Godot Engine](https://img.shields.io/badge/Godot-4.3+-blue.svg)](https://godotengine.org/)
[![Research](https://img.shields.io/badge/Research-Active-green.svg)](.)

## 🎯 Overview

This module extends **Microverse** with comprehensive economic systems and behavioral game experiments to study how LLM-based agents make financial decisions, interact in markets, and exhibit economic behaviors similar to humans.

## ✨ Features

### 🎮 Behavioral Economics Games
- **Ultimatum Game** - Study fairness preferences and rejection behavior
- **Trust Game** - Analyze trust formation and reciprocity
- **Public Goods Game** - Examine cooperation and free-riding
- **Dictator Game** - Measure pure altruism

### 💰 Economic Systems
- **Wallet System** - Cash, savings, debt management
- **Market Mechanisms** - Dynamic pricing, supply/demand
- **Trading System** - Agent-to-agent transactions
- **Resource Pool** - Public goods and shared resources

### 📊 Data Collection & Analysis
- **Real-time Logging** - All decisions and transactions
- **Metrics Calculator** - Gini coefficient, wealth mobility, etc.
- **Data Exporter** - JSON, CSV formats
- **Python Analysis** - Jupyter notebooks and visualization

### 🔬 Experiment Management
- **Configuration System** - JSON-based experiment design
- **Agent Profiles** - Risk preferences, personality traits
- **Automated Execution** - Batch experiments
- **Result Comparison** - Multi-model analysis

## 📁 Project Structure

```
economy_experiments/
├── README.md                         # This file
├── QUICK_START.md                    # Setup instructions
│
├── scripts/                          # GDScript components
│   ├── economic_system/              # Core economic logic
│   │   ├── EconomicAgent.gd          # Agent with economic behaviors
│   │   ├── Wallet.gd                 # Financial management
│   │   ├── Market.gd                 # Trading marketplace
│   │   ├── Transaction.gd            # Transaction records
│   │   └── ResourcePool.gd           # Public goods
│   │
│   ├── behavioral_games/             # Game implementations
│   │   ├── GameBase.gd               # Base class for all games
│   │   ├── UltimatumGame.gd
│   │   ├── TrustGame.gd
│   │   ├── PublicGoodsGame.gd
│   │   └── DictatorGame.gd
│   │
│   ├── data_collection/              # Data pipeline
│   │   ├── ExperimentLogger.gd       # Event logging
│   │   ├── MetricsCalculator.gd      # Statistical metrics
│   │   └── DataExporter.gd           # Export utilities
│   │
│   └── managers/                     # System managers
│       ├── ExperimentManager.gd      # Experiment orchestration
│       └── EconomyManager.gd         # Economic system coordinator
│
├── configs/                          # Experiment configurations
│   ├── experiments/                  # Experiment designs
│   │   ├── phase1_behavioral.json
│   │   ├── phase2_market.json
│   │   └── phase3_comparison.json
│   └── agents/                       # Agent personality profiles
│       ├── risk_averse.json
│       ├── risk_neutral.json
│       ├── risk_seeking.json
│       ├── altruistic.json
│       └── selfish.json
│
├── scenes/                           # Godot scene files
│   ├── BehavioralGameLab.tscn
│   ├── MarketSimulation.tscn
│   └── ExperimentDashboard.tscn
│
├── data/                             # Experimental data (gitignored)
│   ├── sessions/                     # Experiment sessions
│   ├── logs/                         # Log files
│   └── exports/                      # Exported datasets
│
├── analysis/                         # Python analysis tools
│   ├── notebooks/                    # Jupyter notebooks
│   ├── scripts/                      # Analysis scripts
│   ├── requirements.txt
│   └── README.md
│
└── docs/                             # Documentation
    ├── API_REFERENCE.md
    ├── EXPERIMENT_GUIDE.md
    └── INTEGRATION_GUIDE.md
```

## 🚀 Quick Start

### Prerequisites
- **Godot Engine 4.3+** installed
- **Python 3.8+** (for analysis tools)
- **Ollama** running locally (see `../experiment_tools/`)

### Basic Setup

1. **Configure Ollama in Microverse**
   - Press `ESC` in game → Settings → API Settings
   - Set API Type: `Ollama`
   - Set API Address: `http://localhost:11434/v1/chat/completions`
   - Set Model: `mistral:7b-instruct`

2. **Load Experiment Scene**
   - Open Godot Editor
   - Navigate to `economy_experiments/scenes/`
   - Open `BehavioralGameLab.tscn`
   - Press `F5` to run

3. **Run First Experiment**
   ```bash
   # See QUICK_START.md for detailed instructions
   ```

For detailed setup instructions, see **[QUICK_START.md](QUICK_START.md)**.

## 📖 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Step-by-step setup
- **[API Reference](docs/API_REFERENCE.md)** - Class documentation
- **[Experiment Guide](docs/EXPERIMENT_GUIDE.md)** - How to design experiments
- **[Integration Guide](docs/INTEGRATION_GUIDE.md)** - Integrate with Microverse

## 🔬 Research Applications

### Study Topics
1. **Economic Decision-Making**
   - Risk preferences and choice under uncertainty
   - Time preferences and intertemporal choice
   - Budget constraints and resource allocation

2. **Market Behavior**
   - Price discovery and market equilibrium
   - Trading strategies and arbitrage
   - Market manipulation and collusion

3. **Social Economics**
   - Fairness and inequality aversion
   - Trust formation and reciprocity
   - Cooperation in public goods provision
   - Social learning and information cascades

4. **Financial Literacy**
   - Saving and investment decisions
   - Debt management strategies
   - Risk assessment capabilities

5. **Model Comparison**
   - Local vs. Cloud LLMs (Mistral vs. GPT-4)
   - Model size effects (7B vs. 13B vs. 70B)
   - Prompt engineering impact

### Expected Outcomes
- Quantitative data on LLM economic rationality
- Insights into AI decision biases
- Frameworks for designing AI economic agents
- Benchmarks for multi-agent economic simulations

## 📊 Example Results

After running experiments, you'll get:
- Transaction logs with complete history
- Statistical summaries (Gini, wealth mobility)
- Behavioral game results (acceptance rates, contributions)
- Visualizations (wealth distribution, price trends)

## 🤝 Contributing

This is a research project. Contributions welcome:
- New behavioral games
- Additional economic mechanisms
- Analysis improvements
- Documentation enhancements

## 📄 License

MIT License - See parent project LICENSE file

## 🔗 Related Projects

- **[Microverse](../)** - Parent multi-agent platform
- **[Experiment Tools](../experiment_tools/)** - Ollama setup and testing

## 📚 Citation

If you use this in your research, please cite:

```bibtex
@article{microverse_economy_2025,
  title={Economic Behavior and Financial Decision-Making in Local LLM-based Multi-Agent Systems},
  author={[Your Name]},
  journal={[Target Venue]},
  year={2025}
}
```

## 📧 Contact

For questions or collaboration:
- Open an issue in the repository
- Contact: [Your Email]

---

**Built with ❤️ for AI Economics Research**


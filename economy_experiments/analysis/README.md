# Python Analysis Tools

This folder contains Python scripts and Jupyter notebooks for analyzing experiment data collected from the economy experiments.

## Setup

### Install Dependencies

```bash
cd economy_experiments/analysis
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

## Structure

- `notebooks/` - Jupyter notebooks for interactive analysis
- `scripts/` - Python scripts for automated analysis
- `requirements.txt` - Python dependencies

## Quick Start

### 1. Analyze Behavioral Games

```bash
python scripts/analyze_games.py --session ../data/sessions/[your_session_id]/
```

This will generate:
- Summary statistics for each game type
- Cooperation rates, fairness scores, trust levels
- Per-agent behavioral profiles
- Comparison charts

### 2. Visualize Market Data

```bash
python scripts/visualize_market.py --session ../data/sessions/[your_session_id]/
```

Generates:
- Price history charts
- Volume and liquidity plots
- Wealth distribution graphs
- Gini coefficient trends

### 3. Calculate Metrics

```bash
python scripts/calculate_metrics.py --session ../data/sessions/[your_session_id]/
```

Calculates:
- Gini coefficient
- Wealth mobility
- Market efficiency
- Decision consistency
- All behavioral metrics

## Jupyter Notebooks

Start Jupyter:

```bash
jupyter notebook
```

Then open:

1. **`01_behavioral_analysis.ipynb`** - Deep dive into behavioral game results
2. **`02_market_dynamics.ipynb`** - Market analysis and trading patterns
3. **`03_model_comparison.ipynb`** - Compare results across different LLM models

## Output

All analysis outputs are saved to `../data/exports/` by default:
- Charts: PNG format
- Tables: CSV format
- Reports: Markdown and HTML

## Tips

- Use `--help` flag on any script to see all options
- Combine multiple sessions for longitudinal analysis
- Export data to CSV for use in R or other tools
- Notebooks are self-documenting - run cells sequentially

## Troubleshooting

**ImportError:** Make sure you activated the virtual environment and installed requirements

**FileNotFoundError:** Check that the session path is correct (use absolute or relative path)

**Empty plots:** Verify the session has completed and data files exist

## Contributing

To add new analysis:
1. Create a new script in `scripts/`
2. Follow the existing pattern (argparse, pandas, matplotlib)
3. Add corresponding notebook in `notebooks/` for interactive exploration


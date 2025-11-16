"""
Analyze behavioral game results from experiment sessions

Usage:
    python analyze_games.py --session PATH_TO_SESSION

Example:
    python analyze_games.py --session ../data/sessions/session_20250101_120000/
"""

import json
import argparse
from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set style
sns.set_theme(style="whitegrid", palette="muted")


def load_session_data(session_path):
    """Load all data files from a session directory"""
    session_path = Path(session_path)
    
    data = {}
    
    # Load games
    games_file = session_path / "games.json"
    if games_file.exists():
        with open(games_file, 'r', encoding='utf-8') as f:
            data['games'] = json.load(f)
    
    # Load decisions
    decisions_file = session_path / "decisions.json"
    if decisions_file.exists():
        with open(decisions_file, 'r', encoding='utf-8') as f:
            data['decisions'] = json.load(f)
    
    # Load events
    events_file = session_path / "events.json"
    if events_file.exists():
        with open(events_file, 'r', encoding='utf-8') as f:
            data['events'] = json.load(f)
    
    return data


def analyze_ultimatum_games(games):
    """Analyze Ultimatum Game results"""
    ultimatum_games = [g for g in games if g.get('game_type') == 'ultimatum']
    
    if not ultimatum_games:
        return None
    
    results = []
    for game in ultimatum_games:
        for round_result in game.get('results', []):
            results.append({
                'game_id': game['game_id'],
                'round': round_result['round'],
                'proposer': round_result['proposer'],
                'responder': round_result['responder'],
                'offer': round_result['offer'],
                'offer_ratio': round_result['offer_ratio'],
                'accepted': round_result['accepted'],
                'proposer_payoff': round_result['proposer_payoff'],
                'responder_payoff': round_result['responder_payoff']
            })
    
    df = pd.DataFrame(results)
    
    analysis = {
        'total_rounds': len(df),
        'acceptance_rate': df['accepted'].mean(),
        'mean_offer_ratio': df['offer_ratio'].mean(),
        'median_offer_ratio': df['offer_ratio'].median(),
        'std_offer_ratio': df['offer_ratio'].std(),
        'min_offer': df['offer'].min(),
        'max_offer': df['offer'].max()
    }
    
    return df, analysis


def analyze_trust_games(games):
    """Analyze Trust Game results"""
    trust_games = [g for g in games if g.get('game_type') == 'trust']
    
    if not trust_games:
        return None
    
    results = []
    for game in trust_games:
        for round_result in game.get('results', []):
            results.append({
                'game_id': game['game_id'],
                'round': round_result['round'],
                'trustor': round_result['trustor'],
                'trustee': round_result['trustee'],
                'amount_sent': round_result['amount_sent'],
                'send_ratio': round_result['send_ratio'],
                'amount_returned': round_result['amount_returned'],
                'return_ratio': round_result['return_ratio'],
                'trust_rewarded': round_result['trust_rewarded']
            })
    
    df = pd.DataFrame(results)
    
    analysis = {
        'total_rounds': len(df),
        'mean_send_ratio': df['send_ratio'].mean(),
        'mean_return_ratio': df['return_ratio'].mean(),
        'trust_success_rate': df['trust_rewarded'].mean()
    }
    
    return df, analysis


def analyze_public_goods_games(games):
    """Analyze Public Goods Game results"""
    pg_games = [g for g in games if g.get('game_type') == 'public_goods']
    
    if not pg_games:
        return None
    
    results = []
    for game in pg_games:
        for round_result in game.get('results', []):
            results.append({
                'game_id': game['game_id'],
                'round': round_result['round'],
                'average_contribution': round_result['average_contribution'],
                'average_contribution_ratio': round_result['average_contribution_ratio'],
                'cooperation_rate': round_result['cooperation_rate'],
                'free_rider_count': round_result['free_rider_count']
            })
    
    df = pd.DataFrame(results)
    
    analysis = {
        'total_rounds': len(df),
        'mean_contribution_ratio': df['average_contribution_ratio'].mean(),
        'mean_cooperation_rate': df['cooperation_rate'].mean(),
        'avg_free_riders': df['free_rider_count'].mean()
    }
    
    return df, analysis


def plot_game_results(data_dict, output_dir):
    """Generate plots for all game types"""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Ultimatum Game
    if 'ultimatum' in data_dict and data_dict['ultimatum'] is not None:
        df, analysis = data_dict['ultimatum']
        
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        
        # Offer distribution
        axes[0].hist(df['offer_ratio'], bins=20, edgecolor='black')
        axes[0].axvline(0.5, color='red', linestyle='--', label='Fair Split')
        axes[0].set_xlabel('Offer Ratio')
        axes[0].set_ylabel('Frequency')
        axes[0].set_title('Ultimatum Game: Offer Distribution')
        axes[0].legend()
        
        # Acceptance by offer
        acceptance_by_offer = df.groupby(pd.cut(df['offer_ratio'], bins=10))['accepted'].mean()
        acceptance_by_offer.plot(kind='bar', ax=axes[1])
        axes[1].set_xlabel('Offer Ratio Range')
        axes[1].set_ylabel('Acceptance Rate')
        axes[1].set_title('Acceptance Rate by Offer')
        axes[1].tick_params(axis='x', rotation=45)
        
        plt.tight_layout()
        plt.savefig(output_dir / 'ultimatum_analysis.png', dpi=300)
        plt.close()
    
    # Trust Game
    if 'trust' in data_dict and data_dict['trust'] is not None:
        df, analysis = data_dict['trust']
        
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        
        # Send vs Return
        axes[0].scatter(df['send_ratio'], df['return_ratio'], alpha=0.6)
        axes[0].plot([0, 1], [0, 1], 'r--', label='Equal Return')
        axes[0].set_xlabel('Send Ratio')
        axes[0].set_ylabel('Return Ratio')
        axes[0].set_title('Trust Game: Send vs Return')
        axes[0].legend()
        
        # Trust rewarded
        trust_rewarded = df['trust_rewarded'].value_counts()
        trust_rewarded.plot(kind='bar', ax=axes[1])
        axes[1].set_xlabel('Trust Rewarded')
        axes[1].set_ylabel('Count')
        axes[1].set_title('Trust Success Rate')
        axes[1].tick_params(axis='x', rotation=0)
        
        plt.tight_layout()
        plt.savefig(output_dir / 'trust_analysis.png', dpi=300)
        plt.close()
    
    # Public Goods Game
    if 'public_goods' in data_dict and data_dict['public_goods'] is not None:
        df, analysis = data_dict['public_goods']
        
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        
        # Contribution over rounds
        axes[0].plot(df['round'], df['average_contribution_ratio'], marker='o')
        axes[0].set_xlabel('Round')
        axes[0].set_ylabel('Average Contribution Ratio')
        axes[0].set_title('Public Goods: Contribution Over Time')
        axes[0].grid(True)
        
        # Free riders
        axes[1].bar(df['round'], df['free_rider_count'])
        axes[1].set_xlabel('Round')
        axes[1].set_ylabel('Free Rider Count')
        axes[1].set_title('Free Riders Over Rounds')
        
        plt.tight_layout()
        plt.savefig(output_dir / 'public_goods_analysis.png', dpi=300)
        plt.close()


def generate_report(data_dict, output_path):
    """Generate markdown summary report"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# Behavioral Games Analysis Report\n\n")
        
        # Ultimatum Game
        if 'ultimatum' in data_dict and data_dict['ultimatum'] is not None:
            df, analysis = data_dict['ultimatum']
            f.write("## Ultimatum Game\n\n")
            f.write(f"- Total Rounds: {analysis['total_rounds']}\n")
            f.write(f"- Acceptance Rate: {analysis['acceptance_rate']:.2%}\n")
            f.write(f"- Mean Offer Ratio: {analysis['mean_offer_ratio']:.2%}\n")
            f.write(f"- Median Offer Ratio: {analysis['median_offer_ratio']:.2%}\n\n")
        
        # Trust Game
        if 'trust' in data_dict and data_dict['trust'] is not None:
            df, analysis = data_dict['trust']
            f.write("## Trust Game\n\n")
            f.write(f"- Total Rounds: {analysis['total_rounds']}\n")
            f.write(f"- Mean Send Ratio: {analysis['mean_send_ratio']:.2%}\n")
            f.write(f"- Mean Return Ratio: {analysis['mean_return_ratio']:.2%}\n")
            f.write(f"- Trust Success Rate: {analysis['trust_success_rate']:.2%}\n\n")
        
        # Public Goods Game
        if 'public_goods' in data_dict and data_dict['public_goods'] is not None:
            df, analysis = data_dict['public_goods']
            f.write("## Public Goods Game\n\n")
            f.write(f"- Total Rounds: {analysis['total_rounds']}\n")
            f.write(f"- Mean Contribution Ratio: {analysis['mean_contribution_ratio']:.2%}\n")
            f.write(f"- Mean Cooperation Rate: {analysis['mean_cooperation_rate']:.2%}\n")
            f.write(f"- Average Free Riders: {analysis['avg_free_riders']:.1f}\n\n")


def main():
    parser = argparse.ArgumentParser(description='Analyze behavioral game results')
    parser.add_argument('--session', required=True, help='Path to session directory')
    parser.add_argument('--output', default='../data/exports/', help='Output directory for results')
    args = parser.parse_args()
    
    print(f"Loading data from {args.session}...")
    data = load_session_data(args.session)
    
    if 'games' not in data:
        print("ERROR: No games data found")
        return
    
    print(f"Analyzing {len(data['games'])} games...")
    
    # Analyze each game type
    results = {}
    
    ultimatum_result = analyze_ultimatum_games(data['games'])
    if ultimatum_result:
        results['ultimatum'] = ultimatum_result
        print(f"  - Analyzed {ultimatum_result[1]['total_rounds']} Ultimatum Game rounds")
    
    trust_result = analyze_trust_games(data['games'])
    if trust_result:
        results['trust'] = trust_result
        print(f"  - Analyzed {trust_result[1]['total_rounds']} Trust Game rounds")
    
    pg_result = analyze_public_goods_games(data['games'])
    if pg_result:
        results['public_goods'] = pg_result
        print(f"  - Analyzed {pg_result[1]['total_rounds']} Public Goods Game rounds")
    
    # Generate plots
    print(f"Generating plots...")
    plot_game_results(results, args.output)
    
    # Generate report
    print(f"Generating report...")
    generate_report(results, Path(args.output) / 'behavioral_analysis_report.md')
    
    print(f"\nAnalysis complete! Results saved to {args.output}")


if __name__ == '__main__':
    main()


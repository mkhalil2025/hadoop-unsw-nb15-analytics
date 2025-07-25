"""
UNSW-NB15 Dataset Visualization Generator
UEL-CN-7031 Big Data Analytics Assignment

This module provides automated visualization generation for the UNSW-NB15 cybersecurity dataset.
Includes functions for creating publication-quality charts and interactive dashboards.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import warnings
from pathlib import Path
from datetime import datetime
import json
from typing import Dict, List, Optional, Tuple, Union

# Suppress warnings for cleaner output
warnings.filterwarnings('ignore')

# Set style configurations
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

class UNSWVisualizationGenerator:
    """
    Comprehensive visualization generator for UNSW-NB15 dataset analysis.
    """
    
    def __init__(self, output_dir: str = "./output/visualizations"):
        """
        Initialize the visualization generator.
        
        Args:
            output_dir: Directory to save generated visualizations
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Color schemes for different visualization types
        self.colors = {
            'attack': ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57'],
            'normal': ['#74B9FF', '#81ECEC', '#A29BFE', '#FD79A8', '#FDCB6E'],
            'protocol': ['#E17055', '#00B894', '#0984E3', '#A29BFE', '#FDCB6E'],
            'severity': ['#2ECC71', '#F39C12', '#E74C3C', '#8E44AD']
        }
    
    def load_hive_data(self, query: str, connection_params: Dict = None) -> pd.DataFrame:
        """
        Load data from Hive using provided query.
        
        Args:
            query: HiveQL query to execute
            connection_params: Hive connection parameters
            
        Returns:
            DataFrame with query results
        """
        try:
            from pyhive import hive
            
            # Default connection parameters
            if connection_params is None:
                connection_params = {
                    'host': 'localhost',
                    'port': 10000,
                    'username': 'hive',
                    'database': 'unsw_nb15'
                }
            
            # Create connection
            connection = hive.Connection(**connection_params)
            
            # Execute query and return DataFrame
            df = pd.read_sql(query, connection)
            connection.close()
            
            return df
            
        except Exception as e:
            print(f"Error loading data from Hive: {e}")
            # Return sample data for demonstration
            return self._generate_sample_data()
    
    def _generate_sample_data(self) -> pd.DataFrame:
        """
        Generate sample data for demonstration when Hive is not available.
        """
        np.random.seed(42)
        
        attack_categories = ['Normal', 'DoS', 'Exploits', 'Reconnaissance', 
                           'Analysis', 'Backdoor', 'Fuzzers', 'Generic', 
                           'Shellcode', 'Worms']
        protocols = ['tcp', 'udp', 'icmp', 'arp']
        services = ['http', 'https', 'ssh', 'ftp', 'dns', 'smtp', '-']
        
        n_records = 10000
        
        data = {
            'attack_cat': np.random.choice(attack_categories, n_records, 
                                         p=[0.6, 0.08, 0.08, 0.06, 0.04, 0.03, 0.03, 0.03, 0.03, 0.02]),
            'proto': np.random.choice(protocols, n_records, p=[0.7, 0.2, 0.08, 0.02]),
            'service': np.random.choice(services, n_records, p=[0.3, 0.2, 0.15, 0.1, 0.1, 0.05, 0.1]),
            'sbytes': np.random.lognormal(8, 2, n_records),
            'dbytes': np.random.lognormal(7, 2, n_records),
            'dur': np.random.exponential(2, n_records),
            'spkts': np.random.poisson(10, n_records),
            'dpkts': np.random.poisson(8, n_records),
            'hour_of_day': np.random.randint(0, 24, n_records),
            'label': np.random.choice([0, 1], n_records, p=[0.6, 0.4])
        }
        
        df = pd.DataFrame(data)
        df['total_bytes'] = df['sbytes'] + df['dbytes']
        df['total_pkts'] = df['spkts'] + df['dpkts']
        
        return df
    
    def create_attack_distribution_chart(self, df: pd.DataFrame) -> str:
        """
        Create attack category distribution visualization.
        """
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Attack category counts
        attack_counts = df['attack_cat'].value_counts()
        
        # Bar chart
        bars = ax1.bar(range(len(attack_counts)), attack_counts.values, 
                      color=self.colors['attack'][:len(attack_counts)])
        ax1.set_title('Attack Category Distribution', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Attack Category')
        ax1.set_ylabel('Number of Records')
        ax1.set_xticks(range(len(attack_counts)))
        ax1.set_xticklabels(attack_counts.index, rotation=45, ha='right')
        
        # Add value labels on bars
        for bar, value in zip(bars, attack_counts.values):
            ax1.text(bar.get_x() + bar.get_width()/2., bar.get_height() + value*0.01,
                    f'{value:,}', ha='center', va='bottom', fontsize=10)
        
        # Pie chart
        colors_pie = self.colors['attack'][:len(attack_counts)]
        wedges, texts, autotexts = ax2.pie(attack_counts.values, labels=attack_counts.index, 
                                          autopct='%1.1f%%', colors=colors_pie, startangle=90)
        ax2.set_title('Attack Category Proportions', fontsize=14, fontweight='bold')
        
        plt.tight_layout()
        
        # Save the plot
        filename = f"attack_distribution_{self.timestamp}.png"
        filepath = self.output_dir / filename
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        return str(filepath)
    
    def create_protocol_analysis_chart(self, df: pd.DataFrame) -> str:
        """
        Create protocol usage analysis visualization.
        """
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Protocol distribution
        protocol_counts = df['proto'].value_counts()
        ax1.bar(protocol_counts.index, protocol_counts.values, color=self.colors['protocol'])
        ax1.set_title('Protocol Distribution', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Protocol')
        ax1.set_ylabel('Number of Flows')
        
        # Protocol vs Attack Category heatmap
        proto_attack = pd.crosstab(df['proto'], df['attack_cat'])
        sns.heatmap(proto_attack, annot=True, fmt='d', cmap='YlOrRd', ax=ax2)
        ax2.set_title('Protocol vs Attack Category Heatmap', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Attack Category')
        ax2.set_ylabel('Protocol')
        
        # Bytes transferred by protocol
        bytes_by_proto = df.groupby('proto')['total_bytes'].agg(['mean', 'median', 'std'])
        bytes_by_proto.plot(kind='bar', ax=ax3, color=['skyblue', 'orange', 'lightcoral'])
        ax3.set_title('Bytes Transferred by Protocol (Statistics)', fontsize=14, fontweight='bold')
        ax3.set_xlabel('Protocol')
        ax3.set_ylabel('Bytes')
        ax3.legend(['Mean', 'Median', 'Std Dev'])
        ax3.tick_params(axis='x', rotation=0)
        
        # Service distribution
        service_counts = df['service'].value_counts().head(10)
        ax4.barh(range(len(service_counts)), service_counts.values, color=self.colors['normal'])
        ax4.set_title('Top 10 Services', fontsize=14, fontweight='bold')
        ax4.set_xlabel('Number of Flows')
        ax4.set_yticks(range(len(service_counts)))
        ax4.set_yticklabels(service_counts.index)
        
        plt.tight_layout()
        
        # Save the plot
        filename = f"protocol_analysis_{self.timestamp}.png"
        filepath = self.output_dir / filename
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        return str(filepath)
    
    def create_temporal_analysis_chart(self, df: pd.DataFrame) -> str:
        """
        Create temporal analysis of attacks.
        """
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Hourly attack distribution
        hourly_attacks = df[df['label'] == 1].groupby('hour_of_day').size()
        hourly_normal = df[df['label'] == 0].groupby('hour_of_day').size()
        
        hours = range(24)
        width = 0.35
        
        ax1.bar([h - width/2 for h in hours], 
               [hourly_attacks.get(h, 0) for h in hours], 
               width, label='Attacks', color='red', alpha=0.7)
        ax1.bar([h + width/2 for h in hours], 
               [hourly_normal.get(h, 0) for h in hours], 
               width, label='Normal', color='blue', alpha=0.7)
        ax1.set_title('Hourly Distribution: Attacks vs Normal Traffic', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Hour of Day')
        ax1.set_ylabel('Number of Flows')
        ax1.legend()
        ax1.set_xticks(hours[::2])
        
        # Attack intensity by hour (percentage)
        total_by_hour = df.groupby('hour_of_day').size()
        attack_by_hour = df[df['label'] == 1].groupby('hour_of_day').size()
        attack_percentage = (attack_by_hour / total_by_hour * 100).fillna(0)
        
        ax2.plot(attack_percentage.index, attack_percentage.values, 
                marker='o', linewidth=2, markersize=6, color='red')
        ax2.set_title('Attack Intensity by Hour (%)', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Hour of Day')
        ax2.set_ylabel('Attack Percentage')
        ax2.grid(True, alpha=0.3)
        ax2.set_xticks(range(0, 24, 2))
        
        # Duration analysis
        df['log_dur'] = np.log1p(df['dur'])
        df.boxplot(column='log_dur', by='attack_cat', ax=ax3)
        ax3.set_title('Flow Duration Distribution by Attack Category', fontsize=14, fontweight='bold')
        ax3.set_xlabel('Attack Category')
        ax3.set_ylabel('Log(Duration + 1)')
        ax3.tick_params(axis='x', rotation=45)
        
        # Bytes vs Packets scatter
        sample_df = df.sample(n=min(1000, len(df)))  # Sample for performance
        scatter = ax4.scatter(sample_df['total_bytes'], sample_df['total_pkts'], 
                            c=sample_df['label'], alpha=0.6, cmap='coolwarm')
        ax4.set_title('Bytes vs Packets (Sample)', fontsize=14, fontweight='bold')
        ax4.set_xlabel('Total Bytes (log scale)')
        ax4.set_ylabel('Total Packets (log scale)')
        ax4.set_xscale('log')
        ax4.set_yscale('log')
        plt.colorbar(scatter, ax=ax4, label='Label (0=Normal, 1=Attack)')
        
        plt.tight_layout()
        
        # Save the plot
        filename = f"temporal_analysis_{self.timestamp}.png"
        filepath = self.output_dir / filename
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        return str(filepath)
    
    def create_interactive_dashboard(self, df: pd.DataFrame) -> str:
        """
        Create an interactive dashboard using Plotly.
        """
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Attack Category Distribution', 'Protocol vs Service Matrix',
                          'Attack Timing Patterns', 'Flow Size Distribution'),
            specs=[[{"type": "pie"}, {"type": "heatmap"}],
                   [{"type": "scatter"}, {"type": "histogram"}]]
        )
        
        # 1. Attack category pie chart
        attack_counts = df['attack_cat'].value_counts()
        fig.add_trace(
            go.Pie(labels=attack_counts.index, values=attack_counts.values,
                  name="Attack Distribution"),
            row=1, col=1
        )
        
        # 2. Protocol vs Service heatmap
        proto_service = pd.crosstab(df['proto'], df['service'])
        fig.add_trace(
            go.Heatmap(z=proto_service.values,
                      x=proto_service.columns,
                      y=proto_service.index,
                      colorscale='Viridis'),
            row=1, col=2
        )
        
        # 3. Temporal scatter plot
        sample_df = df.sample(n=min(2000, len(df)))
        fig.add_trace(
            go.Scatter(x=sample_df['hour_of_day'],
                      y=sample_df['total_bytes'],
                      mode='markers',
                      marker=dict(color=sample_df['label'],
                                colorscale='RdYlBu',
                                opacity=0.6),
                      name="Flow Timing"),
            row=2, col=1
        )
        
        # 4. Flow size histogram
        fig.add_trace(
            go.Histogram(x=np.log1p(df['total_bytes']),
                        nbinsx=50,
                        name="Log(Bytes)"),
            row=2, col=2
        )
        
        # Update layout
        fig.update_layout(
            title_text="UNSW-NB15 Interactive Analysis Dashboard",
            title_x=0.5,
            height=800,
            showlegend=False
        )
        
        # Save the interactive plot
        filename = f"interactive_dashboard_{self.timestamp}.html"
        filepath = self.output_dir / filename
        fig.write_html(str(filepath))
        
        return str(filepath)
    
    def create_anomaly_detection_viz(self, df: pd.DataFrame) -> str:
        """
        Create anomaly detection visualization.
        """
        # Calculate z-scores for numerical features
        numerical_cols = ['sbytes', 'dbytes', 'dur', 'spkts', 'dpkts']
        df_numeric = df[numerical_cols].fillna(0)
        
        # Calculate z-scores
        z_scores = np.abs((df_numeric - df_numeric.mean()) / df_numeric.std())
        df['anomaly_score'] = z_scores.mean(axis=1)
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Anomaly score distribution
        ax1.hist(df['anomaly_score'], bins=50, alpha=0.7, color='skyblue', edgecolor='black')
        ax1.axvline(df['anomaly_score'].quantile(0.95), color='red', linestyle='--', 
                   label='95th Percentile')
        ax1.set_title('Anomaly Score Distribution', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Anomaly Score')
        ax1.set_ylabel('Frequency')
        ax1.legend()
        
        # Anomaly score vs actual labels
        normal_scores = df[df['label'] == 0]['anomaly_score']
        attack_scores = df[df['label'] == 1]['anomaly_score']
        
        ax2.boxplot([normal_scores, attack_scores], labels=['Normal', 'Attack'])
        ax2.set_title('Anomaly Scores by Actual Labels', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Anomaly Score')
        
        # Feature correlation with anomaly scores
        correlations = []
        for col in numerical_cols:
            corr = df[col].corr(df['anomaly_score'])
            correlations.append(corr)
        
        ax3.bar(numerical_cols, correlations, color=self.colors['severity'])
        ax3.set_title('Feature Correlation with Anomaly Score', fontsize=14, fontweight='bold')
        ax3.set_xlabel('Features')
        ax3.set_ylabel('Correlation')
        ax3.tick_params(axis='x', rotation=45)
        
        # 2D anomaly visualization (using PCA for dimensionality reduction)
        from sklearn.decomposition import PCA
        from sklearn.preprocessing import StandardScaler
        
        # Prepare data for PCA
        scaler = StandardScaler()
        scaled_data = scaler.fit_transform(df_numeric)
        
        pca = PCA(n_components=2)
        pca_result = pca.fit_transform(scaled_data)
        
        # Create scatter plot
        scatter = ax4.scatter(pca_result[:, 0], pca_result[:, 1], 
                            c=df['anomaly_score'], cmap='viridis', alpha=0.6)
        ax4.set_title('2D Anomaly Visualization (PCA)', fontsize=14, fontweight='bold')
        ax4.set_xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.2%} variance)')
        ax4.set_ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.2%} variance)')
        plt.colorbar(scatter, ax=ax4, label='Anomaly Score')
        
        plt.tight_layout()
        
        # Save the plot
        filename = f"anomaly_detection_{self.timestamp}.png"
        filepath = self.output_dir / filename
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        return str(filepath)
    
    def generate_summary_report(self, df: pd.DataFrame) -> str:
        """
        Generate a comprehensive summary report with key statistics.
        """
        report = {
            'generation_time': datetime.now().isoformat(),
            'dataset_info': {
                'total_records': len(df),
                'total_attacks': int(df['label'].sum()),
                'attack_percentage': float(df['label'].mean() * 100),
                'unique_protocols': df['proto'].nunique(),
                'unique_services': df['service'].nunique(),
                'unique_attack_categories': df['attack_cat'].nunique()
            },
            'attack_distribution': df['attack_cat'].value_counts().to_dict(),
            'protocol_distribution': df['proto'].value_counts().to_dict(),
            'service_distribution': df['service'].value_counts().head(10).to_dict(),
            'statistical_summary': {
                'bytes_stats': {
                    'mean_sbytes': float(df['sbytes'].mean()),
                    'mean_dbytes': float(df['dbytes'].mean()),
                    'max_total_bytes': float(df['total_bytes'].max()),
                    'min_total_bytes': float(df['total_bytes'].min())
                },
                'duration_stats': {
                    'mean_duration': float(df['dur'].mean()),
                    'max_duration': float(df['dur'].max()),
                    'duration_std': float(df['dur'].std())
                },
                'packet_stats': {
                    'mean_spkts': float(df['spkts'].mean()),
                    'mean_dpkts': float(df['dpkts'].mean()),
                    'max_total_pkts': float(df['total_pkts'].max())
                }
            }
        }
        
        # Save the report
        filename = f"summary_report_{self.timestamp}.json"
        filepath = self.output_dir / filename
        
        with open(filepath, 'w') as f:
            json.dump(report, f, indent=2)
        
        return str(filepath)
    
    def generate_all_visualizations(self, df: Optional[pd.DataFrame] = None) -> Dict[str, str]:
        """
        Generate all visualization types and return file paths.
        """
        if df is None:
            # Use sample data if no DataFrame provided
            df = self._generate_sample_data()
        
        print("Generating UNSW-NB15 Visualizations...")
        
        results = {}
        
        try:
            print("  → Creating attack distribution chart...")
            results['attack_distribution'] = self.create_attack_distribution_chart(df)
            
            print("  → Creating protocol analysis chart...")
            results['protocol_analysis'] = self.create_protocol_analysis_chart(df)
            
            print("  → Creating temporal analysis chart...")
            results['temporal_analysis'] = self.create_temporal_analysis_chart(df)
            
            print("  → Creating interactive dashboard...")
            results['interactive_dashboard'] = self.create_interactive_dashboard(df)
            
            print("  → Creating anomaly detection visualization...")
            results['anomaly_detection'] = self.create_anomaly_detection_viz(df)
            
            print("  → Generating summary report...")
            results['summary_report'] = self.generate_summary_report(df)
            
            print(f"✓ All visualizations generated successfully!")
            print(f"  Output directory: {self.output_dir}")
            
            return results
            
        except Exception as e:
            print(f"Error generating visualizations: {e}")
            return results


def main():
    """
    Main function to demonstrate visualization generation.
    """
    # Initialize the visualization generator
    viz_gen = UNSWVisualizationGenerator()
    
    # Generate sample data for demonstration
    print("Loading sample UNSW-NB15 data...")
    sample_data = viz_gen._generate_sample_data()
    
    # Generate all visualizations
    results = viz_gen.generate_all_visualizations(sample_data)
    
    # Print results
    print("\nGenerated Files:")
    for viz_type, filepath in results.items():
        print(f"  {viz_type}: {filepath}")
    
    print(f"\nTo use with real Hive data, modify the load_hive_data() method")
    print(f"and connect to your HiveServer2 instance.")


if __name__ == "__main__":
    main()
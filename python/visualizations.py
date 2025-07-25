"""
Visualization Framework for UNSW-NB15 Cybersecurity Analytics
This module provides comprehensive visualization functions for cybersecurity data analysis
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import warnings
from typing import Optional, List, Tuple, Dict, Any
from hive_connection import HiveConnectionManager
import os
from datetime import datetime

# Configure visualization settings
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")
warnings.filterwarnings('ignore')

class CybersecurityVisualizer:
    """
    Comprehensive visualization framework for UNSW-NB15 cybersecurity analytics
    """
    
    def __init__(self, hive_host='localhost', hive_port=10000, output_dir='./reports'):
        """
        Initialize the visualizer
        
        Args:
            hive_host: Hive server hostname
            hive_port: Hive server port
            output_dir: Directory to save visualization outputs
        """
        self.hive_host = hive_host
        self.hive_port = hive_port
        self.output_dir = output_dir
        self.hive_conn = None
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # Configure matplotlib for better quality
        plt.rcParams['figure.dpi'] = 300
        plt.rcParams['savefig.dpi'] = 300
        plt.rcParams['font.size'] = 10
    
    def connect_to_hive(self) -> bool:
        """
        Establish connection to Hive server
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            self.hive_conn = HiveConnectionManager(self.hive_host, self.hive_port)
            return self.hive_conn.connect()
        except Exception as e:
            print(f"Failed to connect to Hive: {str(e)}")
            return False
    
    def plot_attack_distribution(self, save_fig=True, show_plot=True) -> Optional[plt.Figure]:
        """
        Create attack category distribution visualization
        
        Args:
            save_fig: Whether to save the figure
            show_plot: Whether to display the plot
            
        Returns:
            matplotlib Figure object
        """
        if not self.hive_conn:
            print("No Hive connection. Call connect_to_hive() first.")
            return None
        
        # Get attack distribution data
        data = self.hive_conn.get_attack_distribution()
        if data is None or data.empty:
            print("No attack distribution data available")
            return None
        
        # Create figure with subplots
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8))
        
        # Bar chart
        bars = ax1.bar(data['attack_cat'], data['count'], 
                      color=sns.color_palette("husl", len(data)))
        ax1.set_title('Attack Category Distribution', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Attack Category')
        ax1.set_ylabel('Number of Attacks')
        ax1.tick_params(axis='x', rotation=45)
        
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax1.text(bar.get_x() + bar.get_width()/2., height,
                    f'{int(height)}', ha='center', va='bottom')
        
        # Pie chart
        colors = sns.color_palette("husl", len(data))
        wedges, texts, autotexts = ax2.pie(data['count'], labels=data['attack_cat'], 
                                          autopct='%1.1f%%', colors=colors)
        ax2.set_title('Attack Category Percentage Distribution', fontsize=14, fontweight='bold')
        
        plt.tight_layout()
        
        if save_fig:
            filename = f"{self.output_dir}/attack_distribution_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            plt.savefig(filename, bbox_inches='tight')
            print(f"Attack distribution plot saved to {filename}")
        
        if show_plot:
            plt.show()
        
        return fig
    
    def plot_service_vulnerability(self, top_n=15, save_fig=True, show_plot=True) -> Optional[plt.Figure]:
        """
        Create service vulnerability assessment visualization
        
        Args:
            top_n: Number of top services to display
            save_fig: Whether to save the figure
            show_plot: Whether to display the plot
            
        Returns:
            matplotlib Figure object
        """
        if not self.hive_conn:
            print("No Hive connection. Call connect_to_hive() first.")
            return None
        
        data = self.hive_conn.get_service_vulnerability_data()
        if data is None or data.empty:
            print("No service vulnerability data available")
            return None
        
        # Take top N services
        data = data.head(top_n)
        
        # Create figure
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 12))
        
        # Attack rate by service
        service_labels = [f"{row['service']} ({row['proto']})" for _, row in data.iterrows()]
        bars1 = ax1.barh(service_labels, data['attack_rate'], 
                        color=plt.cm.Reds(data['attack_rate']/100))
        ax1.set_title('Service Vulnerability Assessment - Attack Rate (%)', 
                     fontsize=14, fontweight='bold')
        ax1.set_xlabel('Attack Rate (%)')
        
        # Add value labels
        for i, bar in enumerate(bars1):
            width = bar.get_width()
            ax1.text(width + 0.5, bar.get_y() + bar.get_height()/2.,
                    f'{width:.1f}%', ha='left', va='center')
        
        # Total connections by service
        bars2 = ax2.barh(service_labels, data['total_connections'],
                        color=plt.cm.Blues(data['total_connections']/data['total_connections'].max()))
        ax2.set_title('Service Usage - Total Connections', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Total Connections')
        
        # Add value labels
        for i, bar in enumerate(bars2):
            width = bar.get_width()
            ax2.text(width + data['total_connections'].max() * 0.01, 
                    bar.get_y() + bar.get_height()/2.,
                    f'{int(width)}', ha='left', va='center')
        
        plt.tight_layout()
        
        if save_fig:
            filename = f"{self.output_dir}/service_vulnerability_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            plt.savefig(filename, bbox_inches='tight')
            print(f"Service vulnerability plot saved to {filename}")
        
        if show_plot:
            plt.show()
        
        return fig
    
    def plot_protocol_security_heatmap(self, save_fig=True, show_plot=True) -> Optional[plt.Figure]:
        """
        Create protocol security analysis heatmap
        
        Args:
            save_fig: Whether to save the figure
            show_plot: Whether to display the plot
            
        Returns:
            matplotlib Figure object
        """
        if not self.hive_conn:
            print("No Hive connection. Call connect_to_hive() first.")
            return None
        
        data = self.hive_conn.get_protocol_analysis()
        if data is None or data.empty:
            print("No protocol analysis data available")
            return None
        
        # Create correlation matrix for security metrics
        metrics_data = data[['total_flows', 'malicious_flows', 'maliciousness_rate', 
                           'avg_duration', 'avg_total_bytes']].copy()
        
        # Normalize data for better correlation
        metrics_data['total_flows_norm'] = metrics_data['total_flows'] / metrics_data['total_flows'].max()
        metrics_data['malicious_flows_norm'] = metrics_data['malicious_flows'] / metrics_data['malicious_flows'].max()
        metrics_data['avg_total_bytes_norm'] = metrics_data['avg_total_bytes'] / metrics_data['avg_total_bytes'].max()
        
        correlation_matrix = metrics_data[['total_flows_norm', 'malicious_flows_norm', 
                                         'maliciousness_rate', 'avg_duration', 
                                         'avg_total_bytes_norm']].corr()
        
        # Create figure with subplots
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Protocol security heatmap
        protocol_metrics = data.set_index('proto')[['maliciousness_rate', 'avg_duration', 'avg_total_bytes']]
        sns.heatmap(protocol_metrics.T, annot=True, cmap='RdYlBu_r', ax=ax1, fmt='.2f')
        ax1.set_title('Protocol Security Metrics Heatmap', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Protocol')
        ax1.set_ylabel('Security Metrics')
        
        # Correlation heatmap
        sns.heatmap(correlation_matrix, annot=True, cmap='RdBu_r', center=0, ax=ax2,
                   square=True, fmt='.2f')
        ax2.set_title('Security Metrics Correlation Matrix', fontsize=14, fontweight='bold')
        
        plt.tight_layout()
        
        if save_fig:
            filename = f"{self.output_dir}/protocol_security_heatmap_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            plt.savefig(filename, bbox_inches='tight')
            print(f"Protocol security heatmap saved to {filename}")
        
        if show_plot:
            plt.show()
        
        return fig
    
    def plot_temporal_patterns(self, save_fig=True, show_plot=True) -> Optional[plt.Figure]:
        """
        Create temporal attack pattern visualization
        
        Args:
            save_fig: Whether to save the figure
            show_plot: Whether to display the plot
            
        Returns:
            matplotlib Figure object
        """
        if not self.hive_conn:
            print("No Hive connection. Call connect_to_hive() first.")
            return None
        
        data = self.hive_conn.get_temporal_patterns()
        if data is None or data.empty:
            print("No temporal pattern data available")
            return None
        
        # Create figure
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))
        
        # Hourly connection volume
        ax1.plot(data['hour_of_day'], data['total_connections'], 
                marker='o', linewidth=2, markersize=6, color='blue', label='Total Connections')
        ax1.plot(data['hour_of_day'], data['attack_connections'], 
                marker='s', linewidth=2, markersize=6, color='red', label='Attack Connections')
        ax1.set_title('Hourly Traffic Patterns', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Hour of Day')
        ax1.set_ylabel('Number of Connections')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Attack rate by hour
        bars = ax2.bar(data['hour_of_day'], data['attack_rate'], 
                      color=plt.cm.Reds(data['attack_rate']/data['attack_rate'].max()))
        ax2.set_title('Hourly Attack Rate Patterns', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Hour of Day')
        ax2.set_ylabel('Attack Rate (%)')
        ax2.grid(True, alpha=0.3)
        
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            if height > 0:
                ax2.text(bar.get_x() + bar.get_width()/2., height + 0.1,
                        f'{height:.1f}%', ha='center', va='bottom')
        
        plt.tight_layout()
        
        if save_fig:
            filename = f"{self.output_dir}/temporal_patterns_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            plt.savefig(filename, bbox_inches='tight')
            print(f"Temporal patterns plot saved to {filename}")
        
        if show_plot:
            plt.show()
        
        return fig
    
    def create_interactive_dashboard(self, save_html=True) -> Optional[go.Figure]:
        """
        Create interactive dashboard using Plotly
        
        Args:
            save_html: Whether to save the dashboard as HTML
            
        Returns:
            Plotly Figure object
        """
        if not self.hive_conn:
            print("No Hive connection. Call connect_to_hive() first.")
            return None
        
        # Get data
        attack_data = self.hive_conn.get_attack_distribution()
        service_data = self.hive_conn.get_service_vulnerability_data()
        protocol_data = self.hive_conn.get_protocol_analysis()
        temporal_data = self.hive_conn.get_temporal_patterns()
        
        if any(data is None or data.empty for data in [attack_data, service_data, protocol_data, temporal_data]):
            print("Insufficient data for dashboard creation")
            return None
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Attack Distribution', 'Service Vulnerability', 
                          'Protocol Analysis', 'Temporal Patterns'),
            specs=[[{"type": "pie"}, {"type": "bar"}],
                   [{"type": "bar"}, {"type": "scatter"}]]
        )
        
        # Attack distribution pie chart
        fig.add_trace(
            go.Pie(labels=attack_data['attack_cat'], values=attack_data['count'],
                  name="Attack Distribution"),
            row=1, col=1
        )
        
        # Service vulnerability bar chart
        service_labels = [f"{row['service']} ({row['proto']})" for _, row in service_data.head(10).iterrows()]
        fig.add_trace(
            go.Bar(x=service_data.head(10)['attack_rate'], y=service_labels,
                  orientation='h', name="Attack Rate %"),
            row=1, col=2
        )
        
        # Protocol analysis
        fig.add_trace(
            go.Bar(x=protocol_data['proto'], y=protocol_data['maliciousness_rate'],
                  name="Maliciousness Rate %"),
            row=2, col=1
        )
        
        # Temporal patterns
        fig.add_trace(
            go.Scatter(x=temporal_data['hour_of_day'], y=temporal_data['attack_rate'],
                      mode='lines+markers', name="Hourly Attack Rate"),
            row=2, col=2
        )
        
        # Update layout
        fig.update_layout(
            title_text="UNSW-NB15 Cybersecurity Analytics Dashboard",
            title_x=0.5,
            height=800,
            showlegend=False
        )
        
        if save_html:
            filename = f"{self.output_dir}/interactive_dashboard_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
            fig.write_html(filename)
            print(f"Interactive dashboard saved to {filename}")
        
        return fig
    
    def generate_comprehensive_report(self) -> str:
        """
        Generate a comprehensive analysis report with all visualizations
        
        Returns:
            Path to the generated report directory
        """
        print("Generating comprehensive cybersecurity analysis report...")
        
        if not self.connect_to_hive():
            print("Failed to connect to Hive server")
            return ""
        
        # Create timestamped report directory
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_dir = f"{self.output_dir}/report_{timestamp}"
        os.makedirs(report_dir, exist_ok=True)
        
        # Update output directory for this report
        original_output_dir = self.output_dir
        self.output_dir = report_dir
        
        try:
            # Generate all visualizations
            print("Creating attack distribution visualization...")
            self.plot_attack_distribution(show_plot=False)
            
            print("Creating service vulnerability analysis...")
            self.plot_service_vulnerability(show_plot=False)
            
            print("Creating protocol security heatmap...")
            self.plot_protocol_security_heatmap(show_plot=False)
            
            print("Creating temporal pattern analysis...")
            self.plot_temporal_patterns(show_plot=False)
            
            print("Creating interactive dashboard...")
            self.create_interactive_dashboard()
            
            # Generate summary statistics
            self._generate_summary_report(report_dir)
            
            print(f"\n✓ Comprehensive report generated in: {report_dir}")
            print(f"Report includes:")
            print(f"  • Attack distribution analysis")
            print(f"  • Service vulnerability assessment")
            print(f"  • Protocol security heatmaps")
            print(f"  • Temporal pattern analysis")
            print(f"  • Interactive dashboard")
            print(f"  • Summary statistics report")
            
        finally:
            # Restore original output directory
            self.output_dir = original_output_dir
            self.hive_conn.close_connection()
        
        return report_dir
    
    def _generate_summary_report(self, report_dir: str):
        """
        Generate a text summary report with key statistics
        
        Args:
            report_dir: Directory to save the summary report
        """
        summary_file = f"{report_dir}/summary_report.txt"
        
        with open(summary_file, 'w') as f:
            f.write("UNSW-NB15 Cybersecurity Analytics Summary Report\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # Get summary statistics
            if self.hive_conn:
                # Total records
                total_count = self.hive_conn.get_table_count('unsw_nb15_combined')
                if total_count:
                    f.write(f"Total Records Analyzed: {total_count:,}\n\n")
                
                # Attack distribution
                attack_data = self.hive_conn.get_attack_distribution()
                if attack_data is not None and not attack_data.empty:
                    f.write("Attack Category Distribution:\n")
                    f.write("-" * 30 + "\n")
                    for _, row in attack_data.iterrows():
                        f.write(f"{row['attack_cat']}: {row['count']:,} ({row['percentage']:.1f}%)\n")
                    f.write("\n")
                
                # Protocol analysis
                protocol_data = self.hive_conn.get_protocol_analysis()
                if protocol_data is not None and not protocol_data.empty:
                    f.write("Protocol Security Analysis:\n")
                    f.write("-" * 30 + "\n")
                    for _, row in protocol_data.iterrows():
                        f.write(f"{row['proto']}: {row['maliciousness_rate']:.1f}% malicious\n")
                    f.write("\n")
            
            f.write("Report Components:\n")
            f.write("-" * 20 + "\n")
            f.write("• attack_distribution_*.png - Attack category analysis\n")
            f.write("• service_vulnerability_*.png - Service security assessment\n")
            f.write("• protocol_security_heatmap_*.png - Protocol analysis\n")
            f.write("• temporal_patterns_*.png - Time-based attack patterns\n")
            f.write("• interactive_dashboard_*.html - Interactive web dashboard\n")
        
        print(f"Summary report saved to {summary_file}")

def main():
    """
    Main function to demonstrate visualization capabilities
    """
    print("UNSW-NB15 Cybersecurity Visualization Framework")
    print("=" * 50)
    
    # Initialize visualizer
    visualizer = CybersecurityVisualizer()
    
    # Generate comprehensive report
    report_path = visualizer.generate_comprehensive_report()
    
    if report_path:
        print(f"\nAll visualizations and reports are available in: {report_path}")
    else:
        print("Failed to generate report. Please check Hive connection.")

if __name__ == "__main__":
    main()
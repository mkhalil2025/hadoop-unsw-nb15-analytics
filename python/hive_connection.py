"""
Hive Connection Manager for UNSW-NB15 Analytics
This module provides connection management and query execution for Hive database
"""

import pandas as pd
from pyhive import hive
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
import logging
import time
from typing import Optional, Dict, Any

class HiveConnectionManager:
    """
    Manages connections to Hive server and executes queries for UNSW-NB15 analysis
    """
    
    def __init__(self, host='localhost', port=10000, username='root', database='cybersecurity_analytics'):
        """
        Initialize Hive connection manager
        
        Args:
            host: Hive server hostname
            port: Hive server port
            username: Username for connection
            database: Database name to use
        """
        self.host = host
        self.port = port
        self.username = username
        self.database = database
        self.connection = None
        self.cursor = None
        
        # Configure logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def connect(self, max_retries=5, retry_delay=10) -> bool:
        """
        Establish connection to Hive server with retry logic
        
        Args:
            max_retries: Maximum number of connection attempts
            retry_delay: Delay between retry attempts in seconds
            
        Returns:
            True if connection successful, False otherwise
        """
        for attempt in range(max_retries):
            try:
                self.logger.info(f"Attempting to connect to Hive server (attempt {attempt + 1}/{max_retries})")
                
                self.connection = hive.Connection(
                    host=self.host,
                    port=self.port,
                    username=self.username,
                    database=self.database
                )
                
                self.cursor = self.connection.cursor()
                
                # Test connection
                self.cursor.execute("SELECT 1")
                result = self.cursor.fetchone()
                
                if result:
                    self.logger.info("Successfully connected to Hive server")
                    return True
                    
            except Exception as e:
                self.logger.warning(f"Connection attempt {attempt + 1} failed: {str(e)}")
                if attempt < max_retries - 1:
                    self.logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    self.logger.error("All connection attempts failed")
                    return False
        
        return False
    
    def execute_query(self, query: str, fetch_results=True) -> Optional[pd.DataFrame]:
        """
        Execute a Hive query and return results as DataFrame
        
        Args:
            query: SQL query to execute
            fetch_results: Whether to fetch and return results
            
        Returns:
            DataFrame with query results or None if error
        """
        if not self.cursor:
            self.logger.error("No active connection. Call connect() first.")
            return None
        
        try:
            self.logger.info(f"Executing query: {query[:100]}...")
            
            self.cursor.execute(query)
            
            if fetch_results:
                # Get column names
                columns = [desc[0] for desc in self.cursor.description] if self.cursor.description else []
                
                # Fetch all results
                results = self.cursor.fetchall()
                
                # Create DataFrame
                if results and columns:
                    df = pd.DataFrame(results, columns=columns)
                    self.logger.info(f"Query executed successfully. Retrieved {len(df)} rows.")
                    return df
                else:
                    self.logger.info("Query executed successfully but returned no results.")
                    return pd.DataFrame()
            else:
                self.logger.info("Query executed successfully (no results fetched).")
                return None
                
        except Exception as e:
            self.logger.error(f"Error executing query: {str(e)}")
            return None
    
    def get_table_info(self, table_name: str) -> Optional[pd.DataFrame]:
        """
        Get information about a table structure
        
        Args:
            table_name: Name of the table to describe
            
        Returns:
            DataFrame with table structure information
        """
        query = f"DESCRIBE {table_name}"
        return self.execute_query(query)
    
    def get_table_count(self, table_name: str) -> Optional[int]:
        """
        Get row count for a table
        
        Args:
            table_name: Name of the table
            
        Returns:
            Number of rows in the table
        """
        query = f"SELECT COUNT(*) FROM {table_name}"
        result = self.execute_query(query)
        
        if result is not None and not result.empty:
            return result.iloc[0, 0]
        return None
    
    def get_attack_distribution(self) -> Optional[pd.DataFrame]:
        """
        Get attack category distribution from the dataset
        
        Returns:
            DataFrame with attack category counts
        """
        query = """
        SELECT 
            attack_cat,
            COUNT(*) as count,
            ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2) as percentage
        FROM unsw_nb15_combined 
        WHERE attack_cat IS NOT NULL
        GROUP BY attack_cat 
        ORDER BY count DESC
        """
        return self.execute_query(query)
    
    def get_service_vulnerability_data(self) -> Optional[pd.DataFrame]:
        """
        Get service vulnerability analysis data
        
        Returns:
            DataFrame with service vulnerability metrics
        """
        query = """
        SELECT 
            service,
            proto,
            COUNT(*) as total_connections,
            SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_connections,
            ROUND((SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) as attack_rate
        FROM unsw_nb15_combined
        WHERE service != '-' AND service IS NOT NULL
        GROUP BY service, proto
        HAVING COUNT(*) >= 10
        ORDER BY attack_rate DESC
        LIMIT 20
        """
        return self.execute_query(query)
    
    def get_protocol_analysis(self) -> Optional[pd.DataFrame]:
        """
        Get protocol security analysis data
        
        Returns:
            DataFrame with protocol analysis metrics
        """
        query = """
        SELECT 
            proto,
            COUNT(*) as total_flows,
            SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as malicious_flows,
            ROUND((SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) as maliciousness_rate,
            ROUND(AVG(dur), 4) as avg_duration,
            ROUND(AVG(sbytes + dbytes), 2) as avg_total_bytes
        FROM unsw_nb15_combined
        GROUP BY proto
        ORDER BY maliciousness_rate DESC
        """
        return self.execute_query(query)
    
    def get_temporal_patterns(self) -> Optional[pd.DataFrame]:
        """
        Get temporal attack patterns
        
        Returns:
            DataFrame with temporal analysis data
        """
        query = """
        SELECT 
            FROM_UNIXTIME(stime, 'HH') as hour_of_day,
            COUNT(*) as total_connections,
            SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_connections,
            ROUND((SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) as attack_rate
        FROM unsw_nb15_combined
        WHERE stime > 0
        GROUP BY FROM_UNIXTIME(stime, 'HH')
        ORDER BY hour_of_day
        """
        return self.execute_query(query)
    
    def close_connection(self):
        """
        Close the Hive connection
        """
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        self.logger.info("Connection closed")
    
    def __enter__(self):
        """Context manager entry"""
        if self.connect():
            return self
        else:
            raise ConnectionError("Failed to connect to Hive server")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close_connection()

# Utility functions for query execution
def execute_hive_query(query: str, host='localhost', port=10000) -> Optional[pd.DataFrame]:
    """
    Utility function to execute a single Hive query
    
    Args:
        query: SQL query to execute
        host: Hive server hostname
        port: Hive server port
        
    Returns:
        DataFrame with query results
    """
    try:
        with HiveConnectionManager(host=host, port=port) as hive_conn:
            return hive_conn.execute_query(query)
    except Exception as e:
        logging.error(f"Error executing query: {str(e)}")
        return None

def test_connection(host='localhost', port=10000) -> bool:
    """
    Test connection to Hive server
    
    Args:
        host: Hive server hostname
        port: Hive server port
        
    Returns:
        True if connection successful, False otherwise
    """
    try:
        with HiveConnectionManager(host=host, port=port) as hive_conn:
            result = hive_conn.execute_query("SELECT 1")
            return result is not None
    except Exception:
        return False

if __name__ == "__main__":
    # Test the connection
    print("Testing Hive connection...")
    
    if test_connection():
        print("✓ Connection successful!")
        
        # Test basic queries
        with HiveConnectionManager() as hive_conn:
            # Show tables
            tables = hive_conn.execute_query("SHOW TABLES")
            if tables is not None:
                print("\nAvailable tables:")
                print(tables)
            
            # Get attack distribution
            attack_dist = hive_conn.get_attack_distribution()
            if attack_dist is not None:
                print("\nAttack distribution:")
                print(attack_dist)
    else:
        print("✗ Connection failed. Make sure Hive server is running.")
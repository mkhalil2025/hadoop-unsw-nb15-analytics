# UNSW-NB15 Data Loading Guide

## Enhanced Implementation for 3 Specific CSV Files

This enhanced implementation loads the 3 required UNSW-NB15 dataset files into Hadoop/Hive for SQL querying:

1. **UNSW-NB15.csv** - Main 600MB network traffic dataset (49 features)
2. **UNSW-NB15_features.csv** - Feature descriptions and metadata  
3. **UNSW-NB15_LIST_EVENTS.csv** - Attack category event statistics

## Quick Start

### 1. Start the Environment
```bash
docker-compose up -d
```

### 2. Load the Data
```bash
./scripts/load_data.sh
```

### 3. Verify Success Criteria
```bash
# Connect to Hive and run these queries:
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'

# In Hive, run:
SHOW TABLES;
SELECT COUNT(*) FROM unsw_nb15_main;
SELECT * FROM unsw_nb15_features LIMIT 10;
SELECT * FROM unsw_nb15_events LIMIT 10;
```

## What's Enhanced

### Updated Hive Schema (`hive/create_tables.sql`)
- **unsw_nb15_main**: Main network flow data (49 features) from UNSW-NB15.csv
- **unsw_nb15_features**: Feature descriptions from UNSW-NB15_features.csv
- **unsw_nb15_events**: Attack statistics from UNSW-NB15_LIST_EVENTS.csv

### Enhanced Load Script (`scripts/load_data.sh`)
- Specifically handles the 3 required CSV files
- Creates sample data if original files aren't available (for testing)
- Validates all required files before loading
- Simple error handling and validation
- Tests success criteria automatically

### Sample Data Files
If the original UNSW-NB15 files are not available, the script automatically creates realistic sample data:
- **UNSW-NB15.csv**: 2000 sample network flow records with realistic attack patterns
- **UNSW-NB15_features.csv**: Complete 49-feature metadata descriptions
- **UNSW-NB15_LIST_EVENTS.csv**: Attack category statistics

## File Structure

```
data/
├── UNSW-NB15.csv              # Main network flow dataset (sample provided)
├── UNSW-NB15_features.csv     # Feature descriptions (provided)
├── UNSW-NB15_LIST_EVENTS.csv  # Attack event statistics (provided)
└── README.md                  # Data directory documentation

scripts/
├── load_data.sh               # Enhanced loading script
└── validate_setup.sh          # Validation and testing script

hive/
├── create_tables.sql          # Updated DDL with 3 tables
└── analytical_queries.sql     # Advanced analytical queries
```

## Usage Options

### Full Pipeline (Default)
```bash
./scripts/load_data.sh
```

### Individual Steps
```bash
# Check files only
./scripts/load_data.sh check

# Load to HDFS only  
./scripts/load_data.sh hdfs

# Create Hive tables and load data
./scripts/load_data.sh hive

# Validate loaded data
./scripts/load_data.sh validate
```

### Validation
```bash
./scripts/validate_setup.sh
```

## Success Criteria

After running the script, you can execute these SQL queries:

```sql
-- Test 1: Show all tables
SHOW TABLES;
-- Expected: unsw_nb15_main, unsw_nb15_features, unsw_nb15_events

-- Test 2: Count main records
SELECT COUNT(*) FROM unsw_nb15_main;
-- Expected: Number of network flow records loaded

-- Test 3: Sample features
SELECT * FROM unsw_nb15_features LIMIT 10;
-- Expected: Feature name, type, description for first 10 features

-- Test 4: Sample events  
SELECT * FROM unsw_nb15_events LIMIT 10;
-- Expected: Event statistics with attack categories
```

## Data Schema Details

### unsw_nb15_main (Main Dataset)
49-feature network flow records with:
- **Network identifiers**: srcip, sport, dstip, dsport, proto, state
- **Traffic statistics**: sbytes, dbytes, sttl, dttl, spkts, dpkts  
- **Timing features**: dur, stime, ltime, sjit, djit
- **Attack classification**: attack_cat, label

### unsw_nb15_features (Metadata)
- **name**: Feature name (e.g., 'srcip', 'sport')
- **type**: Data type (nominal, integer, float, binary, timestamp)
- **description**: Detailed feature description

### unsw_nb15_events (Statistics)
- **event_id**: Unique identifier
- **event_type**: Type of network event
- **attack_category**: Attack category name
- **event_count**: Number of events in dataset
- **event_description**: Detailed description

## Web Interfaces

- **Hadoop NameNode**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088  
- **Hive Server2**: http://localhost:10002
- **Jupyter Lab**: http://localhost:8888

## Troubleshooting

### Missing Files
If original UNSW-NB15 files are not available:
- The script automatically creates sample data
- Sample data has realistic patterns for testing
- Replace with original files for production analysis

### Container Issues
```bash
# Check container status
docker ps

# Restart environment
docker-compose down
docker-compose up -d
```

### Hive Connection Issues
```bash
# Wait for services to start (can take 2-3 minutes)
./scripts/validate_setup.sh

# Check Hive logs
docker logs hiveserver2
```

## Compatible With

- Docker Compose environment 
- Hadoop 3.2.1
- Hive 2.3.2
- HiveServer2 (port 10000)
- Jupyter PySpark notebooks

The implementation is simple, focused, and gets data queryable quickly as requested.
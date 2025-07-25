# UNSW-NB15 Hadoop Analytics Environment Setup Guide
## UEL-CN-7031 Big Data Analytics Assignment

This guide provides step-by-step instructions for setting up and using the complete Hadoop-based big data analytics environment for analyzing the UNSW-NB15 cybersecurity dataset.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Accessing Services](#accessing-services)
6. [Loading Data](#loading-data)
7. [Running Analytics](#running-analytics)
8. [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Software
- **Docker Desktop** (version 4.0+)
  - Windows: Download from [docker.com](https://www.docker.com/products/docker-desktop/)
  - macOS: Download from [docker.com](https://www.docker.com/products/docker-desktop/)
  - Linux: Install via package manager or [docs.docker.com](https://docs.docker.com/engine/install/)

- **Docker Compose** (usually included with Docker Desktop)
- **Git** for cloning the repository

### Optional Tools
- **Web browser** (Chrome, Firefox, Safari, or Edge)
- **Text editor** (VS Code, Sublime Text, or similar)

## 💻 System Requirements

### Minimum Requirements
- **RAM**: 8GB (12GB+ recommended)
- **Storage**: 15GB free disk space
- **CPU**: 4 cores (Intel/AMD x64 or Apple Silicon)
- **OS**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+)

### Recommended Configuration
- **RAM**: 16GB or more
- **Storage**: 25GB+ free SSD space
- **CPU**: 8+ cores
- **Network**: Stable internet connection for initial setup

### Port Requirements
The following ports must be available:
- `5432` - PostgreSQL Metastore
- `8020` - Hadoop Namenode RPC
- `8088` - YARN ResourceManager
- `9870` - Hadoop Namenode Web UI
- `9864` - Hadoop Datanode Web UI
- `10000` - Hive Server2 Thrift
- `10002` - Hive Server2 Web UI
- `8888` - Jupyter Lab

## 🚀 Quick Start

### Option 1: One-Command Setup (Recommended)
```bash
# Clone the repository
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics

# Run the automated setup script
./scripts/setup_environment.sh
```

This script will:
- Check system requirements
- Pull Docker images
- Start all services
- Load sample data
- Display access information

### Option 2: Manual Setup
```bash
# Clone and navigate
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics

# Start services
docker-compose up -d

# Wait for services to start (2-3 minutes)
# Load sample data
./scripts/load_data.sh
```

## 📝 Detailed Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics
```

### Step 2: Configure Environment (Optional)
The `.env` file contains optimized settings for student laptops. You can adjust memory settings if needed:

```bash
# Edit environment variables
nano .env

# Key settings to adjust based on your system:
YARN_NODEMANAGER_RESOURCE_MEMORY_MB=4096    # Adjust based on available RAM
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=4096    # Should match above
```

### Step 3: Start the Environment
```bash
# Start all services in background
docker-compose up -d

# Check service status
docker-compose ps

# View logs (optional)
docker-compose logs -f
```

### Step 4: Wait for Services
Services take 2-5 minutes to fully initialize. You can monitor progress:

```bash
# Check Hadoop Namenode
curl http://localhost:9870

# Check Hive Server2 (this may take longer)
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"
```

### Step 5: Load Sample Data
```bash
# Load UNSW-NB15 sample data
./scripts/load_data.sh

# Or load specific components
./scripts/load_data.sh download  # Download/generate data only
./scripts/load_data.sh hdfs      # Load to HDFS only
./scripts/load_data.sh hive      # Create Hive tables only
```

## 🌐 Accessing Services

Once setup is complete, access the services via web browser:

### Web Interfaces
| Service | URL | Description |
|---------|-----|-------------|
| **Jupyter Lab** | http://localhost:8888 | Python analytics environment |
| **Hadoop Namenode** | http://localhost:9870 | HDFS file system management |
| **YARN ResourceManager** | http://localhost:8088 | Job monitoring and resource management |
| **Hive Server2** | http://localhost:10002 | Hive query interface |

### Command Line Access
```bash
# Hive CLI
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'

# Hadoop HDFS commands
docker exec -it namenode hadoop fs -ls /

# Check YARN applications
docker exec -it resourcemanager yarn application -list

# Access container shells
docker exec -it jupyter-analytics bash
docker exec -it namenode bash
```

## 📊 Loading Data

### Using Real UNSW-NB15 Dataset

1. **Download the dataset**:
   - Visit: https://research.unsw.edu.au/projects/unsw-nb15-dataset
   - Download CSV files (training and testing sets)
   - Place files in the `data/` directory

2. **Load the data**:
   ```bash
   # Place your CSV files in data/ directory
   cp /path/to/UNSW_NB15_training-set.csv data/
   cp /path/to/UNSW_NB15_testing-set.csv data/
   
   # Load data into Hadoop
   ./scripts/load_data.sh
   ```

### Using Sample Data (Default)
The system generates realistic sample data automatically if the original dataset is not available.

### Data Validation
```bash
# Validate loaded data
./scripts/load_data.sh validate

# Check data in Hive
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "
USE unsw_nb15;
SELECT COUNT(*) as total_records FROM network_flows;
SELECT attack_cat, COUNT(*) as count FROM network_flows GROUP BY attack_cat;
"
```

## 🔍 Running Analytics

### 1. Jupyter Notebooks
Access Jupyter Lab at http://localhost:8888

**Available notebooks**:
- `data_exploration.ipynb` - Comprehensive dataset analysis
- Create your own notebooks for custom analysis

**Key features**:
- Pre-configured Hive connectivity
- Complete visualization suite
- Statistical analysis tools
- Machine learning capabilities

### 2. HiveQL Queries
Execute the advanced analytical queries:

```bash
# Connect to Hive
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'

# In Hive, run the analytical queries
USE unsw_nb15;
SOURCE /opt/hive/scripts/analytical_queries.sql;
```

**Available queries**:
- **Query 1**: Attack pattern analysis by protocol and service
- **Query 2**: Geographic analysis with time-based aggregations  
- **Query 3**: Anomaly detection using statistical functions
- **Query 4**: Multi-dimensional analysis with window functions

### 3. Python Visualizations
Generate automated visualizations:

```bash
# Access Jupyter container
docker exec -it jupyter-analytics bash

# Run visualization generator
cd /home/jovyan/python
python visualizations.py
```

### 4. Custom Analysis
Create your own analysis by:
- Writing new Jupyter notebooks
- Developing custom HiveQL queries
- Extending the Python visualization library
- Building new data processing pipelines

## 🎯 Assignment Guidelines

### For UEL-CN-7031 Students

This environment provides everything needed for your Big Data Analytics assignment:

#### **Core Requirements Covered**:
1. **Hadoop HDFS**: Store and manage large datasets
2. **Hive Data Warehousing**: SQL-like queries on big data
3. **Complex Analytics**: Advanced aggregations and window functions
4. **Data Visualization**: Professional charts and interactive dashboards
5. **Documentation**: Complete project documentation

#### **Suggested Assignment Structure**:

1. **Introduction** (10%)
   - Explain the UNSW-NB15 dataset
   - Describe the big data tools used
   - Outline your analysis approach

2. **Data Loading and Preparation** (15%)
   - Document data loading process
   - Describe schema design decisions
   - Show data quality assessment

3. **Analytical Queries** (40%)
   - Execute and explain the 4 provided queries
   - Develop 2+ additional custom queries
   - Analyze query performance and optimization

4. **Visualization and Insights** (25%)
   - Generate comprehensive visualizations
   - Interpret patterns and trends
   - Discuss cybersecurity implications

5. **Conclusion and Recommendations** (10%)
   - Summarize key findings
   - Suggest improvements or extensions
   - Reflect on learning outcomes

#### **Deliverables**:
- **Report**: PDF document with analysis and screenshots
- **Code**: Jupyter notebooks with your analysis
- **Queries**: Custom HiveQL queries you developed
- **Visualizations**: Charts and dashboards generated

#### **Evaluation Criteria**:
- Technical proficiency with Hadoop ecosystem
- Quality and complexity of analytical queries
- Clarity and insight of visualizations
- Understanding of big data concepts
- Documentation and presentation quality

## 🔧 Management Commands

### Service Management
```bash
# Start all services
./scripts/setup_environment.sh start

# Stop all services
./scripts/setup_environment.sh stop

# Restart services
./scripts/setup_environment.sh restart

# Check service status
./scripts/setup_environment.sh status

# View service logs
./scripts/setup_environment.sh logs
```

### Data Management
```bash
# Reload data
./scripts/load_data.sh

# Download new dataset
./scripts/load_data.sh download

# Validate data integrity
./scripts/load_data.sh validate
```

### System Cleanup
```bash
# Remove all containers and data (WARNING: Destructive)
./scripts/setup_environment.sh clean

# Remove only containers (keep volumes)
docker-compose down

# Remove everything including volumes
docker-compose down -v
```

## 📁 Directory Structure

```
hadoop-unsw-nb15-analytics/
├── config/                 # Hadoop configuration files
│   ├── core-site.xml       # Core Hadoop settings
│   ├── hdfs-site.xml       # HDFS configuration
│   ├── yarn-site.xml       # YARN resource manager settings
│   └── mapred-site.xml     # MapReduce configuration
├── data/                   # Dataset storage
│   └── README.md           # Data loading instructions
├── docs/                   # Documentation
│   ├── setup_guide.md      # This file
│   ├── query_explanations.md
│   ├── troubleshooting.md
│   └── assignment_guidelines.md
├── hive/                   # Hive SQL scripts
│   ├── create_tables.sql   # Database schema
│   └── analytical_queries.sql # Advanced analytics queries
├── notebooks/              # Jupyter notebooks
│   └── data_exploration.ipynb # Main analysis notebook
├── output/                 # Results and logs
│   ├── logs/               # System logs
│   ├── results/            # Query results
│   └── visualizations/     # Generated charts
├── python/                 # Python analytics modules
│   └── visualizations.py   # Automated visualization generator
├── scripts/                # Automation scripts
│   ├── setup_environment.sh # Main setup script
│   └── load_data.sh        # Data loading script
├── docker-compose.yml      # Service orchestration
├── .env                    # Environment variables
├── requirements.txt        # Python dependencies
└── README.md              # Project overview
```

## 🎉 Next Steps

After successful setup:

1. **Explore the data**: Open http://localhost:8888 and run `data_exploration.ipynb`
2. **Run queries**: Execute the analytical queries in Hive
3. **Generate visualizations**: Use the Python visualization tools
4. **Develop custom analysis**: Create your own notebooks and queries
5. **Complete assignment**: Follow the assignment guidelines

## 📚 Additional Resources

- **UNSW-NB15 Dataset**: https://research.unsw.edu.au/projects/unsw-nb15-dataset
- **Apache Hadoop Documentation**: https://hadoop.apache.org/docs/
- **Apache Hive Documentation**: https://hive.apache.org/documentation.html
- **Docker Documentation**: https://docs.docker.com/
- **Jupyter Lab Documentation**: https://jupyterlab.readthedocs.io/

## 🆘 Need Help?

1. **Check the troubleshooting guide**: `docs/troubleshooting.md`
2. **View logs**: `docker-compose logs [service-name]`
3. **Check service status**: `docker-compose ps`
4. **Restart services**: `docker-compose restart`
5. **Full reset**: `./scripts/setup_environment.sh clean && ./scripts/setup_environment.sh`

---

**Happy Analytics!** 🎯📊

*This environment provides a complete, production-ready big data analytics platform optimized for educational use and cybersecurity research.*
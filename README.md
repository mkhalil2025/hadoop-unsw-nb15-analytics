# Big Data Analytics Environment for UEL-CN-7031 Coursework

## UNSW-NB15 Cybersecurity Dataset Analysis with Hadoop, Hive, and Python

A comprehensive Big Data Analytics environment designed for analyzing the UNSW-NB15 cybersecurity dataset using modern big data tools and techniques. This project provides everything needed to complete the UEL-CN-7031 Big Data Analytics coursework from initial setup through final report submission.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com)
[![Hadoop](https://img.shields.io/badge/Hadoop-3.2.1-yellow.svg)](https://hadoop.apache.org)
[![Hive](https://img.shields.io/badge/Hive-2.3.2-orange.svg)](https://hive.apache.org)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)

## 🎯 Project Overview

This environment enables comprehensive cybersecurity data analysis through:

- **Docker-based Hadoop Cluster**: Complete ecosystem with Namenode, Datanode, ResourceManager, NodeManager, and HistoryServer
- **Hive Data Warehouse**: PostgreSQL-backed metastore for structured analytics
- **Python Analytics Framework**: Jupyter-based environment with visualization tools
- **UNSW-NB15 Dataset Integration**: 2.5M+ network flow records with 49 features
- **Complex Query Library**: 5+ advanced analytical queries for cybersecurity insights
- **Interactive Visualizations**: Professional charts and dashboards for report generation

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** (20.0+)
- **8GB+ RAM** (16GB recommended)
- **10GB+ free disk space**
- **Linux/macOS/Windows with WSL2**

### 1. Clone and Setup

```bash
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics

# Run automated setup (pulls images, starts cluster, configures services)
./setup/setup.sh
```

### 2. Load Dataset

```bash
# Load UNSW-NB15 data into HDFS and create Hive tables
./setup/data_loader.sh
```

### 3. Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| 🌐 Hadoop Namenode | http://localhost:9870 | HDFS management |
| 📊 YARN ResourceManager | http://localhost:8088 | Job monitoring |
| 🔍 Hive Server | jdbc:hive2://localhost:10000 | SQL analytics |
| 📓 Jupyter Notebook | http://localhost:8888 | Python analysis |

## 📁 Project Structure

```
hadoop-unsw-nb15-analytics/
├── 📄 README.md                    # This file
├── 🐳 docker-compose.yml           # Hadoop cluster definition
├── ⚙️  hadoop.env                  # Environment configuration
├── 🔧 setup/
│   ├── setup.sh                   # Automated cluster setup
│   └── data_loader.sh             # HDFS data loading
├── 🗃️  hive/
│   ├── create_tables.hql          # Database and table creation
│   └── complex_queries.hql        # Assignment analytical queries
├── 🐍 python/
│   ├── requirements.txt           # Python dependencies
│   ├── hive_connection.py         # Database connectivity
│   └── visualizations.py         # Chart generation framework
├── 📚 docs/
│   ├── setup_guide.md            # Detailed installation guide
│   ├── assignment_guide.md       # Coursework completion steps
│   └── troubleshooting.md        # Issue resolution guide
└── 📊 data/
    └── README.md                  # Dataset information and instructions
```

## 🔬 Analytics Capabilities

### Complex Query Examples

1. **Attack Distribution Analysis**
   ```sql
   -- Multi-dimensional attack pattern analysis with temporal insights
   SELECT attack_cat, COUNT(*), AVG(dur), PERCENTILE_APPROX(dur, 0.95)
   FROM unsw_nb15_combined 
   WHERE label = 1 
   GROUP BY attack_cat 
   ORDER BY COUNT(*) DESC;
   ```

2. **Service Vulnerability Assessment**
   ```sql
   -- Risk analysis by service and protocol
   WITH service_stats AS (
       SELECT service, proto,
              COUNT(*) as total,
              SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attacks,
              ROW_NUMBER() OVER (ORDER BY attack_rate DESC) as risk_rank
   )...
   ```

3. **Temporal Pattern Investigation**
   ```sql
   -- Window functions for traffic anomaly detection
   SELECT hour_timestamp,
          connection_count,
          AVG(connection_count) OVER (
              ORDER BY hour_timestamp 
              ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
          ) as moving_avg
   FROM hourly_traffic...
   ```

### Visualization Framework

```python
from visualizations import CybersecurityVisualizer

# Initialize visualizer
visualizer = CybersecurityVisualizer()
visualizer.connect_to_hive()

# Generate comprehensive report
report_path = visualizer.generate_comprehensive_report()

# Individual visualizations
visualizer.plot_attack_distribution()
visualizer.plot_service_vulnerability()
visualizer.plot_protocol_security_heatmap()
visualizer.create_interactive_dashboard()
```

## 🎓 Assignment Completion

### Phase 1: Environment Setup (20 minutes)
- [x] Docker cluster deployment
- [x] Service health verification
- [x] Data loading validation
- [x] Hive table creation

### Phase 2: Query Development (60 minutes)
- [x] Attack distribution temporal analysis
- [x] Service vulnerability assessment
- [x] Traffic pattern investigation
- [x] Protocol security evaluation
- [x] Statistical anomaly detection

### Phase 3: Visualization (45 minutes)
- [x] Python environment setup
- [x] Hive connectivity testing
- [x] Chart generation
- [x] Interactive dashboard creation

### Phase 4: Report Generation (30 minutes)
- [x] Automated report compilation
- [x] Professional formatting
- [x] Insight documentation
- [x] Recommendation development

## 📊 Dataset Information

### UNSW-NB15 Cybersecurity Dataset
- **Records**: 2.5M+ network flows
- **Features**: 49 network and statistical features
- **Attacks**: 9 categories (Fuzzers, Analysis, Backdoors, DoS, Exploits, Generic, Reconnaissance, Shellcode, Worms)
- **Classification**: Binary (Normal vs Attack)
- **Size**: ~600MB CSV format

### Key Features
- **Flow Features**: IP addresses, ports, protocols, states
- **Content Features**: Bytes, packets, time-to-live values
- **Traffic Features**: Load rates, window sizes, jitter
- **Generated Features**: Connection counts, statistical aggregations

## 🛠️ Technical Architecture

### Hadoop Ecosystem
- **Namenode**: Metadata management and namespace
- **Datanode**: Distributed data storage
- **ResourceManager**: YARN resource allocation
- **NodeManager**: Container lifecycle management
- **HistoryServer**: Job history tracking

### Hive Data Warehouse
- **PostgreSQL Metastore**: Schema and metadata storage
- **HiveServer2**: JDBC/ODBC connectivity
- **Query Engine**: SQL-to-MapReduce translation
- **Partitioned Tables**: Performance optimization

### Python Analytics Stack
- **Jupyter**: Interactive analysis environment
- **pandas**: Data manipulation and analysis
- **matplotlib/seaborn**: Statistical visualizations
- **plotly**: Interactive dashboards
- **pyhive**: Hive connectivity

## 🔧 Configuration and Optimization

### Memory Optimization
```bash
# For 4GB systems, adjust hadoop.env:
YARN_CONF_yarn_nodemanager_resource_memory___mb=1024
MAPRED_CONF_mapreduce_map_memory_mb=256
MAPRED_CONF_mapreduce_reduce_memory_mb=512
```

### Query Performance
```sql
-- Enable optimization features
SET hive.exec.dynamic.partition = true;
SET hive.vectorized.execution.enabled = true;
SET hive.optimize.cp = true;
```

### Data Processing
```sql
-- Use partitioned tables for large datasets
CREATE TABLE unsw_nb15_partitioned (...)
PARTITIONED BY (attack_cat STRING, label INT)
STORED AS PARQUET;
```

## 📈 Success Metrics

### Technical Validation
- ✅ All Docker services running successfully
- ✅ HDFS data loading without errors
- ✅ Hive queries executing and returning results
- ✅ Python visualizations generating charts
- ✅ Interactive dashboard functioning

### Academic Requirements
- ✅ Complex SQL features implemented (window functions, CTEs, advanced aggregations)
- ✅ Statistical analysis and pattern detection
- ✅ Professional visualizations with insights
- ✅ Comprehensive report with recommendations
- ✅ Code documentation and reproducibility

## 🎯 Learning Outcomes

By completing this project, students will:

1. **Big Data Infrastructure**: Deploy and manage distributed Hadoop clusters
2. **SQL Analytics**: Write complex queries for large-scale data analysis
3. **Cybersecurity Domain**: Understand network traffic analysis and threat detection
4. **Data Visualization**: Create professional charts and interactive dashboards
5. **Report Writing**: Produce industry-standard analytical reports

## 🆘 Support and Troubleshooting

### Common Issues
- **Port Conflicts**: Modify ports in `docker-compose.yml`
- **Memory Issues**: Reduce allocation in `hadoop.env`
- **Startup Problems**: Check Docker service status
- **Query Failures**: Verify Hive connectivity and data loading

### Getting Help
1. 📖 **Documentation**: Check `docs/` directory for detailed guides
2. 🔍 **Logs**: Use `docker-compose logs [service]` for debugging
3. 🔧 **Troubleshooting**: Follow `docs/troubleshooting.md`
4. 💬 **Support**: Contact course instructors for academic assistance

## 🤝 Contributing

This project is designed for educational purposes. To contribute:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with improvements
4. Follow code style and documentation standards

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **UNSW Australian Centre for Cyber Security**: UNSW-NB15 dataset
- **Apache Software Foundation**: Hadoop, Hive, and ecosystem tools
- **Docker Community**: Containerization platform
- **Python Data Science Community**: Analytics and visualization libraries

## 📚 References

1. Moustafa, N., & Slay, J. (2015). UNSW-NB15: a comprehensive data set for network intrusion detection systems. *MilCIS 2015*.
2. Apache Hadoop Documentation: https://hadoop.apache.org/docs/
3. Apache Hive Documentation: https://hive.apache.org/
4. Docker Documentation: https://docs.docker.com/

---

**Ready to start your Big Data Analytics journey?** 🚀

```bash
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics
./setup/setup.sh
```

For detailed instructions, see: [📖 Setup Guide](docs/setup_guide.md) | [📋 Assignment Guide](docs/assignment_guide.md)

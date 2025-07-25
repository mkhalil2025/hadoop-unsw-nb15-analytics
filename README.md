# UNSW-NB15 Hadoop Analytics Environment
## Complete Big Data Analytics Platform for Cybersecurity Research

[![Hadoop](https://img.shields.io/badge/Hadoop-3.3.4-orange)](https://hadoop.apache.org/)
[![Hive](https://img.shields.io/badge/Hive-3.1.3-blue)](https://hive.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)
[![Jupyter](https://img.shields.io/badge/Jupyter-Lab-orange)](https://jupyterlab.readthedocs.io/)
[![Python](https://img.shields.io/badge/Python-3.10+-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-Academic-green)](LICENSE)

**A production-ready, containerized Hadoop ecosystem for analyzing the UNSW-NB15 cybersecurity dataset. Designed specifically for UEL-CN-7031 Big Data Analytics coursework and cybersecurity research.**

---

## 🎯 Project Overview

This project provides a **complete, containerized Hadoop-based analytics environment** for studying cybersecurity patterns in the UNSW-NB15 dataset. It includes everything needed for big data analytics education and research:

- **🏗️ Complete Hadoop Ecosystem**: HDFS, YARN, Hive, PostgreSQL Metastore
- **📊 Advanced Analytics**: 4+ complex HiveQL queries demonstrating big data concepts
- **🐍 Python Integration**: Jupyter Lab with comprehensive data science libraries
- **📈 Professional Visualizations**: Interactive dashboards and publication-quality charts
- **📚 Comprehensive Documentation**: Step-by-step guides and troubleshooting
- **🔧 Memory Optimized**: Configured for student laptops (8-16GB RAM)

#---

## 🚀 Quick Start

### Prerequisites
- **Docker Desktop** (4.0+) with 8GB+ RAM allocated
- **10GB+ free disk space**
- **Git** for cloning the repository

### One-Command Setup
```bash
# Clone the repository
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics

# Run automated setup (takes 5-10 minutes)
./scripts/setup_environment.sh
```

### Access the Environment
After setup completes, access these services:

| Service | URL | Purpose |
|---------|-----|---------|
| **Jupyter Lab** | http://localhost:8888 | Python analytics and notebooks |
| **Hadoop NameNode** | http://localhost:9870 | HDFS file system management |
| **YARN ResourceManager** | http://localhost:8088 | Job monitoring and resources |
| **Hive Server2** | http://localhost:10002 | SQL-like query interface |

### Quick Test
```bash
# Test Hive connection
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000' -e "SHOW DATABASES;"

# Check loaded data
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000' -e "
USE unsw_nb15;
SELECT COUNT(*) as total_records FROM network_flows;
SELECT attack_cat, COUNT(*) as count FROM network_flows GROUP BY attack_cat LIMIT 10;
"
```

---

## 📊 Dataset Information

### UNSW-NB15 Cybersecurity Dataset
- **Source**: University of New South Wales (UNSW) Canberra
- **Size**: ~2.5 million network flow records  
- **Features**: 49 features including flow statistics, service info, attack labels
- **Purpose**: Network intrusion detection system evaluation
- **Categories**: 9 attack types + normal traffic

### Included Sample Data
If the original dataset is unavailable, the system automatically generates realistic sample data with:
- **1,000+ network flow records**
- **Realistic attack distributions** 
- **All 49 original features**
- **Proper data types and relationships**

---

## 🏗️ Architecture

### Container Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network                          │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Hadoop Core   │   Hive Stack    │    Analytics Layer      │
├─────────────────┼─────────────────┼─────────────────────────┤
│ • NameNode      │ • HiveServer2   │ • Jupyter Lab           │
│ • DataNode      │ • Metastore     │ • Python Libraries      │
│ • ResourceMgr   │ • PostgreSQL    │ • Visualization Tools   │
│ • NodeManager   │                 │ • ML Frameworks         │
└─────────────────┴─────────────────┴─────────────────────────┘
```

### Memory Optimization
Configured for student laptops with intelligent memory allocation:
- **8GB Systems**: 2-3GB allocated to Hadoop services
- **16GB Systems**: 6-8GB allocated to Hadoop services  
- **Dynamic scaling** based on available resources
- **Efficient compression** and caching strategies

---

## 📈 Analytics Components

### 1. Advanced HiveQL Queries (4+ Queries)

#### Query 1: Attack Pattern Analysis
- **Focus**: Protocol and service attack patterns
- **Concepts**: Complex aggregations, window functions, ranking
- **Insights**: Most targeted services, attack frequency rankings

#### Query 2: Geographic & Temporal Analysis  
- **Focus**: Time-based attack patterns with geographic correlation
- **Concepts**: Time series analysis, moving averages, LAG/LEAD functions
- **Insights**: Peak attack hours, regional threat patterns

#### Query 3: Statistical Anomaly Detection
- **Focus**: Outlier detection using statistical methods
- **Concepts**: Z-scores, percentiles, multi-dimensional analysis
- **Insights**: Behavioral anomalies, statistical outliers

#### Query 4: Multi-dimensional Analysis
- **Focus**: Attack evolution and vulnerability assessment
- **Concepts**: Advanced window functions, sequence analysis, ranking
- **Insights**: Attacker behavior profiling, service vulnerabilities

### 2. Python Analytics Suite

#### Jupyter Notebooks
- **`data_exploration.ipynb`**: Comprehensive dataset analysis
- **Interactive visualizations** with Plotly
- **Statistical analysis** and correlation studies
- **Machine learning** implementations

#### Automated Visualization Generator
- **20+ chart types** for cybersecurity data
- **Publication-quality** static visualizations
- **Interactive dashboards** for data exploration
- **Automated reporting** capabilities

### 3. Machine Learning Integration
- **Anomaly detection** algorithms (statistical and ML-based)
- **Attack classification** models
- **Feature importance** analysis
- **Model performance** evaluation and tuning

---

## 📁 Project Structure

```
hadoop-unsw-nb15-analytics/
├── 🐳 docker-compose.yml          # Complete service orchestration
├── ⚙️ .env                        # Environment configuration
├── 📄 README.md                   # This file
│
├── 🔧 config/                     # Hadoop configuration files
│   ├── core-site.xml              # Core Hadoop settings
│   ├── hdfs-site.xml              # HDFS configuration  
│   ├── yarn-site.xml              # YARN resource management
│   └── mapred-site.xml            # MapReduce settings
│
├── 🗄️ hive/                       # Hive SQL scripts
│   ├── create_tables.sql          # UNSW-NB15 database schema
│   └── analytical_queries.sql     # 4+ advanced analytical queries
│
├── 📓 notebooks/                  # Jupyter notebooks
│   ├── data_exploration.ipynb     # Complete data analysis
│   └── [custom notebooks]        # Student/researcher additions
│
├── 🐍 python/                     # Python analytics modules  
│   └── visualizations.py         # Automated chart generation
│
├── 🤖 scripts/                    # Automation scripts
│   ├── setup_environment.sh      # One-command environment setup
│   └── load_data.sh              # Automated data loading
│
├── 📊 data/                       # Dataset storage
│   ├── README.md                  # Data loading instructions
│   └── [dataset files]           # UNSW-NB15 CSV files
│
├── 📈 output/                     # Generated results
│   ├── logs/                     # System and application logs
│   ├── results/                  # Query results and analysis
│   └── visualizations/           # Generated charts and dashboards
│
├── 📚 docs/                       # Comprehensive documentation
│   ├── setup_guide.md            # Step-by-step setup instructions
│   ├── query_explanations.md     # Detailed query documentation
│   ├── troubleshooting.md        # Problem resolution guide
│   └── assignment_guidelines.md   # Student assignment instructions
│
└── 📋 requirements.txt            # Python dependencies
```

---

## 🎓 For Students (UEL-CN-7031)

### Assignment Structure
1. **Environment Setup** (15 points)
2. **Exploratory Data Analysis** (25 points)  
3. **Advanced HiveQL Analytics** (30 points)
4. **Machine Learning Implementation** (20 points)
5. **Research Report** (10 points)

### Getting Started
1. **Setup**: Follow the quick start guide
2. **Explore**: Open Jupyter Lab and run `data_exploration.ipynb`
3. **Query**: Execute the provided HiveQL analytical queries
4. **Develop**: Create your own custom queries and analysis
5. **Document**: Write your findings and recommendations

### Assessment Criteria
- **Technical Proficiency**: Correct use of big data tools
- **Analytical Depth**: Quality of insights and interpretation
- **Code Quality**: Well-documented, reproducible analysis
- **Communication**: Clear reporting and visualization

### Resources
- **Setup Guide**: `docs/setup_guide.md`
- **Query Explanations**: `docs/query_explanations.md`
- **Assignment Guidelines**: `docs/assignment_guidelines.md`
- **Troubleshooting**: `docs/troubleshooting.md`

---

## 🔬 For Researchers

### Research Applications
- **Cybersecurity Analytics**: Advanced threat detection and analysis
- **Big Data Education**: Teaching platform for Hadoop ecosystem
- **Anomaly Detection**: Statistical and ML-based approaches
- **Network Security**: Flow-based intrusion detection research

### Extension Points
- **Custom Datasets**: Adapt schema for other cybersecurity datasets
- **Advanced ML**: Implement deep learning models
- **Real-time Analytics**: Add streaming capabilities with Kafka/Spark
- **Distributed Computing**: Scale to multi-node clusters

### Citation
If you use this project in your research, please cite:
```bibtex
@misc{hadoop-unsw-nb15-analytics,
  title={UNSW-NB15 Hadoop Analytics Environment},
  author={[Your Institution]},
  year={2024},
  url={https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics}
}
```

---

## 🛠️ Advanced Configuration

### Memory Tuning
Adjust settings in `.env` for your system:
```bash
# For 8GB systems
YARN_NODEMANAGER_RESOURCE_MEMORY_MB=2048
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=2048

# For 16GB+ systems  
YARN_NODEMANAGER_RESOURCE_MEMORY_MB=8192
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=8192
```

### Performance Optimization
```bash
# Enable compression for better performance
MAPRED_CONF_mapreduce_output_fileoutputformat_compress=true
MAPRED_CONF_mapreduce_map_output_compress=true

# Optimize for SSD storage
HDFS_CONF_dfs_blocksize=67108864  # 64MB blocks
```

### Security Configuration
```bash
# Disable security for development (default)
HDFS_CONF_dfs_permissions_enabled=false
HADOOP_SECURITY_AUTHENTICATION=simple

# Enable security for production (requires additional setup)
# HADOOP_SECURITY_AUTHENTICATION=kerberos
```

---

## 🔧 Management Commands

```bash
# Environment Management
./scripts/setup_environment.sh          # Complete setup
./scripts/setup_environment.sh start    # Start services
./scripts/setup_environment.sh stop     # Stop services  
./scripts/setup_environment.sh restart  # Restart services
./scripts/setup_environment.sh status   # Check status
./scripts/setup_environment.sh clean    # Remove everything

# Data Management  
./scripts/load_data.sh                  # Load sample data
./scripts/load_data.sh download         # Download real dataset
./scripts/load_data.sh validate         # Validate data quality

# Service Access
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'
docker exec -it namenode hadoop fs -ls /
docker exec -it jupyter-analytics bash
```

---

## 📊 Sample Outputs

### Query Results
```sql
-- Attack Pattern Analysis Results
┌─────────────┬──────────┬─────────────┬───────────────┐
│ protocol    │ service  │ attack_cat  │ attack_count  │
├─────────────┼──────────┼─────────────┼───────────────┤
│ tcp         │ http     │ DoS         │ 15,432        │
│ tcp         │ https    │ Exploits    │ 8,921         │
│ udp         │ dns      │ Analysis    │ 5,234         │
└─────────────┴──────────┴─────────────┴───────────────┘
```

### Generated Visualizations
- **Attack Distribution Charts**: Pie charts, bar graphs, time series
- **Network Analysis**: Flow diagrams, protocol usage, port analysis
- **Anomaly Detection**: Scatter plots, statistical distributions
- **Interactive Dashboards**: Multi-dimensional exploration tools

---

## 🆘 Troubleshooting

### Common Issues

**Containers won't start:**
```bash
# Check available memory
free -h
# Reduce memory allocation in .env
# Restart Docker Desktop
```

**Hive connection fails:**
```bash
# Wait for services to initialize (2-5 minutes)
docker logs hiveserver2
# Restart Hive services
docker-compose restart hivemetastore hiveserver2
```

**Port conflicts:**
```bash
# Find conflicting processes
lsof -i :9870
# Kill process or change ports in docker-compose.yml
```

**Data loading errors:**
```bash
# Check HDFS status
curl http://localhost:9870
# Verify permissions
docker exec namenode hdfs dfs -chmod -R 777 /user
```

### Getting Help
1. **Check logs**: `docker-compose logs [service-name]`
2. **Restart services**: `docker-compose restart`
3. **Full reset**: `./scripts/setup_environment.sh clean && ./scripts/setup_environment.sh`
4. **Documentation**: See `docs/troubleshooting.md`

---

## 🏆 Features & Benefits

### ✅ Complete Big Data Stack
- **Hadoop HDFS**: Distributed storage with replication
- **YARN**: Resource management and job scheduling  
- **Hive**: SQL-like interface for big data queries
- **PostgreSQL**: Reliable metastore for Hive

### ✅ Analytics-Ready
- **Pre-built queries**: 4+ advanced analytical queries
- **Jupyter integration**: Python notebooks with Hive connectivity
- **Visualization suite**: Static and interactive charts
- **ML frameworks**: Scikit-learn, pandas, numpy included

### ✅ Educational Focus
- **Memory optimized**: Works on 8GB+ student laptops
- **Comprehensive docs**: Step-by-step guides and explanations
- **Assignment ready**: Structured for coursework completion
- **Professional quality**: Industry-standard tools and practices

### ✅ Research Friendly
- **Reproducible**: Containerized for consistent environments
- **Extensible**: Modular design for customization
- **Scalable**: Can be adapted for larger clusters
- **Well-documented**: Clear architecture and code documentation

---

## 📜 License & Citation

### Academic Use
This project is designed for educational and research purposes. Free to use for:
- University coursework and assignments
- Academic research projects  
- Educational demonstrations
- Non-commercial research

### UNSW-NB15 Dataset Citation
```bibtex
@article{moustafa2015unsw,
  title={UNSW-NB15: a comprehensive data set for network intrusion detection systems},
  author={Moustafa, Nour and Slay, Jill},
  journal={2015 military communications and information systems conference (MilCIS)},
  pages={1--6},
  year={2015},
  organization={IEEE}
}
```

---

## 🤝 Contributing

We welcome contributions to improve this educational platform:

### Areas for Contribution
- **Additional queries**: More complex analytical examples
- **Visualization enhancements**: New chart types and dashboards
- **Documentation improvements**: Clearer explanations and examples
- **Performance optimizations**: Better resource utilization
- **Bug fixes**: Resolve issues and improve stability

### How to Contribute
1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-enhancement`
3. **Make changes**: Add your improvements
4. **Test thoroughly**: Ensure everything works
5. **Submit a pull request**: With clear description of changes

---

## 📞 Support & Community

### Getting Help
- **Documentation**: Check `docs/` directory for comprehensive guides
- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions
- **Email**: Contact maintainers for urgent issues

### Community
- **Students**: Share your analyses and insights
- **Educators**: Adapt for your curriculum needs  
- **Researchers**: Collaborate on cybersecurity analytics
- **Industry**: Provide feedback on real-world applicability

---

## 🌟 Acknowledgments

### Special Thanks
- **UNSW Canberra**: For the UNSW-NB15 dataset
- **Apache Foundation**: For the excellent big data tools
- **Docker Community**: For containerization technology
- **Educational Community**: For feedback and contributions

### Technical Stack
- **Hadoop Ecosystem**: HDFS, YARN, Hive
- **Containerization**: Docker, Docker Compose
- **Analytics**: Python, Jupyter, Pandas, Scikit-learn
- **Visualization**: Matplotlib, Seaborn, Plotly
- **Database**: PostgreSQL for Hive metastore

---

**🎯 Ready to dive into Big Data Analytics?**

Start your journey with cybersecurity data analysis using enterprise-grade tools in a student-friendly environment!

```bash
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics
./scripts/setup_environment.sh
```

**Happy Analytics!** 📊🚀

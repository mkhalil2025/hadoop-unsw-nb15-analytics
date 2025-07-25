# Hadoop UNSW-NB15 Analytics Setup Guide

This guide provides step-by-step instructions for setting up the complete Big Data Analytics environment for UNSW-NB15 cybersecurity dataset analysis.

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 18.04+), macOS 10.14+, or Windows 10 with WSL2
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: At least 10GB free disk space
- **CPU**: 4+ cores recommended for optimal performance

### Required Software

1. **Docker** (version 20.0+)
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   
   # macOS (using Homebrew)
   brew install docker docker-compose
   
   # Start Docker service
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Docker Compose** (version 1.29+)
   ```bash
   # Verify installation
   docker --version
   docker-compose --version
   ```

3. **Git** (for cloning the repository)
   ```bash
   # Ubuntu/Debian
   sudo apt install git
   
   # macOS
   brew install git
   ```

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics
```

### Step 2: Download the UNSW-NB15 Dataset

1. Visit the official UNSW-NB15 dataset page: https://research.unsw.edu.au/projects/unsw-nb15-dataset
2. Download the following files to the `data/` directory:
   - `UNSW_NB15_training-set.csv`
   - `UNSW_NB15_testing-set.csv`
   - `NUSW-NB15_features.csv`

```bash
# Create data directory if it doesn't exist
mkdir -p data/

# Place downloaded files in the data/ directory
# Your data/ directory should look like:
# data/
# ├── UNSW_NB15_training-set.csv
# ├── UNSW_NB15_testing-set.csv
# └── NUSW-NB15_features.csv
```

**Note**: If you don't have access to the original dataset, the data loader script will create sample data files for demonstration purposes.

### Step 3: Run the Automated Setup

```bash
# Make setup script executable
chmod +x setup/setup.sh

# Run the complete setup
./setup/setup.sh
```

The setup script will:
- Pull all required Docker images
- Start the Hadoop cluster services
- Configure Hive with PostgreSQL metastore
- Set up Jupyter notebook environment
- Create necessary HDFS directories
- Verify all services are running

### Step 4: Load the Dataset

```bash
# Make data loader script executable
chmod +x setup/data_loader.sh

# Load UNSW-NB15 data into HDFS
./setup/data_loader.sh
```

### Step 5: Create Hive Tables

```bash
# Connect to Hive and create tables
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -f /opt/hive/scripts/create_tables.hql

# Or run interactively
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

## Service Access URLs

Once the setup is complete, you can access the following services:

| Service | URL | Description |
|---------|-----|-------------|
| Hadoop Namenode | http://localhost:9870 | HDFS management interface |
| YARN ResourceManager | http://localhost:8088 | YARN job management |
| Hive Server | jdbc:hive2://localhost:10000 | Hive SQL interface |
| Jupyter Notebook | http://localhost:8888 | Python analysis environment |
| MapReduce History Server | http://localhost:8188 | Job history tracking |

## Verification Steps

### 1. Check Docker Containers

```bash
# Verify all containers are running
docker-compose ps

# Expected output should show all services as "Up"
```

### 2. Verify HDFS

```bash
# Check HDFS status
docker exec namenode hadoop fs -ls /

# Verify data upload
docker exec namenode hadoop fs -ls /data/unsw-nb15/
```

### 3. Test Hive Connection

```bash
# Connect to Hive
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

# In Hive shell, run:
USE cybersecurity_analytics;
SHOW TABLES;
SELECT COUNT(*) FROM unsw_nb15_combined;
```

### 4. Test Jupyter Environment

1. Open http://localhost:8888 in your browser
2. Navigate to the `work` directory
3. Create a new notebook and test Python connection:

```python
# Test basic functionality
import pandas as pd
import matplotlib.pyplot as plt
from hive_connection import HiveConnectionManager

# Test Hive connection
hive_conn = HiveConnectionManager()
if hive_conn.connect():
    print("Successfully connected to Hive!")
    hive_conn.close_connection()
else:
    print("Failed to connect to Hive")
```

## Configuration Customization

### Memory Optimization

For systems with limited memory, edit `hadoop.env`:

```bash
# Reduce memory allocation (4GB systems)
YARN_CONF_yarn_nodemanager_resource_memory___mb=1024
YARN_CONF_yarn_scheduler_maximum___allocation___mb=1024
MAPRED_CONF_mapreduce_map_memory_mb=256
MAPRED_CONF_mapreduce_reduce_memory_mb=512
```

### Port Configuration

To change default ports, modify `docker-compose.yml`:

```yaml
# Example: Change Namenode port
namenode:
  ports:
    - "9871:9870"  # Change from 9870 to 9871
```

### Data Directory

To use a different data directory, update the volume mount in `docker-compose.yml`:

```yaml
volumes:
  - /path/to/your/data:/data  # Change the host path
```

## Network Configuration

### Docker Network

The environment uses a custom Docker network named `hadoop`. All services communicate through this network using service names as hostnames.

### Firewall Settings

Ensure the following ports are accessible:
- 9870 (Namenode Web UI)
- 8088 (YARN ResourceManager)
- 10000 (Hive Server)
- 8888 (Jupyter Notebook)

## Data Loading Process

The data loading process involves:

1. **HDFS Directory Creation**: Creating structured directories in HDFS
2. **File Transfer**: Copying CSV files from local storage to HDFS
3. **Data Validation**: Verifying file integrity and accessibility
4. **Hive Integration**: Making data available for Hive queries

## Performance Tuning

### Hadoop Configuration

Optimize Hadoop settings in `hadoop.env`:

```bash
# Enable compression
MAPRED_CONF_mapred_map_output_compress=true
MAPRED_CONF_mapred_map_output_compress_codec=org.apache.hadoop.io.compress.SnappyCodec

# Increase parallelism
MAPRED_CONF_mapreduce_job_reduces=4
```

### Hive Optimization

```sql
-- Enable vectorization
SET hive.vectorized.execution.enabled=true;

-- Use Parquet for better performance
SET hive.default.fileformat=Parquet;

-- Optimize joins
SET hive.auto.convert.join=true;
```

## Security Considerations

### Default Settings

This environment is configured for development and learning purposes with:
- Disabled HDFS permissions
- No authentication required
- Open network access

### Production Recommendations

For production deployments:
- Enable Kerberos authentication
- Configure HDFS permissions
- Set up SSL/TLS encryption
- Implement network segmentation
- Regular security updates

## Backup and Recovery

### Data Backup

```bash
# Backup HDFS data
docker exec namenode hadoop distcp /data/unsw-nb15 /backup/unsw-nb15

# Export Hive tables
docker exec hive-server hive -e "EXPORT TABLE cybersecurity_analytics.unsw_nb15_combined TO '/backup/hive/unsw_nb15_combined'"
```

### Configuration Backup

```bash
# Backup configuration files
tar -czf hadoop-config-backup.tar.gz hadoop.env docker-compose.yml setup/ hive/
```

## Troubleshooting Quick Reference

### Common Issues

1. **Port conflicts**: Change ports in `docker-compose.yml`
2. **Memory issues**: Reduce memory settings in `hadoop.env`
3. **Slow startup**: Wait longer for services to initialize
4. **Data loading fails**: Check file permissions and paths

### Log Access

```bash
# View service logs
docker-compose logs namenode
docker-compose logs hive-server
docker-compose logs jupyter

# Follow logs in real-time
docker-compose logs -f [service-name]
```

### Service Restart

```bash
# Restart specific service
docker-compose restart namenode

# Restart all services
docker-compose restart

# Complete reset
docker-compose down -v
docker-compose up -d
```

## Next Steps

After successful setup:

1. Review the assignment guide: `docs/assignment_guide.md`
2. Explore complex queries: `hive/complex_queries.hql`
3. Generate visualizations: `python/visualizations.py`
4. Read troubleshooting guide: `docs/troubleshooting.md`

## Support

For additional help:
- Check the troubleshooting guide
- Review Docker and Hadoop logs
- Consult the project README
- Search for known issues in the repository
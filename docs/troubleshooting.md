# Troubleshooting Guide
## UNSW-NB15 Hadoop Analytics Environment

This guide helps resolve common issues encountered when setting up and using the Hadoop analytics environment.

## 🔧 Quick Diagnostic Commands

Before troubleshooting, run these commands to check system status:

```bash
# Check all container status
docker-compose ps

# Check system resources
docker stats --no-stream

# Check available ports
netstat -tuln | grep -E '(5432|8020|8088|9870|10000|8888)'

# Check Docker version
docker --version && docker-compose --version

# Check available disk space
df -h .

# Check available memory
free -h
```

---

## 🚨 Common Issues and Solutions

### 1. Container Startup Issues

#### Problem: Containers fail to start or keep restarting
```bash
$ docker-compose up -d
ERROR: Container namenode exited with error
```

**Diagnosis**:
```bash
# Check container logs
docker-compose logs namenode
docker-compose logs postgres

# Check exit codes
docker-compose ps
```

**Common Causes & Solutions**:

**A) Insufficient Memory**
- **Symptoms**: Containers with status "Exited (137)" or "OOMKilled"
- **Solution**: 
  ```bash
  # Reduce memory allocation in .env file
  nano .env
  # Change YARN_NODEMANAGER_RESOURCE_MEMORY_MB to 2048 or 3072
  # Restart containers
  docker-compose down && docker-compose up -d
  ```

**B) Port Conflicts**
- **Symptoms**: "Port already in use" errors
- **Solution**:
  ```bash
  # Find process using the port
  lsof -i :9870  # Replace 9870 with problematic port
  # Kill the process or change port in docker-compose.yml
  ```

**C) Docker Daemon Issues**
- **Symptoms**: "Cannot connect to Docker daemon"
- **Solution**:
  ```bash
  # Start Docker daemon
  sudo systemctl start docker  # Linux
  # Or restart Docker Desktop (Windows/Mac)
  ```

### 2. Hive Connection Issues

#### Problem: Cannot connect to HiveServer2
```bash
$ docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000"
Error: Could not open client transport
```

**Diagnosis**:
```bash
# Check if HiveServer2 is running
docker exec hiveserver2 ps aux | grep hive

# Check HiveServer2 logs
docker logs hiveserver2

# Test port accessibility
docker exec hiveserver2 netstat -tuln | grep 10000
```

**Solutions**:

**A) HiveServer2 Still Starting**
- **Wait time**: HiveServer2 can take 2-5 minutes to fully initialize
- **Check progress**: `docker logs -f hiveserver2`
- **Wait for message**: "HiveServer2 started on port 10000"

**B) PostgreSQL Metastore Not Ready**
- **Check PostgreSQL**: `docker logs postgres-metastore`
- **Restart sequence**:
  ```bash
  docker-compose restart postgres-metastore
  sleep 30
  docker-compose restart hivemetastore
  sleep 60
  docker-compose restart hiveserver2
  ```

**C) Schema Not Initialized**
- **Reinitialize schema**:
  ```bash
  docker exec hivemetastore schematool -dbType postgres -initSchema
  docker-compose restart hiveserver2
  ```

### 3. Jupyter Notebook Issues

#### Problem: Cannot access Jupyter Lab at localhost:8888
```bash
Error: This site can't be reached
```

**Diagnosis**:
```bash
# Check Jupyter container
docker logs jupyter-analytics

# Check if port is accessible
curl http://localhost:8888
```

**Solutions**:

**A) Container Not Running**
```bash
# Check container status
docker-compose ps jupyter-analytics

# Restart if needed
docker-compose restart jupyter-analytics
```

**B) Package Installation Issues**
```bash
# Access container and install packages manually
docker exec -it jupyter-analytics bash
pip install pyhive thrift sasl thrift_sasl
```

**C) Permission Issues**
```bash
# Fix permissions
docker exec -u root jupyter-analytics chmod -R 777 /home/jovyan
```

### 4. Data Loading Problems

#### Problem: Data loading script fails
```bash
$ ./scripts/load_data.sh
ERROR: Failed to create Hive tables
```

**Diagnosis**:
```bash
# Check if script is executable
ls -la scripts/load_data.sh

# Run with verbose logging
bash -x scripts/load_data.sh

# Check HDFS connectivity
docker exec namenode hdfs dfs -ls /
```

**Solutions**:

**A) HDFS Not Ready**
```bash
# Wait for HDFS to be fully initialized
curl http://localhost:9870

# Check safe mode
docker exec namenode hdfs dfsadmin -safemode get

# Leave safe mode if necessary
docker exec namenode hdfs dfsadmin -safemode leave
```

**B) Permissions Issues**
```bash
# Fix HDFS permissions
docker exec namenode hdfs dfs -chmod -R 777 /user
```

**C) Hive Tables Already Exist**
```bash
# Drop and recreate tables
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "
DROP DATABASE IF EXISTS unsw_nb15 CASCADE;
"
# Re-run data loading script
./scripts/load_data.sh
```

### 5. Performance Issues

#### Problem: System running slowly or containers using too much memory

**Diagnosis**:
```bash
# Monitor resource usage
docker stats

# Check system load
top
htop  # If available

# Check Docker memory limits
docker system info | grep -i memory
```

**Solutions**:

**A) Reduce Memory Allocation**
Edit `.env` file:
```bash
# For 8GB systems
YARN_NODEMANAGER_RESOURCE_MEMORY_MB=2048
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=2048
HADOOP_NAMENODE_OPTS="-Xmx512m -Xms256m"
HADOOP_DATANODE_OPTS="-Xmx256m -Xms128m"
```

**B) Limit Container Resources**
Add to `docker-compose.yml`:
```yaml
services:
  namenode:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

**C) Reduce Data Size**
```bash
# Use smaller sample size
# Edit scripts/load_data.sh and change sample_size parameter
```

### 6. Network Connectivity Issues

#### Problem: Services cannot communicate with each other

**Diagnosis**:
```bash
# Check Docker networks
docker network ls

# Inspect the network
docker network inspect hadoop-unsw-nb15-analytics_hadoop-network

# Test connectivity between containers
docker exec namenode ping postgres-metastore
```

**Solutions**:

**A) Recreate Network**
```bash
docker-compose down
docker network prune
docker-compose up -d
```

**B) Check Firewall**
```bash
# Linux: Check iptables
sudo iptables -L

# Windows: Check Windows Firewall
# Mac: Check System Preferences > Security & Privacy
```

---

## 🔍 Detailed Diagnostics

### Container Health Checks

Create a diagnostic script:
```bash
#!/bin/bash
# Save as: check_health.sh

echo "=== Docker Environment ==="
docker --version
docker-compose --version
echo

echo "=== Container Status ==="
docker-compose ps
echo

echo "=== Resource Usage ==="
docker stats --no-stream
echo

echo "=== Service Connectivity ==="
echo "Namenode Web UI:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:9870
echo

echo "YARN ResourceManager:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8088
echo

echo "HiveServer2:"
timeout 5 docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" 2>/dev/null && echo "Connected" || echo "Failed"

echo "Jupyter Lab:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888
echo

echo "=== Disk Usage ==="
df -h .
echo

echo "=== Memory Usage ==="
free -h
```

### Log Analysis

Check specific service logs:
```bash
# Hadoop Namenode
docker logs namenode 2>&1 | grep -i error

# Hive Server2
docker logs hiveserver2 2>&1 | grep -i "error\|exception"

# PostgreSQL
docker logs postgres-metastore 2>&1 | grep -i "error\|fatal"

# All services with timestamps
docker-compose logs -t
```

---

## 🆘 Emergency Recovery Procedures

### Complete Environment Reset

If everything fails, perform a complete reset:

```bash
#!/bin/bash
# Nuclear option - removes everything

echo "Stopping all containers..."
docker-compose down -v

echo "Removing all project containers..."
docker container prune -f

echo "Removing all project volumes..."
docker volume prune -f

echo "Removing all project networks..."
docker network prune -f

echo "Removing all project images (optional)..."
# docker image prune -a -f

echo "Cleaning up data directories..."
rm -rf output/logs/*
rm -rf data/*.csv

echo "Restarting environment..."
./scripts/setup_environment.sh
```

### Backup Important Data

Before major changes:
```bash
# Backup configuration
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Backup custom notebooks
cp -r notebooks notebooks.backup.$(date +%Y%m%d_%H%M%S)

# Export HDFS data (if any custom data exists)
docker exec namenode hdfs dfs -get /user/data/custom_data ./backup/
```

---

## 🔧 Platform-Specific Issues

### Windows Issues

**1. Path Length Limitations**
```powershell
# Enable long paths in Windows 10/11
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
```

**2. WSL2 Integration**
```bash
# Ensure Docker Desktop is using WSL2 backend
# Docker Desktop Settings > General > Use WSL2 based engine
```

**3. Line Ending Issues**
```bash
# Convert line endings for shell scripts
dos2unix scripts/*.sh
```

### macOS Issues

**1. Docker Desktop Resource Limits**
```bash
# Increase resources in Docker Desktop
# Docker Desktop > Preferences > Resources
# Increase Memory to 8GB+, CPU to 4+
```

**2. File Sharing Permissions**
```bash
# Add project directory to Docker file sharing
# Docker Desktop > Preferences > Resources > File Sharing
```

### Linux Issues

**1. Docker Permissions**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**2. Systemd Service Issues**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

---

## 📊 Performance Tuning

### Memory Optimization

For systems with limited memory (8GB):
```bash
# Ultra-light configuration
cat > .env.light << EOF
YARN_NODEMANAGER_RESOURCE_MEMORY_MB=1536
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=1536
HADOOP_NAMENODE_OPTS="-Xmx256m -Xms128m"
HADOOP_DATANODE_OPTS="-Xmx128m -Xms64m"
YARN_RESOURCEMANAGER_HEAPSIZE=512
YARN_NODEMANAGER_HEAPSIZE=512
HIVE_METASTORE_HEAPSIZE=256m
HIVE_SERVER2_HEAPSIZE=512m
EOF

# Replace .env with light configuration
cp .env.light .env
docker-compose restart
```

### Disk Space Management

```bash
# Clean up Docker system
docker system prune -a --volumes

# Remove old logs
find output/logs -name "*.log" -mtime +7 -delete

# Compress old data
gzip data/*.csv

# Monitor disk usage
du -sh data/ output/ notebooks/
```

---

## 📞 Getting Help

### Self-Help Resources

1. **Check logs first**: Most issues are revealed in container logs
2. **Verify prerequisites**: Ensure Docker, memory, and disk requirements are met
3. **Search error messages**: Copy exact error messages to search engines
4. **Check Docker Hub**: Verify image availability and compatibility

### Information to Gather Before Seeking Help

When reporting issues, include:

```bash
# System information
uname -a
docker --version
docker-compose --version
free -h
df -h .

# Error reproduction
# Exact commands that failed
# Complete error messages
# Container logs for failing services

# Environment details
cat .env | grep -v PASSWORD
docker-compose ps
docker network ls
```

### Community Resources

- **Docker Documentation**: https://docs.docker.com/
- **Hadoop Troubleshooting**: https://hadoop.apache.org/docs/stable/
- **Hive Documentation**: https://hive.apache.org/documentation.html
- **Stack Overflow**: Search for specific error messages
- **GitHub Issues**: Check project repository for known issues

---

## ✅ Prevention Best Practices

### Regular Maintenance

```bash
# Weekly cleanup
docker system prune -f
./scripts/setup_environment.sh restart

# Monthly full reset
./scripts/setup_environment.sh clean
./scripts/setup_environment.sh
```

### Monitoring

```bash
# Create monitoring script
#!/bin/bash
# monitor.sh
while true; do
    echo "$(date): Memory usage:"
    free -h | head -2
    echo "$(date): Disk usage:"
    df -h . | tail -1
    echo "$(date): Container status:"
    docker-compose ps | grep -E "(Up|Exit)"
    echo "---"
    sleep 300  # Check every 5 minutes
done
```

### Backup Strategy

```bash
# Regular backups
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/$DATE

# Backup configurations
cp .env backups/$DATE/
cp docker-compose.yml backups/$DATE/

# Backup custom work
cp -r notebooks backups/$DATE/
cp -r output/results backups/$DATE/ 2>/dev/null || true

echo "Backup completed: backups/$DATE"
```

---

**Remember**: Most issues are resolved by restarting services or reducing resource allocation. When in doubt, try a complete environment reset with `./scripts/setup_environment.sh clean && ./scripts/setup_environment.sh`.
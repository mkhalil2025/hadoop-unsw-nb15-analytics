# Hive Metastore Troubleshooting Guide

## Problem: "MetaException: Version information not found in metastore"

This guide helps resolve the common Hive metastore schema initialization issue in the UNSW-NB15 Big Data Analytics environment.

### Quick Fix (Recommended)

```bash
# Simple one-command fix
./quick_fix_hive.sh
```

### Comprehensive Fix

```bash
# Full diagnostic and fix
./scripts/fix_hive_metastore.sh
```

### Manual Step-by-Step Fix

If the automated scripts don't work, follow these manual steps:

#### 1. Stop All Hive Services
```bash
docker-compose stop hiveserver2 hivemetastore
```

#### 2. Ensure PostgreSQL is Running
```bash
docker-compose up -d postgres
docker exec postgres-metastore pg_isready -U hive
```

#### 3. Backup Existing Data (Optional)
```bash
docker exec postgres-metastore pg_dump -U hive metastore > backup_$(date +%Y%m%d).sql
```

#### 4. Recreate Metastore Database
```bash
docker exec postgres-metastore psql -U hive -d postgres -c "DROP DATABASE IF EXISTS metastore;"
docker exec postgres-metastore psql -U hive -d postgres -c "CREATE DATABASE metastore;"
```

#### 5. Initialize Schema with Schematool
```bash
docker run --rm \
  --network hadoop-unsw-nb15-analytics_hadoop-network \
  -e HIVE_CORE_CONF_javax_jdo_option_ConnectionURL="jdbc:postgresql://postgres:5432/metastore" \
  -e HIVE_CORE_CONF_javax_jdo_option_ConnectionDriverName="org.postgresql.Driver" \
  -e HIVE_CORE_CONF_javax_jdo_option_ConnectionUserName="hive" \
  -e HIVE_CORE_CONF_javax_jdo_option_ConnectionPassword="hive123" \
  bde2020/hive:2.3.2-postgresql-metastore \
  /opt/hive/bin/schematool -dbType postgres -initSchema
```

#### 6. Start Services in Order
```bash
docker-compose up -d namenode datanode
sleep 30
docker-compose up -d hivemetastore
sleep 30
docker-compose up -d hiveserver2
```

#### 7. Verify Setup
```bash
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"
```

### Common Issues and Solutions

#### Issue: Network not found
**Error**: `network hadoop-unsw-nb15-analytics_hadoop-network not found`

**Solution**: 
```bash
cd /path/to/project
docker-compose up -d postgres
# Then retry the schematool command
```

#### Issue: Connection refused
**Error**: `Connection refused to postgres:5432`

**Solution**: 
```bash
# Check if PostgreSQL is running
docker ps | grep postgres
# If not running:
docker-compose up -d postgres
# Wait for it to be ready:
docker exec postgres-metastore pg_isready -U hive
```

#### Issue: Permission denied
**Error**: Permission denied errors in containers

**Solution**: 
```bash
# Fix permissions for bind mounts
sudo chown -R $(id -u):$(id -g) ./config ./hive ./output
```

#### Issue: Port already in use
**Error**: `Port 5432 is already allocated`

**Solution**: 
```bash
# Find what's using the port
sudo lsof -i :5432
# Stop the conflicting service or change the port in docker-compose.yml
```

### Windows/WSL Specific Issues

#### Issue: Docker commands fail in WSL
**Solution**: 
```bash
# Ensure Docker Desktop is running in Windows
# Use WSL 2 backend in Docker Desktop settings
# In WSL terminal:
export DOCKER_HOST=tcp://localhost:2375  # if needed
```

#### Issue: File path issues
**Solution**: 
```bash
# Use absolute paths in WSL
cd /mnt/c/path/to/project  # if project is on C: drive
# Or keep project in WSL filesystem for better performance
```

#### Issue: Web UIs not accessible
**Solution**: 
- Check Windows Firewall settings
- Ensure Docker Desktop port forwarding is enabled
- Access URLs from Windows browser, not WSL browser

### Validation Commands

After fixing, run these commands to validate:

```bash
# Check container status
docker ps

# Test Hive connectivity
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"

# Check metastore schema
docker exec postgres-metastore psql -U hive -d metastore -c "SELECT * FROM VERSION;"

# Check web interfaces
curl http://localhost:9870    # Hadoop NameNode
curl http://localhost:10002   # HiveServer2 Web UI
```

### Logs to Check

If issues persist, check these logs:

```bash
# Hive Metastore logs
docker logs hivemetastore

# HiveServer2 logs
docker logs hiveserver2

# PostgreSQL logs
docker logs postgres-metastore

# All service logs
docker-compose logs
```

### Contact and Support

- Check project documentation in `./docs/`
- Review setup logs in `./output/`
- For course-specific help, contact UEL-CN-7031 instructors

### Environment Cleanup

If you need to start completely fresh:

```bash
# WARNING: This removes all data
docker-compose down -v
docker system prune -f
./scripts/fix_hive_metastore.sh
```

### Next Steps After Fix

1. Load UNSW-NB15 dataset: `./scripts/load_data.sh`
2. Create tables: Run SQL from `./hive/create_tables.sql`
3. Start analytics: Open Jupyter at `http://localhost:8888`
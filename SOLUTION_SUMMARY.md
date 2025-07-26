# Hive Metastore Schema Fix - Solution Summary

## Problem Solved
**Issue**: Hive Metastore containers continuously restarting with error:
```
MetaException: Version information not found in metastore.
```

This was preventing HiveServer2 from functioning and blocking UNSW-NB15 data loading.

## Solution Implemented

### 1. Comprehensive Fix Script (`scripts/fix_hive_metastore.sh`)
**Features:**
- 11-step automated fix process
- Backup existing data before changes
- Clean PostgreSQL database recreation  
- Proper Hive schema initialization using `schematool`
- Service startup in correct dependency order
- Comprehensive health checks and validation
- Detailed logging and status reporting
- Windows/WSL compatibility

**Usage:**
```bash
# Complete fix (recommended)
./scripts/fix_hive_metastore.sh

# Individual operations
./scripts/fix_hive_metastore.sh check        # Check requirements
./scripts/fix_hive_metastore.sh backup       # Backup only
./scripts/fix_hive_metastore.sh init-schema  # Schema init only
./scripts/fix_hive_metastore.sh start        # Start services only
./scripts/fix_hive_metastore.sh status       # Show status
```

### 2. Quick Fix Script (`quick_fix_hive.sh`)
**Purpose**: Simple wrapper for Windows/WSL users
**Features:**
- One-command execution
- Windows environment detection
- Docker compatibility fixes

**Usage:**
```bash
./quick_fix_hive.sh
```

### 3. Enhanced Docker Compose Configuration
**Improvements:**
- Added health checks for Hive services
- Better service dependencies and startup order
- Enhanced environment variables for schema validation
- Restart policies for failed containers
- Volume mounts for troubleshooting scripts

**Key Changes:**
```yaml
hivemetastore:
  environment:
    HIVE_SITE_CONF_hive_metastore_schema_verification: "true"
    HIVE_SITE_CONF_hive_metastore_schema_verification_record_version: "true"
  healthcheck:
    test: ["CMD-SHELL", "netstat -ln | grep 9083 || exit 1"]
    start_period: 60s
  restart: on-failure

hiveserver2:
  depends_on:
    hivemetastore:
      condition: service_healthy
  healthcheck:
    test: ["CMD-SHELL", "netstat -ln | grep 10000 || exit 1"]
    start_period: 90s
  restart: on-failure
```

### 4. Comprehensive Documentation
**Files Added:**
- `HIVE_METASTORE_TROUBLESHOOTING.md` - Detailed troubleshooting guide
- Updated `README.md` with troubleshooting section
- Inline script documentation and help

## Technical Details

### Root Cause Analysis
1. **Schema Not Initialized**: PostgreSQL database was empty without Hive metastore tables
2. **Missing VERSION Table**: Hive requires a VERSION table to track schema version
3. **Configuration Mismatch**: `datanucleus_autoCreateSchema` was set to false without manual initialization
4. **Service Dependencies**: Services starting before dependencies were ready

### Fix Process
1. **Stop Services Cleanly**: Graceful shutdown of Hive components
2. **PostgreSQL Verification**: Ensure metastore database is accessible
3. **Data Backup**: Preserve existing data if present
4. **Database Recreation**: Clean slate PostgreSQL metastore database
5. **Schema Initialization**: Use Hive's official `schematool` utility
6. **Schema Verification**: Validate VERSION table and essential tables exist
7. **Ordered Startup**: Start services in proper dependency order
8. **Health Validation**: Comprehensive connectivity and functionality tests

### Key Commands Used
```bash
# Schema initialization (core fix)
docker run --rm \
  --network hadoop-network \
  -e HIVE_CORE_CONF_javax_jdo_option_ConnectionURL="jdbc:postgresql://postgres:5432/metastore" \
  bde2020/hive:2.3.2-postgresql-metastore \
  /opt/hive/bin/schematool -dbType postgres -initSchema

# Service validation
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"
```

## Validation Results

### Successful Fix Indicators
- ✅ Containers no longer restarting
- ✅ HiveServer2 listening on port 10000
- ✅ VERSION table exists with proper schema version
- ✅ `SHOW DATABASES` command works
- ✅ Web UIs accessible

### Test Commands
```bash
# Container status
docker ps | grep -E "(hivemetastore|hiveserver2|postgres)"

# Hive connectivity
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"

# Schema verification
docker exec postgres-metastore psql -U hive -d metastore -c "SELECT * FROM VERSION;"

# Web interface tests
curl http://localhost:9870    # Hadoop NameNode
curl http://localhost:10002   # HiveServer2 Web UI
```

## Windows/WSL Considerations

### Compatibility Features
- Environment variable detection for WSL
- Docker BuildKit compatibility settings
- Path handling for Windows/Linux differences
- Clear instructions for Docker Desktop setup

### Specific WSL Setup
```bash
# In WSL terminal
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
./quick_fix_hive.sh
```

## Next Steps After Fix

1. **Load UNSW-NB15 Data**:
   ```bash
   ./scripts/load_data.sh
   ```

2. **Create Analytics Tables**:
   ```bash
   docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /opt/hive/scripts/create_tables.sql
   ```

3. **Start Analytics**:
   - Open Jupyter Lab: http://localhost:8888
   - Access Hadoop Web UI: http://localhost:9870
   - Use Hive Web UI: http://localhost:10002

## Monitoring and Maintenance

### Regular Health Checks
```bash
# Quick status check
./scripts/fix_hive_metastore.sh status

# Container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Service logs
docker-compose logs hivemetastore hiveserver2
```

### Backup Strategy
```bash
# Manual backup before major changes
./scripts/fix_hive_metastore.sh backup

# Automated backup (in scripts)
docker exec postgres-metastore pg_dump -U hive metastore > backup_$(date +%Y%m%d).sql
```

## Solution Benefits

✅ **Robust**: Handles edge cases and provides fallbacks  
✅ **User-Friendly**: Clear instructions and automated processes  
✅ **Documented**: Comprehensive guides and inline help  
✅ **Cross-Platform**: Works on Windows, macOS, and Linux  
✅ **Educational**: Teaches Hadoop ecosystem troubleshooting  
✅ **Production-Ready**: Follows best practices for service management  

## File Structure
```
project/
├── scripts/
│   └── fix_hive_metastore.sh     # Main fix script
├── quick_fix_hive.sh             # Simple wrapper
├── HIVE_METASTORE_TROUBLESHOOTING.md  # Detailed guide
├── docker-compose.yml            # Enhanced configuration
├── README.md                     # Updated with troubleshooting
└── output/
    ├── metastore_fix.log         # Fix execution log
    └── metastore_fix_status.txt  # Status report
```

This solution provides a complete, production-ready fix for the Hive metastore schema initialization issue while maintaining educational value and ease of use for students.
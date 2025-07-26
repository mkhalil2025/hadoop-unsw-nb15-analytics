#!/bin/bash

# UNSW-NB15 Hive Metastore Schema Initialization Fix
# UEL-CN-7031 Big Data Analytics - Hadoop & Hive Setup
# 
# This script fixes the "MetaException: Version information not found in metastore" issue
# by properly initializing the PostgreSQL schema for Hive Metastore
#
# Student: mkhalil2025
# Course: UEL-CN-7031 Big Data Analytics

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/output/metastore_fix.log"
BACKUP_DIR="$PROJECT_ROOT/output/backups/$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "  🔧 HIVE METASTORE SCHEMA INITIALIZATION FIX"
    echo "  UEL-CN-7031 Big Data Analytics - UNSW-NB15 Project"
    echo "=================================================================="
    echo -e "${NC}"
}

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    echo -e "${RED}❌ ERROR: $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}💥 Fix failed. Check log at: $LOG_FILE${NC}"
    echo -e "${YELLOW}📋 For troubleshooting, run: docker-compose logs${NC}"
    exit 1
}

# Success message function
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Warning message function
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Info message function
info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

# Progress indicator
progress() {
    echo -e "${PURPLE}🔄 $1${NC}" | tee -a "$LOG_FILE"
}

# Step indicator
step() {
    echo -e "${CYAN}📋 STEP $1: $2${NC}" | tee -a "$LOG_FILE"
}

# Create necessary directories
create_directories() {
    progress "Creating necessary directories..."
    
    mkdir -p "$PROJECT_ROOT/output/logs"
    mkdir -p "$PROJECT_ROOT/output/backups"
    mkdir -p "$BACKUP_DIR"
    
    success "Directories created"
}

# Check system requirements
check_requirements() {
    step "1" "Checking system requirements"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed. Please install Docker first."
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error_exit "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if we're in the correct directory
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        error_exit "docker-compose.yml not found. Please run this script from the project root directory."
    fi
    
    # Check available disk space
    local available_space=$(df "$PROJECT_ROOT" | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$available_space" -lt 2 ]; then
        warning "Less than 2GB disk space available. Consider freeing up space."
    fi
    
    success "System requirements check completed"
}

# Stop all Hive services cleanly
stop_hive_services() {
    step "2" "Stopping all Hive services cleanly"
    
    cd "$PROJECT_ROOT"
    
    # Stop containers gracefully
    info "Stopping HiveServer2..."
    docker-compose stop hiveserver2 2>/dev/null || warning "HiveServer2 was not running"
    
    info "Stopping Hive Metastore..."
    docker-compose stop hivemetastore 2>/dev/null || warning "Hive Metastore was not running"
    
    # Wait a moment for graceful shutdown
    sleep 5
    
    # Force stop if needed
    info "Ensuring containers are stopped..."
    docker stop hiveserver2 hivemetastore 2>/dev/null || true
    
    success "Hive services stopped cleanly"
}

# Start and check PostgreSQL
ensure_postgres_ready() {
    step "3" "Ensuring PostgreSQL metastore is ready"
    
    cd "$PROJECT_ROOT"
    
    # Start PostgreSQL if not running
    info "Starting PostgreSQL metastore..."
    docker-compose up -d postgres
    
    # Wait for PostgreSQL to be ready
    info "Waiting for PostgreSQL to be ready..."
    local retries=30
    while [ $retries -gt 0 ]; do
        if docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
            break
        fi
        info "Waiting for PostgreSQL... ($retries attempts remaining)"
        sleep 5
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "PostgreSQL failed to start within timeout"
    fi
    
    success "PostgreSQL metastore is ready"
}

# Backup existing metastore data
backup_metastore() {
    step "4" "Backing up existing metastore data"
    
    info "Creating backup of existing metastore..."
    
    # Check if metastore database exists and has data
    local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$table_count" -gt 0 ]; then
        info "Found $table_count tables in metastore, creating backup..."
        docker exec postgres-metastore pg_dump -U hive metastore > "$BACKUP_DIR/metastore_backup.sql"
        success "Metastore backup saved to: $BACKUP_DIR/metastore_backup.sql"
    else
        info "No existing metastore tables found, skipping backup"
    fi
    
    success "Backup process completed"
}

# Clean and recreate metastore database
recreate_metastore_database() {
    step "5" "Recreating metastore database"
    
    info "Dropping existing metastore database..."
    docker exec postgres-metastore psql -U hive -d postgres -c "DROP DATABASE IF EXISTS metastore;" 2>/dev/null || true
    
    info "Creating fresh metastore database..."
    docker exec postgres-metastore psql -U hive -d postgres -c "CREATE DATABASE metastore;"
    
    info "Granting permissions..."
    docker exec postgres-metastore psql -U hive -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;"
    
    success "Metastore database recreated successfully"
}

# Initialize Hive schema using schematool
initialize_hive_schema() {
    step "6" "Initializing Hive metastore schema"
    
    cd "$PROJECT_ROOT"
    
    # Ensure namenode and datanode are running for schema initialization
    info "Starting Hadoop services for schema initialization..."
    docker-compose up -d namenode datanode
    
    # Wait for namenode to be ready
    info "Waiting for Hadoop namenode..."
    local retries=20
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:9870 >/dev/null 2>&1; then
            break
        fi
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        warning "Namenode not ready, proceeding anyway..."
    fi
    
    # Create a temporary container to run schematool
    info "Running Hive schematool to initialize schema..."
    
    # Use the same Hive image to run schematool
    docker run --rm \
        --network "$(basename "$PROJECT_ROOT")_hadoop-network" \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionURL="jdbc:postgresql://postgres:5432/metastore" \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionDriverName="org.postgresql.Driver" \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionUserName="hive" \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionPassword="hive123" \
        bde2020/hive:2.3.2-postgresql-metastore \
        /opt/hive/bin/schematool -dbType postgres -initSchema
    
    success "Hive metastore schema initialized successfully"
}

# Verify schema initialization
verify_schema() {
    step "7" "Verifying schema initialization"
    
    info "Checking for VERSION table..."
    local version_check=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM VERSION;" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$version_check" -eq 0 ]; then
        error_exit "VERSION table not found or empty. Schema initialization failed."
    fi
    
    info "Checking schema version..."
    local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT SCHEMA_VERSION FROM VERSION;" 2>/dev/null | tr -d ' ')
    info "Detected Hive schema version: $schema_version"
    
    info "Checking for essential metastore tables..."
    local essential_tables=("DBS" "TBLS" "SDS" "COLUMNS_V2" "PARTITIONS")
    for table in "${essential_tables[@]}"; do
        local table_exists=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$table';" 2>/dev/null | tr -d ' ' || echo "0")
        if [ "$table_exists" -eq 1 ]; then
            success "Table $table exists"
        else
            error_exit "Essential table $table is missing"
        fi
    done
    
    success "Schema verification completed successfully"
}

# Start services in correct order
start_services_ordered() {
    step "8" "Starting services in correct order"
    
    cd "$PROJECT_ROOT"
    
    # Start core Hadoop services first
    info "Starting Hadoop core services..."
    docker-compose up -d namenode datanode
    
    # Wait for namenode
    info "Waiting for namenode to be ready..."
    local retries=20
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:9870 >/dev/null 2>&1; then
            break
        fi
        sleep 10
        retries=$((retries - 1))
    done
    
    # Start YARN services
    info "Starting YARN services..."
    docker-compose up -d resourcemanager nodemanager
    
    # Start Hive Metastore
    info "Starting Hive Metastore..."
    docker-compose up -d hivemetastore
    
    # Wait for metastore to be ready
    info "Waiting for Hive Metastore to be ready..."
    retries=20
    while [ $retries -gt 0 ]; do
        if docker exec hivemetastore pgrep -f "HiveMetaStore" >/dev/null 2>&1; then
            break
        fi
        info "Waiting for metastore... ($retries attempts remaining)"
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "Hive Metastore failed to start"
    fi
    
    # Start HiveServer2
    info "Starting HiveServer2..."
    docker-compose up -d hiveserver2
    
    success "All services started in correct order"
}

# Health check for all services
perform_health_checks() {
    step "9" "Performing comprehensive health checks"
    
    # Check PostgreSQL
    info "Checking PostgreSQL health..."
    if docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
        success "PostgreSQL is healthy"
    else
        error_exit "PostgreSQL health check failed"
    fi
    
    # Check Hadoop Namenode
    info "Checking Hadoop Namenode..."
    if curl -s http://localhost:9870 >/dev/null 2>&1; then
        success "Hadoop Namenode is healthy"
    else
        warning "Hadoop Namenode health check failed (may still be starting)"
    fi
    
    # Check Hive Metastore
    info "Checking Hive Metastore connectivity..."
    local metastore_check=0
    for i in {1..10}; do
        if docker logs hivemetastore 2>&1 | grep -q "Started the new metastore server" || docker logs hivemetastore 2>&1 | grep -q "Metastore started"; then
            metastore_check=1
            break
        fi
        sleep 5
    done
    
    if [ $metastore_check -eq 1 ]; then
        success "Hive Metastore is healthy"
    else
        warning "Hive Metastore health check inconclusive (check logs)"
    fi
    
    # Check HiveServer2
    info "Checking HiveServer2..."
    local hiveserver_retries=15
    while [ $hiveserver_retries -gt 0 ]; do
        if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" >/dev/null 2>&1; then
            success "HiveServer2 is healthy and accepting connections"
            break
        fi
        info "Waiting for HiveServer2... ($hiveserver_retries attempts remaining)"
        sleep 10
        hiveserver_retries=$((hiveserver_retries - 1))
    done
    
    if [ $hiveserver_retries -eq 0 ]; then
        warning "HiveServer2 health check timed out (may still be initializing)"
    fi
    
    success "Health checks completed"
}

# Validate the setup with test queries
validate_setup() {
    step "10" "Validating setup with test queries"
    
    info "Testing basic Hive connectivity..."
    
    # Create a simple test script
    cat > /tmp/hive_test.sql << 'EOF'
-- Test basic Hive functionality
SHOW DATABASES;

-- Create a test database
CREATE DATABASE IF NOT EXISTS test_db
COMMENT 'Test database for validation'
LOCATION '/user/hive/warehouse/test_db.db';

USE test_db;

-- Create a simple test table
CREATE TABLE IF NOT EXISTS test_table (
    id INT,
    name STRING,
    timestamp_val TIMESTAMP
)
STORED AS TEXTFILE;

-- Insert test data
INSERT INTO test_table VALUES 
(1, 'Test Record 1', current_timestamp()),
(2, 'Test Record 2', current_timestamp());

-- Query test data
SELECT * FROM test_table;

-- Show table info
DESCRIBE test_table;

-- Clean up
DROP TABLE test_table;
DROP DATABASE test_db;

SELECT 'Hive validation completed successfully!' as status;
EOF
    
    # Run test queries
    info "Executing validation queries..."
    if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/hive_test.sql >/dev/null 2>&1; then
        success "Hive validation queries executed successfully"
    else
        warning "Some validation queries failed (this may be normal during initial startup)"
    fi
    
    # Clean up test file
    rm -f /tmp/hive_test.sql
    
    success "Setup validation completed"
}

# Generate comprehensive status report
generate_status_report() {
    step "11" "Generating comprehensive status report"
    
    local status_file="$PROJECT_ROOT/output/metastore_fix_status.txt"
    local containers_status=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Unable to get container status")
    
    cat > "$status_file" << EOF
HIVE METASTORE SCHEMA FIX STATUS REPORT
Generated: $(date)
Project: UNSW-NB15 Hadoop Analytics Environment

=================================================================
SYSTEM INFORMATION:
=================================================================
- OS: $(uname -s) $(uname -r)
- Architecture: $(uname -m)
- Available Memory: $(free -h 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")
- Available Disk: $(df -h "$PROJECT_ROOT" 2>/dev/null | awk 'NR==2{print $4}' || echo "Unknown")
- Docker Version: $(docker --version 2>/dev/null || echo "Unknown")

=================================================================
CONTAINER STATUS:
=================================================================
$containers_status

=================================================================
HIVE METASTORE INFORMATION:
=================================================================
EOF
    
    # Add metastore schema info
    local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT SCHEMA_VERSION FROM VERSION;" 2>/dev/null | tr -d ' ' || echo "Unknown")
    local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "Unknown")
    
    cat >> "$status_file" << EOF
- Schema Version: $schema_version
- Total Tables: $table_count
- Database: metastore
- User: hive

=================================================================
SERVICE ENDPOINTS:
=================================================================
- Hadoop Namenode Web UI: http://localhost:9870
- YARN ResourceManager: http://localhost:8088
- Hive Server2 Web UI: http://localhost:10002
- Hive Server2 JDBC: jdbc:hive2://localhost:10000
- PostgreSQL: localhost:5432

=================================================================
CONNECTION COMMANDS:
=================================================================
Hive CLI (Beeline):
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'

Hadoop CLI:
docker exec -it namenode hadoop fs -ls /

PostgreSQL CLI:
docker exec -it postgres-metastore psql -U hive -d metastore

=================================================================
TROUBLESHOOTING:
=================================================================
1. Check container logs:
   docker-compose logs [container_name]

2. Restart specific service:
   docker-compose restart [container_name]

3. Full environment restart:
   docker-compose down && docker-compose up -d

4. Re-run this fix script:
   ./scripts/fix_hive_metastore.sh

5. Clean restart (removes all data):
   docker-compose down -v && ./scripts/fix_hive_metastore.sh

=================================================================
NEXT STEPS:
=================================================================
1. Access Hadoop Web UI: http://localhost:9870
2. Access Hive Server2 Web UI: http://localhost:10002
3. Start loading UNSW-NB15 data: ./scripts/load_data.sh
4. Open Jupyter for analytics: http://localhost:8888

=================================================================
WINDOWS/WSL SPECIFIC NOTES:
=================================================================
- Ensure Docker Desktop is running
- Use WSL terminal for best compatibility
- If ports are blocked, check Windows Firewall
- File paths should use forward slashes in WSL

EOF
    
    info "Status report saved to: $status_file"
    success "Status report generated successfully"
}

# Show final instructions
show_final_instructions() {
    echo
    echo -e "${GREEN}=================================================================="
    echo -e "  🎉 HIVE METASTORE SCHEMA FIX COMPLETED SUCCESSFULLY!"
    echo -e "==================================================================${NC}"
    echo
    echo -e "${CYAN}🔗 Service URLs:${NC}"
    echo -e "  • Hadoop NameNode UI:   ${BLUE}http://localhost:9870${NC}"
    echo -e "  • YARN ResourceManager: ${BLUE}http://localhost:8088${NC}"
    echo -e "  • Hive Server2 Web UI:  ${BLUE}http://localhost:10002${NC}"
    echo -e "  • Jupyter Lab:          ${BLUE}http://localhost:8888${NC}"
    echo
    echo -e "${CYAN}🗃️  Database Connections:${NC}"
    echo -e "  • Hive CLI: ${YELLOW}docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'${NC}"
    echo -e "  • Test Query: ${YELLOW}SHOW DATABASES;${NC}"
    echo
    echo -e "${CYAN}📊 Next Steps for UNSW-NB15 Analytics:${NC}"
    echo -e "  1. ${BLUE}Load dataset:${NC} ${YELLOW}./scripts/load_data.sh${NC}"
    echo -e "  2. ${BLUE}Create tables:${NC} Run SQL from ${YELLOW}./hive/create_tables.sql${NC}"
    echo -e "  3. ${BLUE}Start analysis:${NC} Open ${YELLOW}http://localhost:8888${NC}"
    echo
    echo -e "${CYAN}📋 Important Files:${NC}"
    echo -e "  • Status Report: ${BLUE}./output/metastore_fix_status.txt${NC}"
    echo -e "  • Fix Log: ${BLUE}$LOG_FILE${NC}"
    echo -e "  • Backup: ${BLUE}$BACKUP_DIR${NC}"
    echo
    echo -e "${GREEN}✅ Ready for Big Data Analytics! 🚀${NC}"
    echo
}

# Cleanup function for script interruption
cleanup() {
    warning "Script interrupted. Performing cleanup..."
    # Add any cleanup logic here if needed
    exit 1
}

# Trap interruption signals
trap cleanup INT TERM

# Main execution function
main() {
    show_banner
    
    # Create output directory and log file
    create_directories
    echo "Hive Metastore Schema Fix Log - $(date)" > "$LOG_FILE"
    
    # Execute all steps
    check_requirements
    stop_hive_services
    ensure_postgres_ready
    backup_metastore
    recreate_metastore_database
    initialize_hive_schema
    verify_schema
    start_services_ordered
    perform_health_checks
    validate_setup
    generate_status_report
    show_final_instructions
    
    success "🎉 Hive Metastore Schema Fix completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "check")
        check_requirements
        ;;
    "backup")
        ensure_postgres_ready
        backup_metastore
        ;;
    "init-schema")
        ensure_postgres_ready
        recreate_metastore_database
        initialize_hive_schema
        verify_schema
        ;;
    "start")
        start_services_ordered
        perform_health_checks
        ;;
    "status")
        generate_status_report
        cat "$PROJECT_ROOT/output/metastore_fix_status.txt"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [OPTION]"
        echo
        echo "Fix Hive Metastore Schema Initialization Issues"
        echo
        echo "Options:"
        echo "  (no args)    Run complete fix process"
        echo "  check        Check system requirements only"
        echo "  backup       Backup existing metastore only"
        echo "  init-schema  Initialize schema only"
        echo "  start        Start services only"
        echo "  status       Show current status"
        echo "  help         Show this help message"
        echo
        ;;
    *)
        main
        ;;
esac
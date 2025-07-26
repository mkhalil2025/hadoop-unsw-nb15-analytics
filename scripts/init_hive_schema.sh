#!/bin/bash

# Hive Metastore Schema Initialization Script
# UEL-CN-7031 Big Data Analytics - UNSW-NB15 Project
#
# This script provides a robust, idempotent initialization of the Hive metastore schema
# for PostgreSQL 15, supporting Hive 2.3.2. It includes proper error handling and 
# can be run multiple times safely.
#
# Usage: ./init_hive_schema.sh [--force] [--dry-run] [--verbose]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/output/schema_init.log"

# Options
FORCE_INIT=false
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Docker Compose wrapper function for v1/v2 compatibility
docker_compose() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Get the correct Docker network name
get_docker_network() {
    local project_name=$(basename "$PROJECT_ROOT")
    local networks=(
        "${project_name}_hadoop-network"
        "${project_name}_default"
        "hadoop-network"
        "default"
    )
    
    for network in "${networks[@]}"; do
        if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
            echo "$network"
            return 0
        fi
    done
    
    # Default fallback
    echo "${project_name}_default"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_INIT=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    echo "Hive Metastore Schema Initialization Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --force     Force re-initialization even if schema exists"
    echo "  --dry-run   Show what would be done without executing"
    echo "  --verbose   Enable verbose logging"
    echo "  --help, -h  Show this help message"
    echo
    echo "This script initializes the Hive metastore schema in PostgreSQL 15"
    echo "and is idempotent (safe to run multiple times)."
}

# Logging functions
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp] $message${NC}"
    [ "$VERBOSE" = true ] && echo "[$timestamp] $message" >> "$LOG_FILE"
}

error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR] $message${NC}" >&2
    echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
}

success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS] $message${NC}"
    [ "$VERBOSE" = true ] && echo "[$timestamp] SUCCESS: $message" >> "$LOG_FILE"
}

warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING] $message${NC}"
    echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
}

info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[INFO] $message${NC}"
    [ "$VERBOSE" = true ] && echo "[$timestamp] INFO: $message" >> "$LOG_FILE"
}

# Execute command with dry-run support
execute() {
    local description="$1"
    shift
    local command="$@"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${PURPLE}[DRY-RUN] $description${NC}"
        echo -e "${PURPLE}  Command: $command${NC}"
        return 0
    else
        log "$description"
        eval "$command"
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        return 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
        return 1
    fi
    
    # Check if we're in the correct directory
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        error "docker-compose.yml not found. Please run this script from the project root."
        return 1
    fi
    
    success "Prerequisites check passed"
    return 0
}

# Ensure PostgreSQL is running and ready
ensure_postgres_ready() {
    log "Ensuring PostgreSQL is running and ready..."
    
    cd "$PROJECT_ROOT"
    
    # Start PostgreSQL if not running
    execute "Starting PostgreSQL" "docker_compose up -d postgres"
    
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    # Wait for PostgreSQL to be ready
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
        error "PostgreSQL failed to start within timeout"
        return 1
    fi
    
    success "PostgreSQL is ready"
    return 0
}

# Check if schema already exists
check_existing_schema() {
    log "Checking for existing schema..."
    
    if [ "$DRY_RUN" = true ]; then
        info "Dry-run mode: would check for existing schema"
        return 1  # Assume schema doesn't exist for dry-run
    fi
    
    # Check if VERSION table exists and has data
    local version_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM VERSION;" 2>/dev/null | tr -d ' ' || echo "0")
    
    # Handle empty or invalid response
    if [[ ! "$version_count" =~ ^[0-9]+$ ]]; then
        version_count=0
    fi
    
    if [ "$version_count" -gt 0 ]; then
        local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ')
        info "Existing schema found (version: $schema_version)"
        
        if [ "$FORCE_INIT" = false ]; then
            warning "Schema already exists. Use --force to re-initialize"
            return 0  # Schema exists, no need to initialize
        else
            warning "Force mode enabled, will re-initialize schema"
            return 1  # Schema exists but force mode, proceed with initialization
        fi
    else
        info "No existing schema found"
        return 1  # No schema, proceed with initialization
    fi
}

# Backup existing schema if it exists
backup_existing_schema() {
    log "Creating backup of existing schema..."
    
    local backup_dir="$PROJECT_ROOT/output/backups/$(date +%Y%m%d_%H%M%S)"
    execute "Creating backup directory" "mkdir -p '$backup_dir'"
    
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    # Check if there's anything to backup
    local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
    
    # Handle empty or invalid response
    if [[ ! "$table_count" =~ ^[0-9]+$ ]]; then
        table_count=0
    fi
    
    if [ "$table_count" -gt 0 ]; then
        execute "Backing up existing metastore data" "docker exec postgres-metastore pg_dump -U hive metastore > '$backup_dir/metastore_backup.sql'"
        success "Backup saved to: $backup_dir/metastore_backup.sql"
    else
        info "No existing data to backup"
    fi
}

# Clean and recreate metastore database
prepare_database() {
    log "Preparing metastore database..."
    
    execute "Dropping existing metastore database" "docker exec postgres-metastore psql -U hive -d postgres -c 'DROP DATABASE IF EXISTS metastore;'"
    execute "Creating fresh metastore database" "docker exec postgres-metastore psql -U hive -d postgres -c 'CREATE DATABASE metastore;'"
    execute "Granting privileges" "docker exec postgres-metastore psql -U hive -d postgres -c 'GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;'"
    
    success "Database prepared successfully"
}

# Initialize schema using schematool
initialize_schema() {
    log "Initializing Hive metastore schema..."
    
    cd "$PROJECT_ROOT"
    
    # Ensure Hadoop services are available for schema initialization
    execute "Starting Hadoop services" "docker_compose up -d namenode datanode"
    
    if [ "$DRY_RUN" = false ]; then
        # Wait a bit for services to be ready
        sleep 10
    fi
    
    # Get the Docker network
    local docker_network
    if [ "$DRY_RUN" = true ]; then
        docker_network="example_network"
    else
        docker_network=$(get_docker_network)
    fi
    
    info "Using Docker network: $docker_network"
    
    # Run schematool with enhanced error handling
    local schematool_cmd="docker run --rm \
        --network '$docker_network' \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionURL='jdbc:postgresql://postgres:5432/metastore' \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionDriverName='org.postgresql.Driver' \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionUserName='hive' \
        -e HIVE_CORE_CONF_javax_jdo_option_ConnectionPassword='hive123' \
        bde2020/hive:2.3.2-postgresql-metastore \
        /opt/hive/bin/schematool -dbType postgres -initSchema"
    
    execute "Running Hive schematool" "$schematool_cmd"
    
    success "Schema initialization completed"
}

# Verify schema initialization
verify_schema_initialization() {
    log "Verifying schema initialization..."
    
    if [ "$DRY_RUN" = true ]; then
        info "Dry-run mode: would verify schema initialization"
        return 0
    fi
    
    # Check VERSION table
    local version_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM VERSION;" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$version_count" -eq 0 ]; then
        error "VERSION table not found or empty"
        return 1
    fi
    
    # Get schema version
    local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ')
    success "VERSION table created with schema version: $schema_version"
    
    # Check essential tables
    local essential_tables=("DBS" "TBLS" "SDS" "COLUMNS_V2" "PARTITIONS" "TABLE_PARAMS")
    local missing_tables=()
    
    for table in "${essential_tables[@]}"; do
        local table_exists=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$table';" 2>/dev/null | tr -d ' ' || echo "0")
        
        if [ "$table_exists" -eq 1 ]; then
            success "✓ Table $table exists"
        else
            missing_tables+=("$table")
            error "✗ Table $table is missing"
        fi
    done
    
    if [ ${#missing_tables[@]} -gt 0 ]; then
        error "Schema verification failed: Missing tables: ${missing_tables[*]}"
        return 1
    fi
    
    # Count total tables
    local total_tables=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
    success "Schema verification passed: $total_tables tables created"
    
    return 0
}

# Generate status report
generate_status_report() {
    log "Generating status report..."
    
    local status_file="$PROJECT_ROOT/output/schema_init_status.txt"
    local timestamp=$(date)
    
    if [ "$DRY_RUN" = true ]; then
        info "Dry-run mode: would generate status report at $status_file"
        return 0
    fi
    
    cat > "$status_file" << EOF
HIVE METASTORE SCHEMA INITIALIZATION STATUS
Generated: $timestamp

=================================================================
INITIALIZATION RESULTS:
=================================================================
EOF
    
    # Add schema information
    local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ' || echo "Unknown")
    local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "Unknown")
    
    cat >> "$status_file" << EOF
- Schema Version: $schema_version
- Total Tables Created: $table_count
- Database: metastore
- User: hive
- PostgreSQL Version: 15

=================================================================
NEXT STEPS:
=================================================================
1. Start Hive services:
   ./scripts/fix_hive_metastore.sh start

2. Verify schema:
   ./scripts/verify_hive_schema.sh

3. Test connectivity:
   docker exec hiveserver2 beeline -u 'jdbc:hive2://localhost:10000' -e 'SHOW DATABASES;'

=================================================================
TROUBLESHOOTING:
=================================================================
- If services fail to start, check logs: docker_compose logs
- To re-initialize schema: $0 --force
- For comprehensive fix: ./scripts/fix_hive_metastore.sh

EOF
    
    success "Status report saved to: $status_file"
}

# Show summary
show_summary() {
    echo
    echo -e "${CYAN}=================================="
    echo -e "  SCHEMA INITIALIZATION SUMMARY"
    echo -e "==================================${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${PURPLE}Mode: DRY-RUN (no changes made)${NC}"
    else
        echo -e "${GREEN}Mode: EXECUTE${NC}"
    fi
    
    echo -e "Force: $FORCE_INIT"
    echo -e "Verbose: $VERBOSE"
    
    if [ "$DRY_RUN" = false ]; then
        local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ' || echo "Unknown")
        local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "Unknown")
        
        echo -e "Schema Version: ${GREEN}$schema_version${NC}"
        echo -e "Tables Created: ${GREEN}$table_count${NC}"
    fi
    
    echo
}

# Main function
main() {
    # Setup
    mkdir -p "$PROJECT_ROOT/output"
    echo "Schema initialization started: $(date)" > "$LOG_FILE"
    
    echo -e "${CYAN}Hive Metastore Schema Initialization${NC}"
    echo -e "${CYAN}====================================${NC}"
    echo
    
    # Parse arguments
    parse_args "$@"
    
    # Show configuration
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}Configuration:${NC}"
        echo -e "  Force: $FORCE_INIT"
        echo -e "  Dry-run: $DRY_RUN"
        echo -e "  Verbose: $VERBOSE"
        echo -e "  Log file: $LOG_FILE"
        echo
    fi
    
    # Execute steps
    check_prerequisites || exit 1
    ensure_postgres_ready || exit 1
    
    # Check if schema exists and whether to proceed
    if check_existing_schema; then
        success "Schema already exists and is valid"
        show_summary
        exit 0
    fi
    
    # Proceed with initialization
    backup_existing_schema || exit 1
    prepare_database || exit 1
    initialize_schema || exit 1
    verify_schema_initialization || exit 1
    generate_status_report || exit 1
    
    # Show final summary
    show_summary
    
    if [ "$DRY_RUN" = false ]; then
        success "Schema initialization completed successfully!"
        echo -e "${GREEN}Ready to start Hive services!${NC}"
    else
        info "Dry-run completed. Use without --dry-run to execute."
    fi
    
    echo
}

# Run main function with all arguments
main "$@"
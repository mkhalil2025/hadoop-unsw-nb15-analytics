#!/bin/bash

# Hive Metastore Schema Verification Script
# UEL-CN-7031 Big Data Analytics - UNSW-NB15 Project
#
# This script verifies that the Hive metastore schema is properly initialized
# before allowing the metastore service to start. This prevents the 
# "Version information not found in metastore" error.
#
# Usage: ./verify_hive_schema.sh [--wait] [--timeout=300]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_TIMEOUT=300  # 5 minutes
WAIT_MODE=false
TIMEOUT=$DEFAULT_TIMEOUT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Docker Compose wrapper function for v1/v2 compatibility
docker_compose() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --wait)
                WAIT_MODE=true
                shift
                ;;
            --timeout=*)
                TIMEOUT="${1#*=}"
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
    echo "Hive Metastore Schema Verification Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --wait              Wait for schema to be available instead of just checking"
    echo "  --timeout=SECONDS   Timeout for wait mode (default: $DEFAULT_TIMEOUT)"
    echo "  --help, -h          Show this help message"
    echo
    echo "Exit codes:"
    echo "  0  Schema is valid and ready"
    echo "  1  Schema verification failed"
    echo "  2  PostgreSQL is not accessible"
    echo "  3  Essential tables are missing"
    echo "  4  Timeout waiting for schema"
}

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if PostgreSQL is accessible
check_postgres_connectivity() {
    log "Checking PostgreSQL connectivity..."
    
    if ! docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
        error "PostgreSQL is not accessible"
        return 2
    fi
    
    success "PostgreSQL is accessible"
    return 0
}

# Check if metastore database exists
check_metastore_database() {
    log "Checking metastore database..."
    
    local db_exists=$(docker exec postgres-metastore psql -U hive -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='metastore';" 2>/dev/null | tr -d ' ' || echo "")
    
    if [ "$db_exists" != "1" ]; then
        error "Metastore database does not exist"
        return 1
    fi
    
    success "Metastore database exists"
    return 0
}

# Check if VERSION table exists and has data
check_version_table() {
    log "Checking VERSION table..."
    
    # Check if VERSION table exists
    local table_exists=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'VERSION';" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$table_exists" -eq 0 ]; then
        error "VERSION table does not exist"
        return 3
    fi
    
    # Check if VERSION table has data
    local version_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM \"VERSION\";" 2>/dev/null | tr -d ' ' || echo "0")
    
    # Handle empty or invalid response
    if [[ ! "$version_count" =~ ^[0-9]+$ ]]; then
        version_count=0
    fi
    
    if [ "$version_count" -eq 0 ]; then
        error "VERSION table is empty"
        return 3
    fi
    
    # Get the schema version
    local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ' || echo "unknown")
    
    success "VERSION table is valid (schema version: $schema_version)"
    return 0
}

# Check essential metastore tables
check_essential_tables() {
    log "Checking essential metastore tables..."
    
    local essential_tables=("DBS" "TBLS" "SDS" "COLUMNS_V2" "PARTITIONS" "TABLE_PARAMS" "SERDE_PARAMS")
    local missing_tables=()
    
    for table in "${essential_tables[@]}"; do
        local table_exists=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$table';" 2>/dev/null | tr -d ' ' || echo "0")
        
        if [ "$table_exists" -eq 0 ]; then
            missing_tables+=("$table")
            warning "Table $table is missing"
        else
            log "✓ Table $table exists"
        fi
    done
    
    if [ ${#missing_tables[@]} -gt 0 ]; then
        error "Missing essential tables: ${missing_tables[*]}"
        return 3
    fi
    
    success "All essential metastore tables exist"
    return 0
}

# Check schema integrity
check_schema_integrity() {
    log "Performing schema integrity check..."
    
    # Count total tables in public schema
    local table_count=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$table_count" -lt 10 ]; then
        error "Schema appears incomplete (only $table_count tables found)"
        return 3
    fi
    
    success "Schema integrity check passed ($table_count tables found)"
    return 0
}

# Perform comprehensive schema verification
verify_schema() {
    log "Starting comprehensive schema verification..."
    
    # Check PostgreSQL connectivity
    check_postgres_connectivity || return $?
    
    # Check metastore database
    check_metastore_database || return $?
    
    # Check VERSION table
    check_version_table || return $?
    
    # Check essential tables
    check_essential_tables || return $?
    
    # Check schema integrity
    check_schema_integrity || return $?
    
    success "Schema verification completed successfully"
    return 0
}

# Wait for schema to be ready (with timeout)
wait_for_schema() {
    log "Waiting for schema to be ready (timeout: ${TIMEOUT}s)..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + TIMEOUT))
    
    while [ $(date +%s) -lt $end_time ]; do
        if verify_schema >/dev/null 2>&1; then
            success "Schema is ready!"
            return 0
        fi
        
        local remaining=$((end_time - $(date +%s)))
        log "Schema not ready yet, waiting... (${remaining}s remaining)"
        sleep 5
    done
    
    error "Timeout waiting for schema to be ready"
    return 4
}

# Show schema status summary
show_schema_status() {
    echo
    echo -e "${CYAN}================================="
    echo -e "  HIVE METASTORE SCHEMA STATUS"
    echo -e "=================================${NC}"
    
    # PostgreSQL status
    if check_postgres_connectivity >/dev/null 2>&1; then
        echo -e "PostgreSQL:      ${GREEN}✓ Connected${NC}"
    else
        echo -e "PostgreSQL:      ${RED}✗ Not accessible${NC}"
    fi
    
    # Database status
    if check_metastore_database >/dev/null 2>&1; then
        echo -e "Database:        ${GREEN}✓ Exists${NC}"
    else
        echo -e "Database:        ${RED}✗ Missing${NC}"
    fi
    
    # VERSION table status
    if check_version_table >/dev/null 2>&1; then
        local schema_version=$(docker exec postgres-metastore psql -U hive -d metastore -t -c "SELECT \"SCHEMA_VERSION\" FROM \"VERSION\";" 2>/dev/null | tr -d ' ' || echo "unknown")
        echo -e "VERSION Table:   ${GREEN}✓ Valid (v${schema_version})${NC}"
    else
        echo -e "VERSION Table:   ${RED}✗ Missing or invalid${NC}"
    fi
    
    # Essential tables status
    if check_essential_tables >/dev/null 2>&1; then
        echo -e "Essential Tables: ${GREEN}✓ All present${NC}"
    else
        echo -e "Essential Tables: ${RED}✗ Some missing${NC}"
    fi
    
    # Schema integrity
    if check_schema_integrity >/dev/null 2>&1; then
        echo -e "Schema Integrity: ${GREEN}✓ Valid${NC}"
    else
        echo -e "Schema Integrity: ${RED}✗ Invalid${NC}"
    fi
    
    echo
}

# Main function
main() {
    parse_args "$@"
    
    echo -e "${CYAN}Hive Metastore Schema Verification${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo
    
    cd "$PROJECT_ROOT"
    
    if [ "$WAIT_MODE" = true ]; then
        wait_for_schema
        local exit_code=$?
    else
        verify_schema
        local exit_code=$?
    fi
    
    echo
    show_schema_status
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}Schema verification: PASSED ✓${NC}"
        echo -e "${GREEN}Metastore is ready to start!${NC}"
    else
        echo -e "${RED}Schema verification: FAILED ✗${NC}"
        echo -e "${YELLOW}Run the fix script: ./scripts/fix_hive_metastore.sh${NC}"
    fi
    
    echo
    exit $exit_code
}

# Run main function with all arguments
main "$@"
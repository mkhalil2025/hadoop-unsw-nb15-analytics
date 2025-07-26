#!/bin/bash

# Hive Metastore Startup Script with Schema Verification
# UEL-CN-7031 Big Data Analytics - UNSW-NB15 Project
#
# This script ensures the Hive metastore schema is properly initialized
# before starting the metastore service. It prevents the common
# "Version information not found in metastore" error.
#
# Usage: ./start_hive_metastore.sh [--wait-timeout=300] [--force-schema-init]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WAIT_TIMEOUT=300  # 5 minutes
FORCE_SCHEMA_INIT=false

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
            --wait-timeout=*)
                WAIT_TIMEOUT="${1#*=}"
                shift
                ;;
            --force-schema-init)
                FORCE_SCHEMA_INIT=true
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
    echo "Hive Metastore Startup Script with Schema Verification"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --wait-timeout=SECONDS    Timeout for schema verification (default: 300)"
    echo "  --force-schema-init       Force schema initialization if verification fails"
    echo "  --help, -h                Show this help message"
    echo
    echo "This script:"
    echo "1. Verifies that the Hive metastore schema is properly initialized"
    echo "2. Initializes the schema if it's missing or corrupted"
    echo "3. Starts all Hive services in the correct order"
    echo "4. Performs health checks to ensure everything is working"
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

info() {
    echo -e "${CYAN}[INFO] $1${NC}"
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "  🚀 HIVE METASTORE STARTUP WITH SCHEMA VERIFICATION"
    echo "  UEL-CN-7031 Big Data Analytics - UNSW-NB15 Project"
    echo "=================================================================="
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if we're in the correct directory
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        error "docker-compose.yml not found. Please run this script from the project root."
        return 1
    fi
    
    # Check if verification script exists
    if [ ! -f "$SCRIPT_DIR/verify_hive_schema.sh" ]; then
        error "Schema verification script not found at $SCRIPT_DIR/verify_hive_schema.sh"
        return 1
    fi
    
    # Check if initialization script exists
    if [ ! -f "$SCRIPT_DIR/init_hive_schema.sh" ]; then
        error "Schema initialization script not found at $SCRIPT_DIR/init_hive_schema.sh"
        return 1
    fi
    
    success "Prerequisites check passed"
    return 0
}

# Stop all Hive services cleanly
stop_hive_services() {
    log "Stopping existing Hive services..."
    
    cd "$PROJECT_ROOT"
    
    # Stop Hive services gracefully
    docker_compose stop hiveserver2 2>/dev/null || true
    docker_compose stop hivemetastore 2>/dev/null || true
    
    # Wait for graceful shutdown
    sleep 5
    
    # Force stop if needed
    docker stop hiveserver2 hivemetastore 2>/dev/null || true
    
    success "Hive services stopped"
}

# Ensure core services are running
ensure_core_services() {
    log "Ensuring core services are running..."
    
    cd "$PROJECT_ROOT"
    
    # Start PostgreSQL
    docker_compose up -d postgres
    
    # Start Hadoop core services
    docker_compose up -d namenode datanode
    
    # Wait for PostgreSQL to be ready
    log "Waiting for PostgreSQL..."
    local retries=30
    while [ $retries -gt 0 ]; do
        if docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
            break
        fi
        sleep 5
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error "PostgreSQL failed to start"
        return 1
    fi
    
    # Wait for Namenode to be ready
    log "Waiting for Hadoop Namenode..."
    retries=20
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
    
    success "Core services are running"
}

# Verify schema or initialize if needed
verify_or_initialize_schema() {
    log "Verifying metastore schema..."
    
    cd "$PROJECT_ROOT"
    
    # Run schema verification
    if "$SCRIPT_DIR/verify_hive_schema.sh" >/dev/null 2>&1; then
        success "Schema verification passed"
        return 0
    else
        warning "Schema verification failed"
        
        if [ "$FORCE_SCHEMA_INIT" = true ]; then
            log "Force schema initialization enabled, initializing schema..."
            if "$SCRIPT_DIR/init_hive_schema.sh" --force; then
                success "Schema initialization completed"
                return 0
            else
                error "Schema initialization failed"
                return 1
            fi
        else
            error "Schema is not properly initialized"
            error "Run with --force-schema-init to automatically initialize"
            error "Or manually run: ./scripts/init_hive_schema.sh"
            return 1
        fi
    fi
}

# Start Hive services in correct order
start_hive_services() {
    log "Starting Hive services..."
    
    cd "$PROJECT_ROOT"
    
    # Start YARN services
    log "Starting YARN services..."
    docker_compose up -d resourcemanager nodemanager
    
    # Start Hive Metastore
    log "Starting Hive Metastore..."
    docker_compose up -d hivemetastore
    
    # Wait for metastore to be ready
    log "Waiting for Hive Metastore to start..."
    local retries=20
    while [ $retries -gt 0 ]; do
        if docker logs hivemetastore 2>&1 | grep -q "Started the new metastore server" || \
           docker logs hivemetastore 2>&1 | grep -q "Metastore started" || \
           docker exec hivemetastore pgrep -f "HiveMetaStore" >/dev/null 2>&1; then
            break
        fi
        info "Waiting for metastore... ($retries attempts remaining)"
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error "Hive Metastore failed to start"
        return 1
    fi
    
    # Start HiveServer2
    log "Starting HiveServer2..."
    docker_compose up -d hiveserver2
    
    success "Hive services started"
}

# Perform health checks
perform_health_checks() {
    log "Performing health checks..."
    
    # Check PostgreSQL
    if docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
        success "✓ PostgreSQL is healthy"
    else
        error "✗ PostgreSQL health check failed"
        return 1
    fi
    
    # Check Hadoop Namenode
    if curl -s http://localhost:9870 >/dev/null 2>&1; then
        success "✓ Hadoop Namenode is healthy"
    else
        warning "⚠ Hadoop Namenode health check failed"
    fi
    
    # Check Hive Metastore
    local metastore_retries=10
    while [ $metastore_retries -gt 0 ]; do
        if docker logs hivemetastore 2>&1 | grep -q "Started the new metastore server" || \
           docker logs hivemetastore 2>&1 | grep -q "Metastore started"; then
            success "✓ Hive Metastore is healthy"
            break
        fi
        sleep 5
        metastore_retries=$((metastore_retries - 1))
    done
    
    if [ $metastore_retries -eq 0 ]; then
        warning "⚠ Hive Metastore health check inconclusive"
    fi
    
    # Check HiveServer2
    log "Testing HiveServer2 connectivity..."
    local hiveserver_retries=15
    while [ $hiveserver_retries -gt 0 ]; do
        if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" >/dev/null 2>&1; then
            success "✓ HiveServer2 is healthy and accepting connections"
            return 0
        fi
        info "Waiting for HiveServer2... ($hiveserver_retries attempts remaining)"
        sleep 10
        hiveserver_retries=$((hiveserver_retries - 1))
    done
    
    warning "⚠ HiveServer2 health check timed out (may still be initializing)"
    return 0
}

# Show final status
show_final_status() {
    echo
    echo -e "${GREEN}=================================================================="
    echo -e "  🎉 HIVE METASTORE STARTUP COMPLETED!"
    echo -e "==================================================================${NC}"
    echo
    echo -e "${CYAN}🔗 Service URLs:${NC}"
    echo -e "  • Hadoop NameNode UI:   ${BLUE}http://localhost:9870${NC}"
    echo -e "  • YARN ResourceManager: ${BLUE}http://localhost:8088${NC}"
    echo -e "  • Hive Server2 Web UI:  ${BLUE}http://localhost:10002${NC}"
    echo -e "  • Jupyter Lab:          ${BLUE}http://localhost:8888${NC}"
    echo
    echo -e "${CYAN}🗃️  Test Connection:${NC}"
    echo -e "  ${YELLOW}docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'${NC}"
    echo -e "  ${YELLOW}SHOW DATABASES;${NC}"
    echo
    echo -e "${CYAN}📊 Next Steps:${NC}"
    echo -e "  1. Load UNSW-NB15 dataset: ${YELLOW}./scripts/load_data.sh${NC}"
    echo -e "  2. Create tables: Run SQL from ${YELLOW}./hive/create_tables.sql${NC}"
    echo -e "  3. Start analytics: Open ${YELLOW}http://localhost:8888${NC}"
    echo
    echo -e "${GREEN}✅ Ready for Big Data Analytics! 🚀${NC}"
    echo
}

# Main function
main() {
    parse_args "$@"
    
    show_banner
    
    cd "$PROJECT_ROOT"
    
    # Execute startup sequence
    check_prerequisites || exit 1
    stop_hive_services || exit 1
    ensure_core_services || exit 1
    verify_or_initialize_schema || exit 1
    start_hive_services || exit 1
    perform_health_checks || exit 1
    show_final_status
    
    success "Hive Metastore startup completed successfully!"
}

# Run main function with all arguments
main "$@"
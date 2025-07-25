#!/bin/bash

# UNSW-NB15 Hadoop Analytics Environment Setup Script
# UEL-CN-7031 Big Data Analytics Assignment
# One-command setup for complete analytics environment

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/output/setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "  UNSW-NB15 Big Data Analytics Environment Setup"
    echo "  UEL-CN-7031 Hadoop & Hive Analytics Platform"
    echo "=================================================================="
    echo -e "${NC}"
}

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}Setup failed. Check log at: $LOG_FILE${NC}"
    exit 1
}

# Success message function
success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

# Warning message function
warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

# Info message function
info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

# Progress indicator
progress() {
    echo -e "${CYAN}➤ $1${NC}" | tee -a "$LOG_FILE"
}

# Check system requirements
check_requirements() {
    progress "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed. Please install Docker first."
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error_exit "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check available memory
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$total_mem" -lt 8 ]; then
        warning "System has less than 8GB RAM. Performance may be limited."
    fi
    
    # Check available disk space (at least 10GB)
    local available_space=$(df "$PROJECT_ROOT" | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$available_space" -lt 10 ]; then
        warning "Less than 10GB disk space available. Consider freeing up space."
    fi
    
    # Check if ports are available
    local ports=(5432 8020 8088 9870 9864 10000 10002 8888)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            warning "Port $port is already in use. This may cause conflicts."
        fi
    done
    
    success "System requirements check completed"
}

# Create necessary directories
create_directories() {
    progress "Creating project directories..."
    
    local dirs=(
        "$PROJECT_ROOT/data"
        "$PROJECT_ROOT/output"
        "$PROJECT_ROOT/output/logs"
        "$PROJECT_ROOT/output/results"
        "$PROJECT_ROOT/output/visualizations"
        "$PROJECT_ROOT/notebooks/data_exploration"
        "$PROJECT_ROOT/notebooks/machine_learning"
        "$PROJECT_ROOT/notebooks/visualization"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        info "Created directory: $dir"
    done
    
    success "Project directories created"
}

# Setup environment file
setup_environment() {
    progress "Setting up environment configuration..."
    
    # Check if .env exists and backup if it does
    if [ -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env" "$PROJECT_ROOT/.env.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backed up existing .env file"
    fi
    
    # Detect system memory and adjust settings
    local total_mem_gb=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    local yarn_memory=4096
    local max_allocation=4096
    
    if [ "$total_mem_gb" -ge 16 ]; then
        yarn_memory=8192
        max_allocation=8192
    elif [ "$total_mem_gb" -ge 12 ]; then
        yarn_memory=6144
        max_allocation=6144
    fi
    
    info "Detected ${total_mem_gb}GB RAM, configuring YARN with ${yarn_memory}MB"
    
    # Update .env file with detected settings
    sed -i "s/YARN_NODEMANAGER_RESOURCE_MEMORY_MB=.*/YARN_NODEMANAGER_RESOURCE_MEMORY_MB=$yarn_memory/" "$PROJECT_ROOT/.env"
    sed -i "s/YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=.*/YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=$max_allocation/" "$PROJECT_ROOT/.env"
    
    success "Environment configuration updated"
}

# Pull Docker images
pull_images() {
    progress "Pulling required Docker images..."
    
    local images=(
        "postgres:13"
        "apache/hadoop:3.3.4"
        "apache/hive:3.1.3"
        "jupyter/pyspark-notebook:latest"
    )
    
    for image in "${images[@]}"; do
        info "Pulling $image..."
        docker pull "$image" || warning "Failed to pull $image, will try during compose up"
    done
    
    success "Docker images pulled"
}

# Start services
start_services() {
    progress "Starting Hadoop ecosystem services..."
    
    cd "$PROJECT_ROOT"
    
    # Stop any existing containers
    docker-compose down -v 2>/dev/null || true
    
    # Start services
    info "Starting services with docker-compose..."
    docker-compose up -d
    
    success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    progress "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    info "Waiting for PostgreSQL metastore..."
    local retries=30
    while [ $retries -gt 0 ]; do
        if docker exec postgres-metastore pg_isready -U hive >/dev/null 2>&1; then
            break
        fi
        sleep 5
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "PostgreSQL metastore failed to start"
    fi
    
    # Wait for Namenode
    info "Waiting for Hadoop Namenode..."
    retries=30
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:9870 >/dev/null 2>&1; then
            break
        fi
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "Hadoop Namenode failed to start"
    fi
    
    # Wait for HiveServer2
    info "Waiting for HiveServer2..."
    retries=20
    while [ $retries -gt 0 ]; do
        if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" >/dev/null 2>&1; then
            break
        fi
        sleep 15
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "HiveServer2 failed to start"
    fi
    
    success "All services are ready"
}

# Load sample data
load_sample_data() {
    progress "Loading sample UNSW-NB15 data..."
    
    # Run data loading script
    "$SCRIPT_DIR/load_data.sh" || error_exit "Failed to load sample data"
    
    success "Sample data loaded successfully"
}

# Setup Jupyter notebooks
setup_notebooks() {
    progress "Setting up Jupyter notebooks..."
    
    # Install additional packages in Jupyter container
    docker exec jupyter-analytics pip install --quiet \
        pyhive[hive] \
        thrift \
        sasl \
        thrift_sasl \
        matplotlib \
        seaborn \
        plotly \
        scikit-learn \
        pandas \
        numpy \
        hdfs3 >/dev/null 2>&1 || warning "Some packages may not have installed correctly"
    
    success "Jupyter environment configured"
}

# Create documentation
create_documentation() {
    progress "Creating documentation files..."
    
    # Create README files for directories
    cat > "$PROJECT_ROOT/data/README.md" << 'EOF'
# UNSW-NB15 Dataset Directory

This directory contains the UNSW-NB15 cybersecurity dataset files.

## Dataset Information
- **Source**: University of New South Wales (UNSW)
- **Purpose**: Network intrusion detection evaluation
- **Records**: ~2.5 million network flow records
- **Features**: 49 features including flow statistics, service information, and attack labels

## Files
- `UNSW_NB15_sample.csv`: Sample dataset for testing (generated if original not available)
- Original dataset files (if downloaded)

## Download Instructions
1. Visit: https://research.unsw.edu.au/projects/unsw-nb15-dataset
2. Download the training and testing CSV files
3. Place them in this directory
4. Run: `./scripts/load_data.sh` to reload with real data

## Data Format
CSV files with 49 columns including:
- Network flow features (srcip, dstip, proto, service, etc.)
- Statistical features (bytes, packets, duration, etc.)
- Attack labels (binary and categorical)
EOF
    
    cat > "$PROJECT_ROOT/output/README.md" << 'EOF'
# Output Directory

This directory contains results from analytics queries and visualizations.

## Structure
- `logs/`: System and application logs
- `results/`: Query results and analysis outputs
- `visualizations/`: Generated charts and graphs

## Usage
Query results are automatically saved here when running analytics scripts.
EOF
    
    success "Documentation created"
}

# Generate status report
generate_status_report() {
    progress "Generating setup status report..."
    
    local status_file="$PROJECT_ROOT/output/setup_status.txt"
    
    cat > "$status_file" << EOF
UNSW-NB15 Hadoop Analytics Environment Setup Report
Generated: $(date)

SYSTEM INFORMATION:
- OS: $(uname -s)
- Architecture: $(uname -m)
- Available Memory: $(free -h | awk 'NR==2{print $2}')
- Available Disk: $(df -h "$PROJECT_ROOT" | awk 'NR==2{print $4}')

CONTAINER STATUS:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

SERVICE ENDPOINTS:
- Hadoop Namenode Web UI: http://localhost:9870
- YARN ResourceManager: http://localhost:8088
- Hive Server2 Web UI: http://localhost:10002
- Jupyter Lab: http://localhost:8888
- PostgreSQL: localhost:5432

HIVE CONNECTION:
docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'

NEXT STEPS:
1. Access Jupyter Lab at http://localhost:8888
2. Explore sample notebooks in the notebooks/ directory
3. Run analytical queries from hive/analytical_queries.sql
4. Load real UNSW-NB15 data following instructions in data/README.md

TROUBLESHOOTING:
- Check logs in output/logs/
- Verify all containers are running: docker ps
- Restart services: docker-compose restart
- Full reset: docker-compose down -v && ./scripts/setup_environment.sh

EOF
    
    info "Status report saved to: $status_file"
    success "Setup completed successfully!"
}

# Show final instructions
show_final_instructions() {
    echo
    echo -e "${GREEN}=================================================================="
    echo -e "  🎉 UNSW-NB15 Analytics Environment Setup Complete!"
    echo -e "==================================================================${NC}"
    echo
    echo -e "${CYAN}🌐 Web Interfaces:${NC}"
    echo -e "  • Hadoop NameNode:    ${BLUE}http://localhost:9870${NC}"
    echo -e "  • YARN ResourceManager: ${BLUE}http://localhost:8088${NC}" 
    echo -e "  • Hive Server2:       ${BLUE}http://localhost:10002${NC}"
    echo -e "  • Jupyter Lab:        ${BLUE}http://localhost:8888${NC}"
    echo
    echo -e "${CYAN}💻 Command Line Access:${NC}"
    echo -e "  • Hive CLI: ${YELLOW}docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'${NC}"
    echo -e "  • Hadoop CLI: ${YELLOW}docker exec -it namenode hadoop fs -ls /${NC}"
    echo
    echo -e "${CYAN}📁 Important Directories:${NC}"
    echo -e "  • Notebooks: ${BLUE}./notebooks/${NC}"
    echo -e "  • Queries: ${BLUE}./hive/analytical_queries.sql${NC}"
    echo -e "  • Data: ${BLUE}./data/${NC}"
    echo -e "  • Results: ${BLUE}./output/${NC}"
    echo
    echo -e "${CYAN}🚀 Quick Start:${NC}"
    echo -e "  1. Open Jupyter Lab: ${BLUE}http://localhost:8888${NC}"
    echo -e "  2. Explore sample data and run queries"
    echo -e "  3. Check setup status: ${YELLOW}cat output/setup_status.txt${NC}"
    echo
    echo -e "${GREEN}Happy Analytics! 📊${NC}"
    echo
}

# Cleanup function for script interruption
cleanup() {
    warning "Setup interrupted. Cleaning up..."
    # Add any cleanup logic here if needed
    exit 1
}

# Trap interruption signals
trap cleanup INT TERM

# Main execution
main() {
    show_banner
    
    # Create output directory and log file
    mkdir -p "$PROJECT_ROOT/output/logs"
    echo "UNSW-NB15 Environment Setup Log - $(date)" > "$LOG_FILE"
    
    # Execute setup steps
    check_requirements
    create_directories
    setup_environment
    pull_images
    start_services
    wait_for_services
    setup_notebooks
    load_sample_data
    create_documentation
    generate_status_report
    show_final_instructions
}

# Handle script arguments
case "${1:-}" in
    "check")
        check_requirements
        ;;
    "start")
        start_services
        wait_for_services
        show_final_instructions
        ;;
    "stop")
        info "Stopping all services..."
        cd "$PROJECT_ROOT"
        docker-compose down
        success "Services stopped"
        ;;
    "restart")
        info "Restarting services..."
        cd "$PROJECT_ROOT"
        docker-compose restart
        wait_for_services
        success "Services restarted"
        ;;
    "status")
        echo "Container Status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "clean")
        warning "This will remove all containers and data. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            cd "$PROJECT_ROOT"
            docker-compose down -v
            docker system prune -f
            success "Environment cleaned"
        fi
        ;;
    *)
        main
        ;;
esac
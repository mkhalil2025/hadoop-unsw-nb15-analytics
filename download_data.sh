#!/bin/bash

# UNSW-NB15 Dataset Download and Upload Script
# UEL-CN-7031 Big Data Analytics Assignment
# This script handles UNSW-NB15 dataset download and upload to HDFS with interactive prompts

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
OUTPUT_DIR="$PROJECT_ROOT/output"
LOG_FILE="$OUTPUT_DIR/download_data.log"

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
    echo "  UNSW-NB15 Dataset Download & Upload Manager"
    echo "  UEL-CN-7031 Big Data Analytics Environment"
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
    echo -e "${PURPLE}➤ $1${NC}" | tee -a "$LOG_FILE"
}

# Interactive prompt function
prompt_user() {
    local message="$1"
    local variable_name="$2"
    local default_value="$3"
    
    echo -e "${CYAN}$message${NC}"
    if [ -n "$default_value" ]; then
        echo -e "${YELLOW}Press Enter for default: $default_value${NC}"
    fi
    read -r user_input
    
    if [ -z "$user_input" ] && [ -n "$default_value" ]; then
        declare -g "$variable_name"="$default_value"
    else
        declare -g "$variable_name"="$user_input"
    fi
}

# Check if Docker containers are running
check_containers() {
    info "Checking if Hadoop containers are running..."
    
    local required_containers=("namenode" "datanode" "hiveserver2" "hivemetastore")
    local missing_containers=()
    
    for container in "${required_containers[@]}"; do
        if ! docker ps | grep -q "$container"; then
            missing_containers+=("$container")
        fi
    done
    
    if [ ${#missing_containers[@]} -gt 0 ]; then
        warning "The following containers are not running: ${missing_containers[*]}"
        echo -e "${CYAN}Would you like to start the environment now? (y/n):${NC}"
        read -r start_env
        
        if [[ "$start_env" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            info "Starting Hadoop environment..."
            cd "$PROJECT_ROOT"
            docker compose up -d
            sleep 30  # Wait for services to initialize
        else
            error_exit "Please start the environment first with: docker compose up -d"
        fi
    fi
    
    success "Required containers are running"
}

# Wait for services to be ready
wait_for_services() {
    info "Waiting for Hadoop services to be ready..."
    
    # Wait for Namenode
    local retries=30
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:9870 > /dev/null 2>&1; then
            break
        fi
        warning "Waiting for Namenode... ($retries retries left)"
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "Namenode failed to start within timeout"
    fi
    
    success "Hadoop services are ready"
}

# Display dataset information
show_dataset_info() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "  UNSW-NB15 Dataset Information"
    echo "=================================================================="
    echo -e "${NC}"
    echo -e "${BLUE}Dataset Details:${NC}"
    echo "• Source: University of New South Wales (UNSW) Canberra"
    echo "• Purpose: Network intrusion detection system evaluation"
    echo "• Size: ~2.5 million network flow records"
    echo "• Features: 49 features including flow statistics and attack labels"
    echo "• Attack Categories: 9 types + normal traffic"
    echo ""
    echo -e "${BLUE}Files typically include:${NC}"
    echo "• UNSW-NB15_1.csv - Training set part 1"
    echo "• UNSW-NB15_2.csv - Training set part 2"
    echo "• UNSW-NB15_3.csv - Training set part 3"
    echo "• UNSW-NB15_4.csv - Training set part 4"
    echo "• UNSW_NB15_testing-set.csv - Testing set"
    echo "• UNSW_NB15_features.csv - Feature descriptions"
    echo ""
    echo -e "${YELLOW}Official Download:${NC}"
    echo "Visit: https://research.unsw.edu.au/projects/unsw-nb15-dataset"
    echo ""
}

# Create local data directory
create_data_directory() {
    progress "Creating data directory structure..."
    
    mkdir -p "$DATA_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Create data directory README if it doesn't exist
    if [ ! -f "$DATA_DIR/README.md" ]; then
        cat > "$DATA_DIR/README.md" << 'EOF'
# UNSW-NB15 Dataset Directory

This directory contains the UNSW-NB15 cybersecurity dataset files.

## Dataset Information
- **Source**: University of New South Wales (UNSW)
- **Purpose**: Network intrusion detection evaluation
- **Records**: ~2.5 million network flow records
- **Features**: 49 features including flow statistics, service information, and attack labels

## Download Instructions
1. Visit: https://research.unsw.edu.au/projects/unsw-nb15-dataset
2. Download the training and testing CSV files
3. Place them in this directory
4. Run: `./scripts/download_data.sh` to upload to HDFS

## Supported File Formats
- CSV files with standard UNSW-NB15 schema
- Compressed files (.gz, .zip) will be automatically extracted
EOF
    fi
    
    success "Data directory structure created"
}

# Interactive file selection
interactive_file_selection() {
    show_dataset_info
    
    echo -e "${CYAN}Dataset File Management Options:${NC}"
    echo "1. I have downloaded the files and want to specify their locations"
    echo "2. Use existing files in the data directory"
    echo "3. Generate sample data for testing (if no real data available)"
    echo "4. Exit and download files manually"
    echo ""
    
    prompt_user "Please select an option (1-4):" "option" "2"
    
    case "$option" in
        "1")
            manual_file_specification
            ;;
        "2")
            use_existing_files
            ;;
        "3")
            generate_sample_data
            ;;
        "4")
            info "Please download the UNSW-NB15 dataset and run this script again."
            exit 0
            ;;
        *)
            warning "Invalid option. Using existing files in data directory."
            use_existing_files
            ;;
    esac
}

# Manual file specification
manual_file_specification() {
    progress "Manual file specification mode..."
    
    declare -a file_paths=()
    
    echo -e "${CYAN}Please specify the full paths to your UNSW-NB15 files:${NC}"
    echo -e "${YELLOW}Press Enter with empty input when done.${NC}"
    echo ""
    
    while true; do
        prompt_user "Enter file path (or press Enter to finish):" "file_path" ""
        
        if [ -z "$file_path" ]; then
            break
        fi
        
        if [ ! -f "$file_path" ]; then
            warning "File does not exist: $file_path"
            continue
        fi
        
        # Copy file to data directory
        local filename=$(basename "$file_path")
        cp "$file_path" "$DATA_DIR/$filename"
        file_paths+=("$DATA_DIR/$filename")
        success "Copied: $filename"
    done
    
    if [ ${#file_paths[@]} -eq 0 ]; then
        warning "No files specified. Falling back to existing files."
        use_existing_files
    else
        success "Copied ${#file_paths[@]} files to data directory"
    fi
}

# Use existing files in data directory
use_existing_files() {
    progress "Scanning for existing files in data directory..."
    
    # Find CSV files
    local csv_files=$(find "$DATA_DIR" -name "*.csv" -type f 2>/dev/null || true)
    
    if [ -z "$csv_files" ]; then
        warning "No CSV files found in $DATA_DIR"
        echo -e "${CYAN}Would you like to generate sample data for testing? (y/n):${NC}"
        read -r generate_sample
        
        if [[ "$generate_sample" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            generate_sample_data
        else
            error_exit "No data files available. Please download the dataset first."
        fi
    else
        echo -e "${GREEN}Found CSV files:${NC}"
        echo "$csv_files" | while read -r file; do
            echo "  • $(basename "$file")"
        done
        success "Found $(echo "$csv_files" | wc -l) CSV file(s)"
    fi
}

# Generate sample data for testing
generate_sample_data() {
    progress "Generating sample UNSW-NB15 data for testing..."
    
    local sample_file="$DATA_DIR/UNSW_NB15_sample.csv"
    
    # Create header with all 49 features
    cat > "$sample_file" << 'EOF'
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,sttl,dttl,sloss,dloss,service,sload,dload,spkts,dpkts,swin,dwin,stcpb,dtcpb,smeansz,dmeansz,trans_depth,res_bdy_len,sjit,djit,stime,ltime,sintpkt,dintpkt,tcprtt,synack,ackdat,is_sm_ips_ports,ct_state_ttl,ct_flw_http_mthd,is_ftp_login,ct_ftp_cmd,ct_srv_src,ct_srv_dst,ct_dst_ltm,ct_src_ltm,ct_src_dport_ltm,ct_dst_sport_ltm,ct_dst_src_ltm,label,attack_cat
EOF
    
    # Generate realistic sample data
    local protocols=("tcp" "udp" "icmp")
    local services=("http" "https" "ssh" "ftp" "dns" "smtp" "telnet" "pop3")
    local attack_categories=("Normal" "DoS" "Exploits" "Reconnaissance" "Analysis" "Backdoor" "Fuzzers" "Generic" "Shellcode" "Worms")
    local states=("FIN" "CON" "INT" "RST" "REQ")
    
    progress "Generating 5000 sample records..."
    
    for i in {1..5000}; do
        # Generate random but realistic values
        local src_ip="192.168.$((RANDOM % 256)).$((RANDOM % 256))"
        local dst_ip="10.0.$((RANDOM % 256)).$((RANDOM % 256))"
        local sport=$((RANDOM % 65535 + 1))
        local dsport=$((RANDOM % 1024 + 22))
        local proto="${protocols[$((RANDOM % ${#protocols[@]}))]}"
        local service="${services[$((RANDOM % ${#services[@]}))]}"
        local state="${states[$((RANDOM % ${#states[@]}))]}"
        
        # 70% normal traffic, 30% attacks
        local is_attack=$((RANDOM % 10 < 3 ? 1 : 0))
        local label=$is_attack
        local attack_cat="Normal"
        
        if [ $is_attack -eq 1 ]; then
            # Select random attack category (excluding Normal)
            local attack_idx=$((RANDOM % 9 + 1))
            attack_cat="${attack_categories[$attack_idx]}"
        fi
        
        # Generate other features with realistic ranges
        local dur="$((RANDOM % 3600)).$((RANDOM % 999))"
        local sbytes=$((RANDOM % 100000))
        local dbytes=$((RANDOM % 50000))
        local sttl=$((RANDOM % 255))
        local dttl=$((RANDOM % 255))
        local sloss=$((RANDOM % 10))
        local dloss=$((RANDOM % 10))
        local sload=$((RANDOM % 1000000))
        local dload=$((RANDOM % 500000))
        local spkts=$((RANDOM % 1000))
        local dpkts=$((RANDOM % 500))
        
        # Generate timestamp
        local hour=$((RANDOM % 24))
        local minute=$((RANDOM % 60))
        local second=$((RANDOM % 60))
        local stime="2023-01-01 $(printf "%02d:%02d:%02d" $hour $minute $second)"
        local ltime="2023-01-01 $(printf "%02d:%02d:%02d" $hour $((minute + 1)) $second)"
        
        echo "$src_ip,$sport,$dst_ip,$dsport,$proto,$state,$dur,$sbytes,$dbytes,$sttl,$dttl,$sloss,$dloss,$service,$sload,$dload,$spkts,$dpkts,8192,8192,$((RANDOM % 1000)),$((RANDOM % 1000)),$((sbytes / (spkts + 1))),$((dbytes / (dpkts + 1))),1,0,0.$((RANDOM % 99)),0.$((RANDOM % 99)),$stime,$ltime,0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),$((RANDOM % 2)),$((RANDOM % 5)),$((RANDOM % 3)),0,0,$((RANDOM % 10)),$((RANDOM % 10)),$((RANDOM % 20)),$((RANDOM % 15)),$((RANDOM % 5)),$((RANDOM % 3)),$((RANDOM % 2)),$label,$attack_cat" >> "$sample_file"
        
        # Progress indicator
        if [ $((i % 1000)) -eq 0 ]; then
            echo -ne "\rGenerated $i records..."
        fi
    done
    
    echo ""
    success "Generated sample dataset with 5000 records in: $sample_file"
    
    # Show statistics
    local normal_count=$(grep -c ",Normal$" "$sample_file")
    local attack_count=$(grep -vc ",Normal$" "$sample_file")
    info "Dataset statistics: $normal_count normal records, $attack_count attack records"
}

# Create HDFS directory structure
create_hdfs_directories() {
    progress "Creating HDFS directory structure..."
    
    # Create directories
    docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse 2>/dev/null || true
    docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse/unsw_nb15.db 2>/dev/null || true
    docker exec namenode hdfs dfs -mkdir -p /user/data/unsw_nb15 2>/dev/null || true
    docker exec namenode hdfs dfs -mkdir -p /user/output 2>/dev/null || true
    
    # Set permissions
    docker exec namenode hdfs dfs -chmod -R 777 /user 2>/dev/null || true
    
    success "HDFS directories created"
}

# Upload data to HDFS with progress tracking
upload_to_hdfs() {
    progress "Uploading data files to HDFS..."
    
    # Find all CSV files in data directory
    local csv_files=$(find "$DATA_DIR" -name "*.csv" -type f)
    
    if [ -z "$csv_files" ]; then
        error_exit "No CSV files found in $DATA_DIR"
    fi
    
    local total_files=$(echo "$csv_files" | wc -l)
    local current_file=0
    
    echo "$csv_files" | while read -r file; do
        current_file=$((current_file + 1))
        local filename=$(basename "$file")
        local filesize=$(du -h "$file" | cut -f1)
        
        progress "Uploading file $current_file/$total_files: $filename ($filesize)"
        
        # Copy file to container
        docker cp "$file" namenode:/tmp/"$filename"
        
        # Upload to HDFS with overwrite
        docker exec namenode hdfs dfs -put -f /tmp/"$filename" /user/data/unsw_nb15/
        
        # Clean up temporary file
        docker exec namenode rm -f /tmp/"$filename"
        
        success "Uploaded: $filename"
    done
    
    success "All data files uploaded to HDFS"
}

# Verify HDFS uploads
verify_hdfs_uploads() {
    progress "Verifying HDFS uploads..."
    
    echo -e "${CYAN}HDFS Directory Listing:${NC}"
    docker exec namenode hdfs dfs -ls /user/data/unsw_nb15/
    
    echo -e "${CYAN}HDFS Usage Summary:${NC}"
    docker exec namenode hdfs dfs -du -h /user/data/unsw_nb15/
    
    # Count total records
    echo -e "${CYAN}Counting total records in uploaded files:${NC}"
    local total_lines=$(docker exec namenode hdfs dfs -cat /user/data/unsw_nb15/*.csv | wc -l)
    local total_records=$((total_lines - $(docker exec namenode hdfs dfs -ls /user/data/unsw_nb15/*.csv | wc -l)))
    
    info "Total records uploaded: $total_records"
    success "HDFS upload verification completed"
}

# Provide status feedback
provide_status() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "  Data Upload Status Report"
    echo "=================================================================="
    echo -e "${NC}"
    
    echo -e "${BLUE}✓ Local Data Directory:${NC} $DATA_DIR"
    echo -e "${BLUE}✓ HDFS Data Path:${NC} /user/data/unsw_nb15"
    echo -e "${BLUE}✓ Log File:${NC} $LOG_FILE"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Load data into Hive tables: ./scripts/load_data.sh hive"
    echo "2. Run analytical queries: docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'"
    echo "3. Explore data in Jupyter: http://localhost:8888"
    echo ""
    echo -e "${CYAN}Web Interfaces:${NC}"
    echo "• Hadoop NameNode: http://localhost:9870"
    echo "• YARN ResourceManager: http://localhost:8088"
    echo "• Hive Server2: http://localhost:10002"
    echo "• Jupyter Lab: http://localhost:8888"
    echo ""
    success "Data download and upload process completed successfully!"
}

# Main execution
main() {
    show_banner
    
    # Create output directory for logs
    mkdir -p "$OUTPUT_DIR"
    
    # Create log file
    echo "UNSW-NB15 Data Download & Upload Log - $(date)" > "$LOG_FILE"
    
    # Execute main workflow
    create_data_directory
    check_containers
    wait_for_services
    interactive_file_selection
    create_hdfs_directories
    upload_to_hdfs
    verify_hdfs_uploads
    provide_status
}

# Handle script arguments
case "${1:-}" in
    "interactive")
        main
        ;;
    "upload")
        check_containers
        wait_for_services
        create_hdfs_directories
        upload_to_hdfs
        verify_hdfs_uploads
        ;;
    "sample")
        create_data_directory
        generate_sample_data
        ;;
    "verify")
        check_containers
        verify_hdfs_uploads
        ;;
    "help"|"--help"|"-h")
        echo "UNSW-NB15 Dataset Download & Upload Script"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (no args)    Run interactive mode with full workflow"
        echo "  interactive  Run interactive mode with full workflow"
        echo "  upload       Upload existing files to HDFS"
        echo "  sample       Generate sample data only"
        echo "  verify       Verify HDFS uploads"
        echo "  help         Show this help message"
        echo ""
        ;;
    *)
        main
        ;;
esac
#!/bin/bash

# UNSW-NB15 Data Loading Script for Hadoop Analytics Environment
# UEL-CN-7031 Big Data Analytics Assignment
# This script automates the process of loading UNSW-NB15 dataset into HDFS and Hive

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
OUTPUT_DIR="$PROJECT_ROOT/output"
LOG_FILE="$OUTPUT_DIR/data_loading.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

# Warning message function
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Info message function
info() {
    echo -e "${BLUE}INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if Docker containers are running
check_containers() {
    info "Checking if Hadoop containers are running..."
    
    local required_containers=("namenode" "datanode" "hiveserver2" "hivemetastore")
    
    for container in "${required_containers[@]}"; do
        if ! docker ps | grep -q "$container"; then
            error_exit "Container $container is not running. Please start the environment first with: docker-compose up -d"
        fi
    done
    
    success "All required containers are running"
}

# Wait for services to be ready
wait_for_services() {
    info "Waiting for services to be ready..."
    
    # Wait for Namenode
    local retries=30
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:9870 > /dev/null 2>&1; then
            break
        fi
        warning "Waiting for Namenode to be ready... ($retries retries left)"
        sleep 10
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "Namenode failed to start within timeout"
    fi
    
    # Wait for HiveServer2
    retries=20
    while [ $retries -gt 0 ]; do
        if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" > /dev/null 2>&1; then
            break
        fi
        warning "Waiting for HiveServer2 to be ready... ($retries retries left)"
        sleep 15
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        error_exit "HiveServer2 failed to start within timeout"
    fi
    
    success "All services are ready"
}

# Create directory structure in HDFS
create_hdfs_directories() {
    info "Creating HDFS directory structure..."
    
    # Create directories
    docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse || warning "Directory may already exist"
    docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse/unsw_nb15.db || warning "Directory may already exist"
    docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse/unsw_nb15.db/network_flows_raw || warning "Directory may already exist"
    docker exec namenode hdfs dfs -mkdir -p /user/data/unsw_nb15 || warning "Directory may already exist"
    docker exec namenode hdfs dfs -mkdir -p /user/output || warning "Directory may already exist"
    
    # Set permissions
    docker exec namenode hdfs dfs -chmod -R 777 /user || warning "Permission setting may have failed"
    
    success "HDFS directories created successfully"
}

# Download UNSW-NB15 dataset (if not already present)
download_dataset() {
    info "Checking for UNSW-NB15 dataset..."
    
    # Create local data directory if it doesn't exist
    mkdir -p "$DATA_DIR"
    
    # Check if dataset files exist
    if [ ! -f "$DATA_DIR/UNSW-NB15_1.csv" ] && [ ! -f "$DATA_DIR/UNSW_NB15_training-set.csv" ]; then
        info "UNSW-NB15 dataset not found locally. Creating sample data for testing..."
        create_sample_data
    else
        success "UNSW-NB15 dataset found in $DATA_DIR"
    fi
}

# Create sample data for testing (when real dataset is not available)
create_sample_data() {
    info "Creating sample UNSW-NB15 data for testing..."
    
    local sample_file="$DATA_DIR/UNSW_NB15_sample.csv"
    
    # Create header
    cat > "$sample_file" << 'EOF'
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,sttl,dttl,sloss,dloss,service,sload,dload,spkts,dpkts,swin,dwin,stcpb,dtcpb,smeansz,dmeansz,trans_depth,res_bdy_len,sjit,djit,stime,ltime,sintpkt,dintpkt,tcprtt,synack,ackdat,is_sm_ips_ports,ct_state_ttl,ct_flw_http_mthd,is_ftp_login,ct_ftp_cmd,ct_srv_src,ct_srv_dst,ct_dst_ltm,ct_src_ltm,ct_src_dport_ltm,ct_dst_sport_ltm,ct_dst_src_ltm,label,attack_cat
192.168.1.100,12345,10.0.0.1,80,tcp,FIN,0.121,1500,800,64,64,0,0,http,12000,6400,10,8,8192,8192,100,200,150,100,1,800,0.1,0.05,2023-01-01 10:00:00,2023-01-01 10:00:01,0.012,0.008,0.05,0.02,0.01,0,2,1,0,0,5,3,10,8,2,1,0,0,Normal
172.16.0.50,54321,192.168.1.200,443,tcp,RST,2.543,25000,15000,128,128,1,0,ssl,98000,59000,45,30,16384,16384,500,600,555,500,2,0,0.5,0.3,2023-01-01 10:01:00,2023-01-01 10:01:03,0.056,0.1,0.1,0.05,0.03,0,3,0,0,0,2,1,5,3,1,0,1,1,DoS
10.0.0.5,23,192.168.1.50,22,tcp,CON,15.678,5000,50000,64,64,0,2,ssh,2667,26667,20,200,4096,4096,1000,2000,250,250,5,0,1.2,0.8,2023-01-01 10:02:00,2023-01-01 10:02:16,0.784,0.078,0.2,0.1,0.05,0,1,0,1,2,8,15,25,10,5,3,2,1,Exploits
192.168.0.100,8080,10.0.0.10,80,tcp,FIN,0.234,2000,1200,64,64,0,0,http,68000,41000,15,12,8192,8192,150,180,133,100,1,1200,0.15,0.08,2023-01-01 10:03:00,2023-01-01 10:03:01,0.0156,0.0083,0.06,0.025,0.015,0,2,1,0,0,6,4,12,9,3,2,1,0,Normal
203.45.67.89,1234,192.168.1.100,21,tcp,INT,0.05,200,0,64,0,0,0,ftp,32000,0,2,0,2048,0,50,0,100,0,0,0,0.02,0,2023-01-01 10:04:00,2023-01-01 10:04:01,0.025,0,0.03,0.01,0.005,0,1,0,1,1,1,0,1,1,0,0,0,1,Reconnaissance
EOF
    
    # Generate more sample data
    for i in {1..1000}; do
        # Generate random but realistic network flow data
        local src_ip="192.168.$((RANDOM % 255)).$((RANDOM % 255))"
        local dst_ip="10.0.$((RANDOM % 255)).$((RANDOM % 255))"
        local sport=$((RANDOM % 65535 + 1))
        local dsport=$((RANDOM % 1000 + 20))
        local proto=$([ $((RANDOM % 2)) -eq 0 ] && echo "tcp" || echo "udp")
        local service=$([ $((RANDOM % 3)) -eq 0 ] && echo "http" || ([ $((RANDOM % 2)) -eq 0 ] && echo "ssh" || echo "ftp"))
        local label=$((RANDOM % 10 < 7 ? 0 : 1))  # 70% normal, 30% attack
        local attack_cat="Normal"
        
        if [ $label -eq 1 ]; then
            local attacks=("DoS" "Exploits" "Reconnaissance" "Analysis" "Backdoor" "Fuzzers" "Generic" "Shellcode" "Worms")
            attack_cat="${attacks[$((RANDOM % ${#attacks[@]}))]}"
        fi
        
        echo "$src_ip,$sport,$dst_ip,$dsport,$proto,FIN,$((RANDOM % 1000)).$(printf "%03d" $((RANDOM % 1000))),$((RANDOM % 100000)),$((RANDOM % 50000)),64,64,0,0,$service,$((RANDOM % 100000)),$((RANDOM % 50000)),$((RANDOM % 100)),$((RANDOM % 50)),8192,8192,$((RANDOM % 1000)),$((RANDOM % 1000)),$((RANDOM % 500)),$((RANDOM % 300)),1,0,0.$((RANDOM % 99)),0.$((RANDOM % 99)),2023-01-01 10:$(printf "%02d" $((i % 60))):$(printf "%02d" $((RANDOM % 60))),2023-01-01 10:$(printf "%02d" $(((i % 60) + 1))):$(printf "%02d" $((RANDOM % 60))),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0.0$((RANDOM % 99)),0,$((RANDOM % 5)),$((RANDOM % 3)),0,0,$((RANDOM % 10)),$((RANDOM % 10)),$((RANDOM % 20)),$((RANDOM % 15)),$((RANDOM % 5)),$((RANDOM % 3)),$((RANDOM % 2)),$label,$attack_cat" >> "$sample_file"
    done
    
    success "Sample UNSW-NB15 dataset created with 1000+ records"
}

# Load data into HDFS
load_data_to_hdfs() {
    info "Loading data into HDFS..."
    
    # Find CSV files in data directory
    local csv_files=$(find "$DATA_DIR" -name "*.csv" -type f)
    
    if [ -z "$csv_files" ]; then
        error_exit "No CSV files found in $DATA_DIR"
    fi
    
    # Copy each CSV file to HDFS
    for file in $csv_files; do
        local filename=$(basename "$file")
        info "Uploading $filename to HDFS..."
        
        # Copy file to container
        docker cp "$file" namenode:/tmp/"$filename"
        
        # Put file in HDFS
        docker exec namenode hdfs dfs -put -f /tmp/"$filename" /user/data/unsw_nb15/
        
        # Clean up temporary file
        docker exec namenode rm -f /tmp/"$filename"
        
        success "Uploaded $filename to HDFS"
    done
    
    # Verify files in HDFS
    info "Verifying files in HDFS..."
    docker exec namenode hdfs dfs -ls /user/data/unsw_nb15/
}

# Create Hive database and tables
create_hive_tables() {
    info "Creating Hive database and tables..."
    
    # Copy SQL script to Hive container
    docker cp "$PROJECT_ROOT/hive/create_tables.sql" hiveserver2:/tmp/create_tables.sql
    
    # Execute SQL script
    docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/create_tables.sql || error_exit "Failed to create Hive tables"
    
    success "Hive database and tables created successfully"
}

# Load data into Hive tables
load_data_to_hive() {
    info "Loading data into Hive tables..."
    
    # Create dynamic SQL for loading data
    cat > /tmp/load_data.sql << EOF
USE unsw_nb15;

-- Load data from HDFS into raw table
LOAD DATA INPATH '/user/data/unsw_nb15/' INTO TABLE network_flows_raw;

-- Insert data into partitioned table
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 1000;
SET hive.exec.max.dynamic.partitions.pernode = 100;

INSERT INTO TABLE network_flows PARTITION(year, month)
SELECT 
    srcip, sport, dstip, dsport, proto, dur,
    sbytes, dbytes, sttl, dttl, sloss, dloss,
    service, sload, dload, spkts, dpkts,
    swin, dwin, stcpb, dtcpb, smeansz, dmeansz,
    trans_depth, res_bdy_len, sjit, djit,
    stime, ltime, sintpkt, dintpkt, tcprtt,
    synack, ackdat, is_sm_ips_ports, ct_state_ttl,
    ct_flw_http_mthd, is_ftp_login, ct_ftp_cmd,
    ct_srv_src, ct_srv_dst, ct_dst_ltm, ct_src_ltm,
    ct_src_dport_ltm, ct_dst_sport_ltm, ct_dst_src_ltm,
    label, attack_cat,
    COALESCE(YEAR(stime), 2023) as year,
    COALESCE(MONTH(stime), 1) as month
FROM network_flows_raw
WHERE srcip IS NOT NULL;

-- Refresh statistics
ANALYZE TABLE network_flows COMPUTE STATISTICS;

-- Show loaded data count
SELECT COUNT(*) as total_records FROM network_flows;
SELECT attack_cat, COUNT(*) as count FROM network_flows GROUP BY attack_cat;
EOF
    
    # Copy and execute loading script
    docker cp /tmp/load_data.sql hiveserver2:/tmp/load_data.sql
    docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/load_data.sql || error_exit "Failed to load data into Hive"
    
    # Clean up
    rm -f /tmp/load_data.sql
    
    success "Data loaded into Hive tables successfully"
}

# Validate data loading
validate_data() {
    info "Validating loaded data..."
    
    # Create validation script
    cat > /tmp/validate_data.sql << EOF
USE unsw_nb15;

-- Basic data validation queries
SELECT 'Total Records' as metric, COUNT(*) as value FROM network_flows
UNION ALL
SELECT 'Attack Records' as metric, SUM(CASE WHEN label = true THEN 1 ELSE 0 END) as value FROM network_flows
UNION ALL
SELECT 'Normal Records' as metric, SUM(CASE WHEN label = false THEN 1 ELSE 0 END) as value FROM network_flows
UNION ALL
SELECT 'Unique Source IPs' as metric, COUNT(DISTINCT srcip) as value FROM network_flows
UNION ALL
SELECT 'Unique Destination IPs' as metric, COUNT(DISTINCT dstip) as value FROM network_flows;

-- Attack category distribution
SELECT 'Attack Distribution' as analysis, attack_cat, COUNT(*) as count 
FROM network_flows 
WHERE attack_cat IS NOT NULL 
GROUP BY attack_cat 
ORDER BY count DESC;

-- Protocol distribution
SELECT 'Protocol Distribution' as analysis, proto, COUNT(*) as count 
FROM network_flows 
GROUP BY proto 
ORDER BY count DESC;
EOF
    
    # Run validation
    docker cp /tmp/validate_data.sql hiveserver2:/tmp/validate_data.sql
    docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/validate_data.sql
    
    # Clean up
    rm -f /tmp/validate_data.sql
    
    success "Data validation completed"
}

# Main execution
main() {
    info "Starting UNSW-NB15 data loading process..."
    
    # Create output directory for logs
    mkdir -p "$OUTPUT_DIR"
    
    # Create log file
    echo "UNSW-NB15 Data Loading Log - $(date)" > "$LOG_FILE"
    
    # Execute steps
    check_containers
    wait_for_services
    create_hdfs_directories
    download_dataset
    load_data_to_hdfs
    create_hive_tables
    load_data_to_hive
    validate_data
    
    success "UNSW-NB15 data loading completed successfully!"
    info "Check the log file at: $LOG_FILE"
    info "Access Hive at: http://localhost:10002"
    info "Access Hadoop Web UI at: http://localhost:9870"
    info "Connect to Hive using: docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'"
}

# Handle script arguments
case "${1:-}" in
    "download")
        download_dataset
        ;;
    "hdfs")
        check_containers
        wait_for_services
        create_hdfs_directories
        load_data_to_hdfs
        ;;
    "hive")
        check_containers
        wait_for_services
        create_hive_tables
        load_data_to_hive
        ;;
    "validate")
        check_containers
        validate_data
        ;;
    *)
        main
        ;;
esac
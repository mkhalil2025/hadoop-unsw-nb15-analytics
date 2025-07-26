#!/bin/bash

# Enhanced UNSW-NB15 Data Loading Script for Hadoop Analytics Environment
# Loads 3 specific CSV files: UNSW-NB15.csv, UNSW-NB15_features.csv, UNSW-NB15_LIST_EVENTS.csv
# UEL-CN-7031 Big Data Analytics Assignment
# This script automates the process of loading UNSW-NB15 dataset into HDFS and Hive

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
OUTPUT_DIR="$PROJECT_ROOT/output"
LOG_FILE="$OUTPUT_DIR/data_loading.log"

# Required files for UNSW-NB15 dataset
REQUIRED_FILES=(
    "UNSW-NB15.csv"
    "UNSW-NB15_features.csv"
    "UNSW-NB15_LIST_EVENTS.csv"
)

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
check_required_files() {
    info "Checking for required UNSW-NB15 dataset files..."
    
    # Create local data directory if it doesn't exist
    mkdir -p "$DATA_DIR"
    
    local missing_files=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$DATA_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        warning "Missing required files: ${missing_files[*]}"
        info "Creating sample data for testing purposes..."
        create_sample_files
    else
        success "All required UNSW-NB15 dataset files found in $DATA_DIR"
        # Verify file contents
        for file in "${REQUIRED_FILES[@]}"; do
            local line_count=$(wc -l < "$DATA_DIR/$file")
            info "$file: $line_count lines"
        done
    fi
}

# Create sample data files if originals are not available
create_sample_files() {
    info "Creating sample UNSW-NB15 data files..."
    
    # Only create files that don't exist
    if [ ! -f "$DATA_DIR/UNSW-NB15.csv" ]; then
        create_sample_main_data
    fi
    
    if [ ! -f "$DATA_DIR/UNSW-NB15_features.csv" ]; then
        create_sample_features_data
    fi
    
    if [ ! -f "$DATA_DIR/UNSW-NB15_LIST_EVENTS.csv" ]; then
        create_sample_events_data
    fi
    
    success "Sample data files created successfully"
}

# Create sample main dataset (UNSW-NB15.csv)
create_sample_main_data() {
    local sample_file="$DATA_DIR/UNSW-NB15.csv"
    info "Creating sample main dataset: $sample_file"
    
    # Create header
    cat > "$sample_file" << 'EOF'
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,sttl,dttl,sloss,dloss,service,sload,dload,spkts,dpkts,swin,dwin,stcpb,dtcpb,smeansz,dmeansz,trans_depth,res_bdy_len,sjit,djit,stime,ltime,sintpkt,dintpkt,tcprtt,synack,ackdat,is_sm_ips_ports,ct_state_ttl,ct_flw_http_mthd,is_ftp_login,ct_ftp_cmd,ct_srv_src,ct_srv_dst,ct_dst_ltm,ct_src_ltm,ct_src_dport_ltm,ct_dst_sport_ltm,ct_dst_src_ltm,label,attack_cat
EOF
    
    # Generate sample data with realistic values
    local protocols=("tcp" "udp" "icmp")
    local services=("http" "https" "ssh" "ftp" "dns" "smtp" "telnet" "pop3" "-")
    local attack_categories=("Normal" "DoS" "Exploits" "Reconnaissance" "Analysis" "Backdoor" "Fuzzers" "Generic" "Shellcode" "Worms")
    local states=("FIN" "CON" "INT" "RST" "REQ")
    
    info "Generating 2000 sample network flow records..."
    
    for i in {1..2000}; do
        # Generate random but realistic values
        local src_ip="192.168.$((RANDOM % 256)).$((RANDOM % 256))"
        local dst_ip="10.0.$((RANDOM % 256)).$((RANDOM % 256))"
        local sport=$((RANDOM % 65535 + 1))
        local dsport=$((RANDOM % 1024 + 22))
        local proto="${protocols[$((RANDOM % ${#protocols[@]}))]}"
        local service="${services[$((RANDOM % ${#services[@]}))]}"
        local state="${states[$((RANDOM % ${#states[@]}))]}"
        
        # 75% normal traffic, 25% attacks
        local is_attack=$((RANDOM % 4 == 0 ? 1 : 0))
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
        if [ $((i % 500)) -eq 0 ]; then
            echo -ne "\rGenerated $i records..."
        fi
    done
    echo ""
    success "Generated sample main dataset with 2000 records"
}

# Create sample features data (UNSW-NB15_features.csv)
create_sample_features_data() {
    local features_file="$DATA_DIR/UNSW-NB15_features.csv"
    info "Creating sample features file: $features_file"
    
    # This file already exists from our earlier creation, but let's ensure it's correct
    if [ ! -f "$features_file" ]; then
        cat > "$features_file" << 'EOF'
Name,Type,Description
srcip,nominal,Source IP address
sport,integer,Source port number
dstip,nominal,Destination IP address
dsport,integer,Destination port number
proto,nominal,Transaction protocol
state,nominal,Indicates to the state and its dependent protocol
dur,float,Record total duration
sbytes,integer,Source to destination transaction bytes
dbytes,integer,Destination to source transaction bytes
sttl,integer,Source to destination time to live value
dttl,integer,Destination to source time to live value
sloss,integer,Source packets retransmitted or dropped
dloss,integer,Destination packets retransmitted or dropped
service,nominal,http ftp smtp ssh dns ftp-data irc and (-) if not much used service
sload,float,Source bits per second
dload,float,Destination bits per second
spkts,integer,Source to destination packet count
dpkts,integer,Destination to source packet count
swin,integer,Source TCP window advertisement value
dwin,integer,Destination TCP window advertisement value
stcpb,integer,Source TCP base sequence number
dtcpb,integer,Destination TCP base sequence number
smeansz,float,Mean of the flow packet size transmitted by the src
dmeansz,float,Mean of the flow packet size transmitted by the dst
trans_depth,integer,The depth into the connection of http request/response transaction
res_bdy_len,integer,The content size of the data transferred from the server response
sjit,float,Source jitter (mSec)
djit,float,Destination jitter (mSec)
stime,timestamp,Record start time
ltime,timestamp,Record last time
sintpkt,float,Source inter-packet arrival time (mSec)
dintpkt,float,Destination inter-packet arrival time (mSec)
tcprtt,float,TCP connection setup round-trip time the sum of synack and ackdat
synack,float,TCP connection setup time the time between the SYN and the SYN_ACK packets
ackdat,float,TCP connection setup time the time between the SYN_ACK and the ACK packets
is_sm_ips_ports,binary,If source equals to destination IP addresses and port numbers are equal this variable takes value 1 else 0
ct_state_ttl,integer,No for each state according to specific range of values for source/destination time to live
ct_flw_http_mthd,integer,No of flows that has methods such as Get and Post in http service
is_ftp_login,binary,If the ftp session is accessed by user and password then 1 else 0
ct_ftp_cmd,integer,No of flows that has a command in ftp session
ct_srv_src,integer,No of connections that contain the same service and source address in 100 connections according to the last time
ct_srv_dst,integer,No of connections that contain the same service and destination address in 100 connections according to the last time
ct_dst_ltm,integer,No of connections of the same destination address in 100 connections according to the last time
ct_src_ltm,integer,No of connections of the same source address in 100 connections according to the last time
ct_src_dport_ltm,integer,No of connections of the same source address and the destination port in 100 connections according to the last time
ct_dst_sport_ltm,integer,No of connections of the same destination address and the source port in 100 connections according to the last time
ct_dst_src_ltm,integer,No of connections of the same source and the destination address in in 100 connections according to the last time
attack_cat,nominal,The name of each attack category In this data set nine categories e.g. Fuzzers Reconnaissance Backdoor DoS Exploits Analysis Generic Shellcode Worms
label,binary,0 for normal 1 for attack
EOF
    fi
    success "Features file ready with 49 feature descriptions"
}

# Create sample events data (UNSW-NB15_LIST_EVENTS.csv)
create_sample_events_data() {
    local events_file="$DATA_DIR/UNSW-NB15_LIST_EVENTS.csv"
    info "Creating sample events file: $events_file"
    
    # This file already exists from our earlier creation, but let's ensure it's correct
    if [ ! -f "$events_file" ]; then
        cat > "$events_file" << 'EOF'
event_id,event_type,attack_category,event_count,event_description
1,Normal,Normal,1746654,Normal network traffic
2,DoS,DoS,16353,Denial of Service attacks
3,Exploits,Exploits,44525,Exploitation attacks using vulnerabilities
4,Generic,Generic,215481,Generic attacks that cannot be classified into specific categories
5,Reconnaissance,Reconnaissance,13987,Information gathering and reconnaissance activities  
6,Analysis,Analysis,2677,Analysis attacks including port scans and vulnerability assessments
7,Backdoor,Backdoor,2329,Backdoor attacks providing unauthorized access
8,Shellcode,Shellcode,1511,Shellcode attacks delivering executable payloads
9,Worms,Worms,174,Self-replicating worm attacks
10,Fuzzers,Fuzzers,24246,Fuzzing attacks using automated testing tools
EOF
    fi
    success "Events file ready with 10 attack category statistics"
}

# Load data into HDFS
load_data_to_hdfs() {
    info "Loading the 3 required UNSW-NB15 files into HDFS..."
    
    # Verify all required files exist
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$DATA_DIR/$file" ]; then
            error_exit "Required file not found: $DATA_DIR/$file"
        fi
    done
    
    # Copy each required CSV file to HDFS
    for file in "${REQUIRED_FILES[@]}"; do
        local filename="$file"
        local filepath="$DATA_DIR/$file"
        info "Uploading $filename to HDFS..."
        
        # Copy file to container
        docker cp "$filepath" namenode:/tmp/"$filename"
        
        # Put file in HDFS
        docker exec namenode hdfs dfs -put -f /tmp/"$filename" /user/data/unsw_nb15/
        
        # Clean up temporary file
        docker exec namenode rm -f /tmp/"$filename"
        
        # Get file size for verification
        local hdfs_size=$(docker exec namenode hdfs dfs -du -h /user/data/unsw_nb15/"$filename" | awk '{print $1}')
        success "Uploaded $filename to HDFS ($hdfs_size)"
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
    
    # Create dynamic SQL for loading data into the 3 tables
    cat > /tmp/load_hive_data.sql << EOF
USE unsw_nb15;

-- Load main dataset (UNSW-NB15.csv)
LOAD DATA INPATH '/user/data/unsw_nb15/UNSW-NB15.csv' INTO TABLE unsw_nb15_main;

-- Load features dataset (UNSW-NB15_features.csv)  
LOAD DATA INPATH '/user/data/unsw_nb15/UNSW-NB15_features.csv' INTO TABLE unsw_nb15_features;

-- Load events dataset (UNSW-NB15_LIST_EVENTS.csv)
LOAD DATA INPATH '/user/data/unsw_nb15/UNSW-NB15_LIST_EVENTS.csv' INTO TABLE unsw_nb15_events;

-- Show successful table creation
SHOW TABLES;

-- Basic validation queries
SELECT COUNT(*) as total_main_records FROM unsw_nb15_main;
SELECT COUNT(*) as total_features FROM unsw_nb15_features;
SELECT COUNT(*) as total_events FROM unsw_nb15_events;

-- Sample data from each table
SELECT 'Main Dataset Sample:' as info;
SELECT srcip, dstip, proto, service, attack_cat, label FROM unsw_nb15_main LIMIT 5;

SELECT 'Features Sample:' as info;
SELECT name, type, description FROM unsw_nb15_features LIMIT 5;

SELECT 'Events Sample:' as info;
SELECT event_type, attack_category, event_count FROM unsw_nb15_events LIMIT 5;
EOF
    
    # Copy and execute loading script
    docker cp /tmp/load_hive_data.sql hiveserver2:/tmp/load_hive_data.sql
    docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/load_hive_data.sql || error_exit "Failed to load data into Hive"
    
    # Clean up
    rm -f /tmp/load_hive_data.sql
    
    success "Data loaded into Hive tables successfully"
}

# Validate data loading
validate_data() {
    info "Validating loaded data..."
    
    # Create validation script to test the success criteria
    cat > /tmp/validate_success_criteria.sql << EOF
USE unsw_nb15;

-- Success Criteria Tests
SELECT 'SUCCESS CRITERIA VALIDATION' as test_header;

-- Test 1: SHOW TABLES
SELECT 'Test 1: SHOW TABLES' as test_name;
SHOW TABLES;

-- Test 2: SELECT COUNT(*) FROM unsw_nb15_main
SELECT 'Test 2: Main dataset count' as test_name;
SELECT COUNT(*) as main_record_count FROM unsw_nb15_main;

-- Test 3: SELECT * FROM unsw_nb15_features LIMIT 10
SELECT 'Test 3: Features sample (first 10)' as test_name;
SELECT * FROM unsw_nb15_features LIMIT 10;

-- Test 4: SELECT * FROM unsw_nb15_events LIMIT 10  
SELECT 'Test 4: Events sample (first 10)' as test_name;
SELECT * FROM unsw_nb15_events LIMIT 10;

-- Additional validation queries
SELECT 'ADDITIONAL VALIDATION' as validation_header;

-- Attack distribution in main dataset
SELECT 'Attack Distribution:' as metric;
SELECT attack_cat, COUNT(*) as count, 
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM unsw_nb15_main 
WHERE attack_cat IS NOT NULL 
GROUP BY attack_cat 
ORDER BY count DESC;

-- Protocol distribution
SELECT 'Protocol Distribution:' as metric;
SELECT proto, COUNT(*) as count 
FROM unsw_nb15_main 
GROUP BY proto 
ORDER BY count DESC
LIMIT 5;

-- Features metadata validation
SELECT 'Feature Types Summary:' as metric;
SELECT type, COUNT(*) as feature_count
FROM unsw_nb15_features
GROUP BY type
ORDER BY feature_count DESC;

-- Events summary validation
SELECT 'Events Summary:' as metric;
SELECT SUM(event_count) as total_events_in_dataset,
       COUNT(*) as unique_event_types,
       AVG(event_count) as avg_events_per_type
FROM unsw_nb15_events;
EOF
    
    # Run validation
    docker cp /tmp/validate_success_criteria.sql hiveserver2:/tmp/validate_success_criteria.sql
    docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/validate_success_criteria.sql
    
    # Clean up
    rm -f /tmp/validate_success_criteria.sql
    
    success "Data validation completed - Success criteria verified!"
}

# Main execution
main() {
    info "Starting Enhanced UNSW-NB15 data loading process for 3 required files..."
    
    # Create output directory for logs
    mkdir -p "$OUTPUT_DIR"
    
    # Create log file
    echo "Enhanced UNSW-NB15 Data Loading Log - $(date)" > "$LOG_FILE"
    echo "Loading 3 files: UNSW-NB15.csv, UNSW-NB15_features.csv, UNSW-NB15_LIST_EVENTS.csv" >> "$LOG_FILE"
    
    # Execute steps
    check_containers
    wait_for_services
    create_hdfs_directories
    check_required_files
    load_data_to_hdfs
    create_hive_tables
    load_data_to_hive
    validate_data
    
    success "Enhanced UNSW-NB15 data loading completed successfully!"
    info "Log file: $LOG_FILE"
    info "Access Hive at: http://localhost:10002"
    info "Access Hadoop Web UI at: http://localhost:9870"
    info "Connect to Hive using: docker exec -it hiveserver2 beeline -u 'jdbc:hive2://localhost:10000'"
    echo ""
    echo -e "${GREEN}SUCCESS CRITERIA READY:${NC}"
    echo "You can now run these queries in Hive:"
    echo "  SHOW TABLES;"
    echo "  SELECT COUNT(*) FROM unsw_nb15_main;"
    echo "  SELECT * FROM unsw_nb15_features LIMIT 10;"
    echo "  SELECT * FROM unsw_nb15_events LIMIT 10;"
}

# Handle script arguments  
case "${1:-}" in
    "check")
        check_required_files
        ;;
    "hdfs")
        check_containers
        wait_for_services
        create_hdfs_directories
        check_required_files
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
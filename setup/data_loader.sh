#!/bin/bash

# UNSW-NB15 Data Loader Script
# This script loads the UNSW-NB15 cybersecurity dataset into HDFS

set -e

echo "=== UNSW-NB15 Data Loader ==="
echo "This script loads the UNSW-NB15 dataset into HDFS for analysis"
echo

# Check if data files exist
DATA_DIR="/home/runner/work/hadoop-unsw-nb15-analytics/hadoop-unsw-nb15-analytics/data"
TRAINING_FILE="$DATA_DIR/UNSW_NB15_training-set.csv"
TESTING_FILE="$DATA_DIR/UNSW_NB15_testing-set.csv"
FEATURES_FILE="$DATA_DIR/NUSW-NB15_features.csv"

# Function to download UNSW-NB15 dataset
download_dataset() {
    echo "Downloading UNSW-NB15 dataset..."
    mkdir -p "$DATA_DIR"
    
    # Note: In a real scenario, you would download from the official source
    # For this demo, we'll create sample data files
    echo "Creating sample dataset files for demonstration..."
    
    # Create features file
    cat > "$FEATURES_FILE" << 'EOF'
Name,Type,Description
srcip,nominal,Source IP address
sport,integer,Source port number
dstip,nominal,Destination IP address
dsport,integer,Destination port number
proto,nominal,Transaction protocol
state,nominal,Protocol state
dur,float,Record total duration
sbytes,integer,Source to destination transaction bytes
dbytes,integer,Destination to source transaction bytes
sttl,integer,Source to destination time to live value
dttl,integer,Destination to source time to live value
sloss,integer,Source packets retransmitted or dropped
dloss,integer,Destination packets retransmitted or dropped
service,nominal,http, ftp, smtp, ssh, dns, ftp-data, irc and (-) if not much used service
sload,float,Source bits per second
dload,float,Destination bits per second
spkts,integer,Source to destination packet count
dpkts,integer,Destination to source packet count
swin,integer,Source TCP window advertisement value
dwin,integer,Destination TCP window advertisement value
stcpb,integer,Source TCP base sequence number
dtcpb,integer,Destination TCP base sequence number
smeansz,integer,Mean of the flow packet size transmitted by the src
dmeansz,integer,Mean of the flow packet size transmitted by the dst
trans_depth,integer,Connection state number
res_bdy_len,integer,Content size of the data transferred from server's http service
sjit,float,Source jitter
djit,float,Destination jitter
stime,integer,Record start time
ltime,integer,Record last time
sintpkt,float,Source interpacket arrival time
dintpkt,float,Destination interpacket arrival time
tcprtt,float,TCP connection setup round-trip time
synack,float,TCP connection setup time between SYN and SYN_ACK packets
ackdat,float,TCP connection setup time between SYN_ACK and ACK packets
is_sm_ips_ports,binary,Source and destination IP addresses equal and port numbers equal
ct_state_ttl,integer,Connection of each state according to specific range of values for source/destination time to live
ct_flw_http_mthd,integer,Number of flows that has methods such as Get and Post in http service
is_ftp_login,binary,If the ftp session is accessed by user and password then 1 else 0
ct_ftp_cmd,integer,Number of flows that has a command in ftp session
ct_srv_src,integer,Number of connections that contain the same service and source address in 100 connections according to the last time
ct_srv_dst,integer,Number of connections that contain the same service and destination address in 100 connections according to the last time
ct_dst_ltm,integer,Number of connections of the same destination address in 100 connections according to the last time
ct_src_ltm,integer,Number of connections of the same source address in 100 connections according to the last time
ct_src_dport_ltm,integer,Number of connections of the same source address and destination port in 100 connections according to the last time
ct_dst_sport_ltm,integer,Number of connections of the same destination address and source port in 100 connections according to the last time
ct_dst_src_ltm,integer,Number of connections of the same source and destination address in 100 connections according to the last time
attack_cat,nominal,The name of each attack category
label,binary,0 for normal and 1 for attack
EOF

    # Create sample training data (first few rows for demonstration)
    cat > "$TRAINING_FILE" << 'EOF'
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,sttl,dttl,sloss,dloss,service,sload,dload,spkts,dpkts,swin,dwin,stcpb,dtcpb,smeansz,dmeansz,trans_depth,res_bdy_len,sjit,djit,stime,ltime,sintpkt,dintpkt,tcprtt,synack,ackdat,is_sm_ips_ports,ct_state_ttl,ct_flw_http_mthd,is_ftp_login,ct_ftp_cmd,ct_srv_src,ct_srv_dst,ct_dst_ltm,ct_src_ltm,ct_src_dport_ltm,ct_dst_sport_ltm,ct_dst_src_ltm,attack_cat,label
192.168.1.100,49153,192.168.1.1,53,udp,INT,0.003,56,84,254,254,0,0,dns,0.0,0.0,1,1,0,0,0,0,56,84,0,0,0.0,0.0,1454444400,1454444400,0.0,0.0,0.0,0.0,0.0,0,2,0,0,0,2,2,2,2,2,2,2,Normal,0
10.0.0.1,80,192.168.1.50,49154,tcp,FIN,5.0,1024,2048,64,64,0,0,http,204.8,409.6,10,20,65536,32768,1000,2000,102,102,1,512,0.1,0.05,1454444401,1454444406,0.5,0.25,0.02,0.01,0.005,0,1,1,0,0,1,1,1,1,1,1,1,Normal,0
172.16.0.10,22,192.168.1.75,49155,tcp,FIN,10.5,2048,1024,64,64,0,0,ssh,195.0,97.5,15,10,65536,32768,3000,4000,136,102,2,0,0.2,0.1,1454444402,1454444412,0.7,1.05,0.03,0.015,0.008,0,1,0,0,0,1,1,1,1,1,1,1,Normal,0
192.168.1.200,49156,8.8.8.8,53,udp,INT,0.002,64,128,254,254,0,0,dns,0.0,0.0,1,1,0,0,0,0,64,128,0,0,0.0,0.0,1454444403,1454444403,0.0,0.0,0.0,0.0,0.0,0,2,0,0,0,3,3,3,3,3,3,3,Normal,0
192.168.1.100,49157,192.168.1.10,80,tcp,FIN,2.0,512,1536,64,64,0,0,http,256.0,768.0,5,12,65536,32768,5000,6000,102,128,1,1024,0.05,0.08,1454444404,1454444406,0.4,0.17,0.025,0.012,0.006,0,1,1,0,0,2,2,2,2,2,2,2,Normal,0
EOF

    # Create sample testing data
    cat > "$TESTING_FILE" << 'EOF'
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,sttl,dttl,sloss,dloss,service,sload,dload,spkts,dpkts,swin,dwin,stcpb,dtcpb,smeansz,dmeansz,trans_depth,res_bdy_len,sjit,djit,stime,ltime,sintpkt,dintpkt,tcprtt,synack,ackdat,is_sm_ips_ports,ct_state_ttl,ct_flw_http_mthd,is_ftp_login,ct_ftp_cmd,ct_srv_src,ct_srv_dst,ct_dst_ltm,ct_src_ltm,ct_src_dport_ltm,ct_dst_sport_ltm,ct_dst_src_ltm,attack_cat,label
192.168.1.150,49158,192.168.1.1,53,udp,INT,0.003,56,84,254,254,0,0,dns,0.0,0.0,1,1,0,0,0,0,56,84,0,0,0.0,0.0,1454444500,1454444500,0.0,0.0,0.0,0.0,0.0,0,2,0,0,0,2,2,2,2,2,2,2,Normal,0
10.0.0.2,80,192.168.1.75,49159,tcp,FIN,3.0,2048,4096,64,64,0,0,http,682.7,1365.3,20,40,65536,32768,7000,8000,102,102,1,2048,0.15,0.1,1454444501,1454444504,0.15,0.075,0.02,0.01,0.005,0,1,1,0,0,1,1,1,1,1,1,1,Normal,0
172.16.0.15,23,192.168.1.100,49160,tcp,FIN,1.0,100,50,64,64,0,0,telnet,100.0,50.0,2,1,65536,32768,9000,10000,50,50,1,0,0.5,1.0,1454444502,1454444503,0.5,1.0,0.05,0.025,0.015,0,1,0,0,0,1,1,1,1,1,1,1,Reconnaissance,1
192.168.1.250,49161,8.8.4.4,53,udp,INT,0.002,64,128,254,254,0,0,dns,0.0,0.0,1,1,0,0,0,0,64,128,0,0,0.0,0.0,1454444503,1454444503,0.0,0.0,0.0,0.0,0.0,0,2,0,0,0,3,3,3,3,3,3,3,Normal,0
192.168.1.150,49162,192.168.1.20,80,tcp,FIN,0.5,256,768,64,64,0,0,http,512.0,1536.0,3,8,65536,32768,11000,12000,85,96,1,512,0.1,0.06,1454444504,1454444504,0.17,0.063,0.02,0.01,0.005,0,1,1,0,0,2,2,2,2,2,2,2,Normal,0
EOF

    echo "✓ Sample dataset files created"
}

# Check if the Hadoop cluster is running
if ! docker exec namenode hadoop version > /dev/null 2>&1; then
    echo "ERROR: Hadoop cluster is not running. Please run ./setup/setup.sh first."
    exit 1
fi

# Download dataset if files don't exist
if [[ ! -f "$TRAINING_FILE" || ! -f "$TESTING_FILE" || ! -f "$FEATURES_FILE" ]]; then
    echo "Dataset files not found. Creating sample files..."
    download_dataset
fi

echo "Loading UNSW-NB15 dataset into HDFS..."

# Create HDFS directories
docker exec namenode hadoop fs -mkdir -p /data/unsw-nb15/training
docker exec namenode hadoop fs -mkdir -p /data/unsw-nb15/testing
docker exec namenode hadoop fs -mkdir -p /data/unsw-nb15/features

# Copy data files to containers and then to HDFS
docker cp "$TRAINING_FILE" namenode:/tmp/
docker cp "$TESTING_FILE" namenode:/tmp/
docker cp "$FEATURES_FILE" namenode:/tmp/

# Load files into HDFS
docker exec namenode hadoop fs -put /tmp/UNSW_NB15_training-set.csv /data/unsw-nb15/training/
docker exec namenode hadoop fs -put /tmp/UNSW_NB15_testing-set.csv /data/unsw-nb15/testing/
docker exec namenode hadoop fs -put /tmp/NUSW-NB15_features.csv /data/unsw-nb15/features/

# Verify files are loaded
echo "Verifying data load..."
docker exec namenode hadoop fs -ls /data/unsw-nb15/training/
docker exec namenode hadoop fs -ls /data/unsw-nb15/testing/
docker exec namenode hadoop fs -ls /data/unsw-nb15/features/

# Clean up temporary files
docker exec namenode rm /tmp/UNSW_NB15_training-set.csv
docker exec namenode rm /tmp/UNSW_NB15_testing-set.csv
docker exec namenode rm /tmp/NUSW-NB15_features.csv

echo
echo "✓ UNSW-NB15 dataset successfully loaded into HDFS!"
echo
echo "Dataset locations in HDFS:"
echo "• Training data: /data/unsw-nb15/training/"
echo "• Testing data: /data/unsw-nb15/testing/"
echo "• Features data: /data/unsw-nb15/features/"
echo
echo "Next steps:"
echo "1. Run the Hive table creation scripts: hive/create_tables.hql"
echo "2. Execute complex analytical queries: hive/complex_queries.hql"
echo "3. Use Python visualizations for analysis results"
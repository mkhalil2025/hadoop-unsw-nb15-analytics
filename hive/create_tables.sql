-- UNSW-NB15 Cybersecurity Dataset Schema
-- Enhanced for loading 3 specific CSV files: UNSW-NB15.csv, UNSW-NB15_features.csv, UNSW-NB15_LIST_EVENTS.csv
-- Optimized for Big Data Analytics with Hive
-- Dataset contains 49 features for network intrusion detection

-- Create database for UNSW-NB15 analytics
CREATE DATABASE IF NOT EXISTS unsw_nb15
COMMENT 'UNSW-NB15 Cybersecurity Dataset for Big Data Analytics'
LOCATION '/user/hive/warehouse/unsw_nb15.db';

USE unsw_nb15;

-- ==================================================================
-- TABLE 1: Main UNSW-NB15 dataset (from UNSW-NB15.csv)
-- ==================================================================

-- Main table for UNSW-NB15 network flow data
CREATE TABLE IF NOT EXISTS unsw_nb15_main (
    -- Flow identification
    srcip STRING COMMENT 'Source IP address',
    sport INT COMMENT 'Source port number',
    dstip STRING COMMENT 'Destination IP address', 
    dsport INT COMMENT 'Destination port number',
    proto STRING COMMENT 'Transaction protocol',
    state STRING COMMENT 'Connection state',
    
    -- Flow statistics
    dur DOUBLE COMMENT 'Record total duration',
    sbytes BIGINT COMMENT 'Source to destination transaction bytes',
    dbytes BIGINT COMMENT 'Destination to source transaction bytes',
    sttl INT COMMENT 'Source to destination time to live value',
    dttl INT COMMENT 'Destination to source time to live value',
    sloss INT COMMENT 'Source packets retransmitted or dropped',
    dloss INT COMMENT 'Destination packets retransmitted or dropped',
    
    -- Service and state information
    service STRING COMMENT 'http, ftp, smtp, ssh, dns, ftp-data, irc and (-) if not much used service',
    sload DOUBLE COMMENT 'Source bits per second',
    dload DOUBLE COMMENT 'Destination bits per second',
    spkts INT COMMENT 'Source to destination packet count',
    dpkts INT COMMENT 'Destination to source packet count',
    
    -- Window features (aggregated features)
    swin INT COMMENT 'Source TCP window advertisement value',
    dwin INT COMMENT 'Destination TCP window advertisement value',
    stcpb BIGINT COMMENT 'Source TCP base sequence number',
    dtcpb BIGINT COMMENT 'Destination TCP base sequence number',
    smeansz DOUBLE COMMENT 'Mean of the flow packet size transmitted by the src',
    dmeansz DOUBLE COMMENT 'Mean of the flow packet size transmitted by the dst',
    trans_depth INT COMMENT 'The depth into the connection of http request/response transaction',
    res_bdy_len INT COMMENT 'The content size of the data transferred from the server response',
    
    -- Additional flow features
    sjit DOUBLE COMMENT 'Source jitter (mSec)',
    djit DOUBLE COMMENT 'Destination jitter (mSec)',
    stime TIMESTAMP COMMENT 'Record start time',
    ltime TIMESTAMP COMMENT 'Record last time',
    sintpkt DOUBLE COMMENT 'Source inter-packet arrival time (mSec)',
    dintpkt DOUBLE COMMENT 'Destination inter-packet arrival time (mSec)',
    
    -- TCP connection features
    tcprtt DOUBLE COMMENT 'TCP connection setup round-trip time',
    synack DOUBLE COMMENT 'TCP connection setup time',
    ackdat DOUBLE COMMENT 'TCP connection setup time',
    
    -- Connection state features
    is_sm_ips_ports INT COMMENT 'If source equals to destination IP addresses and port numbers are equal',
    ct_state_ttl INT COMMENT 'No. for each state according to specific range of values for source/destination time to live',
    ct_flw_http_mthd INT COMMENT 'No. of flows that has methods such as Get and Post in http service',
    is_ftp_login INT COMMENT 'If the ftp session is accessed by user and password then 1 else 0',
    ct_ftp_cmd INT COMMENT 'No of flows that has a command in ftp session',
    ct_srv_src INT COMMENT 'No. of connections that contain the same service and source address in 100 connections according to the last time',
    ct_srv_dst INT COMMENT 'No. of connections that contain the same service and destination address in 100 connections according to the last time',
    ct_dst_ltm INT COMMENT 'No. of connections of the same destination address in 100 connections according to the last time',
    ct_src_ltm INT COMMENT 'No. of connections of the same source address in 100 connections according to the last time',
    ct_src_dport_ltm INT COMMENT 'No of connections of the same source address and the destination port in 100 connections according to the last time',
    ct_dst_sport_ltm INT COMMENT 'No of connections of the same destination address and the source port in 100 connections according to the last time',
    ct_dst_src_ltm INT COMMENT 'No of connections of the same source and the destination address in in 100 connections according to the last time',
    
    -- Binary classification label
    label INT COMMENT 'Binary label: 0 for normal, 1 for attack',
    
    -- Multi-class classification label  
    attack_cat STRING COMMENT 'The name of each attack category'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/unsw_nb15.db/unsw_nb15_main'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'comment'='Main UNSW-NB15 network flow records from UNSW-NB15.csv'
);

-- ==================================================================
-- TABLE 2: Feature descriptions (from UNSW-NB15_features.csv)
-- ==================================================================

-- Table for UNSW-NB15 feature descriptions and metadata
CREATE TABLE IF NOT EXISTS unsw_nb15_features (
    name STRING COMMENT 'Feature name',
    type STRING COMMENT 'Feature data type (nominal, integer, float, binary, timestamp)',
    description STRING COMMENT 'Detailed description of the feature'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/unsw_nb15.db/unsw_nb15_features'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'comment'='Feature descriptions and metadata from UNSW-NB15_features.csv'
);

-- ==================================================================
-- TABLE 3: Attack event statistics (from UNSW-NB15_LIST_EVENTS.csv)
-- ==================================================================

-- Table for attack category event statistics
CREATE TABLE IF NOT EXISTS unsw_nb15_events (
    event_id INT COMMENT 'Unique event identifier',
    event_type STRING COMMENT 'Type of network event',
    attack_category STRING COMMENT 'Attack category name',
    event_count BIGINT COMMENT 'Number of events in this category',
    event_description STRING COMMENT 'Detailed description of the event type'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/unsw_nb15.db/unsw_nb15_events'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'comment'='Attack category event statistics from UNSW-NB15_LIST_EVENTS.csv'
);

-- ==================================================================
-- OPTIONAL: Additional analysis tables (kept for advanced analytics)
-- ==================================================================

-- Summary table for attack statistics
CREATE TABLE IF NOT EXISTS attack_summary (
    attack_cat STRING COMMENT 'Attack category',
    proto STRING COMMENT 'Protocol',
    service STRING COMMENT 'Service type',
    attack_count BIGINT COMMENT 'Number of attacks',
    total_sbytes BIGINT COMMENT 'Total source bytes',
    total_dbytes BIGINT COMMENT 'Total destination bytes',
    avg_duration DOUBLE COMMENT 'Average flow duration',
    unique_src_ips INT COMMENT 'Unique source IPs',
    unique_dst_ips INT COMMENT 'Unique destination IPs',
    date_created TIMESTAMP COMMENT 'Summary creation timestamp'
)
STORED AS PARQUET
LOCATION '/user/hive/warehouse/unsw_nb15.db/attack_summary'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'comment'='Pre-aggregated attack statistics for dashboard queries'
);

-- Print success message
SELECT 'UNSW-NB15 database schema created successfully!' as message;
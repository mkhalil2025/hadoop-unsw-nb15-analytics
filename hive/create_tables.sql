-- UNSW-NB15 Cybersecurity Dataset Schema
-- Optimized for Big Data Analytics with Hive
-- Dataset contains 49 features for network intrusion detection

-- Create database for UNSW-NB15 analytics
CREATE DATABASE IF NOT EXISTS unsw_nb15
COMMENT 'UNSW-NB15 Cybersecurity Dataset for Big Data Analytics'
LOCATION '/user/hive/warehouse/unsw_nb15.db';

USE unsw_nb15;

-- Main table for raw UNSW-NB15 data
-- Partitioned by attack category for better query performance
CREATE TABLE IF NOT EXISTS network_flows (
    -- Flow identification
    srcip STRING COMMENT 'Source IP address',
    sport INT COMMENT 'Source port number',
    dstip STRING COMMENT 'Destination IP address', 
    dsport INT COMMENT 'Destination port number',
    proto STRING COMMENT 'Transaction protocol',
    
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
    is_sm_ips_ports BOOLEAN COMMENT 'If source equals to destination IP addresses and port numbers are equal',
    ct_state_ttl INT COMMENT 'No. for each state according to specific range of values for source/destination time to live',
    ct_flw_http_mthd INT COMMENT 'No. of flows that has methods such as Get and Post in http service',
    is_ftp_login BOOLEAN COMMENT 'If the ftp session is accessed by user and password then 1 else 0',
    ct_ftp_cmd INT COMMENT 'No of flows that has a command in ftp session',
    ct_srv_src INT COMMENT 'No. of connections that contain the same service and source address in 100 connections according to the last time',
    ct_srv_dst INT COMMENT 'No. of connections that contain the same service and destination address in 100 connections according to the last time',
    ct_dst_ltm INT COMMENT 'No. of connections of the same destination address in 100 connections according to the last time',
    ct_src_ltm INT COMMENT 'No. of connections of the same source address in 100 connections according to the last time',
    ct_src_dport_ltm INT COMMENT 'No of connections of the same source address and the destination port in 100 connections according to the last time',
    ct_dst_sport_ltm INT COMMENT 'No of connections of the same destination address and the source port in 100 connections according to the last time',
    ct_dst_src_ltm INT COMMENT 'No of connections of the same source and the destination address in in 100 connections according to the last time',
    
    -- Binary classification label
    label BOOLEAN COMMENT 'Binary label: 0 for normal, 1 for attack',
    
    -- Multi-class classification label  
    attack_cat STRING COMMENT 'The name of each attack category'
)
PARTITIONED BY (
    year INT COMMENT 'Year of the record',
    month INT COMMENT 'Month of the record'
)
STORED AS PARQUET
LOCATION '/user/hive/warehouse/unsw_nb15.db/network_flows'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'comment'='Main table for UNSW-NB15 network flow records partitioned by year and month'
);

-- Create external table for loading raw CSV data
CREATE TABLE IF NOT EXISTS network_flows_raw (
    srcip STRING,
    sport INT,
    dstip STRING,
    dsport INT,
    proto STRING,
    state STRING,
    dur DOUBLE,
    sbytes BIGINT,
    dbytes BIGINT,
    sttl INT,
    dttl INT,
    sloss INT,
    dloss INT,
    service STRING,
    sload DOUBLE,
    dload DOUBLE,
    spkts INT,
    dpkts INT,
    swin INT,
    dwin INT,
    stcpb BIGINT,
    dtcpb BIGINT,
    smeansz DOUBLE,
    dmeansz DOUBLE,
    trans_depth INT,
    res_bdy_len INT,
    sjit DOUBLE,
    djit DOUBLE,
    stime TIMESTAMP,
    ltime TIMESTAMP,
    sintpkt DOUBLE,
    dintpkt DOUBLE,
    tcprtt DOUBLE,
    synack DOUBLE,
    ackdat DOUBLE,
    is_sm_ips_ports BOOLEAN,
    ct_state_ttl INT,
    ct_flw_http_mthd INT,
    is_ftp_login BOOLEAN,
    ct_ftp_cmd INT,
    ct_srv_src INT,
    ct_srv_dst INT,
    ct_dst_ltm INT,
    ct_src_ltm INT,
    ct_src_dport_ltm INT,
    ct_dst_sport_ltm INT,
    ct_dst_src_ltm INT,
    label BOOLEAN,
    attack_cat STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/unsw_nb15.db/network_flows_raw'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'comment'='Raw CSV data loading table for UNSW-NB15 dataset'
);

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

-- Geographic analysis table (if IP geolocation data available)
CREATE TABLE IF NOT EXISTS geo_analysis (
    country_code STRING COMMENT 'Country code',
    region STRING COMMENT 'Geographic region',
    attack_cat STRING COMMENT 'Attack category',
    hour_of_day INT COMMENT 'Hour of the day (0-23)',
    attack_count BIGINT COMMENT 'Number of attacks',
    data_transferred BIGINT COMMENT 'Total bytes transferred',
    analysis_date DATE COMMENT 'Date of analysis'
)
PARTITIONED BY (
    analysis_year INT,
    analysis_month INT
)
STORED AS PARQUET
LOCATION '/user/hive/warehouse/unsw_nb15.db/geo_analysis'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'comment'='Geographic analysis of attack patterns'
);

-- Anomaly detection results table
CREATE TABLE IF NOT EXISTS anomaly_scores (
    flow_id STRING COMMENT 'Unique flow identifier',
    srcip STRING COMMENT 'Source IP',
    dstip STRING COMMENT 'Destination IP',
    proto STRING COMMENT 'Protocol',
    service STRING COMMENT 'Service',
    anomaly_score DOUBLE COMMENT 'Calculated anomaly score',
    zscore_sbytes DOUBLE COMMENT 'Z-score for source bytes',
    zscore_dbytes DOUBLE COMMENT 'Z-score for destination bytes',
    zscore_duration DOUBLE COMMENT 'Z-score for duration',
    is_anomaly BOOLEAN COMMENT 'True if flagged as anomaly',
    detection_timestamp TIMESTAMP COMMENT 'When anomaly was detected'
)
STORED AS PARQUET
LOCATION '/user/hive/warehouse/unsw_nb15.db/anomaly_scores'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'comment'='Results from anomaly detection algorithms'
);

-- Create indexes for common query patterns
-- Note: Hive 3.x supports indexes via materialized views

-- Index for IP-based queries
CREATE MATERIALIZED VIEW IF NOT EXISTS ip_index AS
SELECT srcip, dstip, COUNT(*) as flow_count,
       SUM(CAST(label AS INT)) as attack_count
FROM network_flows
GROUP BY srcip, dstip;

-- Index for time-based queries  
CREATE MATERIALIZED VIEW IF NOT EXISTS time_index AS
SELECT 
    EXTRACT(HOUR FROM stime) as hour_of_day,
    EXTRACT(DAY FROM stime) as day_of_month,
    attack_cat,
    COUNT(*) as flow_count
FROM network_flows
WHERE stime IS NOT NULL
GROUP BY EXTRACT(HOUR FROM stime), EXTRACT(DAY FROM stime), attack_cat;

-- Index for protocol and service analysis
CREATE MATERIALIZED VIEW IF NOT EXISTS protocol_service_index AS
SELECT proto, service, attack_cat,
       COUNT(*) as flow_count,
       AVG(dur) as avg_duration,
       SUM(sbytes + dbytes) as total_bytes
FROM network_flows
WHERE proto IS NOT NULL AND service IS NOT NULL
GROUP BY proto, service, attack_cat;

-- Print success message
SELECT 'UNSW-NB15 database schema created successfully!' as message;
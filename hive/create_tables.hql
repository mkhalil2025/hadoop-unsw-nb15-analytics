-- UNSW-NB15 Cybersecurity Dataset - Database and Table Creation
-- This script creates the database and tables for UNSW-NB15 analysis

-- Create the cybersecurity analytics database
CREATE DATABASE IF NOT EXISTS cybersecurity_analytics
COMMENT 'Database for UNSW-NB15 cybersecurity dataset analysis'
LOCATION '/user/hive/warehouse/cybersecurity_analytics.db';

USE cybersecurity_analytics;

-- Drop tables if they exist (for clean re-creation)
DROP TABLE IF EXISTS unsw_nb15_features;
DROP TABLE IF EXISTS unsw_nb15_training;
DROP TABLE IF EXISTS unsw_nb15_testing;
DROP TABLE IF EXISTS unsw_nb15_combined;

-- Create features table to store dataset feature descriptions
CREATE TABLE IF NOT EXISTS unsw_nb15_features (
    name STRING,
    type STRING,
    description STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- Load features data
LOAD DATA INPATH '/data/unsw-nb15/features/NUSW-NB15_features.csv' 
INTO TABLE unsw_nb15_features;

-- Create training dataset table with optimized data types
CREATE TABLE IF NOT EXISTS unsw_nb15_training (
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
    swin BIGINT,
    dwin BIGINT,
    stcpb BIGINT,
    dtcpb BIGINT,
    smeansz INT,
    dmeansz INT,
    trans_depth INT,
    res_bdy_len BIGINT,
    sjit DOUBLE,
    djit DOUBLE,
    stime BIGINT,
    ltime BIGINT,
    sintpkt DOUBLE,
    dintpkt DOUBLE,
    tcprtt DOUBLE,
    synack DOUBLE,
    ackdat DOUBLE,
    is_sm_ips_ports INT,
    ct_state_ttl INT,
    ct_flw_http_mthd INT,
    is_ftp_login INT,
    ct_ftp_cmd INT,
    ct_srv_src INT,
    ct_srv_dst INT,
    ct_dst_ltm INT,
    ct_src_ltm INT,
    ct_src_dport_ltm INT,
    ct_dst_sport_ltm INT,
    ct_dst_src_ltm INT,
    attack_cat STRING,
    label INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- Load training data
LOAD DATA INPATH '/data/unsw-nb15/training/UNSW_NB15_training-set.csv' 
INTO TABLE unsw_nb15_training;

-- Create testing dataset table with same schema
CREATE TABLE IF NOT EXISTS unsw_nb15_testing (
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
    swin BIGINT,
    dwin BIGINT,
    stcpb BIGINT,
    dtcpb BIGINT,
    smeansz INT,
    dmeansz INT,
    trans_depth INT,
    res_bdy_len BIGINT,
    sjit DOUBLE,
    djit DOUBLE,
    stime BIGINT,
    ltime BIGINT,
    sintpkt DOUBLE,
    dintpkt DOUBLE,
    tcprtt DOUBLE,
    synack DOUBLE,
    ackdat DOUBLE,
    is_sm_ips_ports INT,
    ct_state_ttl INT,
    ct_flw_http_mthd INT,
    is_ftp_login INT,
    ct_ftp_cmd INT,
    ct_srv_src INT,
    ct_srv_dst INT,
    ct_dst_ltm INT,
    ct_src_ltm INT,
    ct_src_dport_ltm INT,
    ct_dst_sport_ltm INT,
    ct_dst_src_ltm INT,
    attack_cat STRING,
    label INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- Load testing data
LOAD DATA INPATH '/data/unsw-nb15/testing/UNSW_NB15_testing-set.csv' 
INTO TABLE unsw_nb15_testing;

-- Create combined view for comprehensive analysis
CREATE TABLE IF NOT EXISTS unsw_nb15_combined AS
SELECT 
    srcip, sport, dstip, dsport, proto, state, dur,
    sbytes, dbytes, sttl, dttl, sloss, dloss, service,
    sload, dload, spkts, dpkts, swin, dwin, stcpb, dtcpb,
    smeansz, dmeansz, trans_depth, res_bdy_len, sjit, djit,
    stime, ltime, sintpkt, dintpkt, tcprtt, synack, ackdat,
    is_sm_ips_ports, ct_state_ttl, ct_flw_http_mthd, 
    is_ftp_login, ct_ftp_cmd, ct_srv_src, ct_srv_dst,
    ct_dst_ltm, ct_src_ltm, ct_src_dport_ltm, ct_dst_sport_ltm,
    ct_dst_src_ltm, attack_cat, label,
    'training' as dataset_source
FROM unsw_nb15_training
UNION ALL
SELECT 
    srcip, sport, dstip, dsport, proto, state, dur,
    sbytes, dbytes, sttl, dttl, sloss, dloss, service,
    sload, dload, spkts, dpkts, swin, dwin, stcpb, dtcpb,
    smeansz, dmeansz, trans_depth, res_bdy_len, sjit, djit,
    stime, ltime, sintpkt, dintpkt, tcprtt, synack, ackdat,
    is_sm_ips_ports, ct_state_ttl, ct_flw_http_mthd, 
    is_ftp_login, ct_ftp_cmd, ct_srv_src, ct_srv_dst,
    ct_dst_ltm, ct_src_ltm, ct_src_dport_ltm, ct_dst_sport_ltm,
    ct_dst_src_ltm, attack_cat, label,
    'testing' as dataset_source
FROM unsw_nb15_testing;

-- Create partitioned table for better performance on large datasets
CREATE TABLE IF NOT EXISTS unsw_nb15_partitioned (
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
    swin BIGINT,
    dwin BIGINT,
    stcpb BIGINT,
    dtcpb BIGINT,
    smeansz INT,
    dmeansz INT,
    trans_depth INT,
    res_bdy_len BIGINT,
    sjit DOUBLE,
    djit DOUBLE,
    stime BIGINT,
    ltime BIGINT,
    sintpkt DOUBLE,
    dintpkt DOUBLE,
    tcprtt DOUBLE,
    synack DOUBLE,
    ackdat DOUBLE,
    is_sm_ips_ports INT,
    ct_state_ttl INT,
    ct_flw_http_mthd INT,
    is_ftp_login INT,
    ct_ftp_cmd INT,
    ct_srv_src INT,
    ct_srv_dst INT,
    ct_dst_ltm INT,
    ct_src_ltm INT,
    ct_src_dport_ltm INT,
    ct_dst_sport_ltm INT,
    ct_dst_src_ltm INT,
    dataset_source STRING
)
PARTITIONED BY (attack_cat STRING, label INT)
STORED AS PARQUET;

-- Insert data into partitioned table
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT INTO TABLE unsw_nb15_partitioned PARTITION (attack_cat, label)
SELECT 
    srcip, sport, dstip, dsport, proto, state, dur,
    sbytes, dbytes, sttl, dttl, sloss, dloss, service,
    sload, dload, spkts, dpkts, swin, dwin, stcpb, dtcpb,
    smeansz, dmeansz, trans_depth, res_bdy_len, sjit, djit,
    stime, ltime, sintpkt, dintpkt, tcprtt, synack, ackdat,
    is_sm_ips_ports, ct_state_ttl, ct_flw_http_mthd, 
    is_ftp_login, ct_ftp_cmd, ct_srv_src, ct_srv_dst,
    ct_dst_ltm, ct_src_ltm, ct_src_dport_ltm, ct_dst_sport_ltm,
    ct_dst_src_ltm, dataset_source, attack_cat, label
FROM unsw_nb15_combined;

-- Display table information
SHOW TABLES;
DESCRIBE unsw_nb15_training;
DESCRIBE unsw_nb15_testing;
DESCRIBE unsw_nb15_combined;

-- Basic verification queries
SELECT COUNT(*) as total_records FROM unsw_nb15_combined;
SELECT attack_cat, COUNT(*) as count FROM unsw_nb15_combined GROUP BY attack_cat;
SELECT label, COUNT(*) as count FROM unsw_nb15_combined GROUP BY label;
-- UNSW-NB15 Complex Analytical Queries for Big Data Analytics Assignment
-- These queries demonstrate advanced Hive analytics capabilities for cybersecurity analysis

USE cybersecurity_analytics;

-- =====================================================================
-- QUERY 1: Attack Distribution Analysis with Temporal Patterns
-- =====================================================================
-- Analysis of attack patterns over time with statistical measures

SELECT 
    attack_cat,
    COUNT(*) as attack_count,
    ROUND(AVG(dur), 4) as avg_duration,
    ROUND(STDDEV(dur), 4) as stddev_duration,
    ROUND(PERCENTILE_APPROX(dur, 0.5), 4) as median_duration,
    ROUND(PERCENTILE_APPROX(dur, 0.95), 4) as p95_duration,
    ROUND(AVG(sbytes + dbytes), 2) as avg_total_bytes,
    ROUND(AVG(spkts + dpkts), 2) as avg_total_packets,
    MIN(FROM_UNIXTIME(stime)) as earliest_attack,
    MAX(FROM_UNIXTIME(ltime)) as latest_attack,
    ROUND(
        (MAX(ltime) - MIN(stime)) / 3600.0, 2
    ) as attack_window_hours
FROM unsw_nb15_combined 
WHERE label = 1 AND attack_cat != 'Normal'
GROUP BY attack_cat
HAVING COUNT(*) > 0
ORDER BY attack_count DESC;

-- =====================================================================
-- QUERY 2: Network Service Vulnerability Assessment
-- =====================================================================
-- Comprehensive analysis of service vulnerabilities and attack patterns

WITH service_stats AS (
    SELECT 
        service,
        proto,
        COUNT(*) as total_connections,
        SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_connections,
        ROUND(
            (SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
        ) as attack_rate_percent,
        ROUND(AVG(dur), 4) as avg_duration,
        ROUND(AVG(sbytes), 2) as avg_src_bytes,
        ROUND(AVG(dbytes), 2) as avg_dst_bytes,
        COUNT(DISTINCT srcip) as unique_sources,
        COUNT(DISTINCT dstip) as unique_destinations
    FROM unsw_nb15_combined
    WHERE service != '-' AND service IS NOT NULL
    GROUP BY service, proto
),
service_rankings AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY attack_rate_percent DESC) as vulnerability_rank,
        CASE 
            WHEN attack_rate_percent >= 80 THEN 'Critical'
            WHEN attack_rate_percent >= 50 THEN 'High'
            WHEN attack_rate_percent >= 20 THEN 'Medium'
            ELSE 'Low'
        END as risk_level
    FROM service_stats
    WHERE total_connections >= 10
)
SELECT 
    service,
    proto,
    total_connections,
    attack_connections,
    attack_rate_percent,
    risk_level,
    vulnerability_rank,
    avg_duration,
    avg_src_bytes,
    avg_dst_bytes,
    unique_sources,
    unique_destinations
FROM service_rankings
ORDER BY vulnerability_rank;

-- =====================================================================
-- QUERY 3: Traffic Pattern Investigation using Window Functions
-- =====================================================================
-- Advanced traffic pattern analysis with sliding window calculations

WITH hourly_traffic AS (
    SELECT 
        FROM_UNIXTIME(stime, 'yyyy-MM-dd HH') as hour_timestamp,
        proto,
        service,
        COUNT(*) as connection_count,
        SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_count,
        ROUND(AVG(sbytes + dbytes), 2) as avg_bytes_per_hour,
        COUNT(DISTINCT srcip) as unique_sources,
        COUNT(DISTINCT dstip) as unique_destinations
    FROM unsw_nb15_combined
    WHERE stime > 0
    GROUP BY FROM_UNIXTIME(stime, 'yyyy-MM-dd HH'), proto, service
),
traffic_with_windows AS (
    SELECT 
        *,
        AVG(connection_count) OVER (
            PARTITION BY proto, service 
            ORDER BY hour_timestamp 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) as moving_avg_connections,
        LAG(connection_count, 1) OVER (
            PARTITION BY proto, service 
            ORDER BY hour_timestamp
        ) as prev_hour_connections,
        LEAD(connection_count, 1) OVER (
            PARTITION BY proto, service 
            ORDER BY hour_timestamp
        ) as next_hour_connections,
        RANK() OVER (
            PARTITION BY proto, service 
            ORDER BY connection_count DESC
        ) as traffic_rank
    FROM hourly_traffic
)
SELECT 
    hour_timestamp,
    proto,
    service,
    connection_count,
    attack_count,
    ROUND(
        (attack_count * 100.0) / NULLIF(connection_count, 0), 2
    ) as hourly_attack_rate,
    ROUND(moving_avg_connections, 2) as moving_avg_connections,
    CASE 
        WHEN prev_hour_connections IS NULL THEN 'N/A'
        WHEN connection_count > prev_hour_connections * 1.5 THEN 'Spike'
        WHEN connection_count < prev_hour_connections * 0.5 THEN 'Drop'
        ELSE 'Normal'
    END as traffic_pattern,
    traffic_rank,
    avg_bytes_per_hour,
    unique_sources,
    unique_destinations
FROM traffic_with_windows
WHERE connection_count > 0
ORDER BY proto, service, hour_timestamp;

-- =====================================================================
-- QUERY 4: Protocol Security Analysis with Advanced Grouping
-- =====================================================================
-- Multi-dimensional analysis of protocol security characteristics

WITH protocol_security AS (
    SELECT 
        proto,
        state,
        CASE 
            WHEN dsport BETWEEN 1 AND 1023 THEN 'Well-Known'
            WHEN dsport BETWEEN 1024 AND 49151 THEN 'Registered'
            WHEN dsport BETWEEN 49152 AND 65535 THEN 'Dynamic'
            ELSE 'Unknown'
        END as port_category,
        COUNT(*) as total_flows,
        SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as malicious_flows,
        ROUND(AVG(dur), 4) as avg_duration,
        ROUND(AVG(sbytes), 2) as avg_src_bytes,
        ROUND(AVG(dbytes), 2) as avg_dst_bytes,
        ROUND(AVG(spkts), 2) as avg_src_packets,
        ROUND(AVG(dpkts), 2) as avg_dst_packets,
        ROUND(AVG(tcprtt), 6) as avg_rtt,
        COUNT(DISTINCT CONCAT(srcip, ':', dstip)) as unique_connections
    FROM unsw_nb15_combined
    GROUP BY proto, state, 
        CASE 
            WHEN dsport BETWEEN 1 AND 1023 THEN 'Well-Known'
            WHEN dsport BETWEEN 1024 AND 49151 THEN 'Registered'
            WHEN dsport BETWEEN 49152 AND 65535 THEN 'Dynamic'
            ELSE 'Unknown'
        END
),
protocol_with_stats AS (
    SELECT 
        *,
        ROUND(
            (malicious_flows * 100.0) / NULLIF(total_flows, 0), 2
        ) as maliciousness_rate,
        ROUND(
            avg_src_bytes / NULLIF(avg_src_packets, 0), 2
        ) as avg_src_packet_size,
        ROUND(
            avg_dst_bytes / NULLIF(avg_dst_packets, 0), 2
        ) as avg_dst_packet_size,
        CASE 
            WHEN proto = 'tcp' AND state IN ('FIN', 'CON') THEN 'Complete'
            WHEN proto = 'tcp' AND state IN ('INT', 'REQ') THEN 'Incomplete'
            WHEN proto = 'udp' THEN 'Connectionless'
            ELSE 'Other'
        END as connection_completeness
    FROM protocol_security
)
SELECT 
    proto,
    state,
    port_category,
    connection_completeness,
    total_flows,
    malicious_flows,
    maliciousness_rate,
    CASE 
        WHEN maliciousness_rate >= 50 THEN 'High Risk'
        WHEN maliciousness_rate >= 20 THEN 'Medium Risk'
        WHEN maliciousness_rate >= 5 THEN 'Low Risk'
        ELSE 'Minimal Risk'
    END as security_assessment,
    avg_duration,
    avg_src_bytes,
    avg_dst_bytes,
    avg_src_packet_size,
    avg_dst_packet_size,
    avg_rtt,
    unique_connections,
    ROUND(
        total_flows * 100.0 / SUM(total_flows) OVER(), 2
    ) as traffic_percentage
FROM protocol_with_stats
WHERE total_flows >= 5
ORDER BY maliciousness_rate DESC, total_flows DESC;

-- =====================================================================
-- QUERY 5: Advanced Statistical Analysis and Anomaly Detection
-- =====================================================================
-- Comprehensive statistical analysis for anomaly detection

WITH traffic_statistics AS (
    SELECT 
        srcip,
        COUNT(*) as total_connections,
        COUNT(DISTINCT dstip) as unique_destinations,
        COUNT(DISTINCT dsport) as unique_ports,
        COUNT(DISTINCT service) as unique_services,
        SUM(sbytes + dbytes) as total_bytes,
        SUM(spkts + dpkts) as total_packets,
        AVG(dur) as avg_connection_duration,
        MAX(dur) as max_connection_duration,
        SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_connections,
        COLLECT_SET(attack_cat) as attack_types_array
    FROM unsw_nb15_combined
    GROUP BY srcip
),
statistical_measures AS (
    SELECT 
        *,
        ROUND(
            (attack_connections * 100.0) / NULLIF(total_connections, 0), 2
        ) as attack_percentage,
        ROUND(
            total_bytes / NULLIF(total_connections, 0), 2
        ) as avg_bytes_per_connection,
        ROUND(
            total_packets / NULLIF(total_connections, 0), 2
        ) as avg_packets_per_connection,
        SIZE(attack_types_array) as attack_diversity,
        CASE 
            WHEN unique_destinations / NULLIF(total_connections, 0) > 0.8 THEN 'Scanner'
            WHEN total_connections > 1000 THEN 'High Volume'
            WHEN attack_connections > 0 THEN 'Compromised'
            ELSE 'Normal'
        END as behavior_classification
    FROM traffic_statistics
),
percentile_ranks AS (
    SELECT 
        *,
        PERCENT_RANK() OVER (ORDER BY total_connections) as connection_percentile,
        PERCENT_RANK() OVER (ORDER BY unique_destinations) as destination_percentile,
        PERCENT_RANK() OVER (ORDER BY total_bytes) as bytes_percentile,
        PERCENT_RANK() OVER (ORDER BY attack_percentage) as attack_percentile
    FROM statistical_measures
)
SELECT 
    srcip,
    behavior_classification,
    total_connections,
    unique_destinations,
    unique_ports,
    unique_services,
    total_bytes,
    total_packets,
    ROUND(avg_connection_duration, 4) as avg_connection_duration,
    ROUND(max_connection_duration, 4) as max_connection_duration,
    attack_connections,
    attack_percentage,
    attack_diversity,
    ROUND(avg_bytes_per_connection, 2) as avg_bytes_per_connection,
    ROUND(avg_packets_per_connection, 2) as avg_packets_per_connection,
    ROUND(connection_percentile * 100, 2) as connection_percentile,
    ROUND(destination_percentile * 100, 2) as destination_percentile,
    ROUND(bytes_percentile * 100, 2) as bytes_percentile,
    ROUND(attack_percentile * 100, 2) as attack_percentile,
    CASE 
        WHEN connection_percentile > 0.95 OR 
             destination_percentile > 0.95 OR 
             bytes_percentile > 0.95 OR 
             attack_percentile > 0.95 THEN 'Anomalous'
        WHEN connection_percentile > 0.8 OR 
             attack_percentage > 50 THEN 'Suspicious'
        ELSE 'Normal'
    END as anomaly_score
FROM percentile_ranks
WHERE total_connections > 1
ORDER BY 
    CASE 
        WHEN connection_percentile > 0.95 OR 
             destination_percentile > 0.95 OR 
             bytes_percentile > 0.95 OR 
             attack_percentile > 0.95 THEN 1
        WHEN connection_percentile > 0.8 OR 
             attack_percentage > 50 THEN 2
        ELSE 3
    END,
    attack_percentage DESC,
    total_connections DESC;
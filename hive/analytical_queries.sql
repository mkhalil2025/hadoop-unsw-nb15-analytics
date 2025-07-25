-- Advanced HiveQL Queries for UNSW-NB15 Dataset Analysis
-- UEL-CN-7031 Big Data Analytics Assignment
-- 4+ Complex Analytical Queries Demonstrating Different Big Data Concepts

USE unsw_nb15;

-- =================================================================
-- QUERY 1: Attack Pattern Analysis by Protocol and Service
-- Concepts: Complex aggregations, window functions, ranking
-- =================================================================

-- Q1a: Comprehensive attack pattern analysis with ranking
WITH attack_patterns AS (
    SELECT 
        proto,
        service,
        attack_cat,
        COUNT(*) as attack_count,
        SUM(sbytes + dbytes) as total_bytes_transferred,
        AVG(dur) as avg_duration,
        MIN(dur) as min_duration,
        MAX(dur) as max_duration,
        COUNT(DISTINCT srcip) as unique_source_ips,
        COUNT(DISTINCT dstip) as unique_target_ips,
        AVG(spkts + dpkts) as avg_total_packets,
        STDDEV(sbytes + dbytes) as stddev_bytes
    FROM network_flows 
    WHERE label = true  -- Only attack traffic
      AND attack_cat IS NOT NULL 
      AND attack_cat != 'Normal'
    GROUP BY proto, service, attack_cat
),
ranked_patterns AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY proto ORDER BY attack_count DESC) as attack_rank_by_proto,
        ROW_NUMBER() OVER (PARTITION BY service ORDER BY total_bytes_transferred DESC) as bytes_rank_by_service,
        PERCENT_RANK() OVER (ORDER BY attack_count) as attack_percentile
    FROM attack_patterns
)
SELECT 
    proto,
    service,
    attack_cat,
    attack_count,
    ROUND(total_bytes_transferred / 1024 / 1024, 2) as total_mb_transferred,
    ROUND(avg_duration, 4) as avg_duration_sec,
    unique_source_ips,
    unique_target_ips,
    ROUND(avg_total_packets, 2) as avg_packets,
    attack_rank_by_proto,
    bytes_rank_by_service,
    ROUND(attack_percentile * 100, 2) as attack_percentile,
    CASE 
        WHEN attack_percentile >= 0.9 THEN 'High Frequency'
        WHEN attack_percentile >= 0.7 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END as frequency_category
FROM ranked_patterns
WHERE attack_rank_by_proto <= 3  -- Top 3 attacks per protocol
ORDER BY proto, attack_rank_by_proto;

-- Q1b: Protocol-Service Attack Matrix with Pivot-like Analysis
SELECT 
    proto,
    SUM(CASE WHEN attack_cat = 'Analysis' THEN 1 ELSE 0 END) as analysis_attacks,
    SUM(CASE WHEN attack_cat = 'Backdoor' THEN 1 ELSE 0 END) as backdoor_attacks,
    SUM(CASE WHEN attack_cat = 'DoS' THEN 1 ELSE 0 END) as dos_attacks,
    SUM(CASE WHEN attack_cat = 'Exploits' THEN 1 ELSE 0 END) as exploit_attacks,
    SUM(CASE WHEN attack_cat = 'Fuzzers' THEN 1 ELSE 0 END) as fuzzer_attacks,
    SUM(CASE WHEN attack_cat = 'Generic' THEN 1 ELSE 0 END) as generic_attacks,
    SUM(CASE WHEN attack_cat = 'Reconnaissance' THEN 1 ELSE 0 END) as recon_attacks,
    SUM(CASE WHEN attack_cat = 'Shellcode' THEN 1 ELSE 0 END) as shellcode_attacks,
    SUM(CASE WHEN attack_cat = 'Worms' THEN 1 ELSE 0 END) as worm_attacks,
    COUNT(*) as total_attacks,
    ROUND(AVG(sbytes + dbytes), 2) as avg_bytes_per_attack
FROM network_flows
WHERE label = true AND attack_cat IS NOT NULL AND attack_cat != 'Normal'
GROUP BY proto
HAVING COUNT(*) > 100  -- Focus on protocols with significant attack volume
ORDER BY total_attacks DESC;

-- =================================================================
-- QUERY 2: Geographic and Temporal Analysis with Time-based Aggregations
-- Concepts: Time series analysis, geographic patterns, complex joins
-- =================================================================

-- Q2a: Hourly attack patterns with moving averages
WITH hourly_attacks AS (
    SELECT 
        EXTRACT(HOUR FROM stime) as hour_of_day,
        EXTRACT(DATE FROM stime) as attack_date,
        attack_cat,
        COUNT(*) as hourly_attack_count,
        SUM(sbytes + dbytes) as hourly_bytes,
        COUNT(DISTINCT CONCAT(srcip, ':', dstip)) as unique_flows_per_hour
    FROM network_flows
    WHERE label = true 
      AND stime IS NOT NULL 
      AND attack_cat IS NOT NULL 
      AND attack_cat != 'Normal'
    GROUP BY EXTRACT(HOUR FROM stime), EXTRACT(DATE FROM stime), attack_cat
),
hourly_with_moving_avg AS (
    SELECT *,
        AVG(hourly_attack_count) OVER (
            PARTITION BY hour_of_day 
            ORDER BY attack_date 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) as moving_avg_attacks,
        LAG(hourly_attack_count, 1) OVER (
            PARTITION BY hour_of_day, attack_cat 
            ORDER BY attack_date
        ) as prev_day_same_hour,
        MAX(hourly_attack_count) OVER (
            PARTITION BY hour_of_day
        ) as max_attacks_this_hour
    FROM hourly_attacks
)
SELECT 
    hour_of_day,
    attack_cat,
    AVG(hourly_attack_count) as avg_attacks_per_hour,
    MAX(hourly_attack_count) as peak_attacks,
    MIN(hourly_attack_count) as min_attacks,
    STDDEV(hourly_attack_count) as attack_variability,
    AVG(moving_avg_attacks) as smoothed_avg,
    SUM(hourly_bytes) / 1024 / 1024 as total_mb_per_hour,
    COUNT(DISTINCT attack_date) as days_observed,
    CASE 
        WHEN hour_of_day BETWEEN 0 AND 5 THEN 'Night'
        WHEN hour_of_day BETWEEN 6 AND 11 THEN 'Morning' 
        WHEN hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END as time_period
FROM hourly_with_moving_avg
GROUP BY hour_of_day, attack_cat
HAVING COUNT(DISTINCT attack_date) >= 3  -- At least 3 days of data
ORDER BY hour_of_day, avg_attacks_per_hour DESC;

-- Q2b: IP Geographic Clustering Analysis (Simulated geographic data)
WITH ip_attack_summary AS (
    SELECT 
        srcip,
        dstip,
        attack_cat,
        COUNT(*) as attack_frequency,
        SUM(sbytes + dbytes) as total_bytes,
        AVG(dur) as avg_duration,
        -- Simulate geographic regions based on IP ranges
        CASE 
            WHEN SUBSTR(srcip, 1, 3) IN ('10.', '192', '172') THEN 'Internal'
            WHEN SUBSTR(srcip, 1, 2) IN ('1.', '2.', '3.') THEN 'Asia-Pacific'
            WHEN SUBSTR(srcip, 1, 2) IN ('4.', '5.', '6.') THEN 'North America'
            WHEN SUBSTR(srcip, 1, 2) IN ('7.', '8.', '9.') THEN 'Europe'
            ELSE 'Other'
        END as src_region,
        CASE 
            WHEN SUBSTR(dstip, 1, 3) IN ('10.', '192', '172') THEN 'Internal'
            WHEN SUBSTR(dstip, 1, 2) IN ('1.', '2.', '3.') THEN 'Asia-Pacific'
            WHEN SUBSTR(dstip, 1, 2) IN ('4.', '5.', '6.') THEN 'North America'
            WHEN SUBSTR(dstip, 1, 2) IN ('7.', '8.', '9.') THEN 'Europe'
            ELSE 'Other'
        END as dst_region
    FROM network_flows
    WHERE label = true AND attack_cat IS NOT NULL AND attack_cat != 'Normal'
)
SELECT 
    src_region,
    dst_region,
    attack_cat,
    COUNT(DISTINCT srcip) as unique_attackers,
    COUNT(DISTINCT dstip) as unique_targets,
    SUM(attack_frequency) as total_attacks,
    ROUND(AVG(total_bytes) / 1024, 2) as avg_kb_per_attack,
    ROUND(AVG(avg_duration), 4) as avg_duration_sec,
    -- Calculate attack intensity score
    ROUND(
        (SUM(attack_frequency) * AVG(total_bytes) / 1000000) / 
        NULLIF(COUNT(DISTINCT srcip), 0), 2
    ) as attack_intensity_score
FROM ip_attack_summary
GROUP BY src_region, dst_region, attack_cat
HAVING SUM(attack_frequency) > 50  -- Focus on significant attack patterns
ORDER BY attack_intensity_score DESC, total_attacks DESC;

-- =================================================================
-- QUERY 3: Anomaly Detection Using Statistical Functions
-- Concepts: Statistical analysis, outlier detection, percentiles
-- =================================================================

-- Q3a: Statistical anomaly detection with z-scores and percentiles
WITH flow_statistics AS (
    SELECT 
        srcip,
        dstip,
        proto,
        service,
        sbytes,
        dbytes,
        dur,
        spkts,
        dpkts,
        attack_cat,
        label,
        -- Calculate z-scores for numerical features
        (sbytes - AVG(sbytes) OVER()) / NULLIF(STDDEV(sbytes) OVER(), 0) as zscore_sbytes,
        (dbytes - AVG(dbytes) OVER()) / NULLIF(STDDEV(dbytes) OVER(), 0) as zscore_dbytes,
        (dur - AVG(dur) OVER()) / NULLIF(STDDEV(dur) OVER(), 0) as zscore_duration,
        (spkts - AVG(spkts) OVER()) / NULLIF(STDDEV(spkts) OVER(), 0) as zscore_spkts,
        
        -- Calculate percentiles
        PERCENT_RANK() OVER (ORDER BY sbytes) as percentile_sbytes,
        PERCENT_RANK() OVER (ORDER BY dbytes) as percentile_dbytes,
        PERCENT_RANK() OVER (ORDER BY dur) as percentile_duration,
        
        -- Protocol-specific statistics
        AVG(sbytes) OVER (PARTITION BY proto) as proto_avg_sbytes,
        STDDEV(sbytes) OVER (PARTITION BY proto) as proto_stddev_sbytes
    FROM network_flows
    WHERE sbytes IS NOT NULL 
      AND dbytes IS NOT NULL 
      AND dur IS NOT NULL
      AND spkts IS NOT NULL 
      AND dpkts IS NOT NULL
),
anomaly_detection AS (
    SELECT *,
        -- Composite anomaly score
        (
            ABS(zscore_sbytes) + ABS(zscore_dbytes) + 
            ABS(zscore_duration) + ABS(zscore_spkts)
        ) / 4.0 as composite_anomaly_score,
        
        -- Multiple anomaly detection criteria
        CASE 
            WHEN ABS(zscore_sbytes) > 3 OR ABS(zscore_dbytes) > 3 OR 
                 ABS(zscore_duration) > 3 THEN true
            ELSE false
        END as is_statistical_outlier,
        
        CASE 
            WHEN percentile_sbytes > 0.99 OR percentile_dbytes > 0.99 OR 
                 percentile_duration > 0.99 THEN true
            ELSE false
        END as is_extreme_percentile,
        
        -- Protocol-specific anomaly
        CASE 
            WHEN ABS(sbytes - proto_avg_sbytes) > (3 * NULLIF(proto_stddev_sbytes, 0)) 
            THEN true
            ELSE false
        END as is_protocol_anomaly
        
    FROM flow_statistics
)
SELECT 
    srcip,
    dstip,
    proto,
    service,
    ROUND(sbytes / 1024, 2) as sbytes_kb,
    ROUND(dbytes / 1024, 2) as dbytes_kb,
    ROUND(dur, 4) as duration_sec,
    ROUND(composite_anomaly_score, 3) as anomaly_score,
    ROUND(zscore_sbytes, 2) as z_sbytes,
    ROUND(zscore_dbytes, 2) as z_dbytes,
    ROUND(zscore_duration, 2) as z_duration,
    is_statistical_outlier,
    is_extreme_percentile,
    is_protocol_anomaly,
    CASE WHEN label = true THEN attack_cat ELSE 'Normal' END as actual_label,
    -- Anomaly classification
    CASE 
        WHEN composite_anomaly_score > 3 THEN 'High Anomaly'
        WHEN composite_anomaly_score > 2 THEN 'Medium Anomaly'
        WHEN composite_anomaly_score > 1 THEN 'Low Anomaly'
        ELSE 'Normal Pattern'
    END as anomaly_classification
FROM anomaly_detection
WHERE (is_statistical_outlier = true OR 
       is_extreme_percentile = true OR 
       is_protocol_anomaly = true OR
       composite_anomaly_score > 2)
ORDER BY composite_anomaly_score DESC
LIMIT 100;

-- Q3b: Time-based anomaly patterns
WITH daily_flow_stats AS (
    SELECT 
        EXTRACT(DATE FROM stime) as flow_date,
        proto,
        COUNT(*) as daily_flow_count,
        AVG(sbytes + dbytes) as avg_daily_bytes,
        SUM(CASE WHEN label = true THEN 1 ELSE 0 END) as daily_attack_count,
        AVG(dur) as avg_daily_duration
    FROM network_flows
    WHERE stime IS NOT NULL
    GROUP BY EXTRACT(DATE FROM stime), proto
),
daily_anomalies AS (
    SELECT *,
        (daily_flow_count - AVG(daily_flow_count) OVER (PARTITION BY proto)) / 
        NULLIF(STDDEV(daily_flow_count) OVER (PARTITION BY proto), 0) as zscore_daily_flows,
        
        (avg_daily_bytes - AVG(avg_daily_bytes) OVER (PARTITION BY proto)) / 
        NULLIF(STDDEV(avg_daily_bytes) OVER (PARTITION BY proto), 0) as zscore_daily_bytes,
        
        LAG(daily_attack_count, 1) OVER (PARTITION BY proto ORDER BY flow_date) as prev_day_attacks,
        
        LEAD(daily_attack_count, 1) OVER (PARTITION BY proto ORDER BY flow_date) as next_day_attacks
    FROM daily_flow_stats
)
SELECT 
    flow_date,
    proto,
    daily_flow_count,
    ROUND(avg_daily_bytes / 1024, 2) as avg_daily_kb,
    daily_attack_count,
    ROUND(zscore_daily_flows, 2) as flow_zscore,
    ROUND(zscore_daily_bytes, 2) as bytes_zscore,
    prev_day_attacks,
    next_day_attacks,
    CASE 
        WHEN ABS(zscore_daily_flows) > 2 OR ABS(zscore_daily_bytes) > 2 THEN 'Anomalous Day'
        ELSE 'Normal Day'
    END as day_classification,
    -- Attack surge detection
    CASE 
        WHEN daily_attack_count > (COALESCE(prev_day_attacks, 0) * 3) THEN 'Attack Surge'
        WHEN daily_attack_count < (COALESCE(prev_day_attacks, 0) * 0.3) AND prev_day_attacks > 0 THEN 'Attack Drop'
        ELSE 'Stable'
    END as attack_trend
FROM daily_anomalies
WHERE ABS(zscore_daily_flows) > 1.5 OR ABS(zscore_daily_bytes) > 1.5
ORDER BY ABS(zscore_daily_flows) DESC, flow_date DESC;

-- =================================================================
-- QUERY 4: Multi-dimensional Analysis with Advanced Window Functions
-- Concepts: Complex window functions, ranking, cohort analysis
-- =================================================================

-- Q4a: Attack evolution analysis with window functions
WITH attack_timeline AS (
    SELECT 
        srcip,
        dstip,
        attack_cat,
        stime,
        dur,
        sbytes + dbytes as total_bytes,
        ROW_NUMBER() OVER (PARTITION BY srcip ORDER BY stime) as attack_sequence,
        LAG(stime) OVER (PARTITION BY srcip ORDER BY stime) as prev_attack_time,
        LEAD(stime) OVER (PARTITION BY srcip ORDER BY stime) as next_attack_time,
        LAG(attack_cat) OVER (PARTITION BY srcip ORDER BY stime) as prev_attack_type,
        LEAD(attack_cat) OVER (PARTITION BY srcip ORDER BY stime) as next_attack_type
    FROM network_flows
    WHERE label = true 
      AND attack_cat IS NOT NULL 
      AND attack_cat != 'Normal'
      AND stime IS NOT NULL
),
attack_patterns AS (
    SELECT *,
        -- Time between attacks
        CASE 
            WHEN prev_attack_time IS NOT NULL THEN 
                (UNIX_TIMESTAMP(stime) - UNIX_TIMESTAMP(prev_attack_time)) / 3600.0
            ELSE NULL
        END as hours_since_prev_attack,
        
        -- Attack type transitions
        CASE 
            WHEN prev_attack_type IS NOT NULL AND prev_attack_type != attack_cat 
            THEN CONCAT(prev_attack_type, ' -> ', attack_cat)
            ELSE NULL
        END as attack_transition,
        
        -- Cumulative statistics per attacker
        SUM(total_bytes) OVER (
            PARTITION BY srcip 
            ORDER BY stime 
            ROWS UNBOUNDED PRECEDING
        ) as cumulative_bytes,
        
        COUNT(*) OVER (
            PARTITION BY srcip 
            ORDER BY stime 
            ROWS UNBOUNDED PRECEDING
        ) as cumulative_attacks
    FROM attack_timeline
)
SELECT 
    srcip as attacker_ip,
    attack_cat,
    attack_sequence,
    stime as attack_time,
    ROUND(dur, 4) as duration_sec,
    ROUND(total_bytes / 1024, 2) as attack_size_kb,
    prev_attack_type,
    attack_transition,
    ROUND(hours_since_prev_attack, 2) as hours_since_last,
    ROUND(cumulative_bytes / 1024 / 1024, 2) as cumulative_mb,
    cumulative_attacks,
    -- Attacker behavior classification
    CASE 
        WHEN cumulative_attacks >= 10 THEN 'Persistent Attacker'
        WHEN hours_since_prev_attack IS NOT NULL AND hours_since_prev_attack < 1 THEN 'Rapid Attacker'
        WHEN attack_transition IS NOT NULL THEN 'Multi-Vector Attacker'
        ELSE 'Opportunistic Attacker'
    END as attacker_profile,
    
    -- Attack intensity scoring
    ROUND(
        (cumulative_attacks * LOG(cumulative_bytes + 1)) / 
        NULLIF(GREATEST(hours_since_prev_attack, 1), 0), 2
    ) as intensity_score
FROM attack_patterns
WHERE attack_sequence <= 20  -- Focus on first 20 attacks per IP
ORDER BY srcip, attack_sequence;

-- Q4b: Service vulnerability analysis with ranking
WITH service_attacks AS (
    SELECT 
        service,
        dstip as target_ip,
        dsport as target_port,
        attack_cat,
        COUNT(*) as attack_count,
        COUNT(DISTINCT srcip) as unique_attackers,
        SUM(sbytes + dbytes) as total_attack_bytes,
        AVG(dur) as avg_attack_duration,
        MIN(stime) as first_attack,
        MAX(stime) as last_attack
    FROM network_flows
    WHERE label = true 
      AND attack_cat IS NOT NULL 
      AND attack_cat != 'Normal'
      AND service IS NOT NULL
      AND service != '-'
    GROUP BY service, dstip, dsport, attack_cat
),
service_rankings AS (
    SELECT *,
        -- Rankings within each service
        ROW_NUMBER() OVER (
            PARTITION BY service 
            ORDER BY attack_count DESC
        ) as vulnerability_rank,
        
        DENSE_RANK() OVER (
            PARTITION BY service 
            ORDER BY unique_attackers DESC
        ) as attacker_diversity_rank,
        
        -- Percentile rankings
        PERCENT_RANK() OVER (
            PARTITION BY service 
            ORDER BY attack_count
        ) as attack_percentile,
        
        -- Cross-service rankings
        ROW_NUMBER() OVER (ORDER BY attack_count DESC) as global_vulnerability_rank,
        
        -- Time-based analysis
        (UNIX_TIMESTAMP(last_attack) - UNIX_TIMESTAMP(first_attack)) / 3600.0 as attack_duration_hours
    FROM service_attacks
)
SELECT 
    service,
    target_ip,
    target_port,
    attack_cat,
    attack_count,
    unique_attackers,
    ROUND(total_attack_bytes / 1024 / 1024, 2) as total_mb_attacked,
    ROUND(avg_attack_duration, 4) as avg_duration_sec,
    vulnerability_rank,
    attacker_diversity_rank,
    global_vulnerability_rank,
    ROUND(attack_percentile * 100, 2) as attack_percentile,
    ROUND(attack_duration_hours, 2) as attack_span_hours,
    first_attack,
    last_attack,
    -- Risk assessment
    CASE 
        WHEN attack_percentile >= 0.9 AND unique_attackers >= 5 THEN 'Critical Risk'
        WHEN attack_percentile >= 0.7 OR unique_attackers >= 3 THEN 'High Risk'
        WHEN attack_percentile >= 0.5 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_level,
    
    -- Calculate attack rate (attacks per hour)
    ROUND(
        attack_count / NULLIF(GREATEST(attack_duration_hours, 1), 0), 2
    ) as attacks_per_hour
FROM service_rankings
WHERE vulnerability_rank <= 5  -- Top 5 most attacked targets per service
ORDER BY service, vulnerability_rank;
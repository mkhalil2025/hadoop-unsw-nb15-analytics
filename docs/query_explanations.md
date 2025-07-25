# Advanced HiveQL Queries Explanation
## UNSW-NB15 Big Data Analytics - UEL-CN-7031

This document provides detailed explanations of the four advanced analytical queries designed for the UNSW-NB15 cybersecurity dataset. Each query demonstrates different Big Data concepts and analytical techniques.

## 📊 Query Overview

| Query | Focus Area | Big Data Concepts | Complexity |
|-------|------------|-------------------|------------|
| **Q1** | Attack Pattern Analysis | Aggregations, Window Functions, Ranking | ⭐⭐⭐ |
| **Q2** | Geographic & Temporal Analysis | Time Series, Moving Averages, Joins | ⭐⭐⭐⭐ |
| **Q3** | Anomaly Detection | Statistical Functions, Percentiles, Z-scores | ⭐⭐⭐⭐⭐ |
| **Q4** | Multi-dimensional Analysis | Advanced Window Functions, Cohort Analysis | ⭐⭐⭐⭐⭐ |

---

## 🎯 Query 1: Attack Pattern Analysis by Protocol and Service

### Purpose
Analyze attack patterns across different network protocols and services to identify:
- Most targeted protocols and services
- Attack frequency and severity rankings
- Byte transfer patterns per attack type
- Source and target diversity analysis

### Key Concepts Demonstrated
- **Complex Aggregations**: Multiple GROUP BY clauses with various aggregate functions
- **Window Functions**: ROW_NUMBER(), PERCENT_RANK() for ranking and percentile calculations
- **Conditional Logic**: CASE statements for classification
- **Performance Optimization**: Efficient grouping and filtering strategies

### Query Structure

#### Part A: Comprehensive Pattern Analysis
```sql
WITH attack_patterns AS (
    SELECT 
        proto,
        service,
        attack_cat,
        COUNT(*) as attack_count,
        SUM(sbytes + dbytes) as total_bytes_transferred,
        AVG(dur) as avg_duration,
        COUNT(DISTINCT srcip) as unique_source_ips,
        COUNT(DISTINCT dstip) as unique_target_ips,
        AVG(spkts + dpkts) as avg_total_packets,
        STDDEV(sbytes + dbytes) as stddev_bytes
    FROM network_flows 
    WHERE label = true AND attack_cat IS NOT NULL AND attack_cat != 'Normal'
    GROUP BY proto, service, attack_cat
)
```

**What it does**:
- Aggregates attack data by protocol, service, and attack category
- Calculates comprehensive statistics for each combination
- Filters to include only actual attack traffic

#### Part B: Ranking and Classification
```sql
ranked_patterns AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY proto ORDER BY attack_count DESC) as attack_rank_by_proto,
        ROW_NUMBER() OVER (PARTITION BY service ORDER BY total_bytes_transferred DESC) as bytes_rank_by_service,
        PERCENT_RANK() OVER (ORDER BY attack_count) as attack_percentile
    FROM attack_patterns
)
```

**Advanced techniques**:
- **PARTITION BY**: Groups data for ranking within categories
- **ROW_NUMBER()**: Assigns unique ranks within partitions
- **PERCENT_RANK()**: Calculates percentile positions (0-1 scale)

#### Part C: Protocol-Service Attack Matrix
```sql
SELECT 
    proto,
    SUM(CASE WHEN attack_cat = 'Analysis' THEN 1 ELSE 0 END) as analysis_attacks,
    SUM(CASE WHEN attack_cat = 'Backdoor' THEN 1 ELSE 0 END) as backdoor_attacks,
    -- ... more attack categories
FROM network_flows
GROUP BY proto
```

**Pivot technique**: Uses conditional aggregation to create a cross-tabulation matrix

### Business Insights
- **Security Priority**: Identifies which protocols need immediate attention
- **Resource Allocation**: Shows where to focus security monitoring
- **Attack Evolution**: Reveals changing attack patterns over time
- **Threat Intelligence**: Provides data for threat hunting activities

---

## 🌍 Query 2: Geographic and Temporal Analysis

### Purpose
Perform time-series analysis of attack patterns with geographic correlation to understand:
- Hourly attack trends and seasonality
- Geographic distribution of attacks
- Time-based attack evolution
- Regional threat patterns

### Key Concepts Demonstrated
- **Time Series Analysis**: Temporal grouping and trend analysis
- **Moving Averages**: Smoothing techniques for trend identification
- **LAG/LEAD Functions**: Time-shifted comparisons
- **Geographic Simulation**: IP-based regional classification

### Query Structure

#### Part A: Hourly Attack Patterns with Moving Averages
```sql
WITH hourly_attacks AS (
    SELECT 
        EXTRACT(HOUR FROM stime) as hour_of_day,
        EXTRACT(DATE FROM stime) as attack_date,
        attack_cat,
        COUNT(*) as hourly_attack_count,
        SUM(sbytes + dbytes) as hourly_bytes
    FROM network_flows
    WHERE label = true AND stime IS NOT NULL
    GROUP BY EXTRACT(HOUR FROM stime), EXTRACT(DATE FROM stime), attack_cat
)
```

**Time extraction**: Uses EXTRACT() to separate temporal components

#### Part B: Moving Average Calculation
```sql
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
        ) as prev_day_same_hour
    FROM hourly_attacks
)
```

**Advanced windowing**:
- **ROWS BETWEEN**: Defines the window frame for moving averages
- **LAG()**: Accesses previous row values for comparison
- **Complex partitioning**: Multiple partition keys for precise calculations

#### Part C: Geographic Clustering
```sql
-- Simulated geographic regions based on IP ranges
CASE 
    WHEN SUBSTR(srcip, 1, 3) IN ('10.', '192', '172') THEN 'Internal'
    WHEN SUBSTR(srcip, 1, 2) IN ('1.', '2.', '3.') THEN 'Asia-Pacific'
    WHEN SUBSTR(srcip, 1, 2) IN ('4.', '5.', '6.') THEN 'North America'
    WHEN SUBSTR(srcip, 1, 2) IN ('7.', '8.', '9.') THEN 'Europe'
    ELSE 'Other'
END as src_region
```

**Geographic simulation**: Demonstrates how to classify IPs into regions

### Business Applications
- **Incident Response**: Identify peak attack hours for staffing
- **Global Monitoring**: Understand regional threat landscapes
- **Predictive Analytics**: Use trends to forecast attack patterns
- **Compliance**: Regional data protection and monitoring requirements

---

## 🔍 Query 3: Anomaly Detection Using Statistical Functions

### Purpose
Implement statistical anomaly detection techniques to identify:
- Outliers using z-score analysis
- Extreme percentile values
- Protocol-specific anomalies
- Time-based anomaly patterns

### Key Concepts Demonstrated
- **Statistical Functions**: Z-scores, percentiles, standard deviations
- **Outlier Detection**: Multiple detection criteria
- **Window Functions**: Statistical calculations across datasets
- **Composite Scoring**: Multi-dimensional anomaly assessment

### Query Structure

#### Part A: Statistical Feature Calculation
```sql
WITH flow_statistics AS (
    SELECT 
        srcip, dstip, proto, service, sbytes, dbytes, dur, spkts, dpkts,
        -- Calculate z-scores for numerical features
        (sbytes - AVG(sbytes) OVER()) / NULLIF(STDDEV(sbytes) OVER(), 0) as zscore_sbytes,
        (dbytes - AVG(dbytes) OVER()) / NULLIF(STDDEV(dbytes) OVER(), 0) as zscore_dbytes,
        -- Calculate percentiles
        PERCENT_RANK() OVER (ORDER BY sbytes) as percentile_sbytes,
        PERCENT_RANK() OVER (ORDER BY dbytes) as percentile_dbytes
    FROM network_flows
    WHERE sbytes IS NOT NULL AND dbytes IS NOT NULL
)
```

**Z-score calculation**: 
- Formula: `(value - mean) / standard_deviation`
- `NULLIF()` prevents division by zero
- Window functions calculate global statistics

#### Part B: Multi-Criteria Anomaly Detection
```sql
anomaly_detection AS (
    SELECT *,
        -- Composite anomaly score
        (ABS(zscore_sbytes) + ABS(zscore_dbytes) + ABS(zscore_duration) + ABS(zscore_spkts)) / 4.0 as composite_anomaly_score,
        
        -- Multiple detection criteria
        CASE 
            WHEN ABS(zscore_sbytes) > 3 OR ABS(zscore_dbytes) > 3 OR ABS(zscore_duration) > 3 
            THEN true ELSE false
        END as is_statistical_outlier,
        
        CASE 
            WHEN percentile_sbytes > 0.99 OR percentile_dbytes > 0.99 OR percentile_duration > 0.99 
            THEN true ELSE false
        END as is_extreme_percentile
    FROM flow_statistics
)
```

**Detection methods**:
- **Statistical outliers**: Z-score > 3 (99.7% rule)
- **Extreme percentiles**: Top 1% of values
- **Composite scoring**: Average of multiple z-scores

#### Part C: Time-based Anomaly Analysis
```sql
WITH daily_flow_stats AS (
    SELECT 
        EXTRACT(DATE FROM stime) as flow_date,
        proto,
        COUNT(*) as daily_flow_count,
        AVG(sbytes + dbytes) as avg_daily_bytes
    FROM network_flows
    GROUP BY EXTRACT(DATE FROM stime), proto
),
daily_anomalies AS (
    SELECT *,
        (daily_flow_count - AVG(daily_flow_count) OVER (PARTITION BY proto)) / 
        NULLIF(STDDEV(daily_flow_count) OVER (PARTITION BY proto), 0) as zscore_daily_flows
    FROM daily_flow_stats
)
```

**Temporal anomalies**: Detect unusual daily patterns within protocols

### Statistical Principles
- **Z-score threshold**: 3 standard deviations (99.7% confidence)
- **Percentile analysis**: Top/bottom 1% as extreme values
- **Multi-dimensional scoring**: Combines multiple features
- **Protocol normalization**: Within-group anomaly detection

---

## 🔄 Query 4: Multi-dimensional Analysis with Advanced Window Functions

### Purpose
Perform sophisticated multi-dimensional analysis including:
- Attack evolution and sequence analysis
- Attacker behavior profiling
- Service vulnerability assessment
- Time-series pattern recognition

### Key Concepts Demonstrated
- **Advanced Window Functions**: Complex frame specifications
- **Sequence Analysis**: Attack progression tracking
- **Behavioral Analytics**: Pattern recognition in time series
- **Multi-level Aggregation**: Nested analytical functions

### Query Structure

#### Part A: Attack Timeline Analysis
```sql
WITH attack_timeline AS (
    SELECT 
        srcip, dstip, attack_cat, stime, dur, sbytes + dbytes as total_bytes,
        ROW_NUMBER() OVER (PARTITION BY srcip ORDER BY stime) as attack_sequence,
        LAG(stime) OVER (PARTITION BY srcip ORDER BY stime) as prev_attack_time,
        LAG(attack_cat) OVER (PARTITION BY srcip ORDER BY stime) as prev_attack_type,
        -- Cumulative statistics per attacker
        SUM(total_bytes) OVER (
            PARTITION BY srcip 
            ORDER BY stime 
            ROWS UNBOUNDED PRECEDING
        ) as cumulative_bytes
    FROM network_flows
    WHERE label = true AND attack_cat IS NOT NULL
)
```

**Sequence tracking**:
- **ROW_NUMBER()**: Orders attacks per source IP
- **LAG()**: Accesses previous attack information
- **Cumulative SUM**: Running totals with UNBOUNDED PRECEDING

#### Part B: Attack Pattern Recognition
```sql
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
        END as attack_transition
    FROM attack_timeline
)
```

**Pattern analysis**:
- **Time calculations**: Inter-attack intervals
- **Transition detection**: Attack type changes
- **String concatenation**: Readable transition patterns

#### Part C: Service Vulnerability Analysis
```sql
WITH service_attacks AS (
    SELECT 
        service, dstip, dsport, attack_cat,
        COUNT(*) as attack_count,
        COUNT(DISTINCT srcip) as unique_attackers,
        MIN(stime) as first_attack,
        MAX(stime) as last_attack
    FROM network_flows
    WHERE label = true AND service IS NOT NULL
    GROUP BY service, dstip, dsport, attack_cat
),
service_rankings AS (
    SELECT *,
        -- Rankings within each service
        ROW_NUMBER() OVER (PARTITION BY service ORDER BY attack_count DESC) as vulnerability_rank,
        DENSE_RANK() OVER (PARTITION BY service ORDER BY unique_attackers DESC) as attacker_diversity_rank,
        -- Cross-service rankings
        ROW_NUMBER() OVER (ORDER BY attack_count DESC) as global_vulnerability_rank
    FROM service_attacks
)
```

**Multi-level ranking**:
- **Within-service ranking**: Most attacked targets per service
- **Diversity ranking**: Services with most varied attackers
- **Global ranking**: Overall vulnerability assessment

### Advanced Techniques
- **Unbounded windows**: `ROWS UNBOUNDED PRECEDING` for cumulative calculations
- **Complex partitioning**: Multiple partition keys for precise analysis
- **Conditional aggregation**: Context-aware statistical calculations
- **Multi-dimensional ranking**: Different ranking criteria simultaneously

---

## 🎯 Query Performance Optimization Tips

### 1. Partitioning Strategy
```sql
-- Effective partitioning
PARTITION BY (year, month)  -- Time-based partitioning for temporal queries

-- Avoid over-partitioning
-- Bad: PARTITION BY (year, month, day, hour)
-- Good: PARTITION BY (year, month)
```

### 2. Predicate Pushdown
```sql
-- Filter early in the query
WHERE label = true AND attack_cat IS NOT NULL AND attack_cat != 'Normal'
-- Apply filters in WITH clauses to reduce data volume
```

### 3. Window Function Optimization
```sql
-- Reuse window specifications
WINDOW w AS (PARTITION BY srcip ORDER BY stime)
SELECT 
    ROW_NUMBER() OVER w,
    LAG(attack_cat) OVER w,
    SUM(bytes) OVER w
```

### 4. Index Usage
```sql
-- Leverage materialized views (Hive indexes)
CREATE MATERIALIZED VIEW ip_index AS
SELECT srcip, dstip, COUNT(*) as flow_count
GROUP BY srcip, dstip;
```

## 🧠 Learning Outcomes

After working with these queries, students will understand:

### Technical Skills
- **Advanced SQL**: Complex window functions and analytical operations
- **Big Data Processing**: Efficient query design for large datasets
- **Statistical Analysis**: Practical application of statistical methods
- **Performance Tuning**: Query optimization techniques

### Analytical Thinking
- **Pattern Recognition**: Identifying trends and anomalies in data
- **Multi-dimensional Analysis**: Combining multiple analytical perspectives
- **Cybersecurity Insights**: Understanding attack patterns and indicators
- **Business Intelligence**: Translating data into actionable insights

### Big Data Concepts
- **Distributed Computing**: How queries execute across clusters
- **Data Partitioning**: Strategies for organizing large datasets
- **Memory Management**: Efficient resource utilization
- **Scalability**: Designing queries that work at any scale

---

## 📚 Additional Query Ideas for Students

### Beginner Level
1. **Basic Attack Counts**: Count attacks by category and protocol
2. **Top Talkers**: Find most active source and destination IPs
3. **Service Analysis**: Analyze most targeted services
4. **Hourly Patterns**: Basic time-of-day analysis

### Intermediate Level
1. **Attack Correlation**: Find correlations between different attack types
2. **Bandwidth Analysis**: Analyze data transfer patterns
3. **Geographic Clustering**: Group attacks by simulated geographic regions
4. **Service Port Analysis**: Analyze attacks by destination ports

### Advanced Level
1. **Machine Learning Integration**: Use Hive with Spark MLlib
2. **Real-time Analytics**: Implement streaming analytics patterns
3. **Custom UDFs**: Write user-defined functions for specialized analysis
4. **Cross-dataset Joins**: Combine UNSW-NB15 with other security datasets

---

**Next Steps**: Practice modifying these queries and creating your own analytical insights! Each query serves as a foundation for deeper cybersecurity analysis and big data exploration.
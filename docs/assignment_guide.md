# UEL-CN-7031 Big Data Analytics Assignment Guide

This guide provides step-by-step instructions for completing the Big Data Analytics coursework using the UNSW-NB15 cybersecurity dataset with Hadoop, Hive, and Python visualization tools.

## Assignment Overview

### Learning Objectives

Upon completion of this assignment, you will be able to:
- Set up and configure a distributed Hadoop environment
- Process large-scale cybersecurity datasets using Hive
- Write complex SQL queries for big data analytics
- Create comprehensive visualizations for cybersecurity analysis
- Generate professional reports with insights and recommendations

### Assessment Criteria

1. **Technical Implementation (40%)**
   - Successful Hadoop cluster setup
   - Correct Hive table creation and data loading
   - Query execution and result validation

2. **Analytical Complexity (30%)**
   - Use of advanced SQL features (window functions, CTEs, aggregations)
   - Multi-dimensional analysis approaches
   - Statistical analysis and pattern recognition

3. **Visualization and Reporting (20%)**
   - Quality and clarity of visualizations
   - Appropriate chart types for data representation
   - Professional report formatting

4. **Insights and Interpretation (10%)**
   - Meaningful analysis of results
   - Cybersecurity domain understanding
   - Actionable recommendations

## Phase 1: Environment Setup (15-20 minutes)

### 1.1 Initial Setup

Follow the setup guide to establish your environment:

```bash
# Clone the repository
git clone https://github.com/mkhalil2025/hadoop-unsw-nb15-analytics.git
cd hadoop-unsw-nb15-analytics

# Run automated setup
./setup/setup.sh

# Load the dataset
./setup/data_loader.sh
```

### 1.2 Verification Checklist

Ensure all services are running:

- [ ] Hadoop Namenode accessible at http://localhost:9870
- [ ] YARN ResourceManager at http://localhost:8088
- [ ] Hive Server responding to connections
- [ ] Jupyter Notebook available at http://localhost:8888
- [ ] UNSW-NB15 data loaded in HDFS

**Screenshot Task 1**: Take a screenshot of the Hadoop Namenode web interface showing the cluster overview.

### 1.3 Database Setup

Create the Hive database and tables:

```bash
# Connect to Hive
docker exec -it hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

# Run table creation script
!run /path/to/hive/create_tables.hql
```

Verify table creation:

```sql
USE cybersecurity_analytics;
SHOW TABLES;
DESCRIBE unsw_nb15_combined;
SELECT COUNT(*) FROM unsw_nb15_combined;
```

**Screenshot Task 2**: Take a screenshot showing the successful table creation and record count.

## Phase 2: Complex Query Development (45-60 minutes)

### 2.1 Query 1: Attack Distribution Analysis with Temporal Patterns

**Objective**: Analyze attack patterns over time with statistical measures.

**Requirements**:
- Group attacks by category
- Calculate statistical measures (mean, median, percentiles)
- Include temporal analysis
- Rank attack types by severity

**Expected Output**: Attack categories with frequency, duration statistics, and time patterns.

**Implementation Hint**: Use the provided query in `hive/complex_queries.hql` as a starting point.

```sql
-- Your Query 1 implementation here
-- Should include: aggregations, statistical functions, temporal analysis
```

**Analysis Questions**:
1. Which attack category is most frequent?
2. What are the duration characteristics of different attacks?
3. When do attacks typically occur?

### 2.2 Query 2: Network Service Vulnerability Assessment

**Objective**: Identify vulnerable network services and protocols.

**Requirements**:
- Analyze service-protocol combinations
- Calculate attack rates and risk levels
- Use window functions for ranking
- Include traffic volume analysis

**Expected Output**: Services ranked by vulnerability with risk assessments.

```sql
-- Your Query 2 implementation here
-- Should include: window functions, complex joins, case statements
```

**Analysis Questions**:
1. Which services have the highest attack rates?
2. How does protocol type affect security?
3. What traffic patterns indicate vulnerabilities?

### 2.3 Query 3: Traffic Pattern Investigation using Window Functions

**Objective**: Analyze traffic patterns using advanced window functions.

**Requirements**:
- Implement sliding window calculations
- Use LAG/LEAD functions for temporal comparisons
- Calculate moving averages
- Detect traffic anomalies

**Expected Output**: Hourly traffic patterns with trend analysis.

```sql
-- Your Query 3 implementation here
-- Should include: window functions, moving averages, trend analysis
```

**Analysis Questions**:
1. What are the normal traffic patterns?
2. When do traffic spikes occur?
3. How do attack patterns correlate with traffic volume?

### 2.4 Query 4: Protocol Security Analysis with Advanced Grouping

**Objective**: Multi-dimensional analysis of protocol security.

**Requirements**:
- Use GROUPING SETS or CUBE operations
- Analyze by port categories
- Calculate security metrics
- Implement risk scoring

**Expected Output**: Comprehensive protocol security assessment.

```sql
-- Your Query 4 implementation here
-- Should include: advanced grouping, multi-dimensional analysis, risk scoring
```

**Analysis Questions**:
1. Which protocols are most secure/vulnerable?
2. How do port ranges affect security?
3. What connection patterns indicate threats?

### 2.5 Query Documentation

For each query, document:
- **Purpose**: What the query analyzes
- **Methodology**: How the analysis is performed
- **Key Findings**: Important insights discovered
- **Business Impact**: Implications for cybersecurity

## Phase 3: Python Visualization Development (30-45 minutes)

### 3.1 Environment Setup

Launch Jupyter and install requirements:

```bash
# Start Jupyter (already running from setup)
# Navigate to http://localhost:8888

# In Jupyter, install Python packages
!pip install -r requirements.txt
```

### 3.2 Hive Connection Setup

Test the connection to Hive:

```python
from hive_connection import HiveConnectionManager

# Test connection
hive_conn = HiveConnectionManager()
if hive_conn.connect():
    print("Connected to Hive successfully!")
    
    # Test query
    result = hive_conn.execute_query("SELECT COUNT(*) FROM cybersecurity_analytics.unsw_nb15_combined")
    print(f"Total records: {result.iloc[0, 0] if result is not None else 'Error'}")
    
    hive_conn.close_connection()
else:
    print("Failed to connect to Hive")
```

### 3.3 Visualization Development

Create the following visualizations:

#### 3.3.1 Attack Distribution Charts

```python
from visualizations import CybersecurityVisualizer

visualizer = CybersecurityVisualizer()
visualizer.connect_to_hive()

# Create attack distribution visualization
visualizer.plot_attack_distribution()
```

**Requirements**:
- Bar chart showing attack frequency
- Pie chart showing percentage distribution
- Color-coded by attack severity

#### 3.3.2 Service Vulnerability Analysis

```python
# Create service vulnerability plots
visualizer.plot_service_vulnerability(top_n=15)
```

**Requirements**:
- Horizontal bar chart of attack rates
- Service usage volume analysis
- Risk level color coding

#### 3.3.3 Protocol Security Heatmaps

```python
# Create protocol security heatmap
visualizer.plot_protocol_security_heatmap()
```

**Requirements**:
- Heatmap of protocol security metrics
- Correlation analysis
- Risk level visualization

#### 3.3.4 Temporal Pattern Analysis

```python
# Create temporal pattern visualization
visualizer.plot_temporal_patterns()
```

**Requirements**:
- Time series of attack patterns
- Hourly distribution analysis
- Trend identification

### 3.4 Interactive Dashboard

Create an interactive dashboard:

```python
# Generate interactive dashboard
dashboard = visualizer.create_interactive_dashboard()
dashboard.show()
```

**Screenshot Task 3**: Take screenshots of at least 3 different visualizations showing clear insights.

## Phase 4: Report Generation and Analysis (20-30 minutes)

### 4.1 Automated Report Generation

Generate a comprehensive report:

```python
# Generate complete report
report_path = visualizer.generate_comprehensive_report()
print(f"Report generated at: {report_path}")
```

### 4.2 Key Analysis Points

Address the following in your analysis:

#### 4.2.1 Attack Landscape Analysis
- Most prevalent attack types
- Attack frequency trends
- Severity assessments

#### 4.2.2 Network Security Assessment
- Vulnerable services identification
- Protocol security evaluation
- Risk prioritization

#### 4.2.3 Operational Insights
- Peak attack times
- Traffic pattern anomalies
- Defensive recommendations

#### 4.2.4 Business Impact
- Risk quantification
- Resource allocation recommendations
- Security strategy implications

### 4.3 Professional Report Structure

Organize your final report with:

1. **Executive Summary** (1 page)
   - Key findings overview
   - Critical vulnerabilities
   - Recommended actions

2. **Methodology** (1-2 pages)
   - Data processing approach
   - Query design rationale
   - Analysis techniques used

3. **Technical Analysis** (3-4 pages)
   - Query results and interpretation
   - Visualization insights
   - Statistical findings

4. **Conclusions and Recommendations** (1-2 pages)
   - Security implications
   - Mitigation strategies
   - Future analysis suggestions

5. **Appendices**
   - Query code
   - Full visualization outputs
   - Technical specifications

## Quality Assurance Checklist

### Technical Requirements
- [ ] All Hive queries execute successfully
- [ ] Results contain meaningful data
- [ ] Visualizations display correctly
- [ ] Interactive dashboard functions properly
- [ ] Code is well-documented

### Analytical Requirements
- [ ] Queries use advanced SQL features
- [ ] Analysis demonstrates statistical understanding
- [ ] Insights are domain-relevant
- [ ] Conclusions are data-driven
- [ ] Recommendations are actionable

### Presentation Requirements
- [ ] Report is professionally formatted
- [ ] Visualizations are clear and informative
- [ ] Screenshots demonstrate working system
- [ ] Writing is clear and concise
- [ ] Technical content is accurate

## Common Pitfalls to Avoid

1. **Query Performance**: Ensure queries complete in reasonable time
2. **Data Validation**: Verify query results make sense
3. **Visualization Clarity**: Ensure charts are readable and informative
4. **Analysis Depth**: Go beyond simple counts to meaningful insights
5. **Report Quality**: Maintain professional standards throughout

## Submission Guidelines

### Required Deliverables

1. **Technical Implementation**
   - Working Hadoop cluster (demonstrated via screenshots)
   - All 4+ complex Hive queries with results
   - Python visualization code and outputs

2. **Analysis Report**
   - PDF document (8-12 pages)
   - Professional formatting
   - Clear insights and recommendations

3. **Supporting Materials**
   - Query code files (.sql or .hql)
   - Python notebook (.ipynb)
   - Visualization outputs (PNG/HTML files)

### File Organization

```
submission/
├── report.pdf
├── queries/
│   ├── query1_attack_analysis.sql
│   ├── query2_service_vulnerability.sql
│   ├── query3_traffic_patterns.sql
│   └── query4_protocol_security.sql
├── visualizations/
│   ├── analysis_notebook.ipynb
│   ├── attack_distribution.png
│   ├── service_vulnerability.png
│   ├── protocol_heatmap.png
│   ├── temporal_patterns.png
│   └── interactive_dashboard.html
└── screenshots/
    ├── hadoop_namenode.png
    ├── hive_tables.png
    └── visualizations.png
```

## Assessment Rubric

| Criterion | Excellent (A) | Good (B) | Satisfactory (C) | Needs Improvement (D/F) |
|-----------|---------------|----------|------------------|-------------------------|
| Setup & Configuration | Flawless setup, all services working | Minor issues, mostly working | Some components not working | Major setup failures |
| Query Complexity | Advanced SQL features used effectively | Good use of SQL features | Basic SQL functionality | Simple queries only |
| Analysis Quality | Deep insights, statistical rigor | Good analysis with some insights | Basic analysis | Superficial analysis |
| Visualizations | Professional, informative charts | Good visualizations | Adequate charts | Poor or missing visualizations |
| Report Quality | Excellent presentation and insights | Well-written with good insights | Adequate reporting | Poor presentation |

## Additional Resources

### Hive Documentation
- [Apache Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
- [Hive Window Functions](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+WindowingAndAnalytics)

### Visualization Resources
- [Matplotlib Documentation](https://matplotlib.org/stable/)
- [Seaborn Tutorial](https://seaborn.pydata.org/tutorial.html)
- [Plotly Documentation](https://plotly.com/python/)

### Cybersecurity Context
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Network Traffic Analysis Best Practices](https://www.sans.org/white-papers/network-traffic-analysis/)

## Support and Help

If you encounter issues:

1. **Technical Problems**: Check `docs/troubleshooting.md`
2. **Query Issues**: Review Hive documentation and examples
3. **Visualization Problems**: Check Python package documentation
4. **Analysis Questions**: Consult cybersecurity resources and course materials

Remember: This assignment is designed to demonstrate your ability to work with big data tools for real-world cybersecurity analysis. Focus on producing meaningful insights that could inform actual security decisions.
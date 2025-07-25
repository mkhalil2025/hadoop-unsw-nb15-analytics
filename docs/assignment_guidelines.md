# Assignment Guidelines for UEL-CN-7031 Students
## Big Data Analytics with UNSW-NB15 Dataset

This document provides comprehensive guidelines for completing your Big Data Analytics assignment using the Hadoop-based UNSW-NB15 analytics environment.

## 📚 Assignment Overview

### Course Information
- **Course**: UEL-CN-7031 Big Data Analytics
- **Dataset**: UNSW-NB15 Cybersecurity Dataset
- **Platform**: Hadoop Ecosystem (HDFS, Hive, YARN, Jupyter)
- **Duration**: 4-6 weeks recommended
- **Weight**: Varies by institution (typically 40-60% of course grade)

### Learning Objectives
By completing this assignment, you will demonstrate:
1. **Technical Proficiency**: Hands-on experience with big data tools
2. **Analytical Skills**: Complex data analysis and pattern recognition
3. **Problem Solving**: Real-world cybersecurity analytics
4. **Communication**: Technical reporting and visualization
5. **Research Skills**: Independent exploration and hypothesis testing

---

## 🎯 Assignment Structure and Requirements

### Part 1: Environment Setup and Data Loading (15 points)

#### Objectives
- Successfully deploy the Hadoop analytics environment
- Load and validate the UNSW-NB15 dataset
- Demonstrate understanding of big data architecture

#### Deliverables
1. **Setup Documentation** (5 points)
   - Screenshot of successful environment deployment
   - Documentation of any setup challenges and resolutions
   - System specifications and resource allocation decisions

2. **Data Loading Report** (5 points)
   - Evidence of successful data loading into HDFS and Hive
   - Data quality assessment report
   - Schema validation and row count verification

3. **Architecture Overview** (5 points)
   - Diagram of the deployed Hadoop ecosystem
   - Explanation of each component's role
   - Discussion of scalability considerations

#### Sample Evidence to Include
```bash
# Screenshot outputs from these commands:
docker-compose ps
curl http://localhost:9870
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SELECT COUNT(*) FROM unsw_nb15.network_flows;"
```

### Part 2: Exploratory Data Analysis (25 points)

#### Objectives
- Perform comprehensive exploratory data analysis
- Identify key patterns and characteristics in the dataset
- Create meaningful visualizations

#### Deliverables
1. **Jupyter Notebook Analysis** (15 points)
   - Complete execution of provided `data_exploration.ipynb`
   - Additional custom analysis cells (minimum 5)
   - Clear markdown documentation explaining findings

2. **Statistical Summary** (5 points)
   - Dataset characteristics summary
   - Attack category distribution analysis
   - Protocol and service usage patterns
   - Temporal pattern identification

3. **Visualization Portfolio** (5 points)
   - Minimum 8 different chart types
   - Interactive visualizations using Plotly
   - Publication-quality static charts
   - Clear interpretation of each visualization

#### Required Analysis Areas
- **Attack Distribution**: Categories, frequency, severity
- **Network Patterns**: Protocols, services, ports
- **Temporal Analysis**: Time-of-day, seasonal patterns
- **Data Quality**: Missing values, outliers, inconsistencies
- **Feature Relationships**: Correlations, dependencies

### Part 3: Advanced HiveQL Analytics (30 points)

#### Objectives
- Execute and interpret complex analytical queries
- Develop original HiveQL queries
- Demonstrate advanced SQL and big data concepts

#### Deliverables
1. **Provided Query Analysis** (15 points)
   - Execute all 4 provided analytical queries
   - Document query execution times and performance
   - Interpret results with business context
   - Explain the big data concepts demonstrated

2. **Custom Query Development** (15 points)
   - Develop minimum 3 original complex queries
   - Demonstrate different analytical techniques
   - Include performance optimization considerations
   - Provide business justification for each query

#### Query Requirements

**Custom Query 1: Security Intelligence** (5 points)
- Focus: Threat detection and attack correlation
- Requirements: Use window functions, subqueries
- Example topics: Attack progression, IP reputation, service targeting

**Custom Query 2: Performance Analytics** (5 points)
- Focus: Network performance and capacity analysis
- Requirements: Statistical functions, aggregations
- Example topics: Bandwidth utilization, flow duration analysis, QoS metrics

**Custom Query 3: Predictive Insights** (5 points)
- Focus: Trend analysis and forecasting
- Requirements: Time series analysis, ranking functions
- Example topics: Attack trend prediction, capacity planning, anomaly forecasting

#### Query Documentation Template
```sql
-- Query Title: [Descriptive Name]
-- Business Objective: [Why this analysis is important]
-- Big Data Concepts: [Window functions, aggregations, etc.]
-- Expected Insights: [What patterns you expect to find]

-- Your HiveQL query here
SELECT ...
```

### Part 4: Advanced Analytics and Machine Learning (20 points)

#### Objectives
- Apply machine learning techniques to cybersecurity data
- Implement anomaly detection algorithms
- Evaluate model performance

#### Deliverables
1. **Anomaly Detection Implementation** (10 points)
   - Extend the provided statistical anomaly detection
   - Implement at least 2 different detection methods
   - Compare effectiveness using confusion matrices
   - Discuss false positive/negative trade-offs

2. **Classification Model** (10 points)
   - Build a model to classify attack types
   - Use scikit-learn or Spark MLlib
   - Report accuracy, precision, recall, F1-score
   - Discuss feature importance and selection

#### Required Analysis
- **Statistical Anomaly Detection**: Z-scores, percentiles, outlier detection
- **Machine Learning Models**: Decision trees, random forest, or neural networks
- **Feature Engineering**: Create new features from existing data
- **Model Evaluation**: Cross-validation, performance metrics, interpretation

#### Code Template
```python
# Machine Learning Analysis Template
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix

# 1. Data preparation
# 2. Feature engineering
# 3. Model training
# 4. Evaluation
# 5. Feature importance analysis
```

### Part 5: Research Report and Recommendations (10 points)

#### Objectives
- Synthesize findings into actionable insights
- Demonstrate understanding of cybersecurity implications
- Provide recommendations for security improvements

#### Deliverables
1. **Executive Summary** (3 points)
   - Key findings summary (1-2 pages)
   - Business impact assessment
   - High-level recommendations

2. **Technical Analysis Report** (4 points)
   - Detailed methodology explanation
   - Statistical findings and interpretations
   - Technical challenges and solutions

3. **Security Recommendations** (3 points)
   - Specific security improvements based on analysis
   - Implementation prioritization
   - Cost-benefit considerations

---

## 📋 Detailed Rubric

### Technical Proficiency (40% of total grade)

| Criteria | Excellent (9-10) | Good (7-8) | Satisfactory (5-6) | Needs Improvement (0-4) |
|----------|------------------|------------|-------------------|-------------------------|
| **Environment Setup** | Flawless deployment, custom optimizations | Successful setup with minor issues | Basic setup completed | Failed setup or major issues |
| **HiveQL Queries** | Advanced queries with optimization | Correct complex queries | Basic queries work | Syntax errors or failures |
| **Python Analytics** | Sophisticated analysis, custom functions | Good use of provided tools | Basic analysis completed | Limited or incorrect analysis |

### Analytical Thinking (35% of total grade)

| Criteria | Excellent (9-10) | Good (7-8) | Satisfactory (5-6) | Needs Improvement (0-4) |
|----------|------------------|------------|-------------------|-------------------------|
| **Data Insights** | Novel discoveries, deep insights | Good pattern recognition | Basic patterns identified | Superficial analysis |
| **Problem Solving** | Creative solutions, multiple approaches | Effective problem solving | Standard approaches used | Limited problem solving |
| **Critical Analysis** | Thoughtful interpretation, implications discussed | Good analysis with context | Basic interpretation | Weak or missing analysis |

### Communication (25% of total grade)

| Criteria | Excellent (9-10) | Good (7-8) | Satisfactory (5-6) | Needs Improvement (0-4) |
|----------|------------------|------------|-------------------|-------------------------|
| **Documentation** | Clear, comprehensive, professional | Well-documented, minor gaps | Adequate documentation | Poor or missing documentation |
| **Visualizations** | Publication-quality, insightful | Good charts with clear labels | Basic visualizations | Poor or confusing visuals |
| **Report Writing** | Excellent structure, clear arguments | Good organization, readable | Adequate structure | Poor organization or clarity |

---

## 💡 Success Strategies

### Time Management
- **Week 1**: Environment setup and basic data exploration
- **Week 2**: Complete exploratory data analysis and visualizations
- **Week 3**: Develop and execute custom HiveQL queries
- **Week 4**: Implement machine learning models and anomaly detection
- **Week 5**: Write report and prepare final submission

### Technical Tips

#### 1. Start Simple, Build Complexity
```sql
-- Start with basic queries
SELECT COUNT(*) FROM network_flows WHERE label = true;

-- Gradually add complexity
SELECT attack_cat, proto, COUNT(*) as attacks
FROM network_flows 
WHERE label = true 
GROUP BY attack_cat, proto
ORDER BY attacks DESC;

-- Finally, use advanced functions
WITH ranked_attacks AS (
    SELECT attack_cat, proto, COUNT(*) as attacks,
           ROW_NUMBER() OVER (PARTITION BY proto ORDER BY COUNT(*) DESC) as rank
    FROM network_flows 
    WHERE label = true 
    GROUP BY attack_cat, proto
)
SELECT * FROM ranked_attacks WHERE rank <= 3;
```

#### 2. Document Everything
```python
# Always include explanatory comments
# What does this code do?
# Why is this analysis important?
# What insights do you expect?

# Example: Anomaly detection using z-scores
z_scores = np.abs(stats.zscore(df[numerical_features]))
# Z-scores > 3 indicate potential outliers (99.7% confidence)
```

#### 3. Performance Optimization
```sql
-- Use appropriate filters early
WHERE label = true AND stime >= '2023-01-01'

-- Partition your queries effectively
PARTITION BY (year, month)

-- Use LIMIT for testing
LIMIT 1000  -- Remove for final analysis
```

### Research and Analysis Tips

#### 1. Cybersecurity Context
- Research real-world attack patterns
- Understand network protocols and services
- Consider business impact of security incidents
- Reference current threat intelligence

#### 2. Statistical Rigor
- Always validate your assumptions
- Use appropriate statistical tests
- Consider confidence intervals
- Discuss limitations of your analysis

#### 3. Business Relevance
- Connect technical findings to business outcomes
- Prioritize recommendations by impact and feasibility
- Consider implementation costs and complexity
- Think about scalability and maintenance

---

## 📊 Sample Assignment Outputs

### Example Executive Summary
```
Executive Summary: UNSW-NB15 Security Analytics

Key Findings:
1. TCP traffic represents 78% of all flows, with HTTP being the most targeted service
2. DoS attacks peak during business hours (9 AM - 5 PM), suggesting targeted campaigns
3. Statistical anomaly detection achieved 87% accuracy with 12% false positive rate
4. 15 IP addresses generated 45% of all attack traffic, indicating concentrated threats

Recommendations:
1. Implement enhanced monitoring for TCP/HTTP traffic
2. Deploy additional security controls during peak hours
3. Investigate and potentially block the 15 high-risk IP addresses
4. Tune anomaly detection thresholds to reduce false positives

Business Impact: Implementation of these recommendations could reduce security incidents by an estimated 60% while improving detection accuracy.
```

### Example Technical Finding
```python
# Sample analysis code with professional documentation

def analyze_attack_patterns(df, time_window='hour'):
    """
    Analyze temporal attack patterns to identify peak activity periods.
    
    Parameters:
    df (DataFrame): Network flow data with attack labels
    time_window (str): Aggregation window ('hour', 'day', 'week')
    
    Returns:
    DataFrame: Aggregated attack statistics by time period
    """
    
    # Group attacks by time window
    if time_window == 'hour':
        df['time_group'] = df['stime'].dt.hour
    
    attack_patterns = df[df['label'] == 1].groupby('time_group').agg({
        'attack_cat': 'count',
        'sbytes': 'sum',
        'dbytes': 'sum'
    }).reset_index()
    
    # Calculate attack intensity score
    attack_patterns['intensity_score'] = (
        attack_patterns['attack_cat'] * 
        np.log(attack_patterns['sbytes'] + attack_patterns['dbytes'] + 1)
    )
    
    return attack_patterns

# Usage and interpretation
hourly_patterns = analyze_attack_patterns(df, 'hour')
peak_hour = hourly_patterns.loc[hourly_patterns['intensity_score'].idxmax(), 'time_group']
print(f"Peak attack activity occurs at {peak_hour}:00 hours")
```

---

## 🚀 Going Above and Beyond

### Extension Ideas for Exceptional Grades

#### 1. Real-time Analytics Simulation
- Implement streaming analytics using Kafka and Spark Streaming
- Create real-time dashboards
- Demonstrate scalability concepts

#### 2. Advanced Machine Learning
- Implement ensemble methods
- Use deep learning for anomaly detection
- Experiment with unsupervised learning techniques

#### 3. Integration with Security Tools
- Connect with threat intelligence feeds
- Implement SIEM-like functionality
- Create automated alert generation

#### 4. Performance Benchmarking
- Compare query performance across different configurations
- Analyze resource utilization patterns
- Optimize for specific hardware constraints

#### 5. Industry Integration
- Research how real organizations use similar analytics
- Interview cybersecurity professionals
- Propose innovative solutions to current industry challenges

---

## 📝 Submission Requirements

### File Structure
```
[StudentID]_BigDataAnalytics_Assignment/
├── README.md                           # Overview and instructions
├── docs/
│   ├── report.pdf                     # Main assignment report
│   └── technical_appendix.pdf         # Detailed technical documentation
├── notebooks/
│   ├── data_exploration.ipynb         # Completed exploration notebook
│   ├── custom_analysis.ipynb          # Your additional analysis
│   └── machine_learning.ipynb         # ML implementation
├── queries/
│   ├── custom_query_1.sql            # Your original queries
│   ├── custom_query_2.sql
│   └── custom_query_3.sql
├── visualizations/
│   ├── attack_distribution.png        # Generated visualizations
│   ├── temporal_patterns.png
│   └── interactive_dashboard.html
├── data/
│   └── analysis_results.csv           # Exported results
└── scripts/
    └── custom_analysis.py              # Any custom Python scripts
```

### Report Requirements
- **Length**: 15-25 pages (excluding appendices)
- **Format**: PDF with professional formatting
- **Sections**: Executive Summary, Introduction, Methodology, Analysis, Results, Conclusions, References
- **Citations**: Minimum 10 academic or industry references
- **Figures**: All charts and tables must be numbered and captioned

### Code Requirements
- **Documentation**: All code must be well-commented
- **Reproducibility**: Include clear instructions for running your analysis
- **Version Control**: Use Git for code management (optional but recommended)
- **Testing**: Include basic validation and error checking

---

## ✅ Final Checklist

Before submission, ensure you have:

### Technical Requirements
- [ ] Environment successfully deployed and documented
- [ ] All provided queries executed and interpreted
- [ ] Minimum 3 custom queries developed and documented
- [ ] Machine learning model implemented and evaluated
- [ ] Comprehensive visualizations created
- [ ] Code is well-documented and reproducible

### Analysis Requirements
- [ ] Exploratory data analysis completed
- [ ] Statistical significance testing performed
- [ ] Business context provided for all findings
- [ ] Limitations and assumptions documented
- [ ] Recommendations prioritized and justified

### Submission Requirements
- [ ] All files organized in required structure
- [ ] Report meets length and formatting requirements
- [ ] Citations properly formatted
- [ ] Code tested and functional
- [ ] README file explains how to reproduce results

### Quality Assurance
- [ ] Spell-check and grammar review completed
- [ ] All figures properly labeled and referenced
- [ ] Technical accuracy verified
- [ ] Professional presentation throughout
- [ ] Backup copies created

---

## 🎓 Learning Outcomes Assessment

Upon successful completion, you will have demonstrated:

### Technical Skills
- **Big Data Platforms**: Hands-on experience with Hadoop ecosystem
- **SQL Proficiency**: Advanced HiveQL query development
- **Programming**: Python for data science and analytics
- **Visualization**: Professional chart creation and interpretation
- **Machine Learning**: Practical ML model development and evaluation

### Analytical Skills
- **Pattern Recognition**: Identify trends and anomalies in large datasets
- **Statistical Analysis**: Apply appropriate statistical methods
- **Critical Thinking**: Interpret results in business context
- **Problem Solving**: Address real-world cybersecurity challenges

### Professional Skills
- **Technical Communication**: Write clear, professional reports
- **Project Management**: Plan and execute complex analytical projects
- **Research**: Find and integrate relevant external sources
- **Presentation**: Create compelling visualizations and arguments

---

**Good luck with your assignment!** Remember that this is not just an academic exercise—the skills you develop here are directly applicable to real-world big data and cybersecurity roles. Take pride in your work and don't hesitate to ask questions or seek clarification when needed.

The cybersecurity industry needs skilled professionals who can analyze large datasets to identify threats and protect organizations. Your work on this assignment is a stepping stone toward that important career path.
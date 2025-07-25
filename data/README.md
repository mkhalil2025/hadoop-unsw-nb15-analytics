# UNSW-NB15 Dataset Information

## About the UNSW-NB15 Dataset

The UNSW-NB15 dataset is a comprehensive cybersecurity dataset created by the Australian Centre for Cyber Security (ACCS) for network intrusion detection research. This dataset contains realistic modern normal activities and synthetic contemporary attack behaviors.

## Dataset Characteristics

- **Total Records**: ~2.5 million network flow records
- **File Size**: Approximately 600MB (CSV format)
- **Features**: 49 features including network flow statistics and attack indicators
- **Attack Categories**: 9 different attack types plus normal traffic
- **Time Period**: Captured over multiple days with realistic traffic patterns

## Attack Categories

1. **Normal** - Legitimate network traffic
2. **Fuzzers** - Attempts to discover security loopholes by providing random data
3. **Analysis** - Attacks that analyze network traffic for vulnerabilities
4. **Backdoors** - Techniques to bypass security mechanisms
5. **DoS** - Denial of Service attacks
6. **Exploits** - Attacks that take advantage of system vulnerabilities
7. **Generic** - Attacks against hash functions and block ciphers
8. **Reconnaissance** - Surveillance and probing attacks
9. **Shellcode** - Code injection attacks
10. **Worms** - Self-replicating malware

## Dataset Files

### Required Files (Download from official source)

1. **UNSW_NB15_training-set.csv** - Training dataset
2. **UNSW_NB15_testing-set.csv** - Testing dataset  
3. **NUSW-NB15_features.csv** - Feature descriptions

### Official Download Source

The official UNSW-NB15 dataset can be downloaded from:
- **Primary Source**: https://research.unsw.edu.au/projects/unsw-nb15-dataset
- **Alternative**: https://www.kaggle.com/dhoogla/unswnb15

## Dataset Schema

The dataset contains 49 features organized into several categories:

### Basic Flow Features
- `srcip`, `dstip` - Source and destination IP addresses
- `sport`, `dsport` - Source and destination port numbers
- `proto` - Protocol type (tcp, udp, icmp, etc.)
- `state` - Protocol state (FIN, CON, INT, etc.)
- `dur` - Record duration

### Content Features
- `sbytes`, `dbytes` - Source and destination transaction bytes
- `sttl`, `dttl` - Source and destination time to live values
- `sloss`, `dloss` - Packet loss counters
- `service` - Network service type (http, ssh, ftp, etc.)

### Traffic Features
- `sload`, `dload` - Source and destination bits per second
- `spkts`, `dpkts` - Packet counts
- `swin`, `dwin` - TCP window sizes
- `stcpb`, `dtcpb` - TCP sequence numbers

### Time-based Features
- `stime`, `ltime` - Start and last time timestamps
- `sintpkt`, `dintpkt` - Inter-packet arrival times
- `sjit`, `djit` - Jitter measurements

### Generated Features
- Various connection counts (`ct_*` features)
- Flow analysis features
- Statistical aggregations

### Labels
- `attack_cat` - Attack category name
- `label` - Binary classification (0=normal, 1=attack)

## Data Preparation Steps

1. **Download the Dataset**
   ```bash
   # Create data directory
   mkdir -p data/
   
   # Download files to data/ directory
   # Note: Replace URLs with actual download links
   wget -O data/UNSW_NB15_training-set.csv [TRAINING_SET_URL]
   wget -O data/UNSW_NB15_testing-set.csv [TESTING_SET_URL]
   wget -O data/NUSW-NB15_features.csv [FEATURES_URL]
   ```

2. **Verify Data Integrity**
   ```bash
   # Check file sizes
   ls -lh data/
   
   # Verify CSV headers
   head -1 data/UNSW_NB15_training-set.csv
   head -1 data/UNSW_NB15_testing-set.csv
   ```

3. **Load into Hadoop Environment**
   ```bash
   # Run the data loader script
   ./setup/data_loader.sh
   ```

## Sample Data Preview

### Training Set Sample
```csv
srcip,sport,dstip,dsport,proto,state,dur,sbytes,dbytes,...,attack_cat,label
192.168.1.100,49153,192.168.1.1,53,udp,INT,0.003,56,84,...,Normal,0
10.0.0.1,80,192.168.1.50,49154,tcp,FIN,5.0,1024,2048,...,Normal,0
```

### Features Description Sample
```csv
Name,Type,Description
srcip,nominal,Source IP address
sport,integer,Source port number
proto,nominal,Transaction protocol
```

## Data Quality Considerations

### Missing Values
- Some features may contain null values or placeholder characters ('-')
- Handle missing values appropriately during analysis

### Data Types
- IP addresses stored as strings
- Numeric features may need type conversion
- Timestamps stored as Unix epoch values

### Outliers
- Network traffic data naturally contains outliers
- Consider appropriate outlier detection and handling strategies

## Usage in Hive Analysis

The dataset is loaded into Hive tables with optimized schema:

```sql
-- Main analysis table
SELECT * FROM cybersecurity_analytics.unsw_nb15_combined LIMIT 10;

-- Attack distribution
SELECT attack_cat, COUNT(*) FROM unsw_nb15_combined GROUP BY attack_cat;

-- Protocol analysis  
SELECT proto, AVG(dur), COUNT(*) FROM unsw_nb15_combined GROUP BY proto;
```

## Citation

If you use this dataset in your research, please cite:

```
Moustafa, N., & Slay, J. (2015). UNSW-NB15: a comprehensive data set for 
network intrusion detection systems (UNSW-NB15 network data set). 
2015 military communications and information systems conference (MilCIS) (pp. 1-6). IEEE.
```

## Ethical Considerations

- This dataset contains synthesized attack data for research purposes
- Use only for legitimate cybersecurity research and education
- Do not use for malicious purposes or unauthorized network testing
- Follow institutional guidelines for cybersecurity research

## Support and Issues

For dataset-related questions:
- Contact: Australian Centre for Cyber Security (ACCS)
- Email: cyber.security@unsw.edu.au
- Website: https://research.unsw.edu.au/projects/unsw-nb15-dataset

For implementation issues with this analytics environment:
- Check the troubleshooting guide: `docs/troubleshooting.md`
- Review setup instructions: `docs/setup_guide.md`
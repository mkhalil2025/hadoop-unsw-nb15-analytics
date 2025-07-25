# UNSW-NB15 Dataset Directory

This directory contains the UNSW-NB15 cybersecurity dataset files for the Hadoop analytics environment.

## 📊 Dataset Information

### About UNSW-NB15
- **Source**: University of New South Wales (UNSW) Canberra
- **Purpose**: Network intrusion detection system evaluation
- **Type**: Labeled network flow records for cybersecurity research
- **Size**: ~2.5 million network flow records
- **Features**: 49 features including flow statistics, service information, and attack labels
- **License**: Available for academic and research purposes

### Dataset Characteristics
- **Records**: Approximately 2,540,044 network flow records
- **Features**: 49 features covering network flow properties
- **Labels**: Binary (normal/attack) and multi-class (9 attack categories)
- **Time Period**: Network traffic captured over multiple days
- **File Format**: CSV (Comma Separated Values)

## 📁 File Structure

```
data/
├── README.md                    # This file
├── UNSW_NB15_sample.csv        # Generated sample data (created automatically)
├── UNSW_NB15_training-set.csv  # Original training dataset (download required)
├── UNSW_NB15_testing-set.csv   # Original testing dataset (download required)
├── UNSW-NB15_features.csv      # Feature descriptions
└── UNSW-NB15_GT.csv           # Ground truth labels (if available)
```

## 🔄 Data Loading Options

### Option 1: Use Sample Data (Default)
The environment automatically generates realistic sample data if the original dataset is not available:
- **File**: `UNSW_NB15_sample.csv`
- **Records**: 1,000+ sample records
- **Purpose**: Testing and development
- **Content**: Realistic synthetic network flow data

### Option 2: Download Original Dataset

#### Step 1: Download from Official Source
1. Visit: https://research.unsw.edu.au/projects/unsw-nb15-dataset
2. Download the following files:
   - `UNSW_NB15_training-set.csv` (~1.6M records)
   - `UNSW_NB15_testing-set.csv` (~175K records)
   - `UNSW-NB15_features.csv` (feature descriptions)

#### Step 2: Alternative Download Sources
If the official source is unavailable, try these academic mirrors:
- **Kaggle**: https://www.kaggle.com/datasets/dhoogla/unswnb15
- **IEEE DataPort**: https://ieee-dataport.org/open-access/unsw-nb15-network-intrusion-dataset
- **Academic Archives**: Search for "UNSW-NB15" on academic data repositories

#### Step 3: Place Files in Data Directory
```bash
# Copy downloaded files to the data directory
cp /path/to/downloads/UNSW_NB15_training-set.csv ./data/
cp /path/to/downloads/UNSW_NB15_testing-set.csv ./data/
cp /path/to/downloads/UNSW-NB15_features.csv ./data/
```

#### Step 4: Reload Data
```bash
# Reload data into Hadoop environment
./scripts/load_data.sh
```

## 📋 Dataset Schema

### Network Flow Features (49 total)

#### Basic Flow Information
| Feature | Type | Description |
|---------|------|-------------|
| `srcip` | String | Source IP address |
| `sport` | Integer | Source port number |
| `dstip` | String | Destination IP address |
| `dsport` | Integer | Destination port number |
| `proto` | String | Protocol (tcp, udp, icmp, etc.) |

#### Flow Statistics
| Feature | Type | Description |
|---------|------|-------------|
| `dur` | Float | Total duration of the flow |
| `sbytes` | Integer | Source to destination bytes |
| `dbytes` | Integer | Destination to source bytes |
| `sttl` | Integer | Source to destination time to live |
| `dttl` | Integer | Destination to source time to live |
| `sloss` | Integer | Source packets retransmitted/dropped |
| `dloss` | Integer | Destination packets retransmitted/dropped |
| `spkts` | Integer | Source to destination packet count |
| `dpkts` | Integer | Destination to source packet count |

#### Service and State Features
| Feature | Type | Description |
|---------|------|-------------|
| `service` | String | Service type (http, ftp, ssh, etc.) |
| `sload` | Float | Source bits per second |
| `dload` | Float | Destination bits per second |
| `state` | String | Connection state |

#### Advanced Features
| Feature | Type | Description |
|---------|------|-------------|
| `swin` | Integer | Source TCP window advertisement |
| `dwin` | Integer | Destination TCP window advertisement |
| `stcpb` | Integer | Source TCP base sequence number |
| `dtcpb` | Integer | Destination TCP base sequence number |
| `smeansz` | Float | Mean flow packet size (source) |
| `dmeansz` | Float | Mean flow packet size (destination) |
| `trans_depth` | Integer | Connection depth |
| `res_bdy_len` | Integer | Response body length |

#### Timing Features
| Feature | Type | Description |
|---------|------|-------------|
| `sjit` | Float | Source jitter (milliseconds) |
| `djit` | Float | Destination jitter (milliseconds) |
| `stime` | Timestamp | Record start time |
| `ltime` | Timestamp | Record last time |
| `sintpkt` | Float | Source inter-packet arrival time |
| `dintpkt` | Float | Destination inter-packet arrival time |

#### TCP-specific Features
| Feature | Type | Description |
|---------|------|-------------|
| `tcprtt` | Float | TCP connection setup round-trip time |
| `synack` | Float | TCP connection setup time |
| `ackdat` | Float | TCP connection setup time |

#### Behavioral Features
| Feature | Type | Description |
|---------|------|-------------|
| `is_sm_ips_ports` | Boolean | Same source/destination IPs and ports |
| `ct_state_ttl` | Integer | Count of connections with specific TTL |
| `ct_flw_http_mthd` | Integer | Count of HTTP method flows |
| `is_ftp_login` | Boolean | FTP login attempt indicator |
| `ct_ftp_cmd` | Integer | Count of FTP command flows |

#### Connection Context Features
| Feature | Type | Description |
|---------|------|-------------|
| `ct_srv_src` | Integer | Count of same service and source |
| `ct_srv_dst` | Integer | Count of same service and destination |
| `ct_dst_ltm` | Integer | Count of same destination in time window |
| `ct_src_ltm` | Integer | Count of same source in time window |
| `ct_src_dport_ltm` | Integer | Count of same source and dest port |
| `ct_dst_sport_ltm` | Integer | Count of same dest and source port |
| `ct_dst_src_ltm` | Integer | Count of same source and destination |

#### Labels
| Feature | Type | Description |
|---------|------|-------------|
| `label` | Boolean | Binary label (0=Normal, 1=Attack) |
| `attack_cat` | String | Attack category name |

### Attack Categories

| Category | Description | Example Attacks |
|----------|-------------|-----------------|
| **Normal** | Legitimate network traffic | Regular web browsing, email |
| **Analysis** | Probing and scanning attacks | Port scans, vulnerability scans |
| **Backdoor** | Unauthorized remote access | Remote shells, trojans |
| **DoS** | Denial of Service attacks | SYN flood, UDP flood |
| **Exploits** | Exploitation of vulnerabilities | Buffer overflows, code injection |
| **Fuzzers** | Automated testing tools | Random input generation |
| **Generic** | Generic attack patterns | Broad category attacks |
| **Reconnaissance** | Information gathering | Network mapping, fingerprinting |
| **Shellcode** | Code injection attacks | Executable payload delivery |
| **Worms** | Self-replicating malware | Network propagation attacks |

## 🔧 Data Validation

### Quality Checks
After loading data, verify its quality:

```sql
-- Check total record count
SELECT COUNT(*) as total_records FROM unsw_nb15.network_flows;

-- Check attack distribution
SELECT attack_cat, COUNT(*) as count, 
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM unsw_nb15.network_flows 
GROUP BY attack_cat 
ORDER BY count DESC;

-- Check for missing values
SELECT 
    SUM(CASE WHEN srcip IS NULL THEN 1 ELSE 0 END) as null_srcip,
    SUM(CASE WHEN dstip IS NULL THEN 1 ELSE 0 END) as null_dstip,
    SUM(CASE WHEN proto IS NULL THEN 1 ELSE 0 END) as null_proto,
    SUM(CASE WHEN attack_cat IS NULL THEN 1 ELSE 0 END) as null_attack_cat
FROM unsw_nb15.network_flows;

-- Check data ranges
SELECT 
    MIN(sbytes) as min_sbytes, MAX(sbytes) as max_sbytes,
    MIN(dbytes) as min_dbytes, MAX(dbytes) as max_dbytes,
    MIN(dur) as min_duration, MAX(dur) as max_duration
FROM unsw_nb15.network_flows;
```

### Expected Statistics
For the complete UNSW-NB15 dataset:
- **Total Records**: ~2.54 million
- **Normal Traffic**: ~87% (2.22 million records)
- **Attack Traffic**: ~13% (321,283 records)
- **Most Common Protocol**: TCP (~87%)
- **Most Common Service**: HTTP/HTTPS (~45%)

## 📈 Usage Examples

### Loading Data Programmatically

#### Python (via Jupyter)
```python
# Connect to Hive and load data
from pyhive import hive
import pandas as pd

conn = hive.Connection(host='hiveserver2', port=10000, database='unsw_nb15')

# Load sample data
query = """
SELECT srcip, dstip, proto, service, attack_cat, sbytes, dbytes, label
FROM network_flows 
LIMIT 10000
"""

df = pd.read_sql(query, conn)
print(f"Loaded {len(df)} records")
print(df.head())
```

#### HiveQL (Direct)
```sql
-- Access data directly in Hive
USE unsw_nb15;

-- Basic exploration
SELECT proto, COUNT(*) as flow_count
FROM network_flows 
GROUP BY proto 
ORDER BY flow_count DESC;

-- Attack analysis
SELECT attack_cat, AVG(sbytes + dbytes) as avg_bytes
FROM network_flows 
WHERE label = true 
GROUP BY attack_cat;
```

## 🔒 Data Security and Privacy

### Anonymization
The UNSW-NB15 dataset has been anonymized for research use:
- IP addresses are sanitized/simulated
- No personally identifiable information
- Timestamps are relative, not absolute

### Usage Guidelines
1. **Academic Use**: Freely available for academic research
2. **Commercial Use**: Contact UNSW for licensing terms
3. **Citation Required**: Always cite the original research
4. **Data Integrity**: Do not modify the original dataset files

### Recommended Citation
```bibtex
@article{moustafa2015unsw,
  title={UNSW-NB15: a comprehensive data set for network intrusion detection systems (UNSW-NB15 network data set)},
  author={Moustafa, Nour and Slay, Jill},
  journal={2015 military communications and information systems conference (MilCIS)},
  pages={1--6},
  year={2015},
  organization={IEEE}
}
```

## 🚀 Next Steps

After placing your data files in this directory:

1. **Load Data**: Run `./scripts/load_data.sh`
2. **Validate**: Check data quality using the provided queries
3. **Explore**: Open Jupyter Lab and start with `data_exploration.ipynb`
4. **Analyze**: Execute the advanced HiveQL queries
5. **Visualize**: Generate charts using the Python visualization tools

## 📞 Support

### Data Issues
- **Missing Files**: Use the sample data generator
- **Corrupted Downloads**: Re-download from alternative sources
- **Loading Errors**: Check `./output/logs/data_loading.log`

### Performance Issues
- **Large Dataset**: Consider using a subset for initial analysis
- **Memory Limits**: Adjust YARN memory settings in `.env`
- **Slow Queries**: Use LIMIT clauses during development

### Additional Resources
- **Original Paper**: https://ieeexplore.ieee.org/document/7348942
- **Dataset Homepage**: https://research.unsw.edu.au/projects/unsw-nb15-dataset
- **Academic Citations**: Search for "UNSW-NB15" on Google Scholar

---

**Data is the foundation of great analytics!** 📊 Ensure your data is properly loaded and validated before beginning analysis.
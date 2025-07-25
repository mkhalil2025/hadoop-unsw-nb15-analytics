# Troubleshooting Guide

This guide helps resolve common issues encountered when setting up and using the Hadoop UNSW-NB15 Analytics environment.

## Docker and Container Issues

### Container Startup Problems

#### Issue: Containers fail to start or exit immediately

**Symptoms:**
- `docker-compose ps` shows containers as "Exited"
- Services are not accessible via web interfaces
- Error messages in logs about port conflicts

**Solutions:**

1. **Check port conflicts:**
   ```bash
   # Find processes using required ports
   sudo netstat -tulpn | grep :9870
   sudo netstat -tulpn | grep :8088
   sudo netstat -tulpn | grep :10000
   
   # Kill conflicting processes
   sudo kill -9 [PID]
   ```

2. **Restart Docker service:**
   ```bash
   sudo systemctl restart docker
   docker-compose down -v
   docker-compose up -d
   ```

3. **Clear Docker cache:**
   ```bash
   docker system prune -a
   docker volume prune
   ```

#### Issue: Out of memory errors

**Symptoms:**
- Containers exit with code 137
- "OutOfMemoryError" in logs
- System becomes unresponsive

**Solutions:**

1. **Reduce memory allocation in `hadoop.env`:**
   ```bash
   # For 4GB systems
   YARN_CONF_yarn_nodemanager_resource_memory___mb=1024
   YARN_CONF_yarn_scheduler_maximum___allocation___mb=1024
   MAPRED_CONF_mapreduce_map_memory_mb=256
   MAPRED_CONF_mapreduce_reduce_memory_mb=512
   ```

2. **Increase Docker memory limits:**
   ```bash
   # Docker Desktop: Settings > Resources > Memory > 4GB+
   # Linux: Edit /etc/docker/daemon.json
   {
     "default-ulimits": {
       "memlock": {"name": "memlock", "soft": -1, "hard": -1}
     }
   }
   ```

### Network Connectivity Issues

#### Issue: Services cannot communicate with each other

**Symptoms:**
- Hive cannot connect to Namenode
- "Connection refused" errors in logs
- Services appear up but are not functional

**Solutions:**

1. **Check Docker network:**
   ```bash
   docker network ls
   docker network inspect hadoop-unsw-nb15-analytics_hadoop
   ```

2. **Restart with fresh network:**
   ```bash
   docker-compose down
   docker network prune
   docker-compose up -d
   ```

3. **Verify DNS resolution:**
   ```bash
   docker exec namenode nslookup hive-server
   docker exec hive-server nslookup namenode
   ```

## Hadoop-Specific Issues

### HDFS Problems

#### Issue: Namenode fails to start

**Symptoms:**
- Namenode container exits repeatedly
- "Namenode is in safe mode" errors
- Web UI not accessible

**Solutions:**

1. **Format Namenode (CAUTION: This deletes all data):**
   ```bash
   docker-compose down -v
   docker volume rm $(docker volume ls -q | grep namenode)
   docker-compose up -d
   ```

2. **Check safe mode:**
   ```bash
   docker exec namenode hadoop dfsadmin -safemode get
   docker exec namenode hadoop dfsadmin -safemode leave
   ```

3. **Fix permissions:**
   ```bash
   docker exec namenode hadoop fs -chmod 777 /tmp
   docker exec namenode hadoop fs -chmod 777 /user
   ```

#### Issue: Datanode cannot connect to Namenode

**Symptoms:**
- Datanode logs show connection errors
- No available datanodes in Namenode UI
- Cannot write to HDFS

**Solutions:**

1. **Check Namenode accessibility:**
   ```bash
   docker exec datanode telnet namenode 9000
   ```

2. **Restart in sequence:**
   ```bash
   docker-compose stop
   docker-compose start namenode
   # Wait 30 seconds
   docker-compose start datanode
   ```

3. **Verify HDFS health:**
   ```bash
   docker exec namenode hadoop fsck /
   ```

### YARN Issues

#### Issue: ResourceManager fails to start

**Symptoms:**
- YARN web UI not accessible
- Job submission fails
- "Connection to ResourceManager failed" errors

**Solutions:**

1. **Check ResourceManager logs:**
   ```bash
   docker-compose logs resourcemanager
   ```

2. **Verify dependencies:**
   ```bash
   # Ensure Namenode is running first
   curl http://localhost:9870
   docker-compose restart resourcemanager
   ```

3. **Check resource allocation:**
   ```bash
   # Ensure memory settings are reasonable
   docker exec resourcemanager cat /opt/hadoop-3.2.1/etc/hadoop/yarn-site.xml
   ```

#### Issue: NodeManager registration failure

**Symptoms:**
- No nodes available in YARN UI
- Jobs remain in "ACCEPTED" state
- NodeManager logs show registration errors

**Solutions:**

1. **Restart NodeManager:**
   ```bash
   docker-compose restart nodemanager1
   ```

2. **Check ResourceManager connectivity:**
   ```bash
   docker exec nodemanager1 telnet resourcemanager 8030
   ```

## Hive-Specific Issues

### Metastore Problems

#### Issue: Hive Metastore connection failures

**Symptoms:**
- "MetaException" errors
- Cannot connect to Hive Server
- "Database does not exist" errors

**Solutions:**

1. **Check PostgreSQL status:**
   ```bash
   docker-compose logs hive-metastore-postgresql
   docker exec hive-metastore-postgresql pg_isready
   ```

2. **Restart Metastore services:**
   ```bash
   docker-compose restart hive-metastore-postgresql
   docker-compose restart hive-metastore
   docker-compose restart hive-server
   ```

3. **Initialize schema (if needed):**
   ```bash
   docker exec hive-metastore /opt/hive/bin/schematool -dbType postgres -initSchema
   ```

#### Issue: Hive Server connection timeouts

**Symptoms:**
- BeeLine connection hangs
- "Connection timeout" errors
- Cannot execute queries

**Solutions:**

1. **Check Hive Server status:**
   ```bash
   docker-compose logs hive-server
   docker exec hive-server ps aux | grep HiveServer
   ```

2. **Test connection incrementally:**
   ```bash
   # Test basic connectivity
   docker exec hive-server telnet localhost 10000
   
   # Test with simple query
   docker exec hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
   ```

3. **Increase timeout settings:**
   ```bash
   # In Hive session
   SET hive.server2.idle.session.timeout=7200000;
   SET hive.server2.session.check.interval=60000;
   ```

### Query Execution Issues

#### Issue: Queries fail with OutOfMemoryError

**Symptoms:**
- Large queries fail midway
- "Java heap space" errors
- Container memory usage spikes

**Solutions:**

1. **Increase Hive memory settings:**
   ```sql
   SET hive.tez.container.size=2048;
   SET hive.tez.java.opts=-Xmx1600m;
   ```

2. **Optimize query structure:**
   ```sql
   -- Use LIMIT for testing
   SELECT * FROM large_table LIMIT 1000;
   
   -- Enable vectorization
   SET hive.vectorized.execution.enabled=true;
   
   -- Use sampling for large datasets
   SELECT * FROM table TABLESAMPLE(BUCKET 1 OUT OF 10);
   ```

3. **Break complex queries into steps:**
   ```sql
   -- Create intermediate tables
   CREATE TABLE temp_results AS
   SELECT ... FROM ... WHERE ...;
   
   -- Use temp table in subsequent queries
   SELECT * FROM temp_results ...;
   ```

## Python and Jupyter Issues

### Connection Problems

#### Issue: Cannot connect to Hive from Python

**Symptoms:**
- "Connection refused" in Python scripts
- Import errors for pyhive
- Thrift connection timeouts

**Solutions:**

1. **Install required packages:**
   ```bash
   # In Jupyter terminal
   pip install pyhive thrift sasl thrift-sasl
   ```

2. **Test connection parameters:**
   ```python
   from pyhive import hive
   
   # Test with different parameters
   conn = hive.Connection(host='hive-server', port=10000, username='root')
   # or
   conn = hive.Connection(host='localhost', port=10000, username='root')
   ```

3. **Check network connectivity:**
   ```bash
   # From Jupyter container
   docker exec jupyter telnet hive-server 10000
   ```

#### Issue: Jupyter notebook not accessible

**Symptoms:**
- Browser cannot reach http://localhost:8888
- "Connection refused" errors
- Jupyter container exits

**Solutions:**

1. **Check Jupyter logs:**
   ```bash
   docker-compose logs jupyter
   ```

2. **Restart Jupyter service:**
   ```bash
   docker-compose restart jupyter
   ```

3. **Access via container IP:**
   ```bash
   # Find container IP
   docker inspect jupyter | grep IPAddress
   # Access via http://[container-ip]:8888
   ```

### Package Installation Issues

#### Issue: Python packages fail to install

**Symptoms:**
- pip install errors
- Import failures
- Version conflicts

**Solutions:**

1. **Update pip:**
   ```bash
   # In Jupyter terminal
   pip install --upgrade pip
   ```

2. **Install with specific versions:**
   ```bash
   pip install pandas==1.5.0 matplotlib==3.5.0
   ```

3. **Use conda instead:**
   ```bash
   conda install pandas matplotlib seaborn
   ```

## Data Loading Issues

### HDFS Upload Problems

#### Issue: Cannot upload data to HDFS

**Symptoms:**
- "Permission denied" errors
- "No such file or directory"
- Upload commands hang

**Solutions:**

1. **Check HDFS permissions:**
   ```bash
   docker exec namenode hadoop fs -ls /
   docker exec namenode hadoop fs -chmod 777 /data
   ```

2. **Verify file paths:**
   ```bash
   # Check if source file exists
   docker exec namenode ls -la /tmp/
   
   # Check if destination directory exists
   docker exec namenode hadoop fs -mkdir -p /data/unsw-nb15
   ```

3. **Use alternative upload method:**
   ```bash
   # Copy file to container first
   docker cp data/UNSW_NB15_training-set.csv namenode:/tmp/
   
   # Then upload to HDFS
   docker exec namenode hadoop fs -put /tmp/UNSW_NB15_training-set.csv /data/unsw-nb15/
   ```

### Data Format Issues

#### Issue: CSV files not loading correctly

**Symptoms:**
- Empty Hive tables after loading
- Parsing errors in query results
- Wrong number of columns

**Solutions:**

1. **Check CSV format:**
   ```bash
   # Examine file structure
   docker exec namenode head -5 /tmp/UNSW_NB15_training-set.csv
   ```

2. **Verify table schema:**
   ```sql
   DESCRIBE unsw_nb15_training;
   SELECT * FROM unsw_nb15_training LIMIT 5;
   ```

3. **Reload with correct settings:**
   ```sql
   -- Drop and recreate table
   DROP TABLE unsw_nb15_training;
   
   -- Create with explicit settings
   CREATE TABLE unsw_nb15_training (...)
   ROW FORMAT DELIMITED
   FIELDS TERMINATED BY ','
   LINES TERMINATED BY '\n'
   TBLPROPERTIES ('skip.header.line.count'='1');
   ```

## Performance Issues

### Slow Query Execution

#### Issue: Queries take too long to execute

**Symptoms:**
- Queries run for hours without completing
- High CPU/memory usage
- Timeouts in applications

**Solutions:**

1. **Add LIMIT clauses for testing:**
   ```sql
   SELECT * FROM large_table LIMIT 1000;
   ```

2. **Enable query optimization:**
   ```sql
   SET hive.exec.dynamic.partition = true;
   SET hive.exec.dynamic.partition.mode = nonstrict;
   SET hive.optimize.cp = true;
   SET hive.optimize.ppd = true;
   ```

3. **Use sampling for large datasets:**
   ```sql
   SELECT * FROM table TABLESAMPLE(0.1 PERCENT);
   ```

### Memory Usage Issues

#### Issue: System becomes unresponsive

**Symptoms:**
- High memory usage
- Containers being killed
- System freezes

**Solutions:**

1. **Monitor resource usage:**
   ```bash
   docker stats
   free -h
   htop
   ```

2. **Reduce concurrent operations:**
   ```bash
   # Stop unnecessary services temporarily
   docker-compose stop jupyter
   docker-compose stop historyserver
   ```

3. **Optimize container memory:**
   ```yaml
   # In docker-compose.yml
   services:
     namenode:
       mem_limit: 1g
       memswap_limit: 1g
   ```

## General Debugging Strategies

### Log Analysis

1. **Check all service logs:**
   ```bash
   docker-compose logs --tail=50 namenode
   docker-compose logs --tail=50 datanode
   docker-compose logs --tail=50 resourcemanager
   docker-compose logs --tail=50 hive-server
   ```

2. **Follow logs in real-time:**
   ```bash
   docker-compose logs -f [service-name]
   ```

3. **Search for specific errors:**
   ```bash
   docker-compose logs | grep -i error
   docker-compose logs | grep -i exception
   ```

### Health Checks

1. **Service availability:**
   ```bash
   curl http://localhost:9870    # Namenode
   curl http://localhost:8088    # ResourceManager
   curl http://localhost:8888    # Jupyter
   ```

2. **Container status:**
   ```bash
   docker-compose ps
   docker inspect [container-name]
   ```

3. **Network connectivity:**
   ```bash
   docker network ls
   docker exec namenode ping hive-server
   ```

### Recovery Procedures

1. **Soft restart:**
   ```bash
   docker-compose restart
   ```

2. **Hard restart:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Complete reset (WARNING: Deletes all data):**
   ```bash
   docker-compose down -v
   docker system prune -f
   docker-compose up -d
   ```

## Getting Help

### Information to Collect

When seeking help, provide:

1. **System information:**
   ```bash
   uname -a
   docker --version
   docker-compose --version
   free -h
   ```

2. **Service status:**
   ```bash
   docker-compose ps
   docker-compose logs --tail=20 [service-name]
   ```

3. **Error messages:**
   - Complete error text
   - Steps to reproduce
   - Expected vs actual behavior

### Resources

- **Docker Documentation**: https://docs.docker.com/
- **Hadoop Documentation**: https://hadoop.apache.org/docs/
- **Hive Documentation**: https://hive.apache.org/
- **Stack Overflow**: Search for specific error messages

### Best Practices

1. **Regular monitoring:**
   ```bash
   # Check disk space
   df -h
   
   # Monitor container resources
   docker stats --no-stream
   ```

2. **Backup important data:**
   ```bash
   # Export Hive tables
   docker exec hive-server hive -e "EXPORT TABLE ..."
   
   # Backup configuration
   cp docker-compose.yml docker-compose.yml.bak
   ```

3. **Keep logs:**
   ```bash
   # Save logs for troubleshooting
   docker-compose logs > hadoop-cluster.log
   ```

Remember: Most issues can be resolved by carefully reading error messages and following the systematic troubleshooting approach outlined above.
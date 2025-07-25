#!/bin/bash

# Test script for UNSW-NB15 Hadoop Analytics Environment
# This script performs basic tests to verify the environment is working correctly

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/environment_test.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Test result function
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS: $2${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}✗ FAIL: $2${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

echo -e "${BLUE}🧪 Testing UNSW-NB15 Hadoop Analytics Environment${NC}"
echo "================================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting environment tests" > "$LOG_FILE"

# Test 1: Docker Compose Configuration
echo -e "\n${YELLOW}Test 1: Docker Compose Configuration${NC}"
cd "$SCRIPT_DIR"
docker compose config --quiet
test_result $? "Docker Compose configuration is valid"

# Test 2: Environment Files
echo -e "\n${YELLOW}Test 2: Environment Files${NC}"
[ -f ".env" ]
test_result $? ".env file exists"

[ -f "hadoop.env" ]
test_result $? "hadoop.env file exists"

[ -f "download_data.sh" ]
test_result $? "download_data.sh script exists"

[ -x "download_data.sh" ]
test_result $? "download_data.sh script is executable"

# Test 3: Required Directories
echo -e "\n${YELLOW}Test 3: Required Directories${NC}"
[ -d "config" ]
test_result $? "config directory exists"

[ -d "hive" ]
test_result $? "hive directory exists"

[ -d "notebooks" ]
test_result $? "notebooks directory exists"

[ -d "scripts" ]
test_result $? "scripts directory exists"

# Test 4: Configuration Files
echo -e "\n${YELLOW}Test 4: Configuration Files${NC}"
[ -f "config/core-site.xml" ]
test_result $? "core-site.xml exists"

[ -f "config/hdfs-site.xml" ]
test_result $? "hdfs-site.xml exists"

[ -f "config/yarn-site.xml" ]
test_result $? "yarn-site.xml exists"

[ -f "config/mapred-site.xml" ]
test_result $? "mapred-site.xml exists"

# Test 5: Hive Scripts
echo -e "\n${YELLOW}Test 5: Hive Scripts${NC}"
[ -f "hive/create_tables.sql" ]
test_result $? "create_tables.sql exists"

[ -f "hive/analytical_queries.sql" ]
test_result $? "analytical_queries.sql exists"

# Test 6: Jupyter Notebooks
echo -e "\n${YELLOW}Test 6: Jupyter Notebooks${NC}"
[ -f "notebooks/data_exploration.ipynb" ]
test_result $? "data_exploration.ipynb exists"

[ -f "notebooks/machine_learning.ipynb" ]
test_result $? "machine_learning.ipynb exists"

[ -f "notebooks/data_processing_pipeline.ipynb" ]
test_result $? "data_processing_pipeline.ipynb exists"

# Test 7: Scripts
echo -e "\n${YELLOW}Test 7: Scripts${NC}"
[ -f "scripts/setup_environment.sh" ]
test_result $? "setup_environment.sh exists"

[ -x "scripts/setup_environment.sh" ]
test_result $? "setup_environment.sh is executable"

[ -f "scripts/load_data.sh" ]
test_result $? "load_data.sh exists"

[ -x "scripts/load_data.sh" ]
test_result $? "load_data.sh is executable"

# Test 8: Environment Variable Validation
echo -e "\n${YELLOW}Test 8: Environment Variables${NC}"

# Check if required environment variables are defined in .env
grep -q "HADOOP_HOME" .env
test_result $? "HADOOP_HOME defined in .env"

grep -q "YARN_NODEMANAGER_RESOURCE_MEMORY_MB" .env
test_result $? "YARN memory settings defined in .env"

grep -q "POSTGRES_PASSWORD" .env
test_result $? "PostgreSQL settings defined in .env"

# Check hadoop.env
grep -q "CORE_CONF_fs_defaultFS" hadoop.env
test_result $? "HDFS settings defined in hadoop.env"

grep -q "HIVE_METASTORE_JDBC_URL" hadoop.env
test_result $? "Hive metastore settings defined in hadoop.env"

# Test 9: Docker Image Availability
echo -e "\n${YELLOW}Test 9: Docker Images${NC}"

# Check if images exist locally or can be pulled
docker image inspect postgres:13 > /dev/null 2>&1
test_result $? "PostgreSQL image available"

docker image inspect bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8 > /dev/null 2>&1
test_result $? "Hadoop namenode image available"

docker image inspect bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8 > /dev/null 2>&1
test_result $? "Hadoop datanode image available"

docker image inspect bde2020/hive:2.3.2-postgresql-metastore > /dev/null 2>&1
test_result $? "Hive image available"

docker image inspect jupyter/pyspark-notebook:latest > /dev/null 2>&1
test_result $? "Jupyter PySpark image available"

# Test 10: Port Availability Check
echo -e "\n${YELLOW}Test 10: Port Availability${NC}"

# Check if required ports are available (not in use)
ports=(5432 8020 8088 9870 9864 10000 10002 8888 9083)
for port in "${ports[@]}"; do
    if ! lsof -i :$port > /dev/null 2>&1; then
        test_result 0 "Port $port is available"
    else
        echo -e "${YELLOW}⚠ WARNING: Port $port is already in use${NC}" | tee -a "$LOG_FILE"
    fi
done

# Test 11: File Syntax Validation
echo -e "\n${YELLOW}Test 11: File Syntax Validation${NC}"

# Validate XML files (if xmllint is available)
if command -v xmllint > /dev/null 2>&1; then
    for xml_file in config/*.xml; do
        if [ -f "$xml_file" ]; then
            xmllint --noout "$xml_file" 2>/dev/null
            test_result $? "$(basename $xml_file) syntax is valid"
        fi
    done
else
    echo -e "${YELLOW}⚠ WARNING: xmllint not available, skipping XML validation${NC}" | tee -a "$LOG_FILE"
fi

# Validate JSON in Jupyter notebooks (if python is available)
if command -v python > /dev/null 2>&1 || command -v python3 > /dev/null 2>&1; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    for notebook in notebooks/*.ipynb; do
        if [ -f "$notebook" ]; then
            $PYTHON_CMD -m json.tool "$notebook" > /dev/null 2>&1
            test_result $? "$(basename $notebook) JSON syntax is valid"
        fi
    done
else
    echo -e "${YELLOW}⚠ WARNING: Python not available, skipping JSON validation${NC}" | tee -a "$LOG_FILE"
fi

# Test Summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "================================================================"

TOTAL_TESTS=$(grep -c "✓ PASS\|✗ FAIL" "$LOG_FILE" || echo "0")
PASSED_TESTS=$(grep -c "✓ PASS" "$LOG_FILE" || echo "0")
FAILED_TESTS=$(grep -c "✗ FAIL" "$LOG_FILE" || echo "0")

echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    EXIT_CODE=1
else
    echo -e "Failed: ${GREEN}$FAILED_TESTS${NC}"
    EXIT_CODE=0
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Environment is ready for deployment.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Start the environment: ./scripts/setup_environment.sh"
    echo "2. Load sample data: ./download_data.sh"
    echo "3. Access Jupyter Lab: http://localhost:8888"
    echo "4. Access Hadoop Web UI: http://localhost:9870"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    echo ""
    echo "Check the log file for details: $LOG_FILE"
    exit 1
fi
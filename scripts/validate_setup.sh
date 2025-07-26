#!/bin/bash

# Simple validation script to test the UNSW-NB15 data loading implementation
# Tests the success criteria requirements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}UNSW-NB15 Data Loading Validation Test${NC}"
echo -e "${BLUE}============================================${NC}"

# Check if files exist
echo -e "\n${YELLOW}1. Checking required data files...${NC}"
DATA_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")/data"

REQUIRED_FILES=("UNSW-NB15.csv" "UNSW-NB15_features.csv" "UNSW-NB15_LIST_EVENTS.csv")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$DATA_DIR/$file" ]; then
        echo -e "${GREEN}✓ Found: $file${NC}"
    else
        echo -e "${RED}✗ Missing: $file${NC}"
    fi
done

# Check if Docker containers are running
echo -e "\n${YELLOW}2. Checking Docker containers...${NC}"
REQUIRED_CONTAINERS=("namenode" "datanode" "hiveserver2" "hivemetastore")

for container in "${REQUIRED_CONTAINERS[@]}"; do
    if docker ps | grep -q "$container"; then
        echo -e "${GREEN}✓ Container running: $container${NC}"
    else
        echo -e "${RED}✗ Container not running: $container${NC}"
    fi
done

# Test Hive connectivity
echo -e "\n${YELLOW}3. Testing Hive connectivity...${NC}"
if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Hive connection successful${NC}"
else
    echo -e "${RED}✗ Hive connection failed${NC}"
fi

# Test the success criteria if Hive is available
echo -e "\n${YELLOW}4. Testing Success Criteria...${NC}"

# Create test script for success criteria
cat > /tmp/test_success_criteria.sql << 'EOF'
USE unsw_nb15;

-- Test 1: SHOW TABLES
SELECT '=== SHOW TABLES TEST ===' as test;
SHOW TABLES;

-- Test 2: Count main records  
SELECT '=== MAIN DATASET COUNT TEST ===' as test;
SELECT COUNT(*) as unsw_nb15_main_count FROM unsw_nb15_main;

-- Test 3: Features sample
SELECT '=== FEATURES SAMPLE TEST ===' as test;
SELECT * FROM unsw_nb15_features LIMIT 10;

-- Test 4: Events sample
SELECT '=== EVENTS SAMPLE TEST ===' as test;
SELECT * FROM unsw_nb15_events LIMIT 10;
EOF

# Try to run the tests
if docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -f /tmp/test_success_criteria.sql > /tmp/test_results.txt 2>&1; then
    echo -e "${GREEN}✓ Success criteria tests completed${NC}"
    echo -e "${BLUE}Test results saved to: /tmp/test_results.txt${NC}"
    
    # Show summary of results
    echo -e "\n${YELLOW}5. Test Results Summary:${NC}"
    if grep -q "unsw_nb15_main" /tmp/test_results.txt; then
        echo -e "${GREEN}✓ unsw_nb15_main table accessible${NC}"
    fi
    if grep -q "unsw_nb15_features" /tmp/test_results.txt; then
        echo -e "${GREEN}✓ unsw_nb15_features table accessible${NC}"
    fi
    if grep -q "unsw_nb15_events" /tmp/test_results.txt; then
        echo -e "${GREEN}✓ unsw_nb15_events table accessible${NC}"
    fi
else
    echo -e "${RED}✗ Success criteria tests failed${NC}"
    echo "Check the logs for details"
fi

# Clean up
rm -f /tmp/test_success_criteria.sql

echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}Validation test completed${NC}"
echo -e "${BLUE}============================================${NC}"
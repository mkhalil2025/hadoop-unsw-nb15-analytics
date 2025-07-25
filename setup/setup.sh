#!/bin/bash

# Hadoop UNSW-NB15 Analytics Environment Setup Script
# This script sets up the complete Hadoop cluster for Big Data Analytics

set -e

echo "=== Hadoop UNSW-NB15 Analytics Environment Setup ==="
echo "This script will set up a complete Hadoop cluster with Hive and Jupyter for cybersecurity data analysis"
echo

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✓ Docker and Docker Compose are installed"

# Stop any existing containers
echo "Stopping any existing containers..."
docker-compose down -v 2>/dev/null || true

# Pull all required images
echo "Pulling Docker images (this may take several minutes)..."
docker-compose pull

# Start the Hadoop cluster
echo "Starting Hadoop cluster..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check if namenode is ready
echo "Checking Namenode status..."
for i in {1..30}; do
    if curl -s http://localhost:9870 > /dev/null; then
        echo "✓ Namenode is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: Namenode failed to start after 5 minutes"
        exit 1
    fi
    sleep 10
done

# Check if YARN ResourceManager is ready
echo "Checking YARN ResourceManager status..."
for i in {1..30}; do
    if curl -s http://localhost:8088 > /dev/null; then
        echo "✓ YARN ResourceManager is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: YARN ResourceManager failed to start after 5 minutes"
        exit 1
    fi
    sleep 10
done

# Check if Hive Server is ready
echo "Checking Hive Server status..."
for i in {1..60}; do
    if docker exec hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" > /dev/null 2>&1; then
        echo "✓ Hive Server is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "WARNING: Hive Server may still be starting. You can check status later."
        break
    fi
    sleep 10
done

# Create HDFS directories
echo "Creating HDFS directories..."
docker exec namenode hadoop fs -mkdir -p /user/hive/warehouse
docker exec namenode hadoop fs -mkdir -p /tmp
docker exec namenode hadoop fs -mkdir -p /data/unsw-nb15
docker exec namenode hadoop fs -chmod 777 /tmp
docker exec namenode hadoop fs -chmod 777 /user/hive/warehouse

echo
echo "=== Setup Complete! ==="
echo
echo "Services are available at:"
echo "• Hadoop Namenode: http://localhost:9870"
echo "• YARN ResourceManager: http://localhost:8088"
echo "• Hive Server: jdbc:hive2://localhost:10000"
echo "• Jupyter Notebook: http://localhost:8888"
echo
echo "Next steps:"
echo "1. Download the UNSW-NB15 dataset to the data/ directory"
echo "2. Run ./setup/data_loader.sh to load data into HDFS"
echo "3. Run the Hive scripts to create tables and perform analysis"
echo
echo "For troubleshooting, check: docker-compose logs [service-name]"
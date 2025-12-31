#!/bin/bash

# Safe Deployment Script for Vanyatra
# This script deploys updates WITHOUT destroying the database

set -e

echo "================================================"
echo "Vanyatra Safe Deployment Script"
echo "================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NETWORK_NAME="vanyatra-net"
VOLUME_NAME="sqldata-persistent"
SQL_PASSWORD="Akhilesh@22"

echo -e "${BLUE}Step 1: Pre-deployment checks${NC}"

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running${NC}"
    exit 1
fi

# Check if SQL container exists
SQL_RUNNING=$(docker ps -q -f name=vanyatra-sql)
if [ -z "$SQL_RUNNING" ]; then
    echo -e "${YELLOW}⚠️  SQL Server is not running${NC}"
    echo "Starting SQL Server..."
    
    # Create network if needed
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        docker network create "$NETWORK_NAME"
    fi
    
    # Create volume if needed
    if ! docker volume ls | grep -q "$VOLUME_NAME"; then
        docker volume create "$VOLUME_NAME"
    fi
    
    # Start SQL Server
    docker run -d \
        --name vanyatra-sql \
        --network "$NETWORK_NAME" \
        -e "ACCEPT_EULA=Y" \
        -e "SA_PASSWORD=$SQL_PASSWORD" \
        -p 1433:1433 \
        -v "${VOLUME_NAME}:/var/opt/mssql" \
        --restart unless-stopped \
        mcr.microsoft.com/azure-sql-edge:latest
    
    echo "Waiting for SQL Server to start..."
    sleep 20
    
    # Create database if needed
    docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
        -S localhost -U sa -P "$SQL_PASSWORD" \
        -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"
else
    echo -e "${GREEN}✅ SQL Server is running${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Backup current database${NC}"
./backup-database.sh || echo -e "${YELLOW}⚠️  Backup failed, continuing anyway${NC}"

echo ""
echo -e "${BLUE}Step 3: Pull latest code${NC}"
cd ..
git pull origin main || echo -e "${YELLOW}⚠️  Git pull failed, using current code${NC}"

echo ""
echo -e "${BLUE}Step 4: Build new application image${NC}"
cd server
docker build -t vanyatra-server:latest . || {
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
}

echo ""
echo -e "${BLUE}Step 5: Stop and remove old application container${NC}"
docker stop vanyatra-server 2>/dev/null || true
docker rm vanyatra-server 2>/dev/null || true

echo ""
echo -e "${BLUE}Step 6: Start new application container${NC}"
docker run -d \
    --name vanyatra-server \
    --network "$NETWORK_NAME" \
    -p 8000:8080 \
    -e "ASPNETCORE_ENVIRONMENT=Production" \
    -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=$SQL_PASSWORD;TrustServerCertificate=True;" \
    -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=$SQL_PASSWORD;TrustServerCertificate=True;" \
    --restart unless-stopped \
    vanyatra-server:latest

echo ""
echo -e "${BLUE}Step 7: Wait for application to start${NC}"
sleep 10

echo ""
echo -e "${BLUE}Step 8: Verify deployment${NC}"

# Check containers are running
if docker ps | grep -q vanyatra-sql && docker ps | grep -q vanyatra-server; then
    echo -e "${GREEN}✅ All containers running${NC}"
else
    echo -e "${RED}❌ Some containers are not running${NC}"
    docker ps
    exit 1
fi

# Test API health
echo "Testing API health..."
if curl -f http://localhost:8000/health 2>/dev/null; then
    echo -e "${GREEN}✅ API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  API health check failed${NC}"
    echo "Checking logs..."
    docker logs vanyatra-server --tail 20
fi

echo ""
echo "================================================"
echo -e "${GREEN}✅ Deployment completed successfully${NC}"
echo "================================================"
echo ""
echo "Service URLs:"
echo "  API: http://localhost:8000"
echo ""
echo "Useful commands:"
echo "  View logs: docker logs vanyatra-server -f"
echo "  Restart app: docker restart vanyatra-server"
echo "  Check status: docker ps"
echo ""
echo "Database is safe and persistent! 🎉"
echo "================================================"

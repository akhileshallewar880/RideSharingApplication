#!/bin/bash

# Quick fix script for database issues on Azure VM
# Run this on your Azure VM if the database doesn't exist

set -e

echo "================================================"
echo "Vanyatra Database Quick Fix"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if SQL container is running
if ! docker ps | grep -q vanyatra-sql; then
    echo -e "${YELLOW}SQL Server container is not running. Starting it...${NC}"
    docker start vanyatra-sql || {
        echo -e "${RED}Failed to start SQL Server container${NC}"
        echo "Run: docker-compose up -d vanyatra-sql"
        exit 1
    }
    sleep 10
fi

# Wait for SQL Server to be ready
echo -e "${YELLOW}Waiting for SQL Server to be ready...${NC}"
for i in {1..30}; do
    if docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "SELECT 1" &> /dev/null; then
        echo -e "${GREEN}SQL Server is ready${NC}"
        break
    fi
    echo -n "."
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e "${RED}SQL Server failed to start${NC}"
        exit 1
    fi
done

# Check if database exists
echo -e "\n${YELLOW}Checking if RideSharingDb exists...${NC}"
DB_EXISTS=$(docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = 'RideSharingDb'" -h -1 2>/dev/null | tr -d ' ')

if [ "$DB_EXISTS" = "0" ]; then
    echo -e "${YELLOW}Database does not exist. Creating it...${NC}"
    docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "CREATE DATABASE RideSharingDb"
    echo -e "${GREEN}✓ Database created successfully${NC}"
else
    echo -e "${GREEN}✓ Database already exists${NC}"
fi

# Restart application to apply migrations
echo -e "${YELLOW}Restarting application...${NC}"
docker restart vanyatra-server

echo -e "\n${YELLOW}Waiting for application to start...${NC}"
sleep 10

# Show recent logs
echo -e "\n${YELLOW}Recent application logs:${NC}"
docker logs --tail=20 vanyatra-server

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Database fix completed!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nTo monitor logs: docker logs -f vanyatra-server"
echo -e "To test API: curl http://localhost:8000/api/v1/auth/send-otp -H 'Content-Type: application/json' -d '{\"phoneNumber\":\"9595959595\"}'"

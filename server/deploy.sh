#!/bin/bash

# Vanyatra Server Deployment Script for Azure VM
# This script handles building and deploying the RideSharing API

set -e  # Exit on error

echo "================================================"
echo "Vanyatra Server Deployment"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Stop and remove existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker-compose down || true

# Remove old images (optional - uncomment if you want to force rebuild)
# docker rmi vanyatra-server:latest || true

# Build the application
echo -e "${YELLOW}Building the application...${NC}"
docker-compose build --no-cache

# Start the services
echo -e "${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for SQL Server to be ready
echo -e "${YELLOW}Waiting for SQL Server to be ready...${NC}"
sleep 15

# Check SQL Server status
echo -e "${YELLOW}Checking SQL Server connection...${NC}"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "SELECT @@VERSION" || {
    echo -e "${RED}Failed to connect to SQL Server${NC}"
    exit 1
}

# Check if database exists, create if not
echo -e "${YELLOW}Checking if database exists...${NC}"
DB_EXISTS=$(docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = 'RideSharingDb'" -h -1)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo -e "${YELLOW}Creating RideSharingDb database...${NC}"
    docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "CREATE DATABASE RideSharingDb"
    echo -e "${GREEN}Database created successfully${NC}"
else
    echo -e "${GREEN}Database already exists${NC}"
fi

# Wait for application to start
echo -e "${YELLOW}Waiting for application to start...${NC}"
sleep 10

# Show container status
echo -e "\n${GREEN}Container Status:${NC}"
docker-compose ps

# Show logs
echo -e "\n${YELLOW}Recent logs:${NC}"
docker-compose logs --tail=50

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\nAPI is available at: http://localhost:8000"
echo -e "To view logs: docker-compose logs -f"
echo -e "To stop: docker-compose down"
echo -e "To restart: docker-compose restart"

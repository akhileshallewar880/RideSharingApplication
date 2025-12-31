#!/bin/bash

# Complete VM Setup and Testing Script
# Run this on your Azure VM

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================"
echo "Vanyatra Complete Setup and Testing"
echo "================================================"
echo ""

# Step 1: Find repository
echo -e "${BLUE}Step 1: Locating repository...${NC}"
REPO_PATH=""

if [ -d ~/vanyatra_rural_ride_booking ]; then
    REPO_PATH=~/vanyatra_rural_ride_booking
elif [ -d /home/akhileshallewar880/vanyatra_rural_ride_booking ]; then
    REPO_PATH=/home/akhileshallewar880/vanyatra_rural_ride_booking
else
    echo -e "${RED}Repository not found!${NC}"
    echo "Please provide the full path to the repository:"
    read -r REPO_PATH
    
    if [ ! -d "$REPO_PATH" ]; then
        echo -e "${RED}Invalid path. Please clone the repository first:${NC}"
        echo "cd ~ && git clone <your-repo-url>"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Found repository at: $REPO_PATH${NC}"
cd "$REPO_PATH"

# Step 2: Pull latest
echo -e "\n${BLUE}Step 2: Pulling latest code...${NC}"
git pull origin main || echo -e "${YELLOW}Warning: Could not pull latest code${NC}"

# Step 3: Setup Docker
echo -e "\n${BLUE}Step 3: Setting up Docker environment...${NC}"

# Stop existing containers
docker stop vanyatra-server vanyatra-sql 2>/dev/null || true
docker rm vanyatra-server vanyatra-sql 2>/dev/null || true

# Create volume and network
docker volume create sqldata-persistent 2>/dev/null || true
docker network create vanyatra-net 2>/dev/null || true

echo -e "${GREEN}✓ Docker environment ready${NC}"

# Step 4: Start SQL Server
echo -e "\n${BLUE}Step 4: Starting SQL Server with persistence...${NC}"
docker run -d --name vanyatra-sql --network vanyatra-net \
  -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 -v sqldata-persistent:/var/opt/mssql \
  --restart unless-stopped \
  mcr.microsoft.com/azure-sql-edge:latest

echo "Waiting for SQL Server to start..."
sleep 30

# Test SQL connection
if docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -Q "SELECT 1" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ SQL Server is running${NC}"
else
  echo -e "${RED}✗ SQL Server failed to start${NC}"
  exit 1
fi

# Step 5: Create database
echo -e "\n${BLUE}Step 5: Creating database...${NC}"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"

echo -e "${GREEN}✓ Database created${NC}"

# Step 6: Run migrations
echo -e "\n${BLUE}Step 6: Running database migrations...${NC}"
if [ -f "$REPO_PATH/create-database-schema.sql" ]; then
  docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
    < "$REPO_PATH/create-database-schema.sql"
  echo -e "${GREEN}✓ Migrations completed${NC}"
else
  echo -e "${YELLOW}⚠ Migration file not found, skipping${NC}"
fi

# Check table count
TABLE_COUNT=$(docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'" -h -1 | tr -d ' ')

echo "Tables created: $TABLE_COUNT"

# Step 7: Build and deploy application
echo -e "\n${BLUE}Step 7: Building and deploying application...${NC}"
cd "$REPO_PATH/server"

if [ -f "./safe-deploy.sh" ]; then
  chmod +x *.sh
  ./safe-deploy.sh
else
  echo "Building application manually..."
  docker build -t vanyatra-server:latest .
  
  docker run -d --name vanyatra-server --network vanyatra-net \
    -p 8000:8080 \
    -e "ASPNETCORE_ENVIRONMENT=Production" \
    -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
    -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
    --restart unless-stopped \
    vanyatra-server:latest
fi

echo "Waiting for application to start..."
sleep 15

# Step 8: Insert test data
echo -e "\n${BLUE}Step 8: Creating test data for persistence verification...${NC}"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TestPersistence')
      CREATE TABLE TestPersistence (Id INT PRIMARY KEY, TestValue NVARCHAR(100), CreatedAt DATETIME);
      IF NOT EXISTS (SELECT * FROM TestPersistence WHERE Id = 1)
      INSERT INTO TestPersistence VALUES (1, 'Setup Test Data - $(date)', GETDATE());" 2>/dev/null || true

echo -e "${GREEN}✓ Test data created${NC}"

# Step 9: Verification
echo -e "\n${BLUE}Step 9: Running verification tests...${NC}"
echo ""

# Check containers
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check volume
echo "=== Volume Status ==="
docker volume ls | grep sqldata-persistent
echo ""

# Check database
echo "=== Database Status ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'" -h -1
echo ""

# Test API
echo "=== API Health Check ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✓ API is healthy (HTTP $HTTP_CODE)${NC}"
else
  echo -e "${YELLOW}⚠ API returned HTTP $HTTP_CODE${NC}"
  echo "Checking logs..."
  docker logs vanyatra-server --tail 20
fi
echo ""

# Test data
echo "=== Test Data (for persistence verification) ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence" 2>/dev/null || echo "No test data found"
echo ""

# Final summary
echo "================================================"
echo -e "${GREEN}✅ SETUP COMPLETE${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Test API: curl http://localhost:8000/health"
echo "2. Enable CI/CD and push a change to trigger deployment"
echo "3. Verify data persists: SELECT * FROM TestPersistence"
echo "4. Test VM restart: sudo reboot"
echo "5. After reboot, verify data still exists"
echo ""
echo "For detailed testing, see VM_COMPLETE_SETUP.md"
echo "================================================"

#!/bin/bash
# One-command API fix for Azure VM
# Copy and paste this entire script into your VM terminal

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Vanyatra API Setup - One Command Fix"
echo "=========================================="

# 1. Find or clone repository
echo -e "\n${YELLOW}[1/8] Finding repository...${NC}"
REPO_PATH=""

if [ -d ~/vanyatra_rural_ride_booking ]; then
    REPO_PATH=~/vanyatra_rural_ride_booking
    echo -e "${GREEN}✓ Found at: $REPO_PATH${NC}"
elif [ -d /home/akhileshallewar880/vanyatra_rural_ride_booking ]; then
    REPO_PATH=/home/akhileshallewar880/vanyatra_rural_ride_booking
    echo -e "${GREEN}✓ Found at: $REPO_PATH${NC}"
else
    echo -e "${YELLOW}Repository not found. Cloning...${NC}"
    cd ~
    git clone https://github.com/akhileshallewar880/vanyatra_rural_ride_booking.git
    REPO_PATH=~/vanyatra_rural_ride_booking
    echo -e "${GREEN}✓ Cloned to: $REPO_PATH${NC}"
fi

cd "$REPO_PATH"
git pull origin main 2>/dev/null || echo "Using local code"

# 2. Stop old containers
echo -e "\n${YELLOW}[2/8] Cleaning up old containers...${NC}"
docker stop vanyatra-server vanyatra-sql 2>/dev/null || true
docker rm vanyatra-server vanyatra-sql 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"

# 3. Create network and volume
echo -e "\n${YELLOW}[3/8] Setting up Docker infrastructure...${NC}"
docker network create vanyatra-net 2>/dev/null || echo "Network already exists"
docker volume create sqldata-persistent 2>/dev/null || echo "Volume already exists"
echo -e "${GREEN}✓ Infrastructure ready${NC}"

# 4. Start SQL Server
echo -e "\n${YELLOW}[4/8] Starting SQL Server...${NC}"
docker run -d \
  --name vanyatra-sql \
  --network vanyatra-net \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 \
  -v sqldata-persistent:/var/opt/mssql \
  --restart unless-stopped \
  mcr.microsoft.com/azure-sql-edge:latest

echo "Waiting for SQL Server (30 seconds)..."
sleep 30
echo -e "${GREEN}✓ SQL Server started${NC}"

# 5. Create database
echo -e "\n${YELLOW}[5/8] Creating database...${NC}"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb" 2>/dev/null || true
echo -e "${GREEN}✓ Database ready${NC}"

# 6. Run migrations
echo -e "\n${YELLOW}[6/8] Running database migrations...${NC}"
if [ -f "$REPO_PATH/create-database-schema.sql" ]; then
  docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
    < "$REPO_PATH/create-database-schema.sql" 2>/dev/null || echo "Schema already exists"
  echo -e "${GREEN}✓ Migrations complete${NC}"
else
  echo -e "${YELLOW}⚠ Migration file not found - skipping${NC}"
fi

# 7. Build and start application
echo -e "\n${YELLOW}[7/8] Building and starting application...${NC}"
cd "$REPO_PATH/server"

# Build image
docker build -t vanyatra-server:latest . 2>&1 | tail -5

# Start container
docker run -d \
  --name vanyatra-server \
  --network vanyatra-net \
  -p 8000:8080 \
  -e "ASPNETCORE_ENVIRONMENT=Production" \
  -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  --restart unless-stopped \
  vanyatra-server:latest

echo "Waiting for application (15 seconds)..."
sleep 15
echo -e "${GREEN}✓ Application started${NC}"

# 8. Verify
echo -e "\n${YELLOW}[8/8] Verifying API...${NC}"
echo ""

# Check containers
echo "Containers:"
docker ps --format "  {{.Names}}: {{.Status}}" | grep vanyatra

# Test API
echo ""
echo "API Health Check:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
  echo -e "  ${GREEN}✓ API is responding (HTTP $HTTP_CODE)${NC}"
else
  echo -e "  ${YELLOW}⚠ API returned HTTP $HTTP_CODE${NC}"
  echo ""
  echo "Recent logs:"
  docker logs vanyatra-server --tail 10
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "Test your API:"
echo "  curl http://localhost:8000/health"
echo ""
echo "View logs:"
echo "  docker logs vanyatra-server -f"
echo ""
echo "Check status:"
echo "  docker ps"
echo "=========================================="

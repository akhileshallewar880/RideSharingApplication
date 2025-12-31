#!/bin/bash
# VanYatra Auto-Start Setup Script
# This script configures systemd to auto-start your application on VM boot

set -e

echo "=========================================="
echo "VanYatra Auto-Start Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}Project directory: $PROJECT_DIR${NC}"
echo ""

# Step 1: Enable Docker
echo -e "${BLUE}Step 1: Enabling Docker service...${NC}"
sudo systemctl enable docker
if sudo systemctl is-enabled docker | grep -q enabled; then
    echo -e "${GREEN}✓ Docker service enabled${NC}"
else
    echo -e "${RED}✗ Failed to enable Docker service${NC}"
    exit 1
fi
echo ""

# Step 2: Start Docker if not running
echo -e "${BLUE}Step 2: Starting Docker service...${NC}"
if ! sudo systemctl is-active docker | grep -q active; then
    sudo systemctl start docker
    sleep 3
fi
if sudo systemctl is-active docker | grep -q active; then
    echo -e "${GREEN}✓ Docker service is running${NC}"
else
    echo -e "${RED}✗ Docker service failed to start${NC}"
    exit 1
fi
echo ""

# Step 3: Create systemd service file
echo -e "${BLUE}Step 3: Creating systemd service file...${NC}"
sudo tee /etc/systemd/system/vanyatra.service > /dev/null <<EOF
[Unit]
Description=VanYatra Ride Sharing Application
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStartPre=/usr/bin/docker network create vanyatra-network || true
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
ExecReload=/usr/bin/docker-compose restart
StandardOutput=journal
StandardError=journal
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

if [ -f /etc/systemd/system/vanyatra.service ]; then
    echo -e "${GREEN}✓ Service file created${NC}"
else
    echo -e "${RED}✗ Failed to create service file${NC}"
    exit 1
fi
echo ""

# Step 4: Set correct permissions
echo -e "${BLUE}Step 4: Setting permissions...${NC}"
sudo chmod 644 /etc/systemd/system/vanyatra.service
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 5: Reload systemd
echo -e "${BLUE}Step 5: Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

# Step 6: Enable the service
echo -e "${BLUE}Step 6: Enabling VanYatra service...${NC}"
sudo systemctl enable vanyatra.service
if sudo systemctl is-enabled vanyatra.service | grep -q enabled; then
    echo -e "${GREEN}✓ VanYatra service enabled (will start on boot)${NC}"
else
    echo -e "${RED}✗ Failed to enable VanYatra service${NC}"
    exit 1
fi
echo ""

# Step 7: Stop existing containers (if any)
echo -e "${BLUE}Step 7: Stopping existing containers...${NC}"
cd "$PROJECT_DIR"
if docker ps -a | grep -q vanyatra; then
    docker-compose down 2>/dev/null || true
    echo -e "${GREEN}✓ Existing containers stopped${NC}"
else
    echo -e "${YELLOW}⚠ No existing containers found${NC}"
fi
echo ""

# Step 8: Start the service
echo -e "${BLUE}Step 8: Starting VanYatra service...${NC}"
sudo systemctl start vanyatra.service
sleep 5
echo ""

# Step 9: Check service status
echo -e "${BLUE}Step 9: Checking service status...${NC}"
if sudo systemctl is-active vanyatra.service | grep -q active; then
    echo -e "${GREEN}✓ VanYatra service is active${NC}"
else
    echo -e "${YELLOW}⚠ Service status:${NC}"
    sudo systemctl status vanyatra.service --no-pager -l
fi
echo ""

# Step 10: Verify containers are running
echo -e "${BLUE}Step 10: Verifying containers...${NC}"
sleep 10  # Give containers time to start
echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep vanyatra || echo -e "${YELLOW}⚠ Containers not running yet${NC}"
echo ""

# Step 11: Check if API is responding
echo -e "${BLUE}Step 11: Testing API endpoint...${NC}"
sleep 5  # Additional time for API to initialize
for i in {1..10}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/admin/health 2>/dev/null | grep -q 200; then
        echo -e "${GREEN}✓ API is responding (HTTP 200)${NC}"
        API_OK=true
        break
    else
        if [ $i -eq 10 ]; then
            echo -e "${YELLOW}⚠ API not responding yet (may need more time to initialize)${NC}"
            API_OK=false
        else
            sleep 3
        fi
    fi
done
echo ""

# Step 12: Check Nginx
echo -e "${BLUE}Step 12: Checking Nginx...${NC}"
if command -v nginx &> /dev/null; then
    if sudo systemctl is-active nginx | grep -q active; then
        echo -e "${GREEN}✓ Nginx is running${NC}"
    else
        echo -e "${YELLOW}⚠ Nginx is installed but not running${NC}"
        echo "  Starting Nginx..."
        sudo systemctl start nginx
        sudo systemctl enable nginx
    fi
else
    echo -e "${YELLOW}⚠ Nginx not installed (web apps won't be accessible)${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Docker service: enabled and running"
echo "  ✓ VanYatra service: enabled and running"
echo "  ✓ Auto-start on boot: configured"
echo ""
echo "Service Status:"
sudo systemctl status vanyatra.service --no-pager -l | head -5
echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep vanyatra || echo "  (Containers still starting...)"
echo ""
echo "=========================================="
echo "What to test next:"
echo "=========================================="
echo ""
echo "1. Test API locally on VM:"
echo "   curl http://localhost:8000/api/v1/admin/health"
echo ""
echo "2. Test API from outside VM:"
echo "   curl http://57.159.31.172:8000/api/v1/admin/health"
echo ""
echo "3. Test admin web app:"
echo "   http://57.159.31.172"
echo ""
echo "4. Test auto-start (reboot VM):"
echo "   sudo reboot"
echo "   # After reboot, SSH back and run: docker ps"
echo ""
echo "=========================================="
echo "Useful Commands:"
echo "=========================================="
echo ""
echo "Check service status:"
echo "  sudo systemctl status vanyatra.service"
echo ""
echo "View service logs:"
echo "  sudo journalctl -u vanyatra.service -f"
echo ""
echo "View container logs:"
echo "  docker logs vanyatra-server -f"
echo "  docker logs vanyatra-sql -f"
echo ""
echo "Restart service:"
echo "  sudo systemctl restart vanyatra.service"
echo ""
echo "Stop service:"
echo "  sudo systemctl stop vanyatra.service"
echo ""
echo "=========================================="

# If API is not responding, show troubleshooting tips
if [ "$API_OK" = false ]; then
    echo ""
    echo -e "${YELLOW}=========================================="
    echo "⚠ API Troubleshooting"
    echo "==========================================${NC}"
    echo ""
    echo "The API didn't respond immediately. This could be normal."
    echo "Check the following:"
    echo ""
    echo "1. View API logs:"
    echo "   docker logs vanyatra-server --tail=50"
    echo ""
    echo "2. Check SQL Server:"
    echo "   docker logs vanyatra-sql --tail=30"
    echo ""
    echo "3. Check database connection:"
    echo "   docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'Akhilesh@22' -Q 'SELECT name FROM sys.databases'"
    echo ""
    echo "4. If database doesn't exist, the app will create it on first run."
    echo "   Wait 1-2 minutes and try again:"
    echo "   curl http://localhost:8000/api/v1/admin/health"
    echo ""
fi

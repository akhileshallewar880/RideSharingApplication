#!/bin/bash

# Database Backup Script for Vanyatra
# Run this before any major changes or deployments

set -e

BACKUP_DIR="./database-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="RideSharingDb_${TIMESTAMP}.bak"

echo "================================================"
echo "Vanyatra Database Backup"
echo "================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if SQL container is running
if ! docker ps | grep -q vanyatra-sql; then
    echo -e "${RED}❌ SQL Server container is not running${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating database backup...${NC}"

# Create backup inside container
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P "Akhilesh@22" \
    -Q "BACKUP DATABASE RideSharingDb TO DISK = '/tmp/${BACKUP_FILE}' WITH FORMAT, INIT, NAME = 'Full Backup';" \
    || {
        echo -e "${RED}❌ Backup failed${NC}"
        exit 1
    }

# Copy backup from container to host
docker cp "vanyatra-sql:/tmp/${BACKUP_FILE}" "${BACKUP_DIR}/${BACKUP_FILE}"

# Verify backup exists
if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
    echo -e "${GREEN}✅ Backup created successfully${NC}"
    echo "Location: ${BACKUP_DIR}/${BACKUP_FILE}"
    echo "Size: ${BACKUP_SIZE}"
    
    # Clean up old backups (keep last 10)
    echo -e "${YELLOW}Cleaning up old backups...${NC}"
    cd "$BACKUP_DIR"
    ls -t RideSharingDb_*.bak | tail -n +11 | xargs -r rm -f
    echo -e "${GREEN}✅ Old backups cleaned (kept last 10)${NC}"
else
    echo -e "${RED}❌ Backup file not found${NC}"
    exit 1
fi

echo ""
echo "================================================"
echo "✅ Backup completed successfully"
echo "================================================"

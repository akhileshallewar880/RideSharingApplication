#!/bin/bash

# Database Restore Script for Vanyatra
# Usage: ./restore-database.sh <backup-file>

set -e

BACKUP_DIR="./database-backups"

echo "================================================"
echo "Vanyatra Database Restore"
echo "================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if backup file provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Available backups:${NC}"
    ls -lh "$BACKUP_DIR"/*.bak 2>/dev/null || echo "No backups found"
    echo ""
    echo "Usage: $0 <backup-file>"
    echo "Example: $0 ${BACKUP_DIR}/RideSharingDb_20241231_120000.bak"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# Check if SQL container is running
if ! docker ps | grep -q vanyatra-sql; then
    echo -e "${RED}❌ SQL Server container is not running${NC}"
    exit 1
fi

echo -e "${YELLOW}Restoring database from: $BACKUP_FILE${NC}"
echo -e "${RED}⚠️  This will overwrite the current database!${NC}"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Copy backup to container
BACKUP_NAME=$(basename "$BACKUP_FILE")
docker cp "$BACKUP_FILE" "vanyatra-sql:/tmp/${BACKUP_NAME}"

# Restore database
echo -e "${YELLOW}Restoring database...${NC}"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U sa -P "Akhilesh@22" \
    -Q "ALTER DATABASE RideSharingDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE; RESTORE DATABASE RideSharingDb FROM DISK = '/tmp/${BACKUP_NAME}' WITH REPLACE; ALTER DATABASE RideSharingDb SET MULTI_USER;" \
    || {
        echo -e "${RED}❌ Restore failed${NC}"
        exit 1
    }

echo -e "${GREEN}✅ Database restored successfully${NC}"

# Restart application to reconnect
echo -e "${YELLOW}Restarting application...${NC}"
docker restart vanyatra-server

echo ""
echo "================================================"
echo "✅ Restore completed successfully"
echo "================================================"

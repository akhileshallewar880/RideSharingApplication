#!/bin/bash
# Fix database issue - Create database and run migrations

set -e

echo "🔧 Fixing database issue on Azure server..."
echo ""

SERVER_IP="57.159.31.172"
SSH_KEY="server/ride_sharing_application/akhileshallewar880-key.pem"
SSH_USER="akhileshallewar880"
DB_PASSWORD="Akhilesh@22"

echo "Step 1: Creating RideSharingDb database..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" << 'ENDSSH'
docker exec vanyatra-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Akhilesh@22' -C -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb')
BEGIN
    CREATE DATABASE RideSharingDb;
    PRINT 'Database RideSharingDb created successfully';
END
ELSE
BEGIN
    PRINT 'Database RideSharingDb already exists';
END
"
ENDSSH

echo ""
echo "✅ Database created!"
echo ""
echo "Step 2: Restarting API container to run migrations..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "docker restart vanyatra-server"

echo ""
echo "Step 3: Waiting for container to start (15 seconds)..."
sleep 15

echo ""
echo "Step 4: Checking API logs..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "docker logs vanyatra-server --tail 30"

echo ""
echo "Step 5: Verifying database tables..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" << 'ENDSSH'
docker exec vanyatra-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Akhilesh@22' -C -Q "
USE RideSharingDb;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;
"
ENDSSH

echo ""
echo "🎉 Database fix complete!"
echo ""
echo "📋 Test the API:"
echo "   curl http://57.159.31.172:8000/swagger/index.html"
echo ""

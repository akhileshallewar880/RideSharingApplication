# 🚀 COMPLETE VM SETUP & TESTING GUIDE

## STEP 1: Find or Clone Repository (Run on VM)

```bash
# Check if repo exists anywhere
find /home -name "vanyatra_rural_ride_booking" 2>/dev/null

# If nothing found, clone the repository
cd ~
git clone https://github.com/<your-username>/vanyatra_rural_ride_booking.git

# Or use the correct path if it exists elsewhere
# Then navigate to it
cd ~/vanyatra_rural_ride_booking
```

## STEP 2: Complete Setup (Run on VM)

```bash
# Navigate to repo (adjust path if needed)
cd ~/vanyatra_rural_ride_booking

# Pull latest fixes
git pull origin main

# Setup persistence
docker stop vanyatra-server vanyatra-sql 2>/dev/null || true
docker rm vanyatra-server vanyatra-sql 2>/dev/null || true
docker volume create sqldata-persistent
docker network create vanyatra-net 2>/dev/null || true

# Start SQL Server with persistent volume
docker run -d --name vanyatra-sql --network vanyatra-net \
  -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 -v sqldata-persistent:/var/opt/mssql \
  --restart unless-stopped mcr.microsoft.com/azure-sql-edge:latest

# Wait for SQL to be ready
echo "Waiting for SQL Server to start..."
sleep 30

# Test SQL connection
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -Q "SELECT @@VERSION"

# Create database
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"

# Verify database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"

# Run migrations
docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  < create-database-schema.sql

# Count tables created
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
```

## STEP 3: Deploy Application (Run on VM)

```bash
cd ~/vanyatra_rural_ride_booking/server

# Make scripts executable
chmod +x *.sh

# Deploy application
./safe-deploy.sh

# If safe-deploy.sh fails, do manual deployment:
docker build -t vanyatra-server:latest .

docker run -d --name vanyatra-server --network vanyatra-net \
  -p 8000:8080 \
  -e "ASPNETCORE_ENVIRONMENT=Production" \
  -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  --restart unless-stopped \
  vanyatra-server:latest

# Wait for app to start
sleep 15
```

## STEP 4: Verify Everything is Working

```bash
# Check containers are running
echo "=== Container Status ==="
docker ps

# Check volume exists
echo -e "\n=== Volume Status ==="
docker volume ls | grep sqldata-persistent

# Check database
echo -e "\n=== Database Status ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"

# Test API health endpoint
echo -e "\n=== API Health Check ==="
curl -v http://localhost:8000/health 2>&1 | grep -E "HTTP|Connection"

# Test API send-otp endpoint
echo -e "\n=== API Send-OTP Test ==="
curl -X POST http://localhost:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9595959595","countryCode":"+91"}' | jq '.'

# Check application logs (last 30 lines)
echo -e "\n=== Application Logs ==="
docker logs vanyatra-server --tail 30
```

## STEP 5: Test Data Persistence Before CI/CD

```bash
# Insert test data
echo "=== Inserting Test Data ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TestPersistence')
      CREATE TABLE TestPersistence (Id INT PRIMARY KEY, TestValue NVARCHAR(100), CreatedAt DATETIME);
      INSERT INTO TestPersistence VALUES (1, 'Before CI/CD - $(date)', GETDATE());"

# Verify test data exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"
```

## STEP 6: Enable and Test CI/CD Pipeline

### On your LOCAL machine:

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Re-enable CI/CD if it was disabled
if [ -f .github/workflows/deploy-to-azure-vm.yml.DISABLED ]; then
  git mv .github/workflows/deploy-to-azure-vm.yml.DISABLED .github/workflows/deploy-to-azure-vm.yml
fi

# Make a small change to trigger CI/CD
echo "# CI/CD Test - $(date)" >> .github/workflows/README.md

git add .
git commit -m "Test CI/CD with database persistence"
git push origin main
```

### Monitor CI/CD:

1. Go to GitHub Actions: https://github.com/<your-username>/vanyatra_rural_ride_booking/actions
2. Watch the deployment run
3. Wait for it to complete

### After CI/CD completes, verify on VM:

```bash
# Check containers are still running
docker ps

# Check SQL Server is SAME container (not recreated)
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.CreatedAt}}"

# Verify test data STILL EXISTS (proves persistence)
echo "=== Checking if data persisted after CI/CD ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"

# Check application is updated
docker logs vanyatra-server --tail 20

# Test API still works
curl http://localhost:8000/health
```

## STEP 7: Test VM Restart (Final Test)

```bash
# Backup first (just in case)
cd ~/vanyatra_rural_ride_booking/server
./backup-database.sh

# Note current container IDs
echo "Container IDs before restart:"
docker ps --format "table {{.ID}}\t{{.Names}}"

# Restart VM
sudo reboot
```

### After VM comes back online (SSH again):

```bash
# Wait 2-3 minutes for containers to auto-start
sleep 60

# Check containers auto-started
echo "=== Container Status After Reboot ==="
docker ps

# If containers didn't auto-start (they should with --restart unless-stopped)
if ! docker ps | grep -q vanyatra-sql; then
  docker start vanyatra-sql
  sleep 10
fi

if ! docker ps | grep -q vanyatra-server; then
  docker start vanyatra-server
  sleep 10
fi

# Verify data STILL EXISTS after reboot
echo "=== Checking if data persisted after VM restart ==="
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"

# Test API
curl http://localhost:8000/health

# Check application logs
docker logs vanyatra-server --tail 20
```

## STEP 8: Clean Logs and Final Verification

```bash
# Clear old logs
docker system prune -f

# Get clean status
echo "=== FINAL SYSTEM STATUS ==="
echo ""
echo "Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Volumes:"
docker volume ls | grep sqldata
echo ""
echo "Networks:"
docker network ls | grep vanyatra
echo ""
echo "Database Tables:"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
echo ""
echo "Test Data (Should exist after ALL tests):"
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"
echo ""
echo "API Health:"
curl -s http://localhost:8000/health | jq '.'
```

## ✅ SUCCESS CRITERIA

All of these should be TRUE:

- [ ] Containers running: `docker ps` shows both vanyatra-sql and vanyatra-server
- [ ] Volume persists: `docker volume ls` shows sqldata-persistent
- [ ] Database has tables: Table count > 0
- [ ] API responds: `curl http://localhost:8000/health` returns 200
- [ ] Data survived CI/CD: TestPersistence table still has data
- [ ] Data survived VM restart: TestPersistence table still has data
- [ ] No error logs: `docker logs vanyatra-server --tail 50` shows no major errors
- [ ] Containers auto-restart: After reboot, containers started automatically

## 🆘 TROUBLESHOOTING

### Container not running?
```bash
docker start vanyatra-sql
sleep 10
docker start vanyatra-server
```

### API not responding?
```bash
docker restart vanyatra-server
sleep 10
curl http://localhost:8000/health
```

### Database connection error?
```bash
docker exec vanyatra-server printenv | grep ConnectionStrings
# Should show Server=vanyatra-sql, not localhost
```

### Need to rebuild?
```bash
cd ~/vanyatra_rural_ride_booking/server
docker build -t vanyatra-server:latest .
docker stop vanyatra-server && docker rm vanyatra-server
./safe-deploy.sh
```

## 📊 EXPECTED OUTPUT (No Errors)

All commands should complete successfully with:
- ✅ Containers showing "Up" status
- ✅ Health endpoints returning 200 OK
- ✅ Test data persisting through all operations
- ✅ Clean logs without major errors
- ✅ API endpoints responding correctly

---

**If all tests pass, you're PRODUCTION READY! 🚀**

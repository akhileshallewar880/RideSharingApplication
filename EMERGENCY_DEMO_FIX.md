# 🚨 EMERGENCY DATABASE PERSISTENCE FIX

## Immediate Actions (Manual - Do This NOW on Your VM)

### 1. SSH into your Azure VM
```bash
ssh <your-username>@<vm-ip>
```

### 2. Stop EVERYTHING and create persistent volume
```bash
# Stop all containers
docker stop vanyatra-server vanyatra-sql || true
docker rm vanyatra-server vanyatra-sql || true

# Create/verify persistent volume
docker volume create sqldata-persistent

# Verify it exists
docker volume ls | grep sqldata-persistent
```

### 3. Start SQL Server with PERSISTENT volume
```bash
docker run -d \
  --name vanyatra-sql \
  --network vanyatra-net \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 \
  -v sqldata-persistent:/var/opt/mssql \
  --restart unless-stopped \
  mcr.microsoft.com/azure-sql-edge:latest

# Wait for SQL to start
sleep 15
```

### 4. Verify SQL is running and create database
```bash
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"

# Verify database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"
```

### 5. Start your application
```bash
docker run -d \
  --name vanyatra-server \
  --network vanyatra-net \
  -p 8000:8080 \
  -e "ASPNETCORE_ENVIRONMENT=Production" \
  -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  --restart unless-stopped \
  <your-dockerhub-username>/vanyatra-server:latest
```

### 6. Run migrations/create tables NOW
```bash
# Copy your SQL scripts to the VM first, then:
cd ~/vanyatra_rural_ride_booking

# Create all your tables/migrations
docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  < create-database-schema.sql

# Run any other migration scripts you have
```

### 7. **DISABLE CI/CD Pipeline** (Critical!)
```bash
# On your local machine, rename the workflow to disable it temporarily
mv .github/workflows/deploy-to-azure-vm.yml .github/workflows/deploy-to-azure-vm.yml.disabled
git add .
git commit -m "Temporarily disable CI/CD for demo"
git push
```

## For Your Demo TODAY:

1. ✅ Database will persist across VM restarts
2. ✅ Data won't be lost when VM deallocates
3. ✅ No CI/CD will destroy your data
4. ⚠️ Make manual deployments if needed (see below)

## Manual Deployment (If needed during demo):

```bash
# SSH to VM
ssh <username>@<vm-ip>

# Pull latest code
cd ~/vanyatra_rural_ride_booking
git pull

# Rebuild ONLY the app container (NOT SQL!)
cd server
docker build -t <your-dockerhub-username>/vanyatra-server:latest .

# Restart only app (SQL keeps running)
docker stop vanyatra-server
docker rm vanyatra-server

docker run -d \
  --name vanyatra-server \
  --network vanyatra-net \
  -p 8000:8080 \
  -e "ASPNETCORE_ENVIRONMENT=Production" \
  -e "ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;" \
  --restart unless-stopped \
  <your-dockerhub-username>/vanyatra-server:latest
```

## Verification Commands:

```bash
# Check SQL is running
docker ps | grep vanyatra-sql

# Check volume exists
docker volume ls | grep sqldata-persistent

# Check database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"

# Check data persists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"

# Test API
curl http://localhost:8000/health
```

## After Demo - Proper Fix:

After your demo, I'll implement:
1. ✅ Fixed CI/CD pipeline with proper volume management
2. ✅ Automatic database backup/restore
3. ✅ Migration management
4. ✅ Zero-downtime deployments

## Emergency Contact Commands:

If something breaks during demo:

```bash
# Restart application only (data safe)
docker restart vanyatra-server

# View logs
docker logs vanyatra-server --tail 50

# Check SQL connection
docker exec vanyatra-server curl http://localhost:8080/health
```

---

## WHY This Was Happening:

1. **CI/CD was destroying SQL container** every deployment
2. **No volume mounted** = all data lost
3. **VM deallocation** stopped containers, but volume would persist if properly configured
4. Your docker-compose had volumes, but CI/CD wasn't using them!

## What Changed:

| Before | After |
|--------|-------|
| `docker run` without `-v` flag | `docker run -v sqldata-persistent:/var/opt/mssql` |
| CI/CD stops & removes SQL | Manual control, SQL never stopped |
| Data lost on every deploy | Data persists forever |

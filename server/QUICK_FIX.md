# Quick Fix Guide for Azure VM

## 🚨 Current Issue
Database connection failing with:
- `Login failed for user 'sa'`
- `Cannot open database "RideSharingDb"`
- `The ConnectionString property has not been initialized`

## ✅ Solution Applied

### Files Changed:
1. **appsettings.Production.json** - Changed `localhost` → `vanyatra-sql`
2. **docker-compose.yml** - Created proper container orchestration
3. **deploy.sh** - Full deployment automation
4. **fix-database.sh** - Quick database fix script

## 📋 Immediate Steps on Azure VM

### Option 1: Quick Fix (5 minutes)
If containers are already running, just fix the database:

```bash
# SSH into your VM
ssh akhileshallewar880@<your-vm-ip>

# Pull latest code
cd ~/vanyatra_rural_ride_booking
git pull origin main

# Run the quick fix
cd server
./fix-database.sh
```

### Option 2: Full Redeployment (10 minutes)
Complete rebuild and deployment:

```bash
# SSH into your VM
ssh akhileshallewar880@<your-vm-ip>

# Pull latest code
cd ~/vanyatra_rural_ride_booking
git pull origin main

# Run full deployment
cd server
./deploy.sh
```

### Option 3: Manual Fix
If scripts don't work:

```bash
# 1. Stop containers
docker stop vanyatra-server vanyatra-sql

# 2. Remove containers
docker rm vanyatra-server vanyatra-sql

# 3. Pull code
cd ~/vanyatra_rural_ride_booking
git pull origin main

# 4. Start with docker-compose
cd server
docker-compose up -d

# 5. Create database
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "CREATE DATABASE RideSharingDb"

# 6. Restart API
docker restart vanyatra-server
```

## 🔍 Verify It's Working

```bash
# Check containers are running
docker ps

# Check logs
docker logs -f vanyatra-server

# Test API
curl http://localhost:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9595959595"}'
```

Expected response (200 OK):
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otpId": "...",
    "expiresIn": 300,
    "isExistingUser": true
  }
}
```

## 🐛 Still Not Working?

### Check SQL Server
```bash
# Is SQL Server running?
docker ps | grep vanyatra-sql

# Can we connect?
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -Q "SELECT @@VERSION"

# Does database exist?
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases"
```

### Check Application
```bash
# View last 50 log lines
docker logs --tail=50 vanyatra-server

# Check environment
docker exec vanyatra-server printenv | grep ConnectionStrings

# Restart application
docker restart vanyatra-server
```

### Check Network
```bash
# Can API reach SQL Server?
docker exec vanyatra-server ping -c 3 vanyatra-sql

# Check network
docker network ls
docker network inspect server_vanyatra-network
```

## 📞 Common Error Messages

### "Login failed for user 'sa'"
**Cause**: Wrong password or SQL Server not ready  
**Fix**: 
```bash
# Verify password in docker-compose.yml matches appsettings.json
docker restart vanyatra-sql
sleep 10
docker restart vanyatra-server
```

### "Cannot open database 'RideSharingDb'"
**Cause**: Database doesn't exist  
**Fix**:
```bash
./fix-database.sh
```

### "The ConnectionString property has not been initialized"
**Cause**: Connection string not loaded from config  
**Fix**: Verify appsettings.Production.json has correct server name:
```bash
docker exec vanyatra-server cat /app/appsettings.Production.json | grep Server
# Should show: "Server=vanyatra-sql,1433"
```

### "Could not connect to vanyatra-sql"
**Cause**: Containers not on same network  
**Fix**:
```bash
docker-compose down
docker-compose up -d
```

## 🎯 What Changed?

### Before:
```json
"Server=localhost,1433;..."  ❌ Wrong for Docker
```

### After:
```json
"Server=vanyatra-sql,1433;..."  ✓ Correct container name
```

## 📚 Full Documentation

See [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) for complete guide.

## ⚡ TL;DR

```bash
# On Azure VM:
cd ~/vanyatra_rural_ride_booking
git pull
cd server
./fix-database.sh
```

Done! 🎉

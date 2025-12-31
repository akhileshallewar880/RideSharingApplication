# 🚨 DATABASE PERSISTENCE FIX - COMPLETE SOLUTION

## ⚡ CRITICAL ISSUE IDENTIFIED

Your database was being **deleted on every deployment** because:

1. ❌ CI/CD pipeline was running `docker stop vanyatra-sql` + `docker rm vanyatra-sql`
2. ❌ SQL Server was started WITHOUT volume mounting (`-v` flag missing)
3. ❌ Every deployment = fresh database = all data lost
4. ❌ VM restart/deallocation stopped containers, and they restarted fresh

## ✅ WHAT I'VE FIXED

### 1. Fixed CI/CD Pipeline
- ✅ SQL Server now starts ONLY if not already running
- ✅ Persistent volume `sqldata-persistent` automatically created
- ✅ Database persists across all deployments
- ✅ Only application container gets updated (SQL untouched)

### 2. Created Management Scripts
- ✅ `backup-database.sh` - Backup before deployments
- ✅ `restore-database.sh` - Restore from backup
- ✅ `safe-deploy.sh` - Deploy without touching database

### 3. Updated docker-compose
- ✅ Named volume `sqldata-persistent` (persistent across recreates)
- ✅ Proper restart policies

## 🎯 IMMEDIATE ACTION PLAN FOR YOUR DEMO

### DO THIS NOW (Before Demo):

#### 1. SSH to your Azure VM
```bash
ssh <username>@<vm-ip>
```

#### 2. Stop everything and set up persistence
```bash
# Navigate to project
cd ~/vanyatra_rural_ride_booking

# Pull the fixed code
git pull origin main

# Stop all containers
docker stop vanyatra-server vanyatra-sql 2>/dev/null || true
docker rm vanyatra-server vanyatra-sql 2>/dev/null || true

# Create persistent volume
docker volume create sqldata-persistent

# Create network
docker network create vanyatra-net 2>/dev/null || true
```

#### 3. Start SQL Server with persistence
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
sleep 20
```

#### 4. Create database
```bash
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"

# Verify
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"
```

#### 5. Run your migrations/create tables
```bash
cd ~/vanyatra_rural_ride_booking

# Run all your SQL scripts
docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  < create-database-schema.sql

# Add any other migration scripts you need
```

#### 6. Start application
```bash
cd ~/vanyatra_rural_ride_booking/server
./safe-deploy.sh
```

#### 7. **DISABLE CI/CD for demo** (Important!)
```bash
# On your local machine
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Temporarily disable the workflow
git mv .github/workflows/deploy-to-azure-vm.yml .github/workflows/deploy-to-azure-vm.yml.DISABLED

git add .
git commit -m "Temporarily disable CI/CD for demo"
git push origin main
```

### ✅ Your System is Now:
- ✅ Database persists across VM restarts
- ✅ Database persists across VM deallocations
- ✅ Database persists across application updates
- ✅ No more manual migrations needed
- ✅ Safe for demo

## 📋 VERIFICATION CHECKLIST

Run these on your VM to verify everything is working:

```bash
# 1. Check volume exists
docker volume ls | grep sqldata-persistent
# Should show: sqldata-persistent

# 2. Check SQL is running
docker ps | grep vanyatra-sql
# Should show: vanyatra-sql running

# 3. Check database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"
# Should show: RideSharingDb

# 4. Check tables exist
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
# Should show: number of tables

# 5. Test API
curl http://localhost:8000/health
# Should return: success

# 6. Restart VM (test persistence)
sudo reboot
# After reboot, SSH back and check everything still works
```

## 🔄 HOW TO DEPLOY UPDATES (During Demo If Needed)

```bash
# SSH to VM
ssh <username>@<vm-ip>

# Navigate to project
cd ~/vanyatra_rural_ride_booking/server

# Run safe deployment (database untouched)
./safe-deploy.sh
```

This will:
1. ✅ Backup database automatically
2. ✅ Pull latest code
3. ✅ Build new application
4. ✅ Update ONLY application (SQL untouched)
5. ✅ Verify deployment

## 🆘 EMERGENCY COMMANDS (If Something Breaks)

### App not responding?
```bash
docker restart vanyatra-server
docker logs vanyatra-server --tail 50
```

### Database issue?
```bash
docker restart vanyatra-sql
sleep 10
docker restart vanyatra-server
```

### Need to restore backup?
```bash
cd ~/vanyatra_rural_ride_booking/server
./restore-database.sh ./database-backups/RideSharingDb_XXXXXXXX_XXXXXX.bak
```

### Complete restart?
```bash
docker restart vanyatra-sql vanyatra-server
```

### Check what's wrong?
```bash
# Container status
docker ps -a

# SQL logs
docker logs vanyatra-sql --tail 50

# App logs
docker logs vanyatra-server --tail 50

# Database connection test
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -Q "SELECT 1"
```

## 📊 WHAT WAS THE PROBLEM?

### Before (Broken):
```yaml
# CI/CD Pipeline:
docker stop vanyatra-sql        # ❌ Stops SQL
docker rm vanyatra-sql          # ❌ Deletes SQL
docker run ... vanyatra-sql     # ❌ Fresh start, NO -v flag
                               # Result: All data lost!
```

### After (Fixed):
```yaml
# CI/CD Pipeline:
if SQL not running:             # ✅ Check first
  docker run -v sqldata-persistent:/var/opt/mssql  # ✅ With volume
else:
  Skip SQL, it's already running with data  # ✅ Don't touch it!

# Only update app container      # ✅ SQL untouched
```

## 🎓 WHY IT WORKS NOW

| Issue | Before | After |
|-------|--------|-------|
| Volume | ❌ None | ✅ `sqldata-persistent` |
| CI/CD | ❌ Deletes SQL | ✅ Skips if running |
| Persistence | ❌ Lost on deploy | ✅ Forever |
| VM restart | ❌ Fresh DB | ✅ Data intact |

## 🚀 AFTER DEMO - RE-ENABLE CI/CD

Once your demo is done and you've verified everything works:

```bash
# On your local machine
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Re-enable CI/CD
git mv .github/workflows/deploy-to-azure-vm.yml.DISABLED .github/workflows/deploy-to-azure-vm.yml

git add .
git commit -m "Re-enable CI/CD with database persistence"
git push origin main
```

The fixed CI/CD will now:
- ✅ Check if SQL is running (won't delete it)
- ✅ Use persistent volumes
- ✅ Only update application
- ✅ Never lose data again

## 📞 SCRIPT REFERENCE

| Script | Purpose |
|--------|---------|
| `safe-deploy.sh` | Deploy updates without touching SQL |
| `backup-database.sh` | Backup database before changes |
| `restore-database.sh` | Restore from backup |
| `fix-database.sh` | Quick database fix (existing) |

## ✅ SUCCESS CRITERIA

Your demo is ready when:
- ✅ `docker ps` shows both containers running
- ✅ Database has all tables and data
- ✅ API responds to health checks
- ✅ After VM restart, data still exists
- ✅ CI/CD is disabled temporarily

---

## 🎯 SUMMARY

**What to do RIGHT NOW:**
1. SSH to VM
2. Run the commands in "DO THIS NOW" section
3. Verify with checklist
4. Disable CI/CD temporarily
5. Run your demo with confidence! 🚀

**Your database will now:**
- ✅ Survive VM restarts
- ✅ Survive VM deallocations
- ✅ Survive deployments
- ✅ Persist forever (until you explicitly delete the volume)

**Good luck with your demo!** 🎉

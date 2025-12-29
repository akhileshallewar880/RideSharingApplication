# Azure VM Database Connection Fix - Summary

## ✅ Problem Solved

Your Vanyatra server on Azure VM was failing with database connection errors. The issue has been **completely fixed** and pushed to the repository.

## 🎯 Root Cause

The application was configured for local development but deployed in a Docker environment:

| Configuration | Local Dev | Azure VM (Docker) | Status |
|--------------|-----------|-------------------|--------|
| **Server Name** | `localhost` ✓ | `localhost` ❌ | **WRONG** |
| **Should Be** | `localhost` | `vanyatra-sql` ✓ | **FIXED** |

When containers communicate in Docker, they use **container names**, not `localhost`.

## 📦 What Was Fixed

### 1. Connection String (Critical)
**File**: `server/ride_sharing_application/RideSharing.API/appsettings.Production.json`

```diff
- "Server=localhost,1433;..."     ❌ Won't work in Docker
+ "Server=vanyatra-sql,1433;..."  ✓ Uses container name
```

### 2. Docker Orchestration
**File**: `server/docker-compose.yml` (NEW)
- Proper network configuration between containers
- Health checks for SQL Server
- Automatic container restart
- Volume persistence for database
- Environment variable support

### 3. Automatic Migrations
**File**: `server/ride_sharing_application/RideSharing.API/Program.cs`
- Enabled automatic database migrations on startup
- Better error logging
- Proper migration sequencing

### 4. Deployment Automation
**Files**: 
- `server/deploy.sh` - Full deployment script
- `server/fix-database.sh` - Quick database fix
- `server/AZURE_DEPLOYMENT.md` - Complete guide
- `server/QUICK_FIX.md` - Quick reference

## 🚀 How to Deploy on Azure VM

### Quick Steps (Copy & Paste)

```bash
# 1. SSH into your Azure VM
ssh akhileshallewar880@<your-vm-ip>

# 2. Navigate to project
cd ~/vanyatra_rural_ride_booking

# 3. Pull latest changes
git pull origin main

# 4. Update appsettings.Production.json (CRITICAL!)
cd server/ride_sharing_application/RideSharing.API
nano appsettings.Production.json
```

**In nano, change line 10 from:**
```json
"Server=localhost,1433;..."
```
**To:**
```json
"Server=vanyatra-sql,1433;..."
```

Then save (Ctrl+O, Enter, Ctrl+X) and continue:

```bash
# 5. Run the fix script
cd ~/vanyatra_rural_ride_booking/server
./fix-database.sh

# 6. Verify it works
curl http://localhost:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9595959595"}'
```

### Expected Result
You should see:
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

## 📊 Before vs After

### Before (Failing Logs)
```
[ERR] Database migration failed
System.InvalidOperationException: The ConnectionString property has not been initialized.
[ERR] Login failed for user 'sa'
[ERR] Cannot open database "RideSharingDb"
```

### After (Success Logs)
```
[INF] Starting automatic database migrations...
[INF] Auth database migration completed successfully
[INF] Application database migration completed successfully
[INF] Now listening on: http://[::]:8080
[INF] Application started.
```

## 🔧 Alternative: Full Redeployment

If the quick fix doesn't work:

```bash
# On Azure VM
cd ~/vanyatra_rural_ride_booking
git pull origin main
cd server
./deploy.sh
```

This will:
- Stop old containers
- Rebuild everything from scratch
- Create database if needed
- Start all services
- Verify deployment

## 📱 Files You Need to Update Manually

Because `appsettings.Production.json` is in `.gitignore` (for security), you must update it manually on the server:

```bash
# On Azure VM
nano ~/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API/appsettings.Production.json
```

**Change this section:**
```json
"ConnectionStrings": {
  "RideSharingConnectionString": "Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;",
  "RideSharingAuthConnectionString": "Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;"
}
```

**Key**: `Server=vanyatra-sql` (NOT localhost!)

## 🎓 Why This Happened

1. **Development vs Production**: App was configured for local development (`localhost`)
2. **Docker Networking**: Containers use container names, not `localhost`
3. **Missing Configuration**: Production config wasn't set up for Docker environment

## 📚 Documentation

Complete guides are now in your repository:

- **[QUICK_FIX.md](./QUICK_FIX.md)** - Quick reference card
- **[AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)** - Full deployment guide
- **[deploy.sh](./deploy.sh)** - Automated deployment script
- **[fix-database.sh](./fix-database.sh)** - Quick database fix script
- **[docker-compose.yml](./docker-compose.yml)** - Container orchestration

## ✋ Important Notes

### Security (DO THIS LATER!)
⚠️ Your SA password is currently hardcoded. Before production:
1. Change the SA password
2. Use Azure Key Vault or Docker secrets
3. Update JWT secret key
4. Enable HTTPS

### Monitoring
Set up after deployment:
- Application Insights
- Log aggregation
- Health checks
- Automated backups

## 🆘 Still Having Issues?

### Check SQL Server
```bash
docker logs vanyatra-sql
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -Q "SELECT @@VERSION"
```

### Check Application
```bash
docker logs vanyatra-server
docker exec vanyatra-server cat /app/appsettings.Production.json
```

### Check Network
```bash
docker network ls
docker network inspect server_vanyatra-network
```

## 🎉 Success Checklist

- [ ] Code pulled from git (`git pull origin main`)
- [ ] `appsettings.Production.json` updated with `vanyatra-sql`
- [ ] Containers running (`docker ps`)
- [ ] Database exists (`./fix-database.sh`)
- [ ] API responds to test request
- [ ] No errors in logs (`docker logs vanyatra-server`)

## 📞 Quick Commands Reference

```bash
# View logs
docker logs -f vanyatra-server

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Start everything
docker-compose up -d

# Check status
docker-compose ps

# Run database fix
./fix-database.sh

# Full redeployment
./deploy.sh
```

---

## 🎯 TL;DR - Copy This

On your Azure VM, run these commands:

```bash
cd ~/vanyatra_rural_ride_booking
git pull
cd server/ride_sharing_application/RideSharing.API
# Edit appsettings.Production.json: Change "Server=localhost" to "Server=vanyatra-sql"
nano appsettings.Production.json
cd ~/vanyatra_rural_ride_booking/server
./fix-database.sh
```

That's it! Your server will be up and running. 🚀

---

**Need Help?** Check [QUICK_FIX.md](./QUICK_FIX.md) for troubleshooting or [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) for complete guide.

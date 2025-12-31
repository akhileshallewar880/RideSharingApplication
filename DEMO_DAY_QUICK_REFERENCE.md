# 🚨 DEMO DAY QUICK REFERENCE

## ⚡ 3-MINUTE SETUP (Do this NOW on Azure VM)

```bash
# 1. SSH to VM
ssh <username>@<vm-ip>

# 2. Pull fixes
cd ~/vanyatra_rural_ride_booking && git pull

# 3. Setup persistence (COPY AND PASTE THIS ENTIRE BLOCK)
docker stop vanyatra-server vanyatra-sql 2>/dev/null || true
docker rm vanyatra-server vanyatra-sql 2>/dev/null || true
docker volume create sqldata-persistent
docker network create vanyatra-net 2>/dev/null || true

docker run -d --name vanyatra-sql --network vanyatra-net \
  -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Akhilesh@22" -p 1433:1433 \
  -v sqldata-persistent:/var/opt/mssql --restart unless-stopped \
  mcr.microsoft.com/azure-sql-edge:latest

sleep 20

docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RideSharingDb') CREATE DATABASE RideSharingDb"

# 4. Run your migrations
cd ~/vanyatra_rural_ride_booking
docker exec -i vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  < create-database-schema.sql
# (Run other migrations as needed)

# 5. Deploy app
cd ~/vanyatra_rural_ride_booking/server
./safe-deploy.sh

# 6. Verify
curl http://localhost:8000/health
docker ps
```

## ✅ VERIFICATION (30 seconds)

```bash
# All should return success:
docker ps | grep vanyatra-sql        # Should be running
docker ps | grep vanyatra-server     # Should be running
docker volume ls | grep sqldata-persistent  # Should exist
curl http://localhost:8000/health    # Should respond
```

## 🆘 EMERGENCY FIXES

### App crash during demo?
```bash
docker restart vanyatra-server
# Wait 10 seconds, try again
```

### Database not responding?
```bash
docker restart vanyatra-sql
sleep 15
docker restart vanyatra-server
```

### 500 Error?
```bash
docker logs vanyatra-server --tail 20
# Check connection string in logs
```

### Complete reset?
```bash
docker restart vanyatra-sql vanyatra-server
sleep 10
curl http://localhost:8000/health
```

## 🎯 WHAT'S FIXED

✅ Database persists across:
- VM restarts
- VM deallocations  
- Application updates
- Container restarts

✅ No more manual migrations needed (unless schema changes)

## 📱 DEMO DAY CONTACTS

**If something breaks:**
1. Run emergency fix above
2. Check logs: `docker logs vanyatra-server --tail 50`
3. Restart services: `docker restart vanyatra-sql vanyatra-server`

---

**You're ready! Good luck! 🚀**

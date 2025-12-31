# 🚀 VM Auto-Start Configuration Guide

## 🐛 Problem
After restarting the Azure VM, the VanYatra application doesn't start automatically, resulting in 500 Internal Server Errors for all APIs.

## ✅ Solution
Configure systemd service to automatically start Docker Compose on VM boot.

---

## 📋 Prerequisites Check

### 1. Verify Docker is Enabled
```bash
# Check if Docker starts on boot
sudo systemctl is-enabled docker

# If not enabled, enable it
sudo systemctl enable docker
```

### 2. Verify Docker Compose Configuration
Your `docker-compose.yml` already has `restart: unless-stopped` which is correct ✅

---

## 🔧 Setup Auto-Start Service

### Step 1: Create Systemd Service File

SSH into your VM:
```bash
ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172
```

Create the service file:
```bash
sudo nano /etc/systemd/system/vanyatra.service
```

### Step 2: Add Service Configuration

Paste the following content (adjust the path if needed):

```ini
[Unit]
Description=VanYatra Ride Sharing Application
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/akhileshallewar880/vanyatra_rural_ride_booking/server
ExecStartPre=/usr/bin/docker network create vanyatra-network || true
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
ExecReload=/usr/bin/docker-compose restart
StandardOutput=journal
StandardError=journal
User=akhileshallewar880
Group=akhileshallewar880

[Install]
WantedBy=multi-user.target
```

**Important**: If your project is in a different location, update the `WorkingDirectory` path!

### Step 3: Set Correct Permissions
```bash
sudo chmod 644 /etc/systemd/system/vanyatra.service
```

### Step 4: Reload Systemd and Enable Service
```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable vanyatra.service

# Start the service now
sudo systemctl start vanyatra.service

# Check status
sudo systemctl status vanyatra.service
```

**Expected Output**:
```
● vanyatra.service - VanYatra Ride Sharing Application
     Loaded: loaded (/etc/systemd/system/vanyatra.service; enabled; vendor preset: enabled)
     Active: active (exited) since ...
```

---

## 🧪 Test Auto-Start

### Test 1: Verify Containers are Running
```bash
docker ps
```

**Expected Output**:
```
CONTAINER ID   IMAGE                    STATUS         PORTS                    NAMES
xxxxxxxxxx     vanyatra-server:latest   Up X minutes   0.0.0.0:8000->8080/tcp   vanyatra-server
yyyyyyyyyy     azure-sql-edge:latest    Up X minutes   0.0.0.0:1433->1433/tcp   vanyatra-sql
```

### Test 2: Test API Endpoint
```bash
curl http://localhost:8000/api/v1/health
# or
curl http://localhost:8000/api/v1/admin/health
```

### Test 3: Simulate VM Restart
```bash
# Reboot the VM
sudo reboot
```

Wait 2-3 minutes, then SSH back in and check:
```bash
# Check service status
sudo systemctl status vanyatra.service

# Check containers
docker ps

# Check logs
sudo journalctl -u vanyatra.service -f
```

---

## 🔍 Troubleshooting

### Issue: Service fails to start

**Check logs:**
```bash
sudo journalctl -u vanyatra.service -xe
```

**Common fixes:**

1. **Docker not running:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

2. **Wrong working directory:**
```bash
# Find your project location
find /home -name "docker-compose.yml" 2>/dev/null

# Update WorkingDirectory in service file
sudo nano /etc/systemd/system/vanyatra.service
sudo systemctl daemon-reload
sudo systemctl restart vanyatra.service
```

3. **Permission issues:**
```bash
# Ensure user has docker permissions
sudo usermod -aG docker akhileshallewar880
newgrp docker

# Restart service
sudo systemctl restart vanyatra.service
```

### Issue: Containers start but API returns 500 errors

**Check container logs:**
```bash
# Check API logs
docker logs vanyatra-server --tail=100

# Check SQL Server logs
docker logs vanyatra-sql --tail=50
```

**Common issues:**

1. **Database not ready:**
```bash
# The docker-compose already has health checks, but if needed:
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -Q "SELECT @@VERSION"
```

2. **Database doesn't exist:**
```bash
# Check if database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases WHERE name='RideSharingDb'"

# If not found, run migrations
docker exec vanyatra-server dotnet ef database update
```

3. **Environment variables issue:**
```bash
# Check environment in container
docker exec vanyatra-server printenv | grep ConnectionStrings

# Should show:
# ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;...
```

### Issue: Nginx not serving web apps

**Check Nginx status:**
```bash
sudo systemctl status nginx

# If not running:
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Test Nginx config:**
```bash
sudo nginx -t
```

---

## 🎯 Verify Everything Works

### Full System Check
```bash
# 1. Check service
sudo systemctl status vanyatra.service

# 2. Check containers
docker ps

# 3. Check Docker Compose status
cd /home/akhileshallewar880/vanyatra_rural_ride_booking/server
docker-compose ps

# 4. Check API health
curl http://localhost:8000/api/v1/admin/health

# 5. Check from outside VM
# From your local machine:
curl http://57.159.31.172:8000/api/v1/admin/health

# 6. Check web apps
curl http://57.159.31.172
```

---

## 📝 Useful Management Commands

### Start/Stop/Restart Service
```bash
# Start
sudo systemctl start vanyatra.service

# Stop
sudo systemctl stop vanyatra.service

# Restart
sudo systemctl restart vanyatra.service

# Status
sudo systemctl status vanyatra.service

# View logs
sudo journalctl -u vanyatra.service -f
```

### Manual Docker Compose Commands
```bash
cd /home/akhileshallewar880/vanyatra_rural_ride_booking/server

# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart vanyatra-server

# Rebuild and restart
docker-compose up -d --build vanyatra-server
```

### Container Management
```bash
# View container logs
docker logs vanyatra-server -f
docker logs vanyatra-sql -f

# Execute command in container
docker exec -it vanyatra-server bash
docker exec -it vanyatra-sql bash

# Restart container
docker restart vanyatra-server
docker restart vanyatra-sql

# Check container resource usage
docker stats
```

---

## 🔒 Security Best Practices

### 1. Secure the Service File
Your service file should NOT contain passwords. Currently, passwords are in `docker-compose.yml` which is acceptable if properly secured.

**Secure docker-compose.yml:**
```bash
cd /home/akhileshallewar880/vanyatra_rural_ride_booking/server
chmod 600 docker-compose.yml
```

### 2. Use Environment File (Optional)
Create `.env` file for sensitive data:
```bash
nano .env
```

Add:
```env
SA_PASSWORD=Akhilesh@22
JWT_SECRET=kjsdfhiosdfihAkjdfAdfh823knhf323kjnfHAnnsf023lsdfh
```

Update `docker-compose.yml` to reference:
```yaml
environment:
  - SA_PASSWORD=${SA_PASSWORD}
```

### 3. Secure permissions:
```bash
chmod 600 .env
```

---

## 📊 Monitoring After Restart

### Check Startup Time
```bash
# View service startup logs
sudo journalctl -u vanyatra.service -b

# View Docker daemon logs
sudo journalctl -u docker -b
```

### Monitor Resource Usage
```bash
# Overall system
top

# Docker specific
docker stats

# Disk usage
df -h
docker system df
```

---

## ✅ Success Checklist

After following this guide, verify:

- [ ] Docker service is enabled: `sudo systemctl is-enabled docker` → `enabled`
- [ ] VanYatra service is enabled: `sudo systemctl is-enabled vanyatra.service` → `enabled`
- [ ] VanYatra service is active: `sudo systemctl status vanyatra.service` → `active`
- [ ] Containers are running: `docker ps` shows both containers
- [ ] API responds: `curl http://localhost:8000/api/v1/admin/health` → 200 OK
- [ ] Nginx is running: `sudo systemctl status nginx` → `active`
- [ ] After reboot, everything starts automatically (test with `sudo reboot`)

---

## 🆘 Still Having Issues?

If you've followed all steps and still experiencing problems:

1. **Collect diagnostic info:**
```bash
# Save this output
{
  echo "=== SYSTEM INFO ==="
  uname -a
  uptime
  
  echo -e "\n=== DOCKER INFO ==="
  docker --version
  docker-compose --version
  sudo systemctl status docker
  
  echo -e "\n=== VANYATRA SERVICE ==="
  sudo systemctl status vanyatra.service
  
  echo -e "\n=== CONTAINERS ==="
  docker ps -a
  
  echo -e "\n=== SERVICE LOGS ==="
  sudo journalctl -u vanyatra.service --no-pager -n 50
  
  echo -e "\n=== CONTAINER LOGS ==="
  docker logs vanyatra-server --tail=50
  docker logs vanyatra-sql --tail=30
  
  echo -e "\n=== NETWORK ==="
  docker network ls
  
  echo -e "\n=== DISK SPACE ==="
  df -h
  docker system df
} > ~/vanyatra-diagnostic.txt

# Share the diagnostic file
cat ~/vanyatra-diagnostic.txt
```

2. **Quick recovery commands:**
```bash
# Nuclear option - restart everything
sudo systemctl restart docker
sudo systemctl restart vanyatra.service
sudo systemctl restart nginx

# Wait 30 seconds then test
sleep 30
curl http://localhost:8000/api/v1/admin/health
```

---

## 📚 Related Documentation

- [DEPLOYMENT_COMPLETE.md](./DEPLOYMENT_COMPLETE.md) - Full deployment guide
- [server/AZURE_DEPLOYMENT.md](./server/AZURE_DEPLOYMENT.md) - Azure-specific setup
- [server/docker-compose.yml](./server/docker-compose.yml) - Container configuration
- [ADMIN_QUICK_START.md](./ADMIN_QUICK_START.md) - Admin dashboard setup

---

**Last Updated**: December 31, 2025

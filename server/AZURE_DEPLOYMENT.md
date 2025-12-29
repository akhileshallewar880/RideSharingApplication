# Azure VM Deployment Guide

## Problem Fixed

The application was failing with `Login failed for user 'sa'` and `Cannot open database "RideSharingDb"` errors because:

1. **Wrong Server Name**: `appsettings.Production.json` was using `localhost` instead of `vanyatra-sql` (the Docker container name)
2. **Missing Database**: The database wasn't being created automatically
3. **Connection String Not Initialized**: Environment variables weren't being used properly

## Changes Made

### 1. Updated `appsettings.Production.json`
Changed connection string from `localhost` to `vanyatra-sql`:
```json
"ConnectionStrings": {
  "RideSharingConnectionString": "Server=vanyatra-sql,1433;...",
  "RideSharingAuthConnectionString": "Server=vanyatra-sql,1433;..."
}
```

### 2. Created `docker-compose.yml`
Properly orchestrates both SQL Server and API containers with:
- Health checks for SQL Server
- Proper networking between containers
- Volume persistence for database
- Automatic restart policies

### 3. Created `deploy.sh`
Automated deployment script that:
- Stops old containers
- Rebuilds the application
- Starts services
- Creates database if it doesn't exist
- Verifies deployment

## Deployment Steps for Azure VM

### Prerequisites
- Docker installed
- Docker Compose installed
- Git installed

### Step 0: Update Production Configuration
The `appsettings.Production.json` file is gitignored for security. You need to update it on the server:

```bash
# SSH into VM
ssh akhileshallewar880@<your-vm-ip>

# Navigate to project
cd ~/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API

# Copy template if needed
cp appsettings.Production.json.template appsettings.Production.json

# Edit the file - IMPORTANT: Change Server from 'localhost' to 'vanyatra-sql'
nano appsettings.Production.json
```

Make sure the connection strings look like this:
```json
"ConnectionStrings": {
  "RideSharingConnectionString": "Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;",
  "RideSharingAuthConnectionString": "Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;"
}
```

**Key Point**: The server MUST be `vanyatra-sql` (not `localhost`) for Docker networking to work!

### Step 1: SSH into Azure VM
```bash
ssh akhileshallewar880@vanyatraVm
```

### Step 2: Navigate to Project Directory
```bash
cd ~/vanyatra_rural_ride_booking/server
```

### Step 3: Pull Latest Changes
```bash
git pull origin main
```

### Step 4: Run Deployment Script
```bash
./deploy.sh
```

The script will:
- Stop existing containers
- Build new Docker images
- Start SQL Server and API containers
- Create the database if needed
- Show deployment status

### Step 5: Verify Deployment
```bash
# Check containers are running
docker ps

# Check application logs
docker logs -f vanyatra-server

# Test API endpoint
curl http://localhost:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9595959595"}'
```

## Manual Deployment (Alternative)

If you prefer manual control:

```bash
# Stop existing containers
docker-compose down

# Build and start services
docker-compose up -d --build

# Check logs
docker-compose logs -f

# Create database manually (if needed)
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "CREATE DATABASE RideSharingDb"
```

## Troubleshooting

### Issue: SQL Server won't start
```bash
# Check SQL Server logs
docker logs vanyatra-sql

# Restart SQL Server
docker restart vanyatra-sql
```

### Issue: Database connection errors
```bash
# Test SQL Server connection
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT @@VERSION"

# Check if database exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "SELECT name FROM sys.databases"
```

### Issue: Application won't start
```bash
# Check application logs
docker logs vanyatra-server

# Restart application
docker restart vanyatra-server

# Rebuild application
docker-compose build --no-cache vanyatra-server
docker-compose up -d vanyatra-server
```

### Issue: Port already in use
```bash
# Find process using port 8000
sudo lsof -i :8000

# Kill the process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
```

## Environment Variables

The application uses these environment variables (configured in docker-compose.yml):

- `ASPNETCORE_ENVIRONMENT=Production`
- `ASPNETCORE_URLS=http://+:8080`
- `ConnectionStrings__RideSharingConnectionString`
- `ConnectionStrings__RideSharingAuthConnectionString`

You can override them by creating a `.env` file:

```bash
# .env file
ASPNETCORE_ENVIRONMENT=Production
SA_PASSWORD=YourStrongPassword
```

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Rebuild specific service
docker-compose build vanyatra-server
docker-compose up -d vanyatra-server

# Check service health
docker-compose ps

# Execute command in container
docker exec -it vanyatra-server bash

# Access SQL Server
docker exec -it vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22"
```

## Port Configuration

- **SQL Server**: Port 1433 (exposed to host)
- **API**: Port 8080 (container) → Port 8000 (host)

Access the API at: `http://<your-vm-ip>:8000`

## Database Backup

```bash
# Backup database
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" \
  -Q "BACKUP DATABASE RideSharingDb TO DISK = '/var/opt/mssql/backup/RideSharingDb.bak'"

# Copy backup from container
docker cp vanyatra-sql:/var/opt/mssql/backup/RideSharingDb.bak ./backup/
```

## Security Recommendations

⚠️ **Important**: Before deploying to production:

1. **Change SA Password**: Update the password in both `appsettings.Production.json` and `docker-compose.yml`
2. **Use Secrets**: Store sensitive data in Azure Key Vault or Docker secrets
3. **Enable HTTPS**: Configure SSL certificates
4. **Firewall Rules**: Restrict access to necessary ports only
5. **Update JWT Secret**: Change the JWT secret key in `appsettings.Production.json`

## Next Steps

After successful deployment:

1. Test all API endpoints
2. Set up monitoring and logging
3. Configure automated backups
4. Set up CI/CD pipeline
5. Enable application insights

## Support

If you encounter issues:
1. Check logs: `docker-compose logs -f`
2. Verify network: `docker network inspect server_vanyatra-network`
3. Check container health: `docker-compose ps`
4. Review this guide's troubleshooting section

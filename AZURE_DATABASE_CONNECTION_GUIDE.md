# Azure SQL Database Connection Guide

## ✅ Issue #1: Admin Login - **RESOLVED**

Admin user created successfully:
- **Email**: `admin@vanyatra.com`
- **Password**: `Admin@123`
- **Status**: ✅ Login working, JWT token generated
- **Permissions**: Full admin access (all permissions)

---

## 🔧 Issue #2: Azure SQL Database Connection

### Current Configuration
The application uses environment variables for database connections:
- `ConnectionStrings__RideSharingConnectionString` - Main database
- `ConnectionStrings__RideSharingAuthConnectionString` - Auth database

Current values (local SQL Server):
```bash
Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;
```

### Azure SQL Database Connection String Format

For Azure SQL Database, use this format:
```
Server=tcp:<your-server>.database.windows.net,1433;
Database=<your-database>;
User Id=<your-username>;
Password=<your-password>;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
```

### Steps to Connect to Azure SQL Database

#### Option 1: Using Server Name and Credentials

1. **Get your Azure SQL connection details:**
   - Server name: `<your-server>.database.windows.net`
   - Database name: (e.g., `RideSharingDb`)
   - Username: (SQL authentication user)
   - Password: (SQL authentication password)

2. **Update Docker container environment variables:**

```bash
# Stop the current container
docker stop vanyatra-server
docker rm vanyatra-server

# Run with Azure connection strings
docker run -d \
  --name vanyatra-server \
  --network vanyatra-network \
  -p 8000:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_HTTP_PORTS=8080 \
  -e "ConnectionStrings__RideSharingConnectionString=Server=tcp:<your-server>.database.windows.net,1433;Database=<your-database>;User Id=<your-username>;Password=<your-password>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=Server=tcp:<your-server>.database.windows.net,1433;Database=<your-database>;User Id=<your-username>;Password=<your-password>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
  -e "JWT__Key=ThisIsAVerySecureKeyForJWTTokenGenerationWithAtLeast32Characters" \
  -e "JWT__Issuer=localhost:7219/" \
  -e "JWT__Audience=localhost:7219/" \
  -e "JWT__ExpiryInMinutes=180" \
  vanyatra-server:latest
```

#### Option 2: Using Full Connection String

If you have a complete connection string from Azure Portal:

```bash
docker run -d \
  --name vanyatra-server \
  --network vanyatra-network \
  -p 8000:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_HTTP_PORTS=8080 \
  -e "ConnectionStrings__RideSharingConnectionString=<your-full-connection-string>" \
  -e "ConnectionStrings__RideSharingAuthConnectionString=<your-full-connection-string>" \
  -e "JWT__Key=ThisIsAVerySecureKeyForJWTTokenGenerationWithAtLeast32Characters" \
  -e "JWT__Issuer=localhost:7219/" \
  -e "JWT__Audience=localhost:7219/" \
  -e "JWT__ExpiryInMinutes=180" \
  vanyatra-server:latest
```

### Testing Azure Connection

After updating the container:

1. **Check container logs:**
```bash
docker logs vanyatra-server --tail 50
```

2. **Test an API endpoint:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9876543210","countryCode":"+91"}'
```

3. **Test admin login:**
```bash
curl -X POST http://localhost:8000/api/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@vanyatra.com","password":"Admin@123"}'
```

### Troubleshooting Azure Connection

#### Common Issues:

1. **Firewall Rules**: Ensure Azure SQL firewall allows your server IP
   - Go to Azure Portal → SQL Server → Networking
   - Add your server's public IP address

2. **Authentication Failed**: Verify credentials
   ```bash
   # Test connection with sqlcmd (if available)
   sqlcmd -S <your-server>.database.windows.net -d <database> -U <username> -P <password>
   ```

3. **Timeout Errors**: Check network connectivity
   ```bash
   # Test if port 1433 is reachable
   nc -zv <your-server>.database.windows.net 1433
   ```

4. **SSL/TLS Errors**: Ensure `Encrypt=True` and `TrustServerCertificate=False` in connection string

### Dual Configuration (Local + Azure)

To support both local and Azure databases:

1. **Use Docker Compose** with profiles:
```yaml
version: '3.8'
services:
  vanyatra-server-local:
    image: vanyatra-server:latest
    environment:
      - ConnectionStrings__RideSharingConnectionString=Server=vanyatra-sql,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;
    profiles: ["local"]
    
  vanyatra-server-azure:
    image: vanyatra-server:latest
    environment:
      - ConnectionStrings__RideSharingConnectionString=Server=tcp:<azure-server>.database.windows.net,1433;Database=<database>;User Id=<username>;Password=<password>;Encrypt=True;
    profiles: ["azure"]
```

2. **Switch between environments:**
```bash
# Use local database
docker-compose --profile local up -d

# Use Azure database
docker-compose --profile azure up -d
```

---

## What Information Do You Need?

To help you connect to Azure SQL Database, please provide:

1. **Azure SQL Server name**: `______.database.windows.net`
2. **Database name**: `______`
3. **Username**: `______`
4. **Password**: `______`

Or:

- **Complete connection string** from Azure Portal

Once you provide these details, I'll update the Docker container configuration for you.

---

## Current Status

✅ **Admin Login**: Working  
✅ **Local Database**: Connected  
⏳ **Azure Database**: Waiting for connection details

# Quick Fix: Apply Database Migration to Azure SQL

## The Problem
You're trying to connect to localhost SQL Server which doesn't exist on your machine.

## The Solution
Run the generated SQL script directly in Azure SQL Server (no local SQL Server needed).

---

## ✅ Step-by-Step Instructions

### Step 1: Create Azure SQL Server & Database (5 minutes)

Open a **new terminal** and run these commands:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "217ecefe-913a-435c-8e32-b806fa2b0381"

# Create SQL Server
az sql server create \
  --name vanyatra-server \
  --resource-group vayatra-app-service_group \
  --location centralindia \
  --admin-user sqladmin \
  --admin-password "Vanyatra@2026!"

# Allow Azure services to access the server
az sql server firewall-rule create \
  --resource-group vayatra-app-service_group \
  --server vanyatra-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create Database (Basic tier - cheapest option ~$5/month)
az sql db create \
  --resource-group vayatra-app-service_group \
  --server vanyatra-server \
  --name RideSharingDb \
  --service-objective Basic
```

**Save these credentials:**
- Server: `vanyatra-server.database.windows.net`
- Database: `RideSharingDb`
- Username: `sqladmin`
- Password: `Vanyatra@2026!`

---

### Step 2: Run SQL Script in Azure Portal (2 minutes)

1. **Open Azure Portal**: https://portal.azure.com
2. **Navigate to**: SQL databases → RideSharingDb
3. **Click**: Query Editor (left menu)
4. **Login** with:
   - Username: `sqladmin`
   - Password: `Vanyatra@2026!`

5. **Open the migration script file**:
   ```
   /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API/migration-script.sql
   ```

6. **Copy ALL contents** from the file

7. **Paste** into Azure Query Editor

8. **Click "Run"** button

9. **Wait** for success message (should take 5-10 seconds)

---

### Step 3: Verify Tables Created (30 seconds)

In the same Query Editor, run this query:

```sql
-- Check if all tables were created
SELECT name FROM sys.tables ORDER BY name;
```

**Expected output (20 tables):**
- Banners
- Bookings
- Cities
- CouponUsages
- Coupons
- Drivers
- LocationTrackings
- Notifications
- OTPVerifications
- PasswordResetTokens
- Payments
- Payouts
- Ratings
- RefreshTokens
- Rides
- RouteSegments
- UserProfiles
- Users
- VehicleModels
- Vehicles

---

### Step 4: Update Azure App Service Configuration (2 minutes)

1. **Go to Azure Portal** → App Services → `vayatra-app-service`

2. **Click**: Configuration (Settings section in left menu)

3. **Under "Connection strings"**, add/update:

   **Connection String 1:**
   - Name: `RideSharingConnectionString`
   - Value: 
     ```
     Server=tcp:vanyatra-server.database.windows.net,1433;Database=RideSharingDb;User Id=sqladmin;Password=Vanyatra@2026!;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
     ```
   - Type: `SQLAzure`

   **Connection String 2:**
   - Name: `RideSharingAuthConnectionString`
   - Value: (same as above)
   - Type: `SQLAzure`

4. **Click "Save"** at the top

5. **Click "Continue"** when prompted (app will restart automatically)

---

### Step 5: Test Your API (1 minute)

Wait 30 seconds for app restart, then test:

```bash
# Test analytics endpoint
curl https://vayatra-app-service.azurewebsites.net/api/Admin/Dashboard/Analytics
```

**Expected**: Should return `200 OK` with analytics data (no more 500 errors!)

---

## Alternative: If You Want Local SQL Server (Optional)

If you prefer to test locally, install SQL Server on your Mac:

### Option A: Install SQL Server in Docker (Recommended)

```bash
# Pull SQL Server image
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 --name sqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest

# Apply migrations to local SQL Server
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API
dotnet ef database update --context RideSharingDbContext
```

### Option B: Install Azure SQL Edge (Apple Silicon Compatible)

```bash
# Pull Azure SQL Edge (works on M1/M2/M3 Macs)
docker pull mcr.microsoft.com/azure-sql-edge:latest

# Run Azure SQL Edge
docker run -e "ACCEPT_EULA=1" -e "MSSQL_SA_PASSWORD=Akhilesh@22" \
  -p 1433:1433 --name azuresqledge \
  -d mcr.microsoft.com/azure-sql-edge:latest

# Apply migrations
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API
dotnet ef database update --context RideSharingDbContext
```

---

## Summary

**Recommended Path** (No local SQL Server needed):
1. ✅ Create Azure SQL Server using Azure CLI commands
2. ✅ Run migration-script.sql in Azure Portal Query Editor
3. ✅ Update App Service connection strings
4. ✅ Test API - Fixed!

**The migration-script.sql file is already generated and ready to use!**

Location: `/Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API/migration-script.sql`

---

## Need Help?

If you encounter any issues during these steps, let me know which step failed and I'll help you troubleshoot.

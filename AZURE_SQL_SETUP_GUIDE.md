# Azure SQL Server Setup Guide

## Problem
The Azure SQL Server `vayatra-server.database.windows.net` doesn't exist or was removed.

## Your Azure Resources Found
- **Subscription**: vanyatra_billed_subscription (217ecefe-913a-435c-8e32-b806fa2b0381)
- **Resource Groups**:
  - vanyatraVm_group
  - vayatra-app-service_group (likely where your App Service is)
  - NetworkWatcherRG

---

## Solution: Create Azure SQL Server & Database

### Option A: Create via Azure Portal (Recommended - Visual)

#### Step 1: Create Azure SQL Server

1. **Go to Azure Portal**: https://portal.azure.com
2. **Navigate to**: SQL servers → Click **"+ Create"**
3. **Configure Basic Settings**:
   - **Subscription**: vanyatra_billed_subscription
   - **Resource Group**: `vayatra-app-service_group` (same as your App Service)
   - **Server name**: `vanyatra-server` (or any unique name)
   - **Location**: Central India (same as your resource group)
   - **Authentication method**: Use SQL authentication
   - **Server admin login**: Choose a username (e.g., `sqladmin`)
   - **Password**: Create a strong password (save this!)

4. **Networking**:
   - Allow Azure services to access server: **YES** ✅
   - Add current client IP: **YES** ✅ (so you can connect from your machine)

5. Click **"Review + Create"** → **"Create"**

#### Step 2: Create Database

1. After server is created, go to the SQL Server resource
2. Click **"+ Create database"**
3. **Configure Database**:
   - **Database name**: `RideSharingDb`
   - **Compute + storage**: 
     - Click **"Configure database"**
     - Choose **Basic** tier (cheapest, ~$5/month) or **General Purpose** for production
   - Leave other settings as default

4. Click **"Review + Create"** → **"Create"**

#### Step 3: Get Connection String

1. Go to your SQL Database → **"Connection strings"** (left menu)
2. Copy the **ADO.NET** connection string
3. It will look like:
   ```
   Server=tcp:vanyatra-server.database.windows.net,1433;Initial Catalog=RideSharingDb;Persist Security Info=False;User ID={your_username};Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
   ```

4. **Replace** `{your_username}` and `{your_password}` with actual values

#### Step 4: Configure Azure App Service

1. Go to **Azure Portal** → **App Services** → Your app (likely `vayatra-app-service`)
2. Click **"Configuration"** (left menu under Settings)
3. Under **"Application settings"**, find or add these connection strings:

   **Connection String 1:**
   - Name: `RideSharingConnectionString`
   - Value: Your connection string from Step 3
   - Type: SQLAzure

   **Connection String 2:**
   - Name: `RideSharingAuthConnectionString`
   - Value: Same connection string
   - Type: SQLAzure

4. Click **"Save"** at the top
5. Click **"Continue"** when prompted (app will restart)

---

### Option B: Create via Azure CLI (Fast)

Open terminal and run these commands:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "217ecefe-913a-435c-8e32-b806fa2b0381"

# Create SQL Server (replace PASSWORD with strong password)
az sql server create \
  --name vanyatra-server \
  --resource-group vayatra-app-service_group \
  --location centralindia \
  --admin-user sqladmin \
  --admin-password "YourStrongPassword123!"

# Allow Azure services to access
az sql server firewall-rule create \
  --resource-group vayatra-app-service_group \
  --server vanyatra-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Add your current IP (so you can connect from local machine)
az sql server firewall-rule create \
  --resource-group vayatra-app-service_group \
  --server vanyatra-server \
  --name AllowMyIP \
  --start-ip-address $(curl -s https://api.ipify.org) \
  --end-ip-address $(curl -s https://api.ipify.org)

# Create Database (Basic tier - cheapest)
az sql db create \
  --resource-group vayatra-app-service_group \
  --server vanyatra-server \
  --name RideSharingDb \
  --service-objective Basic

# Get connection string
az sql db show-connection-string \
  --server vanyatra-server \
  --name RideSharingDb \
  --client ado.net
```

**After running these commands:**
1. Copy the connection string output
2. Replace `<username>` with `sqladmin`
3. Replace `<password>` with your password
4. Configure it in Azure App Service (see Step 4 above)

---

### Option C: Use Existing Server (If You Have One)

If you already have an Azure SQL Server but under a different name:

1. Check Azure Portal → SQL servers → Find your server
2. Check if database `RideSharingDb` exists
3. Update the connection string in App Service Configuration

---

## After Creating SQL Server & Database

### Apply Database Schema (Create Tables)

You have **3 options** to create the database tables:

#### Option 1: Using EF Core Migrations (Recommended)

```bash
# Navigate to API project
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API

# Install EF Core tools
dotnet tool install --global dotnet-ef

# Create migration
dotnet ef migrations add InitialCreate --context RideSharingDbContext

# Update connection string in appsettings.json temporarily with Azure SQL connection
# Then apply migration
dotnet ef database update --context RideSharingDbContext
```

#### Option 2: Run SQL Script in Azure Portal

1. Open Azure Portal → Your SQL Database → **Query Editor**
2. Login with SQL authentication
3. Copy contents from: `/Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API/create-database-schema.sql`
4. Paste and click **"Run"**
5. Verify 20 tables are created

#### Option 3: Use Automated Script

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking
./apply-ef-migrations.sh
```

---

## Verify Everything Works

### 1. Test Database Connection

In Azure Portal → Your SQL Database → Query Editor:
```sql
-- Check if tables exist
SELECT name FROM sys.tables ORDER BY name;

-- Should show 20 tables:
-- Banners, Bookings, Cities, CouponUsages, Coupons,
-- Drivers, LocationTrackings, Notifications, OTPVerifications,
-- PasswordResetTokens, Payments, Payouts, Ratings, RefreshTokens,
-- Rides, RouteSegments, UserProfiles, Users, VehicleModels, Vehicles
```

### 2. Restart Azure App Service

1. Azure Portal → App Services → Your app
2. Click **"Restart"** at the top
3. Wait for restart to complete

### 3. Test Your API

```bash
# Test analytics endpoint (should return 200 OK now)
curl https://vayatra-app-service.azurewebsites.net/api/Admin/Dashboard/Analytics
```

---

## Common Issues & Solutions

### Issue 1: "Server does not exist"
- **Cause**: SQL Server not created yet
- **Solution**: Follow Option A or B above

### Issue 2: "Cannot open server"
- **Cause**: Firewall blocking connection
- **Solution**: Add firewall rule to allow Azure services and your IP

### Issue 3: "Login failed"
- **Cause**: Incorrect username/password in connection string
- **Solution**: Verify credentials match what you set during server creation

### Issue 4: "Database does not exist"
- **Cause**: Database not created
- **Solution**: Create database `RideSharingDb` in your SQL Server

### Issue 5: "Invalid object name 'Drivers'"
- **Cause**: Tables not created in database
- **Solution**: Run migrations or SQL script to create tables

---

## Cost Estimate

- **SQL Server**: Free (resource itself has no cost)
- **SQL Database (Basic tier)**: ~$5/month
- **SQL Database (Standard S0)**: ~$15/month
- **SQL Database (General Purpose)**: ~$200+/month

**Recommendation**: Start with **Basic** tier for development/testing, upgrade to **Standard** for production.

---

## Connection String Format

```
Server=tcp:vanyatra-server.database.windows.net,1433;Initial Catalog=RideSharingDb;User Id=sqladmin;Password=YourPassword123!;TrustServerCertificate=True;Encrypt=True;
```

**Important Parts:**
- `Server`: Your SQL server name + `.database.windows.net`
- `Initial Catalog`: Database name (`RideSharingDb`)
- `User Id`: Admin username you created
- `Password`: Admin password you created
- `TrustServerCertificate=True`: Needed for Azure SQL
- `Encrypt=True`: Required for Azure SQL

---

## Next Steps Checklist

- [ ] 1. Create Azure SQL Server
- [ ] 2. Create Database `RideSharingDb`
- [ ] 3. Configure firewall rules
- [ ] 4. Get connection string
- [ ] 5. Update App Service Configuration with connection string
- [ ] 6. Create database tables (using migrations or SQL script)
- [ ] 7. Restart App Service
- [ ] 8. Test API endpoints
- [ ] 9. Verify no more 500 errors

---

## Need Help?

If you encounter any issues:
1. Check Azure Activity Log for error details
2. Check App Service logs
3. Verify connection string is correct
4. Ensure firewall rules allow connections
5. Verify database tables exist

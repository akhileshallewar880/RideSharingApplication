# 🚀 Entity Framework Migrations Guide

## Quick Start (Recommended)

```bash
# Run the automated script
./run-migrations.sh
```

This will:
1. ✅ Install EF Core tools (if needed)
2. ✅ Create initial migration
3. ✅ Generate SQL script
4. ✅ Apply to database

---

## Manual Method (Step by Step)

### Step 1: Install EF Core Tools
```bash
dotnet tool install --global dotnet-ef
```

### Step 2: Navigate to Project
```bash
cd server/ride_sharing_application/RideSharing.API
```

### Step 3: Create Migration
```bash
dotnet ef migrations add InitialCreate --context RideSharingDbContext
```

This creates a `Migrations/` folder with:
- `YYYYMMDDHHMMSS_InitialCreate.cs` - Migration code
- `YYYYMMDDHHMMSS_InitialCreate.Designer.cs` - Metadata
- `RideSharingDbContextModelSnapshot.cs` - Current model

### Step 4: Generate SQL Script (Optional - for review)
```bash
dotnet ef migrations script -o migration-script.sql --idempotent
```

### Step 5: Apply to Local Database (Testing)
```bash
# Using connection string from appsettings.json
dotnet ef database update
```

### Step 6: Apply to Azure SQL (Production)

**Option A: From Local Machine**
```bash
# Set Azure connection string
export ConnectionStrings__RideSharingConnectionString="Server=tcp:YOUR_SERVER.database.windows.net,1433;Initial Catalog=RideSharingDb;User ID=YOUR_USER;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=False;"

# Apply migration
dotnet ef database update
```

**Option B: Using Generated SQL Script**
1. Open `migration-script.sql`
2. Copy contents
3. Go to Azure Portal → SQL Database → Query Editor
4. Paste and run the script

---

## 🔄 If You Need to Reset Database

### Remove Existing Migrations
```bash
cd server/ride_sharing_application/RideSharing.API

# Remove migrations folder
rm -rf Migrations

# Or remove last migration
dotnet ef migrations remove
```

### Drop All Tables (Azure SQL)
```sql
-- Run this in Azure SQL Query Editor
DROP TABLE IF EXISTS CouponUsages, LocationTrackings, Ratings, Payments, Payouts, 
                      Bookings, Rides, Vehicles, Drivers, UserProfiles, RefreshTokens, 
                      PasswordResetTokens, Notifications, Coupons, RouteSegments, 
                      Banners, OTPVerifications, VehicleModels, Cities, Users;
```

### Create Fresh Migration
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

---

## 📊 Verify Migration Applied

### Check Migration History
```bash
dotnet ef migrations list
```

### Check in Database
```sql
-- See applied migrations
SELECT * FROM __EFMigrationsHistory;

-- See all tables
SELECT name FROM sys.tables ORDER BY name;
```

---

## 🐛 Troubleshooting

### Error: "No DbContext was found"
```bash
# Specify the context explicitly
dotnet ef migrations add InitialCreate --context RideSharingDbContext
```

### Error: "Build failed"
```bash
# Build the project first
dotnet build
dotnet ef migrations add InitialCreate
```

### Error: "Login failed / Connection timeout"
- Check Azure SQL firewall allows your IP
- Verify connection string is correct
- Check Azure SQL server is online

### Error: "Cannot drop table because it's referenced"
Use the `drop-all-tables.sql` script which drops in correct order.

---

## 🎯 Best Practices

1. **Always create migrations** - Don't manually edit database
2. **Review generated SQL** before applying to production
3. **Test locally first** before applying to Azure
4. **Keep migrations in source control** - Commit to Git
5. **Use idempotent scripts** for production (--idempotent flag)

---

## 📝 Migration Commands Cheat Sheet

```bash
# Install tools
dotnet tool install --global dotnet-ef

# Create migration
dotnet ef migrations add <MigrationName>

# Remove last migration
dotnet ef migrations remove

# List migrations
dotnet ef migrations list

# Generate SQL script
dotnet ef migrations script

# Apply migrations
dotnet ef database update

# Revert to specific migration
dotnet ef database update <MigrationName>

# Drop database (local only)
dotnet ef database drop
```

---

## 🚀 After Migration Success

Your app should now:
- ✅ Have all 20 tables in Azure SQL
- ✅ Analytics endpoint returns 200 OK
- ✅ No "Invalid object name 'Drivers'" error
- ✅ Admin web app fully functional

Test with:
```bash
# Restart your app
az webapp restart --name vayatra-app-service --resource-group vayatra-app-service_group

# Test analytics endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard
```

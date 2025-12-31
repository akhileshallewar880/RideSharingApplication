# API 500 Error Fix - Status Report

## Problem Summary
After VM restart, auto-start was configured successfully, but all APIs were returning 500 Internal Server Error.

## Root Causes Identified

### 1. Connection String Configuration Mismatch ✅ FIXED
**Issue**: Environment variables were set as `ConnectionStrings__DefaultConnection` and `ConnectionStrings__AuthConnection`, but application code expects:
- `ConnectionStrings__RideSharingConnectionString`
- `ConnectionStrings__RideSharingAuthConnectionString`

**Solution**: Updated `/usr/local/bin/start-vanyatra.sh` with correct environment variable names.

**Location**: [Program.cs line 74-77](server/ride_sharing_application/RideSharing.API/Program.cs#L74-L77)
```csharp
builder.Services.AddDbContext<RideSharingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("RideSharingConnectionString")));

builder.Services.AddDbContext<RideSharingAuthDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("RideSharingAuthConnectionString")));
```

### 2. JWT Configuration Missing ✅ FIXED
**Issue**: JWT settings environment variables were not configured, causing authentication middleware to fail.

**Error**: `JWT secret key is not configured. Set configuration key 'JwtSettings:secretKey'`

**Solution**: Added JWT environment variables to startup script:
```bash
-e "JwtSettings__secretKey=ThisIsASecretKeyForJwtTokenGenerationPleaseChangeThis123"
-e "JwtSettings__validIssuer=https://localhost:7123"
-e "JwtSettings__validAudience=https://localhost:7123"
```

### 3. Database Missing ✅ FIXED
**Issue**: Database "RideSharingDb" didn't exist in SQL Server container.

**Solution**: Created database manually:
```sql
CREATE DATABASE RideSharingDb
```

### 4. Database Schema Missing ⏳ IN PROGRESS
**Issue**: Database exists but tables haven't been created (error: "Invalid object name 'Users'").

**Root Cause**: EF Core migrations code was commented out in Program.cs.

**Attempted Solutions**:
1. ✅ Uncommented migration code in Program.cs (lines 184-210)
2. ✅ Fixed compilation error: removed `AvailableSeats` property from Vehicle initialization in AuthController.cs
3. ✅ Rebuilt Docker image locally (image ID: e6a491e378d4)
4. ❌ **BLOCKED**: Docker Hub push failed due to authentication issues

## Current Status

### What's Working
- ✅ VM auto-start via systemd service
- ✅ Docker containers start automatically on boot
- ✅ Connection string configuration correct
- ✅ JWT configuration correct
- ✅ Database created
- ✅ SQL Server accessible
- ✅ API server starts and responds
- ✅ Code changes committed locally:
  - Program.cs: Migrations uncommented
  - AuthController.cs: Compilation error fixed

### What's Not Working
- ❌ Database tables not created (migrations haven't run)
- ❌ All API endpoints returning 500 errors
- ❌ Updated Docker image not pushed to Docker Hub (authentication required)

## Next Steps

### Option 1: Complete Docker Image Push (Recommended for Production)
1. Complete Docker Hub authentication
2. Push updated image: `docker push akhileshallewar880/vanyatra-server:latest`
3. Update container on VM: `docker pull akhileshallewar880/vanyatra-server:latest`
4. Restart service: `sudo systemctl restart vanyatra.service`
5. Verify migrations run automatically (check logs for "migration completed successfully")

### Option 2: Manual Schema Creation (Quick Fix)
1. Copy all migration SQL scripts to VM
2. Apply migrations manually in correct order:
   ```bash
   docker exec vanyatra-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Akhilesh@22" -C -i /path/to/migration.sql
   ```
3. Restart API container
4. Test endpoints

### Option 3: Run Migrations from Local Development
1. Configure connection string to point to Azure VM SQL Server
2. Run: `dotnet ef database update --project RideSharing.API`
3. Restart API container on VM

## Files Modified

1. **server/ride_sharing_application/RideSharing.API/Program.cs**
   - Lines 184-210: Uncommented automatic migration code
   - Change: Removed comment wrapper around `Task.Run` block

2. **server/ride_sharing_application/RideSharing.API/Controllers/AuthController.cs**
   - Line 300: Removed `AvailableSeats` property from Vehicle initialization
   - Reason: Property doesn't exist in Vehicle model

3. **/usr/local/bin/start-vanyatra.sh** (on VM)
   - Updated connection string environment variables
   - Updated JWT configuration environment variables

## Testing After Fix

Once migrations are applied, test with:
```bash
curl -X POST http://57.159.31.172:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9511254558"}'
```

Expected successful response:
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": { ... }
}
```

## Technical Details

### Docker Image
- Repository: akhileshallewar880/vanyatra-server
- Latest Build: e6a491e378d4 (local)
- Status: Built locally but not pushed to registry

### Database
- Server: vanyatra-sql (Docker container)
- Database: RideSharingDb
- Status: Database created, schema missing

### Migrations Available
- 20251113164941_InitialCreate.cs
- 20251129102629_AddVehicleModelAndEnhanceRide.cs
- 20251129114842_AddSegmentPricingToRides.cs
- 20251129190024_AddLicenseDocumentToDriver.cs
- 20251129195242_AddCityTableAndVehicleModelIdTables.cs
- 20251129195730_SeedCityDataStatic.cs
- 20251219171836_AddLocationTracking.cs
- 20251224183140_AddSeatingArrangementFields.cs
- 20251227181705_AddBannersTable.cs
- 20251228103026_AddSubLocationToCity.cs
- 20251228174040_AddRouteSegmentsTable.cs

## Contact Info
- VM IP: 57.159.31.172
- API Port: 8000
- SQL Port: 1433
- SSH User: akhileshallewar880

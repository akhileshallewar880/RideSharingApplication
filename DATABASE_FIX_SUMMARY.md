# Database Fix Summary

## Overview
Fixed all database schema issues for the VanYatra ride sharing application. The database and all tables are now properly configured and the API is running successfully.

## Issues Fixed

### 1. Database Missing (Critical)
- **Problem**: RideSharingDb database did not exist in SQL Server
- **Error**: "Login failed for user 'sa'. Reason: Failed to open the explicitly specified database 'RideSharingDb'"
- **Solution**: Created RideSharingDb database using SQL command

### 2. Tables Missing (Critical)
- **Problem**: No tables existed in the database
- **Solution**: Created 18 core tables using `create-database-schema.sql`:
  - Users
  - UserProfiles
  - Drivers
  - Vehicles
  - VehicleModels
  - Cities
  - Rides
  - Bookings
  - Payments
  - Ratings
  - Notifications
  - Payouts
  - OTPVerifications
  - RefreshTokens
  - LocationTrackings
  - PasswordResetTokens
  - Banners
  - RouteSegments

### 3. Rides Table Schema Mismatch (Critical)
- **Problem**: Missing 16 columns, had 8 deprecated columns
- **Missing Columns**: RideNumber, VehicleModelId, IntermediateStops, SegmentPrices, TravelDate, DepartureTime, EstimatedArrivalTime, ActualDepartureTime, ActualArrivalTime, BookedSeats, Route, Distance, Duration, IsReturnTrip, LinkedReturnRideId, AdminNotes
- **Deprecated Columns**: ScheduledStartTime, ActualStartTime, ActualEndTime, EstimatedDuration, ActualDuration, EstimatedDistance, ActualDistance, AvailableSeats
- **Solution**: 
  - Dropped index IX_Rides_ScheduledStartTime
  - Added 16 new columns with proper data types
  - Removed 8 deprecated columns

### 4. Bookings Table Schema Mismatch (Critical)
- **Problem**: Missing 15 columns required by Domain model
- **Missing Columns**: 
  - BookingNumber (NVARCHAR(20), unique identifier)
  - PassengerCount (INT, number of passengers)
  - SeatNumbers (NVARCHAR(50), seat identifiers)
  - SelectedSeats (JSON array of selected seats)
  - SeatingArrangementImage (NVARCHAR(500), screenshot path)
  - PricePerSeat (DECIMAL, per seat price)
  - TotalFare (DECIMAL, total fare amount)
  - PlatformFee (DECIMAL, platform fee)
  - OTP (NVARCHAR(6), verification code)
  - QRCode (NVARCHAR(MAX), QR code data)
  - IsVerified (BIT, verification status)
  - VerifiedAt (DATETIME2, verification timestamp)
  - CancellationType (NVARCHAR(20), passenger/driver/system)
  - CancelledAt (DATETIME2, cancellation timestamp)
  - PaymentMethod (NVARCHAR(20), cash/upi/card/wallet)
- **Solution**: Created and executed `alter-bookings-table.sql` to add all missing columns

### 5. Background Service Failures
- **Problem**: BookingNoShowService was crashing every 10 minutes due to schema mismatches
- **Error**: "Invalid column name 'BookingNumber'", "Invalid column name 'SeatNumbers'", etc.
- **Solution**: Fixed Bookings table schema, service now runs without errors

## Files Created

1. **create-database-schema.sql** (400+ lines)
   - Complete initial database schema
   - 18 tables with proper relationships
   - Foreign keys and indexes
   - Status: ✅ Executed successfully

2. **alter-rides-table.sql**
   - Adds 16 missing columns to Rides table
   - Removes 8 deprecated columns
   - Status: ✅ Executed successfully

3. **alter-bookings-table.sql** (3800+ bytes)
   - Adds 14 missing columns to Bookings table
   - Uses IF NOT EXISTS for safe execution
   - Status: ✅ Executed successfully

4. **fix-database.sh**
   - Automated database creation script
   - Restarts API container
   - Verifies table creation
   - Status: ✅ Ready to use

## Current Status

### ✅ Database
- Database: RideSharingDb - EXISTS
- Tables: 18 tables - ALL PRESENT
- Schema: Matches Domain models - VERIFIED

### ✅ API Server
- Container: vanyatra-server - RUNNING
- Swagger UI: http://localhost:8000/swagger/index.html - HTTP 200 ✅
- Logs: No "Invalid column" errors - CLEAN

### ✅ Background Services
- BookingNoShowService - RUNNING (no crashes)
- Other services - RUNNING

### ⚠️ Warnings (Non-Critical)
- Firebase service account key not found - Notifications disabled
- No migrations found in assembly - Expected (using manual schema)
- Data protection keys in container - Keys won't persist on container restart

## Verification Commands

Check database exists:
```bash
docker exec vanyatra-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Akhilesh@22' -C -Q "SELECT name FROM sys.databases"
```

List all tables:
```bash
docker exec vanyatra-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'Akhilesh@22' -d RideSharingDb -C -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME"
```

Check API health:
```bash
curl http://localhost:8000/swagger/index.html
# Should return HTTP 200
```

Check for errors:
```bash
docker logs vanyatra-server --tail 50 | grep -i "Invalid column"
# Should return no results
```

## Next Steps

### 1. Configure GitHub Secrets for CI/CD
Run the helper script to get secret values:
```bash
./show-github-secrets.sh
```

Add these secrets to GitHub repository:
- AZURE_VM_HOST
- AZURE_VM_USERNAME
- AZURE_VM_SSH_KEY

### 2. Open Azure NSG Ports
Open ports 80 and 81 for web app access:
- Port 80: Admin Dashboard
- Port 81: Passenger Web App

### 3. Test Deployments
Push a small change to test workflows:
- Change to `admin_web/**` should trigger deploy-admin-web workflow only
- Change to `mobile/**` should trigger deploy-passenger-web workflow only
- Change to `server/**` should trigger deploy-to-azure-vm workflow only

## Connection Details

- **SQL Server Container**: vanyatra-sql
- **SQL Server Port**: 1433
- **Database Name**: RideSharingDb
- **Username**: sa
- **Password**: Akhilesh@22
- **API Container**: vanyatra-server
- **API Port**: 8000 (internal), 8080 (exposed)

## Notes

- The application uses EF Core Code-First without migrations
- Database schema must be managed manually via SQL scripts
- Domain models define the required schema
- Always verify schema after model changes
- Use DbContext configurations for indexes and foreign keys

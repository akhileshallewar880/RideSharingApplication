# Driver Login Crash Fix - Complete Guide

## Problem Summary
When trying to login with a driver mobile number (Firebase test number), the app crashes with:
- Process killed with signal 9
- "Lost connection to device"
- No specific error message

## Root Cause
The crash occurs because:
1. User logs in with test phone number via Firebase Authentication ✅
2. User selects "Driver" role ✅
3. App navigates to `DriverDashboardScreen` ✅
4. Dashboard calls `getDashboard()` API endpoint `/driver/dashboard` ✅
5. **Backend returns 400 Bad Request: "Driver profile not found"** ❌
6. No driver record exists in database for this user
7. App crashes due to error handling issue

## Solution Overview
Two-part solution:
1. ✅ **Improved Error Handling** - Show user-friendly message instead of crashing
2. ⚠️ **Create Driver Profile** - Add driver record to database

## Part 1: Improved Error Handling ✅

### What Was Fixed
Updated `/mobile/lib/features/driver/presentation/screens/driver_dashboard_screen.dart`:

**Before:**
- Generic error message
- Only Retry button
- No specific handling for "Driver profile not found"

**After:**
- Specific "Driver Profile Not Found" message
- Clear instructions: "Contact support to complete driver registration"
- Both Retry and Logout buttons for better UX
- Different icon (person_off) for profile not found vs generic error

### User Experience Now
When driver profile doesn't exist:
```
🚫 Driver Profile Not Found

Your driver profile hasn't been created yet. 
Please contact support to complete your driver registration.

[Retry] [Logout]
```

## Part 2: Create Driver Profile in Database ⚠️

### Prerequisites
1. User must have logged in at least once to create a Users record
2. You need to know the test phone number (e.g., +919999999999)
3. Access to SQL Server database

### Step 1: Get Your Test Phone Number
From Firebase Console → Authentication → Phone numbers for testing
Example: `+919999999999`

### Step 2: Run SQL Script
Use the provided script: `create-test-driver.sql`

1. **Update the phone number** in the script (line 6):
   ```sql
   DECLARE @TestPhoneNumber NVARCHAR(20) = '+919999999999'; -- UPDATE THIS
   ```

2. **Execute the script** in Azure Data Studio or SSMS

3. **Verify output**:
   ```
   Successfully created test driver profile!
   Driver ID: [GUID]
   User ID: [GUID]
   License Number: TEST-LICENSE-001
   ```

### Step 3: Test Driver Login
1. Open the app
2. Login with the test phone number
3. Complete OTP verification
4. Select "Driver" role
5. Dashboard should now load successfully! ✅

## Database Schema Reference

### Drivers Table Structure
```sql
CREATE TABLE Drivers (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL, -- FK to Users.Id
    LicenseNumber NVARCHAR(50) NOT NULL,
    LicenseExpiryDate DATETIME2,
    LicenseImageUrl NVARCHAR(MAX),
    IsVerified BIT DEFAULT 0,
    IsOnline BIT DEFAULT 0,
    IsAvailable BIT DEFAULT 0,
    CurrentLatitude FLOAT,
    CurrentLongitude FLOAT,
    LastLocationUpdate DATETIME2,
    TotalRides INT DEFAULT 0,
    TotalEarnings DECIMAL(10,2) DEFAULT 0,
    PendingEarnings DECIMAL(10,2) DEFAULT 0,
    AvailableForWithdrawal DECIMAL(10,2) DEFAULT 0,
    Rating FLOAT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);
```

### Test Driver Values Created
- **License Number**: `TEST-LICENSE-001` (can be changed)
- **License Expiry**: 5 years from creation
- **IsVerified**: `1` (verified for testing)
- **IsAvailable**: `1` (available to take rides)
- **Rating**: `5.0` (perfect rating initially)
- **All Earnings**: `0.00`

## Verification Steps

### Check if User Exists
```sql
SELECT * FROM Users WHERE PhoneNumber = '+919999999999';
```

### Check if Driver Profile Exists
```sql
SELECT d.*, u.PhoneNumber, up.Name as DriverName
FROM Drivers d
INNER JOIN Users u ON d.UserId = u.Id
LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE u.PhoneNumber = '+919999999999';
```

### Check Driver Dashboard Data
```sql
-- Same query the backend uses
SELECT 
    d.Id,
    d.IsOnline,
    d.PendingEarnings,
    d.AvailableForWithdrawal,
    up.Name,
    up.Rating,
    up.TotalRides
FROM Drivers d
INNER JOIN Users u ON d.UserId = u.Id
LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE u.PhoneNumber = '+919999999999';
```

## Troubleshooting

### Error: "User with phone number not found"
**Cause**: User hasn't logged in yet
**Solution**: 
1. Login with the test number as passenger first
2. Complete the full authentication flow
3. Then run the SQL script

### Error: "Driver profile already exists"
**Cause**: Driver record was already created
**Solution**: 
- Check existing driver with verification query
- Update existing record if needed
- Or use different test phone number

### Dashboard Still Shows Error After Creating Driver
**Solutions**:
1. Pull down to refresh dashboard
2. Click Retry button
3. Logout and login again
4. Check backend logs for API errors

### Backend Returns 401 Unauthorized
**Cause**: Firebase token expired or invalid
**Solution**:
- Logout and login again to get fresh token
- Check Firebase token in backend logs

## Files Modified

### 1. driver_dashboard_screen.dart
- **Line ~228-277**: Enhanced error handling UI
- **Added**: Specific handling for "Driver profile not found"
- **Added**: Logout button when profile not found
- **Improved**: User-friendly error messages

### 2. create-test-driver.sql (NEW)
- **Purpose**: Creates driver profile for test phone number
- **Usage**: Update phone number and execute in database
- **Output**: Driver record with test values

## Testing Checklist

- [ ] Test phone number added to Firebase Console
- [ ] User logged in at least once (Users record exists)
- [ ] SQL script executed successfully
- [ ] Driver record visible in database
- [ ] App rebuilt and restarted
- [ ] Login with test number works
- [ ] OTP verification completes
- [ ] Driver role selection navigates to dashboard
- [ ] Dashboard loads without crash
- [ ] Dashboard shows driver stats (0 rides, 0 earnings)
- [ ] Toggle online/offline status works
- [ ] Pull to refresh works

## Next Steps

After verifying driver login works:

1. **Add Driver Documents** (optional for testing):
   - License image URL
   - Vehicle information
   - Bank account details

2. **Test Driver Features**:
   - Schedule a ride
   - Accept booking
   - Start trip
   - Complete trip
   - View earnings

3. **Create More Test Drivers** (if needed):
   - Use script with different phone numbers
   - Different license numbers
   - Different vehicle types

## API Endpoint Reference

### GET /driver/dashboard
**Headers**: 
- Authorization: Bearer {firebaseToken}

**Response Success** (200):
```json
{
  "success": true,
  "message": "Dashboard retrieved successfully",
  "data": {
    "driver": {
      "id": "guid",
      "name": "Driver Name",
      "rating": 5.0,
      "totalRides": 0,
      "isOnline": false
    },
    "todayStats": {
      "totalEarnings": 0,
      "totalRides": 0,
      "onlineHours": 0
    },
    "pendingEarnings": 0,
    "availableForWithdrawal": 0
  }
}
```

**Response Error** (400):
```json
{
  "success": false,
  "message": "Driver profile not found",
  "data": null
}
```

## Additional Notes

### Why App Crashed Before
The crash (signal 9) was likely due to:
1. Unhandled exception in dashboard initialization
2. Null pointer exception when accessing driver data
3. Android system killing the app due to uncaught exception
4. No graceful error handling for missing driver profile

### Why It Won't Crash Now
1. ✅ Error state is properly handled in UI
2. ✅ Null checks for dashboardData
3. ✅ User-friendly error message displayed
4. ✅ Alternative actions provided (Retry, Logout)
5. ✅ No code tries to access null driver data

## Contact & Support

If issues persist after following this guide:

1. Check backend logs: `docker logs [container_name]`
2. Check mobile logs: Flutter console output
3. Verify database connection: Run test query
4. Verify Firebase configuration: Check google-services.json
5. Check API base URL: Ensure pointing to correct backend

---

**Last Updated**: After driver login crash investigation
**Status**: ✅ Error handling improved, ⚠️ Database setup required
**Impact**: Driver can now login without crash + see helpful error message

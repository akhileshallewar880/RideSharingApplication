# Driver Ride Visibility - Quick Diagnosis

## Problem
Rides scheduled from admin web app aren't showing in driver app.

## Immediate Steps

### 1. Get Driver Phone Number
Note the exact phone number used in driver app login (e.g., +919876543210)

### 2. Run Diagnostic Query
Open SQL Server Management Studio and run:

```sql
-- Replace +919876543210 with actual driver phone
SELECT 
    u.PhoneNumber,
    d.Id as DriverId,
    up.Name as DriverName,
    COUNT(r.Id) as ScheduledRidesCount
FROM Users u
INNER JOIN Drivers d ON u.Id = d.UserId
LEFT JOIN UserProfiles up ON u.Id = up.UserId
LEFT JOIN Rides r ON d.Id = r.DriverId AND r.Status IN ('scheduled', 'active')
WHERE u.PhoneNumber = '+919876543210'
    AND u.Role = 'driver'
GROUP BY u.PhoneNumber, d.Id, up.Name;
```

**Expected Result**: One row with ScheduledRidesCount > 0

### 3. Check Backend Logs

#### When admin schedules:
```
✅ Admin scheduled ride - DriverPhone: +919876543210
```

#### When driver logs in:
```
✅ GetActiveRides: Found driver - DriverId: {guid}, Phone: +919876543210
📋 GetActiveRides: Retrieved X rides
```

### 4. Common Issues & Fixes

| Issue | Check | Fix |
|-------|-------|-----|
| Query returns 0 rides | Ride not scheduled for this driver | Reschedule from admin with correct driver |
| Query returns no rows | Driver account doesn't exist | Driver needs to complete registration |
| Phone numbers don't match | Different phones in admin vs app | Use exact same phone number |
| DriverId mismatch in logs | Database inconsistency | Contact support |

## Quick Fix Commands

### If driver needs verification:
```sql
UPDATE Drivers 
SET IsVerified = 1 
WHERE Id = 'driver-guid-from-query';
```

### If ride exists but wrong status:
```sql
UPDATE Rides 
SET Status = 'scheduled' 
WHERE RideNumber = 'RD20250108001';
```

## Test Workflow

1. **Admin**: Schedule ride for driver with phone +919876543210
2. **Check**: Run diagnostic query - should show 1 ride
3. **Driver**: Login with +919876543210
4. **Verify**: Check logs show matching DriverId and ride count > 0
5. **App**: Ride should appear in Upcoming/Scheduled tab

## Files Created

- **DRIVER_RIDE_VISIBILITY_DIAGNOSTIC.sql** - Complete SQL queries
- **DRIVER_RIDE_VISIBILITY_TROUBLESHOOTING.md** - Detailed guide
- **Backend logs** - Added comprehensive logging
- **App logs** - Enhanced authentication tracking

## Next Steps

If issue persists after checking above:

1. Run full diagnostic: `DRIVER_RIDE_VISIBILITY_DIAGNOSTIC.sql` Query #7
2. Check for duplicate accounts: Query #5
3. Verify vehicle registration: Query #6
4. Review complete troubleshooting guide

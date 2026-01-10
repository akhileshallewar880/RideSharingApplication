# Driver Ride Visibility Troubleshooting Guide

## Problem
Rides scheduled from the admin web app for a specific driver are not appearing in the driver app when the driver logs in with their mobile number.

## How the System Works

### The Connection Chain
1. **Admin schedules a ride**: Admin selects a driver from the dropdown and creates a ride
2. **Ride is assigned to Driver**: The ride is created with `Ride.DriverId` = selected driver's ID
3. **Driver logs in**: Driver enters phone number → Gets OTP → Verifies OTP
4. **Authentication**: Backend creates JWT token with `userId` claim (User.Id)
5. **Fetch rides**: Driver app calls `/api/v1/driver/rides/active`
   - Backend extracts `userId` from JWT token
   - Finds `Driver` record where `Driver.UserId` = `userId`
   - Fetches all rides where `Ride.DriverId` = `Driver.Id`

### Key Relationships
```
User (phoneNumber) 
  ↓ (UserId)
Driver (has reference to User.Id via Driver.UserId)
  ↓ (DriverId)
Ride (has reference to Driver.Id via Ride.DriverId)
```

## Diagnostic Steps

### Step 1: Verify Driver Account Exists
1. Get the driver's phone number (e.g., +919876543210)
2. Open `DRIVER_RIDE_VISIBILITY_DIAGNOSTIC.sql`
3. Run **Query #1** with the driver's phone number
4. Expected result: Should return one row with:
   - UserId
   - PhoneNumber
   - DriverId
   - DriverName
   - IsVerified = 1
   - UserIsActive = 1

**If no results**: The driver account doesn't exist or isn't properly set up.
- Check if driver completed registration
- Verify driver is approved by admin
- Check if `Driver.IsVerified` is true

### Step 2: Verify Rides Are Assigned to the Driver
1. Copy the `DriverId` from Step 1
2. Run **Query #2** with this DriverId
3. Expected result: Should return all rides scheduled for this driver

**If no results**: No rides are scheduled for this driver.
- Check if admin selected the correct driver when scheduling
- Run Query #3 to see all scheduled rides and verify phone numbers

### Step 3: Check for Common Issues

#### Issue A: Multiple Driver Accounts
Run **Query #5** to check if the phone number has multiple driver accounts.
- If yes: There are duplicate accounts. Delete the duplicate or consolidate.

#### Issue B: Driver Has No Vehicle
Run **Query #6** to verify the driver has an active vehicle registered.
- If no vehicle: Admin cannot schedule rides for this driver. Driver needs to complete vehicle registration.

#### Issue C: Phone Number Mismatch
Compare the phone number used in admin (when selecting driver) vs. the phone number used in driver app login.
- Ensure they are identical, including country code (e.g., +91)
- Check for extra spaces or formatting differences

### Step 4: Monitor Backend Logs

#### When Admin Schedules a Ride:
Look for this log entry:
```
✅ Admin scheduled ride - RideId: {RideId}, RideNumber: {RideNumber}, 
   DriverId: {DriverId}, DriverName: {DriverName}, DriverPhone: {DriverPhone}, 
   DriverUserId: {DriverUserId}
```

Note down:
- DriverId
- DriverPhone
- DriverUserId

#### When Driver Logs In and Fetches Rides:
Look for these log entries:
```
🔍 GetActiveRides: Extracted userId from token: {UserId}
✅ GetActiveRides: Found driver - DriverId: {DriverId}, UserId: {UserId}, Phone: {Phone}
📋 GetActiveRides: Retrieved {Count} rides for driver {DriverId}
```

Compare:
- The `userId` from the token should match the `DriverUserId` from the admin schedule log
- The `DriverId` should match the `DriverId` from the admin schedule log
- The `Phone` should match the `DriverPhone` from the admin schedule log
- The `Count` should be > 0 if rides exist

### Step 5: Check Driver App Logs

In the Flutter app, look for these logs:
```
✅ OTP verified successfully - UserType: driver, UserId: {userId}, IsNewUser: false
🚗 Loading active rides...
📦 Service response - Success: true, Data count: {count}
```

If `Data count: 0`, the rides aren't being returned by the API.

## Common Root Causes

### 1. Wrong Driver Selected in Admin
**Symptom**: Rides are scheduled but for a different driver
**Solution**: 
- Run Query #3 to see all scheduled rides with phone numbers
- Verify the phone number matches the driver logging in
- If wrong driver, cancel the ride and reschedule for correct driver

### 2. Driver UserId Mismatch
**Symptom**: Driver account exists but the UserId doesn't match
**Solution**:
- Run Query #1 and Query #8 (with userId from JWT token)
- If they don't match, there's a database inconsistency
- Verify the driver's User account is correct

### 3. Driver Not Verified
**Symptom**: Driver account exists but IsVerified = false
**Solution**:
- Admin needs to verify the driver in the admin dashboard
- Update: `UPDATE Drivers SET IsVerified = 1 WHERE Id = 'driver-id'`

### 4. Rides Filtered Out by Date/Status
**Symptom**: Rides exist but are in the wrong status or date
**Solution**:
- Check the ride's `TravelDate` - should be today or future
- Check the ride's `Status` - should be 'scheduled' or 'active'
- Verify the ride isn't cancelled

### 5. JWT Token Issue
**Symptom**: Driver login works but userId is incorrect
**Solution**:
- Check if the driver is logging in with the correct phone number
- Verify the backend is returning the correct userId in the token
- Check if the driver completed profile setup after OTP verification

## Quick Fix Checklist

- [ ] Driver account exists and is verified
- [ ] Driver has an active vehicle registered
- [ ] Ride is scheduled with correct DriverId
- [ ] Ride status is 'scheduled' or 'active'
- [ ] Ride TravelDate is today or in the future
- [ ] Phone numbers match exactly (admin vs. app login)
- [ ] No duplicate driver accounts for the same phone
- [ ] Backend logs show correct userId and DriverId
- [ ] Driver app successfully fetches rides (count > 0)

## Testing Steps

1. **Schedule a test ride from admin**:
   - Select a specific driver
   - Schedule for today or tomorrow
   - Note the RideNumber

2. **Check backend logs**:
   - Verify the ride creation log shows correct DriverId and phone

3. **Login to driver app**:
   - Use the exact phone number of the selected driver
   - Check backend logs for userId and DriverId

4. **Verify ride appears**:
   - Driver should see the ride in "Upcoming" or "Scheduled" tab
   - Ride details should match what was scheduled

## SQL Query Reference

See `DRIVER_RIDE_VISIBILITY_DIAGNOSTIC.sql` for all diagnostic queries:
- Query #1: Verify driver-user relationship
- Query #2: Verify rides for specific driver
- Query #3: See all scheduled rides with driver info
- Query #4: Recent admin-scheduled rides
- Query #5: Check for duplicate accounts
- Query #6: Verify driver has vehicle
- Query #7: Comprehensive driver lookup
- Query #8: Verify by JWT userId

## Need More Help?

If rides still don't appear after following this guide:

1. Run all diagnostic queries and save results
2. Check backend logs for both admin scheduling and driver login
3. Check driver app logs
4. Verify database relationships with Query #7
5. Contact support with:
   - Driver phone number
   - Expected RideNumber
   - Results from Query #1 and Query #2
   - Backend log entries from scheduling and login

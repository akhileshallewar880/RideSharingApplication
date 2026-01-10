# Driver Login Fix - Quick Start

## Problem
Driver login crashes with Firebase test phone number.

## Quick Solution (2 Steps)

### Step 1: Update SQL Script
Edit `create-test-driver.sql` line 6:
```sql
DECLARE @TestPhoneNumber NVARCHAR(20) = '+919999999999'; -- Your test number
```

### Step 2: Run SQL Script
Execute in Azure Data Studio:
```sql
-- Run the entire create-test-driver.sql file
```

### Step 3: Test
1. Login with test phone number
2. Complete OTP
3. Select "Driver" role
4. Dashboard should load! ✅

## If User Doesn't Exist Yet
Login as **passenger first** with the test number, then run SQL script.

## What Was Fixed
- ✅ Better error handling (shows "Driver Profile Not Found" instead of crash)
- ✅ SQL script to create driver profile in database
- ✅ User-friendly error messages with Logout button

## Files
- `/mobile/lib/features/driver/presentation/screens/driver_dashboard_screen.dart` - Error handling improved
- `create-test-driver.sql` - New SQL script
- `DRIVER_LOGIN_CRASH_FIX.md` - Complete documentation

That's it! 🎉

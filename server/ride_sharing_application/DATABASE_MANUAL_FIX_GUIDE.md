# 🔧 MANUAL DATABASE FIX - Step by Step Guide

## Problem
**Error:** `"Invalid object name 'Drivers'"`  
**Cause:** Database tables were never created in Azure SQL  
**Solution:** Manually run SQL script to create all tables

---

## ✅ SOLUTION: Run SQL Script in Azure Portal

### Step 1: Open Azure Portal
1. Go to: https://portal.azure.com
2. Sign in with your Azure account

### Step 2: Navigate to SQL Database
1. In the search bar, type: **SQL databases**
2. Click on **SQL databases**
3. Find and click your database (likely named: `RideSharingDb` or similar)

### Step 3: Open Query Editor
1. In the left sidebar, click **Query editor (preview)**
2. You'll be prompted to login:
   - Select **SQL Server authentication**
   - Enter your database username
   - Enter your database password
   - Click **OK**

### Step 4: Copy and Run SQL Script
1. Open this file: [`create-database-schema.sql`](./create-database-schema.sql)
2. **Copy ALL the contents** (Cmd+A, Cmd+C)
3. **Paste** into the Azure Query Editor
4. Click **Run** button at the top

### Step 5: Verify Success
You should see output like:
```
✅ Users table created
✅ UserProfiles table created
✅ Drivers table created
✅ Vehicles table created
✅ Rides table created
✅ Bookings table created
... (20 tables total)
✅ DATABASE SCHEMA CREATION COMPLETE
```

### Step 6: Verify Tables Exist
Run this query in the Query Editor:
```sql
SELECT name FROM sys.tables ORDER BY name;
```

You should see 20 tables:
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

## 🧪 Test the Fix

### Test 1: Analytics Endpoint
1. Open your admin web app
2. Login with your credentials
3. Navigate to analytics dashboard
4. Check browser console (F12)

**Expected result:**
```javascript
✅ Success: GET /api/v1/admin/analytics/dashboard [200 OK]
```

**Old error (should be GONE):**
```javascript
❌ Error: Invalid object name 'Drivers'
```

### Test 2: Check All Admin Features
Try accessing:
- ✅ Dashboard / Analytics
- ✅ Rides Management
- ✅ User Management  
- ✅ Driver Management
- ✅ Bookings
- ✅ Notifications
- ✅ Banners
- ✅ Locations

All should now work without 500 errors!

---

## 🔍 Troubleshooting

### Issue: "Login failed for user"
**Solution:** Check your database connection string in Azure App Service settings

### Issue: "Permission denied"
**Solution:** Your database user needs these permissions:
- CREATE TABLE
- ALTER TABLE
- SELECT, INSERT, UPDATE, DELETE

### Issue: Tables already exist
**Solution:** That's OK! The script checks for existing tables and skips them.

### Issue: Script fails partway through
**Solution:** The script uses transactions. You can run it again safely.

---

## 📊 What This Creates

The SQL script creates **20 tables**:

### Core Tables
1. **Users** - User authentication and profiles
2. **UserProfiles** - Extended user information
3. **Drivers** - Driver-specific data and verification
4. **Vehicles** - Vehicle registration and documents
5. **Rides** - Scheduled rides by drivers
6. **Bookings** - Passenger bookings

### Transaction Tables
7. **Payments** - Payment transactions
8. **Payouts** - Driver payouts
9. **Ratings** - Ride ratings and reviews

### Supporting Tables
10. **Cities** - Service area cities
11. **VehicleModels** - Vehicle types and models
12. **Notifications** - Push notifications
13. **Banners** - Admin banners
14. **RouteSegments** - Route pricing
15. **Coupons** - Discount coupons
16. **CouponUsages** - Coupon usage tracking

### Security Tables
17. **OTPVerifications** - OTP codes for phone/email
18. **RefreshTokens** - JWT refresh tokens
19. **PasswordResetTokens** - Password reset tokens
20. **LocationTrackings** - Real-time driver location

---

## ⚡ Quick Alternative: Using Azure CLI

If you have Azure CLI installed, you can run the script from terminal:

```bash
# Login to Azure
az login

# Run SQL script
az sql db execute \
  --server YOUR_SQL_SERVER_NAME \
  --database YOUR_DATABASE_NAME \
  --auth-mode ActiveDirectoryPassword \
  --file create-database-schema.sql
```

Replace:
- `YOUR_SQL_SERVER_NAME` - Your Azure SQL Server name
- `YOUR_DATABASE_NAME` - Your database name (RideSharingDb)

---

## 🎯 Expected Outcome

After running this script:

1. **All 20 tables created** in Azure SQL Database
2. **Analytics endpoint returns 200 OK** (not 500)
3. **All admin APIs work correctly**
4. **No more "Invalid object name" errors**
5. **Admin web app fully functional**

---

## 📝 Why Did This Happen?

The automatic database initialization in `Program.cs` likely failed because:
1. Connection string issues during initial deployment
2. Insufficient permissions
3. Database didn't exist yet
4. Firewall rules blocking access
5. Silent failure during app startup

The manual script ensures tables are created correctly.

---

## ✅ After Fix Checklist

- [ ] All 20 tables exist in database
- [ ] Analytics dashboard loads successfully
- [ ] No console errors in browser
- [ ] All admin features accessible
- [ ] Rides management works
- [ ] User/Driver management works
- [ ] Bookings display correctly

---

## 🆘 Need Help?

If you're stuck:
1. Check Azure Portal for SQL Database
2. Verify connection strings in App Service
3. Check firewall rules allow Azure services
4. Review App Service logs for errors
5. Try restarting App Service after creating tables

---

**Created:** January 15, 2026  
**Status:** Ready to execute  
**File:** `create-database-schema.sql`

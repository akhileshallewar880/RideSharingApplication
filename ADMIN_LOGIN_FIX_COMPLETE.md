# Admin Login Fix Guide

## Problem
You're getting this error when trying to login to the admin dashboard:
```json
{
    "success": false,
    "error": {
        "message": "Access denied. Admin privileges required."
    }
}
```

## Root Cause
The admin user either:
1. **Doesn't exist** in the database
2. **Has wrong UserType** (must be exactly "admin" in lowercase)
3. **Has incorrect password hash** that doesn't match "Admin@123"

## Solution: Run the Fix Script

### Step 1: Run the SQL Script
Execute this script on your Azure SQL Database:

```bash
# From the project root
sqlcmd -S your-server.database.windows.net -d RideSharingDb -U your-admin-user -P your-password -i fix-admin-login.sql
```

Or use Azure Data Studio / SSMS to execute `fix-admin-login.sql`

### Step 2: Verify Admin User Exists
After running the script, check the admin user:

```sql
SELECT 
    Id,
    Email,
    PhoneNumber,
    UserType,
    IsActive,
    IsBlocked,
    LEFT(PasswordHash, 30) as PasswordHashPreview
FROM Users 
WHERE Email = 'admin@vanyatra.com';
```

You should see:
- ✅ Email: `admin@vanyatra.com`
- ✅ UserType: `admin` (lowercase)
- ✅ IsActive: `1`
- ✅ IsBlocked: `0`
- ✅ PasswordHash: starts with `$2a$11$`

### Step 3: Test Login
Now try logging in with:
- **Email:** `admin@vanyatra.com`
- **Password:** `Admin@123`

## What the Fix Script Does

1. **Deletes any existing admin user** (clean slate)
2. **Creates a new admin user** with:
   - Email: `admin@vanyatra.com`
   - Password: `Admin@123` (BCrypt hashed)
   - UserType: `admin` (lowercase - important!)
   - Phone: +91 9999999999
   - All verification flags enabled
3. **Creates admin profile** with System Administrator name
4. **Verifies** the user was created successfully

## Troubleshooting

### Still Getting "Access denied"?

**Check 1: User exists**
```sql
SELECT * FROM Users WHERE Email = 'admin@vanyatra.com';
```
If no rows → Run `fix-admin-login.sql` again

**Check 2: UserType is correct**
```sql
SELECT UserType FROM Users WHERE Email = 'admin@vanyatra.com';
```
Must be exactly `admin` (lowercase)

**Check 3: Test password verification**
The password "Admin@123" must verify against the stored hash.

**Check 4: JWT Token Generation**
Look at backend logs when you try to login:
```bash
# Check backend logs
docker logs <container-name> --tail 100
# or on VM
pm2 logs backend
```

You should see:
- ✅ "Admin login attempt" message
- ✅ User found
- ✅ User is admin
- ✅ Password verification succeeded
- ✅ JWT token generated

### Common Issues

**Issue 1: UserType is "Admin" (capital A)**
- **Fix:** Must be lowercase "admin"
```sql
UPDATE Users 
SET UserType = 'admin' 
WHERE Email = 'admin@vanyatra.com';
```

**Issue 2: Password hash doesn't work**
- **Fix:** Use the exact hash from `fix-admin-login.sql`

**Issue 3: User IsActive = 0 or IsBlocked = 1**
```sql
UPDATE Users 
SET IsActive = 1, IsBlocked = 0 
WHERE Email = 'admin@vanyatra.com';
```

**Issue 4: Wrong API endpoint**
- Admin login endpoint: `POST /api/v1/admin/auth/login`
- NOT `/api/v1/auth/login` (that's for passengers)

## Security Note

⚠️ **IMPORTANT:** After your first successful login, change the password immediately!

The default password `Admin@123` is only for initial setup.

## Files Modified

- ✅ `fix-admin-login.sql` - Main fix script
- ✅ `check_admin.sql` - Verification query
- ✅ `generate_correct_admin_hash.csx` - Hash generator (optional)

## Next Steps

After fixing admin login:

1. ✅ Login to admin dashboard
2. ⚠️ Change the default password
3. ✅ Test all admin features
4. ✅ Create additional admin users if needed

## Support

If you still can't login after running the fix:

1. Check backend logs for detailed error messages
2. Verify database connection is working
3. Test with a REST client (Postman/Thunder Client):
   ```
   POST http://your-api/api/v1/admin/auth/login
   Content-Type: application/json
   
   {
     "email": "admin@vanyatra.com",
     "password": "Admin@123"
   }
   ```
4. Check the response shows UserType = "admin" in JWT claims

---

✅ **Expected Result:** Admin login works with `admin@vanyatra.com` / `Admin@123`

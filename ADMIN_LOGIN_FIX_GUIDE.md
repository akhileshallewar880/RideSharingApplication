# 🔧 Admin Login Fix - Step by Step Guide

## 🐛 Problem
The admin dashboard login was failing with "login failed" error because the backend was checking passwords against a hardcoded value instead of the database.

## ✅ Solution Applied

The backend code has been updated to use proper BCrypt password hashing. Now you need to update the database with a hashed password.

---

## 📋 Quick Fix Steps

### Step 1: Generate Password Hash

**Option A: Use the API endpoint (Easiest)**

1. Start your API:
   ```bash
   cd server/ride_sharing_application/RideSharing.API
   dotnet run
   ```

2. In another terminal, generate the hash:
   ```bash
   curl -X POST http://192.168.88.20:5056/api/v1/admin/generate-password-hash \
     -H 'Content-Type: application/json' \
     -d '{"password":"Akhilesh@22","email":"akhileshallewar880@gmail.com"}'
   ```

3. Copy the `hash` value from the JSON response

**Option B: Use online tool**

1. Go to https://bcrypt-generator.com/
2. Enter password: `Admin@123`
3. Set rounds: `11`
4. Click "Generate"
5. Copy the hash

### Step 2: Update Database

Run this SQL query in your SQL Server (replace `YOUR_HASH_HERE` with the hash from Step 1):

```sql
-- Check existing admin users
SELECT Id, Email, UserType, PasswordHash, IsActive
FROM Users
WHERE UserType = 'admin';

-- Update admin password
UPDATE Users
SET PasswordHash = 'YOUR_HASH_HERE',
    UpdatedAt = GETUTCDATE()
WHERE Email = 'admin@allapalliride.com';

-- Verify update
SELECT Id, Email, UserType, PasswordHash, IsActive
FROM Users
WHERE Email = 'admin@allapalliride.com';
```

### Step 3: Rebuild and Restart API

```bash
cd server/ride_sharing_application/RideSharing.API
dotnet build
dotnet run
```

### Step 4: Test Login

1. Open admin dashboard: http://localhost:YOUR_PORT
2. Login with:
   - Email: `admin@allapalliride.com`
   - Password: `Admin@123`

---

## 🔍 Troubleshooting

### Issue: "Invalid credentials" error

**Check 1: Verify admin user exists**
```sql
SELECT * FROM Users WHERE Email = 'admin@allapalliride.com';
```

If no user exists, create one:
```sql
INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)
VALUES (
    NEWID(),
    '1234567890',
    '+91',
    'admin@allapalliride.com',
    'YOUR_HASH_HERE',  -- Replace with generated hash
    'admin',
    1,
    1,
    1,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);
```

**Check 2: Verify PasswordHash is not NULL**
```sql
SELECT Email, PasswordHash FROM Users WHERE Email = 'admin@allapalliride.com';
```

**Check 3: Verify UserType is 'admin'**
```sql
SELECT Email, UserType FROM Users WHERE Email = 'admin@allapalliride.com';
```

### Issue: "Access denied" error

This means the user exists but `UserType` is not 'admin'. Fix it:
```sql
UPDATE Users 
SET UserType = 'admin' 
WHERE Email = 'admin@allapalliride.com';
```

### Issue: API returns 500 error

Check API logs for the specific error message. Common issues:
- Database connection problems
- Missing BCrypt package (should be installed)

---

## 📊 Verify Everything Works

### 1. Check API logs
Look for: `"Admin login successful: admin@allapalliride.com"`

### 2. Test with curl
```bash
curl -X POST http://192.168.88.20:5056/api/v1/admin/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@allapalliride.com","password":"Admin@123"}'
```

Expected response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "...",
      "email": "admin@allapalliride.com",
      "name": "Administrator",
      "role": "admin"
    },
    "token": "...",
    "refreshToken": "..."
  }
}
```

---

## 🔐 Security Notes

- ✅ Passwords are now hashed with BCrypt (work factor 11)
- ✅ Never store plain-text passwords
- ✅ Each password hash is unique (BCrypt includes salt)
- ⚠️ The `/generate-password-hash` endpoint should be removed in production

---

## 📝 What Changed?

### Backend Changes:
1. ✅ Installed `BCrypt.Net-Next` package
2. ✅ Created `PasswordHelper.cs` utility
3. ✅ Updated `AdminController.cs` to verify passwords properly
4. ✅ Added `/admin/generate-password-hash` endpoint (development only)

### Database Changes Needed:
1. ⚠️ Update admin user's `PasswordHash` column with BCrypt hash

---

## 🎯 Next Steps (Optional)

1. Add a "Change Password" feature in admin dashboard
2. Add "Forgot Password" functionality
3. Implement password strength requirements
4. Add two-factor authentication (2FA)
5. Remove `/generate-password-hash` endpoint before production

---

## 📧 Need Help?

If you still have issues:
1. Check API logs for detailed error messages
2. Verify database connection string
3. Ensure SQL Server is running
4. Check that the admin user exists in the database
5. Verify the PasswordHash column is not NULL

---

## 🎉 Success!

Once you complete these steps, you should be able to login to the admin dashboard with your database credentials!

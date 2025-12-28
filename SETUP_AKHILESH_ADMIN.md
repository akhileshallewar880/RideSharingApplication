# 🔐 Setup Akhilesh Admin Credentials

## ✅ Ready to Execute!

Your admin credentials are ready with BCrypt hash generated.

### 📋 Credentials
- **Email:** `akhileshallewar880@gmail.com`
- **Password:** `Akhilesh@22`
- **Role:** Admin

---

## 🚀 Quick Setup (Choose One Method)

### Method 1: Run SQL Script (Recommended)

Open SQL Server Management Studio or Azure Data Studio and run:

```sql
-- File: AddAkhileshAdmin.sql
-- This script will create or update your admin user

-- Check if user exists
SELECT * FROM Users WHERE Email = 'akhileshallewar880@gmail.com';

-- Create or Update admin user
UPDATE Users
SET PasswordHash = '$2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G',
    UserType = 'admin',
    IsActive = 1,
    IsBlocked = 0,
    UpdatedAt = GETUTCDATE()
WHERE Email = 'akhileshallewar880@gmail.com';

-- If user doesn't exist, insert new one
IF @@ROWCOUNT = 0
INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, 
                   IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, 
                   CreatedAt, UpdatedAt)
VALUES (NEWID(), '9999999999', '+91', 'akhileshallewar880@gmail.com',
        '$2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G',
        'admin', 1, 1, 1, 0, GETUTCDATE(), GETUTCDATE());

-- Verify
SELECT Email, UserType, IsActive FROM Users WHERE Email = 'akhileshallewar880@gmail.com';
```

### Method 2: Copy-Paste Single Query

Just copy and paste this into your SQL client:

```sql
DECLARE @Email NVARCHAR(255) = 'akhileshallewar880@gmail.com';
DECLARE @Hash NVARCHAR(MAX) = '$2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G';

IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    UPDATE Users SET PasswordHash = @Hash, UserType = 'admin', IsActive = 1, IsBlocked = 0, UpdatedAt = GETUTCDATE() WHERE Email = @Email
ELSE
    INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)
    VALUES (NEWID(), '9999999999', '+91', @Email, @Hash, 'admin', 1, 1, 1, 0, GETUTCDATE(), GETUTCDATE());

SELECT 'Admin user ready!' AS Status, Email, UserType FROM Users WHERE Email = @Email;
```

---

## ✅ Test Login

After running the SQL:

1. **Open Admin Dashboard**
2. **Login with:**
   - Email: `akhileshallewar880@gmail.com`
   - Password: `Akhilesh@22`

3. **You should see:**
   - ✅ "Login successful" 
   - ✅ Redirected to dashboard
   - ✅ API logs: "Admin login successful: akhileshallewar880@gmail.com"

---

## 🔍 Verify It Worked

Run this query to check:

```sql
SELECT 
    Email,
    UserType,
    IsActive,
    IsBlocked,
    CASE WHEN PasswordHash IS NOT NULL THEN '✓ Hash Set' ELSE '✗ No Hash' END AS Status
FROM Users 
WHERE Email = 'akhileshallewar880@gmail.com';
```

Expected output:
```
Email                          UserType  IsActive  IsBlocked  Status
akhileshallewar880@gmail.com   admin     1         0          ✓ Hash Set
```

---

## 🐛 Troubleshooting

### Issue: "Invalid credentials" after running SQL

**Solution 1:** Check password hash is set
```sql
SELECT PasswordHash FROM Users WHERE Email = 'akhileshallewar880@gmail.com';
-- Should show: $2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G
```

**Solution 2:** Verify UserType is 'admin'
```sql
SELECT UserType FROM Users WHERE Email = 'akhileshallewar880@gmail.com';
-- Should show: admin
```

**Solution 3:** Re-run the setup script
- Use Method 2 (single query) above

### Issue: User doesn't exist after running SQL

Check your database connection string in `appsettings.json`

---

## 📝 Files Created

1. **`AddAkhileshAdmin.sql`** - Complete setup script
2. **`SETUP_AKHILESH_ADMIN.md`** - This guide

---

## 🎉 Done!

Your admin account is ready. Go login! 🚀

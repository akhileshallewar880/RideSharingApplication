# 🚀 ADMIN LOGIN - QUICK FIX CARD

## 🎯 THE PROBLEM
Admin login says "login failed" even with correct database credentials.

## ✅ THE FIX (3 Steps)

### 1️⃣ Start API & Generate Hash
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet run
```

Then in another terminal:
```bash
curl -X POST http://192.168.88.20:5056/api/v1/admin/generate-password-hash \
  -H 'Content-Type: application/json' \
  -d '{"password":"Admin@123"}'
```

**Copy the "hash" value from response!**

### 2️⃣ Update Database
```sql
UPDATE Users
SET PasswordHash = 'PASTE_YOUR_HASH_HERE',
    UpdatedAt = GETUTCDATE()
WHERE Email = 'admin@allapalliride.com';
```

### 3️⃣ Test Login
- Email: `admin@allapalliride.com`
- Password: `Admin@123`

## ✨ Done!

---

## 🔧 If Admin User Doesn't Exist

```sql
-- First generate hash as shown in step 1, then:
INSERT INTO Users (
    Id, PhoneNumber, CountryCode, Email, PasswordHash, 
    UserType, IsPhoneVerified, IsEmailVerified, 
    IsActive, IsBlocked, CreatedAt, UpdatedAt
)
VALUES (
    NEWID(), '9999999999', '+91',
    'admin@allapalliride.com',
    'YOUR_HASH_HERE',
    'admin', 1, 1, 1, 0,
    GETUTCDATE(), GETUTCDATE()
);
```

---

## 🐛 Still Not Working?

### Run Diagnostic:
```sql
-- Check admin user status
SELECT Id, Email, UserType, PasswordHash, IsActive, IsBlocked
FROM Users 
WHERE Email = 'admin@allapalliride.com';
```

### Common Fixes:

**Problem: PasswordHash is NULL**
→ Run Step 2 above

**Problem: UserType is not 'admin'**
```sql
UPDATE Users SET UserType = 'admin' WHERE Email = 'admin@allapalliride.com';
```

**Problem: IsActive = 0 or IsBlocked = 1**
```sql
UPDATE Users 
SET IsActive = 1, IsBlocked = 0 
WHERE Email = 'admin@allapalliride.com';
```

---

## 📖 Full Documentation
See `ADMIN_LOGIN_FIX_SUMMARY.md` for complete details.

---

**Status: ✅ Backend Fixed | ⚠️ Database Update Needed**

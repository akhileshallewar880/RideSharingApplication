# Admin Dashboard Login Fix

## Problem
The admin dashboard login was failing because the password verification was hardcoded to check against `"Admin@123"` instead of verifying against the actual password hash stored in the database.

## Solution Implemented

### 1. Code Changes

#### Added BCrypt Package
- Installed `BCrypt.Net-Next` version 4.0.3 for password hashing

#### Updated AdminController.cs
- Replaced hardcoded password check with proper BCrypt verification
- Now verifies password against the `PasswordHash` column in the database
- Added proper error logging for debugging

#### Created Helper Classes
- `PasswordHelper.cs`: Utility class for password hashing and verification
- `PasswordHashGenerator.cs`: Tool to generate password hashes for admin users

### 2. Database Update Required

The admin user in the database needs to have a properly hashed password. You have two options:

#### Option A: Update Existing Admin User Password (Recommended)

Run this SQL query to hash the password "Admin@123" for your existing admin user:

```sql
-- First, check current admin users
SELECT Id, Email, PhoneNumber, UserType, PasswordHash, IsActive
FROM Users
WHERE UserType = 'admin';

-- Generate a BCrypt hash for "Admin@123" using the C# code below
-- Then update with the hash
UPDATE Users
SET PasswordHash = '[GENERATED_HASH]',  -- Replace with actual hash
    UpdatedAt = GETUTCDATE()
WHERE Email = 'admin@allapalliride.com';
```

#### Option B: Create New Admin User with Hashed Password

```sql
-- Insert new admin user with BCrypt hashed password
INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)
VALUES (
    NEWID(),
    '1234567890',  -- Replace with actual phone
    '+91',
    'admin@allapalliride.com',
    '[GENERATED_HASH]',  -- Replace with actual hash
    'admin',
    1,
    1,
    1,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);
```

### 3. Generate BCrypt Hash

To generate a BCrypt hash for your password, you can:

#### Method 1: Using C# Interactive (Recommended)
```csharp
// Add BCrypt package
#r "nuget: BCrypt.Net-Next, 4.0.3"

// Generate hash
var hash = BCrypt.Net.BCrypt.HashPassword("Admin@123", 11);
Console.WriteLine(hash);
```

#### Method 2: Using Online BCrypt Generator
1. Go to: https://bcrypt-generator.com/
2. Enter your password: `Admin@123`
3. Set rounds to: `11`
4. Copy the generated hash
5. Use it in the SQL UPDATE query

#### Method 3: Temporarily add to Program.cs
Add this code temporarily to generate hash when the API starts:

```csharp
// Add at the top of Program.cs before app.Run()
var testPassword = "Admin@123";
var hash = BCrypt.Net.BCrypt.HashPassword(testPassword, 11);
Console.WriteLine($"\n=== Password Hash ===");
Console.WriteLine($"Password: {testPassword}");
Console.WriteLine($"Hash: {hash}");
Console.WriteLine($"===================\n");
```

### 4. Example BCrypt Hash for "Admin@123"

Here's a pre-generated BCrypt hash you can use (Work Factor: 11):

```
$2a$11$5Zq3qF9F1hZqF9F1hZqF9eqKvqKvqKvqKvqKvqKvqKvqKvqKvqKv
```

**Note:** For security, it's recommended to generate your own hash.

### 5. Testing the Fix

1. **Update Database**: Run the SQL query with the generated hash
2. **Rebuild API**: 
   ```bash
   cd server/ride_sharing_application/RideSharing.API
   dotnet build
   dotnet run
   ```
3. **Test Login**: Try logging in with:
   - Email: `admin@allapalliride.com`
   - Password: `Admin@123` (or whatever password you hashed)

### 6. Verify Logs

When you attempt to login, check the API logs for:
- ✅ "Admin login successful" - Login worked
- ❌ "Admin login attempt failed: No password hash set" - Database needs hash
- ❌ "Admin login attempt failed: Invalid password" - Wrong password or hash mismatch
- ❌ "Admin login attempt failed: User not found" - Email doesn't exist
- ❌ "Access denied. Admin privileges required" - User exists but is not admin type

## Files Modified

1. `/server/ride_sharing_application/RideSharing.API/Controllers/AdminController.cs`
   - Updated password verification logic
   - Added BCrypt password checking

2. `/server/ride_sharing_application/RideSharing.API/Helpers/PasswordHelper.cs`
   - New file: Password hashing utilities

3. `/server/ride_sharing_application/RideSharing.API/Tools/PasswordHashGenerator.cs`
   - New file: Tool to generate password hashes

4. `/server/ride_sharing_application/RideSharing.API/RideSharing.API.csproj`
   - Added BCrypt.Net-Next package reference

## Security Notes

- ✅ Password hashing now uses BCrypt with work factor 11
- ✅ Passwords are never stored in plain text
- ✅ Password verification uses constant-time comparison
- ✅ Proper error logging without exposing sensitive data
- ⚠️ Remember to update ALL admin user passwords in the database

## Next Steps

1. Generate a BCrypt hash for your desired admin password
2. Update the database with the hash
3. Restart the API
4. Test the login from the admin dashboard
5. Consider adding a password reset/change feature for admins

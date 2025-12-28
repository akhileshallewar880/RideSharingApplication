# Admin Authentication - Updated Implementation

## Overview
The admin authentication has been updated to use the existing `Users` and `UserProfiles` tables instead of hardcoded credentials. Admin users are now regular users with `UserType = 'admin'`.

## Database Setup

### Creating Admin Users

Run the SQL script `CreateAdminUser.sql` to create your first admin user:

```bash
# From SQL Server Management Studio or Azure Data Studio
# Open and execute: CreateAdminUser.sql
```

Or manually insert:

```sql
-- Insert admin user
INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, UserType, IsPhoneVerified, IsEmailVerified, CreatedAt, UpdatedAt)
VALUES (
    NEWID(),
    '9999999999',
    '+91',
    'admin@allapalliride.com',
    'admin',
    1,
    1,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Insert admin profile (use the same Id from Users table)
INSERT INTO UserProfiles (UserId, Name, DateOfBirth, Address, EmergencyContact, CreatedAt, UpdatedAt)
VALUES (
    '<USER_ID_FROM_ABOVE>',
    'System Administrator',
    '1990-01-01',
    'Admin Office',
    '9999999999',
    GETUTCDATE(),
    GETUTCDATE()
);
```

## Authentication Flow

### 1. Admin Login Endpoint
**POST** `/api/v1/admin/auth/login`

**Request:**
```json
{
  "email": "admin@allapalliride.com",
  "password": "Admin@123"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "admin@allapalliride.com",
      "name": "System Administrator",
      "role": "admin",
      "permissions": ["all"],
      "createdAt": "2025-11-29T18:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

**Response (Error - 401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid credentials",
  "data": null
}
```

**Response (Error - 403 Forbidden):**
```json
{
  "success": false,
  "message": "Access denied. Admin privileges required.",
  "data": null
}
```

### Authentication Logic

1. **User Lookup**: Searches for user by email in `Users` table
2. **UserType Check**: Verifies `UserType = 'admin'`
3. **Password Verification**: Currently uses simple comparison (⚠️ **TEMPORARY**)
4. **Token Generation**: Creates JWT access token and refresh token
5. **Refresh Token Storage**: Stores refresh token in `RefreshTokens` table

## Security Considerations

### ⚠️ CRITICAL - Password Hashing
**Current Implementation**: Passwords are stored in plain text and compared directly.

**TODO - Before Production:**
```csharp
// 1. Install password hashing library
// dotnet add package BCrypt.Net-Next

// 2. Hash password when creating admin user
string hashedPassword = BCrypt.Net.BCrypt.HashPassword("Admin@123");

// 3. Verify password in AdminLogin
if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
{
    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid credentials"));
}
```

### Recommended Security Enhancements

1. **Add PasswordHash column to Users table**
```sql
ALTER TABLE Users ADD PasswordHash NVARCHAR(255) NULL;
```

2. **Implement password reset flow**
   - Send OTP to admin email
   - Allow password reset with OTP verification

3. **Add login attempt tracking**
   - Lock account after N failed attempts
   - Implement CAPTCHA after 3 failed attempts

4. **Enable Two-Factor Authentication (2FA)**
   - SMS/Email OTP
   - Authenticator app support

5. **Audit logging**
   - Log all admin login attempts
   - Log all admin actions (approve/reject drivers)

## Admin User Management

### Creating Multiple Admin Users

You can create multiple admin users with different permissions:

```sql
-- Create admin with specific role
INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, UserType, IsPhoneVerified, IsEmailVerified, CreatedAt, UpdatedAt)
VALUES (
    NEWID(),
    '9999999998',
    '+91',
    'support@allapalliride.com',
    'admin', -- Or create different types: 'super_admin', 'moderator'
    1,
    1,
    GETUTCDATE(),
    GETUTCDATE()
);
```

### Checking Admin Users

```sql
-- List all admin users
SELECT 
    u.Id,
    u.Email,
    u.PhoneNumber,
    u.UserType,
    up.Name,
    u.CreatedAt,
    u.IsEmailVerified
FROM Users u
LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE u.UserType = 'admin'
ORDER BY u.CreatedAt DESC;
```

### Revoking Admin Access

```sql
-- Demote admin to regular user
UPDATE Users 
SET UserType = 'passenger', 
    UpdatedAt = GETUTCDATE()
WHERE Email = 'admin@allapalliride.com';
```

## Testing

### 1. Create Admin User
Run `CreateAdminUser.sql` script

### 2. Start Backend Server
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet run
```

### 3. Test Login (using curl)
```bash
curl -X POST http://localhost:5056/api/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@allapalliride.com",
    "password": "Admin@123"
  }'
```

### 4. Test with Admin Web App
```bash
cd admin_web
flutter run -d chrome
```

Login with:
- Email: `admin@allapalliride.com`
- Password: `Admin@123`

## Current Password

⚠️ **Temporary Password**: `Admin@123`

This password is hardcoded in the `AdminLogin` method and should be replaced with proper password hashing before production deployment.

## Migration Path to Secure Authentication

1. **Phase 1** (Current): Simple email/password check with admin users in database ✅
2. **Phase 2**: Add PasswordHash column and implement BCrypt hashing
3. **Phase 3**: Add password reset functionality
4. **Phase 4**: Implement 2FA
5. **Phase 5**: Add role-based permissions (super_admin, moderator, support)

## Environment Variables (Recommended)

Instead of hardcoding, use environment variables:

```json
// appsettings.json
{
  "AdminSettings": {
    "DefaultPassword": "Admin@123", // Only for initial setup
    "RequirePasswordChange": true,
    "PasswordMinLength": 8,
    "EnableTwoFactor": false
  }
}
```

## Next Steps

1. ✅ Create admin user using SQL script
2. ✅ Test login via API
3. ✅ Test login via admin web
4. 🔜 Implement password hashing
5. 🔜 Add password reset flow
6. 🔜 Implement role-based permissions

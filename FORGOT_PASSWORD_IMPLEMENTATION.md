# 🔐 Forgot Password Feature - Complete Implementation

## Overview
Complete forgot password functionality for VanYatra Admin Dashboard, allowing administrators to reset their passwords via email.

## Features Implemented

### Backend (C# .NET Core)

#### 1. Email Service
**Files Created:**
- `Services/Interface/IEmailService.cs` - Email service interface
- `Services/Implementation/EmailService.cs` - SMTP email implementation

**Features:**
- HTML email templates with professional styling
- Password reset email with 6-digit code
- 15-minute token expiration
- Configurable SMTP settings via appsettings.json
- Development mode (logs email instead of sending when SMTP not configured)

#### 2. Password Reset Endpoints
**File Modified:** `Controllers/AdminController.cs`

**New Endpoints:**

1. **POST `/api/v1/admin/auth/forgot-password`**
   - Request password reset
   - Generates 6-digit token
   - Sends reset email
   - Token expires in 15 minutes
   - Returns success even if email doesn't exist (security)

2. **POST `/api/v1/admin/auth/verify-reset-token`**
   - Verify token validity before allowing password reset
   - Checks token expiration
   - Returns token status

3. **POST `/api/v1/admin/auth/reset-password`**
   - Reset password with valid token
   - Validates password strength (min 8 characters)
   - Marks token as used
   - Updates password hash

#### 3. Database Schema
**Table:** `PasswordResetTokens`

```sql
CREATE TABLE [dbo].[PasswordResetTokens] (
    [Id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [UserId] UNIQUEIDENTIFIER NOT NULL,
    [Token] NVARCHAR(10) NOT NULL,
    [ExpiresAt] DATETIME2(7) NOT NULL,
    [IsUsed] BIT NOT NULL DEFAULT 0,
    [CreatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [UsedAt] DATETIME2(7) NULL,
    CONSTRAINT FK_PasswordResetTokens_Users_UserId 
        FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]) ON DELETE CASCADE
);
```

**Indexes:**
- `IX_PasswordResetTokens_UserId` - Quick lookup by user
- `IX_PasswordResetTokens_Token` - Fast token validation
- `IX_PasswordResetTokens_ExpiresAt` - Cleanup expired tokens

### Frontend (Flutter Web)

#### 1. Forgot Password Screen
**File:** `features/auth/forgot_password_screen.dart`

**Features:**
- Clean, professional UI with card layout
- Email input with validation
- Loading state during API call
- Success dialog with instructions
- Error handling with user-friendly messages
- "Back to Login" link

**User Flow:**
1. Click "Forgot Password?" on login screen
2. Enter admin email address
3. Receives success message (regardless of email existence)
4. Check email for 6-digit reset code
5. Navigate to reset password page

#### 2. Reset Password Screen
**File:** `features/auth/reset_password_screen.dart`

**Features:**
- Email and 6-digit code input
- Auto-verify token when 6 digits entered
- Visual confirmation when token is valid
- New password with strength requirements
- Confirm password with matching validation
- Password visibility toggle
- Loading states
- Success dialog redirects to login

**User Flow:**
1. Enter email and 6-digit code from email
2. System auto-verifies code
3. Create new password (min 8 characters)
4. Confirm password
5. Success! Redirected to login
6. Login with new password

#### 3. Login Screen Updates
**File:** `features/auth/admin_login_screen.dart`

**Changes:**
- Added functional "Forgot Password?" button
- Routes to forgot password screen
- Styled button for better UX

#### 4. Routes Configuration
**File:** `main.dart`

**New Routes:**
- `/forgot-password` - Forgot password form
- `/reset-password` - Reset password form (supports query parameters)
- Query parameter support for email/token pre-filling

## Configuration

### Backend Setup

#### 1. Email Configuration (appsettings.json)
```json
{
  "Email": {
    "SmtpHost": "smtp.gmail.com",
    "SmtpPort": "587",
    "Username": "your-email@gmail.com",
    "Password": "your-app-password",
    "FromEmail": "noreply@allapalliride.com",
    "FromName": "Allapalli Ride Sharing"
  }
}
```

**Gmail Setup:**
1. Enable 2-Factor Authentication in your Google account
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use App Password in configuration (not your regular password)

**Development Mode:**
- If SMTP not configured, backend logs email details to console
- Check backend logs for reset tokens during development
- Look for: `🔑 Password Reset Token for {email}: {token}`

#### 2. Database Setup

**Option 1: SQL Script** (Recommended)
```bash
# Run the SQL script on your RideSharingDb database
sqlcmd -S localhost -U sa -P "YourPassword" -d RideSharingDb -i CreatePasswordResetTokensTable.sql
```

**Option 2: Manual SQL**
Run the CREATE TABLE statement from the Database Schema section above directly in SQL Server Management Studio or Azure Data Studio.

**Option 3: EF Core Migration** (If no conflicts)
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet ef migrations add AddPasswordResetTokens --context RideSharingDbContext
dotnet ef database update --context RideSharingDbContext
```

## Testing Guide

### 1. Backend Testing

**Test Forgot Password Request:**
```bash
curl -X POST http://localhost:5056/api/v1/admin/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "akhileshallewar880@gmail.com",
    "resetUrl": "http://localhost:3000/reset-password"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "If an admin account exists with this email, a password reset link has been sent.",
  "data": {
    "expiresIn": 15
  }
}
```

**Check Backend Logs:**
```
🔑 Password Reset Token for akhileshallewar880@gmail.com: 123456 (expires in 15 minutes)
```

**Test Verify Token:**
```bash
curl -X POST http://localhost:5056/api/v1/admin/auth/verify-reset-token \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "akhileshallewar880@gmail.com",
    "token": "123456"
  }'
```

**Test Reset Password:**
```bash
curl -X POST http://localhost:5056/api/v1/admin/auth/reset-password \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "akhileshallewar880@gmail.com",
    "token": "123456",
    "newPassword": "NewSecure@Password123"
  }'
```

### 2. Frontend Testing

**Step 1: Start Backend**
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet run --urls "http://0.0.0.0:5056"
```

**Step 2: Start Admin Web**
```bash
cd admin_web
flutter run -d chrome
```

**Step 3: Test Flow**
1. Navigate to login page: `http://localhost:3000`
2. Click "Forgot Password?"
3. Enter your admin email: `akhileshallewar880@gmail.com`
4. Click "Send Reset Link"
5. Check backend console logs for the 6-digit token
6. Click "OK" to go to reset password page OR manually navigate
7. Enter email and 6-digit token from logs
8. Create new password (min 8 characters)
9. Click "Reset Password"
10. Success! You'll be redirected to login
11. Login with new password

### 3. Email Testing (With SMTP Configured)

1. Configure SMTP settings in appsettings.json
2. Request password reset for your email
3. Check inbox for reset email
4. Click reset link or copy 6-digit code
5. Complete password reset
6. Login with new password

## API Documentation

### Forgot Password
```
POST /api/v1/admin/auth/forgot-password
Content-Type: application/json

Request:
{
  "email": "admin@example.com",
  "resetUrl": "http://localhost:3000/reset-password" (optional)
}

Response (200 OK):
{
  "success": true,
  "message": "If an admin account exists...",
  "data": {
    "expiresIn": 15
  }
}
```

### Verify Reset Token
```
POST /api/v1/admin/auth/verify-reset-token
Content-Type: application/json

Request:
{
  "email": "admin@example.com",
  "token": "123456"
}

Response (200 OK):
{
  "success": true,
  "message": "Token is valid",
  "data": {
    "valid": true,
    "expiresAt": "2025-12-26T10:30:00Z"
  }
}

Error (400 Bad Request):
{
  "success": false,
  "message": "Invalid or expired token"
}
```

### Reset Password
```
POST /api/v1/admin/auth/reset-password
Content-Type: application/json

Request:
{
  "email": "admin@example.com",
  "token": "123456",
  "newPassword": "NewSecure@Password123"
}

Response (200 OK):
{
  "success": true,
  "message": "Password has been reset successfully..."
}

Error (400 Bad Request):
{
  "success": false,
  "message": "Password must be at least 8 characters long"
}
```

## Security Features

1. **Token Security:**
   - 6-digit random token (1 million combinations)
   - 15-minute expiration
   - One-time use (marked as used after reset)
   - Foreign key cascade delete with user

2. **Email Verification:**
   - Only admin users can request reset
   - Generic success message (doesn't reveal if email exists)
   - Reset link expires after use

3. **Password Requirements:**
   - Minimum 8 characters
   - BCrypt hashing with work factor 11
   - Password confirmation required

4. **Rate Limiting (Recommended):**
   - Add rate limiting middleware for production
   - Limit forgot password requests per IP
   - Prevent token brute force attacks

## Troubleshooting

### Issue: Email not sending
**Cause:** SMTP not configured or incorrect credentials
**Fix:**
1. Check appsettings.json Email configuration
2. Verify Gmail App Password (if using Gmail)
3. Check backend logs for email errors
4. Use development mode (logs token to console)

### Issue: Token expired
**Cause:** 15-minute expiration passed
**Fix:**
1. Request new password reset
2. Use token within 15 minutes
3. Check system clock synchronization

### Issue: Table doesn't exist
**Cause:** Database migration not applied
**Fix:**
1. Run CreatePasswordResetTokensTable.sql
2. Or use EF Core migration commands
3. Verify table exists: `SELECT * FROM PasswordResetTokens`

### Issue: Invalid token error
**Cause:** Token already used, expired, or incorrect
**Fix:**
1. Request new reset email
2. Copy token carefully from email/logs
3. Check for typos in 6-digit code

## Files Modified/Created

### Backend
- ✅ `Services/Interface/IEmailService.cs` (NEW)
- ✅ `Services/Implementation/EmailService.cs` (NEW)
- ✅ `Models/Domain/PasswordResetToken.cs` (NEW)
- ✅ `Controllers/AdminController.cs` (MODIFIED - added 3 endpoints)
- ✅ `Data/RideSharingDbContext.cs` (MODIFIED - added DbSet)
- ✅ `Program.cs` (MODIFIED - registered EmailService)
- ✅ `CreatePasswordResetTokensTable.sql` (NEW)

### Frontend
- ✅ `features/auth/forgot_password_screen.dart` (NEW)
- ✅ `features/auth/reset_password_screen.dart` (NEW)
- ✅ `features/auth/admin_login_screen.dart` (MODIFIED)
- ✅ `main.dart` (MODIFIED - added routes)

## Future Enhancements

1. **Rate Limiting:** Add request throttling for security
2. **Email Templates:** Create reusable email template system
3. **SMS Reset:** Alternative reset via SMS for phone-verified admins
4. **2FA Integration:** Two-factor authentication for password resets
5. **Audit Logging:** Track all password reset attempts
6. **Token Cleanup:** Background job to delete expired tokens
7. **Password History:** Prevent reusing last N passwords

## Production Checklist

- [ ] Configure production SMTP server
- [ ] Update resetUrl in frontend to production domain
- [ ] Enable HTTPS for all password reset operations
- [ ] Add rate limiting middleware
- [ ] Set up email monitoring/alerts
- [ ] Test email deliverability
- [ ] Configure SPF/DKIM/DMARC for email domain
- [ ] Review and update token expiration time
- [ ] Add honeypot field for bot protection
- [ ] Enable CORS only for production domain
- [ ] Remove development logging of tokens

## Support

For issues or questions:
1. Check backend logs for error details
2. Verify database table exists
3. Test API endpoints with curl
4. Review SMTP configuration
5. Check email spam/junk folder

---

**Implementation Date:** December 26, 2025
**Status:** ✅ Complete and Ready for Testing
**Next Step:** Restart backend and test the complete flow!

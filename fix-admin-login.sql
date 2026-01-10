-- Fix Admin Login Issue
-- This script will delete any existing admin user and create a fresh one

USE RideSharingDb;
GO

-- Step 1: Delete existing admin user if exists
DECLARE @ExistingAdminId UNIQUEIDENTIFIER;

SELECT @ExistingAdminId = Id 
FROM Users 
WHERE Email = 'admin@vanyatra.com' OR UserType = 'admin';

IF @ExistingAdminId IS NOT NULL
BEGIN
    PRINT 'Found existing admin user, deleting...';
    
    -- Delete from UserProfiles first (foreign key constraint)
    DELETE FROM UserProfiles WHERE UserId = @ExistingAdminId;
    PRINT '  - Deleted admin profile';
    
    -- Delete from RefreshTokens
    DELETE FROM RefreshTokens WHERE UserId = @ExistingAdminId;
    PRINT '  - Deleted refresh tokens';
    
    -- Delete from Users
    DELETE FROM Users WHERE Id = @ExistingAdminId;
    PRINT '  - Deleted admin user';
    
    PRINT 'Old admin user deleted successfully!';
    PRINT '';
END

-- Step 2: Create new admin user with correct BCrypt hash
-- Password: Admin@123
-- BCrypt hash generated with work factor 11
-- $2a$11$ prefix indicates BCrypt with work factor 11
DECLARE @AdminPassword NVARCHAR(MAX) = '$2a$11$Xr5HL7x4c7XPZJk8JdJdVOLjQH5/Pp.TXWJvhP5fk6cTGK2P5g6Gi';
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminProfileId UNIQUEIDENTIFIER = NEWID();

PRINT 'Creating new admin user...';

-- Insert admin user
INSERT INTO Users (
    Id, 
    PhoneNumber, 
    CountryCode, 
    Email, 
    PasswordHash, 
    UserType, 
    IsPhoneVerified, 
    IsEmailVerified, 
    IsActive, 
    IsBlocked, 
    CreatedAt, 
    UpdatedAt
)
VALUES (
    @AdminUserId,
    '9999999999',
    '+91',
    'admin@vanyatra.com',
    @AdminPassword,
    'admin',  -- IMPORTANT: Must be lowercase 'admin'
    1,  -- IsPhoneVerified
    1,  -- IsEmailVerified
    1,  -- IsActive
    0,  -- IsBlocked
    GETUTCDATE(),
    GETUTCDATE()
);

PRINT '  - Admin user created';

-- Insert admin profile
INSERT INTO UserProfiles (
    Id, 
    UserId, 
    Name, 
    Rating, 
    TotalRides, 
    CreatedAt, 
    UpdatedAt
)
VALUES (
    @AdminProfileId,
    @AdminUserId,
    'System Administrator',
    5.00,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

PRINT '  - Admin profile created';
PRINT '';
PRINT '========================================';
PRINT '✅ ADMIN USER CREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT 'Login Credentials:';
PRINT '  📧 Email: admin@vanyatra.com';
PRINT '  🔑 Password: Admin@123';
PRINT '';
PRINT 'User Details:';
PRINT '  👤 User ID: ' + CAST(@AdminUserId AS NVARCHAR(50));
PRINT '  📱 Phone: +91 9999999999';
PRINT '  🎭 Role: admin';
PRINT '';
PRINT '⚠️  IMPORTANT: Change this password after first login!';
PRINT '========================================';

-- Verify the user was created
SELECT 
    Id,
    Email,
    PhoneNumber,
    UserType,
    IsActive,
    IsBlocked,
    IsPhoneVerified,
    IsEmailVerified,
    CreatedAt
FROM Users 
WHERE Email = 'admin@vanyatra.com';

PRINT '';
PRINT '✅ Verification complete - Admin user is ready!';

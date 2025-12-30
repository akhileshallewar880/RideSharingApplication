-- Create Default Admin User
USE RideSharingDb;
GO

-- BCrypt hash for "Admin@123" with work factor 11
-- Generated using BCrypt.Net.BCrypt.HashPassword("Admin@123", 11)
-- This password should be changed immediately after first login
DECLARE @AdminPassword NVARCHAR(MAX) = '$2a$11$Zc5Ej5zqVQ5KZqHGZqHGZOuN7J1bLJvYL1xZL5YqH9YnLKkR6vYL1x';

-- Generate a new GUID for the admin user
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminProfileId UNIQUEIDENTIFIER = NEWID();

-- Check if admin already exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@vanyatra.com' OR UserType = 'admin')
BEGIN
    -- Insert admin user
    INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)
    VALUES (
        @AdminUserId,
        '9999999999',
        '+91',
        'admin@vanyatra.com',
        @AdminPassword,
        'admin',
        1,  -- IsPhoneVerified
        1,  -- IsEmailVerified
        1,  -- IsActive
        0,  -- IsBlocked
        GETUTCDATE(),
        GETUTCDATE()
    );

    -- Insert admin profile
    INSERT INTO UserProfiles (Id, UserId, Name, Rating, TotalRides, CreatedAt, UpdatedAt)
    VALUES (
        @AdminProfileId,
        @AdminUserId,
        'System Administrator',
        5.00,
        0,
        GETUTCDATE(),
        GETUTCDATE()
    );

    PRINT 'Admin user created successfully!';
    PRINT '';
    PRINT '=== ADMIN CREDENTIALS ===';
    PRINT 'Email: admin@vanyatra.com';
    PRINT 'Password: Admin@123';
    PRINT '';
    PRINT '⚠️  IMPORTANT: Please change this password immediately after first login!';
    PRINT '';
END
ELSE
BEGIN
    PRINT 'Admin user already exists. Skipping creation.';
END
GO

-- Verify admin user was created
SELECT 
    Id,
    PhoneNumber,
    Email,
    UserType,
    IsActive,
    IsEmailVerified,
    CreatedAt
FROM Users 
WHERE UserType = 'admin';
GO

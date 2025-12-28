-- Script to create an admin user in the RideSharing database
-- Run this script to create your first admin user

-- Step 1: Insert admin user into Users table
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminEmail NVARCHAR(100) = 'admin@allapalliride.com';
DECLARE @AdminPhone NVARCHAR(20) = '9999999999'; -- Admin contact number

-- Check if admin already exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @AdminEmail)
BEGIN
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
        @AdminPhone,
        '+91',
        @AdminEmail,
        NULL, -- PasswordHash (will use hardcoded password Admin@123)
        'admin', -- UserType set to 'admin'
        1, -- IsPhoneVerified
        1, -- IsEmailVerified
        1, -- IsActive
        0, -- IsBlocked
        GETUTCDATE(),
        GETUTCDATE()
    );

    -- Insert admin profile
    INSERT INTO UserProfiles (
        Id,
        UserId, 
        Name, 
        DateOfBirth, 
        Address, 
        EmergencyContact, 
        CreatedAt, 
        UpdatedAt
    )
    VALUES (
        NEWID(), -- Id for UserProfiles
        @AdminUserId,
        'System Administrator',
        '1990-01-01', -- Default DOB
        'Admin Office',
        @AdminPhone,
        GETUTCDATE(),
        GETUTCDATE()
    );

    PRINT 'Admin user created successfully!';
    PRINT 'Email: ' + @AdminEmail;
    PRINT 'Password: Admin@123 (temporary - please implement password hashing)';
    PRINT 'User ID: ' + CAST(@AdminUserId AS NVARCHAR(50));
END
ELSE
BEGIN
    PRINT 'Admin user with email ' + @AdminEmail + ' already exists.';
END

-- View the created admin user
SELECT 
    u.Id,
    u.Email,
    u.PhoneNumber,
    u.UserType,
    up.Name,
    u.CreatedAt
FROM Users u
LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE u.Email = @AdminEmail;

GO

-- Optional: Create additional admin users
-- Uncomment and modify the section below to create more admin users

/*
DECLARE @AdminUserId2 UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminEmail2 NVARCHAR(100) = 'admin2@allapalliride.com';
DECLARE @AdminPhone2 NVARCHAR(20) = '9999999998';

IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @AdminEmail2)
BEGIN
    INSERT INTO Users (
        Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, 
        IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt
    )
    VALUES (
        @AdminUserId2,
        @AdminPhone2,
        '+91',
        @AdminEmail2,
        NULL,
        'admin',
        1,
        1,
        1,
        0,
        GETUTCDATE(),
        GETUTCDATE()
    );

    INSERT INTO UserProfiles (
        Id, UserId, Name, DateOfBirth, Address, EmergencyContact, CreatedAt, UpdatedAt
    )
    VALUES (
        NEWID(),
        @AdminUserId2,
        'Admin User 2',
        '1990-01-01',
        'Admin Office',
        @AdminPhone2,
        GETUTCDATE(),
        GETUTCDATE()
    );

    PRINT 'Additional admin user created!';
END
*/

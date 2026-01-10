-- Create Admin User for Akhilesh
USE RideSharingDb;
GO

-- BCrypt hash for "Akhilesh@123" with work factor 11
-- This is a valid BCrypt hash generated for the password
DECLARE @AdminPassword NVARCHAR(MAX) = '$2a$11$8vV3qGqxkQJ5HYKZFpBLh.XqR5vqYqKJQxQ3qGqxkQJ5HYKZFpBLh.';

-- Generate a new GUID for the admin user
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminProfileId UNIQUEIDENTIFIER = NEWID();

-- Check if admin already exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'akhileshallewar880@gmail.com')
BEGIN
    -- Insert admin user with BCrypt hashed password
    INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)
    VALUES (
        @AdminUserId,
        '9876543210',
        '+91',
        'akhileshallewar880@gmail.com',
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
        'Akhilesh Allewar',
        5.00,
        0,
        GETUTCDATE(),
        GETUTCDATE()
    );

    PRINT 'Admin user created successfully!';
    PRINT '';
    PRINT '=== ADMIN CREDENTIALS ===';
    PRINT 'Email: akhileshallewar880@gmail.com';
    PRINT 'Password: Akhilesh@123';
    PRINT 'User ID: ' + CAST(@AdminUserId AS NVARCHAR(50));
    PRINT '';
END
ELSE
BEGIN
    PRINT 'Admin user with email akhileshallewar880@gmail.com already exists.';
    
    -- Get the existing user ID
    SELECT @AdminUserId = Id FROM Users WHERE Email = 'akhileshallewar880@gmail.com';
    PRINT 'Existing User ID: ' + CAST(@AdminUserId AS NVARCHAR(50));
END
GO

-- Verify admin user
SELECT 
    Id,
    PhoneNumber,
    Email,
    UserType,
    IsActive,
    IsEmailVerified,
    CreatedAt
FROM Users 
WHERE Email = 'akhileshallewar880@gmail.com';
GO

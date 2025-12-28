-- Insert Super Admin User into RideSharing Database
-- Execute this script to create a super admin user

-- Generate a unique ID for the admin user
DECLARE @SuperAdminId UNIQUEIDENTIFIER = NEWID();
DECLARE @SuperAdminEmail NVARCHAR(100) = 'superadmin@allapalliride.com';
DECLARE @SuperAdminPhone NVARCHAR(20) = '9999999999';

-- Check if super admin already exists
IF NOT EXISTS (SELECT 1 FROM [RideSharingDb].[dbo].[Users] WHERE Email = @SuperAdminEmail)
BEGIN
    PRINT 'Creating Super Admin user...';
    PRINT 'User ID: ' + CAST(@SuperAdminId AS NVARCHAR(50));
    
    -- Insert super admin into Users table
    INSERT INTO [RideSharingDb].[dbo].[Users] (
        [Id],
        [PhoneNumber],
        [CountryCode],
        [Email],
        [PasswordHash],
        [UserType],
        [IsPhoneVerified],
        [IsEmailVerified],
        [IsActive],
        [IsBlocked],
        [BlockedReason],
        [CreatedAt],
        [UpdatedAt],
        [LastLoginAt]
    )
    VALUES (
        @SuperAdminId,                    -- Id (GUID)
        @SuperAdminPhone,                 -- PhoneNumber
        '+91',                            -- CountryCode
        @SuperAdminEmail,                 -- Email
        NULL,                             -- PasswordHash (NULL for now, will use hardcoded password)
        'admin',                          -- UserType (set to 'admin' for admin users)
        1,                                -- IsPhoneVerified
        1,                                -- IsEmailVerified
        1,                                -- IsActive
        0,                                -- IsBlocked
        NULL,                             -- BlockedReason
        GETUTCDATE(),                     -- CreatedAt
        GETUTCDATE(),                     -- UpdatedAt
        NULL                              -- LastLoginAt
    );

    -- Insert super admin profile into UserProfiles table
    INSERT INTO [RideSharingDb].[dbo].[UserProfiles] (
        [UserId],
        [Name],
        [DateOfBirth],
        [Gender],
        [Address],
        [City],
        [State],
        [Country],
        [PinCode],
        [ProfilePhotoUrl],
        [EmergencyContact],
        [CreatedAt],
        [UpdatedAt]
    )
    VALUES (
        @SuperAdminId,                    -- UserId (same as Users.Id)
        'Super Administrator',            -- Name
        '1990-01-01',                     -- DateOfBirth
        NULL,                             -- Gender
        'Admin Office, Allapalli Ride HQ', -- Address
        'Mumbai',                         -- City
        'Maharashtra',                    -- State
        'India',                          -- Country
        NULL,                             -- PinCode
        NULL,                             -- ProfilePhotoUrl
        @SuperAdminPhone,                 -- EmergencyContact
        GETUTCDATE(),                     -- CreatedAt
        GETUTCDATE()                      -- UpdatedAt
    );

    PRINT '========================================';
    PRINT 'Super Admin User Created Successfully!';
    PRINT '========================================';
    PRINT 'Email: ' + @SuperAdminEmail;
    PRINT 'Phone: ' + @SuperAdminPhone;
    PRINT 'Password: Admin@123 (temporary)';
    PRINT 'User Type: admin';
    PRINT '========================================';
    PRINT 'IMPORTANT: Change the password after first login!';
    PRINT '========================================';
END
ELSE
BEGIN
    PRINT 'Super Admin user with email ' + @SuperAdminEmail + ' already exists.';
    PRINT 'Skipping creation.';
END

-- Display the created/existing super admin user
SELECT 
    u.[Id],
    u.[Email],
    u.[PhoneNumber],
    u.[UserType],
    u.[IsActive],
    u.[IsBlocked],
    up.[Name],
    u.[CreatedAt],
    u.[IsPhoneVerified],
    u.[IsEmailVerified]
FROM [RideSharingDb].[dbo].[Users] u
LEFT JOIN [RideSharingDb].[dbo].[UserProfiles] up ON u.Id = up.UserId
WHERE u.Email = @SuperAdminEmail;

GO

-- Optional: Create additional admin users
-- Uncomment and modify to create more admin accounts

/*
-- Additional Admin User
DECLARE @AdminId2 UNIQUEIDENTIFIER = NEWID();
DECLARE @AdminEmail2 NVARCHAR(100) = 'admin@allapalliride.com';
DECLARE @AdminPhone2 NVARCHAR(20) = '9999999998';

IF NOT EXISTS (SELECT 1 FROM [RideSharingDb].[dbo].[Users] WHERE Email = @AdminEmail2)
BEGIN
    INSERT INTO [RideSharingDb].[dbo].[Users] (
        [Id], [PhoneNumber], [CountryCode], [Email], [PasswordHash], [UserType],
        [IsPhoneVerified], [IsEmailVerified], [IsActive], [IsBlocked],
        [BlockedReason], [CreatedAt], [UpdatedAt], [LastLoginAt]
    )
    VALUES (
        @AdminId2, @AdminPhone2, '+91', @AdminEmail2, NULL, 'admin',
        1, 1, 1, 0, NULL, GETUTCDATE(), GETUTCDATE(), NULL
    );

    INSERT INTO [RideSharingDb].[dbo].[UserProfiles] (
        [UserId], [Name], [DateOfBirth], [Address], [City], [EmergencyContact],
        [CreatedAt], [UpdatedAt]
    )
    VALUES (
        @AdminId2, 'Admin User', '1990-01-01', 'Admin Office', 'Mumbai',
        @AdminPhone2, GETUTCDATE(), GETUTCDATE()
    );

    PRINT 'Additional admin user created: ' + @AdminEmail2;
END
*/

-- Query to list all admin users
SELECT 
    u.[Id],
    u.[Email],
    u.[PhoneNumber],
    u.[UserType],
    up.[Name],
    u.[IsActive],
    u.[IsBlocked],
    u.[CreatedAt]
FROM [RideSharingDb].[dbo].[Users] u
LEFT JOIN [RideSharingDb].[dbo].[UserProfiles] up ON u.Id = up.UserId
WHERE u.[UserType] = 'admin'
ORDER BY u.[CreatedAt] DESC;

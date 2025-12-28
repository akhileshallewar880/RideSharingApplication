-- Add Akhilesh Admin User
-- Email: akhileshallewar880@gmail.com
-- Password: Akhilesh@22

-- Step 1: Check if user already exists
SELECT Id, Email, UserType, PasswordHash, IsActive
FROM Users
WHERE Email = 'akhileshallewar880@gmail.com';

-- Step 2: If user exists, update their credentials
UPDATE Users
SET PasswordHash = '$2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G',
    UserType = 'admin',
    IsActive = 1,
    IsBlocked = 0,
    UpdatedAt = GETUTCDATE()
WHERE Email = 'akhileshallewar880@gmail.com';

-- Step 3: If user doesn't exist (UPDATE returned 0 rows), insert new user
IF @@ROWCOUNT = 0
BEGIN
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
        NEWID(),
        '9999999999',  -- Placeholder phone number
        '+91',
        'akhileshallewar880@gmail.com',
        '$2a$11$NLNiBolJNLFj/uMazWpbxOMxnqvCKKg4li/XIFd4ySOSbxsojfz9G',
        'admin',
        1,
        1,
        1,
        0,
        GETUTCDATE(),
        GETUTCDATE()
    );
    PRINT 'New admin user created for akhileshallewar880@gmail.com';
END
ELSE
BEGIN
    PRINT 'Existing user updated for akhileshallewar880@gmail.com';
END

-- Step 4: Verify the result
SELECT Id, Email, PhoneNumber, UserType, IsActive, IsBlocked, CreatedAt, UpdatedAt,
       CASE 
           WHEN PasswordHash IS NOT NULL THEN 'Password Hash Set ✓'
           ELSE 'No Password Hash ✗'
       END AS PasswordStatus
FROM Users
WHERE Email = 'akhileshallewar880@gmail.com';

PRINT '';
PRINT '========================================';
PRINT 'Admin User Setup Complete!';
PRINT '========================================';
PRINT 'Email: akhileshallewar880@gmail.com';
PRINT 'Password: Akhilesh@22';
PRINT 'UserType: admin';
PRINT '========================================';
PRINT 'You can now login to the admin dashboard!';
PRINT '========================================';


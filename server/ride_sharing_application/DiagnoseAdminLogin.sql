-- Quick Database Check Script for Admin Login
-- Run this to diagnose admin login issues

PRINT '========================================';
PRINT 'Admin User Diagnostics';
PRINT '========================================';
PRINT '';

-- Check 1: Does admin user exist?
PRINT 'Check 1: Admin user existence';
PRINT '------------------------------';
IF EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@allapalliride.com')
BEGIN
    PRINT '✓ Admin user EXISTS';
    SELECT 
        Id,
        Email,
        PhoneNumber,
        UserType,
        IsActive,
        IsBlocked,
        CASE 
            WHEN PasswordHash IS NULL THEN '✗ PASSWORD HASH IS NULL (PROBLEM!)'
            WHEN LEN(PasswordHash) < 50 THEN '✗ PASSWORD HASH TOO SHORT (PROBLEM!)'
            ELSE '✓ Password hash exists'
        END AS PasswordStatus,
        CreatedAt,
        LastLoginAt
    FROM Users 
    WHERE Email = 'admin@allapalliride.com';
END
ELSE
BEGIN
    PRINT '✗ Admin user DOES NOT EXIST (PROBLEM!)';
    PRINT '';
    PRINT 'Solution: Create admin user with:';
    PRINT 'INSERT INTO Users (Id, PhoneNumber, CountryCode, Email, PasswordHash, UserType, IsPhoneVerified, IsEmailVerified, IsActive, IsBlocked, CreatedAt, UpdatedAt)';
    PRINT 'VALUES (NEWID(), ''1234567890'', ''+91'', ''admin@allapalliride.com'', ''YOUR_BCRYPT_HASH'', ''admin'', 1, 1, 1, 0, GETUTCDATE(), GETUTCDATE());';
END
PRINT '';

-- Check 2: UserType validation
PRINT 'Check 2: UserType validation';
PRINT '------------------------------';
DECLARE @UserType NVARCHAR(20);
SELECT @UserType = UserType FROM Users WHERE Email = 'admin@allapalliride.com';
IF @UserType = 'admin'
    PRINT '✓ UserType is correctly set to ''admin''';
ELSE IF @UserType IS NULL
    PRINT '✗ User does not exist';
ELSE
    PRINT '✗ UserType is ''' + @UserType + ''' but should be ''admin'' (PROBLEM!)';
PRINT '';

-- Check 3: Password Hash validation
PRINT 'Check 3: Password hash validation';
PRINT '------------------------------';
DECLARE @PasswordHash NVARCHAR(MAX);
SELECT @PasswordHash = PasswordHash FROM Users WHERE Email = 'admin@allapalliride.com';
IF @PasswordHash IS NULL
BEGIN
    PRINT '✗ PasswordHash is NULL (PROBLEM!)';
    PRINT 'Solution: Generate hash and update with:';
    PRINT 'UPDATE Users SET PasswordHash = ''YOUR_BCRYPT_HASH'' WHERE Email = ''admin@allapalliride.com'';';
END
ELSE IF LEFT(@PasswordHash, 4) = '$2a$' OR LEFT(@PasswordHash, 4) = '$2b$' OR LEFT(@PasswordHash, 4) = '$2y$'
    PRINT '✓ PasswordHash appears to be a valid BCrypt hash';
ELSE
BEGIN
    PRINT '✗ PasswordHash does not look like a BCrypt hash (PROBLEM!)';
    PRINT 'Current hash: ' + LEFT(@PasswordHash, 50);
    PRINT 'Solution: Generate proper BCrypt hash and update';
END
PRINT '';

-- Check 4: Account status
PRINT 'Check 4: Account status';
PRINT '------------------------------';
DECLARE @IsActive BIT, @IsBlocked BIT;
SELECT @IsActive = IsActive, @IsBlocked = IsBlocked FROM Users WHERE Email = 'admin@allapalliride.com';
IF @IsActive = 1 AND @IsBlocked = 0
    PRINT '✓ Account is active and not blocked';
ELSE IF @IsActive = 0
    PRINT '✗ Account is INACTIVE (PROBLEM!)';
ELSE IF @IsBlocked = 1
    PRINT '✗ Account is BLOCKED (PROBLEM!)';
PRINT '';

-- Summary
PRINT '========================================';
PRINT 'Summary';
PRINT '========================================';
IF EXISTS (
    SELECT 1 FROM Users 
    WHERE Email = 'admin@allapalliride.com' 
    AND UserType = 'admin' 
    AND PasswordHash IS NOT NULL
    AND LEN(PasswordHash) > 50
    AND IsActive = 1
    AND IsBlocked = 0
)
BEGIN
    PRINT '✓ All checks passed! Login should work.';
    PRINT '';
    PRINT 'Test login with:';
    PRINT 'Email: admin@allapalliride.com';
    PRINT 'Password: [Your password that was hashed]';
END
ELSE
BEGIN
    PRINT '✗ There are issues that need to be fixed.';
    PRINT 'Review the checks above and follow the solutions.';
END
PRINT '';
PRINT '========================================';

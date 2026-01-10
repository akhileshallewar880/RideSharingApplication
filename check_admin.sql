-- Check if admin user exists
SELECT 
    Id,
    PhoneNumber,
    Email,
    UserType,
    IsActive,
    IsBlocked,
    PasswordHash,
    CreatedAt
FROM Users 
WHERE Email = 'admin@vanyatra.com' OR UserType = 'admin'
ORDER BY CreatedAt DESC;

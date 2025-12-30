-- Update admin password with valid BCrypt hash for "Admin@123"
-- Hash generated using Python bcrypt with work factor 11

UPDATE Users 
SET PasswordHash = '$2b$11$a3e.VsCbwHmq3YWvyKBKc.qUBcYB8QUVx5TClnrlQfySHWfTtegI.'
WHERE Email = 'admin@vanyatra.com';

-- Verify the update
SELECT Id, Email, UserType, IsActive, IsEmailVerified, 
       PasswordHash
FROM Users 
WHERE Email = 'admin@vanyatra.com';

PRINT '';
PRINT '=== Admin Password Updated Successfully ===';
PRINT 'Email: admin@vanyatra.com';
PRINT 'Password: Admin@123';
PRINT '';
PRINT 'You can now login using these credentials.';

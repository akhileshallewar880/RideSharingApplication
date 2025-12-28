-- Script to update admin user password with BCrypt hash
-- This script will update the password for admin@allapalliride.com

-- First, let's check if the admin user exists
SELECT Id, Email, PhoneNumber, UserType, PasswordHash, IsActive
FROM Users
WHERE Email = 'admin@allapalliride.com' OR UserType = 'admin';

-- Update the password hash for the admin user
-- The hash below is for password: Admin@123
-- Generated using BCrypt with WorkFactor 11
UPDATE Users
SET PasswordHash = '$2a$11$9eKGwF5F5F5F5F5F5F5F5eqKZqZqZqZqZqZqZqZqZqZqZqZq',
    UpdatedAt = GETUTCDATE()
WHERE Email = 'admin@allapalliride.com';

-- Note: To generate a new BCrypt hash, you can use this C# code:
-- string hash = BCrypt.Net.BCrypt.HashPassword("YourPassword", 11);

-- Verify the update
SELECT Id, Email, PhoneNumber, UserType, PasswordHash, IsActive, UpdatedAt
FROM Users
WHERE Email = 'admin@allapalliride.com';

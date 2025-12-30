-- Add missing columns to Users table
USE RideSharingDb;
GO

-- Check and add CountryCode
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'CountryCode')
BEGIN
    ALTER TABLE Users ADD CountryCode NVARCHAR(5) NOT NULL DEFAULT '+91';
    PRINT 'Added CountryCode column';
END
GO

-- Check and add IsPhoneVerified
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'IsPhoneVerified')
BEGIN
    ALTER TABLE Users ADD IsPhoneVerified BIT NOT NULL DEFAULT 0;
    PRINT 'Added IsPhoneVerified column';
END
GO

-- Check and add IsEmailVerified
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'IsEmailVerified')
BEGIN
    ALTER TABLE Users ADD IsEmailVerified BIT NOT NULL DEFAULT 0;
    PRINT 'Added IsEmailVerified column';
END
GO

-- Check and add IsBlocked
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'IsBlocked')
BEGIN
    ALTER TABLE Users ADD IsBlocked BIT NOT NULL DEFAULT 0;
    PRINT 'Added IsBlocked column';
END
GO

-- Check and add BlockedReason
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'BlockedReason')
BEGIN
    ALTER TABLE Users ADD BlockedReason NVARCHAR(500) NULL;
    PRINT 'Added BlockedReason column';
END
GO

-- Check and add LastLoginAt
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'LastLoginAt')
BEGIN
    ALTER TABLE Users ADD LastLoginAt DATETIME2 NULL;
    PRINT 'Added LastLoginAt column';
END
GO

-- Check and add FCMToken
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'FCMToken')
BEGIN
    ALTER TABLE Users ADD FCMToken NVARCHAR(512) NULL;
    PRINT 'Added FCMToken column';
END
GO

-- Verify all columns were added
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Users'
ORDER BY ORDINAL_POSITION;
GO

PRINT 'Users table schema update completed successfully!';
GO

-- Add missing columns to UserProfiles table
USE RideSharingDb;
GO

-- Check and add Name (combining FirstName and LastName or as single column)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'Name')
BEGIN
    ALTER TABLE UserProfiles ADD Name NVARCHAR(100) NULL;
    PRINT 'Added Name column';
    -- Optionally copy data from FirstName/LastName if they exist
    UPDATE UserProfiles SET Name = CONCAT(ISNULL(FirstName, ''), ' ', ISNULL(LastName, '')) WHERE Name IS NULL;
END
GO

-- Check and add PinCode (from ZipCode)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'PinCode')
BEGIN
    ALTER TABLE UserProfiles ADD PinCode NVARCHAR(10) NULL;
    PRINT 'Added PinCode column';
    -- Copy from ZipCode if it exists
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'ZipCode')
    BEGIN
        UPDATE UserProfiles SET PinCode = ZipCode WHERE PinCode IS NULL;
    END
END
GO

-- Check and add ProfilePicture (from ProfilePictureUrl)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'ProfilePicture')
BEGIN
    ALTER TABLE UserProfiles ADD ProfilePicture NVARCHAR(500) NULL;
    PRINT 'Added ProfilePicture column';
    -- Copy from ProfilePictureUrl if it exists
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'ProfilePictureUrl')
    BEGIN
        UPDATE UserProfiles SET ProfilePicture = ProfilePictureUrl WHERE ProfilePicture IS NULL;
    END
END
GO

-- Check and add EmergencyContactName
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'EmergencyContactName')
BEGIN
    ALTER TABLE UserProfiles ADD EmergencyContactName NVARCHAR(100) NULL;
    PRINT 'Added EmergencyContactName column';
END
GO

-- Check and add Rating
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'Rating')
BEGIN
    ALTER TABLE UserProfiles ADD Rating DECIMAL(3,2) NOT NULL DEFAULT 0.00;
    PRINT 'Added Rating column';
END
GO

-- Check and add TotalRides
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'TotalRides')
BEGIN
    ALTER TABLE UserProfiles ADD TotalRides INT NOT NULL DEFAULT 0;
    PRINT 'Added TotalRides column';
END
GO

-- Check and add CreatedAt
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'CreatedAt')
BEGIN
    ALTER TABLE UserProfiles ADD CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT 'Added CreatedAt column';
END
GO

-- Check and add UpdatedAt
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'UpdatedAt')
BEGIN
    ALTER TABLE UserProfiles ADD UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt column';
END
GO

-- Verify all columns were added
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'UserProfiles'
ORDER BY ORDINAL_POSITION;
GO

PRINT 'UserProfiles table schema update completed successfully!';
GO

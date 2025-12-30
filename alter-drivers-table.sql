-- Add missing columns to Drivers table
USE RideSharingDb;
GO

-- Check and add LicenseDocument (from LicenseImageUrl)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'LicenseDocument')
BEGIN
    ALTER TABLE Drivers ADD LicenseDocument NVARCHAR(500) NULL;
    PRINT 'Added LicenseDocument column';
    -- Copy from LicenseImageUrl if it exists
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'LicenseImageUrl')
    BEGIN
        UPDATE Drivers SET LicenseDocument = LicenseImageUrl WHERE LicenseDocument IS NULL;
    END
END
GO

-- Check and add LicenseVerified
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'LicenseVerified')
BEGIN
    ALTER TABLE Drivers ADD LicenseVerified BIT NOT NULL DEFAULT 0;
    PRINT 'Added LicenseVerified column';
    -- Set to IsVerified if they're similar
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'IsVerified')
    BEGIN
        UPDATE Drivers SET LicenseVerified = IsVerified WHERE LicenseVerified = 0;
    END
END
GO

-- Check and add AadharNumber
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'AadharNumber')
BEGIN
    ALTER TABLE Drivers ADD AadharNumber NVARCHAR(12) NULL;
    PRINT 'Added AadharNumber column';
END
GO

-- Check and add AadharVerified
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'AadharVerified')
BEGIN
    ALTER TABLE Drivers ADD AadharVerified BIT NOT NULL DEFAULT 0;
    PRINT 'Added AadharVerified column';
END
GO

-- Check and add PanNumber
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'PanNumber')
BEGIN
    ALTER TABLE Drivers ADD PanNumber NVARCHAR(10) NULL;
    PRINT 'Added PanNumber column';
END
GO

-- Check and add VerificationStatus
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'VerificationStatus')
BEGIN
    ALTER TABLE Drivers ADD VerificationStatus NVARCHAR(20) NOT NULL DEFAULT 'pending';
    PRINT 'Added VerificationStatus column';
    -- Set based on IsVerified
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'IsVerified')
    BEGIN
        UPDATE Drivers SET VerificationStatus = CASE WHEN IsVerified = 1 THEN 'approved' ELSE 'pending' END;
    END
END
GO

-- Check and add BankAccountNumber
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'BankAccountNumber')
BEGIN
    ALTER TABLE Drivers ADD BankAccountNumber NVARCHAR(50) NULL;
    PRINT 'Added BankAccountNumber column';
END
GO

-- Check and add BankIFSC
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'BankIFSC')
BEGIN
    ALTER TABLE Drivers ADD BankIFSC NVARCHAR(11) NULL;
    PRINT 'Added BankIFSC column';
END
GO

-- Check and add BankAccountHolderName
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'BankAccountHolderName')
BEGIN
    ALTER TABLE Drivers ADD BankAccountHolderName NVARCHAR(100) NULL;
    PRINT 'Added BankAccountHolderName column';
END
GO

-- Check and add CityId
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'CityId')
BEGIN
    ALTER TABLE Drivers ADD CityId UNIQUEIDENTIFIER NULL;
    PRINT 'Added CityId column';
END
GO

-- Verify all columns were added
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Drivers'
ORDER BY ORDINAL_POSITION;
GO

PRINT 'Drivers table schema update completed successfully!';
GO

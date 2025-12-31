-- Fix Vehicles table by adding missing columns
-- Run this SQL script on your SQL Server database

USE RideSharingDb;
GO

-- Add Make column (rename from Brand) if Brand exists
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'Brand')
BEGIN
    -- Rename Brand to Make
    EXEC sp_rename 'Vehicles.Brand', 'Make', 'COLUMN';
    PRINT 'Renamed Brand column to Make';
END

-- Add FuelType column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'FuelType')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [FuelType] NVARCHAR(20) NULL;
    PRINT 'Added FuelType column';
END

-- Add RegistrationDocument column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'RegistrationDocument')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [RegistrationDocument] NVARCHAR(500) NULL;
    PRINT 'Added RegistrationDocument column';
END

-- Add RegistrationVerified column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'RegistrationVerified')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [RegistrationVerified] BIT NOT NULL DEFAULT 0;
    PRINT 'Added RegistrationVerified column';
END

-- Add RegistrationExpiryDate column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'RegistrationExpiryDate')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [RegistrationExpiryDate] DATETIME2 NULL;
    PRINT 'Added RegistrationExpiryDate column';
END

-- Add InsuranceDocument column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'InsuranceDocument')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [InsuranceDocument] NVARCHAR(500) NULL;
    PRINT 'Added InsuranceDocument column';
END

-- Add InsuranceVerified column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'InsuranceVerified')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [InsuranceVerified] BIT NOT NULL DEFAULT 0;
    PRINT 'Added InsuranceVerified column';
END

-- Add PermitDocument column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'PermitDocument')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [PermitDocument] NVARCHAR(500) NULL;
    PRINT 'Added PermitDocument column';
END

-- Add PermitVerified column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'PermitVerified')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [PermitVerified] BIT NOT NULL DEFAULT 0;
    PRINT 'Added PermitVerified column';
END

-- Add PermitExpiryDate column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'PermitExpiryDate')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [PermitExpiryDate] DATETIME2 NULL;
    PRINT 'Added PermitExpiryDate column';
END

-- Add Features column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Vehicles]') AND name = 'Features')
BEGIN
    ALTER TABLE [dbo].[Vehicles] ADD [Features] NVARCHAR(MAX) NULL;
    PRINT 'Added Features column';
END

PRINT 'Vehicles table update completed!';
GO

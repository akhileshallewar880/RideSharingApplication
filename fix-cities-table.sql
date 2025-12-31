-- Fix Cities table to match Entity Framework Core model
USE RideSharingDb;
GO

-- Add District column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'District')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [District] NVARCHAR(100) NOT NULL DEFAULT '';
    PRINT 'Added District column';
END
ELSE
    PRINT 'District column already exists';
GO

-- Add SubLocation column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'SubLocation')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [SubLocation] NVARCHAR(200) NULL;
    PRINT 'Added SubLocation column';
END
ELSE
    PRINT 'SubLocation column already exists';
GO

-- Add Pincode column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'Pincode')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [Pincode] NVARCHAR(10) NULL;
    PRINT 'Added Pincode column';
END
ELSE
    PRINT 'Pincode column already exists';
GO

-- Add Latitude column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [Latitude] FLOAT NULL;
    PRINT 'Added Latitude column';
END
ELSE
    PRINT 'Latitude column already exists';
GO

-- Add Longitude column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [Longitude] FLOAT NULL;
    PRINT 'Added Longitude column';
END
ELSE
    PRINT 'Longitude column already exists';
GO

-- Add UpdatedAt column if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'UpdatedAt')
BEGIN
    ALTER TABLE [dbo].[Cities] ADD [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt column';
END
ELSE
    PRINT 'UpdatedAt column already exists';
GO

-- Drop Country column if it exists (not in Entity Framework model)
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cities' AND COLUMN_NAME = 'Country')
BEGIN
    ALTER TABLE [dbo].[Cities] DROP COLUMN [Country];
    PRINT 'Dropped Country column';
END
ELSE
    PRINT 'Country column already dropped';
GO

PRINT 'Cities table update completed!';
GO

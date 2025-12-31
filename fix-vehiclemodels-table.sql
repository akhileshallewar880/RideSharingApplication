-- Fix VehicleModels table by adding missing columns
-- Run this SQL script on your SQL Server database

USE RideSharingDb;
GO

-- Add Name column (rename from Model) if Model exists and Name doesn't
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'Model')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'Name')
BEGIN
    -- Rename Model to Name
    EXEC sp_rename 'VehicleModels.Model', 'Name', 'COLUMN';
    PRINT 'Renamed Model column to Name';
END

-- Add SeatingCapacity column (rename from TotalSeats) if TotalSeats exists and SeatingCapacity doesn't
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'TotalSeats')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'SeatingCapacity')
BEGIN
    -- Rename TotalSeats to SeatingCapacity
    EXEC sp_rename 'VehicleModels.TotalSeats', 'SeatingCapacity', 'COLUMN';
    PRINT 'Renamed TotalSeats column to SeatingCapacity';
END

-- Add Features column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'Features')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] ADD [Features] NVARCHAR(MAX) NULL;
    PRINT 'Added Features column';
END

-- Add Description column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'Description')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] ADD [Description] NVARCHAR(1000) NULL;
    PRINT 'Added Description column';
END

-- Add UpdatedAt column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] ADD [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt column';
END

-- Add SeatingLayout column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'SeatingLayout')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] ADD [SeatingLayout] NVARCHAR(MAX) NULL;
    PRINT 'Added SeatingLayout column';
END

-- Drop BasePrice column if exists (no longer needed)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'BasePrice')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] DROP COLUMN [BasePrice];
    PRINT 'Dropped BasePrice column';
END

-- Drop PricePerKm column if exists (no longer needed)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[VehicleModels]') AND name = 'PricePerKm')
BEGIN
    ALTER TABLE [dbo].[VehicleModels] DROP COLUMN [PricePerKm];
    PRINT 'Dropped PricePerKm column';
END

PRINT 'VehicleModels table update completed!';
GO

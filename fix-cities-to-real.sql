-- Fix Cities table Latitude and Longitude to use REAL (System.Single/float in C#)
-- REAL is a 4-byte floating point type that maps to System.Single
-- FLOAT defaults to FLOAT(53) which is 8-byte double precision (System.Double)

USE RideSharingDb;
GO

-- Change Latitude and Longitude to REAL type
ALTER TABLE Cities ALTER COLUMN Latitude REAL NULL;
ALTER TABLE Cities ALTER COLUMN Longitude REAL NULL;
GO

-- Verify the change
SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME='Cities' AND COLUMN_NAME IN ('Latitude', 'Longitude');
GO

-- Show sample data to verify no data loss
SELECT TOP 5 Id, Name, Latitude, Longitude FROM Cities WHERE IsActive=1 ORDER BY Name;
GO

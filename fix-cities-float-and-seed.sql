-- Fix Cities table Latitude/Longitude data type and seed data
USE RideSharingDb;
GO

-- Step 1: Change Latitude and Longitude back to plain FLOAT (not with precision/scale)
-- This fixes the InvalidCastException: Unable to cast System.Double to System.Single
ALTER TABLE Cities ALTER COLUMN Latitude FLOAT NULL;
GO

ALTER TABLE Cities ALTER COLUMN Longitude FLOAT NULL;
GO

PRINT 'Fixed Latitude and Longitude column types';
GO

-- Step 2: Delete existing city data (except if you want to keep it)
-- DELETE FROM Cities;
-- GO

-- Step 3: Seed Maharashtra Gadchiroli District Cities
IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111101')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111101', 'Gadchiroli', 'Maharashtra', 'Gadchiroli', '442605', 20.1809, 80.0027, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111102')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111102', 'Aheri', 'Maharashtra', 'Gadchiroli', '441701', 19.2856, 80.7328, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111103')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111103', 'Allapalli', 'Maharashtra', 'Gadchiroli', '441702', 19.4472, 80.0572, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111104')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111104', 'Armori', 'Maharashtra', 'Gadchiroli', '441208', 20.7450, 80.0450, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111105')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111105', 'Bhamragad', 'Maharashtra', 'Gadchiroli', '441902', 19.1142, 80.3117, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111106')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111106', 'Chamorshi', 'Maharashtra', 'Gadchiroli', '442603', 20.0447, 79.8547, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111107')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111107', 'Desaiganj', 'Maharashtra', 'Gadchiroli', '441220', 20.2833, 80.1500, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111108')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111108', 'Dhanora', 'Maharashtra', 'Gadchiroli', '442605', 19.9194, 79.7811, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111109')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111109', 'Etapalli', 'Maharashtra', 'Gadchiroli', '441903', 19.3119, 80.5278, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111110')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111110', 'Korchi', 'Maharashtra', 'Gadchiroli', '441901', 19.4167, 80.6167, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111111')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Kurkheda', 'Maharashtra', 'Gadchiroli', '441209', 20.5089, 80.1917, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111112')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111112', 'Mulchera', 'Maharashtra', 'Gadchiroli', '441210', 20.4333, 80.2833, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '11111111-1111-1111-1111-111111111113')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('11111111-1111-1111-1111-111111111113', 'Sironcha', 'Maharashtra', 'Gadchiroli', '441104', 18.8314, 81.0439, 1, GETUTCDATE(), GETUTCDATE());
END
GO

-- Add more cities from other popular districts
IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222201')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222201', 'Nagpur', 'Maharashtra', 'Nagpur', '440001', 21.1458, 79.0882, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222202')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222202', 'Mumbai', 'Maharashtra', 'Mumbai City', '400001', 19.0760, 72.8777, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222203')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222203', 'Pune', 'Maharashtra', 'Pune', '411001', 18.5204, 73.8567, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222204')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222204', 'Chandrapur', 'Maharashtra', 'Chandrapur', '442401', 19.9615, 79.2961, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222205')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222205', 'Gondia', 'Maharashtra', 'Gondia', '441601', 21.4577, 80.1942, 1, GETUTCDATE(), GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = '22222222-2222-2222-2222-222222222206')
BEGIN
    INSERT INTO Cities (Id, Name, State, District, Pincode, Latitude, Longitude, IsActive, CreatedAt, UpdatedAt)
    VALUES 
    ('22222222-2222-2222-2222-222222222206', 'Bhandara', 'Maharashtra', 'Bhandara', '441904', 21.1704, 79.6527, 1, GETUTCDATE(), GETUTCDATE());
END
GO

PRINT 'Cities seeded successfully!';
GO

-- Verify the data
SELECT 
    State,
    District,
    COUNT(*) as CityCount
FROM Cities
WHERE IsActive = 1
GROUP BY State, District
ORDER BY State, District;
GO

PRINT 'Total active cities:';
SELECT COUNT(*) as TotalCities FROM Cities WHERE IsActive = 1;
GO

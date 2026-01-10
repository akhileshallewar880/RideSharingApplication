-- Seed Cities Data for VanYatra Rural Ride Booking
-- This populates the Cities table with sample data for Maharashtra districts

USE RideSharingDb;
GO

-- Insert major cities/districts in Maharashtra
INSERT INTO Cities (Id, Name, State, Country, District, Latitude, Longitude, Pincode, SubLocation, IsActive, CreatedAt, UpdatedAt)
VALUES
-- Vidarbha Region (Rural focus area)
(NEWID(), 'Allapalli', 'Maharashtra', 'India', 'Gadchiroli', 19.6500, 79.8833, '442707', 'Main Road', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Gadchiroli', 'Maharashtra', 'India', 'Gadchiroli', 20.1809, 80.0111, '442605', 'City Center', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Chamorshi', 'Maharashtra', 'India', 'Gadchiroli', 20.0167, 79.8167, '442603', 'Market Area', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Desaiganj', 'Maharashtra', 'India', 'Gadchiroli', 20.8167, 80.0500, '442606', 'Town Center', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Armori', 'Maharashtra', 'India', 'Gadchiroli', 20.5000, 80.0333, '441208', 'Bus Stand', 1, GETUTCDATE(), GETUTCDATE()),

-- Gondiya District
(NEWID(), 'Gondia', 'Maharashtra', 'India', 'Gondia', 21.4500, 80.1833, '441601', 'Railway Station', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tirora', 'Maharashtra', 'India', 'Gondia', 21.6833, 79.6167, '441911', 'Market', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Goregaon', 'Maharashtra', 'India', 'Gondia', 21.5667, 80.0333, '441801', 'City Area', 1, GETUTCDATE(), GETUTCDATE()),

-- Chandrapur District
(NEWID(), 'Chandrapur', 'Maharashtra', 'India', 'Chandrapur', 19.9512, 79.2961, '442401', 'Station Road', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Warora', 'Maharashtra', 'India', 'Chandrapur', 20.2333, 79.0000, '442907', 'Main Market', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Bhadravati', 'Maharashtra', 'India', 'Chandrapur', 20.1167, 79.6333, '442902', 'Town', 1, GETUTCDATE(), GETUTCDATE()),

-- Nagpur District (Urban anchor)
(NEWID(), 'Nagpur', 'Maharashtra', 'India', 'Nagpur', 21.1458, 79.0882, '440001', 'Sitabuldi', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Kamptee', 'Maharashtra', 'India', 'Nagpur', 21.2167, 79.2000, '441001', 'Cantonment', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Ramtek', 'Maharashtra', 'India', 'Nagpur', 21.4000, 79.3167, '441106', 'Temple Area', 1, GETUTCDATE(), GETUTCDATE()),

-- Bhandara District
(NEWID(), 'Bhandara', 'Maharashtra', 'India', 'Bhandara', 21.1700, 79.6533, '441904', 'Main Road', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tumsar', 'Maharashtra', 'India', 'Bhandara', 21.3833, 79.7333, '441912', 'Market', 1, GETUTCDATE(), GETUTCDATE()),

-- Yavatmal District
(NEWID(), 'Yavatmal', 'Maharashtra', 'India', 'Yavatmal', 20.3886, 78.1302, '445001', 'City Center', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Wani', 'Maharashtra', 'India', 'Yavatmal', 20.0833, 78.9500, '445304', 'Town', 1, GETUTCDATE(), GETUTCDATE()),

-- Wardha District
(NEWID(), 'Wardha', 'Maharashtra', 'India', 'Wardha', 20.7453, 78.5975, '442001', 'Main Station', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Hinganghat', 'Maharashtra', 'India', 'Wardha', 20.5500, 78.8333, '442301', 'Market', 1, GETUTCDATE(), GETUTCDATE()),

-- Amravati District
(NEWID(), 'Amravati', 'Maharashtra', 'India', 'Amravati', 20.9333, 77.7500, '444601', 'Railway Station', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Achalpur', 'Maharashtra', 'India', 'Amravati', 21.2667, 77.5167, '444806', 'City', 1, GETUTCDATE(), GETUTCDATE()),

-- Washim District
(NEWID(), 'Washim', 'Maharashtra', 'India', 'Washim', 20.1167, 77.1333, '444505', 'Town Center', 1, GETUTCDATE(), GETUTCDATE()),

-- Akola District
(NEWID(), 'Akola', 'Maharashtra', 'India', 'Akola', 20.7002, 77.0082, '444001', 'Station Road', 1, GETUTCDATE(), GETUTCDATE()),

-- Buldhana District
(NEWID(), 'Buldhana', 'Maharashtra', 'India', 'Buldhana', 20.5333, 76.1833, '443001', 'Main Market', 1, GETUTCDATE(), GETUTCDATE());

-- Verify the data
SELECT COUNT(*) AS TotalCities FROM Cities;
SELECT TOP 10 Name, District, State, Latitude, Longitude FROM Cities ORDER BY Name;

PRINT 'Successfully seeded ' + CAST(@@ROWCOUNT AS VARCHAR) + ' cities in the database';

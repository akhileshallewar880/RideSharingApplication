-- Seed data for popular vehicle models
-- Run this script after running the migration

-- Cars
INSERT INTO VehicleModels (Id, Name, Brand, Type, SeatingCapacity, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Dzire', 'Maruti Suzuki', 'car', 4, NULL, '["AC", "Music System", "GPS", "USB Charging"]', 'Comfortable sedan perfect for city rides and intercity travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Ertiga', 'Maruti Suzuki', 'car', 7, NULL, '["AC", "Music System", "GPS", "USB Charging", "Spacious"]', '7-seater compact MPV ideal for families and groups', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Etios', 'Toyota', 'car', 5, NULL, '["AC", "Music System", "USB Charging"]', 'Reliable and fuel-efficient sedan', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'City', 'Honda', 'car', 5, NULL, '["AC", "Music System", "GPS", "USB Charging", "Premium Interior"]', 'Premium sedan with excellent comfort', 1, GETUTCDATE(), GETUTCDATE());

-- SUVs
INSERT INTO VehicleModels (Id, Name, Brand, Type, SeatingCapacity, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Innova Crysta', 'Toyota', 'suv', 7, NULL, '["AC", "Music System", "GPS", "USB Charging", "Push Button Start", "Spacious", "Premium Interior"]', 'Premium 7-seater SUV with superior comfort and space', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Scorpio', 'Mahindra', 'suv', 7, NULL, '["AC", "Music System", "GPS", "USB Charging", "Rugged Build"]', 'Rugged 7-seater SUV suitable for all terrains', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Xylo', 'Mahindra', 'suv', 7, NULL, '["AC", "Music System", "GPS", "USB Charging", "Spacious"]', 'Spacious 7-seater MPV for long journeys', 1, GETUTCDATE(), GETUTCDATE());

-- Vans
INSERT INTO VehicleModels (Id, Name, Brand, Type, SeatingCapacity, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Traveller', 'Force', 'van', 13, NULL, '["AC", "Music System", "Large Luggage Space", "Comfortable Seating"]', '13-seater tempo traveller for group travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Winger', 'Tata', 'van', 13, NULL, '["AC", "Music System", "Large Luggage Space", "Comfortable Seating"]', '13-seater van for comfortable group travel', 1, GETUTCDATE(), GETUTCDATE());

-- Buses
INSERT INTO VehicleModels (Id, Name, Brand, Type, SeatingCapacity, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Starbus', 'Tata', 'bus', 32, NULL, '["AC", "Music System", "Large Luggage Storage", "Comfortable Seating", "Reading Lights"]', '32-seater luxury bus for intercity travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Viking', 'Ashok Leyland', 'bus', 40, NULL, '["AC", "Music System", "Large Luggage Storage", "Comfortable Seating", "Reading Lights", "Reclining Seats"]', '40-seater luxury coach for long-distance travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Ultra', 'Tata', 'bus', 26, NULL, '["AC", "Music System", "Large Luggage Storage", "Comfortable Seating"]', '26-seater mini bus for group tours', 1, GETUTCDATE(), GETUTCDATE());

GO

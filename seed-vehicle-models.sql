-- Seed Vehicle Models for VanYatra Rural Ride Booking
-- Run this script to populate the VehicleModels table with common vehicle types

USE RideSharingDb;
GO

-- Clear existing data (optional - comment out if you want to keep existing data)
-- DELETE FROM VehicleModels;
-- GO

-- Auto Rickshaw Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Bajaj RE Auto', 'Bajaj', 'RE', 'auto', 3, 3, '{"layout":"1-2","rows":2,"seats":[{"id":"D","row":1,"position":"center"},{"id":"P1","row":2,"position":"left"},{"id":"P2","row":2,"position":"right"}]}', 30.00, 8.00, NULL, '["Comfortable seating","Weather protection","Luggage space"]', 'Standard 3-seater auto rickshaw for short distance travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Piaggio Ape Auto', 'Piaggio', 'Ape', 'auto', 3, 3, '{"layout":"1-2","rows":2,"seats":[{"id":"D","row":1,"position":"center"},{"id":"P1","row":2,"position":"left"},{"id":"P2","row":2,"position":"right"}]}', 30.00, 8.00, NULL, '["Fuel efficient","Compact size","Easy maneuverability"]', 'Compact auto rickshaw ideal for narrow roads', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'TVS King Auto', 'TVS', 'King', 'auto', 3, 3, '{"layout":"1-2","rows":2,"seats":[{"id":"D","row":1,"position":"center"},{"id":"P1","row":2,"position":"left"},{"id":"P2","row":2,"position":"right"}]}', 30.00, 8.00, NULL, '["Sturdy build","Good suspension","Reliable engine"]', 'Robust auto rickshaw for rural terrain', 1, GETUTCDATE(), GETUTCDATE());

-- Bike/Motorcycle Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Hero Splendor Plus', 'Hero', 'Splendor Plus', 'bike', 2, 2, '{"layout":"2","rows":1,"seats":[{"id":"D","row":1,"position":"front"},{"id":"P1","row":1,"position":"back"}]}', 20.00, 5.00, NULL, '["Fuel efficient","Comfortable ride","Easy maintenance"]', 'Popular commuter bike for single passenger rides', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Bajaj Pulsar 150', 'Bajaj', 'Pulsar 150', 'bike', 2, 2, '{"layout":"2","rows":1,"seats":[{"id":"D","row":1,"position":"front"},{"id":"P1","row":1,"position":"back"}]}', 25.00, 6.00, NULL, '["Powerful engine","Sporty design","Good mileage"]', 'Sporty bike for quick intercity rides', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Honda Activa Scooter', 'Honda', 'Activa', 'bike', 2, 2, '{"layout":"2","rows":1,"seats":[{"id":"D","row":1,"position":"front"},{"id":"P1","row":1,"position":"back"}]}', 20.00, 5.00, NULL, '["Smooth ride","Easy handling","Storage space"]', 'Comfortable scooter for local commutes', 1, GETUTCDATE(), GETUTCDATE());

-- Car Models (Sedan)
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Maruti Suzuki Swift Dzire', 'Maruti Suzuki', 'Swift Dzire', 'car', 4, 4, '{"layout":"2-2","rows":2,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"right"}]}', 50.00, 12.00, NULL, '["AC","Music system","Comfortable seats","Boot space"]', 'Comfortable sedan for family and group travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Hyundai Xcent', 'Hyundai', 'Xcent', 'car', 4, 4, '{"layout":"2-2","rows":2,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"right"}]}', 50.00, 12.00, NULL, '["AC","Good mileage","Spacious interior","Modern features"]', 'Modern sedan with excellent features', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tata Indigo', 'Tata', 'Indigo', 'car', 4, 4, '{"layout":"2-2","rows":2,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"right"}]}', 45.00, 11.00, NULL, '["Spacious cabin","Reliable","Good for long distance"]', 'Reliable sedan for intercity travel', 1, GETUTCDATE(), GETUTCDATE());

-- SUV Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Mahindra Bolero', 'Mahindra', 'Bolero', 'suv', 7, 7, '{"layout":"2-3-2","rows":3,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"right"}]}', 80.00, 15.00, NULL, '["7 seater","Rugged build","High ground clearance","Good for rough roads"]', 'Sturdy SUV perfect for rural roads and group travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tata Safari', 'Tata', 'Safari', 'suv', 7, 7, '{"layout":"2-3-2","rows":3,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"right"}]}', 90.00, 16.00, NULL, '["Premium interiors","7 seater","AC","Powerful engine"]', 'Premium SUV for comfortable long-distance travel', 1, GETUTCDATE(), GETUTCDATE());

-- Shared Van Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Maruti Suzuki Eeco', 'Maruti Suzuki', 'Eeco', 'van', 7, 7, '{"layout":"2-3-2","rows":3,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"right"}]}', 60.00, 10.00, NULL, '["Spacious","Affordable","Good mileage","Easy maintenance"]', 'Popular van for shared rides and group bookings', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tata Winger', 'Tata', 'Winger', 'van', 13, 13, '{"layout":"2-3-3-3-2","rows":5,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"center"},{"id":"P7","row":3,"position":"right"},{"id":"P8","row":4,"position":"left"},{"id":"P9","row":4,"position":"center"},{"id":"P10","row":4,"position":"right"},{"id":"P11","row":5,"position":"left"},{"id":"P12","row":5,"position":"right"}]}', 100.00, 12.00, NULL, '["13 seater","AC","Comfortable seats","Luggage space"]', 'Large van for group travel and tours', 1, GETUTCDATE(), GETUTCDATE());

-- Mini Bus Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Force Traveller 17 Seater', 'Force', 'Traveller', 'bus', 17, 17, '{"layout":"2-3-3-3-3-3","rows":6,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"center"},{"id":"P7","row":3,"position":"right"},{"id":"P8","row":4,"position":"left"},{"id":"P9","row":4,"position":"center"},{"id":"P10","row":4,"position":"right"},{"id":"P11","row":5,"position":"left"},{"id":"P12","row":5,"position":"center"},{"id":"P13","row":5,"position":"right"},{"id":"P14","row":6,"position":"left"},{"id":"P15","row":6,"position":"center"},{"id":"P16","row":6,"position":"right"}]}', 150.00, 15.00, NULL, '["17 seater","Spacious","Push-back seats","Overhead storage"]', 'Mini bus ideal for group tours and corporate travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Tata LP 410 Mini Bus', 'Tata', 'LP 410', 'bus', 20, 20, '{"layout":"2-3-3-3-3-3-3","rows":7,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"center"},{"id":"P7","row":3,"position":"right"},{"id":"P8","row":4,"position":"left"},{"id":"P9","row":4,"position":"center"},{"id":"P10","row":4,"position":"right"},{"id":"P11","row":5,"position":"left"},{"id":"P12","row":5,"position":"center"},{"id":"P13","row":5,"position":"right"},{"id":"P14","row":6,"position":"left"},{"id":"P15","row":6,"position":"center"},{"id":"P16","row":6,"position":"right"},{"id":"P17","row":7,"position":"left"},{"id":"P18","row":7,"position":"center"},{"id":"P19","row":7,"position":"right"}]}', 180.00, 16.00, NULL, '["20 seater","Durable","Good suspension","Reliable engine"]', 'Durable mini bus for rural routes and schools', 1, GETUTCDATE(), GETUTCDATE());

-- Tempo Traveller Models
INSERT INTO VehicleModels (Id, Name, Brand, Model, Type, SeatingCapacity, TotalSeats, SeatingLayout, BasePrice, PricePerKm, ImageUrl, Features, Description, IsActive, CreatedAt, UpdatedAt)
VALUES 
(NEWID(), 'Force Tempo Traveller 12 Seater', 'Force', 'Tempo Traveller', 'tempo_traveller', 12, 12, '{"layout":"2-2-2-2-2-2","rows":6,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"right"},{"id":"P4","row":3,"position":"left"},{"id":"P5","row":3,"position":"right"},{"id":"P6","row":4,"position":"left"},{"id":"P7","row":4,"position":"right"},{"id":"P8","row":5,"position":"left"},{"id":"P9","row":5,"position":"right"},{"id":"P10","row":6,"position":"left"},{"id":"P11","row":6,"position":"right"}]}', 120.00, 14.00, NULL, '["12 seater","AC","Push-back seats","Music system","Luggage carrier"]', 'Luxury tempo traveller for comfortable group travel', 1, GETUTCDATE(), GETUTCDATE()),
(NEWID(), 'Force Tempo Traveller 15 Seater', 'Force', 'Tempo Traveller', 'tempo_traveller', 15, 15, '{"layout":"2-3-3-3-2-2","rows":6,"seats":[{"id":"D","row":1,"position":"left"},{"id":"P1","row":1,"position":"right"},{"id":"P2","row":2,"position":"left"},{"id":"P3","row":2,"position":"center"},{"id":"P4","row":2,"position":"right"},{"id":"P5","row":3,"position":"left"},{"id":"P6","row":3,"position":"center"},{"id":"P7","row":3,"position":"right"},{"id":"P8","row":4,"position":"left"},{"id":"P9","row":4,"position":"center"},{"id":"P10","row":4,"position":"right"},{"id":"P11","row":5,"position":"left"},{"id":"P12","row":5,"position":"right"},{"id":"P13","row":6,"position":"left"},{"id":"P14","row":6,"position":"right"}]}', 140.00, 15.00, NULL, '["15 seater","AC","Reclining seats","LED lights","First aid kit"]', 'Premium tempo traveller for long-distance travel', 1, GETUTCDATE(), GETUTCDATE());

GO

-- Verify the data
SELECT 
    Type,
    COUNT(*) as VehicleCount,
    MIN(BasePrice) as MinBasePrice,
    MAX(BasePrice) as MaxBasePrice,
    MIN(PricePerKm) as MinPricePerKm,
    MAX(PricePerKm) as MaxPricePerKm
FROM VehicleModels
WHERE IsActive = 1
GROUP BY Type
ORDER BY Type;

GO

PRINT 'Vehicle models seeded successfully!';
PRINT 'Total vehicle models: ';
SELECT COUNT(*) as TotalModels FROM VehicleModels WHERE IsActive = 1;

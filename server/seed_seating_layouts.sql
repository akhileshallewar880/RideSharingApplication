-- Seed Seating Layouts for Vehicle Models
-- Run this SQL script to add seating arrangements to your existing vehicle models

-- 1. Sedan (4 Seater) - 1-3 layout (front 1 passenger + driver, back 3 seats)
UPDATE VehicleModels 
SET SeatingLayout = '{
  "layout": "1-3",
  "rows": 2,
  "seats": [
    {"id": "P1", "row": 1, "position": "right"},
    {"id": "P2", "row": 2, "position": "left"},
    {"id": "P3", "row": 2, "position": "center"},
    {"id": "P4", "row": 2, "position": "right"}
  ]
}'
WHERE SeatingCapacity = 4 OR Type = 'sedan' OR Name LIKE '%Swift%' OR Name LIKE '%i20%';

-- 2. SUV/Ertiga (7 Seater) - 1-3-2 layout (front 1 passenger + driver, middle 3 seats, back 2 seats)
UPDATE VehicleModels 
SET SeatingLayout = '{
  "layout": "1-3-2",
  "rows": 3,
  "seats": [
    {"id": "P1", "row": 1, "position": "left"},
    {"id": "P2", "row": 2, "position": "left"},
    {"id": "P3", "row": 2, "position": "center"},
    {"id": "P4", "row": 2, "position": "right"},
    {"id": "P5", "row": 3, "position": "left"},
    {"id": "P6", "row": 3, "position": "right"}
  ]
}'
WHERE SeatingCapacity = 7 OR Type = 'suv' OR Name LIKE '%Ertiga%' OR Name LIKE '%Innova%' OR Name LIKE '%XUV%';

-- 3. Bolero/Van (8 Seater) - 1-3-4 layout (front 1 passenger + driver, middle 3 seats, back 4 seats)
UPDATE VehicleModels 
SET SeatingLayout = '{
  "layout": "1-3-4",
  "rows": 3,
  "seats": [
    {"id": "P1", "row": 1, "position": "right"},
    {"id": "P2", "row": 2, "position": "left"},
    {"id": "P3", "row": 2, "position": "center"},
    {"id": "P4", "row": 2, "position": "right"},
    {"id": "P5", "row": 3, "position": "left"},
    {"id": "P6", "row": 3, "position": "center"},
    {"id": "P7", "row": 3, "position": "center"},
    {"id": "P8", "row": 3, "position": "right"}
  ]
}'
WHERE SeatingCapacity >= 8 AND SeatingCapacity <= 10 OR Type = 'van' OR Name LIKE '%Bolero%' OR Name LIKE '%Marazzo%';

-- 4. Tempo Traveller (11 Seater) - 1-2-2-2-2-2 layout (front 1 passenger + driver, then 5 rows of 2 seats)
UPDATE VehicleModels 
SET SeatingLayout = '{
  "layout": "1-2-2-2-2-2",
  "rows": 6,
  "seats": [
    {"id": "P1", "row": 1, "position": "right"},
    {"id": "P2", "row": 2, "position": "left"},
    {"id": "P3", "row": 2, "position": "right"},
    {"id": "P4", "row": 3, "position": "left"},
    {"id": "P5", "row": 3, "position": "right"},
    {"id": "P6", "row": 4, "position": "left"},
    {"id": "P7", "row": 4, "position": "right"},
    {"id": "P8", "row": 5, "position": "left"},
    {"id": "P9", "row": 5, "position": "right"},
    {"id": "P10", "row": 6, "position": "left"},
    {"id": "P11", "row": 6, "position": "right"}
  ]
}'
WHERE SeatingCapacity >= 11 AND SeatingCapacity <= 14 OR Type = 'tempo' OR Name LIKE '%Tempo%' OR Name LIKE '%Traveller%';

-- 5. Mini Bus (17 Seater) - 1-2-2-2-2-2-2-2-2 layout (front 1 passenger + driver, then 8 rows of 2 seats)
UPDATE VehicleModels 
SET SeatingLayout = '{
  "layout": "1-2-2-2-2-2-2-2-2",
  "rows": 9,
  "seats": [
    {"id": "P1", "row": 1, "position": "right"},
    {"id": "P2", "row": 2, "position": "left"},
    {"id": "P3", "row": 2, "position": "right"},
    {"id": "P4", "row": 3, "position": "left"},
    {"id": "P5", "row": 3, "position": "right"},
    {"id": "P6", "row": 4, "position": "left"},
    {"id": "P7", "row": 4, "position": "right"},
    {"id": "P8", "row": 5, "position": "left"},
    {"id": "P9", "row": 5, "position": "right"},
    {"id": "P10", "row": 6, "position": "left"},
    {"id": "P11", "row": 6, "position": "right"},
    {"id": "P12", "row": 7, "position": "left"},
    {"id": "P13", "row": 7, "position": "right"},
    {"id": "P14", "row": 8, "position": "left"},
    {"id": "P15", "row": 8, "position": "right"},
    {"id": "P16", "row": 9, "position": "left"},
    {"id": "P17", "row": 9, "position": "right"}
  ]
}'
WHERE SeatingCapacity >= 17 AND SeatingCapacity <= 20 OR Type = 'bus' OR Name LIKE '%Bus%';

-- Verify the update
SELECT 
    Name,
    Brand,
    Type,
    SeatingCapacity,
    CASE 
        WHEN SeatingLayout IS NOT NULL THEN 'Yes ✓'
        ELSE 'No ✗'
    END as HasSeatingLayout
FROM VehicleModels
ORDER BY SeatingCapacity;

-- Show sample seating layouts
SELECT 
    Name,
    SeatingCapacity,
    JSON_VALUE(SeatingLayout, '$.layout') as LayoutType,
    JSON_VALUE(SeatingLayout, '$.rows') as Rows
FROM VehicleModels
WHERE SeatingLayout IS NOT NULL;

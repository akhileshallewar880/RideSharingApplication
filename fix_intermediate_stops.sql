-- Fix rides that have SegmentPrices but no IntermediateStops
-- This extracts intermediate stops from SegmentPrices JSON

-- First, let's check the current state
SELECT 
    Id,
    RideNumber,
    PickupLocation,
    DropoffLocation,
    IntermediateStops,
    SegmentPrices,
    Status
FROM Rides 
WHERE SegmentPrices IS NOT NULL 
  AND SegmentPrices != '[]'
  AND (IntermediateStops IS NULL OR IntermediateStops = '' OR IntermediateStops = '[]');

-- For the specific ride mentioned in the logs:
SELECT 
    Id,
    RideNumber,
    PickupLocation,
    DropoffLocation,
    IntermediateStops,
    SegmentPrices,
    Status,
    TravelDate,
    DepartureTime
FROM Rides 
WHERE Id = 'dde35bcd-4924-446f-b1ad-3917db0b7716';

-- Manual fix for the specific ride (if SegmentPrices contains Gondpipri)
-- You'll need to extract the intermediate locations from SegmentPrices
-- and construct the IntermediateStops JSON array

-- Example fix (adjust based on actual SegmentPrices content):
-- UPDATE Rides
-- SET IntermediateStops = '["Gondpipri, Maharashtra"]'
-- WHERE Id = 'dde35bcd-4924-446f-b1ad-3917db0b7716';

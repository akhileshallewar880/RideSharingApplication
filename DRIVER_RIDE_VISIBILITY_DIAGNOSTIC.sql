-- ==========================================
-- DRIVER RIDE VISIBILITY DIAGNOSTIC QUERIES
-- ==========================================
-- Use these queries to diagnose why scheduled rides aren't showing in the driver app

-- 1. VERIFY DRIVER-USER RELATIONSHIP
-- Replace '+919876543210' with the actual driver's phone number
-- This shows if the driver account exists and is properly linked to a user
SELECT 
    u.Id as UserId,
    u.PhoneNumber,
    u.Role,
    u.IsActive as UserIsActive,
    d.Id as DriverId,
    d.UserId as DriverUserId,
    d.IsVerified as DriverIsVerified,
    d.IsAvailable as DriverIsAvailable,
    up.Name as DriverName,
    d.LicenseNumber,
    d.TotalRides,
    d.CreatedAt as DriverCreatedAt
FROM 
    Users u
    INNER JOIN Drivers d ON u.Id = d.UserId
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE 
    u.PhoneNumber = '+919876543210' -- Replace with actual phone number
    AND u.Role = 'driver';

-- 2. VERIFY RIDES SCHEDULED FOR A SPECIFIC DRIVER
-- Replace the DriverId GUID with the actual DriverId from query #1
-- This shows all rides assigned to this driver
SELECT 
    r.Id as RideId,
    r.RideNumber,
    r.DriverId,
    r.PickupLocation,
    r.DropoffLocation,
    r.TravelDate,
    r.DepartureTime,
    r.TotalSeats,
    r.BookedSeats,
    r.PricePerSeat,
    r.Status,
    r.CreatedAt,
    r.IsReturnTrip,
    r.AdminNotes,
    d.Id as DriverId,
    u.PhoneNumber as DriverPhone,
    up.Name as DriverName
FROM 
    Rides r
    INNER JOIN Drivers d ON r.DriverId = d.Id
    INNER JOIN Users u ON d.UserId = u.Id
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE 
    r.DriverId = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -- Replace with actual DriverId
    AND r.Status IN ('scheduled', 'active')
ORDER BY 
    r.TravelDate, r.DepartureTime;

-- 3. VERIFY ALL SCHEDULED RIDES WITH DRIVER INFO
-- This shows all scheduled rides in the system with their driver details
SELECT 
    r.Id as RideId,
    r.RideNumber,
    r.DriverId,
    d.UserId as DriverUserId,
    u.PhoneNumber as DriverPhone,
    up.Name as DriverName,
    r.PickupLocation,
    r.DropoffLocation,
    r.TravelDate,
    r.DepartureTime,
    r.Status,
    r.CreatedAt,
    r.AdminNotes
FROM 
    Rides r
    INNER JOIN Drivers d ON r.DriverId = d.Id
    INNER JOIN Users u ON d.UserId = u.Id
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE 
    r.Status IN ('scheduled', 'active')
    AND r.TravelDate >= CAST(GETDATE() AS DATE)
ORDER BY 
    r.TravelDate, r.DepartureTime;

-- 4. VERIFY RECENT ADMIN-SCHEDULED RIDES
-- This shows rides scheduled by admin in the last 24 hours
SELECT 
    r.Id as RideId,
    r.RideNumber,
    r.DriverId,
    d.UserId as DriverUserId,
    u.PhoneNumber as DriverPhone,
    up.Name as DriverName,
    r.PickupLocation,
    r.DropoffLocation,
    r.TravelDate,
    r.DepartureTime,
    r.Status,
    r.AdminNotes,
    r.CreatedAt,
    DATEDIFF(MINUTE, r.CreatedAt, GETUTCDATE()) as MinutesAgo
FROM 
    Rides r
    INNER JOIN Drivers d ON r.DriverId = d.Id
    INNER JOIN Users u ON d.UserId = u.Id
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
WHERE 
    r.AdminNotes IS NOT NULL
    AND r.CreatedAt >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY 
    r.CreatedAt DESC;

-- 5. CHECK IF DRIVER HAS MULTIPLE USER ACCOUNTS (SHOULD BE UNIQUE)
-- This checks for duplicate driver registrations which could cause issues
SELECT 
    u.PhoneNumber,
    COUNT(d.Id) as DriverAccountCount,
    STRING_AGG(CAST(d.Id AS NVARCHAR(36)), ', ') as DriverIds
FROM 
    Users u
    INNER JOIN Drivers d ON u.Id = d.UserId
WHERE 
    u.Role = 'driver'
GROUP BY 
    u.PhoneNumber
HAVING 
    COUNT(d.Id) > 1;

-- 6. VERIFY DRIVER HAS A VEHICLE (REQUIRED FOR SCHEDULING)
-- Replace the DriverId with actual value
SELECT 
    d.Id as DriverId,
    u.PhoneNumber as DriverPhone,
    up.Name as DriverName,
    v.Id as VehicleId,
    v.RegistrationNumber,
    v.VehicleType,
    v.IsActive as VehicleIsActive,
    vm.Name as VehicleModelName,
    vm.SeatingCapacity
FROM 
    Drivers d
    INNER JOIN Users u ON d.UserId = u.Id
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
    LEFT JOIN Vehicles v ON d.Id = v.DriverId AND v.IsActive = 1
    LEFT JOIN VehicleModels vm ON v.VehicleModelId = vm.Id
WHERE 
    d.Id = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'; -- Replace with actual DriverId

-- 7. COMPREHENSIVE DRIVER LOOKUP BY PHONE NUMBER
-- This is the most comprehensive query - Replace the phone number
-- It shows the complete relationship chain: User -> Driver -> Rides
WITH DriverInfo AS (
    SELECT 
        u.Id as UserId,
        u.PhoneNumber,
        u.Role,
        u.IsActive as UserIsActive,
        d.Id as DriverId,
        d.IsVerified,
        d.IsAvailable,
        up.Name as DriverName,
        d.LicenseNumber
    FROM 
        Users u
        INNER JOIN Drivers d ON u.Id = d.UserId
        LEFT JOIN UserProfiles up ON u.Id = up.UserId
    WHERE 
        u.PhoneNumber = '+919876543210' -- Replace with actual phone number
        AND u.Role = 'driver'
)
SELECT 
    di.UserId,
    di.PhoneNumber,
    di.DriverId,
    di.DriverName,
    di.IsVerified,
    di.IsAvailable,
    COUNT(r.Id) as TotalScheduledRides,
    STRING_AGG(CONCAT(r.RideNumber, ' (', r.Status, ')'), ', ') as RidesList
FROM 
    DriverInfo di
    LEFT JOIN Rides r ON di.DriverId = r.DriverId AND r.Status IN ('scheduled', 'active')
GROUP BY 
    di.UserId, di.PhoneNumber, di.DriverId, di.DriverName, di.IsVerified, di.IsAvailable;

-- 8. CHECK TOKEN CLAIMS (IF AVAILABLE FROM JWT)
-- If you can extract the userId from the JWT token, use this to verify
-- Replace the UserId with the value from the JWT token's userId claim
SELECT 
    u.Id as UserId,
    u.PhoneNumber,
    u.Role,
    d.Id as DriverId,
    up.Name as DriverName,
    COUNT(r.Id) as ScheduledRidesCount
FROM 
    Users u
    LEFT JOIN Drivers d ON u.Id = d.UserId
    LEFT JOIN UserProfiles up ON u.Id = up.UserId
    LEFT JOIN Rides r ON d.Id = r.DriverId AND r.Status IN ('scheduled', 'active')
WHERE 
    u.Id = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -- Replace with userId from JWT
GROUP BY 
    u.Id, u.PhoneNumber, u.Role, d.Id, up.Name;

-- ==========================================
-- TROUBLESHOOTING STEPS
-- ==========================================
-- 1. Run Query #1 with the driver's phone number to get the DriverId and UserId
-- 2. Run Query #2 with the DriverId to see all rides assigned to that driver
-- 3. If Query #1 returns no results, the driver account doesn't exist or isn't properly linked
-- 4. If Query #2 returns no results but Query #1 worked, no rides are scheduled for that driver
-- 5. Run Query #5 to check if there are duplicate driver accounts
-- 6. Run Query #6 to verify the driver has a vehicle (required for scheduling)
-- 7. Run Query #3 to see all scheduled rides and compare phone numbers
-- 8. Check the backend logs when the driver logs in to see the UserId and DriverId being used

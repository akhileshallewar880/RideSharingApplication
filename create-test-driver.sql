-- Create test driver profile for Firebase test phone number
-- This script creates a driver record for the test phone number user

-- First, find the user with the test phone number
-- Replace 'YOUR_TEST_PHONE_NUMBER' with actual test number (e.g., '+919999999999')

DECLARE @TestPhoneNumber NVARCHAR(20) = '+919999999999'; -- UPDATE THIS with your test number
DECLARE @UserId UNIQUEIDENTIFIER;
DECLARE @DriverId UNIQUEIDENTIFIER = NEWID();
DECLARE @LicenseNumber NVARCHAR(50) = 'TEST-LICENSE-001';

-- Find the user ID for the test phone number
SELECT @UserId = Id 
FROM Users 
WHERE PhoneNumber = @TestPhoneNumber;

-- Check if user exists
IF @UserId IS NULL
BEGIN
    PRINT 'ERROR: User with phone number ' + @TestPhoneNumber + ' not found.';
    PRINT 'Please make sure the user has logged in at least once to create a Users record.';
END
ELSE
BEGIN
    -- Check if driver profile already exists
    IF EXISTS (SELECT 1 FROM Drivers WHERE UserId = @UserId)
    BEGIN
        PRINT 'Driver profile already exists for user ' + CAST(@UserId AS NVARCHAR(50));
        SELECT * FROM Drivers WHERE UserId = @UserId;
    END
    ELSE
    BEGIN
        -- Create driver profile
        INSERT INTO Drivers (
            Id,
            UserId,
            LicenseNumber,
            LicenseExpiryDate,
            LicenseImageUrl,
            IsVerified,
            IsOnline,
            IsAvailable,
            CurrentLatitude,
            CurrentLongitude,
            LastLocationUpdate,
            TotalRides,
            TotalEarnings,
            PendingEarnings,
            AvailableForWithdrawal,
            Rating,
            CreatedAt,
            UpdatedAt
        )
        VALUES (
            @DriverId,
            @UserId,
            @LicenseNumber,
            DATEADD(YEAR, 5, GETUTCDATE()), -- License valid for 5 years
            NULL, -- No license image for test driver
            1, -- Verified
            0, -- Not online initially
            1, -- Available
            NULL, -- No location yet
            NULL,
            NULL,
            0, -- No rides yet
            0.00, -- No earnings
            0.00, -- No pending earnings
            0.00, -- Nothing available for withdrawal
            5.0, -- Perfect rating initially
            GETUTCDATE(),
            GETUTCDATE()
        );

        PRINT 'Successfully created test driver profile!';
        PRINT 'Driver ID: ' + CAST(@DriverId AS NVARCHAR(50));
        PRINT 'User ID: ' + CAST(@UserId AS NVARCHAR(50));
        PRINT 'License Number: ' + @LicenseNumber;
        
        -- Display the created driver
        SELECT 
            d.*,
            u.PhoneNumber,
            u.Email,
            up.Name as DriverName
        FROM Drivers d
        INNER JOIN Users u ON d.UserId = u.Id
        LEFT JOIN UserProfiles up ON u.Id = up.UserId
        WHERE d.Id = @DriverId;
    END
END
GO

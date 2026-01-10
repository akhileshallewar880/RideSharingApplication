-- ========================================
-- DELETE USER DATA
-- Phone: 9511803142
-- Email: akhileshallewar880@gmail.com
-- ========================================
-- ⚠️ WARNING: This will permanently delete ALL data for this user!
-- Run this script carefully and ensure you have a backup.
-- ========================================

USE RideSharingDb;
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- Declare variables to store user IDs
    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @DriverId UNIQUEIDENTIFIER;
    DECLARE @DeletedRecords INT = 0;

    -- Find the User ID by phone number or email
    SELECT @UserId = Id
    FROM Users
    WHERE PhoneNumber = '9511803142' 
       OR Email LIKE '%akhileshallewar880%';

    IF @UserId IS NULL
    BEGIN
        PRINT '⚠️ No user found with phone number 9511803142 or email containing akhileshallewar880';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    PRINT '🔍 Found User ID: ' + CAST(@UserId AS NVARCHAR(50));
    PRINT '📧 Email: ' + ISNULL((SELECT Email FROM Users WHERE Id = @UserId), 'N/A');
    PRINT '📱 Phone: ' + ISNULL((SELECT PhoneNumber FROM Users WHERE Id = @UserId), 'N/A');
    PRINT '';
    PRINT '⚠️ Starting deletion process...';
    PRINT '';

    -- Get Driver ID if user is a driver
    SELECT @DriverId = Id FROM Drivers WHERE UserId = @UserId;

    -- ========================================
    -- Step 1: Delete Payments (if any bookings exist)
    -- ========================================
    DELETE FROM Payments
    WHERE BookingId IN (
        SELECT Id FROM Bookings WHERE PassengerId = @UserId
    );
    SET @DeletedRecords = @@ROWCOUNT;
    IF @DeletedRecords > 0
        PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' payment records';

    -- ========================================
    -- Step 2: Delete Bookings (as passenger)
    -- ========================================
    DELETE FROM Bookings
    WHERE PassengerId = @UserId;
    SET @DeletedRecords = @@ROWCOUNT;
    IF @DeletedRecords > 0
        PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' booking records';

    -- ========================================
    -- Step 3: Delete Bookings for rides created by this driver
    -- ========================================
    IF @DriverId IS NOT NULL
    BEGIN
        DELETE FROM Payments
        WHERE BookingId IN (
            SELECT b.Id FROM Bookings b
            INNER JOIN Rides r ON b.RideId = r.Id
            WHERE r.DriverId = @DriverId
        );
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' payment records for driver rides';

        DELETE FROM Bookings
        WHERE RideId IN (
            SELECT Id FROM Rides WHERE DriverId = @DriverId
        );
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' bookings for driver rides';

        -- ========================================
        -- Step 4: Delete Rides created by this driver
        -- ========================================
        DELETE FROM Rides
        WHERE DriverId = @DriverId;
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' ride records';

        -- ========================================
        -- Step 5: Delete Vehicles
        -- ========================================
        DELETE FROM Vehicles
        WHERE DriverId = @DriverId;
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' vehicle records';

        -- ========================================
        -- Step 6: Delete Driver record
        -- ========================================
        DELETE FROM Drivers
        WHERE Id = @DriverId;
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted driver record';
    END

    -- ========================================
    -- Step 7: Delete UserProfile
    -- ========================================
    DELETE FROM UserProfiles
    WHERE UserId = @UserId;
    SET @DeletedRecords = @@ROWCOUNT;
    IF @DeletedRecords > 0
        PRINT '✅ Deleted user profile';

    -- ========================================
    -- Step 8: Delete FCM Tokens (if table exists)
    -- ========================================
    IF OBJECT_ID('dbo.FCMTokens', 'U') IS NOT NULL
    BEGIN
        DELETE FROM FCMTokens
        WHERE UserId = @UserId;
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' FCM token records';
    END

    -- ========================================
    -- Step 9: Delete Password Reset Tokens (if table exists)
    -- ========================================
    IF OBJECT_ID('dbo.PasswordResetTokens', 'U') IS NOT NULL
    BEGIN
        DELETE FROM PasswordResetTokens
        WHERE UserId = @UserId;
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' password reset tokens';
    END

    -- ========================================
    -- Step 10: Delete OTP records (if table exists)
    -- ========================================
    IF OBJECT_ID('dbo.OTPRecords', 'U') IS NOT NULL
    BEGIN
        DELETE FROM OTPRecords
        WHERE PhoneNumber = '9511803142';
        SET @DeletedRecords = @@ROWCOUNT;
        IF @DeletedRecords > 0
            PRINT '✅ Deleted ' + CAST(@DeletedRecords AS NVARCHAR) + ' OTP records';
    END

    -- ========================================
    -- Step 11: Delete User record (CASCADE will handle related records)
    -- ========================================
    DELETE FROM Users
    WHERE Id = @UserId;
    SET @DeletedRecords = @@ROWCOUNT;
    IF @DeletedRecords > 0
        PRINT '✅ Deleted user account';

    PRINT '';
    PRINT '✅ All data for phone 9511803142 and email akhileshallewar880 has been deleted successfully!';
    PRINT '';

    -- Commit the transaction
    COMMIT TRANSACTION;
    PRINT '✅ Transaction committed successfully!';

END TRY
BEGIN CATCH
    -- Rollback in case of error
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '❌ ERROR: Failed to delete user data';
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
END CATCH;

GO

-- ========================================
-- Verification Query
-- Check if user still exists
-- ========================================
PRINT '';
PRINT '🔍 Verification - Checking if user still exists:';
PRINT '';

SELECT 
    COUNT(*) AS RemainingRecords,
    'Users' AS TableName
FROM Users
WHERE PhoneNumber = '9511803142' 
   OR Email LIKE '%akhileshallewar880%'

UNION ALL

SELECT 
    COUNT(*),
    'OTPRecords'
FROM OTPRecords
WHERE PhoneNumber = '9511803142'

UNION ALL

SELECT 
    COUNT(*),
    'UserProfiles'
FROM UserProfiles
WHERE UserId IN (SELECT Id FROM Users WHERE PhoneNumber = '9511803142');

PRINT '';
PRINT '✅ Verification complete!';
PRINT '   If all counts are 0, the deletion was successful.';

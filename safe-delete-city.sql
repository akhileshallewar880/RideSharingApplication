-- Safe delete for Cities table
-- This script handles foreign key constraints before deleting cities

USE RideSharingDb;
GO

-- Option 1: Safe Delete - Set CityId to NULL for affected drivers
-- Replace 'CITY_ID_HERE' with the actual city ID you want to delete
DECLARE @CityIdToDelete UNIQUEIDENTIFIER = 'CITY_ID_HERE';

BEGIN TRANSACTION;

BEGIN TRY
    -- Check if city exists
    IF NOT EXISTS (SELECT 1 FROM Cities WHERE Id = @CityIdToDelete)
    BEGIN
        PRINT 'City not found';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Get city name for logging
    DECLARE @CityName NVARCHAR(200);
    SELECT @CityName = Name FROM Cities WHERE Id = @CityIdToDelete;
    PRINT 'Deleting city: ' + @CityName;

    -- Check for affected drivers
    DECLARE @AffectedDrivers INT;
    SELECT @AffectedDrivers = COUNT(*) FROM Drivers WHERE CityId = @CityIdToDelete;
    PRINT 'Affected drivers: ' + CAST(@AffectedDrivers AS NVARCHAR(10));

    -- Set CityId to NULL for all drivers in this city
    UPDATE Drivers 
    SET CityId = NULL, 
        UpdatedAt = GETUTCDATE()
    WHERE CityId = @CityIdToDelete;
    
    PRINT 'Updated ' + CAST(@AffectedDrivers AS NVARCHAR(10)) + ' drivers (CityId set to NULL)';

    -- Now delete the city
    DELETE FROM Cities WHERE Id = @CityIdToDelete;
    
    PRINT 'City deleted successfully';

    COMMIT TRANSACTION;
    PRINT 'Transaction completed';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Option 2: Delete by City Name
-- Uncomment and use this if you want to delete by name instead of ID
/*
DECLARE @CityNameToDelete NVARCHAR(200) = 'YourCityName';

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE @CityId UNIQUEIDENTIFIER;
    SELECT @CityId = Id FROM Cities WHERE Name = @CityNameToDelete;

    IF @CityId IS NULL
    BEGIN
        PRINT 'City not found: ' + @CityNameToDelete;
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Set CityId to NULL for all drivers
    UPDATE Drivers 
    SET CityId = NULL, 
        UpdatedAt = GETUTCDATE()
    WHERE CityId = @CityId;

    -- Delete the city
    DELETE FROM Cities WHERE Id = @CityId;
    
    PRINT 'City "' + @CityNameToDelete + '" deleted successfully';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO
*/

-- Option 3: Bulk Delete Multiple Cities (by name pattern or IDs)
-- Use this if you need to clean up multiple cities at once
/*
BEGIN TRANSACTION;

BEGIN TRY
    -- Update all drivers first
    UPDATE Drivers 
    SET CityId = NULL, 
        UpdatedAt = GETUTCDATE()
    WHERE CityId IN (
        SELECT Id FROM Cities 
        WHERE Name LIKE '%pattern%'  -- Modify this condition
    );

    -- Delete cities
    DELETE FROM Cities 
    WHERE Name LIKE '%pattern%';  -- Modify this condition
    
    COMMIT TRANSACTION;
    PRINT 'Bulk delete completed';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO
*/

-- Option 4: Soft Delete (Recommended for production)
-- Just mark as inactive instead of deleting
/*
DECLARE @CityIdToDeactivate UNIQUEIDENTIFIER = 'CITY_ID_HERE';

UPDATE Cities 
SET IsActive = 0, 
    UpdatedAt = GETUTCDATE()
WHERE Id = @CityIdToDeactivate;

PRINT 'City marked as inactive (soft delete)';
GO
*/

-- Helper: View all cities with driver counts
SELECT 
    c.Id,
    c.Name,
    c.State,
    c.IsActive,
    COUNT(d.Id) AS DriverCount
FROM Cities c
LEFT JOIN Drivers d ON c.Id = d.CityId
GROUP BY c.Id, c.Name, c.State, c.IsActive
ORDER BY DriverCount DESC, c.Name;
GO

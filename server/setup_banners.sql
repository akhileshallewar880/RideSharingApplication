-- Quick Banner Setup Script
-- Run this in SQL Server Management Studio or Azure Data Studio

USE RideSharingDb;
GO

-- Check if Banners table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Banners')
BEGIN
    PRINT 'ERROR: Banners table does not exist!'
    PRINT 'Please run database migrations first'
END
ELSE
BEGIN
    PRINT 'Banners table found. Inserting sample data...'
    
    -- Clear existing banners (optional - comment out if you want to keep existing)
    -- DELETE FROM Banners;
    
    -- Insert Banner 1: Welcome
    IF NOT EXISTS (SELECT * FROM Banners WHERE Title = 'Welcome to VanYatra')
    BEGIN
        INSERT INTO Banners (
            Id,
            Title,
            Description,
            ImageUrl,
            TargetUrl,
            StartDate,
            EndDate,
            IsActive,
            Priority,
            TargetAudience,
            ImpressionCount,
            ClickCount,
            CreatedAt,
            UpdatedAt
        )
        VALUES (
            NEWID(),
            'Welcome to VanYatra',
            'Book your rural rides easily and safely with verified drivers',
            'https://via.placeholder.com/800x400/4285F4/FFFFFF?text=Welcome+to+VanYatra',
            null,
            GETDATE(),
            DATEADD(year, 1, GETDATE()),
            1,  -- IsActive
            1,  -- Priority (highest)
            'all',
            0,  -- ImpressionCount
            0,  -- ClickCount
            GETDATE(),
            GETDATE()
        );
        PRINT '✓ Banner 1 inserted: Welcome to VanYatra'
    END
    ELSE
        PRINT '⚠ Banner 1 already exists: Welcome to VanYatra'
    
    -- Insert Banner 2: Safety
    IF NOT EXISTS (SELECT * FROM Banners WHERE Title = 'Safe & Comfortable Travel')
    BEGIN
        INSERT INTO Banners (
            Id,
            Title,
            Description,
            ImageUrl,
            TargetUrl,
            StartDate,
            EndDate,
            IsActive,
            Priority,
            TargetAudience,
            ImpressionCount,
            ClickCount,
            CreatedAt,
            UpdatedAt
        )
        VALUES (
            NEWID(),
            'Safe & Comfortable Travel',
            'All our drivers are verified and vehicles are regularly inspected',
            'https://via.placeholder.com/800x400/34A853/FFFFFF?text=Safe+%26+Comfortable',
            null,
            GETDATE(),
            DATEADD(year, 1, GETDATE()),
            1,
            2,
            'all',
            0,
            0,
            GETDATE(),
            GETDATE()
        );
        PRINT '✓ Banner 2 inserted: Safe & Comfortable Travel'
    END
    ELSE
        PRINT '⚠ Banner 2 already exists: Safe & Comfortable Travel'
    
    -- Insert Banner 3: Pricing
    IF NOT EXISTS (SELECT * FROM Banners WHERE Title = 'Best Prices Guaranteed')
    BEGIN
        INSERT INTO Banners (
            Id,
            Title,
            Description,
            ImageUrl,
            TargetUrl,
            StartDate,
            EndDate,
            IsActive,
            Priority,
            TargetAudience,
            ImpressionCount,
            ClickCount,
            CreatedAt,
            UpdatedAt
        )
        VALUES (
            NEWID(),
            'Best Prices Guaranteed',
            'Affordable rides to rural areas with transparent pricing',
            'https://via.placeholder.com/800x400/FBBC04/FFFFFF?text=Best+Prices',
            null,
            GETDATE(),
            DATEADD(year, 1, GETDATE()),
            1,
            3,
            'all',
            0,
            0,
            GETDATE(),
            GETDATE()
        );
        PRINT '✓ Banner 3 inserted: Best Prices Guaranteed'
    END
    ELSE
        PRINT '⚠ Banner 3 already exists: Best Prices Guaranteed'
    
    PRINT ''
    PRINT '=== Banner Summary ==='
    SELECT 
        Title,
        Description,
        IsActive,
        Priority,
        StartDate,
        EndDate
    FROM Banners
    ORDER BY Priority;
    
    PRINT ''
    PRINT '✅ Setup complete! You can now test the banner API:'
    PRINT '   curl http://192.168.88.10:5056/api/v1/passenger/banners'
END
GO

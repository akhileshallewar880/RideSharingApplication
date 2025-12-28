-- ============================================================
-- AUTO-CANCELLATION OF EXPIRED RIDES AND BOOKINGS
-- SQL Server Stored Procedure
-- ============================================================

-- This stored procedure automatically cancels rides and their associated 
-- bookings that have passed their scheduled time without being started.

USE AllapalliRide;
GO

-- Drop existing procedure if it exists
IF OBJECT_ID('dbo.sp_AutoCancelExpiredRides', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AutoCancelExpiredRides;
GO

CREATE PROCEDURE dbo.sp_AutoCancelExpiredRides
    @GracePeriodMinutes INT = 15,  -- Grace period after scheduled time
    @Debug BIT = 0                  -- Set to 1 to see what would be cancelled without actually doing it
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDateTime DATETIME2 = GETUTCDATE();
    DECLARE @CancelledRidesCount INT = 0;
    DECLARE @CancelledBookingsCount INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Temporary table to store rides that need to be cancelled
        CREATE TABLE #ExpiredRides (
            RideId UNIQUEIDENTIFIER,
            RideNumber NVARCHAR(20),
            TravelDate DATE,
            DepartureTime TIME,
            DriverId UNIQUEIDENTIFIER
        );
        
        -- Find all expired rides that haven't started
        INSERT INTO #ExpiredRides (RideId, RideNumber, TravelDate, DepartureTime, DriverId)
        SELECT 
            Id,
            RideNumber,
            TravelDate,
            DepartureTime,
            DriverId
        FROM Rides
        WHERE Status IN ('scheduled', 'upcoming')
        AND (
            -- Past date
            TravelDate < CAST(@CurrentDateTime AS DATE)
            OR
            -- Today but departure time + grace period has passed
            (
                TravelDate = CAST(@CurrentDateTime AS DATE)
                AND 
                DATEADD(MINUTE, @GracePeriodMinutes, 
                    CAST(CAST(TravelDate AS DATETIME) + CAST(DepartureTime AS DATETIME) AS DATETIME2)
                ) < @CurrentDateTime
            )
        );
        
        SET @CancelledRidesCount = @@ROWCOUNT;
        
        IF @Debug = 1
        BEGIN
            -- Debug mode: Just show what would be cancelled
            SELECT 
                'RIDES TO BE CANCELLED' AS [Type],
                * 
            FROM #ExpiredRides;
            
            SELECT 
                'BOOKINGS TO BE CANCELLED' AS [Type],
                b.Id,
                b.BookingNumber,
                b.RideId,
                b.PassengerId,
                b.Status,
                b.PaymentStatus,
                b.TotalAmount
            FROM Bookings b
            INNER JOIN #ExpiredRides er ON b.RideId = er.RideId
            WHERE b.Status NOT IN ('completed', 'cancelled', 'refunded');
            
            -- Rollback since this is just a debug run
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Update rides to cancelled
        UPDATE r
        SET 
            Status = 'cancelled',
            CancellationReason = 'Automatically cancelled: Scheduled time passed without departure',
            UpdatedAt = @CurrentDateTime
        FROM Rides r
        INNER JOIN #ExpiredRides er ON r.Id = er.RideId;
        
        -- Update bookings to cancelled and handle refunds
        UPDATE b
        SET 
            Status = CASE 
                WHEN b.PaymentStatus = 'paid' THEN 'refunded'
                ELSE 'cancelled'
            END,
            CancellationType = 'system',
            CancellationReason = 'Ride automatically cancelled: Scheduled time passed without departure',
            CancelledAt = @CurrentDateTime,
            UpdatedAt = @CurrentDateTime,
            PaymentStatus = CASE 
                WHEN b.PaymentStatus = 'paid' THEN 'refunded'
                ELSE b.PaymentStatus
            END
        FROM Bookings b
        INNER JOIN #ExpiredRides er ON b.RideId = er.RideId
        WHERE b.Status NOT IN ('completed', 'cancelled', 'refunded');
        
        SET @CancelledBookingsCount = @@ROWCOUNT;
        
        -- Create notifications for drivers
        INSERT INTO Notifications (Id, UserId, Title, Message, Type, ReferenceId, IsRead, CreatedAt)
        SELECT 
            NEWID(),
            er.DriverId,
            'Ride Automatically Cancelled',
            'Your ride ' + er.RideNumber + ' was automatically cancelled because the scheduled departure time has passed.',
            'ride_cancelled',
            CAST(er.RideId AS NVARCHAR(36)),
            0,
            @CurrentDateTime
        FROM #ExpiredRides er;
        
        -- Create notifications for passengers
        INSERT INTO Notifications (Id, UserId, Title, Message, Type, ReferenceId, IsRead, CreatedAt)
        SELECT 
            NEWID(),
            b.PassengerId,
            'Booking Automatically Cancelled',
            'Your booking ' + b.BookingNumber + ' was automatically cancelled because the ride did not depart as scheduled.' +
            CASE 
                WHEN b.PaymentStatus = 'refunded' THEN ' A refund has been initiated.'
                ELSE ''
            END,
            'booking_cancelled',
            CAST(b.Id AS NVARCHAR(36)),
            0,
            @CurrentDateTime
        FROM Bookings b
        INNER JOIN #ExpiredRides er ON b.RideId = er.RideId
        WHERE b.CancelledAt = @CurrentDateTime; -- Only for bookings just cancelled
        
        COMMIT TRANSACTION;
        
        -- Log the results
        PRINT 'Auto-cancellation completed successfully:';
        PRINT '  Rides cancelled: ' + CAST(@CancelledRidesCount AS NVARCHAR(10));
        PRINT '  Bookings cancelled: ' + CAST(@CancelledBookingsCount AS NVARCHAR(10));
        PRINT '  Timestamp: ' + CONVERT(NVARCHAR(30), @CurrentDateTime, 121);
        
        -- Clean up
        DROP TABLE #ExpiredRides;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Error in auto-cancellation process:';
        PRINT @ErrorMessage;
        
        -- Re-throw the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- ============================================================
-- TEST THE STORED PROCEDURE
-- ============================================================

-- Test in debug mode (won't make changes)
-- EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 1;

-- Execute for real
-- EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 0;

-- ============================================================
-- CREATE SQL SERVER AGENT JOB (SQL Server only, not SQL Express)
-- ============================================================

/*
-- This creates a job that runs every 5 minutes to check for expired rides
-- Note: SQL Server Agent is not available in SQL Server Express

USE msdb;
GO

-- Create the job
EXEC dbo.sp_add_job
    @job_name = N'Auto Cancel Expired Rides',
    @enabled = 1,
    @description = N'Automatically cancels rides that have passed their scheduled time without departure';

-- Add a job step
EXEC dbo.sp_add_jobstep
    @job_name = N'Auto Cancel Expired Rides',
    @step_name = N'Execute Cancellation Procedure',
    @subsystem = N'TSQL',
    @database_name = N'AllapalliRide',
    @command = N'EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 0;',
    @retry_attempts = 3,
    @retry_interval = 1;

-- Schedule to run every 5 minutes
EXEC dbo.sp_add_schedule
    @schedule_name = N'Every 5 Minutes',
    @freq_type = 4,          -- Daily
    @freq_interval = 1,      -- Every day
    @freq_subday_type = 4,   -- Minutes
    @freq_subday_interval = 5, -- Every 5 minutes
    @active_start_time = 000000; -- Start at midnight

-- Attach the schedule to the job
EXEC dbo.sp_attach_schedule
    @job_name = N'Auto Cancel Expired Rides',
    @schedule_name = N'Every 5 Minutes';

-- Add the job to the local server
EXEC dbo.sp_add_jobserver
    @job_name = N'Auto Cancel Expired Rides',
    @server_name = N'(local)';

GO

-- To disable the job later:
-- EXEC msdb.dbo.sp_update_job @job_name = N'Auto Cancel Expired Rides', @enabled = 0;

-- To enable the job:
-- EXEC msdb.dbo.sp_update_job @job_name = N'Auto Cancel Expired Rides', @enabled = 1;

-- To delete the job:
-- EXEC msdb.dbo.sp_delete_job @job_name = N'Auto Cancel Expired Rides';
*/

-- Add missing columns to Rides table
USE RideSharingDb;
GO

-- Add missing columns
ALTER TABLE Rides ADD RideNumber NVARCHAR(20) NOT NULL DEFAULT '';
ALTER TABLE Rides ADD VehicleModelId UNIQUEIDENTIFIER NULL;
ALTER TABLE Rides ADD IntermediateStops NVARCHAR(MAX) NULL;
ALTER TABLE Rides ADD SegmentPrices NVARCHAR(MAX) NULL;
ALTER TABLE Rides ADD TravelDate DATETIME2 NOT NULL DEFAULT GETUTCDATE();
ALTER TABLE Rides ADD DepartureTime TIME NOT NULL DEFAULT '00:00:00';
ALTER TABLE Rides ADD EstimatedArrivalTime TIME NULL;
ALTER TABLE Rides ADD ActualDepartureTime DATETIME2 NULL;
ALTER TABLE Rides ADD ActualArrivalTime DATETIME2 NULL;
ALTER TABLE Rides ADD BookedSeats INT NOT NULL DEFAULT 0;
ALTER TABLE Rides ADD Route NVARCHAR(MAX) NULL;
ALTER TABLE Rides ADD Distance DECIMAL(10,2) NULL;
ALTER TABLE Rides ADD Duration INT NULL;
ALTER TABLE Rides ADD IsReturnTrip BIT NOT NULL DEFAULT 0;
ALTER TABLE Rides ADD LinkedReturnRideId UNIQUEIDENTIFIER NULL;
ALTER TABLE Rides ADD AdminNotes NVARCHAR(1000) NULL;
GO

-- Add foreign key for VehicleModelId
ALTER TABLE Rides ADD CONSTRAINT FK_Rides_VehicleModels FOREIGN KEY (VehicleModelId) REFERENCES VehicleModels(Id);
GO

-- Create index for RideNumber
CREATE UNIQUE INDEX IX_Rides_RideNumber ON Rides(RideNumber);
GO

-- Remove old columns that are not in the model
ALTER TABLE Rides DROP COLUMN IF EXISTS ScheduledStartTime;
ALTER TABLE Rides DROP COLUMN IF EXISTS ActualStartTime;
ALTER TABLE Rides DROP COLUMN IF EXISTS ActualEndTime;
ALTER TABLE Rides DROP COLUMN IF EXISTS EstimatedDuration;
ALTER TABLE Rides DROP COLUMN IF EXISTS ActualDuration;
ALTER TABLE Rides DROP COLUMN IF EXISTS EstimatedDistance;
ALTER TABLE Rides DROP COLUMN IF EXISTS ActualDistance;
ALTER TABLE Rides DROP COLUMN IF EXISTS AvailableSeats;
GO

PRINT 'Rides table updated successfully!';
GO

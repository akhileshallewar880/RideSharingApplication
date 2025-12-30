-- Create all tables for RideSharingDb
USE RideSharingDb;
GO

-- Create Users table
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(255),
    PasswordHash NVARCHAR(MAX),
    UserType NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT UK_Users_PhoneNumber UNIQUE (PhoneNumber),
    CONSTRAINT UK_Users_Email UNIQUE (Email)
);
CREATE INDEX IX_Users_UserType ON Users(UserType);
GO

-- Create UserProfiles table
CREATE TABLE UserProfiles (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    DateOfBirth DATETIME2,
    Gender NVARCHAR(10),
    Address NVARCHAR(500),
    City NVARCHAR(100),
    State NVARCHAR(100),
    ZipCode NVARCHAR(20),
    Country NVARCHAR(100),
    ProfilePictureUrl NVARCHAR(MAX),
    EmergencyContact NVARCHAR(20),
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    CONSTRAINT UK_UserProfiles_UserId UNIQUE (UserId)
);
GO

-- Create Cities table
CREATE TABLE Cities (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(200) NOT NULL,
    State NVARCHAR(200),
    Country NVARCHAR(200),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
CREATE INDEX IX_Cities_IsActive ON Cities(IsActive);
GO

-- Create Drivers table
CREATE TABLE Drivers (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    LicenseNumber NVARCHAR(50) NOT NULL,
    LicenseExpiryDate DATETIME2,
    LicenseImageUrl NVARCHAR(MAX),
    IsVerified BIT NOT NULL DEFAULT 0,
    IsOnline BIT NOT NULL DEFAULT 0,
    IsAvailable BIT NOT NULL DEFAULT 0,
    CurrentLatitude FLOAT,
    CurrentLongitude FLOAT,
    LastLocationUpdate DATETIME2,
    TotalRides INT NOT NULL DEFAULT 0,
    TotalEarnings DECIMAL(10,2) NOT NULL DEFAULT 0,
    PendingEarnings DECIMAL(10,2) NOT NULL DEFAULT 0,
    AvailableForWithdrawal DECIMAL(10,2) NOT NULL DEFAULT 0,
    Rating FLOAT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Drivers_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    CONSTRAINT UK_Drivers_UserId UNIQUE (UserId),
    CONSTRAINT UK_Drivers_LicenseNumber UNIQUE (LicenseNumber)
);
CREATE INDEX IX_Drivers_IsOnline ON Drivers(IsOnline);
CREATE INDEX IX_Drivers_IsAvailable ON Drivers(IsAvailable);
GO

-- Create VehicleModels table
CREATE TABLE VehicleModels (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Type NVARCHAR(100) NOT NULL,
    Brand NVARCHAR(100),
    Model NVARCHAR(100),
    TotalSeats INT NOT NULL,
    BasePrice DECIMAL(10,2) NOT NULL,
    PricePerKm DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    ImageUrl NVARCHAR(MAX),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
CREATE INDEX IX_VehicleModels_Type ON VehicleModels(Type);
CREATE INDEX IX_VehicleModels_Brand ON VehicleModels(Brand);
CREATE INDEX IX_VehicleModels_IsActive ON VehicleModels(IsActive);
GO

-- Create Vehicles table
CREATE TABLE Vehicles (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DriverId UNIQUEIDENTIFIER NOT NULL,
    VehicleModelId UNIQUEIDENTIFIER,
    VehicleType NVARCHAR(100) NOT NULL,
    Brand NVARCHAR(100),
    Model NVARCHAR(100),
    Year INT,
    Color NVARCHAR(50),
    RegistrationNumber NVARCHAR(50) NOT NULL,
    InsuranceNumber NVARCHAR(100),
    InsuranceExpiryDate DATETIME2,
    TotalSeats INT NOT NULL,
    AvailableSeats INT NOT NULL,
    ImageUrl NVARCHAR(MAX),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Vehicles_Drivers FOREIGN KEY (DriverId) REFERENCES Drivers(Id) ON DELETE CASCADE,
    CONSTRAINT FK_Vehicles_VehicleModels FOREIGN KEY (VehicleModelId) REFERENCES VehicleModels(Id),
    CONSTRAINT UK_Vehicles_RegistrationNumber UNIQUE (RegistrationNumber)
);
CREATE INDEX IX_Vehicles_DriverId ON Vehicles(DriverId);
CREATE INDEX IX_Vehicles_VehicleType ON Vehicles(VehicleType);
GO

-- Create Rides table
CREATE TABLE Rides (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DriverId UNIQUEIDENTIFIER NOT NULL,
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    PickupLocation NVARCHAR(500) NOT NULL,
    PickupLatitude FLOAT NOT NULL,
    PickupLongitude FLOAT NOT NULL,
    DropoffLocation NVARCHAR(500) NOT NULL,
    DropoffLatitude FLOAT NOT NULL,
    DropoffLongitude FLOAT NOT NULL,
    ScheduledStartTime DATETIME2 NOT NULL,
    ActualStartTime DATETIME2,
    ActualEndTime DATETIME2,
    EstimatedDuration INT,
    ActualDuration INT,
    EstimatedDistance FLOAT,
    ActualDistance FLOAT,
    TotalSeats INT NOT NULL,
    AvailableSeats INT NOT NULL,
    PricePerSeat DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CancellationReason NVARCHAR(MAX),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Rides_Drivers FOREIGN KEY (DriverId) REFERENCES Drivers(Id),
    CONSTRAINT FK_Rides_Vehicles FOREIGN KEY (VehicleId) REFERENCES Vehicles(Id)
);
CREATE INDEX IX_Rides_DriverId ON Rides(DriverId);
CREATE INDEX IX_Rides_Status ON Rides(Status);
CREATE INDEX IX_Rides_ScheduledStartTime ON Rides(ScheduledStartTime);
GO

-- Create Bookings table
CREATE TABLE Bookings (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RideId UNIQUEIDENTIFIER NOT NULL,
    PassengerId UNIQUEIDENTIFIER NOT NULL,
    NumberOfSeats INT NOT NULL DEFAULT 1,
    TotalAmount DECIMAL(10,2) NOT NULL,
    PickupLocation NVARCHAR(500),
    PickupLatitude FLOAT,
    PickupLongitude FLOAT,
    DropoffLocation NVARCHAR(500),
    DropoffLatitude FLOAT,
    DropoffLongitude FLOAT,
    Status NVARCHAR(50) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL,
    CancellationReason NVARCHAR(MAX),
    DriverArrivalTime DATETIME2,
    PassengerPickupTime DATETIME2,
    PassengerDropoffTime DATETIME2,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Bookings_Rides FOREIGN KEY (RideId) REFERENCES Rides(Id),
    CONSTRAINT FK_Bookings_Passengers FOREIGN KEY (PassengerId) REFERENCES Users(Id)
);
CREATE INDEX IX_Bookings_RideId ON Bookings(RideId);
CREATE INDEX IX_Bookings_PassengerId ON Bookings(PassengerId);
CREATE INDEX IX_Bookings_Status ON Bookings(Status);
GO

-- Create Payments table
CREATE TABLE Payments (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BookingId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL,
    TransactionId NVARCHAR(255),
    PaymentGatewayResponse NVARCHAR(MAX),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Payments_Bookings FOREIGN KEY (BookingId) REFERENCES Bookings(Id)
);
CREATE INDEX IX_Payments_BookingId ON Payments(BookingId);
CREATE INDEX IX_Payments_PaymentStatus ON Payments(PaymentStatus);
GO

-- Create Ratings table
CREATE TABLE Ratings (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BookingId UNIQUEIDENTIFIER NOT NULL,
    RatedById UNIQUEIDENTIFIER NOT NULL,
    RatedForId UNIQUEIDENTIFIER NOT NULL,
    Rating INT NOT NULL,
    Review NVARCHAR(MAX),
    RatingType NVARCHAR(50) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Ratings_Bookings FOREIGN KEY (BookingId) REFERENCES Bookings(Id),
    CONSTRAINT FK_Ratings_RatedBy FOREIGN KEY (RatedById) REFERENCES Users(Id),
    CONSTRAINT FK_Ratings_RatedFor FOREIGN KEY (RatedForId) REFERENCES Users(Id),
    CONSTRAINT UK_Ratings_Booking UNIQUE (BookingId, RatedById)
);
CREATE INDEX IX_Ratings_RatedForId ON Ratings(RatedForId);
GO

-- Create Notifications table
CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(255) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    Type NVARCHAR(50),
    Data NVARCHAR(MAX),
    IsRead BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);
CREATE INDEX IX_Notifications_UserId ON Notifications(UserId);
CREATE INDEX IX_Notifications_IsRead ON Notifications(IsRead);
CREATE INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt);
GO

-- Create Payouts table
CREATE TABLE Payouts (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DriverId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    PaymentMethod NVARCHAR(50),
    TransactionId NVARCHAR(255),
    BankDetails NVARCHAR(MAX),
    ProcessedAt DATETIME2,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Payouts_Drivers FOREIGN KEY (DriverId) REFERENCES Drivers(Id)
);
CREATE INDEX IX_Payouts_DriverId ON Payouts(DriverId);
CREATE INDEX IX_Payouts_Status ON Payouts(Status);
GO

-- Create OTPVerifications table
CREATE TABLE OTPVerifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber NVARCHAR(20) NOT NULL,
    OTP NVARCHAR(10) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    IsVerified BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
CREATE INDEX IX_OTPVerifications_PhoneNumber ON OTPVerifications(PhoneNumber);
CREATE INDEX IX_OTPVerifications_ExpiresAt ON OTPVerifications(ExpiresAt);
GO

-- Create RefreshTokens table
CREATE TABLE RefreshTokens (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Token NVARCHAR(MAX) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    RevokedAt DATETIME2,
    IsRevoked BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);
CREATE INDEX IX_RefreshTokens_UserId ON RefreshTokens(UserId);
CREATE INDEX IX_RefreshTokens_ExpiresAt ON RefreshTokens(ExpiresAt);
GO

-- Create LocationTrackings table
CREATE TABLE LocationTrackings (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RideId UNIQUEIDENTIFIER NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_LocationTrackings_Rides FOREIGN KEY (RideId) REFERENCES Rides(Id) ON DELETE CASCADE
);
CREATE INDEX IX_LocationTrackings_RideId ON LocationTrackings(RideId);
CREATE INDEX IX_LocationTrackings_Timestamp ON LocationTrackings(Timestamp);
GO

-- Create PasswordResetTokens table
CREATE TABLE PasswordResetTokens (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Token NVARCHAR(MAX) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    IsUsed BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_PasswordResetTokens_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);
CREATE INDEX IX_PasswordResetTokens_UserId ON PasswordResetTokens(UserId);
CREATE INDEX IX_PasswordResetTokens_ExpiresAt ON PasswordResetTokens(ExpiresAt);
GO

-- Create Banners table
CREATE TABLE Banners (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Title NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    ImageUrl NVARCHAR(MAX) NOT NULL,
    LinkUrl NVARCHAR(MAX),
    IsActive BIT NOT NULL DEFAULT 1,
    DisplayOrder INT NOT NULL DEFAULT 0,
    StartDate DATETIME2,
    EndDate DATETIME2,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
CREATE INDEX IX_Banners_IsActive ON Banners(IsActive);
CREATE INDEX IX_Banners_DisplayOrder ON Banners(DisplayOrder);
GO

-- Create RouteSegments table
CREATE TABLE RouteSegments (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RideId UNIQUEIDENTIFIER NOT NULL,
    SequenceNumber INT NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_RouteSegments_Rides FOREIGN KEY (RideId) REFERENCES Rides(Id) ON DELETE CASCADE
);
CREATE INDEX IX_RouteSegments_RideId ON RouteSegments(RideId);
CREATE INDEX IX_RouteSegments_SequenceNumber ON RouteSegments(SequenceNumber);
GO

PRINT 'Database schema created successfully!';
GO

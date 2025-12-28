# Database Schema - Allapalli Ride

## Technology Stack
- **Database**: SQL Server
- **ORM**: Entity Framework Core 8
- **Authentication**: JWT with Refresh Tokens
- **Password Hashing**: BCrypt / PBKDF2

---

## Schema Overview

```
Database: AllapalliRide
├── Users
├── UserProfiles
├── Drivers
├── Vehicles
├── Rides
├── Bookings
├── Payments
├── Ratings
├── Notifications
├── OTPVerifications
└── RefreshTokens
```

---

## 1. Users Table

**Table Name:** `Users`

**Purpose:** Core user authentication and basic information

```sql
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber NVARCHAR(20) NOT NULL UNIQUE,
    CountryCode NVARCHAR(5) NOT NULL DEFAULT '+91',
    Email NVARCHAR(255) UNIQUE,
    PasswordHash NVARCHAR(MAX) NULL, -- Optional for email login
    UserType NVARCHAR(20) NOT NULL CHECK (UserType IN ('passenger', 'driver', 'admin')),
    IsPhoneVerified BIT NOT NULL DEFAULT 0,
    IsEmailVerified BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    IsBlocked BIT NOT NULL DEFAULT 0,
    BlockedReason NVARCHAR(500) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    LastLoginAt DATETIME2 NULL,
    
    INDEX IX_Users_PhoneNumber (PhoneNumber),
    INDEX IX_Users_Email (Email),
    INDEX IX_Users_UserType (UserType)
);
```

**Sample Data:**
```sql
INSERT INTO Users (Id, PhoneNumber, Email, UserType, IsPhoneVerified, IsActive)
VALUES 
    ('A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6', '+919812345678', 'akhilesh@example.com', 'passenger', 1, 1),
    ('B2C3D4E5-F6G7-H8I9-J0K1-L2M3N4O5P6Q7', '+919876543210', 'rajesh.driver@example.com', 'driver', 1, 1);
```

---

## 2. UserProfiles Table

**Table Name:** `UserProfiles`

**Purpose:** Extended user profile information

```sql
CREATE TABLE UserProfiles (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL UNIQUE,
    Name NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NULL,
    Gender NVARCHAR(10) NULL CHECK (Gender IN ('male', 'female', 'other')),
    ProfilePicture NVARCHAR(500) NULL,
    Address NVARCHAR(500) NULL,
    City NVARCHAR(100) NULL,
    State NVARCHAR(100) NULL,
    PinCode NVARCHAR(10) NULL,
    EmergencyContact NVARCHAR(20) NULL,
    EmergencyContactName NVARCHAR(100) NULL,
    Rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    TotalRides INT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX IX_UserProfiles_UserId (UserId)
);
```

**Sample Data:**
```sql
INSERT INTO UserProfiles (Id, UserId, Name, DateOfBirth, Address, EmergencyContact, Rating, TotalRides)
VALUES 
    (NEWID(), 'A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6', 'Akhilesh Allewar', '1995-05-15', '123 Main St, Allapalli', '+919876543210', 4.8, 24),
    (NEWID(), 'B2C3D4E5-F6G7-H8I9-J0K1-L2M3N4O5P6Q7', 'Rajesh Kumar', '1988-08-20', '456 Driver Colony, Chandrapur', '+919123456789', 4.8, 156);
```

---

## 3. Drivers Table

**Table Name:** `Drivers`

**Purpose:** Driver-specific information and verification status

```sql
CREATE TABLE Drivers (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL UNIQUE,
    LicenseNumber NVARCHAR(50) NOT NULL UNIQUE,
    LicenseExpiryDate DATE NOT NULL,
    LicenseVerified BIT NOT NULL DEFAULT 0,
    AadharNumber NVARCHAR(12) NULL,
    AadharVerified BIT NOT NULL DEFAULT 0,
    PanNumber NVARCHAR(10) NULL,
    IsOnline BIT NOT NULL DEFAULT 0,
    IsAvailable BIT NOT NULL DEFAULT 0,
    IsVerified BIT NOT NULL DEFAULT 0,
    VerificationStatus NVARCHAR(20) CHECK (VerificationStatus IN ('pending', 'under_review', 'approved', 'rejected')),
    TotalEarnings DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PendingEarnings DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    AvailableForWithdrawal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    BankAccountNumber NVARCHAR(50) NULL,
    BankIFSC NVARCHAR(11) NULL,
    BankAccountHolderName NVARCHAR(100) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX IX_Drivers_UserId (UserId),
    INDEX IX_Drivers_IsOnline (IsOnline),
    INDEX IX_Drivers_IsAvailable (IsAvailable)
);
```

**Sample Data:**
```sql
INSERT INTO Drivers (Id, UserId, LicenseNumber, LicenseExpiryDate, LicenseVerified, IsVerified, VerificationStatus, TotalEarnings)
VALUES 
    (NEWID(), 'B2C3D4E5-F6G7-H8I9-J0K1-L2M3N4O5P6Q7', 'MH1234567890', '2028-12-31', 1, 1, 'approved', 125600.00);
```

---

## 4. Vehicles Table

**Table Name:** `Vehicles`

**Purpose:** Vehicle information for drivers

```sql
CREATE TABLE Vehicles (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DriverId UNIQUEIDENTIFIER NOT NULL,
    VehicleType NVARCHAR(20) NOT NULL CHECK (VehicleType IN ('auto', 'bike', 'car', 'shared_van', 'mini_bus', 'tempo_traveller')),
    Make NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    Year INT NOT NULL,
    RegistrationNumber NVARCHAR(20) NOT NULL UNIQUE,
    Color NVARCHAR(30) NOT NULL,
    TotalSeats INT NOT NULL,
    FuelType NVARCHAR(20) CHECK (FuelType IN ('petrol', 'diesel', 'cng', 'electric')),
    
    -- Registration Details
    RegistrationDocument NVARCHAR(500) NULL,
    RegistrationVerified BIT NOT NULL DEFAULT 0,
    RegistrationExpiryDate DATE NULL,
    
    -- Insurance Details
    InsuranceDocument NVARCHAR(500) NULL,
    InsuranceVerified BIT NOT NULL DEFAULT 0,
    InsuranceExpiryDate DATE NULL,
    
    -- Permit Details
    PermitDocument NVARCHAR(500) NULL,
    PermitVerified BIT NOT NULL DEFAULT 0,
    PermitExpiryDate DATE NULL,
    
    -- Vehicle Features (JSON string)
    Features NVARCHAR(MAX) NULL, -- ["AC", "Music System", "USB Charging"]
    
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (DriverId) REFERENCES Drivers(Id) ON DELETE CASCADE,
    INDEX IX_Vehicles_DriverId (DriverId),
    INDEX IX_Vehicles_RegistrationNumber (RegistrationNumber),
    INDEX IX_Vehicles_VehicleType (VehicleType)
);
```

**Sample Data:**
```sql
INSERT INTO Vehicles (Id, DriverId, VehicleType, Make, Model, Year, RegistrationNumber, Color, TotalSeats, FuelType, RegistrationVerified, InsuranceVerified, PermitVerified)
VALUES 
    (NEWID(), (SELECT Id FROM Drivers WHERE LicenseNumber = 'MH1234567890'), 'shared_van', 'Toyota', 'Innova Crysta', 2020, 'MH 34 AB 1234', 'White', 7, 'diesel', 1, 1, 1);
```

---

## 5. Rides Table

**Table Name:** `Rides`

**Purpose:** Scheduled rides by drivers

```sql
CREATE TABLE Rides (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RideNumber NVARCHAR(20) NOT NULL UNIQUE, -- DR2401, DR2402, etc.
    DriverId UNIQUEIDENTIFIER NOT NULL,
    VehicleId UNIQUEIDENTIFIER NOT NULL,
    
    -- Location Details
    PickupLocation NVARCHAR(500) NOT NULL,
    PickupLatitude DECIMAL(10,8) NOT NULL,
    PickupLongitude DECIMAL(11,8) NOT NULL,
    DropoffLocation NVARCHAR(500) NOT NULL,
    DropoffLatitude DECIMAL(10,8) NOT NULL,
    DropoffLongitude DECIMAL(11,8) NOT NULL,
    
    -- Schedule Details
    TravelDate DATE NOT NULL,
    DepartureTime TIME NOT NULL,
    EstimatedArrivalTime TIME NULL,
    ActualDepartureTime DATETIME2 NULL,
    ActualArrivalTime DATETIME2 NULL,
    
    -- Capacity
    TotalSeats INT NOT NULL,
    BookedSeats INT NOT NULL DEFAULT 0,
    AvailableSeats AS (TotalSeats - BookedSeats) PERSISTED,
    
    -- Pricing
    PricePerSeat DECIMAL(10,2) NOT NULL,
    EstimatedEarnings AS (BookedSeats * PricePerSeat) PERSISTED,
    
    -- Route Details
    Route NVARCHAR(MAX) NULL, -- JSON array of waypoints
    Distance DECIMAL(10,2) NULL, -- in kilometers
    Duration INT NULL, -- in minutes
    
    -- Status
    Status NVARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (Status IN ('scheduled', 'upcoming', 'active', 'completed', 'cancelled')),
    CancellationReason NVARCHAR(500) NULL,
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (DriverId) REFERENCES Drivers(Id),
    FOREIGN KEY (VehicleId) REFERENCES Vehicles(Id),
    INDEX IX_Rides_DriverId (DriverId),
    INDEX IX_Rides_RideNumber (RideNumber),
    INDEX IX_Rides_TravelDate (TravelDate),
    INDEX IX_Rides_Status (Status),
    INDEX IX_Rides_PickupLocation (PickupLocation),
    INDEX IX_Rides_DropoffLocation (DropoffLocation)
);
```

**Sample Data:**
```sql
INSERT INTO Rides (Id, RideNumber, DriverId, VehicleId, PickupLocation, PickupLatitude, PickupLongitude, DropoffLocation, DropoffLatitude, DropoffLongitude, TravelDate, DepartureTime, TotalSeats, BookedSeats, PricePerSeat, Distance, Status)
VALUES 
    (NEWID(), 'DR2401', 
     (SELECT Id FROM Drivers WHERE LicenseNumber = 'MH1234567890'),
     (SELECT Id FROM Vehicles WHERE RegistrationNumber = 'MH 34 AB 1234'),
     'Allapalli', 19.9876, 79.8765,
     'Chandrapur', 19.9506, 79.2961,
     '2025-11-09', '06:00:00', 7, 4, 850.00, 65.5, 'upcoming');
```

---

## 6. Bookings Table

**Table Name:** `Bookings`

**Purpose:** Passenger ride bookings

```sql
CREATE TABLE Bookings (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BookingNumber NVARCHAR(20) NOT NULL UNIQUE, -- ALR2401234, etc.
    RideId UNIQUEIDENTIFIER NOT NULL,
    PassengerId UNIQUEIDENTIFIER NOT NULL, -- References Users.Id
    
    -- Booking Details
    PassengerCount INT NOT NULL,
    SeatNumbers NVARCHAR(50) NULL, -- "1,2,3" comma-separated
    
    -- Location (can differ from ride's main route)
    PickupLocation NVARCHAR(500) NOT NULL,
    PickupLatitude DECIMAL(10,8) NOT NULL,
    PickupLongitude DECIMAL(11,8) NOT NULL,
    DropoffLocation NVARCHAR(500) NOT NULL,
    DropoffLatitude DECIMAL(10,8) NOT NULL,
    DropoffLongitude DECIMAL(11,8) NOT NULL,
    
    -- Pricing
    PricePerSeat DECIMAL(10,2) NOT NULL,
    TotalFare DECIMAL(10,2) NOT NULL,
    PlatformFee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    TotalAmount DECIMAL(10,2) NOT NULL,
    
    -- Verification
    OTP NVARCHAR(4) NOT NULL,
    QRCode NVARCHAR(MAX) NULL, -- Base64 encoded QR
    IsVerified BIT NOT NULL DEFAULT 0,
    VerifiedAt DATETIME2 NULL,
    
    -- Status
    Status NVARCHAR(20) NOT NULL DEFAULT 'confirmed' CHECK (Status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled', 'refunded')),
    CancellationType NVARCHAR(20) NULL CHECK (CancellationType IN ('passenger', 'driver', 'system')),
    CancellationReason NVARCHAR(500) NULL,
    CancelledAt DATETIME2 NULL,
    
    -- Payment
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (PaymentStatus IN ('pending', 'paid', 'refunded', 'failed')),
    PaymentMethod NVARCHAR(20) NULL CHECK (PaymentMethod IN ('cash', 'upi', 'card', 'wallet')),
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (RideId) REFERENCES Rides(Id),
    FOREIGN KEY (PassengerId) REFERENCES Users(Id),
    INDEX IX_Bookings_RideId (RideId),
    INDEX IX_Bookings_PassengerId (PassengerId),
    INDEX IX_Bookings_BookingNumber (BookingNumber),
    INDEX IX_Bookings_Status (Status),
    INDEX IX_Bookings_OTP (OTP)
);
```

**Sample Data:**
```sql
INSERT INTO Bookings (Id, BookingNumber, RideId, PassengerId, PassengerCount, PickupLocation, PickupLatitude, PickupLongitude, DropoffLocation, DropoffLatitude, DropoffLongitude, PricePerSeat, TotalFare, TotalAmount, OTP, Status, PaymentStatus, PaymentMethod)
VALUES 
    (NEWID(), 'ALR2401234', 
     (SELECT Id FROM Rides WHERE RideNumber = 'DR2401'),
     'A1B2C3D4-E5F6-G7H8-I9J0-K1L2M3N4O5P6',
     4, 'Allapalli', 19.9876, 79.8765, 'Chandrapur', 19.9506, 79.2961,
     850.00, 3400.00, 3400.00, '1234', 'confirmed', 'pending', 'cash');
```

---

## 7. Payments Table

**Table Name:** `Payments`

**Purpose:** Track all payment transactions

```sql
CREATE TABLE Payments (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TransactionId NVARCHAR(100) NOT NULL UNIQUE,
    BookingId UNIQUEIDENTIFIER NOT NULL,
    PassengerId UNIQUEIDENTIFIER NOT NULL,
    DriverId UNIQUEIDENTIFIER NOT NULL,
    
    Amount DECIMAL(10,2) NOT NULL,
    PlatformFee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    DriverAmount DECIMAL(10,2) NOT NULL,
    
    PaymentMethod NVARCHAR(20) NOT NULL CHECK (PaymentMethod IN ('cash', 'upi', 'card', 'wallet')),
    PaymentStatus NVARCHAR(20) NOT NULL CHECK (PaymentStatus IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    
    -- Gateway Details
    GatewayTransactionId NVARCHAR(200) NULL,
    GatewayResponse NVARCHAR(MAX) NULL, -- JSON
    
    ProcessedAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (BookingId) REFERENCES Bookings(Id),
    FOREIGN KEY (PassengerId) REFERENCES Users(Id),
    FOREIGN KEY (DriverId) REFERENCES Drivers(Id),
    INDEX IX_Payments_BookingId (BookingId),
    INDEX IX_Payments_TransactionId (TransactionId),
    INDEX IX_Payments_PaymentStatus (PaymentStatus)
);
```

---

## 8. Payouts Table

**Table Name:** `Payouts`

**Purpose:** Driver payout/withdrawal transactions

```sql
CREATE TABLE Payouts (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PayoutId NVARCHAR(50) NOT NULL UNIQUE,
    DriverId UNIQUEIDENTIFIER NOT NULL,
    
    Amount DECIMAL(10,2) NOT NULL,
    Method NVARCHAR(20) NOT NULL CHECK (Method IN ('bank_transfer', 'upi', 'cash')),
    
    -- Bank Details
    AccountNumber NVARCHAR(50) NULL,
    IFSC NVARCHAR(11) NULL,
    AccountHolderName NVARCHAR(100) NULL,
    UPIId NVARCHAR(50) NULL,
    
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    TransactionReference NVARCHAR(200) NULL,
    
    RequestedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ProcessedAt DATETIME2 NULL,
    CompletedAt DATETIME2 NULL,
    
    Remarks NVARCHAR(500) NULL,
    
    FOREIGN KEY (DriverId) REFERENCES Drivers(Id),
    INDEX IX_Payouts_DriverId (DriverId),
    INDEX IX_Payouts_Status (Status)
);
```

---

## 9. Ratings Table

**Table Name:** `Ratings`

**Purpose:** Ride ratings and reviews

```sql
CREATE TABLE Ratings (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BookingId UNIQUEIDENTIFIER NOT NULL,
    RideId UNIQUEIDENTIFIER NOT NULL,
    RatedBy UNIQUEIDENTIFIER NOT NULL, -- User who gave rating
    RatedTo UNIQUEIDENTIFIER NOT NULL, -- User who received rating
    RatingType NVARCHAR(20) NOT NULL CHECK (RatingType IN ('passenger_to_driver', 'driver_to_passenger')),
    
    Rating INT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    Review NVARCHAR(1000) NULL,
    
    -- Rating Categories (optional)
    BehaviorRating INT NULL CHECK (BehaviorRating >= 1 AND BehaviorRating <= 5),
    PunctualityRating INT NULL CHECK (PunctualityRating >= 1 AND PunctualityRating <= 5),
    VehicleConditionRating INT NULL CHECK (VehicleConditionRating >= 1 AND VehicleConditionRating <= 5),
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (BookingId) REFERENCES Bookings(Id),
    FOREIGN KEY (RideId) REFERENCES Rides(Id),
    FOREIGN KEY (RatedBy) REFERENCES Users(Id),
    FOREIGN KEY (RatedTo) REFERENCES Users(Id),
    INDEX IX_Ratings_BookingId (BookingId),
    INDEX IX_Ratings_RatedTo (RatedTo)
);
```

---

## 10. Notifications Table

**Table Name:** `Notifications`

**Purpose:** User notifications

```sql
CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    
    Type NVARCHAR(50) NOT NULL, -- ride_reminder, booking_confirmed, payment_received, etc.
    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(1000) NOT NULL,
    
    -- Additional Data (JSON)
    Data NVARCHAR(MAX) NULL, -- {"rideId": "uuid", "bookingId": "uuid"}
    
    IsRead BIT NOT NULL DEFAULT 0,
    ReadAt DATETIME2 NULL,
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX IX_Notifications_UserId (UserId),
    INDEX IX_Notifications_IsRead (IsRead),
    INDEX IX_Notifications_CreatedAt (CreatedAt DESC)
);
```

---

## 11. OTPVerifications Table

**Table Name:** `OTPVerifications`

**Purpose:** OTP verification for authentication

```sql
CREATE TABLE OTPVerifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber NVARCHAR(20) NOT NULL,
    OTP NVARCHAR(6) NOT NULL,
    Purpose NVARCHAR(20) NOT NULL CHECK (Purpose IN ('login', 'registration', 'password_reset')),
    
    IsUsed BIT NOT NULL DEFAULT 0,
    IsExpired BIT NOT NULL DEFAULT 0,
    ExpiresAt DATETIME2 NOT NULL,
    UsedAt DATETIME2 NULL,
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_OTPVerifications_PhoneNumber (PhoneNumber),
    INDEX IX_OTPVerifications_CreatedAt (CreatedAt DESC)
);
```

---

## 12. RefreshTokens Table

**Table Name:** `RefreshTokens`

**Purpose:** JWT refresh token management

```sql
CREATE TABLE RefreshTokens (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Token NVARCHAR(500) NOT NULL UNIQUE,
    
    ExpiresAt DATETIME2 NOT NULL,
    IsRevoked BIT NOT NULL DEFAULT 0,
    RevokedAt DATETIME2 NULL,
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX IX_RefreshTokens_UserId (UserId),
    INDEX IX_RefreshTokens_Token (Token)
);
```

---

## 13. RideTracking Table (Optional)

**Table Name:** `RideTracking`

**Purpose:** Store location history for rides

```sql
CREATE TABLE RideTracking (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RideId UNIQUEIDENTIFIER NOT NULL,
    DriverId UNIQUEIDENTIFIER NOT NULL,
    
    Latitude DECIMAL(10,8) NOT NULL,
    Longitude DECIMAL(11,8) NOT NULL,
    Speed DECIMAL(5,2) NULL, -- km/h
    Heading DECIMAL(5,2) NULL, -- degrees
    
    Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    FOREIGN KEY (RideId) REFERENCES Rides(Id),
    FOREIGN KEY (DriverId) REFERENCES Drivers(Id),
    INDEX IX_RideTracking_RideId (RideId),
    INDEX IX_RideTracking_Timestamp (Timestamp DESC)
);
```

---

## Entity Framework Core Models (C#)

### User.cs
```csharp
public class User
{
    public Guid Id { get; set; }
    public string PhoneNumber { get; set; }
    public string CountryCode { get; set; } = "+91";
    public string? Email { get; set; }
    public string? PasswordHash { get; set; }
    public string UserType { get; set; } // passenger, driver, admin
    public bool IsPhoneVerified { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsBlocked { get; set; }
    public string? BlockedReason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }
    
    // Navigation Properties
    public UserProfile? Profile { get; set; }
    public Driver? Driver { get; set; }
    public ICollection<Booking> Bookings { get; set; }
    public ICollection<Notification> Notifications { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; }
}
```

### UserProfile.cs
```csharp
public class UserProfile
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? ProfilePicture { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PinCode { get; set; }
    public string? EmergencyContact { get; set; }
    public string? EmergencyContactName { get; set; }
    public decimal Rating { get; set; }
    public int TotalRides { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation Property
    public User User { get; set; }
}
```

### Driver.cs
```csharp
public class Driver
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string LicenseNumber { get; set; }
    public DateTime LicenseExpiryDate { get; set; }
    public bool LicenseVerified { get; set; }
    public string? AadharNumber { get; set; }
    public bool AadharVerified { get; set; }
    public string? PanNumber { get; set; }
    public bool IsOnline { get; set; }
    public bool IsAvailable { get; set; }
    public bool IsVerified { get; set; }
    public string VerificationStatus { get; set; }
    public decimal TotalEarnings { get; set; }
    public decimal PendingEarnings { get; set; }
    public decimal AvailableForWithdrawal { get; set; }
    public string? BankAccountNumber { get; set; }
    public string? BankIFSC { get; set; }
    public string? BankAccountHolderName { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation Properties
    public User User { get; set; }
    public ICollection<Vehicle> Vehicles { get; set; }
    public ICollection<Ride> Rides { get; set; }
    public ICollection<Payout> Payouts { get; set; }
}
```

### Ride.cs
```csharp
public class Ride
{
    public Guid Id { get; set; }
    public string RideNumber { get; set; }
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
    
    public string PickupLocation { get; set; }
    public decimal PickupLatitude { get; set; }
    public decimal PickupLongitude { get; set; }
    public string DropoffLocation { get; set; }
    public decimal DropoffLatitude { get; set; }
    public decimal DropoffLongitude { get; set; }
    
    public DateTime TravelDate { get; set; }
    public TimeSpan DepartureTime { get; set; }
    public TimeSpan? EstimatedArrivalTime { get; set; }
    public DateTime? ActualDepartureTime { get; set; }
    public DateTime? ActualArrivalTime { get; set; }
    
    public int TotalSeats { get; set; }
    public int BookedSeats { get; set; }
    public decimal PricePerSeat { get; set; }
    
    public string? Route { get; set; } // JSON
    public decimal? Distance { get; set; }
    public int? Duration { get; set; }
    
    public string Status { get; set; }
    public string? CancellationReason { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation Properties
    public Driver Driver { get; set; }
    public Vehicle Vehicle { get; set; }
    public ICollection<Booking> Bookings { get; set; }
    public ICollection<Rating> Ratings { get; set; }
}
```

### Booking.cs
```csharp
public class Booking
{
    public Guid Id { get; set; }
    public string BookingNumber { get; set; }
    public Guid RideId { get; set; }
    public Guid PassengerId { get; set; }
    
    public int PassengerCount { get; set; }
    public string? SeatNumbers { get; set; }
    
    public string PickupLocation { get; set; }
    public decimal PickupLatitude { get; set; }
    public decimal PickupLongitude { get; set; }
    public string DropoffLocation { get; set; }
    public decimal DropoffLatitude { get; set; }
    public decimal DropoffLongitude { get; set; }
    
    public decimal PricePerSeat { get; set; }
    public decimal TotalFare { get; set; }
    public decimal PlatformFee { get; set; }
    public decimal TotalAmount { get; set; }
    
    public string OTP { get; set; }
    public string? QRCode { get; set; }
    public bool IsVerified { get; set; }
    public DateTime? VerifiedAt { get; set; }
    
    public string Status { get; set; }
    public string? CancellationType { get; set; }
    public string? CancellationReason { get; set; }
    public DateTime? CancelledAt { get; set; }
    
    public string PaymentStatus { get; set; }
    public string? PaymentMethod { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation Properties
    public Ride Ride { get; set; }
    public User Passenger { get; set; }
    public ICollection<Payment> Payments { get; set; }
    public ICollection<Rating> Ratings { get; set; }
}
```

---

## Indexes Strategy

**High-Priority Indexes:**
1. `Users.PhoneNumber` - Authentication lookups
2. `Rides.TravelDate + Status` - Ride search queries
3. `Bookings.PassengerId + Status` - User ride history
4. `Drivers.IsOnline + IsAvailable` - Driver availability search
5. `Rides.PickupLocation + DropoffLocation` - Route matching

**Composite Indexes:**
```sql
CREATE INDEX IX_Rides_Search ON Rides(TravelDate, Status, PickupLocation, DropoffLocation);
CREATE INDEX IX_Bookings_History ON Bookings(PassengerId, Status, CreatedAt DESC);
CREATE INDEX IX_Drivers_Available ON Drivers(IsOnline, IsAvailable, IsVerified);
```

---

## Stored Procedures (Optional)

### SP_SearchAvailableRides
```sql
CREATE PROCEDURE SP_SearchAvailableRides
    @PickupLocation NVARCHAR(500),
    @DropoffLocation NVARCHAR(500),
    @TravelDate DATE,
    @PassengerCount INT
AS
BEGIN
    SELECT 
        r.Id, r.RideNumber, r.DriverId, r.VehicleId,
        r.PickupLocation, r.DropoffLocation,
        r.TravelDate, r.DepartureTime,
        r.TotalSeats, r.BookedSeats, r.AvailableSeats,
        r.PricePerSeat,
        v.Make, v.Model, v.RegistrationNumber, v.VehicleType,
        up.Name AS DriverName, up.Rating AS DriverRating
    FROM Rides r
    INNER JOIN Vehicles v ON r.VehicleId = v.Id
    INNER JOIN Drivers d ON r.DriverId = d.Id
    INNER JOIN Users u ON d.UserId = u.Id
    INNER JOIN UserProfiles up ON u.Id = up.UserId
    WHERE r.PickupLocation LIKE '%' + @PickupLocation + '%'
        AND r.DropoffLocation LIKE '%' + @DropoffLocation + '%'
        AND r.TravelDate = @TravelDate
        AND r.AvailableSeats >= @PassengerCount
        AND r.Status = 'scheduled'
        AND d.IsVerified = 1
    ORDER BY r.DepartureTime;
END
```

---

## Migration Scripts

### Initial Migration
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Sample Migration Class
```csharp
public class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Users",
            columns: table => new
            {
                Id = table.Column<Guid>(nullable: false),
                PhoneNumber = table.Column<string>(maxLength: 20, nullable: false),
                // ... other columns
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Users", x => x.Id);
            });
            
        // ... other tables
    }
}
```

---

## Data Seeding

### Seed Default Data
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Seed Admin User
    modelBuilder.Entity<User>().HasData(
        new User
        {
            Id = Guid.NewGuid(),
            PhoneNumber = "+919999999999",
            UserType = "admin",
            IsPhoneVerified = true,
            IsActive = true
        }
    );
}
```

---

## Connection String

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=AllapalliRide;User Id=sa;Password=YourPassword;TrustServerCertificate=True;"
  }
}
```

---

This schema supports all features in your Flutter app and is optimized for SQL Server with Entity Framework Core 8.

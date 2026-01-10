-- Create Coupons table
CREATE TABLE Coupons (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200) NULL,
    DiscountType NVARCHAR(20) NOT NULL DEFAULT 'Fixed',
    DiscountValue DECIMAL(10, 2) NOT NULL,
    MaxDiscountAmount DECIMAL(10, 2) NULL,
    MinOrderAmount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    TotalUsageLimit INT NULL,
    UsageCount INT NOT NULL DEFAULT 0,
    PerUserUsageLimit INT NOT NULL DEFAULT 1,
    ValidFrom DATETIME2 NOT NULL,
    ValidUntil DATETIME2 NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    IsFirstTimeUserOnly BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NULL
);

-- Create indexes for Coupons
CREATE INDEX IX_Coupons_Code ON Coupons(Code);
CREATE INDEX IX_Coupons_IsActive ON Coupons(IsActive);
CREATE INDEX IX_Coupons_ValidDates ON Coupons(ValidFrom, ValidUntil);

-- Create CouponUsages table
CREATE TABLE CouponUsages (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CouponId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    BookingId UNIQUEIDENTIFIER NOT NULL,
    DiscountApplied DECIMAL(10, 2) NOT NULL,
    UsedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_CouponUsages_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(Id),
    CONSTRAINT FK_CouponUsages_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_CouponUsages_Bookings FOREIGN KEY (BookingId) REFERENCES Bookings(Id)
);

-- Create indexes for CouponUsages
CREATE INDEX IX_CouponUsages_CouponId_UserId ON CouponUsages(CouponId, UserId);
CREATE INDEX IX_CouponUsages_BookingId ON CouponUsages(BookingId);

-- Insert sample coupons
INSERT INTO Coupons (Id, Code, Description, DiscountType, DiscountValue, MaxDiscountAmount, MinOrderAmount, TotalUsageLimit, UsageCount, PerUserUsageLimit, ValidFrom, ValidUntil, IsActive, IsFirstTimeUserOnly, CreatedAt)
VALUES 
    (NEWID(), 'FIRST10', 'Get 10% off on your first booking', 'Percentage', 10, 50, 100, NULL, 0, 1, GETUTCDATE(), DATEADD(YEAR, 1, GETUTCDATE()), 1, 1, GETUTCDATE()),
    (NEWID(), 'SAVE50', 'Save ₹50 on your booking', 'Fixed', 50, NULL, 200, 1000, 0, 1, GETUTCDATE(), DATEADD(MONTH, 6, GETUTCDATE()), 1, 0, GETUTCDATE()),
    (NEWID(), 'NEWUSER', 'Get 15% off for new users', 'Percentage', 15, 100, 150, NULL, 0, 1, GETUTCDATE(), DATEADD(YEAR, 1, GETUTCDATE()), 1, 1, GETUTCDATE()),
    (NEWID(), 'WELCOME20', 'Welcome! Get 20% off', 'Percentage', 20, 100, 200, 500, 0, 1, GETUTCDATE(), DATEADD(MONTH, 3, GETUTCDATE()), 1, 1, GETUTCDATE()),
    (NEWID(), 'FLAT100', 'Flat ₹100 off on booking above ₹500', 'Fixed', 100, NULL, 500, 200, 0, 1, GETUTCDATE(), DATEADD(MONTH, 2, GETUTCDATE()), 1, 0, GETUTCDATE());

PRINT 'Coupon tables created and sample data inserted successfully!';

-- Create a test banner for the passenger app
INSERT INTO Banners (
    Id,
    Title,
    Description,
    ImageUrl,
    ActionUrl,
    ActionType,
    ActionText,
    DisplayOrder,
    StartDate,
    EndDate,
    IsActive,
    TargetAudience,
    ImpressionCount,
    ClickCount,
    CreatedAt,
    UpdatedAt
) VALUES (
    NEWID(),
    'Welcome to VanYatra! 🚐',
    'Book your comfortable ride today. Safe, reliable, and affordable transportation at your service.',
    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
    NULL,
    'none',
    NULL,
    1,
    GETUTCDATE(),
    DATEADD(YEAR, 1, GETUTCDATE()),
    1,
    'passenger',
    0,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Create another banner
INSERT INTO Banners (
    Id,
    Title,
    Description,
    ImageUrl,
    ActionUrl,
    ActionType,
    ActionText,
    DisplayOrder,
    StartDate,
    EndDate,
    IsActive,
    TargetAudience,
    ImpressionCount,
    ClickCount,
    CreatedAt,
    UpdatedAt
) VALUES (
    NEWID(),
    'Special Offer! 🎉',
    'Get 20% off on your next 3 rides. Limited time offer for new passengers.',
    'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800&q=80',
    NULL,
    'none',
    'Book Now',
    2,
    GETUTCDATE(),
    DATEADD(MONTH, 3, GETUTCDATE()),
    1,
    'passenger',
    0,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Verify the banners were created
SELECT Id, Title, IsActive, TargetAudience, StartDate, EndDate 
FROM Banners 
WHERE IsActive = 1 AND TargetAudience IN ('passenger', 'all');

using System;
using System.Data.SqlClient;

class Program
{
    static void Main()
    {
        var connectionString = "Server=localhost,1433;Database=RideSharingDb;User Id=sa;Password=Akhilesh@22;TrustServerCertificate=True;";
        
        using (var connection = new SqlConnection(connectionString))
        {
            connection.Open();
            
            // Banner 1
            var sql1 = @"
                INSERT INTO Banners (Id, Title, Description, ImageUrl, ActionType, DisplayOrder, StartDate, EndDate, IsActive, TargetAudience, ImpressionCount, ClickCount, CreatedAt, UpdatedAt)
                VALUES (NEWID(), 'Welcome to VanYatra! 🚐', 'Book your comfortable ride today. Safe, reliable, and affordable transportation.', 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80', 'none', 1, GETUTCDATE(), DATEADD(YEAR, 1, GETUTCDATE()), 1, 'passenger', 0, 0, GETUTCDATE(), GETUTCDATE());
            ";
            
            // Banner 2
            var sql2 = @"
                INSERT INTO Banners (Id, Title, Description, ImageUrl, ActionType, ActionText, DisplayOrder, StartDate, EndDate, IsActive, TargetAudience, ImpressionCount, ClickCount, CreatedAt, UpdatedAt)
                VALUES (NEWID(), 'Special Offer! 🎉', 'Get 20% off on your next 3 rides. Limited time offer.', 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800&q=80', 'none', 'Book Now', 2, GETUTCDATE(), DATEADD(MONTH, 3, GETUTCDATE()), 1, 'passenger', 0, 0, GETUTCDATE(), GETUTCDATE());
            ";
            
            using (var cmd1 = new SqlCommand(sql1, connection))
            {
                cmd1.ExecuteNonQuery();
                Console.WriteLine("✅ Banner 1 created successfully");
            }
            
            using (var cmd2 = new SqlCommand(sql2, connection))
            {
                cmd2.ExecuteNonQuery();
                Console.WriteLine("✅ Banner 2 created successfully");
            }
            
            // Verify
            var verifySql = "SELECT COUNT(*) FROM Banners WHERE IsActive = 1 AND TargetAudience IN ('passenger', 'all')";
            using (var verifyCmd = new SqlCommand(verifySql, connection))
            {
                var count = (int)verifyCmd.ExecuteScalar();
                Console.WriteLine($"📊 Total active passenger banners: {count}");
            }
        }
    }
}

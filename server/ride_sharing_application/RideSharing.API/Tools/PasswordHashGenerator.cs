using RideSharing.API.Helpers;

namespace RideSharing.API.Tools
{
    /// <summary>
    /// Utility class to generate BCrypt password hashes for admin users
    /// Usage: Call GeneratePasswordHash() from Program.cs or use as a console app
    /// </summary>
    public static class PasswordHashGenerator
    {
        /// <summary>
        /// Generate BCrypt hash for a given password
        /// </summary>
        public static void GeneratePasswordHash(string password)
        {
            var hash = PasswordHelper.HashPassword(password);
            Console.WriteLine("========================================");
            Console.WriteLine($"Password: {password}");
            Console.WriteLine($"BCrypt Hash: {hash}");
            Console.WriteLine("========================================");
            Console.WriteLine();
            Console.WriteLine("SQL Query to update admin password:");
            Console.WriteLine($"UPDATE Users SET PasswordHash = '{hash}', UpdatedAt = GETUTCDATE() WHERE Email = 'admin@allapalliride.com';");
            Console.WriteLine("========================================");
        }

        /// <summary>
        /// Generate hashes for common admin passwords
        /// </summary>
        public static void GenerateCommonPasswords()
        {
            Console.WriteLine("\n=== BCrypt Password Hash Generator ===\n");
            
            var commonPasswords = new[] 
            { 
                "Admin@123", 
                "admin123", 
                "password123"
            };

            foreach (var password in commonPasswords)
            {
                GeneratePasswordHash(password);
                Console.WriteLine();
            }
        }
    }
}

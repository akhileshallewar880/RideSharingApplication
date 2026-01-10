using System;

namespace PasswordHashGenerator
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("\n=== BCrypt Password Hash Generator ===\n");

            // Generate hash for Akhilesh@123
            string password = "Akhilesh@123";
            string hash = BCrypt.Net.BCrypt.HashPassword(password, 11);

            Console.WriteLine($"Password: {password}");
            Console.WriteLine($"BCrypt Hash: {hash}");
            Console.WriteLine("\n========================================\n");
            Console.WriteLine("SQL Query to update admin password:");
            Console.WriteLine($"UPDATE Users SET PasswordHash = '{hash}', UpdatedAt = GETUTCDATE() WHERE Email = 'akhileshallewar880@gmail.com';\n");
            Console.WriteLine("========================================\n");
        }
    }
}

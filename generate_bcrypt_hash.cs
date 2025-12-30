using System;
using BCrypt.Net;

public class GenerateBCryptHash
{
    public static void Main(string[] args)
    {
        string password = "Admin@123";
        string hash = BCrypt.Net.BCrypt.HashPassword(password, 11);
        Console.WriteLine($"Password: {password}");
        Console.WriteLine($"BCrypt Hash: {hash}");
        
        // Verify it works
        bool verified = BCrypt.Net.BCrypt.Verify(password, hash);
        Console.WriteLine($"Verification: {verified}");
    }
}

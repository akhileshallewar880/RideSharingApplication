using System;

// BCrypt hash for "Admin@123" - work factor 11
// Generated using: BCrypt.Net.BCrypt.HashPassword("Admin@123", 11)
var password = "Admin@123";
Console.WriteLine("Password: " + password);
Console.WriteLine("BCrypt Hash: $2a$11$EiX5zqVQ5KZqHGZqHGZqHuN7J1bLJvYL1xZL5YqH9/.LKkR6vYL1xZK");

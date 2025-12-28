#!/usr/bin/env dotnet script
#r "nuget: BCrypt.Net-Next, 4.0.3"
using System;

var password = "Admin@123";
var hash = BCrypt.Net.BCrypt.HashPassword(password, 11);

Console.WriteLine($"\nPassword: {password}");
Console.WriteLine($"BCrypt Hash: {hash}\n");
Console.WriteLine("SQL Query to update admin password:");
Console.WriteLine($"UPDATE Users SET PasswordHash = '{hash}', UpdatedAt = GETUTCDATE() WHERE Email = 'admin@allapalliride.com';\n");

// Generate correct BCrypt hash for admin password
// Run: dotnet script generate_correct_admin_hash.csx

#r "nuget: BCrypt.Net-Next, 4.0.3"

using BCrypt.Net;

string password = "Admin@123";
int workFactor = 11;

Console.WriteLine("Generating BCrypt hash for admin password...");
Console.WriteLine($"Password: {password}");
Console.WriteLine($"Work Factor: {workFactor}");
Console.WriteLine();

string hash = BCrypt.HashPassword(password, workFactor);

Console.WriteLine("Generated Hash:");
Console.WriteLine(hash);
Console.WriteLine();

// Verify the hash works
bool isValid = BCrypt.Verify(password, hash);
Console.WriteLine($"Verification Test: {(isValid ? "✅ PASSED" : "❌ FAILED")}");
Console.WriteLine();

Console.WriteLine("SQL Command:");
Console.WriteLine("============");
Console.WriteLine($"DECLARE @AdminPassword NVARCHAR(MAX) = '{hash}';");

namespace RideSharing.API.Helpers
{
    /// <summary>
    /// Helper class for password hashing and verification using BCrypt
    /// </summary>
    public static class PasswordHelper
    {
        /// <summary>
        /// Hash a password using BCrypt with default work factor (11)
        /// </summary>
        /// <param name="password">Plain text password</param>
        /// <returns>BCrypt hashed password</returns>
        public static string HashPassword(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password, 11);
        }

        /// <summary>
        /// Verify a password against a BCrypt hash
        /// </summary>
        /// <param name="password">Plain text password to verify</param>
        /// <param name="hash">BCrypt hash to compare against</param>
        /// <returns>True if password matches hash, false otherwise</returns>
        public static bool VerifyPassword(string password, string hash)
        {
            try
            {
                return BCrypt.Net.BCrypt.Verify(password, hash);
            }
            catch
            {
                return false;
            }
        }
    }
}

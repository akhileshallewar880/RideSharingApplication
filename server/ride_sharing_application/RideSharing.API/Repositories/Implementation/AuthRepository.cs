using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class AuthRepository : IAuthRepository
    {
        private readonly RideSharingDbContext _context;

        public AuthRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<OTPVerification> CreateOTPAsync(string phoneNumber, string otp, string purpose)
        {
            var otpVerification = new OTPVerification
            {
                Id = Guid.NewGuid(),
                PhoneNumber = phoneNumber,
                OTP = otp,
                Purpose = purpose,
                IsUsed = false,
                IsExpired = false,
                ExpiresAt = DateTime.UtcNow.AddMinutes(5),
                CreatedAt = DateTime.UtcNow
            };

            await _context.OTPVerifications.AddAsync(otpVerification);
            await _context.SaveChangesAsync();
            return otpVerification;
        }

        public async Task<OTPVerification?> GetValidOTPAsync(string phoneNumber, string otp, string otpId)
        {
            return await _context.OTPVerifications
                .FirstOrDefaultAsync(o => 
                    o.Id.ToString() == otpId &&
                    o.PhoneNumber == phoneNumber &&
                    o.OTP == otp &&
                    !o.IsUsed &&
                    !o.IsExpired &&
                    o.ExpiresAt > DateTime.UtcNow);
        }

        public async Task MarkOTPAsUsedAsync(Guid otpId)
        {
            var otp = await _context.OTPVerifications.FindAsync(otpId);
            if (otp != null)
            {
                otp.IsUsed = true;
                otp.UsedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

        public async Task<User?> GetUserByPhoneAsync(string phoneNumber)
        {
            var user = await _context.Users
                .Include(u => u.Profile)
                .Include(u => u.Driver)
                .FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);
            
            // Debug logging
            if (user == null)
            {
                var allPhones = await _context.Users.Select(u => u.PhoneNumber).ToListAsync();
                Console.WriteLine($"[DEBUG] Looking for: '{phoneNumber}' | Found: NULL | All phones in DB: {string.Join(", ", allPhones.Select(p => $"'{p}'"))}");
            }
            else
            {
                Console.WriteLine($"[DEBUG] Looking for: '{phoneNumber}' | Found: '{user.PhoneNumber}' | Match: {user.PhoneNumber == phoneNumber}");
            }
            
            return user;
        }

        public async Task<User> CreateUserAsync(User user)
        {
            Console.WriteLine($"[DEBUG] CreateUserAsync - Adding user with Phone: '{user.PhoneNumber}', ID: {user.Id}");
            
            await _context.Users.AddAsync(user);
            await _context.SaveChangesAsync();
            
            // Verify it was saved
            var saved = await _context.Users.FirstOrDefaultAsync(u => u.Id == user.Id);
            Console.WriteLine($"[DEBUG] CreateUserAsync - User saved: {saved != null}, Phone in DB: '{saved?.PhoneNumber}'");
            
            return user;
        }

        public async Task<UserProfile> CreateUserProfileAsync(UserProfile profile)
        {
            await _context.UserProfiles.AddAsync(profile);
            await _context.SaveChangesAsync();
            return profile;
        }

        public async Task<RefreshToken> CreateRefreshTokenAsync(RefreshToken token)
        {
            await _context.RefreshTokens.AddAsync(token);
            await _context.SaveChangesAsync();
            return token;
        }

        public async Task<RefreshToken?> GetRefreshTokenAsync(string token)
        {
            return await _context.RefreshTokens
                .FirstOrDefaultAsync(t => 
                    t.Token == token &&
                    !t.IsRevoked &&
                    t.ExpiresAt > DateTime.UtcNow);
        }

        public async Task RevokeRefreshTokenAsync(Guid tokenId)
        {
            var token = await _context.RefreshTokens.FindAsync(tokenId);
            if (token != null)
            {
                token.IsRevoked = true;
                token.RevokedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

        public async Task RevokeAllUserTokensAsync(Guid userId)
        {
            var tokens = await _context.RefreshTokens
                .Where(t => t.UserId == userId && !t.IsRevoked)
                .ToListAsync();

            foreach (var token in tokens)
            {
                token.IsRevoked = true;
                token.RevokedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }
    }
}

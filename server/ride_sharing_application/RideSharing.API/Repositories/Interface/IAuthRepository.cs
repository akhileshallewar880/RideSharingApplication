using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface IAuthRepository
    {
        Task<OTPVerification> CreateOTPAsync(string phoneNumber, string otp, string purpose);
        Task<OTPVerification?> GetValidOTPAsync(string phoneNumber, string otp, string otpId);
        Task MarkOTPAsUsedAsync(Guid otpId);
        Task<User?> GetUserByPhoneAsync(string phoneNumber);
        Task<User> CreateUserAsync(User user);
        Task<UserProfile> CreateUserProfileAsync(UserProfile profile);
        Task<RefreshToken> CreateRefreshTokenAsync(RefreshToken token);
        Task<RefreshToken?> GetRefreshTokenAsync(string token);
        Task RevokeRefreshTokenAsync(Guid tokenId);
        Task RevokeAllUserTokensAsync(Guid userId);
    }
}

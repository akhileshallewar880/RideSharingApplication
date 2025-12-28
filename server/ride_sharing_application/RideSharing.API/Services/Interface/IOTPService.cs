namespace RideSharing.API.Services.Interface
{
    public interface IOTPService
    {
        /// <summary>
        /// Generate a random 4-digit OTP
        /// </summary>
        string GenerateOTP();

        /// <summary>
        /// Send OTP via SMS to the provided phone number
        /// </summary>
        Task<bool> SendOTPAsync(string phoneNumber, string otp);
    }
}

namespace RideSharing.API.Services.Interface
{
    public interface IEmailService
    {
        /// <summary>
        /// Send password reset email with reset token
        /// </summary>
        Task<bool> SendPasswordResetEmailAsync(string toEmail, string resetToken, string resetUrl);
        
        /// <summary>
        /// Send generic email
        /// </summary>
        Task<bool> SendEmailAsync(string toEmail, string subject, string body);
    }
}

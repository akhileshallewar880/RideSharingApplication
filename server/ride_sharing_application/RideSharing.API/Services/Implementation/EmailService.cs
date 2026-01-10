using System.Net;
using System.Net.Mail;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string resetToken, string resetUrl)
        {
            var subject = "Password Reset Request - Allapalli Ride Sharing";
            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
        .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
        .button {{ display: inline-block; padding: 12px 30px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
        .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
        .token-box {{ background-color: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 5px; font-family: monospace; font-size: 16px; letter-spacing: 2px; text-align: center; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>Password Reset Request</h1>
        </div>
        <div class='content'>
            <p>Hello,</p>
            <p>We received a request to reset your password for your Allapalli Ride Sharing admin account.</p>
            
            <p>Click the button below to reset your password:</p>
            <a href='{resetUrl}' class='button'>Reset Password</a>
            
            <p>Or copy and paste this reset code:</p>
            <div class='token-box'>{resetToken}</div>
            
            <p><strong>This reset link will expire in 15 minutes.</strong></p>
            
            <p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
            
            <p>For security reasons, never share this reset link with anyone.</p>
        </div>
        <div class='footer'>
            <p>&copy; 2025 Allapalli Ride Sharing. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>";

            return await SendEmailAsync(toEmail, subject, body);
        }

        public async Task<bool> SendEmailAsync(string toEmail, string subject, string body)
        {
            try
            {
                // Get SMTP settings from configuration
                var smtpHost = _configuration["Email:SmtpHost"];
                var smtpPortString = _configuration["Email:SmtpPort"];
                var smtpPort = !string.IsNullOrEmpty(smtpPortString) ? int.Parse(smtpPortString) : 587;
                var smtpUsername = _configuration["Email:Username"];
                var smtpPassword = _configuration["Email:Password"];
                var fromEmail = _configuration["Email:FromEmail"] ?? smtpUsername;
                var fromName = _configuration["Email:FromName"] ?? "Allapalli Ride Sharing";

                // If SMTP is not configured, log and return false (development mode)
                if (string.IsNullOrEmpty(smtpHost) || string.IsNullOrEmpty(smtpUsername))
                {
                    _logger.LogWarning("SMTP not configured. Email would be sent to: {ToEmail}", toEmail);
                    _logger.LogInformation("Password reset token would be sent in email. In production, configure SMTP settings in appsettings.json");
                    
                    // In development, just log the email content
                    _logger.LogInformation("Email Subject: {Subject}", subject);
                    _logger.LogInformation("Email would contain reset instructions for: {ToEmail}", toEmail);
                    
                    return true; // Return true for development
                }

                using var smtpClient = new SmtpClient(smtpHost, smtpPort)
                {
                    Credentials = new NetworkCredential(smtpUsername, smtpPassword),
                    EnableSsl = true
                };

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(fromEmail, fromName),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };
                mailMessage.To.Add(toEmail);

                await smtpClient.SendMailAsync(mailMessage);
                _logger.LogInformation("Password reset email sent successfully to: {ToEmail}", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to: {ToEmail}", toEmail);
                return false;
            }
        }
    }
}

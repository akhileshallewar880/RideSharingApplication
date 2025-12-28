using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    public class OTPService : IOTPService
    {
        private readonly ILogger<OTPService> _logger;
        private readonly IConfiguration _configuration;

        public OTPService(ILogger<OTPService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        public string GenerateOTP()
        {
            var random = new Random();
            return random.Next(1000, 9999).ToString();
        }

        public async Task<bool> SendOTPAsync(string phoneNumber, string otp)
        {
            try
            {
                // TODO: Integrate with SMS provider (Twilio, AWS SNS, MSG91, etc.)
                // For now, just log the OTP (DEVELOPMENT ONLY - REMOVE IN PRODUCTION)
                
                _logger.LogInformation($"[DEV MODE] OTP for {phoneNumber}: {otp}");
                
                // Simulate SMS sending delay
                await Task.Delay(100);
                
                // In production, uncomment and implement actual SMS sending:
                /*
                var twilioAccountSid = _configuration["Twilio:AccountSid"];
                var twilioAuthToken = _configuration["Twilio:AuthToken"];
                var twilioPhoneNumber = _configuration["Twilio:PhoneNumber"];
                
                // Example using Twilio:
                // TwilioClient.Init(twilioAccountSid, twilioAuthToken);
                // var message = await MessageResource.CreateAsync(
                //     body: $"Your RideSharing OTP is: {otp}. Valid for 5 minutes.",
                //     from: new PhoneNumber(twilioPhoneNumber),
                //     to: new PhoneNumber(phoneNumber)
                // );
                // return message.Status != MessageResource.StatusEnum.Failed;
                */
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send OTP to {phoneNumber}");
                return false;
            }
        }
    }
}

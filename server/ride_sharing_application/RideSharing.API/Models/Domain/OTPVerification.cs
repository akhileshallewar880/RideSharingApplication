using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class OTPVerification
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string PhoneNumber { get; set; }
        
        [Required]
        [MaxLength(6)]
        public string OTP { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string Purpose { get; set; } // login, registration, password_reset
        
        public bool IsUsed { get; set; }
        public bool IsExpired { get; set; }
        
        public DateTime ExpiresAt { get; set; }
        public DateTime? UsedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class User
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string PhoneNumber { get; set; }
        
        [MaxLength(5)]
        public string CountryCode { get; set; } = "+91";
        
        [MaxLength(255)]
        public string? Email { get; set; }
        
        public string? PasswordHash { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string UserType { get; set; } // passenger, driver, admin
        
        public bool IsPhoneVerified { get; set; }
        public bool IsEmailVerified { get; set; }
        public bool IsActive { get; set; } = true;
        public bool IsBlocked { get; set; }
        
        [MaxLength(500)]
        public string? BlockedReason { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastLoginAt { get; set; }
        
        [MaxLength(512)]
        public string? FCMToken { get; set; }
        
        // Navigation Properties
        public UserProfile? Profile { get; set; }
        public Driver? Driver { get; set; }
        public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    }
}

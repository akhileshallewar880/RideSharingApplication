using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class UserProfile
    {
        public Guid Id { get; set; }
        
        [Required]
        public Guid UserId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }
        
        public DateTime? DateOfBirth { get; set; }
        
        [MaxLength(10)]
        public string? Gender { get; set; } // male, female, other
        
        [MaxLength(500)]
        public string? ProfilePicture { get; set; }
        
        [MaxLength(500)]
        public string? Address { get; set; }
        
        [MaxLength(100)]
        public string? City { get; set; }
        
        [MaxLength(100)]
        public string? State { get; set; }
        
        [MaxLength(10)]
        public string? PinCode { get; set; }
        
        [MaxLength(20)]
        public string? EmergencyContact { get; set; }
        
        [MaxLength(100)]
        public string? EmergencyContactName { get; set; }
        
        public decimal Rating { get; set; }
        public int TotalRides { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Property
        public User User { get; set; }
    }
}

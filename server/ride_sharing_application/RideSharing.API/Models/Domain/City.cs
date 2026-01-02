using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class City
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string State { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string District { get; set; }
        
        [MaxLength(200)]
        public string? SubLocation { get; set; }
        
        [MaxLength(10)]
        public string? Pincode { get; set; }
        
        public float? Latitude { get; set; }
        public float? Longitude { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public ICollection<Driver> Drivers { get; set; } = new List<Driver>();
    }
}

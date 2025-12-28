using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class VehicleModel
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Brand { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string Type { get; set; } // car, suv, van, bus
        
        [Required]
        public int SeatingCapacity { get; set; }
        
        // Seating layout stored as JSON string
        // Example: {"layout":"2-2-3","rows":3,"seats":[{"id":"P1","row":1,"position":"left"},{"id":"P2","row":1,"position":"right"}]}
        public string? SeatingLayout { get; set; }
        
        [MaxLength(500)]
        public string? ImageUrl { get; set; }
        
        // Features stored as JSON array string
        public string? Features { get; set; } // ["AC", "Music System", "GPS"]
        
        public bool IsActive { get; set; } = true;
        
        [MaxLength(1000)]
        public string? Description { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}

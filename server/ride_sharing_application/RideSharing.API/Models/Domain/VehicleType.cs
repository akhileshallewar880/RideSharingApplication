using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class VehicleType
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } // Internal identifier: auto, bike, car, shared_van, mini_bus, tempo_traveller
        
        [Required]
        [MaxLength(100)]
        public string DisplayName { get; set; } // User-friendly name: "Auto Rickshaw", "Motorcycle", "Car", etc.
        
        [MaxLength(200)]
        public string? Icon { get; set; } // Icon name or URL for UI display
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        public decimal BasePrice { get; set; } = 0; // Base fare
        
        public decimal PricePerKm { get; set; } = 0; // Rate per kilometer
        
        public decimal PricePerMinute { get; set; } = 0; // Rate per minute
        
        public int MinSeats { get; set; } = 1;
        
        public int MaxSeats { get; set; } = 4;
        
        public bool IsActive { get; set; } = true;
        
        public int DisplayOrder { get; set; } = 0; // For sorting in UI
        
        [MaxLength(100)]
        public string? Category { get; set; } // personal, shared, commercial
        
        // Features stored as JSON array string
        public string? Features { get; set; } // ["AC", "Luggage Space", "Pet Friendly"]
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}

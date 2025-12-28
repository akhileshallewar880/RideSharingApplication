using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Vehicle
    {
        public Guid Id { get; set; }
        
        [Required]
        public Guid DriverId { get; set; }
        
        public Guid? VehicleModelId { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string VehicleType { get; set; } // auto, bike, car, shared_van, mini_bus, tempo_traveller
        
        [Required]
        [MaxLength(50)]
        public string Make { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Model { get; set; }
        
        [Required]
        public int Year { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string RegistrationNumber { get; set; }
        
        [Required]
        [MaxLength(30)]
        public string Color { get; set; }
        
        [Required]
        public int TotalSeats { get; set; }
        
        [MaxLength(20)]
        public string? FuelType { get; set; } // petrol, diesel, cng, electric
        
        // Registration Details
        [MaxLength(500)]
        public string? RegistrationDocument { get; set; }
        
        public bool RegistrationVerified { get; set; }
        public DateTime? RegistrationExpiryDate { get; set; }
        
        // Insurance Details
        [MaxLength(500)]
        public string? InsuranceDocument { get; set; }
        
        public bool InsuranceVerified { get; set; }
        public DateTime? InsuranceExpiryDate { get; set; }
        
        // Permit Details
        [MaxLength(500)]
        public string? PermitDocument { get; set; }
        
        public bool PermitVerified { get; set; }
        public DateTime? PermitExpiryDate { get; set; }
        
        // Vehicle Features (JSON string)
        public string? Features { get; set; } // ["AC", "Music System", "USB Charging"]
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public Driver Driver { get; set; }
        public VehicleModel? VehicleModel { get; set; }
        public ICollection<Ride> Rides { get; set; } = new List<Ride>();
    }
}

using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Ride
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string RideNumber { get; set; }
        
        [Required]
        public Guid DriverId { get; set; }
        
        [Required]
        public Guid VehicleId { get; set; }
        
        // Optional: Link to vehicle model catalog
        public Guid? VehicleModelId { get; set; }
        
        // Location Details
        [Required]
        [MaxLength(500)]
        public string PickupLocation { get; set; }
        
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        
        [Required]
        [MaxLength(500)]
        public string DropoffLocation { get; set; }
        
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        
        // Intermediate Stops (JSON array of location strings)
        public string? IntermediateStops { get; set; } // ["Bhamragarh", "Mul"]
        
        // Segment Pricing (JSON array of segment price objects)
        public string? SegmentPrices { get; set; } // [{"fromLocation":"...","toLocation":"...","price":300,...}]
        
        // Schedule Details
        public DateTime TravelDate { get; set; }
        public TimeSpan DepartureTime { get; set; }
        public TimeSpan? EstimatedArrivalTime { get; set; }
        public DateTime? ActualDepartureTime { get; set; }
        public DateTime? ActualArrivalTime { get; set; }
        
        // Capacity
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats => TotalSeats - BookedSeats;
        
        // Pricing
        public decimal PricePerSeat { get; set; }
        public decimal EstimatedEarnings => BookedSeats * PricePerSeat;
        
        // Route Details
        public string? Route { get; set; } // JSON array of waypoints
        public decimal? Distance { get; set; } // in kilometers
        public int? Duration { get; set; } // in minutes
        // Pre-computed per-stop cumulative timing (JSON) — set at schedule time, read at search time
        // [{"location":"Gadchiroli","cumulativeDistanceKm":0,"cumulativeDurationMinutes":0}, ...]
        public string? RouteStopsTimingJson { get; set; }
        
        // Status
        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "scheduled"; // scheduled, upcoming, active, completed, cancelled
        
        [MaxLength(500)]
        public string? CancellationReason { get; set; }
        
        // Return Trip Support
        public bool IsReturnTrip { get; set; } = false;
        public Guid? LinkedReturnRideId { get; set; }
        
        // Admin Features
        [MaxLength(1000)]
        public string? AdminNotes { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public Driver Driver { get; set; }
        public Vehicle Vehicle { get; set; }
        public VehicleModel? VehicleModel { get; set; }
        public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
        public ICollection<Rating> Ratings { get; set; } = new List<Rating>();
    }
}

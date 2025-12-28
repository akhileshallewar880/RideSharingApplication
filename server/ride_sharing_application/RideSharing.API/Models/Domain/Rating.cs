using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Rating
    {
        public Guid Id { get; set; }
        
        [Required]
        public Guid BookingId { get; set; }
        
        [Required]
        public Guid RideId { get; set; }
        
        [Required]
        public Guid RatedBy { get; set; } // User who gave rating
        
        [Required]
        public Guid RatedTo { get; set; } // User who received rating
        
        [Required]
        [MaxLength(20)]
        public string RatingType { get; set; } // passenger_to_driver, driver_to_passenger
        
        [Required]
        [Range(1, 5)]
        public int RatingValue { get; set; }
        
        [MaxLength(1000)]
        public string? Review { get; set; }
        
        // Rating Categories (optional)
        [Range(1, 5)]
        public int? BehaviorRating { get; set; }
        
        [Range(1, 5)]
        public int? PunctualityRating { get; set; }
        
        [Range(1, 5)]
        public int? VehicleConditionRating { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public Booking Booking { get; set; }
        public Ride Ride { get; set; }
        public User RatedByUser { get; set; }
        public User RatedToUser { get; set; }
    }
}

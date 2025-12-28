using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    /// <summary>
    /// Represents a route segment between two locations with distance and duration
    /// Used for calculating ride distances and fares
    /// </summary>
    public class RouteSegment
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string FromLocation { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string ToLocation { get; set; } = string.Empty;
        
        /// <summary>
        /// Distance in kilometers
        /// </summary>
        public double DistanceKm { get; set; }
        
        /// <summary>
        /// Estimated duration in minutes
        /// </summary>
        public int DurationMinutes { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}

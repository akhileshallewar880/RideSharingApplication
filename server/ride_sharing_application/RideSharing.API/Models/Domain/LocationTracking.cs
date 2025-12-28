using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace RideSharing.API.Models.Domain
{
    /// <summary>
    /// Location tracking data for active rides
    /// Stores GPS coordinates, speed, and heading
    /// </summary>
    public class LocationTracking
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid RideId { get; set; }

        [Required]
        public Guid DriverId { get; set; }

        [Required]
        [Column(TypeName = "decimal(10, 7)")]
        public decimal Latitude { get; set; }

        [Required]
        [Column(TypeName = "decimal(10, 7)")]
        public decimal Longitude { get; set; }

        /// <summary>
        /// Speed in meters per second
        /// </summary>
        [Column(TypeName = "decimal(6, 2)")]
        public decimal Speed { get; set; }

        /// <summary>
        /// Heading/direction in degrees (0-360)
        /// </summary>
        [Column(TypeName = "decimal(5, 2)")]
        public decimal Heading { get; set; }

        /// <summary>
        /// GPS accuracy in meters
        /// </summary>
        [Column(TypeName = "decimal(6, 2)")]
        public decimal Accuracy { get; set; }

        [Required]
        public DateTime Timestamp { get; set; }

        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("RideId")]
        public virtual Ride Ride { get; set; } = null!;

        [ForeignKey("DriverId")]
        public virtual User Driver { get; set; } = null!;
    }
}

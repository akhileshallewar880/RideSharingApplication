using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Booking
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string BookingNumber { get; set; }
        
        [Required]
        public Guid RideId { get; set; }
        
        [Required]
        public Guid PassengerId { get; set; }
        
        public int PassengerCount { get; set; }
        
        [MaxLength(50)]
        public string? SeatNumbers { get; set; }
        
        // Seat Selection - stored as JSON array
        // Example: ["P1","P2","P5"]
        public string? SelectedSeats { get; set; }
        
        // Screenshot of seating arrangement after booking
        [MaxLength(500)]
        public string? SeatingArrangementImage { get; set; }
        
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
        
        // Pricing
        public decimal PricePerSeat { get; set; }
        public decimal TotalFare { get; set; }
        public decimal PlatformFee { get; set; }
        public decimal TotalAmount { get; set; }
        
        // Verification
        [Required]
        [MaxLength(4)]
        public string OTP { get; set; }
        
        public string? QRCode { get; set; }
        public bool IsVerified { get; set; }
        public DateTime? VerifiedAt { get; set; }
        
        // Status
        [Required]
        [MaxLength(20)]
        public string Status { get; set; } // pending, confirmed, active, completed, cancelled, refunded
        
        [MaxLength(20)]
        public string? CancellationType { get; set; } // passenger, driver, system
        
        [MaxLength(500)]
        public string? CancellationReason { get; set; }
        
        public DateTime? CancelledAt { get; set; }
        
        // Payment
        [MaxLength(20)]
        public string PaymentStatus { get; set; } // pending, paid, refunded, failed
        
        [MaxLength(20)]
        public string? PaymentMethod { get; set; } // cash, upi, card, wallet
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public Ride Ride { get; set; }
        public User Passenger { get; set; }
        public ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public ICollection<Rating> Ratings { get; set; } = new List<Rating>();
    }
}

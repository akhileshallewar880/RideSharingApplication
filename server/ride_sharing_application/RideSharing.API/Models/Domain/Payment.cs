using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Payment
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string TransactionId { get; set; }
        
        [Required]
        public Guid BookingId { get; set; }
        
        [Required]
        public Guid PassengerId { get; set; }
        
        [Required]
        public Guid DriverId { get; set; }
        
        public decimal Amount { get; set; }
        public decimal PlatformFee { get; set; }
        public decimal DriverAmount { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string PaymentMethod { get; set; } // cash, upi, card, wallet
        
        [Required]
        [MaxLength(20)]
        public string PaymentStatus { get; set; } // pending, processing, completed, failed, refunded
        
        [MaxLength(200)]
        public string? GatewayTransactionId { get; set; }
        
        public string? GatewayResponse { get; set; } // JSON
        
        public DateTime? ProcessedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public Booking Booking { get; set; }
        public User Passenger { get; set; }
        public Driver Driver { get; set; }
    }
}

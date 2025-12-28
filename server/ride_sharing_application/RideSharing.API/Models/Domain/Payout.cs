using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Payout
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string PayoutId { get; set; }
        
        [Required]
        public Guid DriverId { get; set; }
        
        public decimal Amount { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string Method { get; set; } // bank_transfer, upi, cash
        
        [MaxLength(50)]
        public string? AccountNumber { get; set; }
        
        [MaxLength(11)]
        public string? IFSC { get; set; }
        
        [MaxLength(100)]
        public string? AccountHolderName { get; set; }
        
        [MaxLength(50)]
        public string? UPIId { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string Status { get; set; } // pending, processing, completed, failed, cancelled
        
        [MaxLength(200)]
        public string? TransactionReference { get; set; }
        
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ProcessedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        
        [MaxLength(500)]
        public string? Remarks { get; set; }
        
        // Navigation Property
        public Driver Driver { get; set; }
    }
}

using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Driver
    {
        public Guid Id { get; set; }
        
        [Required]
        public Guid UserId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string LicenseNumber { get; set; }
        
        [MaxLength(500)]
        public string? LicenseDocument { get; set; }
        
        [Required]
        public DateTime LicenseExpiryDate { get; set; }
        
        public bool LicenseVerified { get; set; }
        
        [MaxLength(12)]
        public string? AadharNumber { get; set; }
        
        public bool AadharVerified { get; set; }
        
        [MaxLength(10)]
        public string? PanNumber { get; set; }
        
        public bool IsOnline { get; set; }
        public bool IsAvailable { get; set; }
        public bool IsVerified { get; set; }
        
        [MaxLength(20)]
        public string VerificationStatus { get; set; } // pending, under_review, approved, rejected
        
        public decimal TotalEarnings { get; set; }
        public decimal PendingEarnings { get; set; }
        public decimal AvailableForWithdrawal { get; set; }
        
        [MaxLength(50)]
        public string? BankAccountNumber { get; set; }
        
        [MaxLength(11)]
        public string? BankIFSC { get; set; }
        
        [MaxLength(100)]
        public string? BankAccountHolderName { get; set; }
        
        // City/Location Information
        public Guid? CityId { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation Properties
        public User User { get; set; }
        public City? City { get; set; }
        public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
        public ICollection<Ride> Rides { get; set; } = new List<Ride>();
        public ICollection<Payout> Payouts { get; set; } = new List<Payout>();
    }
}

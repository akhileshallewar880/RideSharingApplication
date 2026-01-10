using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace RideSharing.API.Models.Domain
{
    /// <summary>
    /// Represents a coupon code that can be applied to bookings for discounts
    /// </summary>
    public class Coupon
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [StringLength(50)]
        public string Code { get; set; } = string.Empty;

        [StringLength(200)]
        public string? Description { get; set; }

        /// <summary>
        /// Discount type: "Percentage" or "Fixed"
        /// </summary>
        [Required]
        [StringLength(20)]
        public string DiscountType { get; set; } = "Fixed";

        /// <summary>
        /// Discount value - percentage (0-100) or fixed amount
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(10, 2)")]
        public decimal DiscountValue { get; set; }

        /// <summary>
        /// Maximum discount amount (useful for percentage discounts)
        /// </summary>
        [Column(TypeName = "decimal(10, 2)")]
        public decimal? MaxDiscountAmount { get; set; }

        /// <summary>
        /// Minimum order amount to apply coupon
        /// </summary>
        [Column(TypeName = "decimal(10, 2)")]
        public decimal MinOrderAmount { get; set; } = 0;

        /// <summary>
        /// Total number of times this coupon can be used across all users
        /// </summary>
        public int? TotalUsageLimit { get; set; }

        /// <summary>
        /// Number of times this coupon has been used
        /// </summary>
        public int UsageCount { get; set; } = 0;

        /// <summary>
        /// Number of times a single user can use this coupon
        /// </summary>
        public int PerUserUsageLimit { get; set; } = 1;

        /// <summary>
        /// Coupon valid from date
        /// </summary>
        [Required]
        public DateTime ValidFrom { get; set; }

        /// <summary>
        /// Coupon valid until date
        /// </summary>
        [Required]
        public DateTime ValidUntil { get; set; }

        /// <summary>
        /// Is the coupon currently active
        /// </summary>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// Is this a one-time use coupon for first-time users
        /// </summary>
        public bool IsFirstTimeUserOnly { get; set; } = false;

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public ICollection<CouponUsage> CouponUsages { get; set; } = new List<CouponUsage>();
    }

    /// <summary>
    /// Tracks which users have used which coupons
    /// </summary>
    public class CouponUsage
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid CouponId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        public Guid BookingId { get; set; }

        /// <summary>
        /// Discount amount applied for this usage
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(10, 2)")]
        public decimal DiscountApplied { get; set; }

        [Required]
        public DateTime UsedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey(nameof(CouponId))]
        public Coupon Coupon { get; set; } = null!;

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [ForeignKey(nameof(BookingId))]
        public Booking Booking { get; set; } = null!;
    }
}

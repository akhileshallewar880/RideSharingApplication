using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    /// <summary>
    /// Request to validate and apply a coupon code
    /// </summary>
    public class ValidateCouponRequestDto
    {
        [Required]
        [StringLength(50)]
        public string CouponCode { get; set; } = string.Empty;

        [Required]
        public Guid UserId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal OrderAmount { get; set; }
    }

    /// <summary>
    /// Response with coupon validation details
    /// </summary>
    public class ValidateCouponResponseDto
    {
        public bool IsValid { get; set; }
        public string? Message { get; set; }
        public CouponDetailsDto? Coupon { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal FinalAmount { get; set; }
    }

    /// <summary>
    /// Coupon details for response
    /// </summary>
    public class CouponDetailsDto
    {
        public Guid Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string DiscountType { get; set; } = string.Empty;
        public decimal DiscountValue { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public decimal MinOrderAmount { get; set; }
        public DateTime ValidFrom { get; set; }
        public DateTime ValidUntil { get; set; }
        public bool IsFirstTimeUserOnly { get; set; }
    }

    /// <summary>
    /// Request to apply a coupon to a booking
    /// </summary>
    public class ApplyCouponRequestDto
    {
        [Required]
        public Guid CouponId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        public Guid BookingId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal DiscountApplied { get; set; }
    }

    /// <summary>
    /// Create or update coupon (Admin only)
    /// </summary>
    public class CreateCouponRequestDto
    {
        [Required]
        [StringLength(50)]
        public string Code { get; set; } = string.Empty;

        [StringLength(200)]
        public string? Description { get; set; }

        [Required]
        [RegularExpression("^(Percentage|Fixed)$", ErrorMessage = "DiscountType must be 'Percentage' or 'Fixed'")]
        public string DiscountType { get; set; } = "Fixed";

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal DiscountValue { get; set; }

        [Range(0.01, double.MaxValue)]
        public decimal? MaxDiscountAmount { get; set; }

        [Range(0, double.MaxValue)]
        public decimal MinOrderAmount { get; set; } = 0;

        [Range(1, int.MaxValue)]
        public int? TotalUsageLimit { get; set; }

        [Range(1, int.MaxValue)]
        public int PerUserUsageLimit { get; set; } = 1;

        [Required]
        public DateTime ValidFrom { get; set; }

        [Required]
        public DateTime ValidUntil { get; set; }

        public bool IsActive { get; set; } = true;

        public bool IsFirstTimeUserOnly { get; set; } = false;
    }

    /// <summary>
    /// Coupon usage history
    /// </summary>
    public class CouponUsageDto
    {
        public Guid Id { get; set; }
        public string CouponCode { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public Guid BookingId { get; set; }
        public decimal DiscountApplied { get; set; }
        public DateTime UsedAt { get; set; }
    }
}

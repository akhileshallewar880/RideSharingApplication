using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace RideSharing.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CouponsController : ControllerBase
    {
        private readonly ICouponRepository _couponRepository;

        public CouponsController(ICouponRepository couponRepository)
        {
            _couponRepository = couponRepository;
        }

        /// <summary>
        /// Validate a coupon code for a user
        /// </summary>
        [HttpPost("validate")]
        public async Task<ActionResult<ValidateCouponResponseDto>> ValidateCoupon([FromBody] ValidateCouponRequestDto request)
        {
            try
            {
                var coupon = await _couponRepository.GetByCodeAsync(request.CouponCode);

                if (coupon == null)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = "Invalid coupon code",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check if coupon is active
                if (!coupon.IsActive)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = "This coupon is no longer active",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check validity dates
                var now = DateTime.UtcNow;
                if (now < coupon.ValidFrom || now > coupon.ValidUntil)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = "This coupon has expired or is not yet valid",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check minimum order amount
                if (request.OrderAmount < coupon.MinOrderAmount)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = $"Minimum order amount of ₹{coupon.MinOrderAmount} is required",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check total usage limit
                if (coupon.TotalUsageLimit.HasValue && coupon.UsageCount >= coupon.TotalUsageLimit.Value)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = "This coupon has reached its usage limit",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check per-user usage limit
                var userUsageCount = await _couponRepository.GetUserCouponUsageCountAsync(coupon.Id, request.UserId);
                if (userUsageCount >= coupon.PerUserUsageLimit)
                {
                    return Ok(new ValidateCouponResponseDto
                    {
                        IsValid = false,
                        Message = "You have already used this coupon",
                        DiscountAmount = 0,
                        FinalAmount = request.OrderAmount
                    });
                }

                // Check first-time user restriction
                if (coupon.IsFirstTimeUserOnly)
                {
                    var hasBookings = await _couponRepository.HasUserMadeAnyBookingAsync(request.UserId);
                    if (hasBookings)
                    {
                        return Ok(new ValidateCouponResponseDto
                        {
                            IsValid = false,
                            Message = "This coupon is only for first-time users",
                            DiscountAmount = 0,
                            FinalAmount = request.OrderAmount
                        });
                    }
                }

                // Calculate discount
                decimal discountAmount = 0;
                if (coupon.DiscountType == "Percentage")
                {
                    discountAmount = (request.OrderAmount * coupon.DiscountValue) / 100;
                    if (coupon.MaxDiscountAmount.HasValue && discountAmount > coupon.MaxDiscountAmount.Value)
                    {
                        discountAmount = coupon.MaxDiscountAmount.Value;
                    }
                }
                else // Fixed
                {
                    discountAmount = coupon.DiscountValue;
                    if (discountAmount > request.OrderAmount)
                    {
                        discountAmount = request.OrderAmount; // Can't discount more than order amount
                    }
                }

                var finalAmount = request.OrderAmount - discountAmount;

                return Ok(new ValidateCouponResponseDto
                {
                    IsValid = true,
                    Message = "Coupon applied successfully!",
                    Coupon = new CouponDetailsDto
                    {
                        Id = coupon.Id,
                        Code = coupon.Code,
                        Description = coupon.Description,
                        DiscountType = coupon.DiscountType,
                        DiscountValue = coupon.DiscountValue,
                        MaxDiscountAmount = coupon.MaxDiscountAmount,
                        MinOrderAmount = coupon.MinOrderAmount,
                        ValidFrom = coupon.ValidFrom,
                        ValidUntil = coupon.ValidUntil,
                        IsFirstTimeUserOnly = coupon.IsFirstTimeUserOnly
                    },
                    DiscountAmount = discountAmount,
                    FinalAmount = finalAmount
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while validating the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Apply a coupon to a booking
        /// </summary>
        [HttpPost("apply")]
        public async Task<ActionResult<CouponUsage>> ApplyCoupon([FromBody] ApplyCouponRequestDto request)
        {
            try
            {
                var couponUsage = new CouponUsage
                {
                    Id = Guid.NewGuid(),
                    CouponId = request.CouponId,
                    UserId = request.UserId,
                    BookingId = request.BookingId,
                    DiscountApplied = request.DiscountApplied,
                    UsedAt = DateTime.UtcNow
                };

                var result = await _couponRepository.RecordCouponUsageAsync(couponUsage);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while applying the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Get all active coupons (Admin)
        /// </summary>
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<List<Coupon>>> GetAllCoupons()
        {
            try
            {
                var coupons = await _couponRepository.GetAllActiveAsync();
                return Ok(coupons);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching coupons", error = ex.Message });
            }
        }

        /// <summary>
        /// Get the currently active coupon for passengers (Public)
        /// </summary>
        [HttpGet("active")]
        public async Task<ActionResult<CouponDetailsDto>> GetActiveCoupon()
        {
            try
            {
                var coupons = await _couponRepository.GetAllActiveAsync();
                var now = DateTime.UtcNow;
                
                // Get the first active coupon that is valid now
                var activeCoupon = coupons
                    .Where(c => c.IsActive && c.ValidFrom <= now && c.ValidUntil >= now)
                    .OrderBy(c => c.CreatedAt)
                    .FirstOrDefault();

                if (activeCoupon == null)
                {
                    return Ok(new { hasActiveCoupon = false });
                }

                return Ok(new
                {
                    hasActiveCoupon = true,
                    coupon = new CouponDetailsDto
                    {
                        Id = activeCoupon.Id,
                        Code = activeCoupon.Code,
                        Description = activeCoupon.Description,
                        DiscountType = activeCoupon.DiscountType,
                        DiscountValue = activeCoupon.DiscountValue,
                        MaxDiscountAmount = activeCoupon.MaxDiscountAmount,
                        MinOrderAmount = activeCoupon.MinOrderAmount,
                        ValidFrom = activeCoupon.ValidFrom,
                        ValidUntil = activeCoupon.ValidUntil,
                        IsFirstTimeUserOnly = activeCoupon.IsFirstTimeUserOnly
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching active coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Create a new coupon (Admin)
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Coupon>> CreateCoupon([FromBody] CreateCouponRequestDto request)
        {
            try
            {
                var coupon = new Coupon
                {
                    Id = Guid.NewGuid(),
                    Code = request.Code.ToUpper(),
                    Description = request.Description,
                    DiscountType = request.DiscountType,
                    DiscountValue = request.DiscountValue,
                    MaxDiscountAmount = request.MaxDiscountAmount,
                    MinOrderAmount = request.MinOrderAmount,
                    TotalUsageLimit = request.TotalUsageLimit,
                    UsageCount = 0,
                    PerUserUsageLimit = request.PerUserUsageLimit,
                    ValidFrom = request.ValidFrom,
                    ValidUntil = request.ValidUntil,
                    IsActive = request.IsActive,
                    IsFirstTimeUserOnly = request.IsFirstTimeUserOnly,
                    CreatedAt = DateTime.UtcNow
                };

                var result = await _couponRepository.CreateAsync(coupon);
                return CreatedAtAction(nameof(GetCouponById), new { id = result.Id }, result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while creating the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Get coupon by ID (Admin)
        /// </summary>
        [HttpGet("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Coupon>> GetCouponById(Guid id)
        {
            try
            {
                var coupon = await _couponRepository.GetByIdAsync(id);
                if (coupon == null)
                    return NotFound();

                return Ok(coupon);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Update a coupon (Admin)
        /// </summary>
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Coupon>> UpdateCoupon(Guid id, [FromBody] CreateCouponRequestDto request)
        {
            try
            {
                var coupon = new Coupon
                {
                    Description = request.Description,
                    DiscountType = request.DiscountType,
                    DiscountValue = request.DiscountValue,
                    MaxDiscountAmount = request.MaxDiscountAmount,
                    MinOrderAmount = request.MinOrderAmount,
                    TotalUsageLimit = request.TotalUsageLimit,
                    PerUserUsageLimit = request.PerUserUsageLimit,
                    ValidFrom = request.ValidFrom,
                    ValidUntil = request.ValidUntil,
                    IsActive = request.IsActive,
                    IsFirstTimeUserOnly = request.IsFirstTimeUserOnly
                };

                var result = await _couponRepository.UpdateAsync(id, coupon);
                if (result == null)
                    return NotFound();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while updating the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Delete a coupon (Admin)
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> DeleteCoupon(Guid id)
        {
            try
            {
                var result = await _couponRepository.DeleteAsync(id);
                if (!result)
                    return NotFound();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while deleting the coupon", error = ex.Message });
            }
        }

        /// <summary>
        /// Get coupon usage history (Admin)
        /// </summary>
        [HttpGet("{id}/usage")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<List<CouponUsageDto>>> GetCouponUsageHistory(Guid id)
        {
            try
            {
                var usages = await _couponRepository.GetCouponUsageHistoryAsync(id);
                var dtos = usages.Select(u => new CouponUsageDto
                {
                    Id = u.Id,
                    CouponCode = u.Coupon.Code,
                    UserName = u.User.Profile?.Name ?? u.User.PhoneNumber,
                    BookingId = u.BookingId,
                    DiscountApplied = u.DiscountApplied,
                    UsedAt = u.UsedAt
                }).ToList();

                return Ok(dtos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while fetching usage history", error = ex.Message });
            }
        }
    }
}

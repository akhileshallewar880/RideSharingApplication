using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.CustomValidations;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/driver/dashboard")]
    [ApiController]
    [Authorize]
    public class DriverDashboardController : ControllerBase
    {
        private readonly IDriverRepository _driverRepository;
        private readonly ILogger<DriverDashboardController> _logger;

        public DriverDashboardController(
            IDriverRepository driverRepository,
            ILogger<DriverDashboardController> logger)
        {
            _driverRepository = driverRepository;
            _logger = logger;
        }

        /// <summary>
        /// Get driver's dashboard overview
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetDashboard()
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var todayEarnings = await _driverRepository.GetTodayEarningsAsync(driver.Id);
                var todayRides = await _driverRepository.GetTodayRidesCountAsync(driver.Id);

                var dashboard = new DriverDashboardDto
                {
                    Driver = new DriverInfoDto
                    {
                        Id = driver.Id,
                        Name = driver.User?.Profile?.Name ?? "",
                        Rating = driver.User?.Profile?.Rating ?? 0,
                        TotalRides = driver.User?.Profile?.TotalRides ?? 0,
                        IsOnline = false // Would need to track this separately
                    },
                    TodayStats = new TodayStatsDto
                    {
                        TotalEarnings = todayEarnings,
                        TotalRides = todayRides,
                        OnlineHours = 0 // Would need to track this
                    },
                    PendingEarnings = driver.PendingEarnings,
                    AvailableForWithdrawal = driver.AvailableForWithdrawal
                };

                return Ok(ApiResponseDto<DriverDashboardDto>.SuccessResponse(dashboard));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driver dashboard");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving dashboard"));
            }
        }

        /// <summary>
        /// Get driver's earnings details for a date range
        /// </summary>
        [HttpGet("earnings")]
        public async Task<IActionResult> GetEarnings(
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var start = startDate ?? DateTime.UtcNow.AddDays(-30);
                var end = endDate ?? DateTime.UtcNow;

                var payments = await _driverRepository.GetDriverEarningsAsync(driver.Id, start, end);

                var earnings = new EarningsSummaryDto
                {
                    Summary = new SummaryDto
                    {
                        TotalEarnings = driver.TotalEarnings,
                        TotalRides = payments.Count,
                        AverageEarningsPerRide = payments.Any() ? payments.Average(p => p.DriverAmount) : 0,
                        TotalDistance = 0,
                        OnlineHours = 0
                    },
                    Breakdown = new BreakdownDto
                    {
                        CashCollected = payments.Where(p => p.PaymentMethod == "cash").Sum(p => p.Amount),
                        OnlinePayments = payments.Where(p => p.PaymentMethod != "cash").Sum(p => p.Amount),
                        Commission = payments.Sum(p => p.PlatformFee),
                        NetEarnings = payments.Sum(p => p.DriverAmount)
                    },
                    ChartData = new List<ChartDataDto>()
                };

                return Ok(ApiResponseDto<EarningsSummaryDto>.SuccessResponse(earnings));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving earnings");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving earnings"));
            }
        }

        /// <summary>
        /// Get driver's payout history
        /// </summary>
        [HttpGet("payouts")]
        public async Task<IActionResult> GetPayouts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var payouts = await _driverRepository.GetDriverPayoutsAsync(driver.Id, page, pageSize);

                var payoutDtos = payouts.Select(p => new PayoutDto
                {
                    PayoutId = p.Id,
                    Amount = p.Amount,
                    RequestedAt = p.RequestedAt,
                    CompletedAt = p.ProcessedAt,
                    Status = p.Status,
                    Method = p.Method
                }).ToList();

                var response = new PayoutHistoryDto
                {
                    Payouts = payoutDtos,
                    Pagination = new PaginationDto
                    {
                        CurrentPage = page,
                        ItemsPerPage = pageSize,
                        TotalItems = payoutDtos.Count,
                        TotalPages = (int)Math.Ceiling(payoutDtos.Count / (double)pageSize)
                    }
                };

                return Ok(ApiResponseDto<PayoutHistoryDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving payouts");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving payouts"));
            }
        }

        /// <summary>
        /// Request payout of available earnings
        /// </summary>
        [HttpPost("payouts/request")]
        [ValidateModel]
        public async Task<IActionResult> RequestPayout([FromBody] RequestPayoutDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                if (request.Amount > driver.AvailableForWithdrawal)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Insufficient balance for withdrawal"));
                }

                var payout = new RideSharing.API.Models.Domain.Payout
                {
                    Id = Guid.NewGuid(),
                    DriverId = driver.Id,
                    Amount = request.Amount,
                    Method = request.Method,
                    Status = "pending",
                    RequestedAt = DateTime.UtcNow
                };

                payout = await _driverRepository.RequestPayoutAsync(payout);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Payout requested successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error requesting payout");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while requesting payout"));
            }
        }

        /// <summary>
        /// Update driver's online status
        /// </summary>
        [HttpPut("status")]
        [ValidateModel]
        public async Task<IActionResult> UpdateOnlineStatus([FromBody] UpdateOnlineStatusDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var success = await _driverRepository.UpdateDriverOnlineStatusAsync(driver.Id, request.IsOnline);
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to update status"));
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Status updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating online status");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating status"));
            }
        }
    }
}

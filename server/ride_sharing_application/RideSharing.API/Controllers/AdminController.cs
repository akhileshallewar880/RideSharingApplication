using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using RideSharing.API.Helpers;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/admin")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly RideSharingDbContext _context;
        private readonly ILogger<AdminController> _logger;
        private readonly ITokenRepository _tokenRepository;
        private readonly IAuthRepository _authRepository;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;

        public AdminController(
            RideSharingDbContext context,
            ILogger<AdminController> logger,
            ITokenRepository tokenRepository,
            IAuthRepository authRepository,
            IEmailService emailService,
            IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _tokenRepository = tokenRepository;
            _authRepository = authRepository;
            _emailService = emailService;
            _configuration = configuration;
        }

        /// <summary>
        /// Admin login endpoint - authenticates users with UserType = 'admin'
        /// </summary>
        [HttpPost("auth/login")]
        [AllowAnonymous]
        public async Task<IActionResult> AdminLogin([FromBody] AdminLoginDto request)
        {
            _logger.LogInformation("=== Admin Login Request Received ===");
            _logger.LogInformation("Email: {Email}", request?.Email ?? "NULL");
            _logger.LogInformation("Request Body: {Request}", System.Text.Json.JsonSerializer.Serialize(request));
            
            try
            {
                // Validate input
                if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                {
                    _logger.LogWarning("Admin login validation failed: Email or password is empty");
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Email and password are required"));
                }

                // Find user by email
                var user = await _context.Users
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Email == request.Email);

                if (user == null)
                {
                    _logger.LogWarning("Admin login attempt failed: User not found with email {Email}", request.Email);
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid credentials"));
                }

                // Check if user is admin
                if (user.UserType != "admin")
                {
                    _logger.LogWarning("Admin login attempt failed: User {Email} is not an admin (UserType: {UserType})", 
                        request.Email, user.UserType);
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Access denied. Admin privileges required."));
                }

                // Verify password
                // Check if PasswordHash exists in database
                if (string.IsNullOrWhiteSpace(user.PasswordHash))
                {
                    _logger.LogWarning("Admin login attempt failed: No password hash set for {Email}", request.Email);
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid credentials"));
                }

                // Verify password using BCrypt
                bool isPasswordValid = PasswordHelper.VerifyPassword(request.Password, user.PasswordHash);
                if (!isPasswordValid)
                {
                    _logger.LogWarning("Admin login attempt failed: Invalid password for {Email}", request.Email);
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid credentials"));
                }

                // Generate JWT token
                var token = _tokenRepository.CreateJwtToken(user.Id, user.Email ?? user.PhoneNumber, new List<string> { user.UserType });

                // Create refresh token
                var refreshToken = new RefreshToken
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Token = Guid.NewGuid().ToString(),
                    ExpiresAt = DateTime.UtcNow.AddDays(30),
                    CreatedAt = DateTime.UtcNow,
                    IsRevoked = false
                };
                await _authRepository.CreateRefreshTokenAsync(refreshToken);

                var adminUser = new
                {
                    id = user.Id.ToString(),
                    email = user.Email,
                    name = user.Profile?.Name ?? "Administrator",
                    role = "admin",
                    permissions = new[] { "all" },
                    createdAt = user.CreatedAt
                };

                var response = new
                {
                    user = adminUser,
                    token = token,
                    refreshToken = refreshToken.Token
                };

                _logger.LogInformation("Admin login successful: {Email}, UserId: {UserId}", request.Email, user.Id);
                return Ok(ApiResponseDto<object>.SuccessResponse(response, "Login successful"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during admin login");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred during login"));
            }
        }

        /// <summary>
        /// Get drivers pending verification
        /// </summary>
        [HttpGet("drivers/pending")]
        [Authorize]
        public async Task<IActionResult> GetPendingDrivers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? status = null)
        {
            try
            {
                var query = _context.Drivers
                    .Include(d => d.User)
                        .ThenInclude(u => u.Profile)
                    .Include(d => d.City)
                    .Include(d => d.Vehicles)
                        .ThenInclude(v => v.VehicleModel)
                    .AsQueryable();

                if (!string.IsNullOrEmpty(status) && status != "all")
                {
                    query = query.Where(d => d.VerificationStatus == status);
                }
                else
                {
                    // Default: show pending and under_review
                    query = query.Where(d => d.VerificationStatus == "pending" || d.VerificationStatus == "under_review");
                }

                var totalCount = await query.CountAsync();
                var drivers = await query
                    .OrderByDescending(d => d.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var driverDtos = drivers.Select(d => new
                {
                    id = d.Id.ToString(),
                    userId = d.UserId.ToString(),
                    fullName = d.User.Profile?.Name ?? "Unknown",
                    email = d.User.Email ?? "",
                    phone = d.User.PhoneNumber,
                    dateOfBirth = d.User.Profile?.DateOfBirth,
                    vehicleNumber = d.Vehicles.FirstOrDefault()?.RegistrationNumber ?? "N/A",
                    vehicleType = d.Vehicles.FirstOrDefault()?.VehicleType ?? "N/A",
                    vehicleBrand = d.Vehicles.FirstOrDefault()?.Make ?? "N/A",
                    vehicleModel = d.Vehicles.FirstOrDefault()?.Model ?? "N/A",
                    vehicleModelName = d.Vehicles.FirstOrDefault()?.VehicleModel?.Name ?? "N/A",
                    seatingCapacity = d.Vehicles.FirstOrDefault()?.TotalSeats ?? 0,
                    city = d.City?.Name ?? d.User.Profile?.Address ?? "N/A",
                    cityDistrict = d.City?.District ?? "N/A",
                    cityState = d.City?.State ?? "N/A",
                    emergencyContact = d.User.Profile?.EmergencyContact,
                    verificationStatus = d.VerificationStatus,
                    rejectionReason = (string?)null,
                    registeredAt = d.CreatedAt,
                    documents = new
                    {
                        drivingLicense = !string.IsNullOrEmpty(d.LicenseDocument) ? new
                        {
                            documentId = d.Id.ToString(),
                            documentUrl = d.LicenseDocument,
                            documentType = "license",
                            uploadedAt = d.CreatedAt,
                            status = d.LicenseVerified ? "verified" : "uploaded"
                        } : null,
                        rcBook = d.Vehicles.FirstOrDefault()?.RegistrationDocument != null ? new
                        {
                            documentId = d.Vehicles.First().Id.ToString(),
                            documentUrl = d.Vehicles.First().RegistrationDocument,
                            documentType = "rc_book",
                            uploadedAt = d.Vehicles.First().CreatedAt,
                            status = d.Vehicles.First().RegistrationVerified ? "verified" : "uploaded"
                        } : null
                    }
                }).ToList();

                var result = new
                {
                    drivers = driverDtos,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(result, "Drivers retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pending drivers");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving drivers"));
            }
        }

        /// <summary>
        /// Get driver details by ID
        /// </summary>
        [HttpGet("drivers/{driverId}")]
        [Authorize]
        public async Task<IActionResult> GetDriverDetails(Guid driverId)
        {
            try
            {
                var driver = await _context.Drivers
                    .Include(d => d.User)
                        .ThenInclude(u => u.Profile)
                    .Include(d => d.City)
                    .Include(d => d.Vehicles)
                        .ThenInclude(v => v.VehicleModel)
                    .FirstOrDefaultAsync(d => d.Id == driverId);

                if (driver == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Driver not found"));
                }

                var driverDto = new
                {
                    id = driver.Id.ToString(),
                    userId = driver.UserId.ToString(),
                    fullName = driver.User.Profile?.Name ?? "Unknown",
                    email = driver.User.Email ?? "",
                    phone = driver.User.PhoneNumber,
                    dateOfBirth = driver.User.Profile?.DateOfBirth,
                    vehicleNumber = driver.Vehicles.FirstOrDefault()?.RegistrationNumber ?? "N/A",
                    vehicleType = driver.Vehicles.FirstOrDefault()?.VehicleType ?? "N/A",
                    vehicleBrand = driver.Vehicles.FirstOrDefault()?.Make ?? "N/A",
                    vehicleModel = driver.Vehicles.FirstOrDefault()?.Model ?? "N/A",
                    vehicleModelName = driver.Vehicles.FirstOrDefault()?.VehicleModel?.Name ?? "N/A",
                    seatingCapacity = driver.Vehicles.FirstOrDefault()?.TotalSeats ?? 0,
                    city = driver.City?.Name ?? driver.User.Profile?.Address ?? "N/A",
                    cityDistrict = driver.City?.District ?? "N/A",
                    cityState = driver.City?.State ?? "N/A",
                    emergencyContact = driver.User.Profile?.EmergencyContact,
                    verificationStatus = driver.VerificationStatus,
                    rejectionReason = (string?)null,
                    registeredAt = driver.CreatedAt,
                    documents = new
                    {
                        drivingLicense = !string.IsNullOrEmpty(driver.LicenseDocument) ? new
                        {
                            documentId = driver.Id.ToString(),
                            documentUrl = driver.LicenseDocument,
                            documentType = "license",
                            uploadedAt = driver.CreatedAt,
                            status = driver.LicenseVerified ? "verified" : "uploaded"
                        } : null,
                        rcBook = driver.Vehicles.FirstOrDefault()?.RegistrationDocument != null ? new
                        {
                            documentId = driver.Vehicles.First().Id.ToString(),
                            documentUrl = driver.Vehicles.First().RegistrationDocument,
                            documentType = "rc_book",
                            uploadedAt = driver.Vehicles.First().CreatedAt,
                            status = driver.Vehicles.First().RegistrationVerified ? "verified" : "uploaded"
                        } : null
                    }
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(driverDto, "Driver retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driver details for {DriverId}", driverId);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving driver details"));
            }
        }

        /// <summary>
        /// Approve driver
        /// </summary>
        [HttpPost("drivers/{driverId}/approve")]
        [Authorize]
        public async Task<IActionResult> ApproveDriver(Guid driverId, [FromBody] ApproveDriverDto? request)
        {
            try
            {
                var driver = await _context.Drivers.FindAsync(driverId);
                if (driver == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Driver not found"));
                }

                driver.VerificationStatus = "approved";
                driver.IsVerified = true;
                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Driver {DriverId} approved. Notes: {Notes}", driverId, request?.Notes);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Driver approved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error approving driver {DriverId}", driverId);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while approving driver"));
            }
        }

        /// <summary>
        /// Reject driver
        /// </summary>
        [HttpPost("drivers/{driverId}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectDriver(Guid driverId, [FromBody] RejectDriverDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Reason))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Rejection reason is required"));
                }

                var driver = await _context.Drivers.FindAsync(driverId);
                if (driver == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Driver not found"));
                }

                driver.VerificationStatus = "rejected";
                driver.IsVerified = false;
                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Driver {DriverId} rejected. Reason: {Reason}", driverId, request.Reason);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Driver rejected successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting driver {DriverId}", driverId);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while rejecting driver"));
            }
        }

        /// <summary>
        /// Get all drivers with filtering
        /// </summary>
        [HttpGet("drivers")]
        [Authorize]
        public async Task<IActionResult> GetAllDrivers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? status = null,
            [FromQuery] string? search = null)
        {
            try
            {
                var query = _context.Drivers
                    .Include(d => d.User)
                        .ThenInclude(u => u.Profile)
                    .Include(d => d.Vehicles)
                    .Include(d => d.Rides)
                    .AsQueryable();

                if (!string.IsNullOrEmpty(status) && status != "all")
                {
                    query = query.Where(d => d.VerificationStatus == status);
                }

                if (!string.IsNullOrEmpty(search))
                {
                    query = query.Where(d =>
                        (d.User.Profile != null && d.User.Profile.Name.Contains(search)) ||
                        d.User.PhoneNumber.Contains(search) ||
                        d.LicenseNumber.Contains(search));
                }

                var totalCount = await query.CountAsync();
                var drivers = await query
                    .OrderByDescending(d => d.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var driverDtos = drivers.Select(d => new
                {
                    id = d.Id.ToString(),
                    name = d.User.Profile?.Name ?? "Unknown",
                    phone = d.User.PhoneNumber,
                    vehicleNumber = d.Vehicles.FirstOrDefault()?.RegistrationNumber ?? "N/A",
                    vehicleType = d.Vehicles.FirstOrDefault()?.VehicleType ?? "N/A",
                    status = d.VerificationStatus,
                    totalRides = d.Rides?.Count ?? 0,
                    rating = 4.5
                }).ToList();

                var result = new
                {
                    drivers = driverDtos,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(result, "Drivers retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all drivers");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving drivers"));
            }
        }

        /// <summary>
        /// Activate driver account
        /// </summary>
        [HttpPost("drivers/{driverId}/activate")]
        [Authorize]
        public async Task<IActionResult> ActivateDriver(Guid driverId)
        {
            try
            {
                var driver = await _context.Drivers.FindAsync(driverId);
                if (driver == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Driver not found"));
                }

                driver.IsAvailable = true;
                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Driver {DriverId} activated", driverId);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Driver activated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error activating driver {DriverId}", driverId);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while activating driver"));
            }
        }

        /// <summary>
        /// Deactivate driver account
        /// </summary>
        [HttpPost("drivers/{driverId}/deactivate")]
        [Authorize]
        public async Task<IActionResult> DeactivateDriver(Guid driverId, [FromBody] DeactivateDriverDto request)
        {
            try
            {
                var driver = await _context.Drivers.FindAsync(driverId);
                if (driver == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Driver not found"));
                }

                driver.IsAvailable = false;
                driver.IsOnline = false;
                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Driver {DriverId} deactivated. Reason: {Reason}", driverId, request.Reason);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Driver deactivated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deactivating driver {DriverId}", driverId);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while deactivating driver"));
            }
        }

        /// <summary>
        /// [DEVELOPMENT ONLY] Generate BCrypt hash for a password
        /// This endpoint should be removed or secured in production
        /// </summary>
        [HttpPost("generate-password-hash")]
        [AllowAnonymous]
        public IActionResult GeneratePasswordHash([FromBody] GenerateHashDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Password))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Password is required"));
                }

                var hash = PasswordHelper.HashPassword(request.Password);
                
                var response = new
                {
                    password = request.Password,
                    hash = hash,
                    sqlQuery = $"UPDATE Users SET PasswordHash = '{hash}', UpdatedAt = GETUTCDATE() WHERE Email = '{request.Email ?? "admin@allapalliride.com"}';"
                };

                _logger.LogInformation("Generated password hash for development purposes");
                return Ok(ApiResponseDto<object>.SuccessResponse(response, "Hash generated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating password hash");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while generating hash"));
            }
        }

        /// <summary>
        /// Request password reset - sends reset token to email
        /// </summary>
        [HttpPost("auth/forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Email is required"));
                }

                // Find user by email
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.UserType == "admin");

                if (user == null)
                {
                    // Don't reveal if user exists for security
                    _logger.LogWarning("Password reset requested for non-existent admin email: {Email}", request.Email);
                    return Ok(ApiResponseDto<object>.SuccessResponse(null, "If an admin account exists with this email, a password reset link has been sent."));
                }

                // Generate 6-digit reset token
                var resetToken = new Random().Next(100000, 999999).ToString();

                // Create password reset token entry
                var passwordResetToken = new PasswordResetToken
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Token = resetToken,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(15), // 15 minutes expiry
                    IsUsed = false,
                    CreatedAt = DateTime.UtcNow
                };

                _context.PasswordResetTokens.Add(passwordResetToken);
                await _context.SaveChangesAsync();

                // Build reset URL from configuration
                var resetBaseUrl = _configuration["AppSettings:ResetPasswordUrl"] ?? "http://localhost:3000/reset-password";
                var resetUrl = $"{resetBaseUrl}?token={resetToken}&email={user.Email}";

                // Send email
                var emailSent = await _emailService.SendPasswordResetEmailAsync(user.Email!, resetToken, resetUrl);

                if (!emailSent)
                {
                    _logger.LogWarning("Failed to send password reset email to: {Email}. Token: {Token}", user.Email, resetToken);
                    // Still return success for security, but log the token for development
                }
                else
                {
                    _logger.LogInformation("Password reset email sent successfully to: {Email}", user.Email);
                }

                // In development, also log the token
                _logger.LogInformation("🔑 Password Reset Token for {Email}: {Token} (expires in 15 minutes)", user.Email, resetToken);

                return Ok(ApiResponseDto<object>.SuccessResponse(
                    new { expiresIn = 15 }, 
                    "If an admin account exists with this email, a password reset link has been sent."
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing forgot password request");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while processing your request"));
            }
        }

        /// <summary>
        /// Verify reset token validity
        /// </summary>
        [HttpPost("auth/verify-reset-token")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyResetToken([FromBody] VerifyResetTokenDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.Email))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Token and email are required"));
                }

                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.UserType == "admin");

                if (user == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid token or email"));
                }

                var resetToken = await _context.PasswordResetTokens
                    .Where(t => t.UserId == user.Id && t.Token == request.Token && !t.IsUsed)
                    .OrderByDescending(t => t.CreatedAt)
                    .FirstOrDefaultAsync();

                if (resetToken == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid or expired token"));
                }

                if (resetToken.ExpiresAt < DateTime.UtcNow)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Token has expired. Please request a new one."));
                }

                return Ok(ApiResponseDto<object>.SuccessResponse(
                    new { 
                        valid = true, 
                        expiresAt = resetToken.ExpiresAt 
                    }, 
                    "Token is valid"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying reset token");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while verifying token"));
            }
        }

        /// <summary>
        /// Reset password using token
        /// </summary>
        [HttpPost("auth/reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Token) || 
                    string.IsNullOrWhiteSpace(request.Email) || 
                    string.IsNullOrWhiteSpace(request.NewPassword))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Token, email, and new password are required"));
                }

                // Validate password strength
                if (request.NewPassword.Length < 8)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Password must be at least 8 characters long"));
                }

                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.UserType == "admin");

                if (user == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid token or email"));
                }

                var resetToken = await _context.PasswordResetTokens
                    .Where(t => t.UserId == user.Id && t.Token == request.Token && !t.IsUsed)
                    .OrderByDescending(t => t.CreatedAt)
                    .FirstOrDefaultAsync();

                if (resetToken == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid or expired token"));
                }

                if (resetToken.ExpiresAt < DateTime.UtcNow)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Token has expired. Please request a new one."));
                }

                // Update password
                user.PasswordHash = PasswordHelper.HashPassword(request.NewPassword);
                user.UpdatedAt = DateTime.UtcNow;

                // Mark token as used
                resetToken.IsUsed = true;
                resetToken.UsedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Password reset successful for admin: {Email}", user.Email);

                return Ok(ApiResponseDto<object>.SuccessResponse(
                    null, 
                    "Password has been reset successfully. You can now login with your new password."
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting password");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while resetting password"));
            }
        }
    }

    // DTOs for admin endpoints
    public class AdminLoginDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class ForgotPasswordDto
    {
        public string Email { get; set; } = string.Empty;
        public string? ResetUrl { get; set; }
    }

    public class VerifyResetTokenDto
    {
        public string Email { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
    }

    public class ResetPasswordDto
    {
        public string Email { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class GenerateHashDto
    {
        public string Password { get; set; } = string.Empty;
        public string? Email { get; set; }
    }

    public class ApproveDriverDto
    {
        public string? Notes { get; set; }
    }

    public class RejectDriverDto
    {
        public string Reason { get; set; } = string.Empty;
    }

    public class DeactivateDriverDto
    {
        public string Reason { get; set; } = string.Empty;
    }
}

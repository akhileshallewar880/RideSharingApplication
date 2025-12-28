using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.CustomValidations;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/auth")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthRepository _authRepository;
        private readonly ITokenRepository _tokenRepository;
        private readonly ILogger<AuthController> _logger;
        private readonly RideSharingDbContext _context;

        public AuthController(
            IAuthRepository authRepository,
            ITokenRepository _tokenRepository,
            ILogger<AuthController> logger,
            RideSharingDbContext context)
        {
            _authRepository = authRepository;
            this._tokenRepository = _tokenRepository;
            _logger = logger;
            _context = context;
        }

        /// <summary>
        /// Send OTP to phone number for login/registration
        /// </summary>
        [HttpPost("send-otp")]
        [ValidateModel]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto request)
        {
            try
            {
                // Store phone number WITHOUT country code prefix (e.g., "9421818209")
                var phoneNumber = request.PhoneNumber;
                var fullPhoneNumber = $"{request.CountryCode}{request.PhoneNumber}"; // For OTP storage
                
                _logger.LogInformation("SendOTP - Checking for existing user with phone: {Phone}", phoneNumber);
                
                // Check if user already exists (search without country code)
                var existingUser = await _authRepository.GetUserByPhoneAsync(phoneNumber);
                var isExistingUser = existingUser != null;
                
                if (existingUser != null)
                {
                    _logger.LogInformation("SendOTP - FOUND USER: ID={UserId}, Phone={Phone}, Name={Name}", 
                        existingUser.Id, existingUser.PhoneNumber, existingUser.Profile?.Name ?? "N/A");
                }
                else
                {
                    _logger.LogWarning("SendOTP - NO USER FOUND for phone: {Phone}", phoneNumber);
                }
                
                _logger.LogInformation("SendOTP - User found: {Found}, Phone checked: {Phone}", isExistingUser, phoneNumber);
                
                // Generate 4-digit OTP
                var otp = new Random().Next(1000, 9999).ToString();
                
                // Store OTP with full phone number (with country code)
                var otpRecord = await _authRepository.CreateOTPAsync(
                    fullPhoneNumber,
                    otp,
                    "login"
                );

                // TODO: Send OTP via SMS service
                _logger.LogInformation("OTP {Otp} created for {Phone} (Existing: {IsExisting})", otp, request.PhoneNumber, isExistingUser);

                var response = new SendOtpResponseDto
                {
                    OtpId = otpRecord.Id.ToString(),
                    ExpiresIn = 300, // 5 minutes
                    IsExistingUser = isExistingUser
                };

                return Ok(ApiResponseDto<SendOtpResponseDto>.SuccessResponse(response, "OTP sent successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending OTP to {PhoneNumber}", request.PhoneNumber);
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while sending OTP"));
            }
        }

        /// <summary>
        /// Verify OTP and return temp token for registration or full auth for existing users
        /// </summary>
        [HttpPost("verify-otp")]
        [ValidateModel]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto request)
        {
            try
            {
                var phoneNumber = request.PhoneNumber;
                var fullPhoneNumber = $"{request.CountryCode}{request.PhoneNumber}";
                var otpRecord = await _authRepository.GetValidOTPAsync(
                    fullPhoneNumber,
                    request.Otp,
                    request.OtpId
                );

                if (otpRecord == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid or expired OTP"));
                }

                await _authRepository.MarkOTPAsUsedAsync(otpRecord.Id);

                // Check if user exists (search without country code)
                var user = await _authRepository.GetUserByPhoneAsync(phoneNumber);
                
                _logger.LogInformation("Checking user for phone: {Phone}, Found: {Found}", phoneNumber, user != null);
                
                if (user == null)
                {
                    // New user - return temp token for registration
                    var response = new VerifyOtpResponseDto
                    {
                        IsNewUser = true,
                        TempToken = Guid.NewGuid().ToString(),
                        PhoneNumber = phoneNumber  // Return without country code
                    };
                    return Ok(ApiResponseDto<VerifyOtpResponseDto>.SuccessResponse(response, "OTP verified. Complete registration."));
                }
                else
                {
                    // Existing user - return full auth tokens
                    var accessToken = _tokenRepository.CreateJwtToken(user.Id, user.PhoneNumber, new List<string> { user.UserType });
                    var refreshToken = new RefreshToken
                    {
                        Id = Guid.NewGuid(),
                        UserId = user.Id,
                        Token = Guid.NewGuid().ToString(),
                        ExpiresAt = DateTime.UtcNow.AddDays(30),
                        CreatedAt = DateTime.UtcNow
                    };
                    await _authRepository.CreateRefreshTokenAsync(refreshToken);

                    var authResponse = new AuthResponseDto
                    {
                        User = new UserDto
                        {
                            Name = user.Profile?.Name ?? "",
                            PhoneNumber = user.PhoneNumber,
                            Email = user.Email,
                            UserType = user.UserType
                        },
                        AccessToken = accessToken,
                        RefreshToken = refreshToken.Token
                    };

                    return Ok(ApiResponseDto<AuthResponseDto>.SuccessResponse(authResponse, "Login successful"));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying OTP");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while verifying OTP"));
            }
        }

        /// <summary>
        /// Complete registration for new users (requires temp token from verify-otp)
        /// </summary>
        [HttpPost("complete-registration")]
        [ValidateModel]
        public async Task<IActionResult> CompleteRegistration([FromBody] CompleteRegistrationDto request, [FromHeader(Name = "X-Phone-Number")] string phoneNumber)
        {
            try
            {
                _logger.LogInformation("CompleteRegistration - Phone from header: {Phone}", phoneNumber);
                
                // Check if user already exists
                var existingUser = await _authRepository.GetUserByPhoneAsync(phoneNumber);
                if (existingUser != null)
                {
                    _logger.LogWarning("User already exists for phone: {Phone}", phoneNumber);
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("User already exists"));
                }

                _logger.LogInformation("Creating new user for phone: {Phone}", phoneNumber);
                
                // Create user (store phone without country code prefix)
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    PhoneNumber = phoneNumber,  // Should be just the number: "9421818209"
                    CountryCode = "+91",
                    Email = request.Email,
                    UserType = request.UserType,
                    IsPhoneVerified = true,
                    CreatedAt = DateTime.UtcNow
                };
                user = await _authRepository.CreateUserAsync(user);
                
                _logger.LogInformation("User created successfully with ID: {UserId}, Phone: {Phone}", user.Id, user.PhoneNumber);

                // Create profile
                var profile = new UserProfile
                {
                    UserId = user.Id,
                    Name = request.Name,
                    DateOfBirth = request.DateOfBirth,
                    Address = request.Address,
                    City = request.CurrentCityName,
                    EmergencyContact = request.EmergencyContact,
                    CreatedAt = DateTime.UtcNow
                };
                await _authRepository.CreateUserProfileAsync(profile);
                
                // If driver, create driver and vehicle records
                if (request.UserType.ToLower() == "driver")
                {
                    _logger.LogInformation("Creating driver record for user: {UserId}", user.Id);
                    _logger.LogInformation("Driver registration data - CityId: {CityId}, CityName: {CityName}, VehicleModelId: {VehicleModelId}, VehicleNumber: {VehicleNumber}", 
                        request.CurrentCityId, request.CurrentCityName, request.VehicleModelId, request.VehicleNumber);
                    
                    // Parse CityId if provided
                    Guid? cityId = null;
                    if (!string.IsNullOrEmpty(request.CurrentCityId) && Guid.TryParse(request.CurrentCityId, out var parsedCityId))
                    {
                        cityId = parsedCityId;
                        _logger.LogInformation("City ID parsed successfully: {CityId}", cityId);
                    }
                    else
                    {
                        _logger.LogWarning("City ID not provided or invalid: {CityId}", request.CurrentCityId);
                    }
                    
                    // Create driver record
                    var driver = new Driver
                    {
                        Id = Guid.NewGuid(),
                        UserId = user.Id,
                        CityId = cityId,
                        LicenseNumber = "TEMP_" + user.PhoneNumber, // Temporary until document upload
                        LicenseExpiryDate = DateTime.UtcNow.AddYears(10), // Temporary
                        LicenseVerified = false,
                        IsOnline = false,
                        IsAvailable = false,
                        IsVerified = false,
                        VerificationStatus = "pending",
                        TotalEarnings = 0,
                        PendingEarnings = 0,
                        AvailableForWithdrawal = 0,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    
                    _context.Drivers.Add(driver);
                    await _context.SaveChangesAsync();
                    
                    _logger.LogInformation("✅ Driver created successfully - ID: {DriverId}, UserID: {UserId}", driver.Id, user.Id);
                    
                    // Verify driver was created
                    var verifyDriver = await _context.Drivers.FindAsync(driver.Id);
                    if (verifyDriver == null)
                    {
                        _logger.LogError("❌ Driver record not found after creation!");
                        return StatusCode(500, ApiResponseDto<object>.ErrorResponse("Failed to create driver record"));
                    }
                    
                    _logger.LogInformation("✅ Driver verification passed");
                    
                    // Create vehicle record if vehicle details provided
                    if (!string.IsNullOrEmpty(request.VehicleModelId) && !string.IsNullOrEmpty(request.VehicleNumber))
                    {
                        _logger.LogInformation("Creating vehicle record for driver: {DriverId}", driver.Id);
                        
                        // Get vehicle model details
                        var vehicleModelId = Guid.Parse(request.VehicleModelId);
                        var vehicleModel = await _context.VehicleModels.FindAsync(vehicleModelId);
                        
                        if (vehicleModel == null)
                        {
                            _logger.LogWarning("Vehicle model not found: {VehicleModelId}", request.VehicleModelId);
                            return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid vehicle model"));
                        }
                        
                        var vehicle = new Vehicle
                        {
                            Id = Guid.NewGuid(),
                            DriverId = driver.Id,
                            VehicleModelId = vehicleModelId,
                            VehicleType = vehicleModel.Type,
                            Make = vehicleModel.Brand,
                            Model = vehicleModel.Name,
                            Year = DateTime.UtcNow.Year, // Default to current year
                            RegistrationNumber = request.VehicleNumber,
                            Color = "Not specified", // To be updated later
                            TotalSeats = vehicleModel.SeatingCapacity,
                            FuelType = "petrol", // Default, to be updated later
                            RegistrationVerified = false,
                            InsuranceVerified = false,
                            PermitVerified = false,
                            IsActive = true,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        
                        _context.Vehicles.Add(vehicle);
                        await _context.SaveChangesAsync();
                        
                        _logger.LogInformation("✅ Vehicle created successfully - ID: {VehicleId}, Registration: {RegNumber}, DriverID: {DriverId}", 
                            vehicle.Id, vehicle.RegistrationNumber, driver.Id);
                        
                        // Verify vehicle was created
                        var verifyVehicle = await _context.Vehicles.FindAsync(vehicle.Id);
                        if (verifyVehicle == null)
                        {
                            _logger.LogError("❌ Vehicle record not found after creation!");
                            return StatusCode(500, ApiResponseDto<object>.ErrorResponse("Failed to create vehicle record"));
                        }
                        
                        _logger.LogInformation("✅ Vehicle verification passed - Driver has {Count} vehicle(s)", 
                            await _context.Vehicles.CountAsync(v => v.DriverId == driver.Id));
                    }
                    else
                    {
                        _logger.LogWarning("⚠️ Vehicle details not provided - DriverID: {DriverId}", driver.Id);
                    }
                }

                // Generate tokens
                var accessToken = _tokenRepository.CreateJwtToken(user.Id, user.PhoneNumber, new List<string> { user.UserType });
                var refreshToken = new RefreshToken
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Token = Guid.NewGuid().ToString(),
                    ExpiresAt = DateTime.UtcNow.AddDays(30),
                    CreatedAt = DateTime.UtcNow
                };
                await _authRepository.CreateRefreshTokenAsync(refreshToken);

                var response = new AuthResponseDto
                {
                    User = new UserDto
                    {
                        Id = user.Id,
                        Name = profile.Name,
                        PhoneNumber = user.PhoneNumber,
                        Email = user.Email,
                        UserType = user.UserType,
                        CreatedAt = user.CreatedAt
                    },
                    AccessToken = accessToken,
                    RefreshToken = refreshToken.Token
                };

                return Ok(ApiResponseDto<AuthResponseDto>.SuccessResponse(response, "Registration completed successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error completing registration");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred during registration"));
            }
        }

        /// <summary>
        /// DEBUG: List all users (remove in production)
        /// </summary>
        [HttpGet("debug/users")]
        public async Task<IActionResult> DebugListUsers()
        {
            var users = await _context.Users
                .Include(u => u.Profile)
                .Select(u => new
                {
                    u.Id,
                    u.PhoneNumber,
                    u.CountryCode,
                    ProfileName = u.Profile != null ? u.Profile.Name : null,
                    u.UserType
                })
                .ToListAsync();

            return Ok(ApiResponseDto<object>.SuccessResponse(users, "Users retrieved"));
        }

        /// <summary>
        /// Refresh access token using refresh token
        /// </summary>
        [HttpPost("refresh-token")]
        [ValidateModel]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                var refreshToken = await _authRepository.GetRefreshTokenAsync(request.RefreshToken);
                
                if (refreshToken == null || refreshToken.IsRevoked || refreshToken.ExpiresAt < DateTime.UtcNow)
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid or expired refresh token"));
                }

                var user = await _authRepository.GetUserByPhoneAsync(refreshToken.User.PhoneNumber);
                if (user == null)
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("User not found"));
                }

                // Generate new access token
                var accessToken = _tokenRepository.CreateJwtToken(user.Id, user.PhoneNumber, new List<string> { user.UserType });

                var response = new TokenResponseDto
                {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken.Token
                };

                return Ok(ApiResponseDto<TokenResponseDto>.SuccessResponse(response, "Token refreshed successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while refreshing token"));
            }
        }

        /// <summary>
        /// Logout and revoke refresh token
        /// </summary>
        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var refreshToken = await _authRepository.GetRefreshTokenAsync(request.RefreshToken);
                if (refreshToken != null)
                {
                    await _authRepository.RevokeRefreshTokenAsync(refreshToken.Id);
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Logged out successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during logout");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred during logout"));
            }
        }

        /// <summary>
        /// Get list of active cities for driver registration
        /// </summary>
        [HttpGet("cities")]
        public async Task<IActionResult> GetCities()
        {
            try
            {
                var cities = await _context.Cities
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.Name)
                    .Select(c => new
                    {
                        id = c.Id,
                        name = c.Name,
                        state = c.State,
                        district = c.District,
                        pincode = c.Pincode,
                        latitude = c.Latitude,
                        longitude = c.Longitude
                    })
                    .ToListAsync();

                return Ok(ApiResponseDto<object>.SuccessResponse(cities, "Cities retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching cities");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while fetching cities"));
            }
        }
    }
}

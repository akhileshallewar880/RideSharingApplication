using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.CustomValidations;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/users")]
    [ApiController]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly IUserRepository _userRepository;
        private readonly IDriverRepository _driverRepository;
        private readonly ILogger<UsersController> _logger;

        public UsersController(
            IUserRepository userRepository, 
            IDriverRepository driverRepository,
            ILogger<UsersController> logger)
        {
            _userRepository = userRepository;
            _driverRepository = driverRepository;
            _logger = logger;
        }

        /// <summary>
        /// Get current user's profile
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var profile = await _userRepository.GetUserProfileAsync(userGuid);
                if (profile == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Profile not found"));
                }

                // Get driver verification status if user is a driver
                string? verificationStatus = null;
                if (profile.User?.UserType == "driver")
                {
                    _logger.LogInformation("User is a driver, fetching verification status for userId: {UserId}", userGuid);
                    var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                    if (driver != null)
                    {
                        verificationStatus = driver.VerificationStatus;
                        _logger.LogInformation("Driver found - VerificationStatus: {Status}, DriverId: {DriverId}", 
                            verificationStatus, driver.Id);
                    }
                    else
                    {
                        _logger.LogWarning("Driver record not found for userId: {UserId}", userGuid);
                    }
                }
                else
                {
                    _logger.LogInformation("User is not a driver, UserType: {UserType}", profile.User?.UserType);
                }

                // Map UserProfile domain model to DTO
                var profileDto = new UserProfileDetailDto
                {
                    Id = profile.UserId,
                    Name = profile.Name,
                    PhoneNumber = profile.User?.PhoneNumber ?? "",
                    Email = profile.User?.Email,
                    UserType = profile.User?.UserType ?? "passenger",
                    DateOfBirth = profile.DateOfBirth,
                    Address = profile.Address,
                    EmergencyContact = profile.EmergencyContact,
                    ProfilePicture = profile.ProfilePicture,
                    IsVerified = profile.User?.IsPhoneVerified ?? false,
                    Rating = profile.Rating,
                    TotalRides = profile.TotalRides,
                    CreatedAt = profile.User?.CreatedAt ?? DateTime.UtcNow,
                    VerificationStatus = verificationStatus
                };

                return Ok(ApiResponseDto<UserProfileDetailDto>.SuccessResponse(profileDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user profile");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving profile"));
            }
        }

        /// <summary>
        /// Update current user's profile
        /// </summary>
        [HttpPut("profile")]
        [ValidateModel]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserProfileDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var profile = await _userRepository.GetUserProfileAsync(userGuid);
                if (profile == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Profile not found"));
                }

                // Update fields
                if (!string.IsNullOrEmpty(request.Name)) profile.Name = request.Name;
                if (request.Email != null) profile.User.Email = request.Email;
                if (request.DateOfBirth.HasValue) profile.DateOfBirth = request.DateOfBirth;
                if (request.Address != null) profile.Address = request.Address;
                if (request.EmergencyContact != null) profile.EmergencyContact = request.EmergencyContact;
                
                profile.UpdatedAt = DateTime.UtcNow;

                var updatedProfile = await _userRepository.UpdateUserProfileAsync(profile);

                // Get driver verification status if user is a driver
                string? verificationStatus = null;
                if (updatedProfile.User?.UserType == "driver")
                {
                    var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                    if (driver != null)
                    {
                        verificationStatus = driver.VerificationStatus;
                    }
                }

                // Map to DTO
                var profileDto = new UserProfileDetailDto
                {
                    Id = updatedProfile.UserId,
                    Name = updatedProfile.Name,
                    PhoneNumber = updatedProfile.User?.PhoneNumber ?? "",
                    Email = updatedProfile.User?.Email,
                    UserType = updatedProfile.User?.UserType ?? "passenger",
                    DateOfBirth = updatedProfile.DateOfBirth,
                    Address = updatedProfile.Address,
                    EmergencyContact = updatedProfile.EmergencyContact,
                    ProfilePicture = updatedProfile.ProfilePicture,
                    IsVerified = updatedProfile.User?.IsPhoneVerified ?? false,
                    Rating = updatedProfile.Rating,
                    TotalRides = updatedProfile.TotalRides,
                    CreatedAt = updatedProfile.User?.CreatedAt ?? DateTime.UtcNow,
                    VerificationStatus = verificationStatus
                };

                return Ok(ApiResponseDto<UserProfileDetailDto>.SuccessResponse(profileDto, "Profile updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user profile");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating profile"));
            }
        }

        /// <summary>
        /// Upload profile picture
        /// </summary>
        [HttpPost("profile/picture")]
        public async Task<IActionResult> UploadProfilePicture([FromForm] IFormFile file)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                if (file == null || file.Length == 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("No file provided"));
                }

                // Validate file type
                var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/webp" };
                if (!allowedTypes.Contains(file.ContentType.ToLower()))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid file type. Only JPEG, PNG, and WebP are allowed"));
                }

                // Validate file size (max 5MB)
                if (file.Length > 5 * 1024 * 1024)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("File size cannot exceed 5MB"));
                }

                using var stream = file.OpenReadStream();
                var pictureUrl = await _userRepository.UploadProfilePictureAsync(userGuid, stream, file.FileName);
                if (string.IsNullOrEmpty(pictureUrl))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to upload profile picture"));
                }

                return Ok(ApiResponseDto<ProfilePictureResponseDto>.SuccessResponse(
                    new ProfilePictureResponseDto { ProfilePicture = pictureUrl, ProfilePictureUrl = pictureUrl },
                    "Profile picture uploaded successfully"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading profile picture");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while uploading picture"));
            }
        }

        /// <summary>
        /// Delete profile picture
        /// </summary>
        [HttpDelete("profile/picture")]
        public async Task<IActionResult> DeleteProfilePicture()
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                // Update profile to remove picture URL
                var profile = await _userRepository.GetUserProfileAsync(userGuid);
                if (profile == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Profile not found"));
                }

                profile.ProfilePicture = null;
                profile.UpdatedAt = DateTime.UtcNow;

                var updated = await _userRepository.UpdateUserProfileAsync(profile);

                if (updated == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to delete profile picture"));
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Profile picture deleted successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting profile picture");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while deleting picture"));
            }
        }
    }
}

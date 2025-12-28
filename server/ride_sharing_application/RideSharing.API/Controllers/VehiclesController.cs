using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.CustomValidations;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/driver/vehicles")]
    [ApiController]
    [Authorize]
    public class VehiclesController : ControllerBase
    {
        private readonly IDriverRepository _driverRepository;
        private readonly ILogger<VehiclesController> _logger;

        public VehiclesController(
            IDriverRepository driverRepository,
            ILogger<VehiclesController> logger)
        {
            _driverRepository = driverRepository;
            _logger = logger;
        }

        /// <summary>
        /// Get driver's vehicle details
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetVehicle()
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

                var vehicle = await _driverRepository.GetDriverVehicleAsync(driver.Id);
                if (vehicle == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("No vehicle registered"));
                }

                var vehicleDto = new VehicleDto
                {
                    VehicleId = vehicle.Id,
                    VehicleType = vehicle.VehicleType,
                    Make = vehicle.Make,
                    Model = vehicle.Model,
                    Year = vehicle.Year,
                    RegistrationNumber = vehicle.RegistrationNumber,
                    Color = vehicle.Color,
                    TotalSeats = vehicle.TotalSeats,
                    FuelType = vehicle.FuelType,
                    Features = string.IsNullOrEmpty(vehicle.Features) ? new List<string>() : new List<string> { vehicle.Features },
                    Documents = new VehicleDocumentsDto
                    {
                        Registration = new DocumentInfoDto
                        {
                            Verified = vehicle.RegistrationVerified,
                            ExpiryDate = vehicle.RegistrationExpiryDate
                        },
                        Insurance = new DocumentInfoDto
                        {
                            Verified = vehicle.InsuranceVerified,
                            ExpiryDate = vehicle.InsuranceExpiryDate
                        },
                        Permit = new DocumentInfoDto
                        {
                            Verified = vehicle.PermitVerified,
                            ExpiryDate = vehicle.PermitExpiryDate
                        }
                    }
                };

                return Ok(ApiResponseDto<VehicleDto>.SuccessResponse(vehicleDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving vehicle"));
            }
        }

        /// <summary>`
        /// Update vehicle details
        /// </summary>
        [HttpPut]
        [ValidateModel]
        public async Task<IActionResult> UpdateVehicle([FromBody] UpdateVehicleDto request)
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

                var vehicle = await _driverRepository.GetDriverVehicleAsync(driver.Id);
                if (vehicle == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("No vehicle registered"));
                }

                // Update vehicle properties
                if (!string.IsNullOrEmpty(request.Color)) vehicle.Color = request.Color;
                if (request.Features != null) vehicle.Features = string.Join(",", request.Features);

                vehicle.UpdatedAt = DateTime.UtcNow;

                vehicle = await _driverRepository.UpdateVehicleAsync(vehicle);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Vehicle updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating vehicle");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating vehicle"));
            }
        }

        /// <summary>
        /// Upload vehicle document
        /// </summary>
        [HttpPost("documents")]
        public async Task<IActionResult> UploadDocument(
            [FromForm] string documentType,
            [FromForm] IFormFile file)
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

                var vehicle = await _driverRepository.GetDriverVehicleAsync(driver.Id);
                if (vehicle == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("No vehicle registered"));
                }

                if (file == null || file.Length == 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("No file provided"));
                }

                // Validate file type
                var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "application/pdf" };
                if (!allowedTypes.Contains(file.ContentType.ToLower()))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid file type. Only JPEG, PNG, and PDF are allowed"));
                }

                // Validate file size (max 10MB)
                if (file.Length > 10 * 1024 * 1024)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("File size cannot exceed 10MB"));
                }

                // Create directory structure: verification/{vehicleNumber}/
                var baseUploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "verification", vehicle.RegistrationNumber);
                if (!Directory.Exists(baseUploadPath))
                {
                    Directory.CreateDirectory(baseUploadPath);
                }

                // Generate unique filename
                var fileExtension = Path.GetExtension(file.FileName);
                var fileName = $"{documentType}_{DateTime.UtcNow:yyyyMMddHHmmss}{fileExtension}";
                var filePath = Path.Combine(baseUploadPath, fileName);

                // Save file to disk
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                _logger.LogInformation("Document saved: {FilePath}", filePath);

                // Generate document URL
                var documentUrl = $"/uploads/verification/{vehicle.RegistrationNumber}/{fileName}";

                // Update vehicle or driver with document URL based on type
                switch (documentType.ToLower())
                {
                    case "license":
                    case "licence":
                        // Update driver's license document
                        driver.LicenseDocument = documentUrl;
                        driver.LicenseVerified = false;
                        await _driverRepository.UpdateDriverAsync(driver);
                        break;
                    case "rc":
                    case "registration":
                        vehicle.RegistrationDocument = documentUrl;
                        vehicle.RegistrationVerified = false;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                        await _driverRepository.UpdateVehicleAsync(vehicle);
                        break;
                    case "insurance":
                        vehicle.InsuranceDocument = documentUrl;
                        vehicle.InsuranceVerified = false;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                        await _driverRepository.UpdateVehicleAsync(vehicle);
                        break;
                    case "permit":
                        vehicle.PermitDocument = documentUrl;
                        vehicle.PermitVerified = false;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                        await _driverRepository.UpdateVehicleAsync(vehicle);
                        break;
                    default:
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid document type. Accepted: license, rc, registration, insurance, permit"));
                }

                
                var response = new
                {
                    documentType = documentType,
                    documentUrl = documentUrl,
                    uploadedAt = DateTime.UtcNow.ToString("o")
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(response, "Document uploaded successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading document");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while uploading document"));
            }
        }

        /// <summary>
        /// Toggle vehicle active status
        /// </summary>
        [HttpPut("status")]
        [ValidateModel]
        public async Task<IActionResult> ToggleStatus([FromBody] UpdateVehicleDto request)
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

                var vehicle = await _driverRepository.GetDriverVehicleAsync(driver.Id);
                if (vehicle == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("No vehicle registered"));
                }

                vehicle.IsActive = !vehicle.IsActive;
                vehicle.UpdatedAt = DateTime.UtcNow;

                await _driverRepository.UpdateVehicleAsync(vehicle);

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Vehicle status updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating vehicle status");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating status"));
            }
        }
    }
}

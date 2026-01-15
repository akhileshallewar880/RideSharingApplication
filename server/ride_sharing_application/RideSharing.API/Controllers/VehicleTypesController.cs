using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;
using System.Text.Json;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/admin/vehicle-types")]
    [ApiController]
    [Authorize(Roles = "admin")]
    public class VehicleTypesController : ControllerBase
    {
        private readonly IVehicleTypeRepository _vehicleTypeRepository;
        private readonly ILogger<VehicleTypesController> _logger;

        public VehicleTypesController(
            IVehicleTypeRepository vehicleTypeRepository,
            ILogger<VehicleTypesController> logger)
        {
            _vehicleTypeRepository = vehicleTypeRepository;
            _logger = logger;
        }

        /// <summary>
        /// Get all vehicle types with optional filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetVehicleTypes(
            [FromQuery] bool? active = null,
            [FromQuery] string? category = null)
        {
            try
            {
                var vehicleTypes = await _vehicleTypeRepository.GetAllVehicleTypesAsync(active, category);

                var vehicleTypeDtos = vehicleTypes.Select(vt => new VehicleTypeDto
                {
                    Id = vt.Id,
                    Name = vt.Name,
                    DisplayName = vt.DisplayName,
                    Icon = vt.Icon,
                    Description = vt.Description,
                    BasePrice = vt.BasePrice,
                    PricePerKm = vt.PricePerKm,
                    PricePerMinute = vt.PricePerMinute,
                    MinSeats = vt.MinSeats,
                    MaxSeats = vt.MaxSeats,
                    IsActive = vt.IsActive,
                    DisplayOrder = vt.DisplayOrder,
                    Category = vt.Category,
                    Features = string.IsNullOrEmpty(vt.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(vt.Features) ?? new List<string>(),
                    CreatedAt = vt.CreatedAt,
                    UpdatedAt = vt.UpdatedAt
                }).ToList();

                var response = new VehicleTypesResponseDto
                {
                    VehicleTypes = vehicleTypeDtos,
                    Total = vehicleTypeDtos.Count
                };

                return Ok(ApiResponseDto<VehicleTypesResponseDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle types");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving vehicle types"));
            }
        }

        /// <summary>
        /// Get a specific vehicle type by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetVehicleTypeById(Guid id)
        {
            try
            {
                var vehicleType = await _vehicleTypeRepository.GetVehicleTypeByIdAsync(id);
                if (vehicleType == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle type not found"));
                }

                var vehicleTypeDto = new VehicleTypeDto
                {
                    Id = vehicleType.Id,
                    Name = vehicleType.Name,
                    DisplayName = vehicleType.DisplayName,
                    Icon = vehicleType.Icon,
                    Description = vehicleType.Description,
                    BasePrice = vehicleType.BasePrice,
                    PricePerKm = vehicleType.PricePerKm,
                    PricePerMinute = vehicleType.PricePerMinute,
                    MinSeats = vehicleType.MinSeats,
                    MaxSeats = vehicleType.MaxSeats,
                    IsActive = vehicleType.IsActive,
                    DisplayOrder = vehicleType.DisplayOrder,
                    Category = vehicleType.Category,
                    Features = string.IsNullOrEmpty(vehicleType.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(vehicleType.Features) ?? new List<string>(),
                    CreatedAt = vehicleType.CreatedAt,
                    UpdatedAt = vehicleType.UpdatedAt
                };

                return Ok(ApiResponseDto<VehicleTypeDto>.SuccessResponse(vehicleTypeDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle type");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving vehicle type"));
            }
        }

        /// <summary>
        /// Create a new vehicle type
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateVehicleType([FromBody] CreateVehicleTypeDto request)
        {
            try
            {
                // Check if vehicle type with same name already exists
                if (await _vehicleTypeRepository.VehicleTypeExistsAsync(request.Name))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("A vehicle type with this name already exists"));
                }

                var vehicleType = new VehicleType
                {
                    Name = request.Name,
                    DisplayName = request.DisplayName,
                    Icon = request.Icon,
                    Description = request.Description,
                    BasePrice = request.BasePrice,
                    PricePerKm = request.PricePerKm,
                    PricePerMinute = request.PricePerMinute,
                    MinSeats = request.MinSeats,
                    MaxSeats = request.MaxSeats,
                    IsActive = request.IsActive,
                    DisplayOrder = request.DisplayOrder,
                    Category = request.Category,
                    Features = request.Features != null && request.Features.Any()
                        ? JsonSerializer.Serialize(request.Features)
                        : null
                };

                var createdVehicleType = await _vehicleTypeRepository.CreateVehicleTypeAsync(vehicleType);

                var vehicleTypeDto = new VehicleTypeDto
                {
                    Id = createdVehicleType.Id,
                    Name = createdVehicleType.Name,
                    DisplayName = createdVehicleType.DisplayName,
                    Icon = createdVehicleType.Icon,
                    Description = createdVehicleType.Description,
                    BasePrice = createdVehicleType.BasePrice,
                    PricePerKm = createdVehicleType.PricePerKm,
                    PricePerMinute = createdVehicleType.PricePerMinute,
                    MinSeats = createdVehicleType.MinSeats,
                    MaxSeats = createdVehicleType.MaxSeats,
                    IsActive = createdVehicleType.IsActive,
                    DisplayOrder = createdVehicleType.DisplayOrder,
                    Category = createdVehicleType.Category,
                    Features = request.Features,
                    CreatedAt = createdVehicleType.CreatedAt,
                    UpdatedAt = createdVehicleType.UpdatedAt
                };

                return CreatedAtAction(nameof(GetVehicleTypeById), new { id = vehicleTypeDto.Id },
                    ApiResponseDto<VehicleTypeDto>.SuccessResponse(vehicleTypeDto, "Vehicle type created successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating vehicle type");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while creating vehicle type"));
            }
        }

        /// <summary>
        /// Update an existing vehicle type
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateVehicleType(Guid id, [FromBody] UpdateVehicleTypeDto request)
        {
            try
            {
                var existingVehicleType = await _vehicleTypeRepository.GetVehicleTypeByIdAsync(id);
                if (existingVehicleType == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle type not found"));
                }

                // Check if updating name would cause a conflict
                if (!string.IsNullOrEmpty(request.Name) && request.Name != existingVehicleType.Name)
                {
                    if (await _vehicleTypeRepository.VehicleTypeExistsAsync(request.Name, id))
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("A vehicle type with this name already exists"));
                    }
                }

                // Update only provided fields
                if (!string.IsNullOrEmpty(request.Name))
                    existingVehicleType.Name = request.Name;
                
                if (!string.IsNullOrEmpty(request.DisplayName))
                    existingVehicleType.DisplayName = request.DisplayName;
                
                if (request.Icon != null)
                    existingVehicleType.Icon = request.Icon;
                
                if (request.Description != null)
                    existingVehicleType.Description = request.Description;
                
                if (request.BasePrice.HasValue)
                    existingVehicleType.BasePrice = request.BasePrice.Value;
                
                if (request.PricePerKm.HasValue)
                    existingVehicleType.PricePerKm = request.PricePerKm.Value;
                
                if (request.PricePerMinute.HasValue)
                    existingVehicleType.PricePerMinute = request.PricePerMinute.Value;
                
                if (request.MinSeats.HasValue)
                    existingVehicleType.MinSeats = request.MinSeats.Value;
                
                if (request.MaxSeats.HasValue)
                    existingVehicleType.MaxSeats = request.MaxSeats.Value;
                
                if (request.IsActive.HasValue)
                    existingVehicleType.IsActive = request.IsActive.Value;
                
                if (request.DisplayOrder.HasValue)
                    existingVehicleType.DisplayOrder = request.DisplayOrder.Value;
                
                if (request.Category != null)
                    existingVehicleType.Category = request.Category;
                
                if (request.Features != null)
                {
                    existingVehicleType.Features = request.Features.Any()
                        ? JsonSerializer.Serialize(request.Features)
                        : null;
                }

                var updatedVehicleType = await _vehicleTypeRepository.UpdateVehicleTypeAsync(id, existingVehicleType);

                if (updatedVehicleType == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle type not found"));
                }

                var vehicleTypeDto = new VehicleTypeDto
                {
                    Id = updatedVehicleType.Id,
                    Name = updatedVehicleType.Name,
                    DisplayName = updatedVehicleType.DisplayName,
                    Icon = updatedVehicleType.Icon,
                    Description = updatedVehicleType.Description,
                    BasePrice = updatedVehicleType.BasePrice,
                    PricePerKm = updatedVehicleType.PricePerKm,
                    PricePerMinute = updatedVehicleType.PricePerMinute,
                    MinSeats = updatedVehicleType.MinSeats,
                    MaxSeats = updatedVehicleType.MaxSeats,
                    IsActive = updatedVehicleType.IsActive,
                    DisplayOrder = updatedVehicleType.DisplayOrder,
                    Category = updatedVehicleType.Category,
                    Features = string.IsNullOrEmpty(updatedVehicleType.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(updatedVehicleType.Features) ?? new List<string>(),
                    CreatedAt = updatedVehicleType.CreatedAt,
                    UpdatedAt = updatedVehicleType.UpdatedAt
                };

                return Ok(ApiResponseDto<VehicleTypeDto>.SuccessResponse(vehicleTypeDto, "Vehicle type updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating vehicle type");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating vehicle type"));
            }
        }

        /// <summary>
        /// Delete a vehicle type
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVehicleType(Guid id)
        {
            try
            {
                var result = await _vehicleTypeRepository.DeleteVehicleTypeAsync(id);
                
                if (!result)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle type not found"));
                }

                return Ok(ApiResponseDto<object>.SuccessResponse(null, "Vehicle type deleted successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting vehicle type");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while deleting vehicle type"));
            }
        }
    }
}

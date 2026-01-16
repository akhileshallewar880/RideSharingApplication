using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using System.Text.Json;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/vehicles/models")]
    [ApiController]
    public class VehicleModelsController : ControllerBase
    {
        private readonly IVehicleModelRepository _vehicleModelRepository;
        private readonly ILogger<VehicleModelsController> _logger;

        public VehicleModelsController(
            IVehicleModelRepository vehicleModelRepository,
            ILogger<VehicleModelsController> logger)
        {
            _vehicleModelRepository = vehicleModelRepository;
            _logger = logger;
        }

        /// <summary>
        /// Get all vehicle models with optional filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetVehicleModels(
            [FromQuery] string? type = null,
            [FromQuery] bool? active = null)
        {
            try
            {
                var vehicleModels = await _vehicleModelRepository.GetAllVehicleModelsAsync(type, active);

                var vehicleModelDtos = vehicleModels.Select(vm => new VehicleModelDto
                {
                    Id = vm.Id,
                    Name = vm.Name,
                    Brand = vm.Brand,
                    Type = vm.Type,
                    SeatingCapacity = vm.SeatingCapacity,
                    SeatingLayout = vm.SeatingLayout,
                    ImageUrl = vm.ImageUrl,
                    Features = string.IsNullOrEmpty(vm.Features) 
                        ? new List<string>() 
                        : JsonSerializer.Deserialize<List<string>>(vm.Features) ?? new List<string>(),
                    Description = vm.Description,
                    IsActive = vm.IsActive
                }).ToList();

                var response = new VehicleModelsResponseDto
                {
                    Vehicles = vehicleModelDtos,
                    Total = vehicleModelDtos.Count
                };

                return Ok(ApiResponseDto<VehicleModelsResponseDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle models");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving vehicle models"));
            }
        }

        /// <summary>
        /// Get a specific vehicle model by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetVehicleModelById(Guid id)
        {
            try
            {
                var vehicleModel = await _vehicleModelRepository.GetVehicleModelByIdAsync(id);
                if (vehicleModel == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle model not found"));
                }

                var vehicleModelDto = new VehicleModelDto
                {
                    Id = vehicleModel.Id,
                    Name = vehicleModel.Name,
                    Brand = vehicleModel.Brand,
                    Type = vehicleModel.Type,
                    SeatingCapacity = vehicleModel.SeatingCapacity,
                    SeatingLayout = vehicleModel.SeatingLayout,
                    ImageUrl = vehicleModel.ImageUrl,
                    Features = string.IsNullOrEmpty(vehicleModel.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(vehicleModel.Features) ?? new List<string>(),
                    Description = vehicleModel.Description,
                    IsActive = vehicleModel.IsActive
                };

                return Ok(ApiResponseDto<VehicleModelDto>.SuccessResponse(vehicleModelDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle model");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving vehicle model"));
            }
        }

        /// <summary>
        /// Search vehicle models by name or brand
        /// </summary>
        [HttpGet("search")]
        public async Task<IActionResult> SearchVehicleModels([FromQuery] string q)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(q))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Search query cannot be empty"));
                }

                var vehicleModels = await _vehicleModelRepository.SearchVehicleModelsAsync(q);

                var vehicleModelDtos = vehicleModels.Select(vm => new VehicleModelDto
                {
                    Id = vm.Id,
                    Name = vm.Name,
                    Brand = vm.Brand,
                    Type = vm.Type,
                    SeatingCapacity = vm.SeatingCapacity,
                    SeatingLayout = vm.SeatingLayout,
                    ImageUrl = vm.ImageUrl,
                    Features = string.IsNullOrEmpty(vm.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(vm.Features) ?? new List<string>(),
                    Description = vm.Description,
                    IsActive = vm.IsActive
                }).ToList();

                var response = new VehicleModelsResponseDto
                {
                    Vehicles = vehicleModelDtos,
                    Total = vehicleModelDtos.Count
                };

                return Ok(ApiResponseDto<VehicleModelsResponseDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching vehicle models");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while searching vehicle models"));
            }
        }

        /// <summary>
        /// Create a new vehicle model (Admin only)
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "admin")]
        public async Task<IActionResult> CreateVehicleModel([FromBody] CreateVehicleModelDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid data"));
                }

                var vehicleModel = new Models.Domain.VehicleModel
                {
                    Name = dto.Name,
                    Brand = dto.Brand,
                    Type = dto.Type,
                    SeatingCapacity = dto.SeatingCapacity,
                    SeatingLayout = dto.SeatingLayout,
                    ImageUrl = dto.ImageUrl,
                    Features = dto.Features != null && dto.Features.Count > 0 
                        ? JsonSerializer.Serialize(dto.Features) 
                        : null,
                    Description = dto.Description,
                    IsActive = dto.IsActive
                };

                var createdModel = await _vehicleModelRepository.CreateVehicleModelAsync(vehicleModel);

                var responseDto = new VehicleModelDto
                {
                    Id = createdModel.Id,
                    Name = createdModel.Name,
                    Brand = createdModel.Brand,
                    Type = createdModel.Type,
                    SeatingCapacity = createdModel.SeatingCapacity,
                    SeatingLayout = createdModel.SeatingLayout,
                    ImageUrl = createdModel.ImageUrl,
                    Features = string.IsNullOrEmpty(createdModel.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(createdModel.Features) ?? new List<string>(),
                    Description = createdModel.Description,
                    IsActive = createdModel.IsActive
                };

                return CreatedAtAction(nameof(GetVehicleModelById), new { id = createdModel.Id }, 
                    ApiResponseDto<VehicleModelDto>.SuccessResponse(responseDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating vehicle model");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while creating vehicle model"));
            }
        }

        /// <summary>
        /// Update an existing vehicle model (Admin only)
        /// </summary>
        [HttpPut("{id}")]
        [Authorize(Roles = "admin")]
        public async Task<IActionResult> UpdateVehicleModel(Guid id, [FromBody] UpdateVehicleModelDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid data"));
                }

                var vehicleModel = new Models.Domain.VehicleModel
                {
                    Name = dto.Name,
                    Brand = dto.Brand,
                    Type = dto.Type,
                    SeatingCapacity = dto.SeatingCapacity,
                    SeatingLayout = dto.SeatingLayout,
                    ImageUrl = dto.ImageUrl,
                    Features = dto.Features != null && dto.Features.Count > 0
                        ? JsonSerializer.Serialize(dto.Features)
                        : null,
                    Description = dto.Description,
                    IsActive = dto.IsActive
                };

                var updatedModel = await _vehicleModelRepository.UpdateVehicleModelAsync(id, vehicleModel);
                if (updatedModel == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle model not found"));
                }

                var responseDto = new VehicleModelDto
                {
                    Id = updatedModel.Id,
                    Name = updatedModel.Name,
                    Brand = updatedModel.Brand,
                    Type = updatedModel.Type,
                    SeatingCapacity = updatedModel.SeatingCapacity,
                    SeatingLayout = updatedModel.SeatingLayout,
                    ImageUrl = updatedModel.ImageUrl,
                    Features = string.IsNullOrEmpty(updatedModel.Features)
                        ? new List<string>()
                        : JsonSerializer.Deserialize<List<string>>(updatedModel.Features) ?? new List<string>(),
                    Description = updatedModel.Description,
                    IsActive = updatedModel.IsActive
                };

                return Ok(ApiResponseDto<VehicleModelDto>.SuccessResponse(responseDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating vehicle model");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating vehicle model"));
            }
        }

        /// <summary>
        /// Delete a vehicle model (Admin only)
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize(Roles = "admin")]
        public async Task<IActionResult> DeleteVehicleModel(Guid id)
        {
            try
            {
                var deleted = await _vehicleModelRepository.DeleteVehicleModelAsync(id);
                if (!deleted)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Vehicle model not found"));
                }

                return Ok(ApiResponseDto<object>.SuccessResponse(null, "Vehicle model deleted successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting vehicle model");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while deleting vehicle model"));
            }
        }
    }
}

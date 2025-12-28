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
    }
}

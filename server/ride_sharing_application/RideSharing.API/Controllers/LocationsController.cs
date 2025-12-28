using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class LocationsController : ControllerBase
    {
        private readonly ILocationService _locationService;
        private readonly ILogger<LocationsController> _logger;

        public LocationsController(ILocationService locationService, ILogger<LocationsController> logger)
        {
            _locationService = locationService;
            _logger = logger;
        }

        /// <summary>
        /// Search locations by query string
        /// </summary>
        /// <param name="query">Search query (minimum 2 characters)</param>
        /// <param name="limit">Maximum number of results to return (default: 10)</param>
        /// <returns>List of matching locations</returns>
        [HttpGet("search")]
        public async Task<ActionResult<ApiResponseDto<LocationSearchResponseDto>>> SearchLocations(
            [FromQuery, Required, MinLength(2)] string query,
            [FromQuery] int limit = 10)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(query) || query.Length < 2)
                {
                    return BadRequest(new ApiResponseDto<LocationSearchResponseDto>
                    {
                        Success = false,
                        Message = "Query must be at least 2 characters long",
                        Data = null,
                        Error = new ErrorDto { Code = "INVALID_QUERY", Message = "Query must be at least 2 characters long" }
                    });
                }

                if (limit < 1 || limit > 50)
                {
                    limit = 10; // Reset to default if out of bounds
                }

                _logger.LogInformation("Searching locations with query: {Query}, limit: {Limit}", query, limit);

                var locations = await _locationService.SearchLocationsAsync(query, limit);

                return Ok(new ApiResponseDto<LocationSearchResponseDto>
                {
                    Success = true,
                    Message = $"Found {locations.Count} location(s)",
                    Data = new LocationSearchResponseDto
                    {
                        Locations = locations
                    },
                    Error = null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching locations for query: {Query}", query);
                return StatusCode(500, new ApiResponseDto<LocationSearchResponseDto>
                {
                    Success = false,
                    Message = "An error occurred while searching locations",
                    Data = null,
                    Error = new ErrorDto { Code = "SERVER_ERROR", Message = "An error occurred while searching locations" }
                });
            }
        }

        /// <summary>
        /// Get location by ID
        /// </summary>
        /// <param name="id">Location ID</param>
        /// <returns>Location details</returns>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponseDto<LocationSuggestionDto>>> GetLocationById(string id)
        {
            try
            {
                var location = await _locationService.GetLocationByIdAsync(id);

                if (location == null)
                {
                    return NotFound(new ApiResponseDto<LocationSuggestionDto>
                    {
                        Success = false,
                        Message = "Location not found",
                        Data = null,
                        Error = new ErrorDto { Code = "NOT_FOUND", Message = "Location not found" }
                    });
                }

                return Ok(new ApiResponseDto<LocationSuggestionDto>
                {
                    Success = true,
                    Message = "Location retrieved successfully",
                    Data = location,
                    Error = null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving location with ID: {Id}", id);
                return StatusCode(500, new ApiResponseDto<LocationSuggestionDto>
                {
                    Success = false,
                    Message = "An error occurred while retrieving the location",
                    Data = null,
                    Error = new ErrorDto { Code = "SERVER_ERROR", Message = "An error occurred while retrieving the location" }
                });
            }
        }

        /// <summary>
        /// Get all locations
        /// </summary>
        /// <returns>All available locations</returns>
        [HttpGet]
        public ActionResult<ApiResponseDto<LocationSearchResponseDto>> GetAllLocations()
        {
            try
            {
                var locations = _locationService.GetAllLocations();

                return Ok(new ApiResponseDto<LocationSearchResponseDto>
                {
                    Success = true,
                    Message = $"Retrieved {locations.Count} location(s)",
                    Data = new LocationSearchResponseDto
                    {
                        Locations = locations
                    },
                    Error = null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all locations");
                return StatusCode(500, new ApiResponseDto<LocationSearchResponseDto>
                {
                    Success = false,
                    Message = "An error occurred while retrieving locations",
                    Data = null,
                    Error = new ErrorDto { Code = "SERVER_ERROR", Message = "An error occurred while retrieving locations" }
                });
            }
        }
    }
}

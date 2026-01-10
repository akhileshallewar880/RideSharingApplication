using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Controllers
{
    /// <summary>
    /// Controller for Google Places API proxy endpoints
    /// </summary>
    [ApiController]
    [Route("api/v1/[controller]")]
    [Authorize]
    public class GooglePlacesController : ControllerBase
    {
        private readonly IGoogleMapsService _googleMapsService;
        private readonly ILogger<GooglePlacesController> _logger;

        public GooglePlacesController(
            IGoogleMapsService googleMapsService,
            ILogger<GooglePlacesController> logger)
        {
            _googleMapsService = googleMapsService;
            _logger = logger;
        }

        /// <summary>
        /// Get place autocomplete suggestions
        /// </summary>
        /// <param name="input">Search query</param>
        /// <param name="components">Optional country restriction (e.g., "country:in")</param>
        /// <returns>List of place suggestions</returns>
        [HttpGet("autocomplete")]
        public async Task<IActionResult> GetAutocomplete([FromQuery] string input, [FromQuery] string? components = null)
        {
            if (string.IsNullOrWhiteSpace(input))
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Input query is required",
                    Data = null
                });
            }

            try
            {
                _logger.LogInformation("Google Places autocomplete request - Input: {Input}, Components: {Components}", 
                    input, components);

                var suggestions = await _googleMapsService.GetPlaceAutocompleteAsync(input, components);

                return Ok(new ApiResponseDto<object>
                {
                    Success = true,
                    Message = $"Found {suggestions.Count} suggestions",
                    Data = new { suggestions }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetAutocomplete for input: {Input}", input);
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "An error occurred while fetching place suggestions",
                    Data = null
                });
            }
        }

        /// <summary>
        /// Get detailed information about a place
        /// </summary>
        /// <param name="placeId">Google Place ID</param>
        /// <returns>Detailed place information</returns>
        [HttpGet("details/{placeId}")]
        public async Task<IActionResult> GetPlaceDetails(string placeId)
        {
            if (string.IsNullOrWhiteSpace(placeId))
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Place ID is required",
                    Data = null
                });
            }

            try
            {
                _logger.LogInformation("Google Places details request - PlaceId: {PlaceId}", placeId);

                var details = await _googleMapsService.GetPlaceDetailsAsync(placeId);

                if (details == null)
                {
                    return NotFound(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Place not found",
                        Data = null
                    });
                }

                return Ok(new ApiResponseDto<object>
                {
                    Success = true,
                    Message = "Place details retrieved successfully",
                    Data = details
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetPlaceDetails for placeId: {PlaceId}", placeId);
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "An error occurred while fetching place details",
                    Data = null
                });
            }
        }
    }
}

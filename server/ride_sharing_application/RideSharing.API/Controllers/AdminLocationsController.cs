using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/admin/locations")]
    [ApiController]
    [Authorize(Roles = "admin,super_admin")]
    public class AdminLocationsController : ControllerBase
    {
        private readonly RideSharingDbContext _context;
        private readonly ILogger<AdminLocationsController> _logger;

        public AdminLocationsController(RideSharingDbContext context, ILogger<AdminLocationsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get all locations with optional filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllLocations(
            [FromQuery] string? search = null,
            [FromQuery] bool? isActive = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var query = _context.Cities.AsQueryable();

                // Apply search filter
                if (!string.IsNullOrWhiteSpace(search))
                {
                    query = query.Where(c =>
                        c.Name.Contains(search) ||
                        c.District.Contains(search) ||
                        c.State.Contains(search) ||
                        (c.SubLocation != null && c.SubLocation.Contains(search)) ||
                        (c.Pincode != null && c.Pincode.Contains(search)));
                }

                // Apply active status filter
                if (isActive.HasValue)
                {
                    query = query.Where(c => c.IsActive == isActive.Value);
                }

                var totalCount = await query.CountAsync();

                var locations = await query
                    .OrderBy(c => c.State)
                    .ThenBy(c => c.District)
                    .ThenBy(c => c.Name)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(c => new AdminLocationDto
                    {
                        Id = c.Id,
                        Name = c.Name,
                        State = c.State,
                        District = c.District,
                        SubLocation = c.SubLocation,
                        Pincode = c.Pincode,
                        Latitude = c.Latitude,
                        Longitude = c.Longitude,
                        IsActive = c.IsActive,
                        CreatedAt = c.CreatedAt,
                        UpdatedAt = c.UpdatedAt
                    })
                    .ToListAsync();

                var response = new
                {
                    locations,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(response, "Locations retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving locations");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving locations"));
            }
        }

        /// <summary>
        /// Get a specific location by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetLocationById(Guid id)
        {
            try
            {
                var location = await _context.Cities
                    .Where(c => c.Id == id)
                    .Select(c => new AdminLocationDto
                    {
                        Id = c.Id,
                        Name = c.Name,
                        State = c.State,
                        District = c.District,
                        SubLocation = c.SubLocation,
                        Pincode = c.Pincode,
                        Latitude = c.Latitude,
                        Longitude = c.Longitude,
                        IsActive = c.IsActive,
                        CreatedAt = c.CreatedAt,
                        UpdatedAt = c.UpdatedAt
                    })
                    .FirstOrDefaultAsync();

                if (location == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Location not found"));
                }

                return Ok(ApiResponseDto<AdminLocationDto>.SuccessResponse(location, "Location retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving location");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving location"));
            }
        }

        /// <summary>
        /// Create a new location
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateLocation([FromBody] CreateLocationRequest request)
        {
            try
            {
                // Validate required fields
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Location name is required"));
                }

                if (string.IsNullOrWhiteSpace(request.State))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("State is required"));
                }

                if (string.IsNullOrWhiteSpace(request.District))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("District is required"));
                }

                // Check if location already exists
                var existingLocation = await _context.Cities
                    .FirstOrDefaultAsync(c =>
                        c.Name.ToLower() == request.Name.ToLower() &&
                        c.District.ToLower() == request.District.ToLower() &&
                        c.State.ToLower() == request.State.ToLower());

                if (existingLocation != null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("A location with this name, district, and state already exists"));
                }

                var location = new City
                {
                    Id = Guid.NewGuid(),
                    Name = request.Name.Trim(),
                    State = request.State.Trim(),
                    District = request.District.Trim(),
                    SubLocation = request.SubLocation?.Trim(),
                    Pincode = request.Pincode?.Trim(),
                    Latitude = request.Latitude,
                    Longitude = request.Longitude,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Cities.Add(location);
                await _context.SaveChangesAsync();

                var locationDto = new AdminLocationDto
                {
                    Id = location.Id,
                    Name = location.Name,
                    State = location.State,
                    District = location.District,
                    SubLocation = location.SubLocation,
                    Pincode = location.Pincode,
                    Latitude = location.Latitude,
                    Longitude = location.Longitude,
                    IsActive = location.IsActive,
                    CreatedAt = location.CreatedAt,
                    UpdatedAt = location.UpdatedAt
                };

                _logger.LogInformation($"Admin created location: {location.Name}, {location.District}, {location.State}");

                return CreatedAtAction(nameof(GetLocationById), new { id = location.Id }, 
                    ApiResponseDto<AdminLocationDto>.SuccessResponse(locationDto, "Location created successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating location");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while creating location"));
            }
        }

        /// <summary>
        /// Update an existing location
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateLocationRequest request)
        {
            try
            {
                var location = await _context.Cities.FindAsync(id);

                if (location == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Location not found"));
                }

                // Update fields if provided
                if (!string.IsNullOrWhiteSpace(request.Name))
                {
                    location.Name = request.Name.Trim();
                }

                if (!string.IsNullOrWhiteSpace(request.State))
                {
                    location.State = request.State.Trim();
                }

                if (!string.IsNullOrWhiteSpace(request.District))
                {
                    location.District = request.District.Trim();
                }

                if (request.SubLocation != null)
                {
                    location.SubLocation = request.SubLocation.Trim();
                }

                if (request.Pincode != null)
                {
                    location.Pincode = request.Pincode.Trim();
                }

                if (request.Latitude.HasValue)
                {
                    location.Latitude = request.Latitude.Value;
                }

                if (request.Longitude.HasValue)
                {
                    location.Longitude = request.Longitude.Value;
                }

                if (request.IsActive.HasValue)
                {
                    location.IsActive = request.IsActive.Value;
                }

                location.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                var locationDto = new AdminLocationDto
                {
                    Id = location.Id,
                    Name = location.Name,
                    State = location.State,
                    District = location.District,
                    SubLocation = location.SubLocation,
                    Pincode = location.Pincode,
                    Latitude = location.Latitude,
                    Longitude = location.Longitude,
                    IsActive = location.IsActive,
                    CreatedAt = location.CreatedAt,
                    UpdatedAt = location.UpdatedAt
                };

                _logger.LogInformation($"Admin updated location: {location.Name}, {location.District}, {location.State}");

                return Ok(ApiResponseDto<AdminLocationDto>.SuccessResponse(locationDto, "Location updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating location");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating location"));
            }
        }

        /// <summary>
        /// Delete a location
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLocation(Guid id)
        {
            try
            {
                var location = await _context.Cities.FindAsync(id);

                if (location == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Location not found"));
                }

                // Check if location is being used by any drivers
                var isUsedByDrivers = await _context.Drivers.AnyAsync(d => d.CityId == id);
                
                if (isUsedByDrivers)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot delete location as it is being used by one or more drivers"));
                }

                _context.Cities.Remove(location);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Admin deleted location: {location.Name}, {location.District}, {location.State}");

                return Ok(ApiResponseDto<object>.SuccessResponse(null, "Location deleted successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting location");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while deleting location"));
            }
        }

        /// <summary>
        /// Get location statistics
        /// </summary>
        [HttpGet("statistics")]
        public async Task<IActionResult> GetLocationStatistics()
        {
            try
            {
                var totalLocations = await _context.Cities.CountAsync();
                var activeLocations = await _context.Cities.CountAsync(c => c.IsActive);
                var inactiveLocations = totalLocations - activeLocations;
                var locationsWithCoordinates = await _context.Cities
                    .CountAsync(c => c.Latitude.HasValue && c.Longitude.HasValue);

                var stats = new
                {
                    totalLocations,
                    activeLocations,
                    inactiveLocations,
                    locationsWithCoordinates,
                    locationsWithoutCoordinates = totalLocations - locationsWithCoordinates
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(stats, "Statistics retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving statistics");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving statistics"));
            }
        }
    }
}

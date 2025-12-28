using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    public class LocationService : ILocationService
    {
        private readonly ILogger<LocationService> _logger;
        private readonly RideSharingDbContext _context;

        public LocationService(ILogger<LocationService> logger, RideSharingDbContext context)
        {
            _logger = logger;
            _context = context;
        }

        public async Task<List<LocationSuggestionDto>> SearchLocationsAsync(string query, int limit = 10)
        {
            if (string.IsNullOrWhiteSpace(query))
            {
                return new List<LocationSuggestionDto>();
            }

            query = query.Trim().ToLowerInvariant();

            try
            {
                // Query active cities from database
                var cities = await _context.Cities
                    .Where(c => c.IsActive)
                    .Where(c => c.Name.ToLower().Contains(query) || 
                               c.District.ToLower().Contains(query) ||
                               c.SubLocation != null && c.SubLocation.ToLower().Contains(query))
                    .OrderBy(c => c.Name)
                    .Take(limit)
                    .ToListAsync();

                // Convert to LocationSuggestionDto
                var results = cities.Select(city => new LocationSuggestionDto
                {
                    Id = city.Id.ToString(),
                    Name = !string.IsNullOrEmpty(city.SubLocation) ? $"{city.SubLocation}, {city.Name}" : city.Name,
                    State = city.State,
                    District = city.District,
                    Latitude = (decimal?)city.Latitude ?? 0m,
                    Longitude = (decimal?)city.Longitude ?? 0m,
                    FullAddress = !string.IsNullOrEmpty(city.SubLocation) 
                        ? $"{city.SubLocation}, {city.Name}, {city.State}"
                        : $"{city.Name}, {city.State}"
                }).ToList();

                _logger.LogInformation("Location search for '{Query}' returned {Count} results from database", query, results.Count);

                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching locations for query: {Query}", query);
                return new List<LocationSuggestionDto>();
            }
        }

        public async Task<LocationSuggestionDto?> GetLocationByIdAsync(string id)
        {
            try
            {
                if (!Guid.TryParse(id, out var cityId))
                {
                    _logger.LogWarning("Invalid city ID format: {Id}", id);
                    return null;
                }

                var city = await _context.Cities
                    .Where(c => c.Id == cityId && c.IsActive)
                    .FirstOrDefaultAsync();

                if (city == null)
                {
                    return null;
                }

                return new LocationSuggestionDto
                {
                    Id = city.Id.ToString(),
                    Name = !string.IsNullOrEmpty(city.SubLocation) ? $"{city.SubLocation}, {city.Name}" : city.Name,
                    State = city.State,
                    District = city.District,
                    Latitude = (decimal?)city.Latitude ?? 0m,
                    Longitude = (decimal?)city.Longitude ?? 0m,
                    FullAddress = !string.IsNullOrEmpty(city.SubLocation) 
                        ? $"{city.SubLocation}, {city.Name}, {city.State}"
                        : $"{city.Name}, {city.State}"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting location by ID: {Id}", id);
                return null;
            }
        }

        public List<LocationSuggestionDto> GetAllLocations()
        {
            try
            {
                // Query all active cities from database synchronously
                var cities = _context.Cities
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.Name)
                    .ToList();

                return cities.Select(city => new LocationSuggestionDto
                {
                    Id = city.Id.ToString(),
                    Name = !string.IsNullOrEmpty(city.SubLocation) ? $"{city.SubLocation}, {city.Name}" : city.Name,
                    State = city.State,
                    District = city.District,
                    Latitude = (decimal?)city.Latitude ?? 0m,
                    Longitude = (decimal?)city.Longitude ?? 0m,
                    FullAddress = !string.IsNullOrEmpty(city.SubLocation) 
                        ? $"{city.SubLocation}, {city.Name}, {city.State}"
                        : $"{city.Name}, {city.State}"
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all locations from database");
                return new List<LocationSuggestionDto>();
            }
        }
    }
}

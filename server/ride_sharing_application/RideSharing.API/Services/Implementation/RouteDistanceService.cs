using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    /// <summary>
    /// Service for retrieving route distances and ETAs between cities from database
    /// Uses RouteSegments table for accurate distance calculations
    /// </summary>
    public class RouteDistanceService
    {
        private readonly ILogger<RouteDistanceService> _logger;
        private readonly RideSharingDbContext _context;
        private readonly ILocationService _locationService;

        public RouteDistanceService(
            ILogger<RouteDistanceService> logger, 
            RideSharingDbContext context,
            ILocationService locationService)
        {
            _logger = logger;
            _context = context;
            _locationService = locationService;
        }

        /// <summary>
        /// Get distance and duration between two cities from database
        /// Automatically handles reverse lookup (from-to or to-from)
        /// </summary>
        public async Task<(double distanceKm, int durationMinutes)?> GetDistanceAndDurationAsync(string fromCity, string toCity)
        {
            if (string.IsNullOrWhiteSpace(fromCity) || string.IsNullOrWhiteSpace(toCity))
                return null;

            try
            {
                // Clean city names (remove "Maharashtra", district names, etc.)
                var cleanFrom = CleanCityName(fromCity);
                var cleanTo = CleanCityName(toCity);

                // Try direct lookup in database
                var segment = await _context.RouteSegments
                    .Where(rs => rs.IsActive)
                    .Where(rs => 
                        (rs.FromLocation == cleanFrom && rs.ToLocation == cleanTo) ||
                        (rs.FromLocation == cleanTo && rs.ToLocation == cleanFrom))
                    .FirstOrDefaultAsync();

                if (segment != null)
                {
                    _logger.LogInformation("✅ Found route in database: {From} → {To} = {Distance}km, {Duration}min", 
                        cleanFrom, cleanTo, segment.DistanceKm, segment.DurationMinutes);
                    return (segment.DistanceKm, segment.DurationMinutes);
                }

                // If not found in database, use fallback calculation
                _logger.LogWarning("⚠️ No route segment found in database for: {From} → {To}, using fallback calculation", 
                    cleanFrom, cleanTo);
                
                var fallback = await CalculateFallbackDistanceAsync(cleanFrom, cleanTo);
                return fallback;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting distance and duration for {From} → {To}", fromCity, toCity);
                return null;
            }
        }

        /// <summary>
        /// Synchronous version for backwards compatibility
        /// </summary>
        public (double distanceKm, int durationMinutes)? GetDistanceAndDuration(string fromCity, string toCity)
        {
            return GetDistanceAndDurationAsync(fromCity, toCity).GetAwaiter().GetResult();
        }

        /// <summary>
        /// Calculate multi-leg route with intermediate stops
        /// Returns total distance, duration, and segment breakdown
        /// </summary>
        public async Task<(double totalDistanceKm, int totalDurationMinutes, List<RouteSegment> segments)?> CalculateMultiLegRouteAsync(
            List<string> cities)
        {
            if (cities == null || cities.Count < 2)
                return null;

            try
            {
                var segments = new List<RouteSegment>();
                double totalDistance = 0;
                int totalDuration = 0;

                for (int i = 0; i < cities.Count - 1; i++)
                {
                    var from = cities[i];
                    var to = cities[i + 1];

                    var route = await GetDistanceAndDurationAsync(from, to);
                    if (route == null)
                    {
                        _logger.LogError("❌ Cannot calculate route for: {From} → {To}", from, to);
                        return null;
                    }

                    segments.Add(new RouteSegment
                    {
                        FromLocation = from,
                        ToLocation = to,
                        DistanceKm = route.Value.distanceKm,
                        DurationMinutes = route.Value.durationMinutes
                    });

                    totalDistance += route.Value.distanceKm;
                    totalDuration += route.Value.durationMinutes;
                }

                _logger.LogInformation("✅ Multi-leg route calculated: {TotalDistance}km, {TotalDuration}min, {Segments} segments",
                    totalDistance, totalDuration, segments.Count);

                return (totalDistance, totalDuration, segments);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating multi-leg route");
                return null;
            }
        }

        /// <summary>
        /// Synchronous wrapper for CalculateMultiLegRouteAsync - for backward compatibility
        /// </summary>
        public (double totalDistanceKm, int totalDurationMinutes, List<RouteSegment> segments)? CalculateMultiLegRoute(
            List<string> cities)
        {
            return CalculateMultiLegRouteAsync(cities).GetAwaiter().GetResult();
        }

        /// <summary>
        /// Fallback distance calculation using Haversine formula
        /// Multiplied by 1.3 to approximate road distance
        /// </summary>
        private async Task<(double distanceKm, int durationMinutes)?> CalculateFallbackDistanceAsync(string fromCity, string toCity)
        {
            try
            {
                var fromLocation = await GetLocationByNameAsync(fromCity);
                var toLocation = await GetLocationByNameAsync(toCity);

                if (fromLocation == null || toLocation == null)
                {
                    _logger.LogWarning("Cannot find location coordinates for fallback calculation: {From} or {To}", fromCity, toCity);
                    return null;
                }

                var straightDistance = CalculateHaversineDistance(
                    (double)fromLocation.Latitude, (double)fromLocation.Longitude,
                    (double)toLocation.Latitude, (double)toLocation.Longitude);

                var roadDistance = straightDistance * 1.3; // Approximate road distance factor
                var duration = (int)Math.Ceiling(roadDistance / 50.0 * 60); // Assume 50 km/h average

                _logger.LogInformation("⚠️ Using fallback calculation for {From} → {To}: {Distance}km (estimated)",
                    fromCity, toCity, roadDistance);

                return (Math.Round(roadDistance, 2), duration);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in fallback distance calculation");
                return null;
            }
        }

        /// <summary>
        /// Haversine formula for straight-line distance
        /// </summary>
        private double CalculateHaversineDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double earthRadiusKm = 6371;

            var dLat = DegreesToRadians(lat2 - lat1);
            var dLon = DegreesToRadians(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return earthRadiusKm * c;
        }

        private double DegreesToRadians(double degrees) => degrees * Math.PI / 180;

        private async Task<Models.DTO.LocationSuggestionDto?> GetLocationByNameAsync(string cityName)
        {
            var locations = await _locationService.SearchLocationsAsync(cityName, 1);
            return locations?.FirstOrDefault(l => 
                l.Name.Equals(CleanCityName(cityName), StringComparison.OrdinalIgnoreCase));
        }

        private string CleanCityName(string cityName)
        {
            // Remove common suffixes and location types
            var cleaned = cityName
                .Replace(" Bus Stand", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Metro Station", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Railway Station", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Hyderabad", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Hyderabad", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Telangana", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Telangana", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Maharashtra", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Maharashtra", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Gadchiroli", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Chandrapur", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Nagpur", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Gondia", "", StringComparison.OrdinalIgnoreCase)
                .Replace(" Gachibowli", "", StringComparison.OrdinalIgnoreCase)
                .Replace(", Gachibowli", "", StringComparison.OrdinalIgnoreCase)
                .Trim();
            
            // Extract just the city name if format is "Location, City, State"
            // e.g., "Allapalli Bus Stand, Allapalli, Maharashtra" -> "Allapalli"
            var parts = cleaned.Split(',');
            if (parts.Length >= 2)
            {
                // Use the second part (the city name) and trim it
                cleaned = parts[1].Trim();
            }
            else if (parts.Length == 1)
            {
                cleaned = parts[0].Trim();
            }
            
            return cleaned;
        }
    }
}

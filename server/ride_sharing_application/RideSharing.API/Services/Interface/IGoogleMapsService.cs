using RideSharing.API.Models.DTO;

namespace RideSharing.API.Services.Interface
{
    /// <summary>
    /// Service for Google Maps API interactions
    /// </summary>
    public interface IGoogleMapsService
    {
        /// <summary>
        /// Calculate distance and duration between two coordinates using Google Maps Distance Matrix API
        /// </summary>
        /// <param name="originLat">Origin latitude</param>
        /// <param name="originLng">Origin longitude</param>
        /// <param name="destLat">Destination latitude</param>
        /// <param name="destLng">Destination longitude</param>
        /// <param name="mode">Travel mode (driving, walking, bicycling, transit)</param>
        /// <returns>Distance in kilometers and duration in minutes</returns>
        Task<GoogleMapsDistanceResultDto?> GetDistanceAndDurationAsync(
            decimal originLat, 
            decimal originLng, 
            decimal destLat, 
            decimal destLng,
            string mode = "driving"
        );
        
        /// <summary>
        /// Get route directions with turn-by-turn instructions using Google Maps Directions API
        /// </summary>
        /// <param name="originLat">Origin latitude</param>
        /// <param name="originLng">Origin longitude</param>
        /// <param name="destLat">Destination latitude</param>
        /// <param name="destLng">Destination longitude</param>
        /// <param name="waypoints">Optional list of waypoint coordinates</param>
        /// <returns>Route with polyline and instructions</returns>
        Task<GoogleMapsDirectionsResultDto?> GetDirectionsAsync(
            decimal originLat,
            decimal originLng,
            decimal destLat,
            decimal destLng,
            List<(decimal lat, decimal lng)>? waypoints = null
        );
        
        /// <summary>
        /// Geocode an address to get coordinates using Google Maps Geocoding API
        /// </summary>
        /// <param name="address">Address string</param>
        /// <returns>Latitude and longitude</returns>
        Task<(decimal lat, decimal lng)?> GeocodeAddressAsync(string address);
        
        /// <summary>
        /// Get place autocomplete suggestions using Google Places API
        /// </summary>
        /// <param name="input">Search query</param>
        /// <param name="components">Country restriction (e.g., "country:in")</param>
        /// <returns>List of place suggestions</returns>
        Task<List<GooglePlaceSuggestionDto>> GetPlaceAutocompleteAsync(string input, string? components = null);
        
        /// <summary>
        /// Get detailed information about a place using Google Places API
        /// </summary>
        /// <param name="placeId">Google Place ID</param>
        /// <returns>Detailed place information</returns>
        Task<GooglePlaceDetailsDto?> GetPlaceDetailsAsync(string placeId);
        
        /// <summary>
        /// Reverse geocode coordinates to get address using Google Maps Geocoding API
        /// </summary>
        /// <param name="latitude">Latitude</param>
        /// <param name="longitude">Longitude</param>
        /// <returns>Formatted address string</returns>
        Task<string?> ReverseGeocodeAsync(decimal latitude, decimal longitude);
    }
}

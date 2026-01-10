namespace RideSharing.API.Models.DTO
{
    /// <summary>
    /// Result from Google Maps Distance Matrix API
    /// </summary>
    public class GoogleMapsDistanceResultDto
    {
        /// <summary>
        /// Distance in kilometers
        /// </summary>
        public double DistanceKm { get; set; }
        
        /// <summary>
        /// Distance in meters
        /// </summary>
        public int DistanceMeters { get; set; }
        
        /// <summary>
        /// Duration in minutes
        /// </summary>
        public int DurationMinutes { get; set; }
        
        /// <summary>
        /// Duration in seconds
        /// </summary>
        public int DurationSeconds { get; set; }
        
        /// <summary>
        /// Human-readable distance text (e.g., "10.5 km")
        /// </summary>
        public string DistanceText { get; set; } = string.Empty;
        
        /// <summary>
        /// Human-readable duration text (e.g., "15 mins")
        /// </summary>
        public string DurationText { get; set; } = string.Empty;
    }
    
    /// <summary>
    /// Result from Google Maps Directions API
    /// </summary>
    public class GoogleMapsDirectionsResultDto
    {
        /// <summary>
        /// Encoded polyline for the route
        /// </summary>
        public string Polyline { get; set; } = string.Empty;
        
        /// <summary>
        /// Total distance in kilometers
        /// </summary>
        public double DistanceKm { get; set; }
        
        /// <summary>
        /// Total duration in minutes
        /// </summary>
        public int DurationMinutes { get; set; }
        
        /// <summary>
        /// List of turn-by-turn instructions
        /// </summary>
        public List<DirectionStepDto> Steps { get; set; } = new List<DirectionStepDto>();
    }
    
    /// <summary>
    /// Individual step in directions
    /// </summary>
    public class DirectionStepDto
    {
        /// <summary>
        /// HTML instructions for this step
        /// </summary>
        public string Instructions { get; set; } = string.Empty;
        
        /// <summary>
        /// Distance for this step in meters
        /// </summary>
        public int DistanceMeters { get; set; }
        
        /// <summary>
        /// Duration for this step in seconds
        /// </summary>
        public int DurationSeconds { get; set; }
        
        /// <summary>
        /// Start location latitude
        /// </summary>
        public decimal StartLat { get; set; }
        
        /// <summary>
        /// Start location longitude
        /// </summary>
        public decimal StartLng { get; set; }
        
        /// <summary>
        /// End location latitude
        /// </summary>
        public decimal EndLat { get; set; }
        
        /// <summary>
        /// End location longitude
        /// </summary>
        public decimal EndLng { get; set; }
    }
    
    /// <summary>
    /// Google Places autocomplete suggestion
    /// </summary>
    public class GooglePlaceSuggestionDto
    {
        /// <summary>
        /// Google Place ID
        /// </summary>
        public string PlaceId { get; set; } = string.Empty;
        
        /// <summary>
        /// Full description of the place
        /// </summary>
        public string Description { get; set; } = string.Empty;
        
        /// <summary>
        /// Main text (primary name)
        /// </summary>
        public string MainText { get; set; } = string.Empty;
        
        /// <summary>
        /// Secondary text (additional context)
        /// </summary>
        public string? SecondaryText { get; set; }
    }
    
    /// <summary>
    /// Detailed information about a Google Place
    /// </summary>
    public class GooglePlaceDetailsDto
    {
        /// <summary>
        /// Google Place ID
        /// </summary>
        public string PlaceId { get; set; } = string.Empty;
        
        /// <summary>
        /// Place name
        /// </summary>
        public string Name { get; set; } = string.Empty;
        
        /// <summary>
        /// Formatted address
        /// </summary>
        public string FormattedAddress { get; set; } = string.Empty;
        
        /// <summary>
        /// Latitude
        /// </summary>
        public decimal Latitude { get; set; }
        
        /// <summary>
        /// Longitude
        /// </summary>
        public decimal Longitude { get; set; }
        
        /// <summary>
        /// Address components
        /// </summary>
        public List<AddressComponentDto> AddressComponents { get; set; } = new List<AddressComponentDto>();
    }
    
    /// <summary>
    /// Address component from Google Places
    /// </summary>
    public class AddressComponentDto
    {
        /// <summary>
        /// Long name
        /// </summary>
        public string LongName { get; set; } = string.Empty;
        
        /// <summary>
        /// Short name
        /// </summary>
        public string ShortName { get; set; } = string.Empty;
        
        /// <summary>
        /// Component types
        /// </summary>
        public List<string> Types { get; set; } = new List<string>();
    }
}

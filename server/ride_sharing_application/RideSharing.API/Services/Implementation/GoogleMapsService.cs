using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace RideSharing.API.Services.Implementation
{
    /// <summary>
    /// Service for interacting with Google Maps APIs
    /// </summary>
    public class GoogleMapsService : IGoogleMapsService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<GoogleMapsService> _logger;
        private readonly string _apiKey;
        private readonly JsonSerializerOptions _jsonOptions;

        public GoogleMapsService(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<GoogleMapsService> logger)
        {
            _httpClient = httpClientFactory.CreateClient("GoogleMaps");
            _configuration = configuration;
            _logger = logger;
            _apiKey = _configuration["GoogleMaps:ApiKey"] ?? throw new InvalidOperationException("Google Maps API Key not configured");
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
        }

        public async Task<GoogleMapsDistanceResultDto?> GetDistanceAndDurationAsync(
            decimal originLat,
            decimal originLng,
            decimal destLat,
            decimal destLng,
            string mode = "driving")
        {
            try
            {
                var origins = $"{originLat},{originLng}";
                var destinations = $"{destLat},{destLng}";
                var url = $"https://maps.googleapis.com/maps/api/distancematrix/json?origins={origins}&destinations={destinations}&mode={mode}&key={_apiKey}";

                _logger.LogInformation("Calling Google Maps Distance Matrix API: {Origins} to {Destinations}", origins, destinations);

                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<DistanceMatrixResponse>(content, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (result?.Status != "OK" || result.Rows == null || result.Rows.Count == 0)
                {
                    _logger.LogWarning("Google Maps API returned non-OK status: {Status}", result?.Status);
                    return null;
                }

                var element = result.Rows[0].Elements?[0];
                if (element?.Status != "OK")
                {
                    _logger.LogWarning("Distance element status not OK: {Status}", element?.Status);
                    return null;
                }

                return new GoogleMapsDistanceResultDto
                {
                    DistanceMeters = element.Distance?.Value ?? 0,
                    DistanceKm = (element.Distance?.Value ?? 0) / 1000.0,
                    DurationSeconds = element.Duration?.Value ?? 0,
                    DurationMinutes = (int)Math.Ceiling((element.Duration?.Value ?? 0) / 60.0),
                    DistanceText = element.Distance?.Text ?? string.Empty,
                    DurationText = element.Duration?.Text ?? string.Empty
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling Google Maps Distance Matrix API");
                return null;
            }
        }

        public async Task<GoogleMapsDirectionsResultDto?> GetDirectionsAsync(
            decimal originLat,
            decimal originLng,
            decimal destLat,
            decimal destLng,
            List<(decimal lat, decimal lng)>? waypoints = null)
        {
            try
            {
                var origin = $"{originLat},{originLng}";
                var destination = $"{destLat},{destLng}";
                var url = $"https://maps.googleapis.com/maps/api/directions/json?origin={origin}&destination={destination}&key={_apiKey}";

                if (waypoints != null && waypoints.Count > 0)
                {
                    var waypointsStr = string.Join("|", waypoints.Select(w => $"{w.lat},{w.lng}"));
                    url += $"&waypoints={waypointsStr}";
                }

                _logger.LogInformation("Calling Google Maps Directions API: {Origin} to {Destination}", origin, destination);

                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<DirectionsResponse>(content, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (result?.Status != "OK" || result.Routes == null || result.Routes.Count == 0)
                {
                    _logger.LogWarning("Google Maps Directions API returned non-OK status: {Status}. Error message: {ErrorMessage}", 
                        result?.Status, result?.ErrorMessage ?? "No error message");
                    return null;
                }

                var route = result.Routes[0];
                
                if (route.Legs == null || route.Legs.Count == 0)
                {
                    return null;
                }

                // Calculate total distance and duration across ALL legs (important for multi-waypoint routes)
                var totalDistanceMeters = 0;
                var totalDurationSeconds = 0;
                var steps = new List<DirectionStepDto>();

                foreach (var leg in route.Legs)
                {
                    totalDistanceMeters += leg.Distance?.Value ?? 0;
                    totalDurationSeconds += leg.Duration?.Value ?? 0;

                    if (leg.Steps != null)
                    {
                        steps.AddRange(leg.Steps.Select(step => new DirectionStepDto
                        {
                            Instructions = step.HtmlInstructions ?? string.Empty,
                            DistanceMeters = step.Distance?.Value ?? 0,
                            DurationSeconds = step.Duration?.Value ?? 0,
                            StartLat = (decimal)(step.StartLocation?.Lat ?? 0),
                            StartLng = (decimal)(step.StartLocation?.Lng ?? 0),
                            EndLat = (decimal)(step.EndLocation?.Lat ?? 0),
                            EndLng = (decimal)(step.EndLocation?.Lng ?? 0)
                        }));
                    }
                }

                _logger.LogInformation("📊 Processed {LegCount} leg(s): Total distance = {Distance}m, Total duration = {Duration}s", 
                    route.Legs.Count, totalDistanceMeters, totalDurationSeconds);

                return new GoogleMapsDirectionsResultDto
                {
                    Polyline = route.OverviewPolyline?.Points ?? string.Empty,
                    DistanceKm = totalDistanceMeters / 1000.0,
                    DurationMinutes = (int)Math.Ceiling(totalDurationSeconds / 60.0),
                    Steps = steps
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling Google Maps Directions API");
                return null;
            }
        }

        public async Task<(decimal lat, decimal lng)?> GeocodeAddressAsync(string address)
        {
            try
            {
                var url = $"https://maps.googleapis.com/maps/api/geocode/json?address={Uri.EscapeDataString(address)}&key={_apiKey}";

                _logger.LogInformation("Geocoding address: {Address}", address);

                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<GeocodeResponse>(content, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (result?.Status != "OK" || result.Results == null || result.Results.Count == 0)
                {
                    _logger.LogWarning("Geocoding returned non-OK status: {Status}", result?.Status);
                    return null;
                }

                var location = result.Results[0].Geometry?.Location;
                if (location == null)
                {
                    return null;
                }

                return ((decimal)location.Lat, (decimal)location.Lng);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error geocoding address: {Address}", address);
                return null;
            }
        }

        public async Task<string?> ReverseGeocodeAsync(decimal latitude, decimal longitude)
        {
            try
            {
                var latlng = $"{latitude},{longitude}";
                var url = $"https://maps.googleapis.com/maps/api/geocode/json?latlng={latlng}&key={_apiKey}";

                _logger.LogInformation("Reverse geocoding: {LatLng}", latlng);

                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<GeocodeResponse>(content, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (result?.Status != "OK" || result.Results == null || result.Results.Count == 0)
                {
                    _logger.LogWarning("Reverse geocoding returned non-OK status: {Status}", result?.Status);
                    return null;
                }

                return result.Results[0].FormattedAddress;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reverse geocoding: ({Lat}, {Lng})", latitude, longitude);
                return null;
            }
        }
        
        /// <summary>
        /// Get place autocomplete suggestions
        /// </summary>
        public async Task<List<GooglePlaceSuggestionDto>> GetPlaceAutocompleteAsync(string input, string? components = null)
        {
            try
            {
                var queryParams = new Dictionary<string, string>
                {
                    { "input", input },
                    { "key", _apiKey },
                    { "language", "en" }
                };
                
                if (!string.IsNullOrEmpty(components))
                {
                    queryParams["components"] = components;
                }
                
                var queryString = string.Join("&", queryParams.Select(kvp => $"{kvp.Key}={Uri.EscapeDataString(kvp.Value)}"));
                var url = $"https://maps.googleapis.com/maps/api/place/autocomplete/json?{queryString}";
                
                _logger.LogInformation("Calling Google Places Autocomplete API: {Url}", url);
                
                var response = await _httpClient.GetStringAsync(url);
                var result = JsonSerializer.Deserialize<PlacesAutocompleteResponse>(response, _jsonOptions);
                
                if (result?.Status != "OK")
                {
                    _logger.LogWarning("Google Places Autocomplete API returned non-OK status: {Status}. Error: {Error}", 
                        result?.Status, result?.ErrorMessage);
                    return new List<GooglePlaceSuggestionDto>();
                }
                
                if (result.Predictions == null || !result.Predictions.Any())
                {
                    return new List<GooglePlaceSuggestionDto>();
                }
                
                return result.Predictions.Select(p => new GooglePlaceSuggestionDto
                {
                    PlaceId = p.PlaceId ?? string.Empty,
                    Description = p.Description ?? string.Empty,
                    MainText = p.StructuredFormatting?.MainText ?? p.Description ?? string.Empty,
                    SecondaryText = p.StructuredFormatting?.SecondaryText
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching place autocomplete for input: {Input}", input);
                return new List<GooglePlaceSuggestionDto>();
            }
        }
        
        /// <summary>
        /// Get detailed information about a place
        /// </summary>
        public async Task<GooglePlaceDetailsDto?> GetPlaceDetailsAsync(string placeId)
        {
            try
            {
                var url = $"https://maps.googleapis.com/maps/api/place/details/json?" +
                          $"place_id={Uri.EscapeDataString(placeId)}&" +
                          $"key={_apiKey}&" +
                          $"fields=place_id,name,formatted_address,address_components,geometry&" +
                          $"language=en";
                
                _logger.LogInformation("Calling Google Places Details API for place: {PlaceId}", placeId);
                
                var response = await _httpClient.GetStringAsync(url);
                var result = JsonSerializer.Deserialize<PlaceDetailsResponse>(response, _jsonOptions);
                
                if (result?.Status != "OK" || result.Result == null)
                {
                    _logger.LogWarning("Google Places Details API returned non-OK status: {Status}. Error: {Error}", 
                        result?.Status, result?.ErrorMessage);
                    return null;
                }
                
                var place = result.Result;
                
                return new GooglePlaceDetailsDto
                {
                    PlaceId = place.PlaceId ?? string.Empty,
                    Name = place.Name ?? string.Empty,
                    FormattedAddress = place.FormattedAddress ?? string.Empty,
                    Latitude = (decimal)(place.Geometry?.Location?.Lat ?? 0),
                    Longitude = (decimal)(place.Geometry?.Location?.Lng ?? 0),
                    AddressComponents = place.AddressComponents?.Select(ac => new AddressComponentDto
                    {
                        LongName = ac.LongName ?? string.Empty,
                        ShortName = ac.ShortName ?? string.Empty,
                        Types = ac.Types ?? new List<string>()
                    }).ToList() ?? new List<AddressComponentDto>()
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching place details for: {PlaceId}", placeId);
                return null;
            }
        }

        // Internal classes for deserializing Google Maps API responses
        private class DistanceMatrixResponse
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;

            [JsonPropertyName("rows")]
            public List<Row> Rows { get; set; } = new();
        }

        private class Row
        {
            [JsonPropertyName("elements")]
            public List<Element>? Elements { get; set; }
        }

        private class Element
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;

            [JsonPropertyName("distance")]
            public Distance? Distance { get; set; }

            [JsonPropertyName("duration")]
            public Duration? Duration { get; set; }
        }

        private class Distance
        {
            [JsonPropertyName("value")]
            public int Value { get; set; }

            [JsonPropertyName("text")]
            public string Text { get; set; } = string.Empty;
        }

        private class Duration
        {
            [JsonPropertyName("value")]
            public int Value { get; set; }

            [JsonPropertyName("text")]
            public string Text { get; set; } = string.Empty;
        }

        private class DirectionsResponse
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;

            [JsonPropertyName("error_message")]
            public string? ErrorMessage { get; set; }

            [JsonPropertyName("routes")]
            public List<Route> Routes { get; set; } = new();
        }

        private class Route
        {
            [JsonPropertyName("legs")]
            public List<Leg>? Legs { get; set; }

            [JsonPropertyName("overview_polyline")]
            public Polyline? OverviewPolyline { get; set; }
        }

        private class Leg
        {
            [JsonPropertyName("distance")]
            public Distance? Distance { get; set; }

            [JsonPropertyName("duration")]
            public Duration? Duration { get; set; }

            [JsonPropertyName("steps")]
            public List<Step>? Steps { get; set; }
        }

        private class Step
        {
            [JsonPropertyName("html_instructions")]
            public string? HtmlInstructions { get; set; }

            [JsonPropertyName("distance")]
            public Distance? Distance { get; set; }

            [JsonPropertyName("duration")]
            public Duration? Duration { get; set; }

            [JsonPropertyName("start_location")]
            public Location? StartLocation { get; set; }

            [JsonPropertyName("end_location")]
            public Location? EndLocation { get; set; }
        }

        private class Polyline
        {
            [JsonPropertyName("points")]
            public string Points { get; set; } = string.Empty;
        }

        private class GeocodeResponse
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;

            [JsonPropertyName("results")]
            public List<GeocodeResult> Results { get; set; } = new();
        }

        private class GeocodeResult
        {
            [JsonPropertyName("formatted_address")]
            public string FormattedAddress { get; set; } = string.Empty;

            [JsonPropertyName("geometry")]
            public Geometry? Geometry { get; set; }
        }

        private class Geometry
        {
            [JsonPropertyName("location")]
            public Location? Location { get; set; }
        }

        private class Location
        {
            [JsonPropertyName("lat")]
            public double Lat { get; set; }

            [JsonPropertyName("lng")]
            public double Lng { get; set; }
        }
        
        private class PlacesAutocompleteResponse
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;
            
            [JsonPropertyName("error_message")]
            public string? ErrorMessage { get; set; }
            
            [JsonPropertyName("predictions")]
            public List<Prediction>? Predictions { get; set; }
        }
        
        private class Prediction
        {
            [JsonPropertyName("place_id")]
            public string? PlaceId { get; set; }
            
            [JsonPropertyName("description")]
            public string? Description { get; set; }
            
            [JsonPropertyName("structured_formatting")]
            public StructuredFormatting? StructuredFormatting { get; set; }
        }
        
        private class StructuredFormatting
        {
            [JsonPropertyName("main_text")]
            public string? MainText { get; set; }
            
            [JsonPropertyName("secondary_text")]
            public string? SecondaryText { get; set; }
        }
        
        private class PlaceDetailsResponse
        {
            [JsonPropertyName("status")]
            public string Status { get; set; } = string.Empty;
            
            [JsonPropertyName("error_message")]
            public string? ErrorMessage { get; set; }
            
            [JsonPropertyName("result")]
            public PlaceResult? Result { get; set; }
        }
        
        private class PlaceResult
        {
            [JsonPropertyName("place_id")]
            public string? PlaceId { get; set; }
            
            [JsonPropertyName("name")]
            public string? Name { get; set; }
            
            [JsonPropertyName("formatted_address")]
            public string? FormattedAddress { get; set; }
            
            [JsonPropertyName("address_components")]
            public List<AddressComponent>? AddressComponents { get; set; }
            
            [JsonPropertyName("geometry")]
            public Geometry? Geometry { get; set; }
        }
        
        private class AddressComponent
        {
            [JsonPropertyName("long_name")]
            public string? LongName { get; set; }
            
            [JsonPropertyName("short_name")]
            public string? ShortName { get; set; }
            
            [JsonPropertyName("types")]
            public List<string>? Types { get; set; }
        }
    }
}

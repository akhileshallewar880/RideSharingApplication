using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public class LocationSuggestionDto
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string State { get; set; }
        public string District { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public string FullAddress { get; set; }
    }

    public class LocationSearchResponseDto
    {
        public List<LocationSuggestionDto> Locations { get; set; } = new();
    }

    public class LocationSearchRequestDto
    {
        [Required]
        [MinLength(2)]
        public string Query { get; set; }
        
        public int Limit { get; set; } = 10;
    }
}

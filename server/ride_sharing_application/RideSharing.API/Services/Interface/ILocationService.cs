using RideSharing.API.Models.DTO;

namespace RideSharing.API.Services.Interface
{
    public interface ILocationService
    {
        Task<List<LocationSuggestionDto>> SearchLocationsAsync(string query, int limit = 10);
        Task<LocationSuggestionDto?> GetLocationByIdAsync(string id);
        List<LocationSuggestionDto> GetAllLocations();
    }
}

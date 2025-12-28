using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface IVehicleModelRepository
    {
        Task<List<VehicleModel>> GetAllVehicleModelsAsync(string? type = null, bool? active = null);
        Task<VehicleModel?> GetVehicleModelByIdAsync(Guid id);
        Task<List<VehicleModel>> SearchVehicleModelsAsync(string query);
    }
}

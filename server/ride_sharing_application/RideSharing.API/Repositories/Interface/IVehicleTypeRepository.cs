using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface IVehicleTypeRepository
    {
        Task<List<VehicleType>> GetAllVehicleTypesAsync(bool? isActive = null, string? category = null);
        Task<VehicleType?> GetVehicleTypeByIdAsync(Guid id);
        Task<VehicleType?> GetVehicleTypeByNameAsync(string name);
        Task<VehicleType> CreateVehicleTypeAsync(VehicleType vehicleType);
        Task<VehicleType?> UpdateVehicleTypeAsync(Guid id, VehicleType vehicleType);
        Task<bool> DeleteVehicleTypeAsync(Guid id);
        Task<bool> VehicleTypeExistsAsync(string name, Guid? excludeId = null);
    }
}

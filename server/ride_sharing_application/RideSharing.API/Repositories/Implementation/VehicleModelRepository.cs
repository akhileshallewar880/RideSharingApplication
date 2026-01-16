using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class VehicleModelRepository : IVehicleModelRepository
    {
        private readonly RideSharingDbContext _context;

        public VehicleModelRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<List<VehicleModel>> GetAllVehicleModelsAsync(string? type = null, bool? active = null)
        {
            var query = _context.VehicleModels.AsQueryable();

            if (!string.IsNullOrEmpty(type))
            {
                query = query.Where(vm => vm.Type.ToLower() == type.ToLower());
            }

            if (active.HasValue)
            {
                query = query.Where(vm => vm.IsActive == active.Value);
            }

            return await query.OrderBy(vm => vm.Brand).ThenBy(vm => vm.Name).ToListAsync();
        }

        public async Task<VehicleModel?> GetVehicleModelByIdAsync(Guid id)
        {
            return await _context.VehicleModels.FirstOrDefaultAsync(vm => vm.Id == id);
        }

        public async Task<List<VehicleModel>> SearchVehicleModelsAsync(string query)
        {
            var lowerQuery = query.ToLower();
            return await _context.VehicleModels
                .Where(vm => vm.IsActive && 
                       (vm.Name.ToLower().Contains(lowerQuery) || 
                        vm.Brand.ToLower().Contains(lowerQuery)))
                .OrderBy(vm => vm.Brand)
                .ThenBy(vm => vm.Name)
                .ToListAsync();
        }

        public async Task<VehicleModel> CreateVehicleModelAsync(VehicleModel vehicleModel)
        {
            vehicleModel.Id = Guid.NewGuid();
            vehicleModel.CreatedAt = DateTime.UtcNow;
            vehicleModel.UpdatedAt = DateTime.UtcNow;
            
            _context.VehicleModels.Add(vehicleModel);
            await _context.SaveChangesAsync();
            
            return vehicleModel;
        }

        public async Task<VehicleModel?> UpdateVehicleModelAsync(Guid id, VehicleModel vehicleModel)
        {
            var existingModel = await _context.VehicleModels.FirstOrDefaultAsync(vm => vm.Id == id);
            if (existingModel == null)
            {
                return null;
            }

            existingModel.Name = vehicleModel.Name;
            existingModel.Brand = vehicleModel.Brand;
            existingModel.Type = vehicleModel.Type;
            existingModel.SeatingCapacity = vehicleModel.SeatingCapacity;
            existingModel.SeatingLayout = vehicleModel.SeatingLayout;
            existingModel.ImageUrl = vehicleModel.ImageUrl;
            existingModel.Features = vehicleModel.Features;
            existingModel.Description = vehicleModel.Description;
            existingModel.IsActive = vehicleModel.IsActive;
            existingModel.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            
            return existingModel;
        }

        public async Task<bool> DeleteVehicleModelAsync(Guid id)
        {
            var vehicleModel = await _context.VehicleModels.FirstOrDefaultAsync(vm => vm.Id == id);
            if (vehicleModel == null)
            {
                return false;
            }

            _context.VehicleModels.Remove(vehicleModel);
            await _context.SaveChangesAsync();
            
            return true;
        }
    }
}

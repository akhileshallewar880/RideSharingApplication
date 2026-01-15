using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class VehicleTypeRepository : IVehicleTypeRepository
    {
        private readonly RideSharingDbContext _dbContext;

        public VehicleTypeRepository(RideSharingDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<List<VehicleType>> GetAllVehicleTypesAsync(bool? isActive = null, string? category = null)
        {
            var query = _dbContext.VehicleTypes.AsQueryable();

            if (isActive.HasValue)
            {
                query = query.Where(vt => vt.IsActive == isActive.Value);
            }

            if (!string.IsNullOrEmpty(category))
            {
                query = query.Where(vt => vt.Category == category);
            }

            return await query.OrderBy(vt => vt.DisplayOrder).ThenBy(vt => vt.DisplayName).ToListAsync();
        }

        public async Task<VehicleType?> GetVehicleTypeByIdAsync(Guid id)
        {
            return await _dbContext.VehicleTypes.FirstOrDefaultAsync(vt => vt.Id == id);
        }

        public async Task<VehicleType?> GetVehicleTypeByNameAsync(string name)
        {
            return await _dbContext.VehicleTypes.FirstOrDefaultAsync(vt => vt.Name.ToLower() == name.ToLower());
        }

        public async Task<VehicleType> CreateVehicleTypeAsync(VehicleType vehicleType)
        {
            vehicleType.Id = Guid.NewGuid();
            vehicleType.CreatedAt = DateTime.UtcNow;
            vehicleType.UpdatedAt = DateTime.UtcNow;

            await _dbContext.VehicleTypes.AddAsync(vehicleType);
            await _dbContext.SaveChangesAsync();

            return vehicleType;
        }

        public async Task<VehicleType?> UpdateVehicleTypeAsync(Guid id, VehicleType vehicleType)
        {
            var existingVehicleType = await _dbContext.VehicleTypes.FirstOrDefaultAsync(vt => vt.Id == id);
            
            if (existingVehicleType == null)
            {
                return null;
            }

            existingVehicleType.Name = vehicleType.Name;
            existingVehicleType.DisplayName = vehicleType.DisplayName;
            existingVehicleType.Icon = vehicleType.Icon;
            existingVehicleType.Description = vehicleType.Description;
            existingVehicleType.BasePrice = vehicleType.BasePrice;
            existingVehicleType.PricePerKm = vehicleType.PricePerKm;
            existingVehicleType.PricePerMinute = vehicleType.PricePerMinute;
            existingVehicleType.MinSeats = vehicleType.MinSeats;
            existingVehicleType.MaxSeats = vehicleType.MaxSeats;
            existingVehicleType.IsActive = vehicleType.IsActive;
            existingVehicleType.DisplayOrder = vehicleType.DisplayOrder;
            existingVehicleType.Category = vehicleType.Category;
            existingVehicleType.Features = vehicleType.Features;
            existingVehicleType.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            return existingVehicleType;
        }

        public async Task<bool> DeleteVehicleTypeAsync(Guid id)
        {
            var vehicleType = await _dbContext.VehicleTypes.FirstOrDefaultAsync(vt => vt.Id == id);
            
            if (vehicleType == null)
            {
                return false;
            }

            _dbContext.VehicleTypes.Remove(vehicleType);
            await _dbContext.SaveChangesAsync();

            return true;
        }

        public async Task<bool> VehicleTypeExistsAsync(string name, Guid? excludeId = null)
        {
            var query = _dbContext.VehicleTypes.Where(vt => vt.Name.ToLower() == name.ToLower());

            if (excludeId.HasValue)
            {
                query = query.Where(vt => vt.Id != excludeId.Value);
            }

            return await query.AnyAsync();
        }
    }
}

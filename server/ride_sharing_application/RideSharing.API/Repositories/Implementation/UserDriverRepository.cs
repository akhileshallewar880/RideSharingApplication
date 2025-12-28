using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class UserDriverRepository : IUserDriverRepository
    {
        private readonly RideSharingDbContext _db;

        public UserDriverRepository(RideSharingDbContext db)
        {
            _db = db;
        }

        public async Task<UserProfileDto?> GetUserProfileAsync(Guid id)
        {
            var user = await _db.Users.Include(u => u.Profile).FirstOrDefaultAsync(u => u.Id == id);
            if (user == null || user.Profile == null) return null;
            return new UserProfileDto(user.Id, user.PhoneNumber, user.Profile.Name, user.Email, user.UserType, user.IsActive);
        }

        public async Task<UserProfileDto?> UpdateUserProfileAsync(Guid id, UpdateProfileRequest req)
        {
            var user = await _db.Users.Include(u => u.Profile).FirstOrDefaultAsync(u => u.Id == id);
            if (user == null || user.Profile == null) return null;
            user.Profile.Name = req.Name ?? user.Profile.Name;
            user.Email = req.Email ?? user.Email;
            user.UpdatedAt = DateTime.UtcNow;
            user.Profile.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return new UserProfileDto(user.Id, user.PhoneNumber, user.Profile.Name, user.Email, user.UserType, user.IsActive);
        }

        public async Task<DriverDto?> RegisterDriverAsync(DriverOnboardRequest req)
        {
            var user = await _db.Users.FindAsync(req.UserId);
            if (user == null) return null;
            
            var driver = new Driver
            {
                Id = Guid.NewGuid(),
                UserId = req.UserId,
                LicenseNumber = req.VehicleNumber, // Map old field to new
                LicenseExpiryDate = DateTime.UtcNow.AddYears(5), // Default expiry
                LicenseVerified = false,
                IsVerified = false,
                VerificationStatus = "pending",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            
            _db.Drivers.Add(driver);
            await _db.SaveChangesAsync();
            
            return new DriverDto(driver.Id, driver.UserId, driver.LicenseNumber, "unknown", 0, driver.VerificationStatus);
        }

        public async Task<DriverDto?> GetDriverAsync(Guid id)
        {
            var driver = await _db.Drivers.Include(d => d.Vehicles).FirstOrDefaultAsync(d => d.Id == id);
            if (driver == null) return null;
            
            var vehicle = driver.Vehicles.FirstOrDefault();
            return new DriverDto(
                driver.Id, 
                driver.UserId, 
                vehicle?.RegistrationNumber ?? "N/A", 
                vehicle?.VehicleType ?? "unknown", 
                vehicle?.TotalSeats ?? 0, 
                driver.VerificationStatus);
        }

        public async Task<IEnumerable<RouteDto>> GetDriverRoutesAsync(Guid id)
        {
            var driver = await _db.Drivers
                .Include(d => d.Rides)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (driver == null) return Enumerable.Empty<RouteDto>();

            // Map new Ride model to old RouteDto structure for backward compatibility
            return driver.Rides.Select(ride => new RouteDto(
                ride.Id,
                ride.DriverId,
                $"{ride.PickupLocation} to {ride.DropoffLocation}", // RouteName
                ride.PickupLocation, // Origin
                ride.DropoffLocation, // Destination
                0, // DistanceKm - not tracked in new schema
                null // RouteStops - not applicable in new schema
            ));
        }
    }
}

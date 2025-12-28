using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.Repositories.Interface;

public interface IUserDriverRepository
{
    Task<UserProfileDto?> GetUserProfileAsync(Guid id);
    Task<UserProfileDto?> UpdateUserProfileAsync(Guid id, UpdateProfileRequest req);
    Task<DriverDto?> RegisterDriverAsync(DriverOnboardRequest req);
    Task<DriverDto?> GetDriverAsync(Guid id);
    Task<IEnumerable<RouteDto>> GetDriverRoutesAsync(Guid id);
}

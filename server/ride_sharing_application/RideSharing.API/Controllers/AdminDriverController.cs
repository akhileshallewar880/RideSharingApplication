using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Helpers;
using RideSharing.API.Models.Domain;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    [Authorize] // Requires JWT authentication
    public class AdminDriverController : ControllerBase
    {
        private readonly RideSharingDbContext _context;

        public AdminDriverController(RideSharingDbContext context)
        {
            _context = context;
        }

        // POST: api/v1/AdminDriver/register
        // Register a new driver (creates user account + driver profile)
        [HttpPost("register")]
        [Authorize(Roles = "admin,super_admin")]
        public async Task<IActionResult> RegisterDriver([FromBody] RegisterDriverRequest request)
        {
            try
            {
                // Validate request - only phone, password, and name are required
                if (string.IsNullOrEmpty(request.PhoneNumber) || string.IsNullOrEmpty(request.Password) || string.IsNullOrEmpty(request.Name))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Phone number, password, and name are required to proceed further"
                    });
                }

                // Check if user already exists by phone number
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber);
                
                if (existingUser != null)
                {
                    return Conflict(new
                    {
                        success = false,
                        message = "User with this phone number already exists"
                    });
                }

                // If email provided, check if it exists
                if (!string.IsNullOrEmpty(request.Email))
                {
                    var existingEmailUser = await _context.Users
                        .FirstOrDefaultAsync(u => u.Email == request.Email);
                    
                    if (existingEmailUser != null)
                    {
                        return Conflict(new
                        {
                            success = false,
                            message = "User with this email already exists"
                        });
                    }
                }

                // Create new user account
                var userId = Guid.NewGuid();
                var newUser = new User
                {
                    Id = userId,
                    Email = request.Email,
                    PhoneNumber = request.PhoneNumber,
                    CountryCode = request.CountryCode ?? "+91",
                    PasswordHash = PasswordHelper.HashPassword(request.Password),
                    UserType = "driver",
                    IsActive = true,
                    IsEmailVerified = !string.IsNullOrEmpty(request.Email), // Only verify if email provided
                    IsPhoneVerified = true,
                    IsBlocked = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Create user profile
                var profile = new UserProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Name = request.Name,
                    Address = request.Address,
                    EmergencyContact = request.EmergencyContact,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Create driver profile
                var driver = new Driver
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    LicenseNumber = request.LicenseNumber,
                    LicenseExpiryDate = request.LicenseExpiryDate ?? DateTime.UtcNow.AddYears(5),
                    LicenseVerified = false,
                    IsVerified = false,
                    VerificationStatus = "pending",
                    IsOnline = false,
                    IsAvailable = false,
                    TotalEarnings = 0,
                    PendingEarnings = 0,
                    AvailableForWithdrawal = 0,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Add to database
                _context.Users.Add(newUser);
                _context.UserProfiles.Add(profile);
                _context.Drivers.Add(driver);
                
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "Driver registered successfully",
                    data = new
                    {
                        userId = newUser.Id,
                        driverId = driver.Id,
                        email = newUser.Email,
                        phone = newUser.PhoneNumber,
                        name = profile.Name,
                        verificationStatus = driver.VerificationStatus
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to register driver",
                    error = ex.Message
                });
            }
        }

        // PUT: api/v1/AdminDriver/{driverId}/block
        // Block or unblock a driver
        [HttpPut("{driverId}/block")]
        [Authorize(Roles = "admin,super_admin")]
        public async Task<IActionResult> BlockDriver(Guid driverId, [FromBody] BlockDriverRequest request)
        {
            try
            {
                var driver = await _context.Drivers
                    .Include(d => d.User)
                    .FirstOrDefaultAsync(d => d.Id == driverId);

                if (driver == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "Driver not found"
                    });
                }

                // Update user status
                driver.User.IsActive = !request.Block;
                driver.User.IsBlocked = request.Block;
                driver.User.BlockedReason = request.Block ? request.Reason : null;
                driver.User.UpdatedAt = DateTime.UtcNow;

                // Update driver availability
                if (request.Block)
                {
                    driver.IsOnline = false;
                    driver.IsAvailable = false;
                }

                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = request.Block ? "Driver blocked successfully" : "Driver unblocked successfully",
                    data = new
                    {
                        driverId = driver.Id,
                        userId = driver.UserId,
                        isActive = driver.User.IsActive,
                        isBlocked = driver.User.IsBlocked,
                        blockedReason = driver.User.BlockedReason
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to update driver status",
                    error = ex.Message
                });
            }
        }

        // PUT: api/v1/AdminDriver/{driverId}/verify
        // Verify or reject a driver's documents
        [HttpPut("{driverId}/verify")]
        [Authorize(Roles = "admin,super_admin")]
        public async Task<IActionResult> VerifyDriver(Guid driverId, [FromBody] VerifyDriverRequest request)
        {
            try
            {
                var driver = await _context.Drivers.FindAsync(driverId);
                if (driver == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "Driver not found"
                    });
                }

                driver.VerificationStatus = request.Approve ? "approved" : "rejected";
                driver.IsVerified = request.Approve;
                driver.LicenseVerified = request.Approve;
                driver.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = request.Approve ? "Driver verified successfully" : "Driver verification rejected",
                    data = new
                    {
                        driver.Id,
                        driver.VerificationStatus,
                        driver.IsVerified
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to verify driver",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminDriver
        // Get all drivers with filters
        [HttpGet]
        [Authorize(Roles = "admin,super_admin")]
        public async Task<IActionResult> GetDrivers(
            [FromQuery] string? status = null, // all, active, blocked, pending, approved, rejected
            [FromQuery] string? search = null,
            [FromQuery] int page = 1,
            [FromQuery] int limit = 20)
        {
            try
            {
                var query = _context.Drivers
                    .Include(d => d.User)
                        .ThenInclude(u => u.Profile)
                    .Include(d => d.Vehicles)
                    .AsQueryable();

                // Filter by status
                if (!string.IsNullOrEmpty(status) && status != "all")
                {
                    switch (status.ToLower())
                    {
                        case "active":
                            query = query.Where(d => d.User.IsActive && !d.User.IsBlocked);
                            break;
                        case "blocked":
                            query = query.Where(d => d.User.IsBlocked);
                            break;
                        case "pending":
                            query = query.Where(d => d.VerificationStatus == "pending");
                            break;
                        case "approved":
                            query = query.Where(d => d.VerificationStatus == "approved");
                            break;
                        case "rejected":
                            query = query.Where(d => d.VerificationStatus == "rejected");
                            break;
                    }
                }

                // Search by name, email, phone, or license number
                if (!string.IsNullOrEmpty(search))
                {
                    query = query.Where(d =>
                        (d.User.Email != null && d.User.Email.Contains(search)) ||
                        d.User.PhoneNumber.Contains(search) ||
                        (d.User.Profile != null && d.User.Profile.Name.Contains(search)) ||
                        d.LicenseNumber.Contains(search)
                    );
                }

                var totalCount = await query.CountAsync();
                var drivers = await query
                    .OrderByDescending(d => d.CreatedAt)
                    .Skip((page - 1) * limit)
                    .Take(limit)
                    .Select(d => new
                    {
                        driverId = d.Id,
                        userId = d.UserId,
                        name = d.User.Profile != null ? d.User.Profile.Name : "N/A",
                        email = d.User.Email,
                        phone = d.User.PhoneNumber,
                        licenseNumber = d.LicenseNumber,
                        licenseExpiry = d.LicenseExpiryDate,
                        verificationStatus = d.VerificationStatus,
                        isVerified = d.IsVerified,
                        isActive = d.User.IsActive,
                        isBlocked = d.User.IsBlocked,
                        isOnline = d.IsOnline,
                        isAvailable = d.IsAvailable,
                        totalEarnings = d.TotalEarnings,
                        totalRides = d.Rides.Count,
                        completedRides = d.Rides.Count(r => r.Status == "completed"),
                        vehicleCount = d.Vehicles.Count,
                        createdAt = d.CreatedAt,
                        lastLogin = d.User.LastLoginAt
                    })
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    data = drivers,
                    pagination = new
                    {
                        page,
                        limit,
                        totalCount,
                        totalPages = (int)Math.Ceiling((double)totalCount / limit)
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to retrieve drivers",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminDriver/{driverId}
        // Get driver details
        [HttpGet("{driverId}")]
        [Authorize(Roles = "admin,super_admin")]
        public async Task<IActionResult> GetDriverById(Guid driverId)
        {
            try
            {
                var driver = await _context.Drivers
                    .Include(d => d.User)
                        .ThenInclude(u => u.Profile)
                    .Include(d => d.Vehicles)
                    .Include(d => d.Rides)
                    .FirstOrDefaultAsync(d => d.Id == driverId);

                if (driver == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "Driver not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    data = new
                    {
                        driverId = driver.Id,
                        userId = driver.UserId,
                        name = driver.User.Profile?.Name ?? "N/A",
                        email = driver.User.Email,
                        phone = driver.User.PhoneNumber,
                        address = driver.User.Profile?.Address,
                        emergencyContact = driver.User.Profile?.EmergencyContact,
                        licenseNumber = driver.LicenseNumber,
                        licenseExpiry = driver.LicenseExpiryDate,
                        licenseVerified = driver.LicenseVerified,
                        verificationStatus = driver.VerificationStatus,
                        isVerified = driver.IsVerified,
                        isActive = driver.User.IsActive,
                        isBlocked = driver.User.IsBlocked,
                        blockedReason = driver.User.BlockedReason,
                        isOnline = driver.IsOnline,
                        isAvailable = driver.IsAvailable,
                        totalEarnings = driver.TotalEarnings,
                        pendingEarnings = driver.PendingEarnings,
                        availableForWithdrawal = driver.AvailableForWithdrawal,
                        vehicles = driver.Vehicles.Select(v => new
                        {
                            v.Id,
                            v.RegistrationNumber,
                            v.VehicleType,
                            v.TotalSeats,
                            v.IsActive
                        }),
                        statistics = new
                        {
                            totalRides = driver.Rides.Count,
                            completedRides = driver.Rides.Count(r => r.Status == "completed"),
                            cancelledRides = driver.Rides.Count(r => r.Status == "cancelled"),
                            totalEarnings = driver.TotalEarnings
                        },
                        createdAt = driver.CreatedAt,
                        lastLogin = driver.User.LastLoginAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to retrieve driver details",
                    error = ex.Message
                });
            }
        }
    }

    // DTOs for request validation
    public class RegisterDriverRequest
    {
        public string? Email { get; set; }
        public string Password { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? CountryCode { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? EmergencyContact { get; set; }
        public string LicenseNumber { get; set; } = string.Empty;
        public DateTime? LicenseExpiryDate { get; set; }
        public string? VehicleNumber { get; set; }
    }

    public class BlockDriverRequest
    {
        public bool Block { get; set; } // true = block, false = unblock
        public string? Reason { get; set; }
    }

    public class VerifyDriverRequest
    {
        public bool Approve { get; set; } // true = approve, false = reject
        public string? Notes { get; set; }
    }
}

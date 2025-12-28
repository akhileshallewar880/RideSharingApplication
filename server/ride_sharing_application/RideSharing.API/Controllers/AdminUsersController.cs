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
    public class AdminUsersController : ControllerBase
    {
        private readonly RideSharingDbContext _context;

        public AdminUsersController(RideSharingDbContext context)
        {
            _context = context;
        }

        // GET: api/v1/AdminUsers?page=1&limit=20&search=john&userType=passenger&status=active
        [HttpGet]
        public async Task<IActionResult> GetUsers(
            [FromQuery] int page = 1,
            [FromQuery] int limit = 20,
            [FromQuery] string? search = null,
            [FromQuery] string? userType = null,
            [FromQuery] string? status = null)
        {
            try
            {
                var query = _context.Users
                    .Include(u => u.Profile)
                    .Include(u => u.Driver)
                    .AsQueryable();

                // Apply filters
                if (!string.IsNullOrEmpty(search))
                {
                    query = query.Where(u =>
                        (u.Email != null && u.Email.Contains(search)) ||
                        u.PhoneNumber.Contains(search));
                }

                if (!string.IsNullOrEmpty(userType))
                {
                    query = query.Where(u => u.UserType == userType);
                }

                if (!string.IsNullOrEmpty(status))
                {
                    var isActive = status.ToLower() == "active";
                    query = query.Where(u => u.IsActive == isActive);
                }

                var totalCount = await query.CountAsync();
                var totalPages = (int)Math.Ceiling(totalCount / (double)limit);

                var users = await query
                    .OrderByDescending(u => u.CreatedAt)
                    .Skip((page - 1) * limit)
                    .Take(limit)
                    .Select(u => new
                    {
                        u.Id,
                        u.Email,
                        Name = u.Profile != null ? u.Profile.Name : (u.Email ?? u.PhoneNumber),
                        Phone = u.PhoneNumber,
                        u.UserType,
                        u.IsActive,
                        u.IsEmailVerified,
                        u.IsPhoneVerified,
                        u.CreatedAt,
                        u.LastLoginAt,
                        ProfileCompleted = u.Profile != null,
                        IsDriver = u.Driver != null,
                        DriverStatus = u.Driver != null ? u.Driver.VerificationStatus : null,
                        RideCount = u.UserType == "driver"
                            ? (u.Driver != null ? u.Driver.Rides.Count : 0)
                            : u.Bookings.Count
                    })
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    data = users,
                    pagination = new
                    {
                        currentPage = page,
                        totalPages,
                        totalCount,
                        limit
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch users",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminUsers/{userId}
        [HttpGet("{userId}")]
        public async Task<IActionResult> GetUserById(Guid userId)
        {
            try
            {
                var user = await _context.Users
                    .Include(u => u.Profile)
                    .Include(u => u.Driver)
                    .Include(u => u.Bookings)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "User not found"
                    });
                }

                // Build response object
                var response = new
                {
                    user.Id,
                    user.Email,
                    Phone = user.PhoneNumber,
                    user.UserType,
                    user.IsActive,
                    user.IsEmailVerified,
                    user.IsPhoneVerified,
                    user.CreatedAt,
                    user.UpdatedAt,
                    user.LastLoginAt,
                    Profile = user.Profile != null ? new
                    {
                        user.Profile.DateOfBirth,
                        user.Profile.Gender,
                        user.Profile.Address,
                        user.Profile.City,
                        user.Profile.State,
                        user.Profile.PinCode,
                        ProfilePicture = (string?)null // Schema doesn't have ProfilePictureUrl
                    } : null,
                    Driver = user.Driver != null ? new
                    {
                        user.Driver.Id,
                        user.Driver.LicenseNumber,
                        user.Driver.LicenseExpiryDate,
                        user.Driver.LicenseVerified,
                        user.Driver.AadharVerified,
                        user.Driver.IsOnline,
                        user.Driver.IsAvailable,
                        user.Driver.IsVerified,
                        Status = user.Driver.VerificationStatus,
                        user.Driver.TotalEarnings,
                        user.Driver.PendingEarnings,
                        user.Driver.AvailableForWithdrawal,
                        TotalRides = user.Driver.Rides.Count,
                        CompletedRides = user.Driver.Rides.Count(r => r.Status == "completed")
                    } : null,
                    Statistics = new
                    {
                        TotalBookings = user.Bookings.Count,
                        CompletedBookings = user.Bookings.Count(b => b.Status == "completed"),
                        CancelledBookings = user.Bookings.Count(b => b.Status == "cancelled"),
                        TotalSpent = user.Bookings.Where(b => b.Status == "completed").Sum(b => b.TotalAmount)
                    }
                };

                return Ok(new
                {
                    success = true,
                    data = response
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch user details",
                    error = ex.Message
                });
            }
        }

        // POST: api/v1/AdminUsers/create-admin
        // Only Super Admin can create other admin users
        [HttpPost("create-admin")]
        [Authorize(Roles = "super_admin")] // Requires super admin role
        public async Task<IActionResult> CreateAdminUser([FromBody] CreateAdminRequest request)
        {
            try
            {
                // Validate request
                if (string.IsNullOrEmpty(request.Email) || string.IsNullOrEmpty(request.Password))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Email and password are required"
                    });
                }

                if (string.IsNullOrWhiteSpace(request.Phone))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Phone number is required"
                    });
                }

                if (request.PhoneVerified != true)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Phone number must be verified"
                    });
                }

                // Check if user already exists
                var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
                if (existingUser != null)
                {
                    return Conflict(new
                    {
                        success = false,
                        message = "User with this email already exists"
                    });
                }

                // Create new admin user
                var adminUser = new User
                {
                    Id = Guid.NewGuid(),
                    Email = request.Email,
                    PhoneNumber = request.Phone.Trim(),
                    PasswordHash = PasswordHelper.HashPassword(request.Password),
                    UserType = request.Role ?? "admin", // admin or staff
                    IsActive = true,
                    IsEmailVerified = true, // Auto-verify admin emails
                    IsPhoneVerified = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(adminUser);

                // Ensure admin has a profile so name shows in admin UI
                var adminProfile = new UserProfile
                {
                    Id = Guid.NewGuid(),
                    UserId = adminUser.Id,
                    Name = string.IsNullOrWhiteSpace(request.Name) ? "Administrator" : request.Name.Trim(),
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UserProfiles.Add(adminProfile);

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "Admin user created successfully",
                    data = new
                    {
                        adminUser.Id,
                        adminUser.Email,
                        adminUser.UserType
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to create admin user",
                    error = ex.Message
                });
            }
        }

        // PUT: api/v1/AdminUsers/{userId}/block
        [HttpPut("{userId}/block")]
        public async Task<IActionResult> BlockUser(Guid userId, [FromBody] BlockUserRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "User not found"
                    });
                }

                // Toggle active status
                user.IsActive = request.Block ? false : true;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = request.Block ? "User blocked successfully" : "User unblocked successfully",
                    data = new
                    {
                        user.Id,
                        user.IsActive,
                        BlockReason = request.Reason
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to update user status",
                    error = ex.Message
                });
            }
        }

        // DELETE: api/v1/AdminUsers/{userId}
        // Soft delete only (set IsActive to false)
        [HttpDelete("{userId}")]
        [Authorize(Roles = "super_admin")] // Only super admin can delete users
        public async Task<IActionResult> DeleteUser(Guid userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "User not found"
                    });
                }

                // Soft delete (set IsActive to false)
                user.IsActive = false;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "User deleted successfully (soft delete)",
                    data = new
                    {
                        user.Id,
                        user.Email
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to delete user",
                    error = ex.Message
                });
            }
        }
    }

    // DTOs for request validation
    public class CreateAdminRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? Name { get; set; }
        public string? Phone { get; set; }
        public string? Role { get; set; } // "admin" or "staff"
        public bool? PhoneVerified { get; set; }
    }

    public class BlockUserRequest
    {
        public bool Block { get; set; } = true;
        public string? Reason { get; set; }
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;

namespace RideSharing.API.Controllers;

[Route("api/v1/admin/banners")]
[ApiController]
[Authorize(Roles = "admin")]
public class AdminBannersController : ControllerBase
{
    private readonly RideSharingDbContext _context;
    private readonly ILogger<AdminBannersController> _logger;
    private readonly IWebHostEnvironment _environment;

    public AdminBannersController(
        RideSharingDbContext context,
        ILogger<AdminBannersController> logger,
        IWebHostEnvironment environment)
    {
        _context = context;
        _logger = logger;
        _environment = environment;
    }

    /// <summary>
    /// Get all banners with optional filters
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetBanners(
        [FromQuery] bool? isActive = null,
        [FromQuery] string? targetAudience = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var query = _context.Banners.AsQueryable();

            // Apply filters
            if (isActive.HasValue)
            {
                query = query.Where(b => b.IsActive == isActive.Value);
            }

            if (!string.IsNullOrWhiteSpace(targetAudience))
            {
                query = query.Where(b => b.TargetAudience == targetAudience);
            }

            if (fromDate.HasValue)
            {
                query = query.Where(b => b.StartDate >= fromDate.Value);
            }

            if (toDate.HasValue)
            {
                query = query.Where(b => b.EndDate <= toDate.Value);
            }

            // Get total count for pagination
            var totalCount = await query.CountAsync();

            // Apply pagination and ordering
            var banners = await query
                .OrderBy(b => b.DisplayOrder)
                .ThenByDescending(b => b.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(new
            {
                success = true,
                data = banners,
                pagination = new
                {
                    currentPage = page,
                    pageSize,
                    totalCount,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banners");
            return StatusCode(500, new { success = false, message = "Error retrieving banners" });
        }
    }

    /// <summary>
    /// Get banner by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetBanner(Guid id)
    {
        try
        {
            var banner = await _context.Banners.FindAsync(id);

            if (banner == null)
            {
                return NotFound(new { success = false, message = "Banner not found" });
            }

            return Ok(new { success = true, data = banner });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving banner {BannerId}", id);
            return StatusCode(500, new { success = false, message = "Error retrieving banner" });
        }
    }

    /// <summary>
    /// Create new banner
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateBanner([FromBody] CreateBannerRequest request)
    {
        try
        {
            // Validate request
            if (string.IsNullOrWhiteSpace(request.Title))
            {
                return BadRequest(new { success = false, message = "Title is required" });
            }

            if (request.StartDate >= request.EndDate)
            {
                return BadRequest(new { success = false, message = "End date must be after start date" });
            }

            var banner = new Banner
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Description = request.Description,
                ImageUrl = request.ImageUrl,
                ActionUrl = request.ActionUrl,
                ActionType = request.ActionType ?? "none",
                ActionText = request.ActionText,
                DisplayOrder = request.DisplayOrder,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                IsActive = request.IsActive,
                TargetAudience = request.TargetAudience ?? "all",
                ImpressionCount = 0,
                ClickCount = 0,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Banners.Add(banner);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created banner {BannerId} - {Title}", banner.Id, banner.Title);

            return CreatedAtAction(nameof(GetBanner), new { id = banner.Id }, new { success = true, data = banner });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating banner");
            return StatusCode(500, new { success = false, message = "Error creating banner" });
        }
    }

    /// <summary>
    /// Update banner
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateBanner(Guid id, [FromBody] UpdateBannerRequest request)
    {
        try
        {
            var banner = await _context.Banners.FindAsync(id);

            if (banner == null)
            {
                return NotFound(new { success = false, message = "Banner not found" });
            }

            // Validate dates
            if (request.StartDate.HasValue && request.EndDate.HasValue && request.StartDate >= request.EndDate)
            {
                return BadRequest(new { success = false, message = "End date must be after start date" });
            }

            // Update fields
            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                banner.Title = request.Title;
            }

            if (request.Description != null)
            {
                banner.Description = request.Description;
            }

            if (request.ImageUrl != null)
            {
                banner.ImageUrl = request.ImageUrl;
            }

            if (request.ActionUrl != null)
            {
                banner.ActionUrl = request.ActionUrl;
            }

            if (request.ActionType != null)
            {
                banner.ActionType = request.ActionType;
            }

            if (request.ActionText != null)
            {
                banner.ActionText = request.ActionText;
            }

            if (request.DisplayOrder.HasValue)
            {
                banner.DisplayOrder = request.DisplayOrder.Value;
            }

            if (request.StartDate.HasValue)
            {
                banner.StartDate = request.StartDate.Value;
            }

            if (request.EndDate.HasValue)
            {
                banner.EndDate = request.EndDate.Value;
            }

            if (request.IsActive.HasValue)
            {
                banner.IsActive = request.IsActive.Value;
            }

            if (request.TargetAudience != null)
            {
                banner.TargetAudience = request.TargetAudience;
            }

            banner.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Updated banner {BannerId} - {Title}", banner.Id, banner.Title);

            return Ok(new { success = true, data = banner });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating banner {BannerId}", id);
            return StatusCode(500, new { success = false, message = "Error updating banner" });
        }
    }

    /// <summary>
    /// Delete banner
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBanner(Guid id)
    {
        try
        {
            var banner = await _context.Banners.FindAsync(id);

            if (banner == null)
            {
                return NotFound(new { success = false, message = "Banner not found" });
            }

            _context.Banners.Remove(banner);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Deleted banner {BannerId} - {Title}", banner.Id, banner.Title);

            return Ok(new { success = true, message = "Banner deleted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting banner {BannerId}", id);
            return StatusCode(500, new { success = false, message = "Error deleting banner" });
        }
    }

    /// <summary>
    /// Upload banner image
    /// </summary>
    [HttpPost("upload")]
    public async Task<IActionResult> UploadImage([FromForm] IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { success = false, message = "No file uploaded" });
            }

            // Validate file type
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new { success = false, message = "Invalid file type. Only images are allowed." });
            }

            // Validate file size (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { success = false, message = "File size must be less than 5MB" });
            }

            // Create uploads directory if it doesn't exist
            var uploadsPath = Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads", "banners");
            Directory.CreateDirectory(uploadsPath);

            // Generate unique filename
            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadsPath, fileName);

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Generate URL
            var imageUrl = $"/uploads/banners/{fileName}";

            _logger.LogInformation("Uploaded banner image: {FileName}", fileName);

            return Ok(new
            {
                success = true,
                data = new
                {
                    fileName,
                    imageUrl,
                    size = file.Length
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading banner image");
            return StatusCode(500, new { success = false, message = "Error uploading image" });
        }
    }
}

// Request DTOs
public class CreateBannerRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? ActionUrl { get; set; }
    public string? ActionType { get; set; }
    public string? ActionText { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string? TargetAudience { get; set; }
}

public class UpdateBannerRequest
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? ActionUrl { get; set; }
    public string? ActionType { get; set; }
    public string? ActionText { get; set; }
    public int? DisplayOrder { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool? IsActive { get; set; }
    public string? TargetAudience { get; set; }
}

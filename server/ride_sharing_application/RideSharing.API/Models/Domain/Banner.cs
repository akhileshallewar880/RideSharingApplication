using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.Domain
{
    public class Banner
    {
        public Guid Id { get; set; }
        
        [Required]
        [MaxLength(200)]
        public string Title { get; set; }
        
        [MaxLength(1000)]
        public string? Description { get; set; }
        
        [MaxLength(500)]
        public string? ImageUrl { get; set; }
        
        [MaxLength(500)]
        public string? ActionUrl { get; set; }
        
        [MaxLength(50)]
        public string ActionType { get; set; } = "none"; // none, deeplink, external
        
        public int DisplayOrder { get; set; } = 0;
        
        [Required]
        public DateTime StartDate { get; set; }
        
        [Required]
        public DateTime EndDate { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        [MaxLength(50)]
        public string TargetAudience { get; set; } = "all"; // all, passenger, driver
        
        [MaxLength(100)]
        public string? ActionText { get; set; } // CTA button text
        
        public int ImpressionCount { get; set; } = 0;
        public int ClickCount { get; set; } = 0;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}

namespace RideSharing.API.Models.Domain
{
    public class Route
    {
        public Guid Id { get; set; }
        public Guid DriverId { get; set; }
        public string RouteName { get; set; }
        public string Origin { get; set; }
        public string Destination { get; set; }
        public decimal? DistanceKm { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation
        public Driver Driver { get; set; }
        public ICollection<RouteStop> RouteStops { get; set; }
        public ICollection<ScheduleTemplate> ScheduleTemplates { get; set; }
    }
}

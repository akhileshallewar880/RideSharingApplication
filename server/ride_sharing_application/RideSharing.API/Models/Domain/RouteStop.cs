namespace RideSharing.API.Models.Domain
{
    public class RouteStop
    {
        public Guid Id { get; set; }
        public Guid RouteId { get; set; }
        public int StopOrder { get; set; }
        public string StopName { get; set; }
        public decimal? StopLat { get; set; }
        public decimal? StopLng { get; set; }

        // Navigation
        public Route Route { get; set; }
    }
}

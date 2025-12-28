namespace RideSharing.API.Models.Domain
{
    public class ScheduleTemplate
    {
        public Guid Id { get; set; }
        public Guid RouteId { get; set; }
        public byte DaysOfWeek { get; set; }
        public TimeSpan DepartureTime { get; set; }
        public int Capacity { get; set; }
        public decimal PricePerSeat { get; set; }
        public bool IsAutoConfirm { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation
        public Route Route { get; set; }
        public ICollection<RideInstance> RideInstances { get; set; }
    }
}

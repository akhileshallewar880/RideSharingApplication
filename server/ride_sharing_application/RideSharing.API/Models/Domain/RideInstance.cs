namespace RideSharing.API.Models.Domain
{
    public class RideInstance
    {
        public Guid Id { get; set; }
        public Guid TemplateId { get; set; }
        public DateTime RideDate { get; set; }
        public DateTime DepartureDateTime { get; set; }
        public int TotalSeats { get; set; }
        public int RemainingSeats { get; set; }
        public string Status { get; set; }
        public DateTime? EstimatedArrival { get; set; }
        public DateTime? ActualDeparture { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation
        public ScheduleTemplate ScheduleTemplate { get; set; }
        public ICollection<Booking> Bookings { get; set; }
    }
}

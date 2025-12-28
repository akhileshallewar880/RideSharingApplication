namespace RideSharing.API.Models.DTO
{
    // Response DTOs
    public class DriverDashboardDto
    {
        public DriverInfoDto Driver { get; set; }
        public TodayStatsDto TodayStats { get; set; }
        public UpcomingRideDto? UpcomingRide { get; set; }
        public decimal PendingEarnings { get; set; }
        public decimal AvailableForWithdrawal { get; set; }
    }

    public class UpdateOnlineStatusDto
    {
        public bool IsOnline { get; set; }
    }

    public class OnlineStatusResponseDto
    {
        public bool IsOnline { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class EarningsSummaryDto
    {
        public SummaryDto Summary { get; set; }
        public BreakdownDto Breakdown { get; set; }
        public List<ChartDataDto> ChartData { get; set; }
    }

    public class PayoutHistoryDto
    {
        public List<PayoutDto> Payouts { get; set; }
        public PaginationDto Pagination { get; set; }
    }

    public class RequestPayoutDto
    {
        public decimal Amount { get; set; }
        public string Method { get; set; }
        public BankDetailsDto? BankDetails { get; set; }
    }

    public class PayoutRequestResponseDto
    {
        public Guid PayoutId { get; set; }
        public decimal Amount { get; set; }
        public string Status { get; set; }
        public DateTime EstimatedCompletionDate { get; set; }
        public DateTime RequestedAt { get; set; }
    }

    // Helper DTOs
    public class DriverInfoDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public decimal Rating { get; set; }
        public int TotalRides { get; set; }
        public bool IsOnline { get; set; }
    }

    public class TodayStatsDto
    {
        public int TotalRides { get; set; }
        public decimal TotalEarnings { get; set; }
        public decimal OnlineHours { get; set; }
    }

    public class UpcomingRideDto
    {
        public Guid RideId { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public string DepartureTime { get; set; }
        public int BookedSeats { get; set; }
        public int TotalSeats { get; set; }
    }

    public class SummaryDto
    {
        public decimal TotalEarnings { get; set; }
        public int TotalRides { get; set; }
        public decimal AverageEarningsPerRide { get; set; }
        public decimal TotalDistance { get; set; }
        public decimal OnlineHours { get; set; }
    }

    public class BreakdownDto
    {
        public decimal CashCollected { get; set; }
        public decimal OnlinePayments { get; set; }
        public decimal Commission { get; set; }
        public decimal NetEarnings { get; set; }
    }

    public class ChartDataDto
    {
        public DateTime Date { get; set; }
        public decimal Earnings { get; set; }
        public int Rides { get; set; }
    }

    public class PayoutDto
    {
        public Guid PayoutId { get; set; }
        public decimal Amount { get; set; }
        public string Status { get; set; }
        public string Method { get; set; }
        public string? TransactionId { get; set; }
        public DateTime RequestedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }

    public class BankDetailsDto
    {
        public string AccountNumber { get; set; }
        public string IfscCode { get; set; }
        public string AccountHolderName { get; set; }
    }
}

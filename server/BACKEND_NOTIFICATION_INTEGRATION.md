# Backend Integration Points for Push Notifications

## 🔔 When to Send Notifications

### 1. Booking Flow

```csharp
// When booking is confirmed
[HttpPost("book-ride")]
public async Task<IActionResult> BookRide([FromBody] BookRideRequest request)
{
    // ... create booking logic ...
    
    // Send confirmation notification
    if (!string.IsNullOrEmpty(user.FCMToken))
    {
        await _fcmService.SendBookingConfirmationAsync(user.FCMToken, booking);
    }
    
    return Ok(response);
}
```

### 2. Ride Lifecycle Events

```csharp
// In DriverRidesController - Start Trip
[HttpPost("{rideId}/start")]
public async Task<IActionResult> StartTrip(Guid rideId)
{
    // ... start trip logic ...
    
    // Notify all passengers
    var passengers = await GetRidePassengers(rideId);
    foreach (var passenger in passengers)
    {
        if (!string.IsNullOrEmpty(passenger.FCMToken))
        {
            await _fcmService.SendRideStartedAsync(
                passenger.FCMToken,
                rideId,
                passenger.BookingNumber
            );
        }
    }
    
    return Ok();
}

// In DriverRidesController - Complete Trip
[HttpPost("{rideId}/complete")]
public async Task<IActionResult> CompleteTrip(Guid rideId)
{
    // ... complete trip logic ...
    
    // Notify all passengers
    var passengers = await GetRidePassengers(rideId);
    foreach (var passenger in passengers)
    {
        if (!string.IsNullOrEmpty(passenger.FCMToken))
        {
            await _fcmService.SendRideCompletedAsync(
                passenger.FCMToken,
                passenger.BookingNumber,
                passenger.TotalFare
            );
        }
    }
    
    return Ok();
}
```

### 3. Cancellation Events

```csharp
[HttpPost("bookings/{bookingId}/cancel")]
public async Task<IActionResult> CancelBooking(
    Guid bookingId, 
    [FromBody] CancelBookingRequest request)
{
    // ... cancellation logic ...
    
    // Notify passenger
    var passenger = await GetBookingPassenger(bookingId);
    if (!string.IsNullOrEmpty(passenger.FCMToken))
    {
        await _fcmService.SendBookingCancelledAsync(
            passenger.FCMToken,
            booking.BookingNumber,
            request.Reason
        );
    }
    
    return Ok();
}
```

### 4. Driver Assignment

```csharp
// When driver accepts ride or is auto-assigned
public async Task AssignDriverToRide(Guid rideId, Guid driverId)
{
    // ... assignment logic ...
    
    // Notify all passengers
    var driver = await _context.Users.FindAsync(driverId);
    var passengers = await GetRidePassengers(rideId);
    
    foreach (var passenger in passengers)
    {
        if (!string.IsNullOrEmpty(passenger.FCMToken))
        {
            await _fcmService.SendDriverAssignedAsync(
                passenger.FCMToken,
                driver.Name,
                driver.VehicleNumber
            );
        }
    }
}
```

### 5. Payment Reminders

```csharp
// Background job or scheduled task
public async Task SendPaymentReminders()
{
    // Get bookings with pending payments
    var pendingPayments = await _context.Bookings
        .Where(b => b.PaymentStatus == "pending" && 
                    b.Status == "completed")
        .Include(b => b.Passenger)
        .ToListAsync();
    
    foreach (var booking in pendingPayments)
    {
        if (!string.IsNullOrEmpty(booking.Passenger.FCMToken))
        {
            await _fcmService.SendPaymentReminderAsync(
                booking.Passenger.FCMToken,
                booking.BookingNumber,
                booking.TotalAmount
            );
        }
    }
}
```

### 6. Promotional Campaigns

```csharp
[HttpPost("admin/send-promo")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> SendPromoCampaign([FromBody] PromoCampaignRequest request)
{
    // Get all active users
    var users = await _context.Users
        .Where(u => u.IsActive && u.FCMToken != null)
        .Select(u => u.FCMToken)
        .ToListAsync();
    
    // Send multicast notification
    await _fcmService.SendMulticastNotificationAsync(
        users,
        request.Title,
        request.Description,
        new Dictionary<string, string>
        {
            { "type", "promo_offer" },
            { "promoCode", request.PromoCode }
        }
    );
    
    return Ok(new { sent = users.Count });
}
```

---

## 🔧 Service Registration

Update `Program.cs` or `Startup.cs`:

```csharp
// Register FCM Notification Service
builder.Services.AddSingleton<FCMNotificationService>();

// Or with scoped lifetime if you need DbContext
builder.Services.AddScoped<FCMNotificationService>();
```

---

## 🗄️ Database Migration

Add FCM token column to Users table:

```sql
-- Add FCMToken column
ALTER TABLE Users
ADD FCMToken NVARCHAR(500) NULL;

-- Add index for faster lookups
CREATE INDEX IX_Users_FCMToken ON Users(FCMToken);

-- Optional: Add notification preferences column
ALTER TABLE Users
ADD NotificationPreferences NVARCHAR(MAX) NULL;
```

Or via Entity Framework migration:

```csharp
public partial class AddFCMToken : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "FCMToken",
            table: "Users",
            type: "nvarchar(500)",
            maxLength: 500,
            nullable: true);
        
        migrationBuilder.CreateIndex(
            name: "IX_Users_FCMToken",
            table: "Users",
            column: "FCMToken");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_Users_FCMToken",
            table: "Users");
        
        migrationBuilder.DropColumn(
            name: "FCMToken",
            table: "Users");
    }
}
```

---

## 📊 Logging & Monitoring

Add logging to track notification delivery:

```csharp
public class FCMNotificationService
{
    private readonly ILogger<FCMNotificationService> _logger;
    
    // After successful send
    _logger.LogInformation(
        "Notification sent successfully. Type: {Type}, User: {UserId}, MessageId: {MessageId}",
        type,
        userId,
        response
    );
    
    // On failure
    _logger.LogError(
        ex,
        "Failed to send notification. Type: {Type}, User: {UserId}",
        type,
        userId
    );
}
```

---

## 🧪 Testing Notifications

### Test from Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter FCM token from app logs
4. Send and verify received

### Test from Backend:
```csharp
[HttpPost("test-notification")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> TestNotification([FromQuery] Guid userId)
{
    var user = await _context.Users.FindAsync(userId);
    if (user?.FCMToken == null)
        return BadRequest("User has no FCM token");
    
    await _fcmService.SendBookingConfirmationAsync(
        user.FCMToken,
        new Booking { /* test data */ }
    );
    
    return Ok("Test notification sent");
}
```

---

## 🎯 Best Practices

1. **Always check for null FCM tokens**
   ```csharp
   if (!string.IsNullOrEmpty(user.FCMToken))
   {
       await _fcmService.SendNotificationAsync(...);
   }
   ```

2. **Handle failures gracefully**
   ```csharp
   try
   {
       await _fcmService.SendNotificationAsync(...);
   }
   catch (FirebaseMessagingException ex)
   {
       _logger.LogWarning(ex, "FCM token may be invalid");
       // Optionally clear invalid token
       user.FCMToken = null;
       await _context.SaveChangesAsync();
   }
   ```

3. **Use topics for broadcast messages**
   ```csharp
   // Instead of sending to 10,000 users individually
   await _fcmService.SendToTopicAsync(
       "all_passengers",
       "System Maintenance",
       "App will be down for 1 hour tonight"
   );
   ```

4. **Batch send for efficiency**
   ```csharp
   // Send to up to 500 tokens at once
   var tokens = users.Select(u => u.FCMToken).ToList();
   await _fcmService.SendMulticastNotificationAsync(
       tokens,
       title,
       body,
       data
   );
   ```

---

## 📞 Support

If notifications aren't working:
1. Check Firebase service account key is valid
2. Verify FCM token is not null/empty
3. Check Firebase Console for delivery stats
4. Review server logs for errors
5. Test with Firebase Console first

---

**Ready to implement!** 🚀 Just add these calls to your existing controllers.

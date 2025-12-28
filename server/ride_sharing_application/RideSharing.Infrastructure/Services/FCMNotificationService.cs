using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using RideSharing.Core.Models;

namespace RideSharing.Infrastructure.Services;

/// <summary>
/// Service for sending push notifications via Firebase Cloud Messaging
/// </summary>
public class FCMNotificationService
{
    private readonly ILogger<FCMNotificationService> _logger;
    private readonly FirebaseMessaging? _messaging;
    private readonly bool _isInitialized;
    
    public FCMNotificationService(ILogger<FCMNotificationService> logger, IConfiguration configuration)
    {
        _logger = logger;
        
        try
        {
            // Initialize Firebase Admin SDK
            // Place your serviceAccountKey.json in the API project root
            var serviceAccountPath = configuration["Firebase:ServiceAccountKeyPath"] ?? "serviceAccountKey.json";
            
            if (!File.Exists(serviceAccountPath))
            {
                _logger.LogWarning($"Firebase service account key not found at: {serviceAccountPath}. Notifications will not be sent.");
                _logger.LogWarning("To enable notifications, add serviceAccountKey.json to the API project root.");
                _isInitialized = false;
                return;
            }
            
            var credential = GoogleCredential.FromFile(serviceAccountPath);
            
            if (FirebaseApp.DefaultInstance == null)
            {
                FirebaseApp.Create(new AppOptions
                {
                    Credential = credential
                });
            }
            
            _messaging = FirebaseMessaging.DefaultInstance;
            _isInitialized = true;
            _logger.LogInformation("✅ Firebase Admin SDK initialized successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Firebase Admin SDK. Notifications will not be sent.");
            _isInitialized = false;
        }
    }

    /// <summary>
    /// Send booking confirmation notification
    /// </summary>
    public async Task SendBookingConfirmationAsync(string fcmToken, Booking booking)
    {
        if (!_isInitialized || _messaging == null)
        {
            _logger.LogWarning("Firebase not initialized. Skipping notification.");
            return;
        }
        
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Booking Confirmed! 🎉",
                    Body = $"Your ride on {booking.TravelDate:MMM dd} is confirmed. OTP: {booking.OTP}"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "booking_confirmed" },
                    { "bookingId", booking.Id.ToString() },
                    { "rideId", booking.RideId.ToString() },
                    { "otp", booking.OTP },
                    { "travelDate", booking.TravelDate.ToString("yyyy-MM-dd") }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Booking confirmation sent successfully. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send booking confirmation to token: {fcmToken}");
        }
    }

    /// <summary>
    /// Send ride started notification
    /// </summary>
    public async Task SendRideStartedAsync(string fcmToken, Guid rideId, string bookingNumber)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Your ride has started! 🚗",
                    Body = "Track your ride in real-time"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "ride_started" },
                    { "rideId", rideId.ToString() },
                    { "bookingNumber", bookingNumber }
                },
                Android = BuildAndroidConfig(priority: Priority.High),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Ride started notification sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send ride started notification");
        }
    }

    /// <summary>
    /// Send ride completed notification
    /// </summary>
    public async Task SendRideCompletedAsync(string fcmToken, string bookingNumber, decimal totalFare)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Ride Completed! ✅",
                    Body = $"Thank you for riding with us. Total fare: ₹{totalFare:F2}"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "ride_completed" },
                    { "bookingNumber", bookingNumber },
                    { "totalFare", totalFare.ToString() }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Ride completed notification sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send ride completed notification");
        }
    }

    /// <summary>
    /// Send booking cancellation notification
    /// </summary>
    public async Task SendBookingCancelledAsync(string fcmToken, string bookingNumber, string reason)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Booking Cancelled",
                    Body = $"Your booking has been cancelled. Reason: {reason}"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "booking_cancelled" },
                    { "bookingNumber", bookingNumber },
                    { "reason", reason }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Booking cancelled notification sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send booking cancelled notification");
        }
    }

    /// <summary>
    /// Send driver assigned notification
    /// </summary>
    public async Task SendDriverAssignedAsync(string fcmToken, string driverName, string vehicleNumber)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Driver Assigned 🚕",
                    Body = $"{driverName} will be your driver. Vehicle: {vehicleNumber}"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "driver_assigned" },
                    { "driverName", driverName },
                    { "vehicleNumber", vehicleNumber }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Driver assigned notification sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send driver assigned notification");
        }
    }

    /// <summary>
    /// Send payment reminder notification
    /// </summary>
    public async Task SendPaymentReminderAsync(string fcmToken, string bookingNumber, decimal amount)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = "Payment Due 💳",
                    Body = $"Complete payment of ₹{amount:F2} for your booking"
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "payment_due" },
                    { "bookingNumber", bookingNumber },
                    { "amount", amount.ToString() }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Payment reminder sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send payment reminder");
        }
    }

    /// <summary>
    /// Send promotional offer notification
    /// </summary>
    public async Task SendPromoOfferAsync(string fcmToken, string title, string description, string promoCode)
    {
        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = title,
                    Body = description
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "promo_offer" },
                    { "promoCode", promoCode }
                },
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Promo offer notification sent. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send promo offer notification");
        }
    }

    /// <summary>
    /// Send notification to multiple users (batch)
    /// </summary>
    public async Task SendMulticastNotificationAsync(
        List<string> fcmTokens, 
        string title, 
        string body, 
        Dictionary<string, string> data)
    {
        try
        {
            var message = new MulticastMessage
            {
                Tokens = fcmTokens,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data,
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendMulticastAsync(message);
            _logger.LogInformation($"Multicast notification sent. Success: {response.SuccessCount}, Failed: {response.FailureCount}");
            
            if (response.FailureCount > 0)
            {
                foreach (var error in response.Responses.Where(r => !r.IsSuccess))
                {
                    _logger.LogWarning($"Failed to send to token. Error: {error.Exception?.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send multicast notification");
        }
    }

    /// <summary>
    /// Subscribe user to topic
    /// </summary>
    public async Task SubscribeToTopicAsync(string fcmToken, string topic)
    {
        try
        {
            var response = await _messaging.SubscribeToTopicAsync(new[] { fcmToken }, topic);
            _logger.LogInformation($"Subscribed to topic {topic}. Success: {response.SuccessCount}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to subscribe to topic {topic}");
        }
    }

    /// <summary>
    /// Unsubscribe user from topic
    /// </summary>
    public async Task UnsubscribeFromTopicAsync(string fcmToken, string topic)
    {
        try
        {
            var response = await _messaging.UnsubscribeFromTopicAsync(new[] { fcmToken }, topic);
            _logger.LogInformation($"Unsubscribed from topic {topic}. Success: {response.SuccessCount}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to unsubscribe from topic {topic}");
        }
    }

    /// <summary>
    /// Send notification to topic (broadcast)
    /// </summary>
    public async Task SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null)
    {
        try
        {
            var message = new Message
            {
                Topic = topic,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>(),
                Android = BuildAndroidConfig(),
                Apns = BuildApnsConfig()
            };
            
            var response = await _messaging.SendAsync(message);
            _logger.LogInformation($"Topic notification sent to {topic}. MessageId: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send notification to topic {topic}");
        }
    }

    private AndroidConfig BuildAndroidConfig(Priority priority = Priority.Normal)
    {
        return new AndroidConfig
        {
            Priority = priority,
            Notification = new AndroidNotification
            {
                Icon = "ic_notification",
                Color = "#FFD700", // Primary yellow color
                Sound = "default",
                ChannelId = "allapalli_ride_channel"
            }
        };
    }

    private ApnsConfig BuildApnsConfig()
    {
        return new ApnsConfig
        {
            Aps = new Aps
            {
                Sound = "default",
                Badge = 1,
                ContentAvailable = true
            }
        };
    }
}

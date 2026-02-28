using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationRepository _notificationRepository;
        private readonly ILogger<NotificationsController> _logger;
        private readonly RideSharing.API.Services.Notification.FCMNotificationService _fcmService;

        public NotificationsController(
            INotificationRepository notificationRepository,
            ILogger<NotificationsController> logger,
            RideSharing.API.Services.Notification.FCMNotificationService fcmService)
        {
            _notificationRepository = notificationRepository;
            _logger = logger;
            _fcmService = fcmService;
        }

        /// <summary>
        /// Get user notifications with pagination
        /// </summary>
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto<NotificationsResponseDto>>> GetNotifications(
            [FromQuery] bool? unreadOnly = false,
            [FromQuery] int page = 1,
            [FromQuery] int limit = 20)
        {
            try
            {
                // Get user ID from JWT token claims
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    return Unauthorized(new ApiResponseDto<NotificationsResponseDto>
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "AUTH_REQUIRED",
                            Message = "User authentication required"
                        }
                    });
                }

                var notifications = await _notificationRepository.GetUserNotificationsAsync(
                    userId, unreadOnly, page, limit);
                
                var unreadCount = await _notificationRepository.GetUnreadCountAsync(userId);

                var response = new NotificationsResponseDto
                {
                    Notifications = notifications.Select(n => new NotificationDetailDto
                    {
                        Id = n.Id,
                        Type = n.Type,
                        Title = n.Title,
                        Message = n.Message,
                        Data = n.Data,
                        IsRead = n.IsRead,
                        CreatedAt = n.CreatedAt,
                        ReadAt = n.ReadAt
                    }).ToList(),
                    UnreadCount = unreadCount,
                    Pagination = new PaginationDto
                    {
                        CurrentPage = page,
                        ItemsPerPage = limit,
                        TotalItems = notifications.Count,
                        TotalPages = (int)Math.Ceiling((double)notifications.Count / limit)
                    }
                };

                return Ok(new ApiResponseDto<NotificationsResponseDto>
                {
                    Success = true,
                    Data = response
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting notifications");
                return StatusCode(500, new ApiResponseDto<NotificationsResponseDto>
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "An error occurred while retrieving notifications"
                    }
                });
            }
        }

        /// <summary>
        /// Create a new notification (called when notification is received on device)
        /// </summary>
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto<NotificationDetailDto>>> CreateNotification(
            [FromBody] CreateNotificationRequestDto request)
        {
            try
            {
                // Get user ID from JWT token claims
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    return Unauthorized(new ApiResponseDto<NotificationDetailDto>
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "AUTH_REQUIRED",
                            Message = "User authentication required"
                        }
                    });
                }

                var notification = new Models.Domain.Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Type = request.Type,
                    Title = request.Title,
                    Message = request.Message,
                    Data = request.Data,
                    IsRead = false
                };

                var createdNotification = await _notificationRepository.CreateNotificationAsync(notification);
                _logger.LogInformation($"Notification created for user {userId}: {notification.Type}");

                return Ok(new ApiResponseDto<NotificationDetailDto>
                {
                    Success = true,
                    Message = "Notification created successfully",
                    Data = new NotificationDetailDto
                    {
                        Id = createdNotification.Id,
                        Type = createdNotification.Type,
                        Title = createdNotification.Title,
                        Message = createdNotification.Message,
                        Data = createdNotification.Data,
                        IsRead = createdNotification.IsRead,
                        CreatedAt = createdNotification.CreatedAt,
                        ReadAt = createdNotification.ReadAt
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating notification");
                return StatusCode(500, new ApiResponseDto<NotificationDetailDto>
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "An error occurred while creating notification"
                    }
                });
            }
        }

        /// <summary>
        /// Mark a notification as read
        /// </summary>
        [HttpPut("{notificationId}/read")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto>> MarkAsRead(Guid notificationId)
        {
            try
            {
                var result = await _notificationRepository.MarkAsReadAsync(notificationId);

                if (!result)
                {
                    return NotFound(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "NOT_FOUND",
                            Message = "Notification not found"
                        }
                    });
                }

                return Ok(new ApiResponseDto
                {
                    Success = true,
                    Message = "Notification marked as read"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking notification as read");
                return StatusCode(500, new ApiResponseDto
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "An error occurred while updating notification"
                    }
                });
            }
        }

        /// <summary>
        /// Mark all notifications as read for the current user
        /// </summary>
        [HttpPut("read-all")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto>> MarkAllAsRead()
        {
            try
            {
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    return Unauthorized(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "AUTH_REQUIRED",
                            Message = "User authentication required"
                        }
                    });
                }

                var result = await _notificationRepository.MarkAllAsReadAsync(userId);

                return Ok(new ApiResponseDto
                {
                    Success = true,
                    Message = "All notifications marked as read"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking all notifications as read");
                return StatusCode(500, new ApiResponseDto
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "An error occurred while updating notifications"
                    }
                });
            }
        }
        
        /// <summary>
        /// Update user's FCM token for push notifications
        /// </summary>
        [HttpPost("fcm-token")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto>> UpdateFCMToken([FromBody] UpdateFCMTokenRequest request)
        {
            try
            {
                _logger.LogInformation("FCM token update request received");
                
                if (string.IsNullOrWhiteSpace(request.Token))
                {
                    _logger.LogWarning("Empty FCM token received");
                    return BadRequest(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "INVALID_TOKEN",
                            Message = "FCM token cannot be empty"
                        }
                    });
                }
                
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    _logger.LogWarning("No valid user ID found in token claims");
                    return Unauthorized(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "AUTH_REQUIRED",
                            Message = "User authentication required"
                        }
                    });
                }

                _logger.LogInformation($"Updating FCM token for user {userId}. Token: {request.Token.Substring(0, Math.Min(20, request.Token.Length))}...");
                await _notificationRepository.UpdateFCMTokenAsync(userId, request.Token);
                _logger.LogInformation($"✅ FCM token updated successfully for user {userId}");

                return Ok(new ApiResponseDto
                {
                    Success = true,
                    Message = "FCM token updated successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating FCM token");
                return StatusCode(500, new ApiResponseDto
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "Failed to update FCM token"
                    }
                });
            }
        }

        /// <summary>
        /// Delete user's FCM token (on logout)
        /// </summary>
        [HttpDelete("fcm-token")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto>> DeleteFCMToken()
        {
            try
            {
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    return Unauthorized(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "AUTH_REQUIRED",
                            Message = "User authentication required"
                        }
                    });
                }

                await _notificationRepository.UpdateFCMTokenAsync(userId, null);
                _logger.LogInformation($"FCM token deleted for user {userId}");

                return Ok(new ApiResponseDto
                {
                    Success = true,
                    Message = "FCM token deleted successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting FCM token");
                return StatusCode(500, new ApiResponseDto
                {
                    Success = false,
                    Error = new ErrorDto
                    {
                        Code = "SERVER_ERROR",
                        Message = "Failed to delete FCM token"
                    }
                });
            }
        }

        /// <summary>
        /// Send a test push notification to the current user's device (for debugging)
        /// </summary>
        [HttpPost("test-push")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto>> SendTestPush()
        {
            try
            {
                var userIdClaim = User.FindFirst("sub") ?? User.FindFirst("userId");
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out Guid userId))
                {
                    return Unauthorized(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto { Code = "AUTH_REQUIRED", Message = "User authentication required" }
                    });
                }

                // Retrieve the user's FCM token from the database
                var fcmToken = await _notificationRepository.GetFCMTokenAsync(userId);

                if (string.IsNullOrWhiteSpace(fcmToken))
                {
                    _logger.LogWarning($"❌ No FCM token found in DB for user {userId}. Token sync may have failed.");
                    return Ok(new ApiResponseDto
                    {
                        Success = false,
                        Error = new ErrorDto
                        {
                            Code = "NO_FCM_TOKEN",
                            Message = "No FCM token found for your account. Please re-login or refresh your token in the debug screen."
                        }
                    });
                }

                _logger.LogInformation($"📤 Sending test push to user {userId}, token: {fcmToken.Substring(0, Math.Min(20, fcmToken.Length))}...");

                await _fcmService.SendTestNotificationAsync(fcmToken);

                return Ok(new ApiResponseDto
                {
                    Success = true,
                    Message = $"✅ Test push sent! Token in DB: {fcmToken.Substring(0, Math.Min(20, fcmToken.Length))}..."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending test push notification");
                return StatusCode(500, new ApiResponseDto
                {
                    Success = false,
                    Error = new ErrorDto { Code = "SERVER_ERROR", Message = $"Failed to send test push: {ex.Message}" }
                });
            }
        }
    }
    
    /// <summary>
    /// Request model for updating FCM token
    /// </summary>
    public class UpdateFCMTokenRequest
    {
        public string Token { get; set; } = string.Empty;
    }
}
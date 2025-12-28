class NotificationStatistics {
  final int totalUsers;
  final int totalDrivers;
  final int totalPassengers;
  final int driversWithNotifications;
  final int passengersWithNotifications;
  final int totalWithNotifications;

  NotificationStatistics({
    required this.totalUsers,
    required this.totalDrivers,
    required this.totalPassengers,
    required this.driversWithNotifications,
    required this.passengersWithNotifications,
    required this.totalWithNotifications,
  });

  factory NotificationStatistics.fromJson(Map<String, dynamic> json) {
    return NotificationStatistics(
      totalUsers: json['totalUsers'] ?? 0,
      totalDrivers: json['totalDrivers'] ?? 0,
      totalPassengers: json['totalPassengers'] ?? 0,
      driversWithNotifications: json['driversWithNotifications'] ?? 0,
      passengersWithNotifications: json['passengersWithNotifications'] ?? 0,
      totalWithNotifications: json['totalWithNotifications'] ?? 0,
    );
  }
}

class SendNotificationRequest {
  final String title;
  final String? banner;
  final String description;
  final String targetAudience; // "all", "drivers", "passengers"

  SendNotificationRequest({
    required this.title,
    this.banner,
    required this.description,
    required this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'banner': banner,
      'description': description,
      'targetAudience': targetAudience,
    };
  }
}

class SendNotificationResponse {
  final bool success;
  final String message;
  final int sentCount;
  final String targetAudience;

  SendNotificationResponse({
    required this.success,
    required this.message,
    required this.sentCount,
    required this.targetAudience,
  });

  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) {
    return SendNotificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      sentCount: json['sentCount'] ?? 0,
      targetAudience: json['targetAudience'] ?? '',
    );
  }
}

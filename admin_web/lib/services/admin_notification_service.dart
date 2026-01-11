import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_notification_models.dart';
import '../core/services/admin_auth_service.dart';
import '../core/constants/app_constants.dart';

class AdminNotificationService {
  static String get baseUrl => '${AppConstants.baseUrl}/admin/notifications';
  final AdminAuthService _authService = AdminAuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<NotificationStatistics> getStatistics() async {
    try {
      final uri = Uri.parse('$baseUrl/statistics');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return NotificationStatistics.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load notification statistics');
    } catch (e) {
      throw Exception('Error fetching notification statistics: $e');
    }
  }

  Future<SendNotificationResponse> sendNotification(SendNotificationRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/send');
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SendNotificationResponse.fromJson(jsonData);
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send notification');
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_autocomplete_result.dart';
import '../models/place_details.dart';
import '../config/environment_config.dart';
import 'admin_auth_service.dart';

/// Service for Google Places API integration (via backend proxy)
class GooglePlacesService {
  final AdminAuthService _authService = AdminAuthService();
  
  static String get baseUrl => '${AdminEnvironmentConfig.apiBaseUrl}/googleplaces';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get place autocomplete suggestions via backend
  Future<List<PlaceAutocompleteResult>> getPlaceSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/autocomplete').replace(
        queryParameters: {
          'input': query,
          'components': 'country:in', // Restrict to India
        },
      );

      print('Fetching place suggestions from backend: $query');
      print('Backend URL: $uri');
      
      final response = await http.get(uri, headers: await _getHeaders());

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null && json['data']['suggestions'] != null) {
          final suggestions = json['data']['suggestions'] as List;
          print('Found ${suggestions.length} suggestions');
          return suggestions
              .map((p) => PlaceAutocompleteResult.fromJson(p))
              .toList();
        } else {
          print('❌ Backend response not successful: ${json['message']}');
          return [];
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token may be invalid');
        return [];
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching place suggestions: $e');
      return [];
    }
  }

  /// Get detailed information about a place via backend
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final uri = Uri.parse('$baseUrl/details/$placeId');

      print('Fetching place details from backend: $placeId');
      print('Backend URL: $uri');
      
      final response = await http.get(uri, headers: await _getHeaders());

      print('Details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          print('✅ Successfully fetched place details');
          return PlaceDetails.fromJson(json['data']);
        } else {
          print('❌ Backend response not successful: ${json['message']}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token may be invalid');
        return null;
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }

  /// Get headers with authentication token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

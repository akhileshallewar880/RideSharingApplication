import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../models/banner_models.dart';
import '../core/services/admin_auth_service.dart';
import '../core/config/environment_config.dart';

class AdminBannerService {
  static String get baseUrl => AdminEnvironmentConfig.bannersUrl;
  final AdminAuthService _authService = AdminAuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<BannerListResponse> getBanners({
    bool? isActive,
    String? targetAudience,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (targetAudience != null && targetAudience.isNotEmpty) {
        queryParams['targetAudience'] = targetAudience;
      }
      if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return BannerListResponse.fromJson(jsonData);
        }
      }

      throw Exception('Failed to load banners');
    } catch (e) {
      throw Exception('Error fetching banners: $e');
    }
  }

  Future<Banner> getBanner(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Banner.fromJson(jsonData['data']);
        }
      }

      throw Exception('Failed to load banner');
    } catch (e) {
      throw Exception('Error fetching banner: $e');
    }
  }

  Future<Banner> createBanner(CreateBannerRequest request) async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Banner.fromJson(jsonData['data']);
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create banner');
    } catch (e) {
      throw Exception('Error creating banner: $e');
    }
  }

  Future<Banner> updateBanner(String id, UpdateBannerRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Banner.fromJson(jsonData['data']);
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update banner');
    } catch (e) {
      throw Exception('Error updating banner: $e');
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri, headers: await _getHeaders());

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete banner');
      }
    } catch (e) {
      throw Exception('Error deleting banner: $e');
    }
  }

  Future<String> uploadImage(html.File file) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('$baseUrl/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Create multipart file from web File
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as List<int>;
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return jsonData['data']['imageUrl'];
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to upload image');
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}

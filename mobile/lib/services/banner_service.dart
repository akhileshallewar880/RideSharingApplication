import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner.dart';
import '../app/constants/app_constants.dart';

class BannerService {
  Future<List<Banner>> getActiveBanners() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/passenger/banners'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final bannerResponse = BannerListResponse.fromJson(jsonData);
          return bannerResponse.data;
        }
      }

      return [];
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }

  Future<void> recordImpression(String bannerId) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/passenger/banners/$bannerId/impression'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error recording impression: $e');
      // Fail silently - analytics shouldn't disrupt user experience
    }
  }

  Future<void> recordClick(String bannerId) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/passenger/banners/$bannerId/click'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error recording click: $e');
      // Fail silently - analytics shouldn't disrupt user experience
    }
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/api_response.dart';
import '../models/vehicle_models.dart';
import '../../app/constants/app_constants.dart';

/// Service for vehicle management operations
class VehicleService {
  final Dio _dio = DioClient.instance;
  final String _baseUrl = '${AppConstants.apiBaseUrl}/driver/vehicles';

  /// Get vehicle details
  Future<ApiResponse<VehicleDetails>> getVehicle() async {
    try {
      final response = await _dio.get(_baseUrl);

      return ApiResponse.fromJson(
        response.data,
        (json) => VehicleDetails.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update vehicle details
  Future<ApiResponse<VehicleDetails>> updateVehicle(
    UpdateVehicleRequest request,
  ) async {
    try {
      final response = await _dio.put(
        _baseUrl,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => VehicleDetails.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Upload vehicle document
  Future<ApiResponse<UploadVehicleDocumentResponse>> uploadDocument(
    File file,
    String documentType,
  ) async {
    try {
      final formData = DioClient.createFormData({
        'document': await MultipartFile.fromFile(file.path),
        'documentType': documentType,
      });

      final response = await _dio.post(
        '$_baseUrl/documents',
        data: formData,
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UploadVehicleDocumentResponse.fromJson(
            json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete vehicle document
  Future<ApiResponse<void>> deleteDocument(String documentType) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/documents/$documentType',
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      rethrow;
    }
  }
}

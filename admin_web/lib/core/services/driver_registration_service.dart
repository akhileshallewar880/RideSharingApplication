import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../constants/app_constants.dart';

class RegistrationCity {
  final String id;
  final String name;

  RegistrationCity({
    required this.id,
    required this.name,
  });

  factory RegistrationCity.fromJson(Map<String, dynamic> json) {
    return RegistrationCity(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
    );
  }
}

class RegistrationVehicleModel {
  final String id;
  final String name;
  final String brand;
  final String type;

  RegistrationVehicleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
  });

  String get displayName => '${brand.isNotEmpty ? '$brand ' : ''}$name';

  factory RegistrationVehicleModel.fromJson(Map<String, dynamic> json) {
    return RegistrationVehicleModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}

class DriverRegistrationPayload {
  final String name;
  final String? email;
  final String dateOfBirth; // YYYY-MM-DD
  final String phoneNumber; // 10 digits (no +91)
  final String currentCityId;
  final String currentCityName;
  final String vehicleModelId;
  final String vehicleNumber; // no spaces
  final String? emergencyContact; // +91xxxxxxxxxx

  DriverRegistrationPayload({
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.currentCityId,
    required this.currentCityName,
    required this.vehicleModelId,
    required this.vehicleNumber,
    required this.emergencyContact,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'userType': 'driver',
        'dateOfBirth': dateOfBirth,
        'phoneNumber': phoneNumber,
        'currentCityId': currentCityId,
        'currentCityName': currentCityName,
        'vehicleModelId': vehicleModelId,
        'vehicleNumber': vehicleNumber,
        if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
        if (emergencyContact != null && emergencyContact!.trim().isNotEmpty)
          'emergencyContact': emergencyContact!.trim(),
      };
}

class DriverRegistrationResult {
  final String accessToken;
  final String refreshToken;
  final String userId;

  DriverRegistrationResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory DriverRegistrationResult.fromAuthResponseData(Map<String, dynamic> data) {
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return DriverRegistrationResult(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
      userId: (user['id'] ?? user['userId'] ?? '').toString(),
    );
  }
}

class SendOtpResult {
  final String? otpId;
  final bool? isExistingUser;
  final String? expiresAt;

  SendOtpResult({
    required this.otpId,
    required this.isExistingUser,
    required this.expiresAt,
  });

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      otpId: json['otpId']?.toString(),
      isExistingUser: json['isExistingUser'] as bool?,
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}

class VerifyOtpResult {
  final bool isNewUser;
  final String? tempToken;
  final String? accessToken;
  final String? refreshToken;

  VerifyOtpResult({
    required this.isNewUser,
    required this.tempToken,
    required this.accessToken,
    required this.refreshToken,
  });

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      isNewUser: json['isNewUser'] == true,
      tempToken: json['tempToken']?.toString(),
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }
}

class DriverRegistrationService {
  final Dio _dio;

  DriverRegistrationService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: AppConstants.apiTimeout,
            receiveTimeout: AppConstants.apiTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

  Future<List<RegistrationCity>> getCities() async {
    final response = await _dio.get('/auth/cities');
    final data = response.data;
    final list = (data is Map ? data['data'] : null) as List?;
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => RegistrationCity.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<SendOtpResult> sendOtp({
    required String phoneNumber, // 10 digits
  }) async {
    final response = await _dio.post(
      '/auth/send-otp',
      data: {
        'phoneNumber': phoneNumber,
      },
    );

    final body = response.data;
    if (body is! Map) {
      throw Exception('Invalid response from server');
    }

    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Failed to send OTP');
    }

    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw Exception(body['message']?.toString() ?? 'Failed to send OTP');
    }

    return SendOtpResult.fromJson(data);
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber, // 10 digits
    required String otp, // 4 digits
    required String otpId,
  }) async {
    final response = await _dio.post(
      '/auth/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'otpId': otpId,
      },
    );

    final body = response.data;
    if (body is! Map) {
      throw Exception('Invalid response from server');
    }

    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'OTP verification failed');
    }

    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw Exception(body['message']?.toString() ?? 'OTP verification failed');
    }

    return VerifyOtpResult.fromJson(data);
  }

  Future<List<RegistrationVehicleModel>> getVehicleModels() async {
    final response = await _dio.get(
      '/vehicles/models',
      queryParameters: {'active': true},
    );
    final data = response.data;
    final vehicles = (data is Map ? (data['data']?['vehicles'] ?? data['data']?['Vehicles']) : null);
    final list = vehicles as List?;
    if (list == null) return [];

    final models = list
        .whereType<Map>()
        .map((e) => RegistrationVehicleModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    // Match driver app: exclude auto and bike
    return models.where((m) => m.type != 'auto' && m.type != 'bike').toList();
  }

  Future<DriverRegistrationResult> completeDriverRegistration({
    required DriverRegistrationPayload payload,
    String? tempToken,
  }) async {
    final response = await _dio.post(
      '/auth/complete-registration',
      data: payload.toJson(),
      options: Options(
        headers: {
          'X-Phone-Number': payload.phoneNumber,
          if (tempToken != null && tempToken.trim().isNotEmpty) 'Authorization': 'Bearer ${tempToken.trim()}',
        },
      ),
    );

    final body = response.data;
    if (body is! Map) {
      throw Exception('Invalid response from server');
    }

    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Registration failed');
    }

    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw Exception(body['message']?.toString() ?? 'Registration failed');
    }

    return DriverRegistrationResult.fromAuthResponseData(data);
  }

  Future<void> uploadDriverDocument({
    required String accessToken,
    required PlatformFile file,
    required String documentType, // license | rc
  }) async {
    final Dio driverDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    final multipartFile = await _toMultipartFile(file);

    final formData = FormData.fromMap({
      'documentType': documentType,
      'file': multipartFile,
    });

    final response = await driverDio.post(
      '/driver/vehicles/documents',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(body['message']?.toString() ?? 'Document upload failed');
    }
  }

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes as Uint8List,
        filename: file.name,
      );
    }

    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }

    throw Exception('Selected file has no data');
  }
}

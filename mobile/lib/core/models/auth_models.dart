/// Authentication request/response models
class SendOtpRequest {
  final String phoneNumber;

  SendOtpRequest({
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
  };
}

class SendOtpResponse {
  final String? phoneNumber;
  final String? expiresAt;
  final String? otpId;
  final bool? isExistingUser;

  SendOtpResponse({
    this.phoneNumber,
    this.expiresAt,
    this.otpId,
    this.isExistingUser,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      phoneNumber: json['phoneNumber'],
      expiresAt: json['expiresAt'],
      otpId: json['otpId'],
      isExistingUser: json['isExistingUser'],
    );
  }
}

class VerifyOtpRequest {
  final String phoneNumber;
  final String otp;
  final String otpId;

  VerifyOtpRequest({
    required this.phoneNumber,
    required this.otp,
    required this.otpId,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'otpId': otpId,
      };
}

class VerifyOtpResponse {
  final bool isNewUser;
  final String? accessToken;
  final String? refreshToken;
  final String? tempToken;
  final String? tokenType;
  final int? expiresIn;
  final UserData? user;
  final String? phoneNumber;

  VerifyOtpResponse({
    required this.isNewUser,
    this.accessToken,
    this.refreshToken,
    this.tempToken,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.phoneNumber,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 VerifyOtpResponse.fromJson - Full JSON: $json');
    print('🔍 isNewUser: ${json['isNewUser']}');
    print('🔍 accessToken present: ${json['accessToken'] != null}');
    print('🔍 user object: ${json['user']}');
    
    return VerifyOtpResponse(
      isNewUser: json['isNewUser'] ?? false,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tempToken: json['tempToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      phoneNumber: json['phoneNumber'],
    );
  }
}

class CompleteRegistrationRequest {
  final String name;
  final String? email;
  final String userType;
  final String? dateOfBirth;
  final String? emergencyContact;
  final String? currentCityId;
  final String? currentCityName;
  final String? vehicleModelId;
  final String? vehicleNumber;

  CompleteRegistrationRequest({
    required this.name,
    this.email,
    required this.userType,
    this.dateOfBirth,
    this.emergencyContact,
    this.currentCityId,
    this.currentCityName,
    this.vehicleModelId,
    this.vehicleNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'userType': userType,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (currentCityId != null) 'currentCityId': currentCityId,
        if (currentCityName != null) 'currentCityName': currentCityName,
        if (vehicleModelId != null) 'vehicleModelId': vehicleModelId,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserData user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 3600,
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

class UserData {
  final String userId;
  final String phoneNumber;
  final String name;
  final String? email;
  final String userType;

  UserData({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    this.email,
    required this.userType,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    print('🔍 UserData.fromJson - Full JSON: $json');
    print('🔍 userType value: ${json['userType']}');
    
    return UserData(
      userId: json['userId'] ?? json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      userType: json['userType'] ?? 'passenger',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'userType': userType,
      };
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 3600,
    );
  }
}

class LogoutRequest {
  final String refreshToken;

  LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

/// Driver registration request with vehicle and document details
class DriverRegistrationRequest {
  final String name;
  final String? email;
  final String dateOfBirth;
  final String phoneNumber;
  final String currentCityId;
  final String currentCityName;
  final String vehicleModelId;
  final String vehicleNumber;
  final String? emergencyContact;
  final String userType = 'driver';

  DriverRegistrationRequest({
    required this.name,
    this.email,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.currentCityId,
    required this.currentCityName,
    required this.vehicleModelId,
    required this.vehicleNumber,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'userType': userType,
        'dateOfBirth': dateOfBirth,
        'phoneNumber': phoneNumber,
        'currentCityId': currentCityId,
        'currentCityName': currentCityName,
        'vehicleModelId': vehicleModelId,
        'vehicleNumber': vehicleNumber,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (emergencyContact != null && emergencyContact!.isNotEmpty)
          'emergencyContact': emergencyContact,
      };
}

/// Driver document upload response
class DriverDocumentUploadResponse {
  final String documentType;
  final String documentUrl;
  final String uploadedAt;

  DriverDocumentUploadResponse({
    required this.documentType,
    required this.documentUrl,
    required this.uploadedAt,
  });

  factory DriverDocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    return DriverDocumentUploadResponse(
      documentType: json['documentType'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}

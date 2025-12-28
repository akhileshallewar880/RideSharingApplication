/// User profile model
class UserProfile {
  final String userId;
  final String phoneNumber;
  final String name;
  final String? email;
  final String? profilePicture;
  final String? dateOfBirth;
  final String? emergencyContact;
  final double rating;
  final int totalRides;
  final String createdAt;
  final String? verificationStatus; // For driver verification: 'pending', 'approved', 'rejected'

  UserProfile({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    this.email,
    this.profilePicture,
    this.dateOfBirth,
    this.emergencyContact,
    required this.rating,
    required this.totalRides,
    required this.createdAt,
    this.verificationStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      profilePicture: json['profilePicture'],
      dateOfBirth: json['dateOfBirth'],
      emergencyContact: json['emergencyContact'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      verificationStatus: json['verificationStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'profilePicture': profilePicture,
        'dateOfBirth': dateOfBirth,
        'emergencyContact': emergencyContact,
        'rating': rating,
        'totalRides': totalRides,
        'createdAt': createdAt,
        'verificationStatus': verificationStatus,
      };

  UserProfile copyWith({
    String? userId,
    String? phoneNumber,
    String? name,
    String? email,
    String? profilePicture,
    String? dateOfBirth,
    String? emergencyContact,
    double? rating,
    int? totalRides,
    String? createdAt,
    String? verificationStatus,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? email;
  final String? dateOfBirth;
  final String? emergencyContact;

  UpdateProfileRequest({
    this.name,
    this.email,
    this.dateOfBirth,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth;
    if (emergencyContact != null) map['emergencyContact'] = emergencyContact;
    return map;
  }
}

class UploadProfilePictureResponse {
  final String profilePictureUrl;

  UploadProfilePictureResponse({required this.profilePictureUrl});

  factory UploadProfilePictureResponse.fromJson(Map<String, dynamic> json) {
    return UploadProfilePictureResponse(
      profilePictureUrl: json['profilePictureUrl'] ?? '',
    );
  }
}

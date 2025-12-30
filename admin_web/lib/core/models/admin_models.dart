class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final List<String> permissions;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'admin',
      permissions: List<String>.from(json['permissions'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PendingDriver {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String vehicleNumber;
  final String vehicleType;
  final String city;
  final String? emergencyContact;
  final String verificationStatus;
  final String? rejectionReason;
  final DateTime registeredAt;
  final DriverDocuments documents;

  PendingDriver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.city,
    this.emergencyContact,
    required this.verificationStatus,
    this.rejectionReason,
    required this.registeredAt,
    required this.documents,
  });

  factory PendingDriver.fromJson(Map<String, dynamic> json) {
    return PendingDriver(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      city: json['city'] ?? '',
      emergencyContact: json['emergencyContact'],
      verificationStatus: json['verificationStatus'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toIso8601String()),
      documents: DriverDocuments.fromJson(json['documents'] ?? {}),
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}

class DriverDocuments {
  final DocumentInfo? drivingLicense;
  final DocumentInfo? rcBook;
  final DocumentInfo? profilePhoto;

  DriverDocuments({
    this.drivingLicense,
    this.rcBook,
    this.profilePhoto,
  });

  factory DriverDocuments.fromJson(Map<String, dynamic> json) {
    return DriverDocuments(
      drivingLicense: json['drivingLicense'] != null 
          ? DocumentInfo.fromJson(json['drivingLicense']) 
          : null,
      rcBook: json['rcBook'] != null 
          ? DocumentInfo.fromJson(json['rcBook']) 
          : null,
      profilePhoto: json['profilePhoto'] != null 
          ? DocumentInfo.fromJson(json['profilePhoto']) 
          : null,
    );
  }
}

class DocumentInfo {
  final String documentId;
  final String documentUrl;
  final String documentType;
  final DateTime uploadedAt;
  final String status;

  DocumentInfo({
    required this.documentId,
    required this.documentUrl,
    required this.documentType,
    required this.uploadedAt,
    required this.status,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      documentId: json['documentId'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      documentType: json['documentType'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'uploaded',
    );
  }
}

class RideInfo {
  final String id;
  final String rideNumber;
  final String status;
  final PassengerInfo passenger;
  final DriverInfo? driver;
  final LocationInfo pickup;
  final LocationInfo dropoff;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double estimatedFare;
  final double? actualFare;
  final double? distance;
  final int? duration;

  RideInfo({
    required this.id,
    required this.rideNumber,
    required this.status,
    required this.passenger,
    this.driver,
    required this.pickup,
    required this.dropoff,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    required this.estimatedFare,
    this.actualFare,
    this.distance,
    this.duration,
  });

  factory RideInfo.fromJson(Map<String, dynamic> json) {
    return RideInfo(
      id: json['id'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      status: json['status'] ?? '',
      passenger: PassengerInfo.fromJson(json['passenger'] ?? {}),
      driver: json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
      pickup: LocationInfo.fromJson(json['pickup'] ?? {}),
      dropoff: LocationInfo.fromJson(json['dropoff'] ?? {}),
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      estimatedFare: (json['estimatedFare'] ?? 0).toDouble(),
      actualFare: json['actualFare']?.toDouble(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
    );
  }
}

class PassengerInfo {
  final String id;
  final String name;
  final String phone;
  final double? rating;

  PassengerInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.rating,
  });

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      rating: json['rating']?.toDouble(),
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleType;
  final double? rating;
  final int totalRides;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
    this.rating,
    required this.totalRides,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      rating: json['rating']?.toDouble(),
      totalRides: json['totalRides'] ?? 0,
    );
  }
}

class LocationInfo {
  final String address;
  final double latitude;
  final double longitude;
  final String? landmark;

  LocationInfo({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      landmark: json['landmark'],
    );
  }
}

class DashboardStats {
  final int totalDrivers;
  final int activeDrivers;
  final int pendingVerifications;
  final int rejectedDrivers;
  final int totalRides;
  final int activeRides;
  final int completedRides;
  final int totalPassengers;
  final double totalRevenue;
  final double todayRevenue;
  final List<DailyStats> dailyStats;

  DashboardStats({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.pendingVerifications,
    required this.rejectedDrivers,
    required this.totalRides,
    required this.activeRides,
    required this.completedRides,
    required this.totalPassengers,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.dailyStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDrivers: json['totalDrivers'] ?? 0,
      activeDrivers: json['activeDrivers'] ?? 0,
      pendingVerifications: json['pendingVerifications'] ?? 0,
      rejectedDrivers: json['rejectedDrivers'] ?? 0,
      totalRides: json['totalRides'] ?? 0,
      activeRides: json['activeRides'] ?? 0,
      completedRides: json['completedRides'] ?? 0,
      totalPassengers: json['totalPassengers'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      dailyStats: (json['dailyStats'] as List<dynamic>?)
              ?.map((e) => DailyStats.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DailyStats {
  final DateTime date;
  final int rides;
  final double revenue;
  final int newDrivers;
  final int newPassengers;

  DailyStats({
    required this.date,
    required this.rides,
    required this.revenue,
    required this.newDrivers,
    required this.newPassengers,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date']),
      rides: json['rides'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      newDrivers: json['newDrivers'] ?? 0,
      newPassengers: json['newPassengers'] ?? 0,
    );
  }
}

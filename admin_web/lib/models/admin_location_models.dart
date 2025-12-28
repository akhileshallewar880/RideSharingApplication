class AdminLocation {
  final String id;
  final String name;
  final String state;
  final String district;
  final String? subLocation;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminLocation({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    this.subLocation,
    this.pincode,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminLocation.fromJson(Map<String, dynamic> json) {
    return AdminLocation(
      id: json['id'],
      name: json['name'],
      state: json['state'],
      district: json['district'],
      subLocation: json['subLocation'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'district': district,
      'subLocation': subLocation,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateLocationRequest {
  final String name;
  final String state;
  final String district;
  final String? subLocation;
  final String? pincode;
  final double latitude;
  final double longitude;

  CreateLocationRequest({
    required this.name,
    required this.state,
    required this.district,
    this.subLocation,
    this.pincode,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'state': state,
      'district': district,
      'subLocation': subLocation,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class UpdateLocationRequest {
  final String? name;
  final String? state;
  final String? district;
  final String? subLocation;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool? isActive;

  UpdateLocationRequest({
    this.name,
    this.state,
    this.district,
    this.subLocation,
    this.pincode,
    this.latitude,
    this.longitude,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (state != null) data['state'] = state;
    if (district != null) data['district'] = district;
    if (subLocation != null) data['subLocation'] = subLocation;
    if (pincode != null) data['pincode'] = pincode;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }
}

class LocationsResponse {
  final List<AdminLocation> locations;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  LocationsResponse({
    required this.locations,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory LocationsResponse.fromJson(Map<String, dynamic> json) {
    return LocationsResponse(
      locations: (json['locations'] as List)
          .map((loc) => AdminLocation.fromJson(loc))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class LocationStatistics {
  final int totalLocations;
  final int activeLocations;
  final int inactiveLocations;
  final int locationsWithCoordinates;
  final int locationsWithoutCoordinates;

  LocationStatistics({
    required this.totalLocations,
    required this.activeLocations,
    required this.inactiveLocations,
    required this.locationsWithCoordinates,
    required this.locationsWithoutCoordinates,
  });

  factory LocationStatistics.fromJson(Map<String, dynamic> json) {
    return LocationStatistics(
      totalLocations: json['totalLocations'],
      activeLocations: json['activeLocations'],
      inactiveLocations: json['inactiveLocations'],
      locationsWithCoordinates: json['locationsWithCoordinates'],
      locationsWithoutCoordinates: json['locationsWithoutCoordinates'],
    );
  }
}

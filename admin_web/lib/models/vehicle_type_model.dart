class VehicleType {
  final String id;
  final String name;
  final String displayName;
  final String? icon;
  final String? description;
  final double basePrice;
  final double pricePerKm;
  final double pricePerMinute;
  final int minSeats;
  final int maxSeats;
  final bool isActive;
  final int displayOrder;
  final String? category;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleType({
    required this.id,
    required this.name,
    required this.displayName,
    this.icon,
    this.description,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerMinute,
    required this.minSeats,
    required this.maxSeats,
    required this.isActive,
    required this.displayOrder,
    this.category,
    this.features = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      icon: json['icon'],
      description: json['description'],
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      pricePerKm: (json['pricePerKm'] ?? 0).toDouble(),
      pricePerMinute: (json['pricePerMinute'] ?? 0).toDouble(),
      minSeats: json['minSeats'] ?? 1,
      maxSeats: json['maxSeats'] ?? 4,
      isActive: json['isActive'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
      category: json['category'],
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'icon': icon,
      'description': description,
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'pricePerMinute': pricePerMinute,
      'minSeats': minSeats,
      'maxSeats': maxSeats,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'category': category,
      'features': features,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateVehicleTypeDto {
  final String name;
  final String displayName;
  final String? icon;
  final String? description;
  final double basePrice;
  final double pricePerKm;
  final double pricePerMinute;
  final int minSeats;
  final int maxSeats;
  final bool isActive;
  final int displayOrder;
  final String? category;
  final List<String> features;

  CreateVehicleTypeDto({
    required this.name,
    required this.displayName,
    this.icon,
    this.description,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerMinute,
    required this.minSeats,
    required this.maxSeats,
    this.isActive = true,
    this.displayOrder = 0,
    this.category,
    this.features = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'icon': icon,
      'description': description,
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'pricePerMinute': pricePerMinute,
      'minSeats': minSeats,
      'maxSeats': maxSeats,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'category': category,
      'features': features,
    };
  }
}

class UpdateVehicleTypeDto {
  final String? name;
  final String? displayName;
  final String? icon;
  final String? description;
  final double? basePrice;
  final double? pricePerKm;
  final double? pricePerMinute;
  final int? minSeats;
  final int? maxSeats;
  final bool? isActive;
  final int? displayOrder;
  final String? category;
  final List<String>? features;

  UpdateVehicleTypeDto({
    this.name,
    this.displayName,
    this.icon,
    this.description,
    this.basePrice,
    this.pricePerKm,
    this.pricePerMinute,
    this.minSeats,
    this.maxSeats,
    this.isActive,
    this.displayOrder,
    this.category,
    this.features,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (displayName != null) data['displayName'] = displayName;
    if (icon != null) data['icon'] = icon;
    if (description != null) data['description'] = description;
    if (basePrice != null) data['basePrice'] = basePrice;
    if (pricePerKm != null) data['pricePerKm'] = pricePerKm;
    if (pricePerMinute != null) data['pricePerMinute'] = pricePerMinute;
    if (minSeats != null) data['minSeats'] = minSeats;
    if (maxSeats != null) data['maxSeats'] = maxSeats;
    if (isActive != null) data['isActive'] = isActive;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (category != null) data['category'] = category;
    if (features != null) data['features'] = features;
    
    return data;
  }
}

class VehicleTypesResponse {
  final List<VehicleType> vehicleTypes;
  final int total;

  VehicleTypesResponse({
    required this.vehicleTypes,
    required this.total,
  });

  factory VehicleTypesResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTypesResponse(
      vehicleTypes: (json['vehicleTypes'] as List?)
              ?.map((item) => VehicleType.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

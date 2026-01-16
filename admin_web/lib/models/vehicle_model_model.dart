class VehicleModel {
  final String id;
  final String name;
  final String brand;
  final String type; // car, suv, van, bus
  final int seatingCapacity;
  final String? seatingLayout;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final List<String> features;

  VehicleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.seatingCapacity,
    this.seatingLayout,
    this.imageUrl,
    this.description,
    required this.isActive,
    this.features = const [],
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? '',
      seatingCapacity: json['seatingCapacity'] ?? 1,
      seatingLayout: json['seatingLayout'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      features: json['features'] != null 
          ? List<String>.from(json['features']) 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'type': type,
      'seatingCapacity': seatingCapacity,
      'seatingLayout': seatingLayout,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'features': features,
    };
  }
}

class CreateVehicleModelDto {
  final String name;
  final String brand;
  final String type;
  final int seatingCapacity;
  final String? seatingLayout;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final List<String> features;

  CreateVehicleModelDto({
    required this.name,
    required this.brand,
    required this.type,
    required this.seatingCapacity,
    this.seatingLayout,
    this.imageUrl,
    this.description,
    this.isActive = true,
    this.features = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'type': type,
      'seatingCapacity': seatingCapacity,
      'seatingLayout': seatingLayout,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'features': features,
    };
  }
}

class UpdateVehicleModelDto {
  final String name;
  final String brand;
  final String type;
  final int seatingCapacity;
  final String? seatingLayout;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final List<String> features;

  UpdateVehicleModelDto({
    required this.name,
    required this.brand,
    required this.type,
    required this.seatingCapacity,
    this.seatingLayout,
    this.imageUrl,
    this.description,
    required this.isActive,
    this.features = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'type': type,
      'seatingCapacity': seatingCapacity,
      'seatingLayout': seatingLayout,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'features': features,
    };
  }
}

class VehicleModelsResponse {
  final List<VehicleModel> vehicles;
  final int total;

  VehicleModelsResponse({
    required this.vehicles,
    required this.total,
  });

  factory VehicleModelsResponse.fromJson(Map<String, dynamic> json) {
    return VehicleModelsResponse(
      vehicles: (json['vehicles'] as List?)
              ?.map((v) => VehicleModel.fromJson(v))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

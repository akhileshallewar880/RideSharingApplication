/// Vehicle management models

/// Vehicle model for driver's vehicle selection (from catalog)
class VehicleModel {
  final String id;
  final String name;
  final String brand;
  final String type; // 'car', 'suv', 'van', 'bus'
  final int seatingCapacity;
  final String? imageUrl;
  final bool isActive;
  final String? description;
  final List<String>? features;

  VehicleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.seatingCapacity,
    this.imageUrl,
    this.isActive = true,
    this.description,
    this.features,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? 'car',
      seatingCapacity: json['seatingCapacity'] ?? 4,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      description: json['description'],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'type': type,
        'seatingCapacity': seatingCapacity,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isActive': isActive,
        if (description != null) 'description': description,
        if (features != null) 'features': features,
      };

  String get displayName => '$brand $name';

  String get typeLabel {
    switch (type) {
      case 'car':
        return 'Car';
      case 'suv':
        return 'SUV';
      case 'van':
        return 'Van';
      case 'bus':
        return 'Bus';
      default:
        return 'Vehicle';
    }
  }
}

/// Location with intermediate stops support
class LocationWithStops {
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? name;

  LocationWithStops({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.name,
  });

  factory LocationWithStops.fromJson(Map<String, dynamic> json) {
    return LocationWithStops(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      placeId: json['placeId'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (placeId != null) 'placeId': placeId,
        if (name != null) 'name': name,
      };
}

/// Vehicle models list response
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

/// Popular vehicle models (fallback/default list)
class PopularVehicleModels {
  static List<VehicleModel> get cars => [
        VehicleModel(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Ertiga',
          brand: 'Maruti Suzuki',
          type: 'car',
          seatingCapacity: 7,
          description: 'Spacious and fuel-efficient MPV',
          features: ['AC', '7 Seater', 'Luggage Space'],
        ),
        VehicleModel(
          id: '22222222-2222-2222-2222-222222222222',
          name: 'Dzire',
          brand: 'Maruti Suzuki',
          type: 'car',
          seatingCapacity: 4,
          description: 'Compact sedan, perfect for city rides',
          features: ['AC', '4 Seater', 'Fuel Efficient'],
        ),
        VehicleModel(
          id: '33333333-3333-3333-3333-333333333333',
          name: 'Etios',
          brand: 'Toyota',
          type: 'car',
          seatingCapacity: 4,
          description: 'Reliable sedan for comfortable travel',
          features: ['AC', '4 Seater', 'Comfortable'],
        ),
        VehicleModel(
          id: '44444444-4444-4444-4444-444444444444',
          name: 'City',
          brand: 'Honda',
          type: 'car',
          seatingCapacity: 4,
          description: 'Premium sedan for comfortable rides',
          features: ['AC', '4 Seater', 'Premium'],
        ),
      ];

  static List<VehicleModel> get suvs => [
        VehicleModel(
          id: '55555555-5555-5555-5555-555555555555',
          name: 'Innova Crysta',
          brand: 'Toyota',
          type: 'suv',
          seatingCapacity: 7,
          description: 'Premium MPV for long journeys',
          features: ['AC', '7-8 Seater', 'Spacious', 'Premium'],
        ),
        VehicleModel(
          id: '66666666-6666-6666-6666-666666666666',
          name: 'Scorpio',
          brand: 'Mahindra',
          type: 'suv',
          seatingCapacity: 7,
          description: 'Powerful SUV for all terrains',
          features: ['AC', '7 Seater', 'Rugged', '4WD'],
        ),
        VehicleModel(
          id: '77777777-7777-7777-7777-777777777777',
          name: 'Xylo',
          brand: 'Mahindra',
          type: 'suv',
          seatingCapacity: 8,
          description: 'Spacious MUV for group travel',
          features: ['AC', '8 Seater', 'Spacious'],
        ),
        VehicleModel(
          id: '88888888-8888-8888-8888-888888888888',
          name: 'Ertiga',
          brand: 'Maruti Suzuki',
          type: 'suv',
          seatingCapacity: 7,
          description: 'Fuel-efficient family SUV',
          features: ['AC', '7 Seater', 'Economical'],
        ),
      ];

  static List<VehicleModel> get vans => [
        VehicleModel(
          id: '99999999-9999-9999-9999-999999999999',
          name: 'Traveller',
          brand: 'Force',
          type: 'van',
          seatingCapacity: 13,
          description: 'Mini bus for group tours',
          features: ['AC', '13 Seater', 'Luggage Space'],
        ),
        VehicleModel(
          id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          name: 'Winger',
          brand: 'Tata',
          type: 'van',
          seatingCapacity: 15,
          description: 'Comfortable van for medium groups',
          features: ['AC', '12-15 Seater', 'Comfortable'],
        ),
      ];

  static List<VehicleModel> get buses => [
        VehicleModel(
          id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          name: 'Starbus',
          brand: 'Tata',
          type: 'bus',
          seatingCapacity: 32,
          description: 'Standard bus for large groups',
          features: ['AC', '32 Seater', 'Luggage Cabin'],
        ),
        VehicleModel(
          id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
          name: 'Viking',
          brand: 'Ashok Leyland',
          type: 'bus',
          seatingCapacity: 40,
          description: 'Large capacity bus',
          features: ['AC', '40 Seater', 'Spacious'],
        ),
      ];

  static List<VehicleModel> get all => [
        ...cars,
        ...suvs,
        ...vans,
        ...buses,
      ];

  static List<VehicleModel> getByType(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return cars;
      case 'suv':
        return suvs;
      case 'van':
        return vans;
      case 'bus':
        return buses;
      default:
        return all;
    }
  }
}

class VehicleDetails {
  final String? vehicleId;
  final String vehicleType;
  final String manufacturer;
  final String model;
  final String registrationNumber;
  final int capacity;
  final String color;
  final String? insuranceExpiry;
  final String? permitExpiry;
  final String? fitnessExpiry;
  final String? registrationDocument;
  final String? insuranceDocument;
  final String? permitDocument;
  final String? fitnessDocument;
  final String verificationStatus;
  final String? verifiedAt;

  VehicleDetails({
    this.vehicleId,
    required this.vehicleType,
    required this.manufacturer,
    required this.model,
    required this.registrationNumber,
    required this.capacity,
    required this.color,
    this.insuranceExpiry,
    this.permitExpiry,
    this.fitnessExpiry,
    this.registrationDocument,
    this.insuranceDocument,
    this.permitDocument,
    this.fitnessDocument,
    required this.verificationStatus,
    this.verifiedAt,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      vehicleId: json['vehicleId'],
      vehicleType: json['vehicleType'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      capacity: json['capacity'] ?? 0,
      color: json['color'] ?? '',
      insuranceExpiry: json['insuranceExpiry'],
      permitExpiry: json['permitExpiry'],
      fitnessExpiry: json['fitnessExpiry'],
      registrationDocument: json['registrationDocument'],
      insuranceDocument: json['insuranceDocument'],
      permitDocument: json['permitDocument'],
      fitnessDocument: json['fitnessDocument'],
      verificationStatus: json['verificationStatus'] ?? '',
      verifiedAt: json['verifiedAt'],
    );
  }
}

class UpdateVehicleRequest {
  final String? vehicleType;
  final String? manufacturer;
  final String? model;
  final String? registrationNumber;
  final int? capacity;
  final String? color;
  final String? insuranceExpiry;
  final String? permitExpiry;
  final String? fitnessExpiry;

  UpdateVehicleRequest({
    this.vehicleType,
    this.manufacturer,
    this.model,
    this.registrationNumber,
    this.capacity,
    this.color,
    this.insuranceExpiry,
    this.permitExpiry,
    this.fitnessExpiry,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (vehicleType != null) data['vehicleType'] = vehicleType;
    if (manufacturer != null) data['manufacturer'] = manufacturer;
    if (model != null) data['model'] = model;
    if (registrationNumber != null) data['registrationNumber'] = registrationNumber;
    if (capacity != null) data['capacity'] = capacity;
    if (color != null) data['color'] = color;
    if (insuranceExpiry != null) data['insuranceExpiry'] = insuranceExpiry;
    if (permitExpiry != null) data['permitExpiry'] = permitExpiry;
    if (fitnessExpiry != null) data['fitnessExpiry'] = fitnessExpiry;
    return data;
  }
}

class UploadVehicleDocumentResponse {
  final String documentType;
  final String documentUrl;
  final String uploadedAt;

  UploadVehicleDocumentResponse({
    required this.documentType,
    required this.documentUrl,
    required this.uploadedAt,
  });

  factory UploadVehicleDocumentResponse.fromJson(Map<String, dynamic> json) {
    return UploadVehicleDocumentResponse(
      documentType: json['documentType'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}

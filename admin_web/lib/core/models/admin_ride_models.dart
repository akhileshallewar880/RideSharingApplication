/// Admin Ride Management Models

import '../utils/datetime_parser.dart';

class AdminDriverInfo {
  final String driverId;
  final String name;
  final String phone;
  final String? licenseNumber;
  final String? vehicleNumber;
  final String? vehicleModel;
  final int vehicleSeats;
  final bool isAvailable;

  AdminDriverInfo({
    required this.driverId,
    required this.name,
    required this.phone,
    this.licenseNumber,
    this.vehicleNumber,
    this.vehicleModel,
    required this.vehicleSeats,
    required this.isAvailable,
  });

  factory AdminDriverInfo.fromJson(Map<String, dynamic> json) {
    return AdminDriverInfo(
      driverId: json['driverId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['licenseNumber'],
      vehicleNumber: json['vehicleNumber'],
      vehicleModel: json['vehicleModel'],
      vehicleSeats: json['vehicleSeats'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}

class AdminRideInfo {
  final String rideId;
  final String rideNumber;
  final String driverId;
  final String driverName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime travelDate;
  final String departureTime;
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String status;
  final String? vehicleNumber;
  final String? vehicleModel;
  final DateTime createdAt;
  final String? adminNotes;
  final String? passengerOtp;
  final List<dynamic>? segmentPrices;
  final List<String>? intermediateStops;
  final double? distance; // in kilometers
  final int? duration; // in minutes

  AdminRideInfo({
    required this.rideId,
    required this.rideNumber,
    required this.driverId,
    required this.driverName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.departureTime,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.status,
    this.vehicleNumber,
    this.vehicleModel,
    required this.createdAt,
    this.adminNotes,
    this.passengerOtp,
    this.segmentPrices,
    this.intermediateStops,
    this.distance,
    this.duration,
  });

  factory AdminRideInfo.fromJson(Map<String, dynamic> json) {
    return AdminRideInfo(
      rideId: json['rideId'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      travelDate: DateTimeParser.parse(json['travelDate']),
      departureTime: json['departureTime'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      bookedSeats: json['bookedSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      vehicleNumber: json['vehicleNumber'],
      vehicleModel: json['vehicleModel'],
      createdAt: DateTimeParser.parse(json['createdAt']),
      adminNotes: json['adminNotes'],
      passengerOtp: json['passengerOtp'],
      segmentPrices: json['segmentPrices'],
      intermediateStops: json['intermediateStops'] != null
          ? List<String>.from(json['intermediateStops'])
          : null,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      duration: json['duration'] as int?,
    );
  }
}

class AdminScheduleRideRequest {
  final String driverId;
  final LocationDto pickupLocation;
  final LocationDto dropoffLocation;
  final List<String>? intermediateStops;
  final List<Map<String, dynamic>>? intermediateStopLocations;  // Full location data with coordinates
  final DateTime travelDate;
  final String departureTime;
  final int totalSeats;
  final double pricePerSeat;
  final String? vehicleModelId;
  final bool scheduleReturnTrip;
  final String? returnDepartureTime;
  final List<SegmentPrice>? segmentPrices;
  final String? adminNotes;

  AdminScheduleRideRequest({
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.intermediateStops,
    this.intermediateStopLocations,
    required this.travelDate,
    required this.departureTime,
    required this.totalSeats,
    required this.pricePerSeat,
    this.vehicleModelId,
    this.scheduleReturnTrip = false,
    this.returnDepartureTime,
    this.segmentPrices,
    this.adminNotes,
  });

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'pickupLocation': pickupLocation.toJson(),
        'dropoffLocation': dropoffLocation.toJson(),
        if (intermediateStops != null && intermediateStops!.isNotEmpty)
          'intermediateStops': intermediateStops,
        if (intermediateStopLocations != null && intermediateStopLocations!.isNotEmpty)
          'intermediateStopLocations': intermediateStopLocations,
        'travelDate': travelDate.toIso8601String(),
        'departureTime': departureTime,
        'totalSeats': totalSeats,
        'pricePerSeat': pricePerSeat,
        if (vehicleModelId != null) 'vehicleModelId': vehicleModelId,
        'scheduleReturnTrip': scheduleReturnTrip,
        if (returnDepartureTime != null) 'returnDepartureTime': returnDepartureTime,
        if (segmentPrices != null && segmentPrices!.isNotEmpty)
          'segmentPrices': segmentPrices!.map((s) => s.toJson()).toList(),
        if (adminNotes != null) 'adminNotes': adminNotes,
      };
}

class AdminUpdateRideRequest {
  final DateTime? travelDate;
  final String? departureTime;
  final int? totalSeats;
  final double? pricePerSeat;
  final LocationDto? pickupLocation;
  final LocationDto? dropoffLocation;
  final List<String>? intermediateStops;
  final List<SegmentPrice>? segmentPrices;
  final String? adminNotes;

  AdminUpdateRideRequest({
    this.travelDate,
    this.departureTime,
    this.totalSeats,
    this.pricePerSeat,
    this.pickupLocation,
    this.dropoffLocation,
    this.intermediateStops,
    this.segmentPrices,
    this.adminNotes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (travelDate != null) json['travelDate'] = travelDate!.toIso8601String();
    if (departureTime != null) json['departureTime'] = departureTime;
    if (totalSeats != null) json['totalSeats'] = totalSeats;
    if (pricePerSeat != null) json['pricePerSeat'] = pricePerSeat;
    if (pickupLocation != null) json['pickupLocation'] = pickupLocation!.toJson();
    if (dropoffLocation != null) json['dropoffLocation'] = dropoffLocation!.toJson();
    if (intermediateStops != null) json['intermediateStops'] = intermediateStops;
    if (segmentPrices != null) json['segmentPrices'] = segmentPrices!.map((s) => s.toJson()).toList();
    if (adminNotes != null) json['adminNotes'] = adminNotes;
    return json;
  }
}

class AdminScheduleRideResponse {
  final String rideId;
  final String rideNumber;
  final String driverId;
  final String driverName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime travelDate;
  final String departureTime;
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String status;
  final DateTime createdAt;
  final String? returnRideId;
  final String? returnRideNumber;
  final String? adminNotes;

  AdminScheduleRideResponse({
    required this.rideId,
    required this.rideNumber,
    required this.driverId,
    required this.driverName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.departureTime,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.status,
    required this.createdAt,
    this.returnRideId,
    this.returnRideNumber,
    this.adminNotes,
  });

  factory AdminScheduleRideResponse.fromJson(Map<String, dynamic> json) {
    return AdminScheduleRideResponse(
      rideId: json['rideId'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      travelDate: DateTimeParser.parse(json['travelDate']),
      departureTime: json['departureTime'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      bookedSeats: json['bookedSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTimeParser.parse(json['createdAt']),
      returnRideId: json['returnRideId'],
      returnRideNumber: json['returnRideNumber'],
      adminNotes: json['adminNotes'],
    );
  }
}

// Reuse from driver models
class LocationDto {
  final String address;
  final double latitude;
  final double longitude;

  LocationDto({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class SegmentPrice {
  final String fromLocation;
  final String toLocation;
  final double price;
  final double suggestedPrice;
  final bool isOverridden;

  SegmentPrice({
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.suggestedPrice,
    this.isOverridden = false,
  });

  Map<String, dynamic> toJson() => {
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'price': price,
        'suggestedPrice': suggestedPrice,
        'isOverridden': isOverridden,
      };

  factory SegmentPrice.fromJson(Map<String, dynamic> json) {
    return SegmentPrice(
      fromLocation: json['fromLocation'] ?? '',
      toLocation: json['toLocation'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      suggestedPrice: (json['suggestedPrice'] ?? 0.0).toDouble(),
      isOverridden: json['isOverridden'] ?? false,
    );
  }

  SegmentPrice copyWith({
    String? fromLocation,
    String? toLocation,
    double? price,
    double? suggestedPrice,
    bool? isOverridden,
  }) {
    return SegmentPrice(
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      price: price ?? this.price,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      isOverridden: isOverridden ?? this.isOverridden,
    );
  }
}

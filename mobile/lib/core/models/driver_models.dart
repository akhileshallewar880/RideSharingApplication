/// Driver ride management models

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
}

class ScheduleRideRequest {
  final String pickupLocationId;
  final String dropoffLocationId;
  final LocationDto pickupLocation;
  final LocationDto dropoffLocation;
  final List<String>? intermediateStops; // stop names sent as "intermediateStops" (what server expects)
  final List<String>? intermediateStopsIds; // stop IDs sent alongside names
  final String travelDate; // ISO 8601 date
  final String departureTime; // HH:mm format
  final int totalSeats;
  final double pricePerSeat;
  final String? vehicleModelId; // New: reference to vehicle model
  final String? vehicleType; // Kept for backward compatibility
  final bool scheduleReturnTrip; // New: flag for return trip
  final String? returnDepartureTime; // New: return trip time (ISO 8601)
  final String? linkedReturnRideId; // New: reference to paired return ride
  final List<SegmentPrice>? segmentPrices; // New: pricing for route segments

  ScheduleRideRequest({
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.intermediateStops,
    this.intermediateStopsIds,
    required this.travelDate,
    required this.departureTime,
    required this.totalSeats,
    required this.pricePerSeat,
    this.vehicleModelId,
    this.vehicleType,
    this.scheduleReturnTrip = false,
    this.returnDepartureTime,
    this.linkedReturnRideId,
    this.segmentPrices,
  });

  Map<String, dynamic> toJson() => {
        'pickupLocationId': pickupLocationId,
        'dropoffLocationId': dropoffLocationId,
        'pickupLocation': pickupLocation.toJson(),
        'dropoffLocation': dropoffLocation.toJson(),
        // "intermediateStops" is what the server's ScheduleRideRequestDto.IntermediateStops maps to
        if (intermediateStops != null && intermediateStops!.isNotEmpty)
          'intermediateStops': intermediateStops,
        if (intermediateStopsIds != null && intermediateStopsIds!.isNotEmpty)
          'intermediateStopsIds': intermediateStopsIds,
        'travelDate': travelDate,
        'departureTime': departureTime,
        'totalSeats': totalSeats,
        'pricePerSeat': pricePerSeat,
        if (vehicleModelId != null) 'vehicleModelId': vehicleModelId,
        if (vehicleType != null) 'vehicleType': vehicleType,
        'scheduleReturnTrip': scheduleReturnTrip,
        if (returnDepartureTime != null)
          'returnDepartureTime': returnDepartureTime,
        if (linkedReturnRideId != null)
          'linkedReturnRideId': linkedReturnRideId,
        if (segmentPrices != null && segmentPrices!.isNotEmpty)
          'segmentPrices': segmentPrices!.map((s) => s.toJson()).toList(),
      };
}

class ScheduleRideResponse {
  final String rideId;
  final String rideNumber;
  final String departureTime;
  final String status;
  final String createdAt;
  final String? returnRideId; // New: ID of paired return ride if created
  final String? returnRideNumber; // New: number of return ride

  ScheduleRideResponse({
    required this.rideId,
    required this.rideNumber,
    required this.departureTime,
    required this.status,
    required this.createdAt,
    this.returnRideId,
    this.returnRideNumber,
  });

  factory ScheduleRideResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleRideResponse(
      rideId: json['rideId'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      departureTime: json['departureTime'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      returnRideId: json['returnRideId'],
      returnRideNumber: json['returnRideNumber'],
    );
  }
}

class DriverRide {
  final String rideId;
  final String rideNumber;
  final String pickupLocationId;
  final String dropoffLocationId;
  final String pickupLocation;
  final String dropoffLocation;
  final List<String>? intermediateStopsIds;
  final List<String>? intermediateStops; // New: intermediate towns
  final String departureTime;
  final String date; // Travel date
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
  final double pricePerSeat;
  final double estimatedEarnings;
  final String status;
  final String? vehicleModelId; // New: reference to vehicle model
  final String? linkedReturnRideId; // New: paired return ride
  final List<SegmentPrice>? segmentPrices; // New: segment-based pricing
  final bool isReturnTrip; // New: indicates if this is a return trip
  final double? distance; // in kilometers
  final int? duration; // in minutes

  DriverRide({
    required this.rideId,
    required this.rideNumber,
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.intermediateStopsIds,
    this.intermediateStops,
    required this.departureTime,
    required this.date,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.estimatedEarnings,
    required this.status,
    this.vehicleModelId,
    this.linkedReturnRideId,
    this.segmentPrices,
    this.isReturnTrip = false,
    this.distance,
    this.duration,
  });

  factory DriverRide.fromJson(Map<String, dynamic> json) {
    return DriverRide(
      rideId: json['rideId'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      pickupLocationId: json['pickupLocationId'] ?? '',
      dropoffLocationId: json['dropoffLocationId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      intermediateStopsIds: json['intermediateStopsIds'] != null
          ? List<String>.from(json['intermediateStopsIds'])
          : null,
      intermediateStops: json['intermediateStops'] != null
          ? List<String>.from(json['intermediateStops'])
          : null,
      departureTime: json['departureTime'] ?? '',
      date: json['date'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      bookedSeats: json['bookedSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      estimatedEarnings: (json['estimatedEarnings'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      vehicleModelId: json['vehicleModelId'],
      linkedReturnRideId: json['linkedReturnRideId'],
      segmentPrices: json['segmentPrices'] != null
          ? (json['segmentPrices'] as List)
              .map((sp) => SegmentPrice.fromJson(sp))
              .toList()
          : null,
      isReturnTrip: json['isReturnTrip'] ?? false,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      duration: json['duration'],
    );
  }
}

class PassengerInfo {
  final String bookingId;
  final String passengerName;
  final String phoneNumber;
  final int passengerCount;
  final String pickupLocationId;
  final String dropoffLocationId;
  final String pickupLocation;
  final String dropoffLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final double totalFare;
  final double totalAmount;
  final String otp;
  final String paymentStatus;
  final String boardingStatus;

  PassengerInfo({
    required this.bookingId,
    required this.passengerName,
    required this.phoneNumber,
    required this.passengerCount,
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    required this.totalFare,
    required this.totalAmount,
    required this.otp,
    required this.paymentStatus,
    required this.boardingStatus,
  });

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      bookingId: json['bookingId'] ?? '',
      passengerName: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      passengerCount: json['passengerCount'] ?? 0,
      pickupLocationId: json['pickupLocationId'] ?? '',
      dropoffLocationId: json['dropoffLocationId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      pickupLatitude: json['pickupLatitude']?.toDouble(),
      pickupLongitude: json['pickupLongitude']?.toDouble(),
      dropoffLatitude: json['dropoffLatitude']?.toDouble(),
      dropoffLongitude: json['dropoffLongitude']?.toDouble(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      otp: json['otp'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      boardingStatus: json['boardingStatus'] ?? '',
    );
  }
}

class RideDetailsWithPassengers {
  final String rideId;
  final String rideNumber;
  final String pickupLocationId;
  final String dropoffLocationId;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final List<String>? intermediateStopsIds;
  final List<String>? intermediateStops;
  final String departureTime;
  final String status;
  final int totalSeats;
  final int bookedSeats;
  final List<PassengerInfo> passengers;
  final double? distance; // in kilometers
  final int? duration; // in minutes
  final List<double>? segmentDistances; // distances for each segment in kilometers

  RideDetailsWithPassengers({
    required this.rideId,
    required this.rideNumber,
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupLatitude = 0.0,
    this.pickupLongitude = 0.0,
    this.dropoffLatitude = 0.0,
    this.dropoffLongitude = 0.0,
    this.intermediateStopsIds,
    this.intermediateStops,
    required this.departureTime,
    required this.status,
    required this.totalSeats,
    required this.bookedSeats,
    required this.passengers,
    this.distance,
    this.duration,
    this.segmentDistances,
  });

  factory RideDetailsWithPassengers.fromJson(Map<String, dynamic> json) {
    return RideDetailsWithPassengers(
      rideId: json['rideId'] ?? '',
      rideNumber: json['rideNumber'] ?? '',
      pickupLocationId: json['pickupLocationId'] ?? '',
      dropoffLocationId: json['dropoffLocationId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      dropoffLatitude: (json['dropoffLatitude'] as num?)?.toDouble() ?? 0.0,
      dropoffLongitude: (json['dropoffLongitude'] as num?)?.toDouble() ?? 0.0,
      intermediateStopsIds: json['intermediateStopsIds'] != null
          ? List<String>.from(json['intermediateStopsIds'])
          : null,
      intermediateStops: json['intermediateStops'] != null
          ? List<String>.from(json['intermediateStops'])
          : null,
      departureTime: json['departureTime'] ?? '',
      status: json['status'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      bookedSeats: json['bookedSeats'] ?? 0,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      duration: json['duration'] as int?,
      segmentDistances: json['segmentDistances'] != null
          ? (json['segmentDistances'] as List).map((d) => (d as num).toDouble()).toList()
          : null,
      passengers: (json['passengers'] as List?)
              ?.map((p) => PassengerInfo.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class StartTripResponse {
  final String rideId;
  final String status;
  final String startedAt;

  StartTripResponse({
    required this.rideId,
    required this.status,
    required this.startedAt,
  });

  factory StartTripResponse.fromJson(Map<String, dynamic> json) {
    return StartTripResponse(
      rideId: json['rideId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAt: json['startedAt']?.toString() ?? '',
    );
  }
}

class VerifyOtpRequest {
  final String otp;

  VerifyOtpRequest({required this.otp});

  Map<String, dynamic> toJson() => {'otp': otp};
}

class VerifyPassengerResponse {
  final String bookingId;
  final String passengerName;
  final String boardingStatus;
  final String verifiedAt;

  VerifyPassengerResponse({
    required this.bookingId,
    required this.passengerName,
    required this.boardingStatus,
    required this.verifiedAt,
  });

  factory VerifyPassengerResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPassengerResponse(
      bookingId: json['bookingId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      boardingStatus: json['boardingStatus'] ?? '',
      verifiedAt: json['verifiedAt'] ?? '',
    );
  }
}

class CompleteTripRequest {
  final LocationDto endLocation;
  final String actualArrivalTime;
  final double actualDistance;

  CompleteTripRequest({
    required this.endLocation,
    required this.actualArrivalTime,
    required this.actualDistance,
  });

  Map<String, dynamic> toJson() {
    return {
      'endLocation': endLocation.toJson(),
      'actualArrivalTime': actualArrivalTime,
      'actualDistance': actualDistance,
    };
  }
}

class CompleteTripResponse {
  final String rideId;
  final String status;
  final double totalEarnings;
  final String completedAt;

  CompleteTripResponse({
    required this.rideId,
    required this.status,
    required this.totalEarnings,
    required this.completedAt,
  });

  factory CompleteTripResponse.fromJson(Map<String, dynamic> json) {
    return CompleteTripResponse(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? '',
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      completedAt: json['completedAt'] ?? '',
    );
  }
}

class CancelRideRequest {
  final String reason;
  final String cancellationType;

  CancelRideRequest({
    required this.reason,
    this.cancellationType = 'driver',
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'cancellationType': cancellationType,
      };
}

class CancelRideResponse {
  final String rideId;
  final String status;
  final String cancelledAt;

  CancelRideResponse({
    required this.rideId,
    required this.status,
    required this.cancelledAt,
  });

  factory CancelRideResponse.fromJson(Map<String, dynamic> json) {
    return CancelRideResponse(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? '',
      cancelledAt: json['cancelledAt'] ?? '',
    );
  }
}

// Dashboard models
class DriverInfo {
  final String id;
  final String name;
  final double rating;
  final int totalRides;
  final bool isOnline;

  DriverInfo({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalRides,
    required this.isOnline,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      isOnline: json['isOnline'] ?? false,
    );
  }
}

class TodayStats {
  final int totalRides;
  final double totalEarnings;
  final double onlineHours;

  TodayStats({
    required this.totalRides,
    required this.totalEarnings,
    required this.onlineHours,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      totalRides: json['totalRides'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      onlineHours: (json['onlineHours'] ?? 0.0).toDouble(),
    );
  }
}

class DashboardData {
  final DriverInfo driver;
  final TodayStats todayStats;
  final double pendingEarnings;
  final double availableForWithdrawal;

  DashboardData({
    required this.driver,
    required this.todayStats,
    required this.pendingEarnings,
    required this.availableForWithdrawal,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      driver: DriverInfo.fromJson(json['driver'] ?? {}),
      todayStats: TodayStats.fromJson(json['todayStats'] ?? {}),
      pendingEarnings: (json['pendingEarnings'] ?? 0.0).toDouble(),
      availableForWithdrawal: (json['availableForWithdrawal'] ?? 0.0).toDouble(),
    );
  }
}

class UpdateOnlineStatusRequest {
  final bool isOnline;

  UpdateOnlineStatusRequest({required this.isOnline});

  Map<String, dynamic> toJson() => {'isOnline': isOnline};
}

class UpdateOnlineStatusResponse {
  final bool isOnline;
  final String updatedAt;

  UpdateOnlineStatusResponse({
    required this.isOnline,
    required this.updatedAt,
  });

  factory UpdateOnlineStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateOnlineStatusResponse(
      isOnline: json['isOnline'] ?? false,
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

// Earnings models
class EarningsSummary {
  final double totalEarnings;
  final int totalRides;
  final double averageEarningsPerRide;
  final double totalDistance;
  final double onlineHours;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalRides,
    required this.averageEarningsPerRide,
    required this.totalDistance,
    required this.onlineHours,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      averageEarningsPerRide: (json['averageEarningsPerRide'] ?? 0.0).toDouble(),
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      onlineHours: (json['onlineHours'] ?? 0.0).toDouble(),
    );
  }
}

class EarningsBreakdown {
  final double cashCollected;
  final double onlinePayments;
  final double commission;
  final double netEarnings;

  EarningsBreakdown({
    required this.cashCollected,
    required this.onlinePayments,
    required this.commission,
    required this.netEarnings,
  });

  factory EarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdown(
      cashCollected: (json['cashCollected'] ?? 0.0).toDouble(),
      onlinePayments: (json['onlinePayments'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      netEarnings: (json['netEarnings'] ?? 0.0).toDouble(),
    );
  }
}

class EarningsData {
  final EarningsSummary summary;
  final EarningsBreakdown breakdown;
  final List<dynamic> chartData;

  EarningsData({
    required this.summary,
    required this.breakdown,
    required this.chartData,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      summary: EarningsSummary.fromJson(json['summary'] ?? {}),
      breakdown: EarningsBreakdown.fromJson(json['breakdown'] ?? {}),
      chartData: json['chartData'] ?? [],
    );
  }
}

class PayoutItem {
  final String payoutId;
  final double amount;
  final String status;
  final String method;
  final String requestedAt;
  final String? completedAt;

  PayoutItem({
    required this.payoutId,
    required this.amount,
    required this.status,
    required this.method,
    required this.requestedAt,
    this.completedAt,
  });

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      payoutId: json['payoutId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      method: json['method'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      completedAt: json['completedAt'],
    );
  }
}

class RequestPayoutRequest {
  final double amount;
  final String method;

  RequestPayoutRequest({
    required this.amount,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'method': method,
      };
}

class RequestPayoutResponse {
  final String payoutId;
  final double amount;
  final String status;
  final String requestedAt;

  RequestPayoutResponse({
    required this.payoutId,
    required this.amount,
    required this.status,
    required this.requestedAt,
  });

  factory RequestPayoutResponse.fromJson(Map<String, dynamic> json) {
    return RequestPayoutResponse(
      payoutId: json['payoutId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
    );
  }
}

// Update price request and response
class UpdateRidePriceRequest {
  final double pricePerSeat;

  UpdateRidePriceRequest({required this.pricePerSeat});

  Map<String, dynamic> toJson() => {
        'pricePerSeat': pricePerSeat,
      };
}

class UpdateRidePriceResponse {
  final String rideId;
  final double pricePerSeat;
  final String updatedAt;

  UpdateRidePriceResponse({
    required this.rideId,
    required this.pricePerSeat,
    required this.updatedAt,
  });

  factory UpdateRidePriceResponse.fromJson(Map<String, dynamic> json) {
    return UpdateRidePriceResponse(
      rideId: json['rideId'] ?? '',
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

// Update segment prices request and response
class UpdateSegmentPricesRequest {
  final List<SegmentPrice> segmentPrices;

  UpdateSegmentPricesRequest({required this.segmentPrices});

  Map<String, dynamic> toJson() => {
        'segmentPrices': segmentPrices.map((s) => s.toJson()).toList(),
      };
}

class UpdateSegmentPricesResponse {
  final String rideId;
  final List<SegmentPrice> segmentPrices;
  final String updatedAt;

  UpdateSegmentPricesResponse({
    required this.rideId,
    required this.segmentPrices,
    required this.updatedAt,
  });

  factory UpdateSegmentPricesResponse.fromJson(Map<String, dynamic> json) {
    return UpdateSegmentPricesResponse(
      rideId: json['rideId'] ?? '',
      segmentPrices: (json['segmentPrices'] as List?)
              ?.map((s) => SegmentPrice.fromJson(s))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

// Update schedule request and response
class UpdateRideScheduleRequest {
  final String date; // dd-MM-yyyy format
  final String departureTime; // HH:mm format

  UpdateRideScheduleRequest({
    required this.date,
    required this.departureTime,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'departureTime': departureTime,
      };
}

class UpdateRideScheduleResponse {
  final String rideId;
  final String date;
  final String departureTime;
  final String updatedAt;

  UpdateRideScheduleResponse({
    required this.rideId,
    required this.date,
    required this.departureTime,
    required this.updatedAt,
  });

  factory UpdateRideScheduleResponse.fromJson(Map<String, dynamic> json) {
    return UpdateRideScheduleResponse(
      rideId: json['rideId'] ?? '',
      date: json['date'] ?? '',
      departureTime: json['departureTime'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}


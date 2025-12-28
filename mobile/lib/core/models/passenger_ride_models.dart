/// Passenger ride related models

class Location {
  final String address;
  final double latitude;
  final double longitude;

  Location({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class SearchRidesRequest {
  final Location pickupLocation;
  final Location dropoffLocation;
  final String travelDate;
  final int passengerCount;
  final String? vehicleType;

  SearchRidesRequest({
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.passengerCount,
    this.vehicleType,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'travelDate': travelDate,
      'passengerCount': passengerCount,
    };
    if (vehicleType != null) map['vehicleType'] = vehicleType!;
    return map;
  }
}

class RouteStopWithTime {
  final String location;
  final String arrivalTime;
  final int cumulativeDurationMinutes;

  RouteStopWithTime({
    required this.location,
    required this.arrivalTime,
    required this.cumulativeDurationMinutes,
  });

  factory RouteStopWithTime.fromJson(Map<String, dynamic> json) {
    return RouteStopWithTime(
      location: json['location'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      cumulativeDurationMinutes: json['cumulativeDurationMinutes'] ?? 0,
    );
  }
}

class AvailableRide {
  final String rideId;
  final String driverName;
  final double driverRating;
  final int driverRatingCount;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final int vehicleSeatingCapacity;
  final String pickupLocation;
  final String dropoffLocation;
  final String departureTime;
  final double pricePerSeat;
  final int availableSeats;
  final int totalSeats;
  final String? estimatedDuration;
  final double? distance;
  final List<String>? intermediateStops;
  final List<RouteStopWithTime>? routeStopsWithTiming;
  final String? seatingLayout;
  final List<String>? bookedSeats;

  AvailableRide({
    required this.rideId,
    required this.driverName,
    required this.driverRating,
    required this.driverRatingCount,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.vehicleSeatingCapacity,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.departureTime,
    required this.pricePerSeat,
    required this.availableSeats,
    required this.totalSeats,
    this.estimatedDuration,
    this.distance,
    this.intermediateStops,
    this.routeStopsWithTiming,
    this.seatingLayout,
    this.bookedSeats,
  });

  factory AvailableRide.fromJson(Map<String, dynamic> json) {
    int ratingCount = 0;
    final rawCount = json['driverRatingCount'];
    if (rawCount is int) {
      ratingCount = rawCount;
    } else if (rawCount is String) {
      ratingCount = int.tryParse(rawCount) ?? 0;
    } else if (rawCount != null) {
      try {
        ratingCount = int.parse(rawCount.toString());
      } catch (_) {
        ratingCount = 0;
      }
    }
    return AvailableRide(
      rideId: json['rideId'] ?? '',
      driverName: json['driverName'] ?? '',
      driverRating: (json['driverRating'] ?? 0.0).toDouble(),
      driverRatingCount: ratingCount,
      phoneNumber: json['phoneNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleSeatingCapacity: (json['vehicleSeatingCapacity'] is int) 
          ? json['vehicleSeatingCapacity'] 
          : (int.tryParse(json['vehicleSeatingCapacity']?.toString() ?? '') ?? 0),
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      departureTime: json['departureTime'] ?? '',
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      availableSeats: json['availableSeats'] ?? 0,
      totalSeats: json['totalSeats'] ?? 0,
      estimatedDuration: json['estimatedDuration'],
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      intermediateStops: json['intermediateStops'] != null
          ? List<String>.from(json['intermediateStops'])
          : null,
      routeStopsWithTiming: json['routeStopsWithTiming'] != null
          ? (json['routeStopsWithTiming'] as List)
              .map((stop) => RouteStopWithTime.fromJson(stop))
              .toList()
          : null,
      seatingLayout: json['seatingLayout'],
      bookedSeats: json['bookedSeats'] != null
          ? List<String>.from(json['bookedSeats'])
          : null,
    );
  }
}

class BookRideRequest {
  final String rideId;
  final int passengerCount;
  final Location pickupLocation;
  final Location dropoffLocation;
  final String paymentMethod;
  final List<String>? selectedSeats;

  BookRideRequest({
    required this.rideId,
    required this.passengerCount,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.paymentMethod,
    this.selectedSeats,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'rideId': rideId,
      'passengerCount': passengerCount,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'paymentMethod': paymentMethod,
    };
    
    if (selectedSeats != null && selectedSeats!.isNotEmpty) {
      json['selectedSeats'] = selectedSeats!;
    }
    
    return json;
  }
}

class DriverDetails {
  final String name;
  final String phoneNumber;
  final double rating;
  final String vehicleModel;
  final String vehicleNumber;

  DriverDetails({
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.vehicleModel,
    required this.vehicleNumber,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
    );
  }
}

class BookingResponse {
  final String bookingNumber;
  final String status;
  final String otp;
  final String rideId;
  final String pickupLocation;
  final String dropoffLocation;
  final String departureTime;
  final int passengerCount;
  final double totalFare;
  final String paymentMethod;
  final String paymentStatus;
  final DriverDetails driverDetails;
  final String bookedAt;

  BookingResponse({
    required this.bookingNumber,
    required this.status,
    required this.otp,
    required this.rideId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.departureTime,
    required this.passengerCount,
    required this.totalFare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.driverDetails,
    required this.bookedAt,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      bookingNumber: json['bookingNumber'] ?? '',
      status: json['status'] ?? '',
      otp: json['otp'] ?? '',
      rideId: json['rideId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      departureTime: json['departureTime'] ?? '',
      passengerCount: json['passengerCount'] ?? 0,
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      driverDetails: DriverDetails.fromJson(json['driverDetails'] ?? {}),
      bookedAt: json['bookedAt'] ?? '',
    );
  }
}

class BookingDetails {
  final String bookingNumber;
  final String status;
  final String otp;
  final String rideId;
  final String pickupLocation;
  final String dropoffLocation;
  final String departureTime;
  final int passengerCount;
  final double totalFare;
  final String paymentStatus;
  final DriverDetails driverDetails;
  final bool isVerified;

  BookingDetails({
    required this.bookingNumber,
    required this.status,
    required this.otp,
    required this.rideId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.departureTime,
    required this.passengerCount,
    required this.totalFare,
    required this.paymentStatus,
    required this.driverDetails,
    this.isVerified = false,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      bookingNumber: json['bookingNumber'] ?? '',
      status: json['status'] ?? '',
      otp: json['otp'] ?? '',
      rideId: json['rideId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      departureTime: json['departureTime'] ?? '',
      passengerCount: json['passengerCount'] ?? 0,
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? '',
      driverDetails: DriverDetails.fromJson(json['driverDetails'] ?? {}),
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class CancelBookingRequest {
  final String reason;
  final String cancellationType;

  CancelBookingRequest({
    required this.reason,
    required this.cancellationType,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'cancellationType': cancellationType,
      };
}

class CancelBookingResponse {
  final String bookingId;
  final String status;
  final double refundAmount;
  final double cancellationCharge;
  final String cancelledAt;

  CancelBookingResponse({
    required this.bookingId,
    required this.status,
    required this.refundAmount,
    required this.cancellationCharge,
    required this.cancelledAt,
  });

  factory CancelBookingResponse.fromJson(Map<String, dynamic> json) {
    return CancelBookingResponse(
      bookingId: json['bookingId'] ?? '',
      status: json['status'] ?? '',
      refundAmount: (json['refundAmount'] ?? 0.0).toDouble(),
      cancellationCharge: (json['cancellationCharge'] ?? 0.0).toDouble(),
      cancelledAt: json['cancelledAt'] ?? '',
    );
  }
}

class RideHistoryItem {
  final String? bookingId;  // UUID from server
  final String bookingNumber;
  final String pickupLocation;
  final String dropoffLocation;
  final String travelDate;
  final String timeSlot;
  final String vehicleType;
  final double totalFare;
  final String status;
  final double? rating;  // Passenger's rating for this specific ride
  final double? driverRating;  // Driver's overall rating
  final String? driverName;
  final String? driverId;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? scheduledDeparture;
  final String? otp;
  final bool isVerified;
  final String? rideId;
  final List<String>? intermediateStops;

  RideHistoryItem({
    this.bookingId,
    required this.bookingNumber,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.timeSlot,
    required this.vehicleType,
    required this.totalFare,
    required this.status,
    this.rating,
    this.driverRating,
    this.driverName,
    this.driverId,
    this.vehicleModel,
    this.vehicleNumber,
    this.scheduledDeparture,
    this.otp,
    this.isVerified = false,
    this.rideId,
    this.intermediateStops,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    // Debug: Print intermediate stops
    print('🔍 RideHistoryItem.fromJson:');
    print('   intermediateStops raw: ${json['intermediateStops']}');
    
    return RideHistoryItem(
      bookingId: json['bookingId']?.toString() ?? json['BookingId']?.toString(),
      bookingNumber: json['bookingNumber'] ?? json['BookingNumber'] ?? '',
      pickupLocation: json['pickupLocation'] ?? json['PickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? json['DropoffLocation'] ?? '',
      travelDate: json['date'] ?? json['travelDate'] ?? '', // API uses 'date' field
      timeSlot: json['timeSlot'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      totalFare: (json['fare'] ?? json['totalFare'] ?? 0.0).toDouble(), // API uses 'fare' field
      status: json['status'] ?? '',
      rating: json['passengerRating'] != null ? (json['passengerRating'] as num).toDouble() : null,
      driverRating: json['driverRating'] != null ? (json['driverRating'] as num).toDouble() : null,
      driverName: json['driverName'],
      driverId: json['driverId']?.toString(),
      vehicleModel: json['vehicleModel'],
      vehicleNumber: json['vehicleNumber'],
      scheduledDeparture: json['scheduledDeparture'],
      otp: json['otp']?.toString(),
      isVerified: json['isVerified'] ?? false,
      rideId: json['rideId']?.toString(),
      intermediateStops: json['intermediateStops'] != null
          ? List<String>.from(json['intermediateStops'])
          : null,
    );
  }
}

class RateRideRequest {
  final int rating;
  final String? review;
  final String driverId;

  RateRideRequest({
    required this.rating,
    this.review,
    required this.driverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
      'driverId': driverId,
    };
  }
}

class RateRideResponse {
  final String ratingId;
  final int rating;
  final String submittedAt;

  RateRideResponse({
    required this.ratingId,
    required this.rating,
    required this.submittedAt,
  });

  factory RateRideResponse.fromJson(Map<String, dynamic> json) {
    return RateRideResponse(
      ratingId: json['ratingId'] ?? '',
      rating: (json['rating'] is int) ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      submittedAt: json['submittedAt'] ?? '',
    );
  }
}

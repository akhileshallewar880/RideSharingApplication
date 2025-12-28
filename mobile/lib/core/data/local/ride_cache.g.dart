// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedRideAdapter extends TypeAdapter<CachedRide> {
  @override
  final int typeId = 0;

  @override
  CachedRide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedRide(
      rideId: fields[0] as String,
      rideNumber: fields[1] as String,
      pickupLocation: fields[2] as String,
      dropoffLocation: fields[3] as String,
      intermediateStops: (fields[4] as List).cast<String>(),
      departureTime: fields[5] as String,
      status: fields[6] as String,
      passengers: (fields[7] as List).cast<CachedPassenger>(),
      totalDistance: fields[8] as double,
      estimatedDuration: fields[9] as int,
      routePolyline: fields[10] as String?,
      cachedAt: fields[11] as DateTime,
      currentLatitude: fields[12] as double?,
      currentLongitude: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedRide obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.rideId)
      ..writeByte(1)
      ..write(obj.rideNumber)
      ..writeByte(2)
      ..write(obj.pickupLocation)
      ..writeByte(3)
      ..write(obj.dropoffLocation)
      ..writeByte(4)
      ..write(obj.intermediateStops)
      ..writeByte(5)
      ..write(obj.departureTime)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.passengers)
      ..writeByte(8)
      ..write(obj.totalDistance)
      ..writeByte(9)
      ..write(obj.estimatedDuration)
      ..writeByte(10)
      ..write(obj.routePolyline)
      ..writeByte(11)
      ..write(obj.cachedAt)
      ..writeByte(12)
      ..write(obj.currentLatitude)
      ..writeByte(13)
      ..write(obj.currentLongitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedRideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedPassengerAdapter extends TypeAdapter<CachedPassenger> {
  @override
  final int typeId = 1;

  @override
  CachedPassenger read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPassenger(
      bookingId: fields[0] as String,
      passengerName: fields[1] as String,
      phoneNumber: fields[2] as String,
      passengerCount: fields[3] as int,
      pickupLocation: fields[4] as String,
      dropoffLocation: fields[5] as String,
      boardingStatus: fields[6] as String,
      paymentStatus: fields[7] as String,
      totalFare: fields[8] as double,
      paymentCollected: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPassenger obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.bookingId)
      ..writeByte(1)
      ..write(obj.passengerName)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.passengerCount)
      ..writeByte(4)
      ..write(obj.pickupLocation)
      ..writeByte(5)
      ..write(obj.dropoffLocation)
      ..writeByte(6)
      ..write(obj.boardingStatus)
      ..writeByte(7)
      ..write(obj.paymentStatus)
      ..writeByte(8)
      ..write(obj.totalFare)
      ..writeByte(9)
      ..write(obj.paymentCollected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPassengerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IntermediateStopDataAdapter extends TypeAdapter<IntermediateStopData> {
  @override
  final int typeId = 2;

  @override
  IntermediateStopData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntermediateStopData(
      locationName: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      distanceFromOrigin: fields[3] as double,
      pickupCount: fields[4] as int,
      dropoffCount: fields[5] as int,
      pickupPassengerNames: (fields[6] as List).cast<String>(),
      dropoffPassengerNames: (fields[7] as List).cast<String>(),
      isPassed: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, IntermediateStopData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.locationName)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.distanceFromOrigin)
      ..writeByte(4)
      ..write(obj.pickupCount)
      ..writeByte(5)
      ..write(obj.dropoffCount)
      ..writeByte(6)
      ..write(obj.pickupPassengerNames)
      ..writeByte(7)
      ..write(obj.dropoffPassengerNames)
      ..writeByte(8)
      ..write(obj.isPassed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntermediateStopDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

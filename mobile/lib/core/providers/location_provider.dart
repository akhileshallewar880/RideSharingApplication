import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/core/services/location_service.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(DioClient.instance);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_location.dart';
import 'package:uuid/uuid.dart';

/// Service for managing saved locations
class SavedLocationService {
  static const String _boxName = 'saved_locations';
  Box<SavedLocation>? _box;
  final _uuid = const Uuid();

  /// Initialize Hive box for saved locations
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SavedLocationAdapter());
    }
    _box = await Hive.openBox<SavedLocation>(_boxName);
  }

  /// Get all saved locations
  List<SavedLocation> getAllLocations() {
    return _box?.values.toList() ?? [];
  }

  /// Get locations by type
  List<SavedLocation> getLocationsByType(SavedLocationType type) {
    return _box?.values.where((loc) => loc.type == type).toList() ?? [];
  }

  /// Get home location
  SavedLocation? getHomeLocation() {
    try {
      return _box?.values.firstWhere((loc) => loc.type == SavedLocationType.home);
    } catch (e) {
      return null;
    }
  }

  /// Get work location
  SavedLocation? getWorkLocation() {
    try {
      return _box?.values.firstWhere((loc) => loc.type == SavedLocationType.work);
    } catch (e) {
      return null;
    }
  }

  /// Get favorite locations
  List<SavedLocation> getFavoriteLocations() {
    return getLocationsByType(SavedLocationType.favorite);
  }

  /// Add or update saved location
  Future<SavedLocation> saveLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required SavedLocationType type,
    String? existingId,
  }) async {
    // For home and work, remove existing location of same type
    if (type == SavedLocationType.home || type == SavedLocationType.work) {
      final existing = type == SavedLocationType.home ? getHomeLocation() : getWorkLocation();
      if (existing != null) {
        await deleteLocation(existing.id);
      }
    }

    final location = SavedLocation(
      id: existingId ?? _uuid.v4(),
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      type: type,
      createdAt: DateTime.now(),
    );

    await _box?.put(location.id, location);
    return location;
  }

  /// Update location's last used timestamp
  Future<void> updateLastUsed(String locationId) async {
    final location = _box?.get(locationId);
    if (location != null) {
      final updated = location.copyWithLastUsed();
      await _box?.put(locationId, updated);
    }
  }

  /// Delete saved location
  Future<void> deleteLocation(String locationId) async {
    await _box?.delete(locationId);
  }

  /// Clear all saved locations
  Future<void> clearAll() async {
    await _box?.clear();
  }

  /// Check if home location is set
  bool hasHomeLocation() {
    return getHomeLocation() != null;
  }

  /// Check if work location is set
  bool hasWorkLocation() {
    return getWorkLocation() != null;
  }

  /// Get recently used locations (sorted by lastUsedAt)
  List<SavedLocation> getRecentlyUsed({int limit = 3}) {
    final locations = getAllLocations();
    locations.sort((a, b) {
      if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
      if (a.lastUsedAt == null) return 1;
      if (b.lastUsedAt == null) return -1;
      return b.lastUsedAt!.compareTo(a.lastUsedAt!);
    });
    return locations.take(limit).toList();
  }

  /// Search locations by name or address
  List<SavedLocation> searchLocations(String query) {
    if (query.isEmpty) return getAllLocations();
    
    final lowerQuery = query.toLowerCase();
    return _box?.values.where((loc) {
      return loc.name.toLowerCase().contains(lowerQuery) ||
             loc.address.toLowerCase().contains(lowerQuery);
    }).toList() ?? [];
  }

  /// Close the box
  Future<void> dispose() async {
    await _box?.close();
  }
}

/// Provider for saved location service
final savedLocationServiceProvider = Provider<SavedLocationService>((ref) {
  return SavedLocationService();
});

/// State notifier for saved locations
class SavedLocationNotifier extends StateNotifier<List<SavedLocation>> {
  final SavedLocationService _service;

  SavedLocationNotifier(this._service) : super([]) {
    _loadLocations();
  }

  void _loadLocations() {
    state = _service.getAllLocations();
  }

  Future<SavedLocation> saveLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required SavedLocationType type,
    String? existingId,
  }) async {
    final location = await _service.saveLocation(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      type: type,
      existingId: existingId,
    );
    _loadLocations();
    return location;
  }

  Future<void> deleteLocation(String locationId) async {
    await _service.deleteLocation(locationId);
    _loadLocations();
  }

  Future<void> updateLastUsed(String locationId) async {
    await _service.updateLastUsed(locationId);
    _loadLocations();
  }

  SavedLocation? getHomeLocation() => _service.getHomeLocation();
  SavedLocation? getWorkLocation() => _service.getWorkLocation();
  List<SavedLocation> getFavoriteLocations() => _service.getFavoriteLocations();
  List<SavedLocation> searchLocations(String query) => _service.searchLocations(query);
}

/// Provider for saved location notifier
final savedLocationNotifierProvider = StateNotifierProvider<SavedLocationNotifier, List<SavedLocation>>((ref) {
  final service = ref.watch(savedLocationServiceProvider);
  return SavedLocationNotifier(service);
});

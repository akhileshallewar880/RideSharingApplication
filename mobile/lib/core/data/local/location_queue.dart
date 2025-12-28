import 'package:hive_flutter/hive_flutter.dart';
import '../../services/location_tracking_service.dart';

/// Local queue for storing location updates when offline
class LocationQueue {
  static const String _boxName = 'location_updates';
  Box<Map>? _box;
  
  /// Initialize Hive box for location updates
  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox<Map>(_boxName);
  }
  
  /// Add location update to queue
  Future<void> addLocationUpdate(LocationUpdateData data) async {
    await init();
    await _box?.put(data.id, data.toJson());
  }
  
  /// Get all pending (unsynced) location updates
  Future<List<LocationUpdateData>> getPendingUpdates() async {
    await init();
    
    final updates = <LocationUpdateData>[];
    final keys = _box?.keys ?? [];
    
    for (var key in keys) {
      final json = _box?.get(key) as Map<dynamic, dynamic>?;
      if (json != null) {
        final data = LocationUpdateData.fromJson(
          Map<String, dynamic>.from(json),
        );
        if (!data.synced) {
          updates.add(data);
        }
      }
    }
    
    return updates;
  }
  
  /// Mark update as synced
  Future<void> markAsSynced(String id) async {
    await init();
    final json = _box?.get(id) as Map<dynamic, dynamic>?;
    if (json != null) {
      final data = LocationUpdateData.fromJson(
        Map<String, dynamic>.from(json),
      );
      await _box?.put(id, data.copyWith(synced: true).toJson());
    }
  }
  
  /// Remove update from queue
  Future<void> removeUpdate(String id) async {
    await init();
    await _box?.delete(id);
  }
  
  /// Clear all synced updates older than 24 hours
  Future<void> clearOldSyncedUpdates() async {
    await init();
    
    final now = DateTime.now();
    final keysToDelete = <String>[];
    
    for (var key in _box?.keys ?? []) {
      final json = _box?.get(key) as Map<dynamic, dynamic>?;
      if (json != null) {
        final data = LocationUpdateData.fromJson(
          Map<String, dynamic>.from(json),
        );
        
        if (data.synced && now.difference(data.timestamp).inHours > 24) {
          keysToDelete.add(key.toString());
        }
      }
    }
    
    for (var key in keysToDelete) {
      await _box?.delete(key);
    }
  }
  
  /// Get total count of pending updates
  Future<int> getPendingCount() async {
    final updates = await getPendingUpdates();
    return updates.length;
  }
}

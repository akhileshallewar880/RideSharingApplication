import 'package:hive/hive.dart';

part 'saved_location.g.dart';

/// Type of saved location
enum SavedLocationType {
  home,
  work,
  favorite,
}

/// Saved location model for quick access
@HiveType(typeId: 10)
class SavedLocation extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name; // "Home", "Work", or custom name like "Mom's House"
  
  @HiveField(2)
  final String address;
  
  @HiveField(3)
  final double latitude;
  
  @HiveField(4)
  final double longitude;
  
  @HiveField(5)
  @HiveField(5, defaultValue: SavedLocationType.favorite)
  final SavedLocationType type;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime? lastUsedAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Update last used timestamp
  SavedLocation copyWithLastUsed() {
    return SavedLocation(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      type: type,
      createdAt: createdAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// Get icon based on type
  String get icon {
    switch (type) {
      case SavedLocationType.home:
        return '🏠';
      case SavedLocationType.work:
        return '💼';
      case SavedLocationType.favorite:
        return '⭐';
    }
  }

  /// Convert to LocationSuggestion for backward compatibility
  Map<String, dynamic> toLocationSuggestion() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'SavedLocation(name: $name, address: $address, type: $type)';
  }
}

/// Hive adapter for SavedLocationType enum
@HiveType(typeId: 11)
enum SavedLocationTypeAdapter {
  @HiveField(0)
  home,
  
  @HiveField(1)
  work,
  
  @HiveField(2)
  favorite,
}

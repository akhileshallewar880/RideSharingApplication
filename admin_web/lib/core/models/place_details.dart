/// Model for Google Places Details API response
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final List<AddressComponent> addressComponents;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.addressComponents,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    // Handle both Google API format and backend format
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final components = json['addressComponents'] as List? ?? 
                      json['address_components'] as List? ?? 
                      [];

    return PlaceDetails(
      placeId: json['placeId'] as String? ?? json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String? ?? 
                       json['formatted_address'] as String? ?? 
                       '',
      latitude: _parseDouble(json['latitude'] ?? location?['lat']) ?? 0.0,
      longitude: _parseDouble(json['longitude'] ?? location?['lng']) ?? 0.0,
      addressComponents: components
          .map((c) => AddressComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Extract specific address component by type
  String? getAddressComponent(String type) {
    try {
      final component = addressComponents.firstWhere(
        (c) => c.types.contains(type),
      );
      return component.longName;
    } catch (e) {
      return null;
    }
  }

  /// Get state (administrative_area_level_1)
  String? get state => getAddressComponent('administrative_area_level_1');

  /// Get district (administrative_area_level_2 or administrative_area_level_3)
  String? get district {
    return getAddressComponent('administrative_area_level_2') ??
        getAddressComponent('administrative_area_level_3');
  }

  /// Get sub-locality or locality
  String? get locality {
    return getAddressComponent('sublocality') ??
        getAddressComponent('sublocality_level_1') ??
        getAddressComponent('locality');
  }

  /// Get postal code
  String? get postalCode => getAddressComponent('postal_code');

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    'formatted_address': formattedAddress,
    'latitude': latitude,
    'longitude': longitude,
    'address_components': addressComponents.map((c) => c.toJson()).toList(),
  };
}

/// Address component from Google Places API
class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['longName'] as String? ?? json['long_name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? json['short_name'] as String? ?? '',
      types: (json['types'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'long_name': longName,
    'short_name': shortName,
    'types': types,
  };
}

/// Location suggestion model for autocomplete
class LocationSuggestion {
  final String id;
  final String name;
  final String state;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String fullAddress;

  LocationSuggestion({
    required this.id,
    required this.name,
    required this.state,
    this.district,
    this.latitude,
    this.longitude,
    required this.fullAddress,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      fullAddress: json['fullAddress']?.toString() ?? json['full_address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
    };
  }

  @override
  String toString() => fullAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationSuggestion &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(id, name, latitude, longitude);
}

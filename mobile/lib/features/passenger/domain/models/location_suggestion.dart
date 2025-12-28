/// Location suggestion model for autocomplete
class LocationSuggestion {
  final String id;
  final String name;
  final String? state;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String fullAddress;
  
  LocationSuggestion({
    required this.id,
    required this.name,
    this.state,
    this.district,
    this.latitude,
    this.longitude,
    required this.fullAddress,
  });
  
  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'],
      district: json['district'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      fullAddress: json['fullAddress'] ?? json['name'] ?? '',
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
}

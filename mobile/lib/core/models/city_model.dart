/// City model for driver registration
class City {
  final String id;
  final String name;
  final String? state;
  final String? district;
  final String? pincode;
  final double? latitude;
  final double? longitude;

  City({
    required this.id,
    required this.name,
    this.state,
    this.district,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'],
      district: json['district'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'district': district,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get displayName {
    if (district != null && state != null) {
      return '$name, $district, $state';
    } else if (state != null) {
      return '$name, $state';
    }
    return name;
  }

  @override
  String toString() => displayName;
}

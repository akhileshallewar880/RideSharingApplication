/// Model for Google Places Autocomplete results
class PlaceAutocompleteResult {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  PlaceAutocompleteResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory PlaceAutocompleteResult.fromJson(Map<String, dynamic> json) {
    // Handle both Google API format and backend format
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    
    return PlaceAutocompleteResult(
      placeId: json['placeId'] as String? ?? json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: json['mainText'] as String? ?? 
                structuredFormatting?['main_text'] as String? ?? 
                json['description'] as String? ?? '',
      secondaryText: json['secondaryText'] as String? ?? 
                     structuredFormatting?['secondary_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'description': description,
    'mainText': mainText,
    'secondaryText': secondaryText,
  };
}

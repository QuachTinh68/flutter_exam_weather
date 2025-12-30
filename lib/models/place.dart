class Place {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;
  final String? timezone;

  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
    this.timezone,
  });

  String get displayName {
    final parts = <String>[
      name,
      if (admin1 != null && admin1!.trim().isNotEmpty) admin1!.trim(),
      if (country != null && country!.trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin1': admin1,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        name: (json['name'] ?? '').toString(),
        admin1: json['admin1']?.toString(),
        country: json['country']?.toString(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone']?.toString(),
      );

  factory Place.fromGeocodingJson(Map<String, dynamic> json) => Place(
        name: (json['name'] ?? '').toString(),
        admin1: json['admin1']?.toString(),
        country: json['country']?.toString(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone']?.toString(),
      );
}

class WeatherHourly {
  final DateTime time;
  final double temperature;
  final int weatherCode;

  /// % (0-100). Có thể null (archive).
  final double? precipitationProbability;

  /// mm/h (nếu có)
  final double? precipitation;

  final double? humidity;
  final double? windSpeed;

  const WeatherHourly({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability,
    this.precipitation,
    this.humidity,
    this.windSpeed,
  });
}

class WeatherDaily {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;

  /// % - có thể null nếu dữ liệu đến từ archive (không có precipitation_probability)
  final double? precipProbMax;

  const WeatherDaily({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipProbMax,
  });

  /// Helper để chuyển NaN/Infinity thành null để tránh lỗi khi encode JSON
  double? _sanitizeDouble(double? value) {
    if (value == null) return null;
    if (value.isNaN || value.isInfinite) return null;
    return value;
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weatherCode': weatherCode,
        'tempMax': _sanitizeDouble(tempMax) ?? 0.0,
        'tempMin': _sanitizeDouble(tempMin) ?? 0.0,
        'precipProbMax': _sanitizeDouble(precipProbMax),
      };

  factory WeatherDaily.fromJson(Map<String, dynamic> json) => WeatherDaily(
        date: DateTime.parse(json['date'] as String),
        weatherCode: (json['weatherCode'] as num).toInt(),
        tempMax: (json['tempMax'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        precipProbMax: (json['precipProbMax'] as num?)?.toDouble(),
      );
}

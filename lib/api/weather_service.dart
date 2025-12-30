import 'package:dio/dio.dart';

import 'api_client.dart';

class WeatherService {
  static const _forecastBase = 'https://api.open-meteo.com/v1/forecast';
  static const _archiveBase = 'https://archive-api.open-meteo.com/v1/archive';

  /// Forecast API: dùng cho hiện tại + vài ngày tới, và có thể lấy thêm vài ngày quá khứ gần đây bằng past_days.
  Future<Map<String, dynamic>> getForecastRaw({
    required double latitude,
    required double longitude,
    String? timezone,
    int forecastDays = 16,
    int pastDays = 2,
  }) async {
    final Response res = await ApiClient.dio.get(
      _forecastBase,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone ?? 'auto',
        'forecast_days': forecastDays,
        'past_days': pastDays,
        // Hourly để phục vụ chart + tách Sáng/Chiều/Tối
        'hourly': [
          'temperature_2m',
          'relative_humidity_2m',
          'wind_speed_10m',
          'precipitation_probability',
          'precipitation',
          'weather_code',
        ].join(','),
        // Daily để tô màu lịch (lấy code theo ngày + max/min)
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_probability_max',
        ].join(','),
        'current_weather': true,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw StateError('Unexpected response type: ${data.runtimeType}');
  }

  /// Historical Weather API: lấy theo khoảng ngày start_date/end_date (chuẩn cho việc lướt tháng).
  Future<Map<String, dynamic>> getArchiveRaw({
    required double latitude,
    required double longitude,
    required String startDate, // yyyy-MM-dd
    required String endDate, // yyyy-MM-dd
    String? timezone,
  }) async {
    final Response res = await ApiClient.dio.get(
      _archiveBase,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone ?? 'auto',
        'start_date': startDate,
        'end_date': endDate,
        'hourly': [
          'temperature_2m',
          'relative_humidity_2m',
          'wind_speed_10m',
          'precipitation',
          'weather_code',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
        ].join(','),
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw StateError('Unexpected response type: ${data.runtimeType}');
  }
}

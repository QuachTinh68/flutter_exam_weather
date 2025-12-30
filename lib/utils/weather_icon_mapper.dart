import 'package:flutter/material.dart';

class WeatherIconMapper {
  static IconData fromCode(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_rounded;
    if (code >= 45 && code <= 48) return Icons.blur_on_rounded; // fog
    if (code >= 51 && code <= 67) return Icons.grain_rounded; // drizzle/rain
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded; // snow
    if (code >= 80 && code <= 82) return Icons.grain_rounded; // showers
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }
}

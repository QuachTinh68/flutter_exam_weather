import 'package:flutter/material.dart';

/// PRD color mapping theo WMO Weather Code:
/// - Clear (0): #FFC107 (Vàng)
/// - Cloudy (1-3): #90A4AE (Xám)
/// - Fog (45, 48): #9E9E9E (Xám đậm)
/// - Drizzle (51-55): #64B5F6 (Xanh nhạt)
/// - Rain (61-65): #039BE5 (Xanh dương)
/// - Freezing Rain (66-67): #42A5F5 (Xanh dương nhạt)
/// - Snow (71-77): #E1F5FE (Xanh rất nhạt)
/// - Rain Showers (80-82): #0288D1 (Xanh đậm)
/// - Snow Showers (85-86): #B3E5FC (Xanh nhạt)
/// - Thunderstorm (95-99): #5E35B1 (Tím)
class WeatherColorMapper {
  static const Color clear = Color(0xFFFFC107);
  static const Color cloudy = Color(0xFF90A4AE);
  static const Color fog = Color(0xFF9E9E9E);
  static const Color drizzle = Color(0xFF64B5F6);
  static const Color rain = Color(0xFF039BE5);
  static const Color freezingRain = Color(0xFF42A5F5);
  static const Color snow = Color(0xFFE1F5FE);
  static const Color rainShowers = Color(0xFF0288D1);
  static const Color snowShowers = Color(0xFFB3E5FC);
  static const Color storm = Color(0xFF5E35B1);
  static const Color other = Color(0xFF26A69A);

  static Color fromWeatherCode(int code) {
    if (code == 0) return clear;
    if (code >= 1 && code <= 3) return cloudy;
    if (code == 45 || code == 48) return fog;
    if (code >= 51 && code <= 55) return drizzle;
    if (code >= 61 && code <= 65) return rain;
    if (code >= 66 && code <= 67) return freezingRain;
    if (code >= 71 && code <= 77) return snow;
    if (code >= 80 && code <= 82) return rainShowers;
    if (code >= 85 && code <= 86) return snowShowers;
    if (code >= 95 && code <= 99) return storm;
    return other;
  }
}

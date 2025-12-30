/// Helper để map WMO weather code sang OpenWeatherMap icon filename
/// Format: {code}{day/night}.png (01d, 01n, etc.)
class WeatherIconAsset {
  /// Chuyển đổi WMO weather code sang OWM icon code
  /// WMO codes: https://open-meteo.com/en/docs#weathervariables
  /// OWM icons: https://openweathermap.org/weather-conditions
  static String getIconCode(int wmoCode, bool isDay) {
    final suffix = isDay ? 'd' : 'n';
    
    // Clear sky
    if (wmoCode == 0) return '01$suffix';
    
    // Mainly clear, partly cloudy, overcast
    if (wmoCode == 1) return '02$suffix';
    if (wmoCode == 2) return '03$suffix';
    if (wmoCode == 3) return '04$suffix';
    
    // Fog
    if (wmoCode >= 45 && wmoCode <= 48) return '50$suffix';
    
    // Drizzle
    if (wmoCode >= 51 && wmoCode <= 55) return '09$suffix';
    if (wmoCode >= 56 && wmoCode <= 57) return '09$suffix';
    
    // Rain
    if (wmoCode >= 61 && wmoCode <= 65) return '10$suffix';
    if (wmoCode >= 66 && wmoCode <= 67) return '10$suffix';
    
    // Snow
    if (wmoCode >= 71 && wmoCode <= 77) return '13$suffix';
    
    // Showers
    if (wmoCode >= 80 && wmoCode <= 82) return '09$suffix';
    
    // Thunderstorm
    if (wmoCode >= 95 && wmoCode <= 99) return '11$suffix';
    
    // Default
    return '02$suffix';
  }
  
  /// Lấy đường dẫn asset icon
  static String getAssetPath(int wmoCode, bool isDay) {
    final iconCode = getIconCode(wmoCode, isDay);
    return 'assets/weather_icons/$iconCode.png';
  }
  
  /// Kiểm tra xem có phải ban ngày không (6h-18h)
  static bool isDayTime(DateTime time) {
    final hour = time.hour;
    return hour >= 6 && hour < 18;
  }
}


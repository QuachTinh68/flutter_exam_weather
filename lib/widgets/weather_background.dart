import 'package:flutter/material.dart';

import '../utils/color_mapper.dart';
import 'weather_particles.dart';

class WeatherBackground extends StatelessWidget {
  final int weatherCode;
  final double? temperature;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.weatherCode,
    this.temperature,
    required this.child,
  });

  /// Tính màu nền dựa trên nhiệt độ (phạm vi: -20°C đến 40°C)
  Color _getTemperatureColor(double? temp) {
    if (temp == null || !temp.isFinite) {
      return WeatherColorMapper.fromWeatherCode(weatherCode);
    }
    
    // Phạm vi nhiệt độ: -20°C (lạnh) đến 40°C (nóng)
    const minTemp = -20.0;
    const maxTemp = 40.0;
    final range = maxTemp - minTemp;
    
    // Normalize: 0 = min, 1 = max
    final normalized = ((temp - minTemp) / range).clamp(0.0, 1.0);
    
    // Gradient: xanh dương (lạnh) -> xanh lá -> vàng -> cam -> đỏ (nóng)
    if (normalized < 0.25) {
      // Xanh dương đậm -> xanh dương nhạt
      final t = normalized / 0.25;
      return Color.lerp(
        const Color(0xFF1565C0), // Blue dark
        const Color(0xFF42A5F5), // Blue light
        t,
      )!;
    } else if (normalized < 0.5) {
      // Xanh dương nhạt -> xanh lá
      final t = (normalized - 0.25) / 0.25;
      return Color.lerp(
        const Color(0xFF42A5F5), // Blue light
        const Color(0xFF66BB6A), // Green
        t,
      )!;
    } else if (normalized < 0.75) {
      // Xanh lá -> vàng
      final t = (normalized - 0.5) / 0.25;
      return Color.lerp(
        const Color(0xFF66BB6A), // Green
        const Color(0xFFFFC107), // Yellow
        t,
      )!;
    } else {
      // Vàng -> cam -> đỏ
      final t = (normalized - 0.75) / 0.25;
      return Color.lerp(
        const Color(0xFFFFC107), // Yellow
        const Color(0xFFFF5722), // Deep Orange/Red
        t,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên màu từ nhiệt độ, nếu không có thì dùng màu từ weather code
    final base = temperature != null && temperature!.isFinite
        ? _getTemperatureColor(temperature)
        : WeatherColorMapper.fromWeatherCode(weatherCode);
    
    final isDark = weatherCode >= 61 || weatherCode >= 95 || (weatherCode >= 45 && weatherCode <= 48);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withOpacity(isDark ? 0.25 : 0.35),
        Colors.black.withOpacity(0.88),
      ],
    );

    final hasParticles = (weatherCode >= 61 && weatherCode <= 65) || // Rain
        (weatherCode >= 71 && weatherCode <= 77) || // Snow
        (weatherCode >= 80 && weatherCode <= 82) || // Showers
        (weatherCode >= 95); // Thunderstorm
    
    // Hiển thị rainbow khi trời quang (clear sky)
    final showRainbow = weatherCode == 0 && temperature != null && temperature! > 10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          if (showRainbow)
            Positioned(
              top: -50,
              right: -50,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/rainbow.png',
                  width: 300,
                  height: 300,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          hasParticles
              ? WeatherParticles(
                  weatherCode: weatherCode,
                  child: child,
                )
              : child,
        ],
      ),
    );
  }
}

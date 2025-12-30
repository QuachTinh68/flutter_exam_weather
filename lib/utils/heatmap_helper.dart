import 'package:flutter/material.dart';

class HeatmapHelper {
  /// Tính màu heatmap theo nhiệt độ (từ min đến max)
  static Color getTemperatureColor(double temp, double min, double max) {
    if (temp.isNaN || min.isNaN || max.isNaN) {
      return Colors.white.withOpacity(0.06);
    }

    final range = max - min;
    if (range == 0) return Colors.blue.withOpacity(0.3);

    // Normalize: 0 = min, 1 = max
    final normalized = (temp - min) / range;
    
    // Gradient: xanh dương (lạnh) -> vàng (ấm) -> đỏ (nóng)
    if (normalized < 0.33) {
      // Xanh dương -> xanh lá
      final t = normalized / 0.33;
      return Color.lerp(
        const Color(0xFF2196F3), // Blue
        const Color(0xFF4CAF50), // Green
        t,
      )!.withOpacity(0.4);
    } else if (normalized < 0.66) {
      // Xanh lá -> vàng
      final t = (normalized - 0.33) / 0.33;
      return Color.lerp(
        const Color(0xFF4CAF50), // Green
        const Color(0xFFFFC107), // Yellow
        t,
      )!.withOpacity(0.4);
    } else {
      // Vàng -> đỏ
      final t = (normalized - 0.66) / 0.34;
      return Color.lerp(
        const Color(0xFFFFC107), // Yellow
        const Color(0xFFF44336), // Red
        t,
      )!.withOpacity(0.4);
    }
  }

  /// Tính màu heatmap theo mưa (0% -> 100%)
  static Color getPrecipitationColor(double? precipProb) {
    if (precipProb == null) {
      return Colors.white.withOpacity(0.06);
    }

    // Gradient: trong suốt -> xanh nhạt -> xanh đậm
    if (precipProb < 20) {
      return Colors.blue.withOpacity(0.1);
    } else if (precipProb < 50) {
      return Colors.blue.withOpacity(0.3);
    } else if (precipProb < 80) {
      return Colors.blue.withOpacity(0.5);
    } else {
      return Colors.blue.withOpacity(0.7);
    }
  }

  /// Tính min/max nhiệt độ từ danh sách daily
  static Map<String, double> getTempRange(Map<DateTime, dynamic> dailyMap) {
    double? minTemp;
    double? maxTemp;

    for (final daily in dailyMap.values) {
      if (daily.tempMin.isFinite) {
        minTemp = minTemp == null ? daily.tempMin : (minTemp < daily.tempMin ? minTemp : daily.tempMin);
      }
      if (daily.tempMax.isFinite) {
        maxTemp = maxTemp == null ? daily.tempMax : (maxTemp > daily.tempMax ? maxTemp : daily.tempMax);
      }
    }

    return {
      'min': minTemp ?? 0.0,
      'max': maxTemp ?? 30.0,
    };
  }
}


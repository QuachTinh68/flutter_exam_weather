import 'package:flutter/material.dart';
import '../models/weather_daily.dart';
import '../utils/weather_text.dart';
import 'glass_card.dart';

class DayTooltip extends StatelessWidget {
  final DateTime day;
  final WeatherDaily? daily;

  const DayTooltip({
    super.key,
    required this.day,
    this.daily,
  });

  @override
  Widget build(BuildContext context) {
    if (daily == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '${day.day}/${day.month}/${day.year}\nChưa có dữ liệu',
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day}/${day.month}/${day.year}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.thermostat_rounded,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                '${daily!.tempMax.toStringAsFixed(0)}° / ${daily!.tempMin.toStringAsFixed(0)}°',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          if (daily!.precipProbMax != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${daily!.precipProbMax!.round()}% mưa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            WeatherText.describe(daily!.weatherCode),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}


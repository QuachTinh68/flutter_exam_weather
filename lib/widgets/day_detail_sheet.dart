import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/day_part_weather.dart';
import '../providers/weather_provider.dart';
import '../utils/date_helper.dart';
import '../utils/weather_icon_mapper.dart';
import '../utils/weather_text.dart';
import 'glass_card.dart';
import 'multi_chart.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<DayPartWeather> parts;

  const DayDetailSheet({
    super.key,
    required this.day,
    required this.parts,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();
    final title = '${day.day}/${day.month}/${day.year}';
    final key = DateHelper.normalizeKey(day);
    final hourlyData = vm.hourlyByDay[key] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Row(
              children: parts.map((p) => Expanded(child: _partCard(p))).toList(),
            ),
            if (hourlyData.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: MultiChart(hourlyData: hourlyData),
              ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _partCard(DayPartWeather p) {
    final icon = WeatherIconMapper.fromCode(p.weatherCode);
    final sub = WeatherText.describe(p.weatherCode);

    String rainText;
    if (p.precipProbAvg != null) {
      rainText = '${p.precipProbAvg!.round()}% mưa';
    } else if (p.precipitationAvg != null) {
      rainText = '${p.precipitationAvg!.toStringAsFixed(1)} mm';
    } else {
      rainText = '—';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(p.label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Icon(icon, size: 28, color: Colors.white.withOpacity(0.9)),
            const SizedBox(height: 8),
            Text('${p.tempAvg.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(rainText, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            const SizedBox(height: 6),
            Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

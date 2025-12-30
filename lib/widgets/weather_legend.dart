import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/color_mapper.dart';
import '../utils/heatmap_helper.dart';
import 'weather_calendar.dart';

class WeatherLegend extends StatelessWidget {
  final HeatmapMode? heatmapMode;
  
  const WeatherLegend({super.key, this.heatmapMode});

  @override
  Widget build(BuildContext context) {
    final mode = heatmapMode ?? HeatmapMode.weatherCode;
    final vm = context.watch<WeatherProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _buildLegendContent(mode, vm),
    );
  }

  Widget _buildLegendContent(HeatmapMode mode, WeatherProvider vm) {
    switch (mode) {
      case HeatmapMode.temperature:
        return _buildTemperatureLegend(vm);
      case HeatmapMode.precipitation:
        return _buildPrecipitationLegend();
      case HeatmapMode.weatherCode:
        return _buildWeatherCodeLegend();
    }
  }

  Widget _buildTemperatureLegend(WeatherProvider vm) {
    final range = HeatmapHelper.getTempRange(vm.monthlyDaily);
    final min = range['min']!;
    final max = range['max']!;
    final rangeValue = max - min;
    
    // Tính các mức nhiệt độ
    final cold = min;
    final cool = min + rangeValue * 0.33;
    final warm = min + rangeValue * 0.66;
    final hot = max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Chú giải (Nhiệt độ)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Màu nền = Nhiệt độ cao nhất trong ngày (°C)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _TemperatureLegendItem(
          color: HeatmapHelper.getTemperatureColor(cold, min, max),
          label: '${cold.toStringAsFixed(0)}°C',
          description: 'Lạnh',
        ),
        const SizedBox(height: 6),
        _TemperatureLegendItem(
          color: HeatmapHelper.getTemperatureColor(cool, min, max),
          label: '${cool.toStringAsFixed(0)}°C',
          description: 'Mát',
        ),
        const SizedBox(height: 6),
        _TemperatureLegendItem(
          color: HeatmapHelper.getTemperatureColor(warm, min, max),
          label: '${warm.toStringAsFixed(0)}°C',
          description: 'Ấm',
        ),
        const SizedBox(height: 6),
        _TemperatureLegendItem(
          color: HeatmapHelper.getTemperatureColor(hot, min, max),
          label: '${hot.toStringAsFixed(0)}°C',
          description: 'Nóng',
        ),
        const SizedBox(height: 6),
        Text(
          'Gradient: Xanh dương (lạnh) → Xanh lá → Vàng → Đỏ (nóng)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPrecipitationLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Chú giải (Lượng mưa)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Màu nền = Xác suất mưa tối đa trong ngày (%)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PrecipitationLegendItem(
          color: HeatmapHelper.getPrecipitationColor(0),
          label: '0%',
          description: 'Không mưa',
        ),
        const SizedBox(height: 6),
        _PrecipitationLegendItem(
          color: HeatmapHelper.getPrecipitationColor(20),
          label: '< 20%',
          description: 'Ít mưa',
        ),
        const SizedBox(height: 6),
        _PrecipitationLegendItem(
          color: HeatmapHelper.getPrecipitationColor(50),
          label: '20-50%',
          description: 'Mưa vừa',
        ),
        const SizedBox(height: 6),
        _PrecipitationLegendItem(
          color: HeatmapHelper.getPrecipitationColor(80),
          label: '50-80%',
          description: 'Mưa nhiều',
        ),
        const SizedBox(height: 6),
        _PrecipitationLegendItem(
          color: HeatmapHelper.getPrecipitationColor(95),
          label: '> 80%',
          description: 'Mưa rất nhiều',
        ),
        const SizedBox(height: 6),
        Text(
          'Gradient: Trong suốt → Xanh nhạt → Xanh đậm',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCodeLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Chú giải (Weather Code)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _LegendGroup(
          title: 'Trời quang & Mây',
          items: [
            _LegendItem(code: 0, label: 'Trời quang'),
            _LegendItem(code: 1, label: 'Ít mây'),
            _LegendItem(code: 2, label: 'Có mây'),
            _LegendItem(code: 3, label: 'Nhiều mây'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Sương mù',
          items: [
            _LegendItem(code: 45, label: 'Sương mù'),
            _LegendItem(code: 48, label: 'Sương mù đóng băng'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Mưa phùn',
          items: [
            _LegendItem(code: 51, label: 'Mưa phùn nhẹ'),
            _LegendItem(code: 53, label: 'Mưa phùn vừa'),
            _LegendItem(code: 55, label: 'Mưa phùn nặng'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Mưa',
          items: [
            _LegendItem(code: 61, label: 'Mưa nhẹ'),
            _LegendItem(code: 63, label: 'Mưa vừa'),
            _LegendItem(code: 65, label: 'Mưa nặng'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Mưa rào',
          items: [
            _LegendItem(code: 80, label: 'Mưa rào nhẹ'),
            _LegendItem(code: 81, label: 'Mưa rào vừa'),
            _LegendItem(code: 82, label: 'Mưa rào nặng'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Tuyết',
          items: [
            _LegendItem(code: 71, label: 'Tuyết nhẹ'),
            _LegendItem(code: 73, label: 'Tuyết vừa'),
            _LegendItem(code: 75, label: 'Tuyết nặng'),
          ],
        ),
        const SizedBox(height: 8),
        _LegendGroup(
          title: 'Dông',
          items: [
            _LegendItem(code: 95, label: 'Dông'),
            _LegendItem(code: 96, label: 'Dông có mưa đá'),
            _LegendItem(code: 99, label: 'Dông mạnh có mưa đá'),
          ],
        ),
      ],
    );
  }
}

class _LegendGroup extends StatelessWidget {
  final String title;
  final List<_LegendItem> items;

  const _LegendGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: items,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final int code;
  final String label;

  const _LegendItem({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = WeatherColorMapper.fromWeatherCode(code);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.32),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemperatureLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _TemperatureLegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label - $description',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrecipitationLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _PrecipitationLegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label - $description',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 1,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


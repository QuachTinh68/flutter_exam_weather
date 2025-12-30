import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../utils/date_helper.dart';
import 'glass_card.dart';
import 'multi_chart.dart';

class CompareDaysSheet extends StatefulWidget {
  final DateTime day1;
  final DateTime day2;

  const CompareDaysSheet({
    super.key,
    required this.day1,
    required this.day2,
  });

  @override
  State<CompareDaysSheet> createState() => _CompareDaysSheetState();
}

class _CompareDaysSheetState extends State<CompareDaysSheet> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();
    final key1 = DateHelper.normalizeKey(widget.day1);
    final key2 = DateHelper.normalizeKey(widget.day2);
    final hourly1 = vm.hourlyByDay[key1] ?? [];
    final hourly2 = vm.hourlyByDay[key2] ?? [];

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              'So sánh 2 ngày',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${widget.day1.day}/${widget.day1.month}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hourly1.isNotEmpty
                              ? '${hourly1.map((e) => e.temperature).where((v) => v.isFinite).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°'
                              : '—',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${widget.day2.day}/${widget.day2.month}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hourly2.isNotEmpty
                              ? '${hourly2.map((e) => e.temperature).where((v) => v.isFinite).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°'
                              : '—',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hourly1.isNotEmpty && hourly2.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: _buildComparisonChart(hourly1, hourly2),
              ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(List hourly1, List hourly2) {
    // Tạo chart so sánh nhiệt độ của 2 ngày
    final spots1 = <dynamic>[];
    final spots2 = <dynamic>[];

    final maxLength = hourly1.length > hourly2.length ? hourly1.length : hourly2.length;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < maxLength; i++) {
      if (i < hourly1.length && hourly1[i].temperature.isFinite) {
        spots1.add({'x': i.toDouble(), 'y': hourly1[i].temperature});
        if (hourly1[i].temperature < minY) minY = hourly1[i].temperature;
        if (hourly1[i].temperature > maxY) maxY = hourly1[i].temperature;
      }
      if (i < hourly2.length && hourly2[i].temperature.isFinite) {
        spots2.add({'x': i.toDouble(), 'y': hourly2[i].temperature});
        if (hourly2[i].temperature < minY) minY = hourly2[i].temperature;
        if (hourly2[i].temperature > maxY) maxY = hourly2[i].temperature;
      }
    }

    if (minY.isInfinite || maxY.isInfinite) {
      return const Text('Không có dữ liệu để so sánh');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhiệt độ so sánh',
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: ComparisonChartPainter(
              data1: spots1,
              data2: spots2,
              minY: minY - 2,
              maxY: maxY + 2,
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 12,
              height: 2,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.day1.day}/${widget.day1.month}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 2,
              color: Colors.cyan.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.day2.day}/${widget.day2.month}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class ComparisonChartPainter extends CustomPainter {
  final List data1;
  final List data2;
  final double minY;
  final double maxY;

  ComparisonChartPainter({
    required this.data1,
    required this.data2,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paint2 = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path1 = Path();
    final path2 = Path();

    if (data1.isNotEmpty) {
      final first = data1.first;
      path1.moveTo(
        (first['x'] / (data1.length > 0 ? data1.length : 1)) * size.width,
        size.height - ((first['y'] - minY) / (maxY - minY)) * size.height,
      );
      for (final point in data1) {
        path1.lineTo(
          (point['x'] / (data1.length > 0 ? data1.length : 1)) * size.width,
          size.height - ((point['y'] - minY) / (maxY - minY)) * size.height,
        );
      }
    }

    if (data2.isNotEmpty) {
      final first = data2.first;
      path2.moveTo(
        (first['x'] / (data2.length > 0 ? data2.length : 1)) * size.width,
        size.height - ((first['y'] - minY) / (maxY - minY)) * size.height,
      );
      for (final point in data2) {
        path2.lineTo(
          (point['x'] / (data2.length > 0 ? data2.length : 1)) * size.width,
          size.height - ((point['y'] - minY) / (maxY - minY)) * size.height,
        );
      }
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(ComparisonChartPainter oldDelegate) {
    return oldDelegate.data1 != data1 || oldDelegate.data2 != data2;
  }
}


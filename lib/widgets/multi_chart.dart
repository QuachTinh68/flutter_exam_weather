import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/weather_hourly.dart';
import '../utils/date_helper.dart';

enum ChartType { temperature, precipitation, wind }

class MultiChart extends StatelessWidget {
  final List<WeatherHourly> hourlyData;
  final List<ChartType> visibleCharts;

  const MultiChart({
    super.key,
    required this.hourlyData,
    this.visibleCharts = const [ChartType.temperature, ChartType.precipitation, ChartType.wind],
  });

  // ✅ Chỉ hiển thị các giờ này trên trục X
  static const Set<int> _shownHours = {0, 3, 6, 9, 12, 15, 18, 21};

  // ✅ Lấy index ĐẦU TIÊN ứng với mỗi hour trong data (tránh trùng lặp nếu data có nhiều điểm/giờ)
  Set<int> _labelIndicesForShownHours() {
    final firstIndexByHour = <int, int>{};
    for (int i = 0; i < hourlyData.length; i++) {
      final t = hourlyData[i].time;
      firstIndexByHour.putIfAbsent(t.hour, () => i);
    }

    final indices = <int>{};
    for (final h in _shownHours) {
      final idx = firstIndexByHour[h];
      if (idx != null) indices.add(idx);
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('Không có dữ liệu')));
    }

    return Column(
      children: [
        if (visibleCharts.contains(ChartType.temperature)) _buildTemperatureChart(),
        if (visibleCharts.contains(ChartType.precipitation)) _buildPrecipitationChart(),
        if (visibleCharts.contains(ChartType.wind)) _buildWindChart(),
      ],
    );
  }

  Widget _buildTemperatureChart() {
    final temps = hourlyData.map((e) => e.temperature).where((v) => v.isFinite).toList();
    if (temps.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < hourlyData.length; i++) {
      if (hourlyData[i].temperature.isFinite) {
        spots.add(FlSpot(i.toDouble(), hourlyData[i].temperature));
      }
    }

    final minY = temps.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = temps.reduce((a, b) => a > b ? a : b) + 2;

    final shownIndices = _labelIndicesForShownHours();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.thermostat_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                'Nhiệt độ (°C)',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}°',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                    ),
                  ),
                ),

                // ✅ FIX: chỉ hiện 00,03,06,09,12,15,18,21
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1, // kiểm soát bằng điều kiện, không dựa vào interval nữa
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= hourlyData.length) return const SizedBox.shrink();

                      // chỉ hiện tại index thuộc tập shownIndices
                      if (!shownIndices.contains(index)) return const SizedBox.shrink();

                      final time = hourlyData[index].time;
                      // nếu data không đúng mốc phút 0 thì bỏ để tránh bị lệch (tuỳ bạn)
                      // if (time.minute != 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateHelper.hm.format(time),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),

                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  isStrokeCapRound: true,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.55),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 350),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrecipitationChart() {
    final precip = hourlyData.map((e) => e.precipitation ?? 0.0).toList();
    if (precip.every((v) => v == 0)) return const SizedBox.shrink();

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < hourlyData.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: precip[i],
              color: Colors.blue.withOpacity(0.7),
              width: 4,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ],
        ),
      );
    }

    final maxY = precip.reduce((a, b) => a > b ? a : b) + 1;

    double yInterval;
    if (maxY <= 0.2) {
      yInterval = 0.1;
    } else if (maxY <= 0.5) {
      yInterval = 0.2;
    } else if (maxY <= 1.0) {
      yInterval = 0.3;
    } else if (maxY <= 2.0) {
      yInterval = 0.5;
    } else if (maxY <= 5.0) {
      yInterval = 1.0;
    } else if (maxY <= 10.0) {
      yInterval = 2.0;
    } else {
      yInterval = (maxY / 4).ceilToDouble();
      if (yInterval <= 5) {
        yInterval = 5;
      } else if (yInterval <= 10) {
        yInterval = 10;
      } else if (yInterval <= 20) {
        yInterval = 20;
      } else {
        yInterval = (yInterval / 10).ceilToDouble() * 10;
      }
    }

    // ✅ dùng chung logic hiển thị giờ như chart khác
    final shownIndices = _labelIndicesForShownHours();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                'Lượng mưa (mm/h)',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > maxY) return const Text('');

                      String text;
                      if (value < 0.05) {
                        text = '0';
                      } else if (value < 1) {
                        final rounded = (value * 10).round() / 10;
                        if (rounded == rounded.roundToDouble()) {
                          text = rounded.toInt().toString();
                        } else {
                          text = rounded.toStringAsFixed(1);
                        }
                      } else {
                        text = value.toInt().toString();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),

                // ✅ FIX: chỉ hiện 00,03,06,09,12,15,18,21
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();

                      if (index < 0 || index >= hourlyData.length) return const SizedBox.shrink();
                      if (!shownIndices.contains(index)) return const SizedBox.shrink();

                      final time = hourlyData[index].time;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateHelper.hm.format(time),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),

                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: bars,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black.withOpacity(0.85),
                  tooltipRoundedRadius: 10,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  tooltipMargin: 10,
                  direction: TooltipDirection.top,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x.toInt();
                    if (index >= 0 && index < hourlyData.length) {
                      final time = hourlyData[index].time;
                      final value = rod.toY;
                      final valueText = value < 0.1 ? '0.0' : (value < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(1));
                      return BarTooltipItem(
                        '${DateHelper.hm.format(time)}\n$valueText mm/h',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 350),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWindChart() {
    final winds = hourlyData.map((e) => e.windSpeed ?? 0.0).where((v) => v > 0).toList();
    if (winds.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < hourlyData.length; i++) {
      if (hourlyData[i].windSpeed != null && hourlyData[i].windSpeed! > 0) {
        spots.add(FlSpot(i.toDouble(), hourlyData[i].windSpeed!));
      }
    }

    final maxY = winds.isEmpty ? 10.0 : winds.reduce((a, b) => a > b ? a : b) + 2;

    final shownIndices = _labelIndicesForShownHours();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.air_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                'Tốc độ gió (km/h)',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                    ),
                  ),
                ),

                // ✅ FIX: chỉ hiện 00,03,06,09,12,15,18,21
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= hourlyData.length) return const SizedBox.shrink();
                      if (!shownIndices.contains(index)) return const SizedBox.shrink();

                      final time = hourlyData[index].time;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateHelper.hm.format(time),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),

                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  isStrokeCapRound: true,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  color: Colors.cyan.withOpacity(0.7),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 350),
          ),
        ),
      ],
    );
  }
}

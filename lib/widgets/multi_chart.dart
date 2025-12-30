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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: hourlyData.length > 12 ? 3 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < hourlyData.length) {
                        return Text(
                          DateHelper.hm.format(hourlyData[index].time),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                        );
                      }
                      return const Text('');
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
    
    // Tính interval cho trục Y - đảm bảo có đủ khoảng cách giữa các nhãn
    // Chiều cao biểu đồ: 100px, mỗi nhãn cần tối thiểu 25px để không đè
    // Tối đa 3-4 nhãn để đảm bảo khoảng cách đủ rộng
    double yInterval;
    if (maxY <= 0.2) {
      yInterval = 0.1; // 0, 0.1, 0.2
    } else if (maxY <= 0.5) {
      yInterval = 0.2; // 0, 0.2, 0.4
    } else if (maxY <= 1.0) {
      yInterval = 0.3; // 0, 0.3, 0.6, 0.9
    } else if (maxY <= 2.0) {
      yInterval = 0.5; // 0, 0.5, 1.0, 1.5, 2.0
    } else if (maxY <= 5.0) {
      yInterval = 1.0; // 0, 1, 2, 3, 4, 5
    } else if (maxY <= 10.0) {
      yInterval = 2.0; // 0, 2, 4, 6, 8, 10
    } else {
      // Cho giá trị lớn, chia thành tối đa 4 mức
      yInterval = (maxY / 4).ceilToDouble();
      // Làm tròn lên số đẹp (5, 10, 20, 50...)
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

    // Tìm các index chính xác của các mốc giờ chính (0h, 6h, 12h, 18h)
    // Chỉ lấy điểm ĐẦU TIÊN của mỗi giờ chính để tránh trùng lặp
    final mainHourIndices = <int>{};
    final seenHours = <int>{};
    for (int i = 0; i < hourlyData.length; i++) {
      final time = hourlyData[i].time;
      final hour = time.hour;
      // Chỉ lấy điểm có giờ chính và phút = 0
      if ((hour == 0 || hour == 6 || hour == 12 || hour == 18) && 
          time.minute == 0 && 
          !seenHours.contains(hour)) {
        mainHourIndices.add(i);
        seenHours.add(hour);
      }
    }
    
    // Tính interval cho trục X dựa trên số lượng dữ liệu
    // Mục tiêu: hiển thị 4 mốc giờ chính (0h, 6h, 12h, 18h)
    double xInterval;
    if (hourlyData.length <= 12) {
      xInterval = 3; // Hiển thị mỗi 3 giờ
    } else if (hourlyData.length <= 24) {
      xInterval = 6; // Hiển thị mỗi 6 giờ (0h, 6h, 12h, 18h)
    } else if (hourlyData.length <= 48) {
      xInterval = 12; // Hiển thị mỗi 12 giờ
    } else {
      xInterval = hourlyData.length / 4; // Chia thành 4 mốc
    }

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
                      // Chỉ hiển thị nhãn nếu giá trị >= 0 và <= maxY
                      if (value < 0 || value > maxY) {
                        return const Text('');
                      }
                      
                      // Format số ngắn gọn, tránh số thập phân không cần thiết
                      String text;
                      if (value < 0.05) {
                        text = '0';
                      } else if (value < 1) {
                        // Làm tròn đến 1 chữ số thập phân, loại bỏ số 0 cuối
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
                            height: 1.2, // Giảm line height để tiết kiệm không gian
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) {
                      // Chỉ xử lý nếu value là số nguyên (hoặc gần số nguyên)
                      // Tránh xử lý các giá trị float không chính xác
                      final index = value.round();
                      
                      // CHỈ hiển thị nếu:
                      // 1. index hợp lệ (>= 0 và < length)
                      // 2. index nằm trong danh sách các mốc giờ chính đã tìm được
                      // 3. value gần với index (tránh trường hợp float không chính xác)
                      if (index >= 0 && 
                          index < hourlyData.length && 
                          mainHourIndices.contains(index) &&
                          (value - index).abs() < 0.5) {
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
                      }
                      return const Text('');
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
                      // Format giá trị mưa
                      final valueText = value < 0.1 
                          ? '0.0' 
                          : (value < 1 
                              ? value.toStringAsFixed(2) 
                              : value.toStringAsFixed(1));
                      return BarTooltipItem(
                        '${DateHelper.hm.format(time)}\n$valueText mm/h',
                        TextStyle(
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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: hourlyData.length > 12 ? 3 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < hourlyData.length) {
                        return Text(
                          DateHelper.hm.format(hourlyData[index].time),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                        );
                      }
                      return const Text('');
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


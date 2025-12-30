import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/weather_provider.dart';
import '../utils/color_mapper.dart';
import '../utils/date_helper.dart';
import '../utils/heatmap_helper.dart';
import 'day_tooltip.dart';

enum HeatmapMode { weatherCode, temperature, precipitation }

class WeatherCalendar extends StatefulWidget {
  final void Function(DateTime day)? onDayTapped;
  final void Function(DateTime day)? onDayDoubleTapped;
  final void Function(HeatmapMode mode)? onModeChanged;

  const WeatherCalendar({
    super.key,
    this.onDayTapped,
    this.onDayDoubleTapped,
    this.onModeChanged,
  });

  @override
  State<WeatherCalendar> createState() => _WeatherCalendarState();
}

class _WeatherCalendarState extends State<WeatherCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  HeatmapMode _heatmapMode = HeatmapMode.weatherCode;
  bool _showYearView = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();

    return Column(
      children: [
        // Heatmap mode selector
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<HeatmapMode>(
                  segments: const [
                    ButtonSegment(
                      value: HeatmapMode.weatherCode,
                      label: Text('Mã thời tiết'),
                      icon: Icon(Icons.wb_cloudy_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: HeatmapMode.temperature,
                      label: Text('Nhiệt độ'),
                      icon: Icon(Icons.thermostat_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: HeatmapMode.precipitation,
                      label: Text('Mưa'),
                      icon: Icon(Icons.water_drop_rounded, size: 16),
                    ),
                  ],
                  selected: {_heatmapMode},
                  onSelectionChanged: (Set<HeatmapMode> newSelection) {
                    setState(() {
                      _heatmapMode = newSelection.first;
                    });
                    widget.onModeChanged?.call(_heatmapMode);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return Colors.white.withOpacity(0.05);
                    }),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Year/Month toggle
              IconButton(
                icon: Icon(_showYearView ? Icons.calendar_month_rounded : Icons.view_module_rounded),
                onPressed: () {
                  setState(() {
                    _showYearView = !_showYearView;
                  });
                },
                tooltip: _showYearView ? 'Xem tháng' : 'Xem cả năm',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Week/Month toggle (chỉ hiện khi không phải year view)
              if (!_showYearView)
                IconButton(
                  icon: Icon(_calendarFormat == CalendarFormat.month ? Icons.view_week_rounded : Icons.calendar_month_rounded),
                  onPressed: () {
                    setState(() {
                      _calendarFormat = _calendarFormat == CalendarFormat.month
                          ? CalendarFormat.week
                          : CalendarFormat.month;
                    });
                  },
                  tooltip: _calendarFormat == CalendarFormat.month ? 'Xem tuần' : 'Xem tháng',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        if (_showYearView)
          _YearView(
            heatmapMode: _heatmapMode,
            onMonthTapped: (month) {
              setState(() {
                _showYearView = false;
              });
              final year = vm.focusedDay.year;
              final newDay = DateTime(year, month, 1);
              vm.setFocusedDay(newDay);
            },
          )
        else
          TableCalendar(
          firstDay: DateTime.utc(1940, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: vm.focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => vm.selectedDay != null && DateHelper.isSameDay(day, vm.selectedDay!),
          onDaySelected: (selectedDay, focusedDay) {
            vm.selectDay(selectedDay);
            widget.onDayTapped?.call(selectedDay);
          },
          onPageChanged: (focusedDay) {
            vm.setFocusedDay(focusedDay);
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            isTodayHighlighted: true,
            weekendTextStyle: TextStyle(color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            weekendStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Colors.white),
            titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _dayCell(context, day, vm),
            todayBuilder: (context, day, focusedDay) {
              final isSelected = vm.selectedDay != null && DateHelper.isSameDay(day, vm.selectedDay!);
              return _dayCell(context, day, vm, isToday: true, isSelected: isSelected);
            },
            selectedBuilder: (context, day, focusedDay) {
              final isToday = DateHelper.isSameDay(day, DateTime.now());
              return _dayCell(context, day, vm, isToday: isToday, isSelected: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, WeatherProvider vm, {bool isToday = false, bool isSelected = false}) {
    final d = DateHelper.normalizeKey(day);
    final daily = vm.monthlyDaily[d];

    Color bg;
    if (daily == null) {
      bg = Colors.white.withOpacity(0.06);
    } else {
      switch (_heatmapMode) {
        case HeatmapMode.temperature:
          final range = HeatmapHelper.getTempRange(vm.monthlyDaily);
          bg = HeatmapHelper.getTemperatureColor(daily.tempMax, range['min']!, range['max']!);
          break;
        case HeatmapMode.precipitation:
          bg = HeatmapHelper.getPrecipitationColor(daily.precipProbMax);
          break;
        case HeatmapMode.weatherCode:
          bg = WeatherColorMapper.fromWeatherCode(daily.weatherCode).withOpacity(0.32);
      }
    }

    // Viền cho ngày hôm nay và ngày được chọn
    // Ngày hôm nay luôn có viền rõ ràng, ngày được chọn có viền dày hơn
    final border = isSelected && isToday
        ? Border.all(color: Colors.white.withOpacity(0.8), width: 2.0) // Vừa là hôm nay vừa được chọn
        : isSelected
            ? Border.all(color: Colors.white.withOpacity(0.7), width: 1.3) // Chỉ được chọn
            : isToday
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5) // Chỉ là hôm nay
                : Border.all(color: Colors.transparent, width: 1);

    return GestureDetector(
      onLongPress: () {
        _showTooltip(context, day, daily);
      },
      onDoubleTap: () {
        widget.onDayDoubleTapped?.call(day);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: Colors.white.withOpacity(daily != null ? 1.0 : 0.65),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context, DateTime day, dynamic daily) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: DayTooltip(day: day, daily: daily),
        ),
      ),
    );
  }
}

class _YearView extends StatefulWidget {
  final HeatmapMode heatmapMode;
  final void Function(int month) onMonthTapped;

  const _YearView({
    required this.heatmapMode,
    required this.onMonthTapped,
  });

  @override
  State<_YearView> createState() => _YearViewState();
}

class _YearViewState extends State<_YearView> {
  bool _hasPrefetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefetch dữ liệu cho các tháng trong năm khi vào year view (chỉ một lần)
    if (!_hasPrefetched && mounted) {
      _hasPrefetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vm = Provider.of<WeatherProvider>(context, listen: false);
        final currentYear = vm.focusedDay.year;
        
        for (int month = 1; month <= 12; month++) {
          if (!mounted) break;
          final monthStart = DateTime(currentYear, month, 1);
          // Chỉ prefetch nếu chưa có dữ liệu
          final hasData = vm.monthlyDaily.keys.any((date) => 
            date.year == currentYear && date.month == month
          );
          if (!hasData) {
            vm.loadMonth(monthStart);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();
    final currentYear = vm.focusedDay.year;
    final monthNames = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthStart = DateTime(currentYear, month, 1);
        final monthEnd = DateTime(currentYear, month + 1, 0);
        
        return _MonthCell(
          month: month,
          monthName: monthNames[index],
          monthStart: monthStart,
          monthEnd: monthEnd,
          heatmapMode: widget.heatmapMode,
          onTap: () => widget.onMonthTapped(month),
        );
      },
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int month;
  final String monthName;
  final DateTime monthStart;
  final DateTime monthEnd;
  final HeatmapMode heatmapMode;
  final VoidCallback onTap;

  const _MonthCell({
    required this.month,
    required this.monthName,
    required this.monthStart,
    required this.monthEnd,
    required this.heatmapMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();
    final now = DateTime.now();
    final isCurrentMonth = now.year == monthStart.year && now.month == month;
    
    // Tính toán màu đại diện cho tháng (dựa trên dữ liệu có sẵn)
    Color monthColor = Colors.white.withOpacity(0.06);
    int daysWithData = 0;
    final List<Color> dayColors = [];
    
    // Lấy dữ liệu từ monthlyDaily
    for (int day = 1; day <= monthEnd.day; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      final key = DateHelper.normalizeKey(date);
      final daily = vm.monthlyDaily[key];
      
      if (daily != null) {
        daysWithData++;
        Color? dayColor;
        switch (heatmapMode) {
          case HeatmapMode.temperature:
            if (daily.tempMax.isFinite) {
              final range = HeatmapHelper.getTempRange(vm.monthlyDaily);
              dayColor = HeatmapHelper.getTemperatureColor(daily.tempMax, range['min']!, range['max']!);
            }
            break;
          case HeatmapMode.precipitation:
            dayColor = HeatmapHelper.getPrecipitationColor(daily.precipProbMax);
            break;
          case HeatmapMode.weatherCode:
            dayColor = WeatherColorMapper.fromWeatherCode(daily.weatherCode).withOpacity(0.32);
        }
        if (dayColor != null) {
          dayColors.add(dayColor);
        }
      }
    }
    
    // Tính màu trung bình của tháng
    if (dayColors.isNotEmpty) {
      int r = 0, g = 0, b = 0, a = 0;
      for (final color in dayColors) {
        r += color.red;
        g += color.green;
        b += color.blue;
        a += color.alpha;
      }
      monthColor = Color.fromARGB(
        a ~/ dayColors.length,
        r ~/ dayColors.length,
        g ~/ dayColors.length,
        b ~/ dayColors.length,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: monthColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentMonth 
                ? Colors.white.withOpacity(0.6) 
                : Colors.white.withOpacity(0.2),
            width: isCurrentMonth ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            if (daysWithData > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$daysWithData/${monthEnd.day}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

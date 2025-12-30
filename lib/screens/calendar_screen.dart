import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../widgets/compare_days_sheet.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/glass_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/weather_background.dart';
import '../widgets/weather_calendar.dart';
import '../widgets/weather_legend.dart';
import '../widgets/base_scaffold.dart';
import 'search_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  HeatmapMode _currentHeatmapMode = HeatmapMode.weatherCode;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();

    return WeatherBackground(
      weatherCode: vm.currentCode,
      temperature: vm.currentTemp,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _Header(
                  title: vm.place?.displayName ?? 'Đang tải...',
                  onSearch: () async {
                    final place = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                    if (place != null && context.mounted) {
                      vm.setPlace(place);
                    }
                  },
                  onToday: () {
                    final today = DateTime.now();
                    vm.setFocusedDay(today);
                    vm.selectDay(today);
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (vm.isOffline)
                        OfflineBanner(onRetry: vm.retry),
                      GlassCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Lịch', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700)),
                                const Spacer(),
                                if (vm.isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.8)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            WeatherCalendar(
                              onDayTapped: (day) {
                                final parts = vm.buildDayParts(day);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => GlassCard(
                                    borderRadius: 26,
                                    blur: 22,
                                    tint: Colors.black,
                                    child: DayDetailSheet(day: day, parts: parts),
                                  ),
                                );
                              },
                              onDayDoubleTapped: (day) {
                                vm.setCompareDay(day);
                              },
                              onModeChanged: (mode) {
                                setState(() {
                                  _currentHeatmapMode = mode;
                                });
                              },
                            ),
                            if (vm.compareDay1 != null || vm.compareDay2 != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (vm.compareDay1 != null)
                                    Expanded(
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Ngày 1: ${vm.compareDay1!.day}/${vm.compareDay1!.month}',
                                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 16),
                                              onPressed: () {
                                                vm.clearCompareDay1();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (vm.compareDay1 != null && vm.compareDay2 != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Ngày 2: ${vm.compareDay2!.day}/${vm.compareDay2!.month}',
                                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 16),
                                              onPressed: () {
                                                vm.clearCompareDay2();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (vm.compareDay1 != null && vm.compareDay2 != null) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => GlassCard(
                                          borderRadius: 26,
                                          blur: 22,
                                          tint: Colors.black,
                                          child: CompareDaysSheet(
                                            day1: vm.compareDay1!,
                                            day2: vm.compareDay2!,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.compare_arrows_rounded),
                                    label: const Text('So sánh 2 ngày'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.15),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Màu nền mỗi ngày = weather_code', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                                const Spacer(),
                                Text('Giữ: chi tiết | 2 lần chạm: so sánh', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      WeatherLegend(heatmapMode: _currentHeatmapMode),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onSearch;
  final VoidCallback onToday;

  const _Header({required this.title, required this.onSearch, required this.onToday});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final baseScaffold = BaseScaffold.of(context);
            baseScaffold?.openMenu();
          },
          icon: const Icon(Icons.menu_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.10),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: onToday,
          icon: const Icon(Icons.today_rounded, size: 18),
          label: const Text('Hôm nay'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.10),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.10),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}


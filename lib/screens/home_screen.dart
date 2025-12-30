import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../utils/weather_text.dart';
import '../utils/weather_icon_asset.dart';
import '../widgets/daily_chart.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/glass_card.dart';
import '../widgets/last_updated_badge.dart';
import '../widgets/offline_banner.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/weather_background.dart';
import '../widgets/weather_calendar.dart';
import '../widgets/base_scaffold.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();

    final heroTemp = vm.currentTemp;
    final desc = WeatherText.describe(vm.currentCode);

    final selected = vm.selectedDay;
    final temps = vm.selectedDayTemps;
    final times = vm.selectedDayTimes;

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
                  lastUpdated: vm.lastUpdated,
                  onSearch: () async {
                    final place = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                    if (place != null && context.mounted) {
                      vm.setPlace(place);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (vm.isOffline)
                        OfflineBanner(onRetry: vm.retry),
                      if (vm.isLoading && vm.monthlyDaily.isEmpty)
                        ..._buildSkeletonContent()
                      else
                        ..._buildContent(context, vm, heroTemp, desc, selected, temps, times),
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

  Widget _miniStat({required IconData icon, required String label, required String value}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WeatherProvider vm,
    double? heroTemp,
    String desc,
    DateTime? selected,
    List<double> temps,
    List<DateTime> times,
  ) {
    return [
      Hero(
        tag: 'hero-temp',
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            heroTemp == null ? '—' : '${heroTemp.toStringAsFixed(0)}°',
                            key: ValueKey(heroTemp),
                            style: const TextStyle(
                              fontSize: 58,
                              height: 1.0,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                  // Weather icon
                  Image.asset(
                    WeatherIconAsset.getAssetPath(vm.currentCode, WeatherIconAsset.isDayTime(DateTime.now())),
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      icon: Icons.water_drop_rounded,
                      label: 'Độ ẩm',
                      value: vm.currentHumidity == null ? '—' : '${vm.currentHumidity!.round()}%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      icon: Icons.air_rounded,
                      label: 'Gió',
                      value: vm.currentWindSpeed == null ? '—' : '${vm.currentWindSpeed!.toStringAsFixed(1)} km/h',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected == null ? 'Nhiệt độ theo giờ' : 'Nhiệt độ theo giờ (${selected.day}/${selected.month})',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (selected != null && temps.isNotEmpty && temps.length == times.length)
              DailyChart(temps: temps, times: times)
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Chọn 1 ngày trên lịch để xem biểu đồ',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Màu nền mỗi ngày = weather_code', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                const Spacer(),
                Text('Giữ để xem chi tiết', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
    ];
  }

  List<Widget> _buildSkeletonContent() {
    return [
      SkeletonCard(height: 200),
      const SizedBox(height: 12),
      SkeletonCard(height: 180),
      const SizedBox(height: 12),
      SkeletonCard(height: 400),
      const SizedBox(height: 22),
    ];
  }
}

class _Header extends StatelessWidget {
  final String title;
  final DateTime? lastUpdated;
  final VoidCallback onSearch;

  const _Header({required this.title, this.lastUpdated, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.10),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (lastUpdated != null) ...[
          const SizedBox(height: 8),
          LastUpdatedBadge(lastUpdated: lastUpdated),
        ],
      ],
    );
  }
}

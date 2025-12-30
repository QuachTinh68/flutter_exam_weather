import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../utils/weather_text.dart';
import '../utils/weather_icon_asset.dart';
import '../widgets/daily_chart.dart';
import '../widgets/glass_card.dart';
import '../widgets/last_updated_badge.dart';
import '../widgets/offline_banner.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/weather_background.dart';
import '../widgets/base_scaffold.dart';
import 'search_screen.dart';

class TodayDetailScreen extends StatelessWidget {
  const TodayDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherProvider>();

    final heroTemp = vm.currentTemp;
    final desc = WeatherText.describe(vm.currentCode);
    final today = DateTime.now();
    final temps = vm.hourlyByDay[DateTime(today.year, today.month, today.day, 12)]?.map((e) => e.temperature).where((v) => v.isFinite).toList() ?? [];
    final times = vm.hourlyByDay[DateTime(today.year, today.month, today.day, 12)]?.map((e) => e.time).toList() ?? [];
    final parts = vm.buildDayParts(today);

    return WeatherBackground(
      weatherCode: vm.currentCode,
      temperature: heroTemp,
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
                        ..._buildContent(vm, heroTemp, desc, temps, times, parts),
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

  List<Widget> _buildContent(
    WeatherProvider vm,
    double? heroTemp,
    String desc,
    List<double> temps,
    List<DateTime> times,
    List parts,
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
              'Nhiệt độ theo giờ (Hôm nay)',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (temps.isNotEmpty && temps.length == times.length)
              DailyChart(temps: temps, times: times)
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Đang tải dữ liệu...',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời tiết theo buổi',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...parts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _dayPartCard(p),
                )),
          ],
        ),
      ),
      const SizedBox(height: 22),
    ];
  }

  Widget _dayPartCard(dynamic part) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              part.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            part.tempAvg.isNaN ? '—' : '${part.tempAvg.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (part.precipProbAvg != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.water_drop_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              '${part.precipProbAvg!.round()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonContent() {
    return [
      SkeletonCard(height: 200),
      const SizedBox(height: 12),
      SkeletonCard(height: 180),
      const SizedBox(height: 12),
      SkeletonCard(height: 200),
      const SizedBox(height: 22),
    ];
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
}

class _Header extends StatelessWidget {
  final String title;
  final DateTime? lastUpdated;
  final VoidCallback onSearch;

  const _Header({
    required this.title,
    this.lastUpdated,
    required this.onSearch,
  });

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


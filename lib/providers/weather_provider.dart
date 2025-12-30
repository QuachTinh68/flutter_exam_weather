import 'dart:convert';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../api/weather_service.dart';
import '../models/day_part_weather.dart';
import '../models/place.dart';
import '../models/weather_daily.dart';
import '../models/weather_hourly.dart';
import '../utils/cache_helper.dart';
import '../utils/date_helper.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  Place? place;
  bool isLoading = false;
  String? error;
  DateTime? lastUpdated;
  bool isOffline = false;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  DateTime? compareDay1;
  DateTime? compareDay2;

  /// Daily data cho tháng đang focus (dùng cho TableCalendar)
  final Map<DateTime, WeatherDaily> monthlyDaily = {};

  /// Hourly cache theo ngày (chỉ giữ trong RAM), key = normalizeKey(day)
  final Map<DateTime, List<WeatherHourly>> hourlyByDay = {};

  // Current hero
  double? currentTemp;
  int currentCode = 0;
  double? currentHumidity;
  double? currentWindSpeed;

  Future<void> bootstrap() async {
    selectedDay = DateTime.now();
    focusedDay = selectedDay!;
    await _loadSavedPlaceOrGps();
    await loadMonth(focusedDay);
  }

  Future<void> _loadSavedPlaceOrGps() async {
    final box = Hive.box('cache');
    final saved = box.get('place');
    if (saved is String) {
      try {
        place = Place.fromJson(jsonDecode(saved) as Map<String, dynamic>);
        return;
      } catch (_) {}
    }

    // fallback: try GPS (best effort)
    try {
      final pos = await _getPosition();
      place = Place(name: 'Vị trí hiện tại', latitude: pos.latitude, longitude: pos.longitude);
      await _savePlace(place!);
    } catch (_) {
      // fallback: Hanoi
      place = const Place(name: 'Hà Nội', latitude: 21.0278, longitude: 105.8342);
      await _savePlace(place!);
    }
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw StateError('Location service disabled');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
  }

  Future<void> setPlace(Place p) async {
    place = p;
    await _savePlace(p);
    await loadMonth(focusedDay, forceRefresh: true);
    notifyListeners();
  }

  /// Retry load tháng hiện tại
  Future<void> retry() async {
    await loadMonth(focusedDay, forceRefresh: true);
  }

  Future<void> _savePlace(Place p) async {
    final box = Hive.box('cache');
    await box.put('place', jsonEncode(p.toJson()));
  }

  void setFocusedDay(DateTime d) {
    if (DateHelper.isSameMonth(focusedDay, d)) {
      // Đã ở cùng tháng, chỉ cần notify
      notifyListeners();
      return;
    }
    
    focusedDay = d;
    loadMonth(d);
    // Prefetch tháng trước và sau (delay một chút để không conflict)
    Future.delayed(const Duration(milliseconds: 500), () {
      _prefetchAdjacentMonths(d);
    });
    notifyListeners();
  }

  /// Prefetch tháng A-1 và A+1 khi load tháng A
  Future<void> _prefetchAdjacentMonths(DateTime month) async {
    // Chỉ prefetch nếu không đang load tháng hiện tại
    if (isLoading) return;
    
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    
    // Prefetch trong background, không block UI và không clear data hiện tại
    try {
      await Future.wait([
        _prefetchMonth(prevMonth),
        _prefetchMonth(nextMonth),
      ]);
    } catch (_) {
      // Ignore prefetch errors
    }
  }

  /// Prefetch một tháng mà không clear data hiện tại
  Future<void> _prefetchMonth(DateTime anyDayInMonth) async {
    final p = place;
    if (p == null) return;

    final monthStart = DateHelper.startOfMonth(anyDayInMonth);
    final monthEnd = DateHelper.endOfMonth(anyDayInMonth);
    final now = DateTime.now();
    final monthKey = '${p.latitude.toStringAsFixed(4)}_${p.longitude.toStringAsFixed(4)}_${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

    // Chỉ prefetch nếu chưa có cache
    final cached = CacheHelper.getIfValid(monthKey);
    if (cached != null) return; // Đã có cache, không cần prefetch

    try {
      final timezone = p.timezone;
      Map<String, dynamic> raw;

      if (monthEnd.isBefore(DateHelper.dateOnly(now))) {
        raw = await _service.getArchiveRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          startDate: DateHelper.toYmd(monthStart),
          endDate: DateHelper.toYmd(monthEnd),
          timezone: timezone,
        );
      } else if (DateHelper.isSameMonth(monthStart, now)) {
        raw = await _service.getForecastRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          timezone: timezone,
          forecastDays: 16,
          pastDays: 2,
        );
      } else {
        raw = await _service.getForecastRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          timezone: timezone,
          forecastDays: 16,
          pastDays: 0,
        );
      }

      // Lưu cache mà không update state hiện tại
      final tempDaily = <DateTime, WeatherDaily>{};
      final tempHourly = <DateTime, List<WeatherHourly>>{};
      
      _parseDailyToMap(raw, tempDaily, isArchive: monthEnd.isBefore(DateHelper.dateOnly(now)));
      _parseHourlyToMap(raw, tempHourly, isArchive: monthEnd.isBefore(DateHelper.dateOnly(now)));

      // Lưu vào cache
      final cacheData = {
        'daily': tempDaily.map((k, v) => MapEntry(k.toIso8601String(), v.toJson())),
        'hourlyByDay': tempHourly.map((k, v) => MapEntry(
              k.toIso8601String(),
              v.map((h) => {
                    'time': h.time.toIso8601String(),
                    'temperature': h.temperature,
                    'weatherCode': h.weatherCode,
                    'precipitationProbability': h.precipitationProbability,
                    'precipitation': h.precipitation,
                    'humidity': h.humidity,
                    'windSpeed': h.windSpeed,
                  }).toList(),
            )),
      };

      final ttlHours = CacheHelper.getTTLForMonth(monthStart, now);
      await CacheHelper.putWithTTL(monthKey, jsonEncode(cacheData), ttlHours: ttlHours);
    } catch (_) {
      // Silently fail prefetch
    }
  }

  void selectDay(DateTime d) {
    selectedDay = d;
    notifyListeners();
  }

  void setCompareDay(DateTime d) {
    if (compareDay1 == null) {
      compareDay1 = d;
    } else if (compareDay2 == null && !DateHelper.isSameDay(compareDay1!, d)) {
      compareDay2 = d;
    } else {
      // Reset và chọn ngày mới
      compareDay1 = d;
      compareDay2 = null;
    }
    notifyListeners();
  }

  void clearCompareDay1() {
    compareDay1 = null;
    if (compareDay2 != null) {
      compareDay1 = compareDay2;
      compareDay2 = null;
    }
    notifyListeners();
  }

  void clearCompareDay2() {
    compareDay2 = null;
    notifyListeners();
  }

  void clearCompare() {
    compareDay1 = null;
    compareDay2 = null;
    notifyListeners();
  }

  /// Hybrid strategy:
  /// - Tháng quá khứ: archive theo start/end month
  /// - Tháng hiện tại: merge archive (đầu tháng -> (today - delay)) + forecast (past_days + forecast range)
  /// - Tháng tương lai: chỉ có dữ liệu nếu nằm trong forecast range (khoảng 16 ngày).
  Future<void> loadMonth(DateTime anyDayInMonth, {bool forceRefresh = false}) async {
    final p = place;
    if (p == null) return;

    final monthStart = DateHelper.startOfMonth(anyDayInMonth);
    final monthEnd = DateHelper.endOfMonth(anyDayInMonth);
    final now = DateTime.now();

    final monthKey = '${p.latitude.toStringAsFixed(4)}_${p.longitude.toStringAsFixed(4)}_${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

    // Cache với TTL
    if (!forceRefresh) {
      final cached = CacheHelper.getIfValid(monthKey);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          _hydrateMonthFromCache(decoded);
          // Lấy lastUpdated từ cache nếu có
          final box = Hive.box('cache');
          final lastUpdatedStr = box.get('lastUpdated:$monthKey');
          if (lastUpdatedStr is String) {
            try {
              lastUpdated = DateTime.parse(lastUpdatedStr);
            } catch (_) {}
          }
          notifyListeners();
          return;
        } catch (_) {}
      }
    }

    isLoading = true;
    error = null;
    isOffline = false;
    notifyListeners();

    try {
      monthlyDaily.clear();
      hourlyByDay.clear();

      final timezone = p.timezone; // Sử dụng timezone từ Place

      // Case 1: past month
      if (monthEnd.isBefore(DateHelper.dateOnly(now))) {
        final raw = await _service.getArchiveRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          startDate: DateHelper.toYmd(monthStart),
          endDate: DateHelper.toYmd(monthEnd),
          timezone: timezone,
        );
        _applyRawToState(raw, isArchive: true);
      }
      // Case 2: current month (merge)
      else if (DateHelper.isSameMonth(monthStart, now)) {
        // archive phần đầu tháng tới (today - delay) để đỡ "trống" nếu người dùng lướt xa hơn past_days
        final delayDays = 5; // docs nói có delay; dùng buffer
        final archiveEnd = DateHelper.dateOnly(now).subtract(Duration(days: delayDays));
        if (archiveEnd.isAfter(monthStart)) {
          final rawA = await _service.getArchiveRaw(
            latitude: p.latitude,
            longitude: p.longitude,
            startDate: DateHelper.toYmd(monthStart),
            endDate: DateHelper.toYmd(archiveEnd),
            timezone: timezone,
          );
          _applyRawToState(rawA, isArchive: true);
        }

        final rawF = await _service.getForecastRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          timezone: timezone,
          forecastDays: 16,
          pastDays: 2,
        );
        _applyRawToState(rawF, isArchive: false);
      }
      // Case 3: future month: try forecast anyway (sẽ chỉ trả về 16 ngày)
      else {
        final rawF = await _service.getForecastRaw(
          latitude: p.latitude,
          longitude: p.longitude,
          timezone: timezone,
          forecastDays: 16,
          pastDays: 0,
        );
        _applyRawToState(rawF, isArchive: false);
      }

      // Lưu cache với TTL
      final ttlHours = CacheHelper.getTTLForMonth(monthStart, now);
      await CacheHelper.putWithTTL(monthKey, jsonEncode(_dumpMonthToCache()), ttlHours: ttlHours);
      
      // Lưu lastUpdated
      lastUpdated = DateTime.now();
      final box = Hive.box('cache');
      await box.put('lastUpdated:$monthKey', lastUpdated!.toIso8601String());
    } catch (e, stackTrace) {
      // Log lỗi ra console thay vì hiển thị trên UI
      developer.log(
        'Error loading weather data: $e',
        name: 'WeatherProvider',
        error: e,
        stackTrace: stackTrace,
      );
      error = null; // Không hiển thị lỗi trên UI
      // Kiểm tra nếu là lỗi mạng
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('network')) {
        isOffline = true;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Helper để chuyển NaN/Infinity thành null để tránh lỗi khi encode JSON
  double? _sanitizeDouble(double? value) {
    if (value == null) return null;
    if (value.isNaN || value.isInfinite) return null;
    return value;
  }

  Map<String, dynamic> _dumpMonthToCache() {
    return {
      'daily': monthlyDaily.map((k, v) => MapEntry(k.toIso8601String(), v.toJson())),
      'hourlyByDay': hourlyByDay.map((k, v) => MapEntry(
            k.toIso8601String(),
            v
                .map((h) => {
                      'time': h.time.toIso8601String(),
                      'temperature': _sanitizeDouble(h.temperature) ?? 0.0,
                      'weatherCode': h.weatherCode,
                      'precipitationProbability': _sanitizeDouble(h.precipitationProbability),
                      'precipitation': _sanitizeDouble(h.precipitation),
                      'humidity': _sanitizeDouble(h.humidity),
                      'windSpeed': _sanitizeDouble(h.windSpeed),
                    })
                .toList(),
          )),
      'current': {
        'temp': _sanitizeDouble(currentTemp),
        'code': currentCode,
        'humidity': _sanitizeDouble(currentHumidity),
        'wind': _sanitizeDouble(currentWindSpeed),
      },
    };
  }

  void _hydrateMonthFromCache(Map<String, dynamic> decoded) {
    monthlyDaily.clear();
    hourlyByDay.clear();

    final daily = decoded['daily'];
    if (daily is Map) {
      for (final entry in daily.entries) {
        monthlyDaily[DateTime.parse(entry.key as String)] =
            WeatherDaily.fromJson((entry.value as Map).cast<String, dynamic>());
      }
    }

    final hbd = decoded['hourlyByDay'];
    if (hbd is Map) {
      for (final entry in hbd.entries) {
        final key = DateTime.parse(entry.key as String);
        final List list = entry.value as List;
        hourlyByDay[key] = list
            .map((e) => e as Map)
            .map(
              (m) => WeatherHourly(
                time: DateTime.parse(m['time'] as String),
                temperature: (m['temperature'] as num).toDouble(),
                weatherCode: (m['weatherCode'] as num).toInt(),
                precipitationProbability: (m['precipitationProbability'] as num?)?.toDouble(),
                precipitation: (m['precipitation'] as num?)?.toDouble(),
                humidity: (m['humidity'] as num?)?.toDouble(),
                windSpeed: (m['windSpeed'] as num?)?.toDouble(),
              ),
            )
            .toList();
      }
    }

    final cur = decoded['current'];
    if (cur is Map) {
      currentTemp = (cur['temp'] as num?)?.toDouble();
      currentCode = (cur['code'] as num?)?.toInt() ?? 0;
      currentHumidity = (cur['humidity'] as num?)?.toDouble();
      currentWindSpeed = (cur['wind'] as num?)?.toDouble();
    }
  }

  void _applyRawToState(Map<String, dynamic> raw, {required bool isArchive}) {
    _parseCurrent(raw);
    _parseDaily(raw, isArchive: isArchive);
    _parseHourly(raw, isArchive: isArchive);
  }

  void _parseCurrent(Map<String, dynamic> raw) {
    // legacy/current_weather

    final cw = raw['current_weather'];
    if (cw is Map) {
      final temp = (cw['temperature'] as num?)?.toDouble();
      currentTemp = (temp != null && temp.isFinite) ? temp : currentTemp;
      final wind = (cw['wind_speed'] as num?)?.toDouble();
      currentWindSpeed = (wind != null && wind.isFinite) ? wind : currentWindSpeed;
      currentCode = (cw['weather_code'] as num?)?.toInt() ?? currentCode;
    }
  }

  void _parseDaily(Map<String, dynamic> raw, {required bool isArchive}) {
    final daily = raw['daily'];
    if (daily is! Map) return;

    final List times = (daily['time'] as List?) ?? const [];
    final List codes = (daily['weather_code'] as List?) ?? (daily['weathercode'] as List?) ?? const [];
    final List tmax = (daily['temperature_2m_max'] as List?) ?? const [];
    final List tmin = (daily['temperature_2m_min'] as List?) ?? const [];

    // forecast có precip_probability_max, archive có precipitation_sum
    final List? ppMax = daily['precipitation_probability_max'] as List?;
    final List? precipSum = daily['precipitation_sum'] as List?;
    
    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.parse(times[i].toString());
      final key = DateHelper.normalizeKey(dt);
      final code = (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0;
      final mxRaw = (tmax.elementAtOrNull(i) as num?)?.toDouble();
      final mx = (mxRaw != null && mxRaw.isFinite) ? mxRaw : 0.0;
      final mnRaw = (tmin.elementAtOrNull(i) as num?)?.toDouble();
      final mn = (mnRaw != null && mnRaw.isFinite) ? mnRaw : 0.0;
      
      // Ưu tiên precip_probability_max từ forecast, nếu không có thì tính từ precipitation_sum
      final ppRaw = (ppMax?.elementAtOrNull(i) as num?)?.toDouble();
      double? pp = (ppRaw != null && ppRaw.isFinite) ? ppRaw : null;
      
      // Nếu là archive và không có precip_probability_max, tính từ precipitation_sum
      if (isArchive && pp == null && precipSum != null) {
        final sumRaw = (precipSum.elementAtOrNull(i) as num?)?.toDouble();
        final sum = (sumRaw != null && sumRaw.isFinite) ? sumRaw : 0.0;
        // Nếu có mưa (> 0.1mm), tính xác suất tương đối dựa trên lượng mưa
        // 0-1mm: 30%, 1-5mm: 60%, 5-10mm: 80%, >10mm: 95%
        if (sum > 0.1) {
          if (sum <= 1.0) {
            pp = 30.0;
          } else if (sum <= 5.0) {
            pp = 60.0;
          } else if (sum <= 10.0) {
            pp = 80.0;
          } else {
            pp = 95.0;
          }
        } else {
          pp = 0.0; // Không mưa
        }
      }

      // Merge strategy: nếu đã có daily từ archive rồi, forecast sẽ override cho các ngày gần đây/tương lai
      monthlyDaily[key] = WeatherDaily(
        date: DateHelper.dateOnly(dt),
        weatherCode: code,
        tempMax: mx,
        tempMin: mn,
        precipProbMax: pp,
      );
    }
  }

  void _parseHourly(Map<String, dynamic> raw, {required bool isArchive}) {
    final hourly = raw['hourly'];
    if (hourly is! Map) return;

    final List times = (hourly['time'] as List?) ?? const [];
    final List temps = (hourly['temperature_2m'] as List?) ?? const [];
    final List codes = (hourly['weather_code'] as List?) ?? (hourly['weathercode'] as List?) ?? const [];

    final List? pp = hourly['precipitation_probability'] as List?;
    final List? pr = hourly['precipitation'] as List?;
    final List? hum = hourly['relative_humidity_2m'] as List?;
    final List? wind = hourly['wind_speed_10m'] as List?;

    for (int i = 0; i < times.length; i++) {
      final t = DateTime.parse(times[i].toString());
      final key = DateHelper.normalizeKey(t);
      
      // Sanitize các giá trị để tránh NaN/Infinity
      final tempRaw = (temps.elementAtOrNull(i) as num?)?.toDouble();
      final temp = (tempRaw != null && tempRaw.isFinite) ? tempRaw : 0.0;
      
      final ppRaw = (pp?.elementAtOrNull(i) as num?)?.toDouble();
      final ppVal = (ppRaw != null && ppRaw.isFinite) ? ppRaw : null;
      
      final prRaw = (pr?.elementAtOrNull(i) as num?)?.toDouble();
      final prVal = (prRaw != null && prRaw.isFinite) ? prRaw : null;
      
      final humRaw = (hum?.elementAtOrNull(i) as num?)?.toDouble();
      final humVal = (humRaw != null && humRaw.isFinite) ? humRaw : null;
      
      final windRaw = (wind?.elementAtOrNull(i) as num?)?.toDouble();
      final windVal = (windRaw != null && windRaw.isFinite) ? windRaw : null;
      
      final item = WeatherHourly(
        time: t,
        temperature: temp,
        weatherCode: (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0,
        precipitationProbability: ppVal,
        precipitation: prVal,
        humidity: humVal,
        windSpeed: windVal,
      );

      final list = hourlyByDay.putIfAbsent(key, () => <WeatherHourly>[]);
      list.add(item);
    }

    // ensure order
    for (final list in hourlyByDay.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }

    _deriveCurrentFromHourlyIfNeeded();
  }

  /// Parse daily data vào map được cung cấp (dùng cho prefetch)
  void _parseDailyToMap(Map<String, dynamic> raw, Map<DateTime, WeatherDaily> targetMap, {required bool isArchive}) {
    final daily = raw['daily'];
    if (daily is! Map) return;

    final List times = (daily['time'] as List?) ?? const [];
    final List codes = (daily['weather_code'] as List?) ?? (daily['weathercode'] as List?) ?? const [];
    final List tmax = (daily['temperature_2m_max'] as List?) ?? const [];
    final List tmin = (daily['temperature_2m_min'] as List?) ?? const [];

    // forecast có precip_probability_max, archive có precipitation_sum
    final List? ppMax = daily['precipitation_probability_max'] as List?;
    final List? precipSum = daily['precipitation_sum'] as List?;
    
    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.parse(times[i].toString());
      final key = DateHelper.normalizeKey(dt);
      final code = (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0;
      final mxRaw = (tmax.elementAtOrNull(i) as num?)?.toDouble();
      final mx = (mxRaw != null && mxRaw.isFinite) ? mxRaw : 0.0;
      final mnRaw = (tmin.elementAtOrNull(i) as num?)?.toDouble();
      final mn = (mnRaw != null && mnRaw.isFinite) ? mnRaw : 0.0;
      
      // Ưu tiên precip_probability_max từ forecast, nếu không có thì tính từ precipitation_sum
      final ppRaw = (ppMax?.elementAtOrNull(i) as num?)?.toDouble();
      double? pp = (ppRaw != null && ppRaw.isFinite) ? ppRaw : null;
      
      // Nếu là archive và không có precip_probability_max, tính từ precipitation_sum
      if (isArchive && pp == null && precipSum != null) {
        final sumRaw = (precipSum.elementAtOrNull(i) as num?)?.toDouble();
        final sum = (sumRaw != null && sumRaw.isFinite) ? sumRaw : 0.0;
        // Nếu có mưa (> 0.1mm), tính xác suất tương đối dựa trên lượng mưa
        // 0-1mm: 30%, 1-5mm: 60%, 5-10mm: 80%, >10mm: 95%
        if (sum > 0.1) {
          if (sum <= 1.0) {
            pp = 30.0;
          } else if (sum <= 5.0) {
            pp = 60.0;
          } else if (sum <= 10.0) {
            pp = 80.0;
          } else {
            pp = 95.0;
          }
        } else {
          pp = 0.0; // Không mưa
        }
      }

      targetMap[key] = WeatherDaily(
        date: DateHelper.dateOnly(dt),
        weatherCode: code,
        tempMax: mx,
        tempMin: mn,
        precipProbMax: pp,
      );
    }
  }

  /// Parse hourly data vào map được cung cấp (dùng cho prefetch)
  void _parseHourlyToMap(Map<String, dynamic> raw, Map<DateTime, List<WeatherHourly>> targetMap, {required bool isArchive}) {
    final hourly = raw['hourly'];
    if (hourly is! Map) return;

    final List times = (hourly['time'] as List?) ?? const [];
    final List temps = (hourly['temperature_2m'] as List?) ?? const [];
    final List codes = (hourly['weather_code'] as List?) ?? (hourly['weathercode'] as List?) ?? const [];

    final List? pp = hourly['precipitation_probability'] as List?;
    final List? pr = hourly['precipitation'] as List?;
    final List? hum = hourly['relative_humidity_2m'] as List?;
    final List? wind = hourly['wind_speed_10m'] as List?;

    for (int i = 0; i < times.length; i++) {
      final t = DateTime.parse(times[i].toString());
      final key = DateHelper.normalizeKey(t);
      
      // Sanitize các giá trị để tránh NaN/Infinity
      final tempRaw = (temps.elementAtOrNull(i) as num?)?.toDouble();
      final temp = (tempRaw != null && tempRaw.isFinite) ? tempRaw : 0.0;
      
      final ppRaw = (pp?.elementAtOrNull(i) as num?)?.toDouble();
      final ppVal = (ppRaw != null && ppRaw.isFinite) ? ppRaw : null;
      
      final prRaw = (pr?.elementAtOrNull(i) as num?)?.toDouble();
      final prVal = (prRaw != null && prRaw.isFinite) ? prRaw : null;
      
      final humRaw = (hum?.elementAtOrNull(i) as num?)?.toDouble();
      final humVal = (humRaw != null && humRaw.isFinite) ? humRaw : null;
      
      final windRaw = (wind?.elementAtOrNull(i) as num?)?.toDouble();
      final windVal = (windRaw != null && windRaw.isFinite) ? windRaw : null;
      
      final item = WeatherHourly(
        time: t,
        temperature: temp,
        weatherCode: (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0,
        precipitationProbability: ppVal,
        precipitation: prVal,
        humidity: humVal,
        windSpeed: windVal,
      );

      final list = targetMap.putIfAbsent(key, () => <WeatherHourly>[]);
      list.add(item);
    }

    // ensure order
    for (final list in targetMap.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
  }

  void _deriveCurrentFromHourlyIfNeeded() {
    // Lấy điểm hourly gần nhất so với thời điểm hiện tại để lấy độ ẩm (và fallback nhiệt độ/gió).
    final now = DateTime.now();
    final key = DateHelper.normalizeKey(now);
    final list = hourlyByDay[key];
    if (list == null || list.isEmpty) return;

    WeatherHourly nearest = list.first;
    int best = (nearest.time.difference(now)).abs().inMinutes;

    for (final h in list) {
      final diff = (h.time.difference(now)).abs().inMinutes;
      if (diff < best) {
        best = diff;
        nearest = h;
      }
    }

    currentHumidity ??= nearest.humidity;
    currentWindSpeed ??= nearest.windSpeed;
    if (currentTemp == null && nearest.temperature.isFinite) {
      currentTemp = nearest.temperature;
    }
  }

  /// Dữ liệu chart: hourly temps của selected day.
  List<double> get selectedDayTemps {
    final d = selectedDay;
    if (d == null) return const [];
    final list = hourlyByDay[DateHelper.normalizeKey(d)];
    if (list == null) return const [];
    return list.map((e) => e.temperature).where((v) => v.isFinite).toList();
  }

  List<DateTime> get selectedDayTimes {
    final d = selectedDay;
    if (d == null) return const [];
    final list = hourlyByDay[DateHelper.normalizeKey(d)];
    if (list == null) return const [];
    return list.map((e) => e.time).toList();
  }

  /// Chia Sáng/Chiều/Tối:
  /// - Sáng: 06-11
  /// - Chiều: 12-17
  /// - Tối: 18-23 + 00-05 (ngày hôm sau)
  List<DayPartWeather> buildDayParts(DateTime day) {
    final key = DateHelper.normalizeKey(day);
    final todayList = hourlyByDay[key] ?? const <WeatherHourly>[];

    final morning = _aggregate(todayList.where((h) => h.time.hour >= 6 && h.time.hour <= 11).toList(), 'Sáng');
    final afternoon = _aggregate(todayList.where((h) => h.time.hour >= 12 && h.time.hour <= 17).toList(), 'Chiều');

    final nextDayKey = DateHelper.normalizeKey(day.add(const Duration(days: 1)));
    final nextList = hourlyByDay[nextDayKey] ?? const <WeatherHourly>[];
    final eveningList = [
      ...todayList.where((h) => h.time.hour >= 18 && h.time.hour <= 23),
      ...nextList.where((h) => h.time.hour >= 0 && h.time.hour <= 5),
    ].toList();
    final evening = _aggregate(eveningList, 'Tối');

    return [morning, afternoon, evening];
  }

  DayPartWeather _aggregate(List<WeatherHourly> items, String label) {
    if (items.isEmpty) {
      return DayPartWeather(label: label, weatherCode: 0, tempAvg: double.nan, precipProbAvg: null, precipitationAvg: null);
    }

    // code đại diện: ưu tiên giờ đại diện (09/14/20) nếu có, nếu không lấy mode.
    int targetHour;
    if (label == 'Sáng') targetHour = 9;
    else if (label == 'Chiều') targetHour = 14;
    else targetHour = 20;

    final rep = items.firstWhereOrNull((e) => e.time.hour == targetHour);
    final code = rep?.weatherCode ?? _mode(items.map((e) => e.weatherCode).toList());

    final temps = items.map((e) => e.temperature).where((v) => v.isFinite).toList();
    final tempAvg = temps.isEmpty ? double.nan : temps.reduce((a, b) => a + b) / temps.length;

    final probs = items.map((e) => e.precipitationProbability).whereType<double>().toList();
    final precipProbAvg = probs.isEmpty ? null : probs.reduce((a, b) => a + b) / probs.length;

    final precs = items.map((e) => e.precipitation).whereType<double>().toList();
    final precipitationAvg = precs.isEmpty ? null : precs.reduce((a, b) => a + b) / precs.length;

    return DayPartWeather(
      label: label,
      weatherCode: code,
      tempAvg: tempAvg,
      precipProbAvg: precipProbAvg,
      precipitationAvg: precipitationAvg,
    );
  }

  int _mode(List<int> list) {
    final counts = <int, int>{};
    for (final v in list) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    int best = list.first;
    int bestCount = 0;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        best = e.key;
        bestCount = e.value;
      }
    }
    return best;
  }
}

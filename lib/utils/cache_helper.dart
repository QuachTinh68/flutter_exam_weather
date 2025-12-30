import 'package:hive/hive.dart';

/// Cache helper với TTL (Time To Live)
class CacheHelper {
  static const String _ttlPrefix = 'ttl:';
  static const String _dataPrefix = 'data:';

  /// Lưu dữ liệu với TTL (giờ)
  static Future<void> putWithTTL(
    String key,
    String value, {
    required int ttlHours,
  }) async {
    final box = Hive.box('cache');
    final expiresAt = DateTime.now().add(Duration(hours: ttlHours));
    
    await box.put('$_ttlPrefix$key', expiresAt.toIso8601String());
    await box.put('$_dataPrefix$key', value);
  }

  /// Lấy dữ liệu nếu chưa hết hạn
  static String? getIfValid(String key) {
    final box = Hive.box('cache');
    final ttlKey = '$_ttlPrefix$key';
    final dataKey = '$_dataPrefix$key';

    final expiresAtStr = box.get(ttlKey);
    if (expiresAtStr is! String) return null;

    try {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isAfter(expiresAt)) {
        // Đã hết hạn, xóa cache
        box.delete(ttlKey);
        box.delete(dataKey);
        return null;
      }
    } catch (_) {
      return null;
    }

    final data = box.get(dataKey);
    return data is String ? data : null;
  }

  /// Kiểm tra cache còn hợp lệ không
  static bool isValid(String key) {
    final box = Hive.box('cache');
    final ttlKey = '$_ttlPrefix$key';
    final expiresAtStr = box.get(ttlKey);
    if (expiresAtStr is! String) return false;

    try {
      final expiresAt = DateTime.parse(expiresAtStr);
      return DateTime.now().isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }

  /// Xóa cache
  static Future<void> delete(String key) async {
    final box = Hive.box('cache');
    await box.delete('$_ttlPrefix$key');
    await box.delete('$_dataPrefix$key');
  }

  /// Tính TTL cho forecast (6-12h) và history (vài ngày)
  static int getTTLForMonth(DateTime monthStart, DateTime now) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    
    // Tháng quá khứ: cache 7 ngày
    if (monthEnd.isBefore(now)) {
      return 7 * 24; // 7 ngày
    }
    
    // Tháng hiện tại: cache 6 giờ (forecast thay đổi thường xuyên)
    if (monthStart.year == now.year && monthStart.month == now.month) {
      return 6; // 6 giờ
    }
    
    // Tháng tương lai: cache 12 giờ
    return 12; // 12 giờ
  }
}


import 'package:intl/intl.dart';

class DateHelper {
  static final DateFormat ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat hm = DateFormat('HH:mm');
  static final DateFormat monthTitle = DateFormat('MMMM yyyy');

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  static String toYmd(DateTime d) => ymd.format(d);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  /// For map keys: normalize to noon to avoid DST edgecases.
  static DateTime normalizeKey(DateTime d) => DateTime(d.year, d.month, d.day, 12);
}

import 'package:intl/intl.dart';

DateTime startOfIsoWeek(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}

String formatWeekRange(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final dayFmt = DateFormat('d MMM', 'es');
  final yearFmt = DateFormat('d MMM yyyy', 'es');
  return '${dayFmt.format(weekStart)} – ${yearFmt.format(weekEnd)}';
}

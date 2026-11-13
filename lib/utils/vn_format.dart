const List<String> kWeekdayLong = [
  'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
];

const List<String> kWeekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String two(int n) => n.toString().padLeft(2, '0');

/// 08:52:24
String formatClock(DateTime t) =>
    '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';

/// Thứ Năm, ngày 12 tháng 11 năm 2026
String formatDateVn(DateTime t) =>
    '${kWeekdayLong[t.weekday - 1]}, ngày ${t.day} tháng ${t.month} năm ${t.year}';

/// 1:05:09 hoặc 05:09 (cho hẹn giờ)
String formatDuration(Duration d) {
  final neg = d.isNegative;
  if (neg) d = -d;
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final body = h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  return neg ? '-$body' : body;
}

/// 01:05.37 (cho bấm giờ, có phần trăm giây)
String formatStopwatch(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final cs = (d.inMilliseconds % 1000) ~/ 10;
  final body = '${two(m)}:${two(s)}.${two(cs)}';
  return h > 0 ? '$h:$body' : body;
}

/// Mô tả lặp lại của báo thức.
String describeDays(Set<int> days) {
  if (days.isEmpty) return 'Một lần';
  if (days.length == 7) return 'Hằng ngày';
  final weekdays = {1, 2, 3, 4, 5};
  if (days.length == 5 && days.containsAll(weekdays)) return 'Thứ Hai - Thứ Sáu';
  if (days.length == 2 && days.containsAll({6, 7})) return 'Cuối tuần';
  final sorted = days.toList()..sort();
  return sorted.map((d) => kWeekdayShort[d - 1]).join(', ');
}

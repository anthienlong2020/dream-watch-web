import '../themes/season_theme.dart';

/// Loại ngày nhớ → biểu tượng và cách gọi "năm thứ mấy".
const Map<String, (String, String)> kSpecialKinds = {
  // id: (emoji, tên)
  'sinhNhat': ('🎂', 'Sinh nhật'),
  'gio': ('🕯️', 'Ngày giỗ'),
  'kyNiem': ('💞', 'Kỷ niệm'),
  'le': ('🧧', 'Lễ, Tết'),
  'khac': ('⭐', 'Khác'),
};

/// Một "ngày nhớ" lặp lại mỗi năm, theo âm lịch hoặc dương lịch:
/// sinh nhật, ngày giỗ, kỷ niệm ngày cưới, Tết...
class SpecialDay {
  final int id;
  String name;
  String kind; // khoá trong kSpecialKinds
  bool lunar; // true = âm lịch
  int day, month;
  int? year; // năm bắt đầu (năm sinh, năm mất, năm cưới) – không bắt buộc
  int remindBefore; // nhắc trước bao nhiêu ngày (0 = đúng ngày); -1 = không nhắc
  int remindHour; // giờ nhắc trong ngày
  bool onClock; // hiện đếm ngược trên mặt đồng hồ

  SpecialDay({
    required this.id,
    required this.name,
    this.kind = 'khac',
    this.lunar = true,
    required this.day,
    required this.month,
    this.year,
    this.remindBefore = 0,
    this.remindHour = 8,
    this.onClock = false,
  });

  String get emoji => (kSpecialKinds[kind] ?? kSpecialKinds['khac']!).$1;

  /// "Âm 10/3" hoặc "Dương 20/11".
  String get dateText => '${lunar ? 'Âm' : 'Dương'} $day/$month${year != null ? '/$year' : ''}';

  /// Ngày dương lịch của lần tới (tính cả hôm nay).
  DateTime nextFrom(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    if (lunar) {
      final ly = solarToLunar(today).year;
      for (var y = ly - 1; y <= ly + 2; y++) {
        final d = lunarDateOf(day, month, y);
        if (!d.isBefore(today)) return d;
      }
      return lunarDateOf(day, month, ly + 1);
    }
    for (var y = today.year; y <= today.year + 1; y++) {
      final d = solarDateOf(day, month, y);
      if (!d.isBefore(today)) return d;
    }
    return solarDateOf(day, month, today.year + 1);
  }

  /// Năm (âm hoặc dương) của lần tới — để tính "tròn N tuổi", "giỗ lần thứ N".
  int occurrenceYear(DateTime next) => lunar ? solarToLunar(next).year : next.year;

  /// Ví dụ "tròn 30 tuổi", "giỗ lần thứ 5", "10 năm"; null nếu không có năm.
  String? yearsText(DateTime next) {
    final y = year;
    if (y == null) return null;
    final n = occurrenceYear(next) - y;
    if (n <= 0) return null;
    switch (kind) {
      case 'sinhNhat':
        return 'tròn $n tuổi';
      case 'gio':
        return 'giỗ lần thứ $n';
      case 'kyNiem':
        return '$n năm';
      default:
        return 'năm thứ $n';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'lunar': lunar,
        'day': day,
        'month': month,
        if (year != null) 'year': year,
        'remindBefore': remindBefore,
        'remindHour': remindHour,
        'onClock': onClock,
      };

  factory SpecialDay.fromJson(Map<String, dynamic> j) => SpecialDay(
        id: (j['id'] as num).toInt(),
        name: (j['name'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'khac',
        lunar: (j['lunar'] as bool?) ?? true,
        day: (j['day'] as num).toInt(),
        month: (j['month'] as num).toInt(),
        year: (j['year'] as num?)?.toInt(),
        remindBefore: (j['remindBefore'] as num?)?.toInt() ?? 0,
        remindHour: (j['remindHour'] as num?)?.toInt() ?? 8,
        onClock: (j['onClock'] as bool?) ?? false,
      );

  SpecialDay copy() => SpecialDay.fromJson(toJson());
}

/// Ngày âm [day]/[month] năm âm [year] → dương lịch. Tháng thiếu (29 ngày) mà
/// chọn ngày 30 thì lấy ngày 29, như cách tính ngày giỗ thường dùng.
DateTime lunarDateOf(int day, int month, int year) {
  if (day == 30) {
    final d = lunarToSolar(30, month, year);
    final l = solarToLunar(d);
    if (l.day == 30 && !l.leap) return d;
    return lunarToSolar(29, month, year);
  }
  return lunarToSolar(day, month, year);
}

/// Ngày dương; 29/2 vào năm không nhuận → 28/2, ngày 31 tháng thiếu → ngày cuối tháng.
DateTime solarDateOf(int day, int month, int year) {
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > last ? last : day);
}

/// Số ngày từ [from] (theo ngày) tới [to].
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// "Hôm nay", "Ngày mai", "Còn 23 ngày".
String countdownText(int days) => days == 0 ? 'Hôm nay' : (days == 1 ? 'Ngày mai' : 'Còn $days ngày');

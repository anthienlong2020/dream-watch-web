import 'package:flutter/material.dart';

import '../themes/season_theme.dart';
import '../utils/vn_format.dart';

/// Tab "Lịch": lịch tháng dương lịch, mỗi ô có ngày âm nhỏ bên dưới,
/// đánh dấu ngày lễ; chạm một ngày để xem âm lịch, can chi và lễ của ngày đó.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month; // ngày 1 của tháng đang xem
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _go(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _today() {
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(now.year, now.month, now.day);
      _month = DateTime(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lunarOfMonth = solarToLunar(_month);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch'),
        actions: [
          TextButton.icon(
            onPressed: _today,
            icon: const Icon(Icons.today),
            label: const Text('Hôm nay'),
          ),
        ],
      ),
      body: GestureDetector(
        // vuốt ngang để đổi tháng
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _go(1);
          if (v > 200) _go(-1);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Column(
                    children: [
                      Text('Tháng ${_month.month} năm ${_month.year}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Năm ${canChiYear(lunarOfMonth.year)} '
                          '${kZodiacEmoji[zodiacOfYear(lunarOfMonth.year)]}',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _go(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 6),
            _MonthGrid(
              month: _month,
              selected: _selected,
              onTap: (d) => setState(() {
                _selected = d;
                if (d.month != _month.month) _month = DateTime(d.year, d.month);
              }),
            ),
            const SizedBox(height: 12),
            _DayDetail(day: _selected),
            const SizedBox(height: 12),
            const _Upcoming(),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Lưới tháng
// =====================================================================

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;
  const _MonthGrid({required this.month, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // tuần bắt đầu từ Thứ Hai
    final first = month.subtract(Duration(days: month.weekday - 1));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((month.weekday - 1 + daysInMonth) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(kWeekdayShort[i],
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: i == 6 ? const Color(0xFFFF8A80) : cs.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: _DayCell(
                    day: DateTime(first.year, first.month, first.day + r * 7 + c),
                    inMonth: DateTime(first.year, first.month, first.day + r * 7 + c).month == month.month,
                    isToday: DateTime(first.year, first.month, first.day + r * 7 + c) == today,
                    isSelected: DateTime(first.year, first.month, first.day + r * 7 + c) == selected,
                    onTap: onTap,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth, isToday, isSelected;
  final ValueChanged<DateTime> onTap;
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = solarToLunar(day);
    final events = eventsOn(day, l);
    final holiday = events.any((e) => e.dayOff);
    final sunday = day.weekday == DateTime.sunday;
    var solarColor = (holiday || sunday) ? const Color(0xFFFF8A80) : cs.onSurface;
    if (!inMonth) solarColor = solarColor.withAlpha(89);
    final special = l.day == 1 || l.day == 15;
    final lunarText = l.day == 1 ? '${l.day}/${l.month}${l.leap ? 'N' : ''}' : '${l.day}';
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected
            ? cs.primary.withAlpha(71)
            : (isToday ? cs.primary.withAlpha(31) : Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isToday ? BorderSide(color: cs.primary, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(day),
          child: SizedBox(
            height: 54,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${day.day}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: solarColor)),
                      Text(lunarText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: special ? FontWeight.w700 : FontWeight.normal,
                            color: (special ? const Color(0xFFFFD54F) : cs.onSurfaceVariant)
                                .withAlpha(inMonth ? 255 : 89),
                          )),
                    ],
                  ),
                ),
                if (events.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 3,
                    child: Text(events.first.emoji, style: const TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Chi tiết ngày đang chọn
// =====================================================================

class _DayDetail extends StatelessWidget {
  final DateTime day;
  const _DayDetail({required this.day});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = solarToLunar(day);
    final events = eventsOn(day, l);
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // tờ lịch nhỏ
            Container(
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(kWeekdayLong[day.weekday - 1], style: tt.labelMedium),
                  Text('${day.day}', style: tt.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Âm: ${l.day}/${l.month}', style: const TextStyle(color: Color(0xFFFFD54F))),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatDateVn(day), style: tt.titleSmall),
                  const SizedBox(height: 6),
                  Text('Âm lịch: ngày ${l.day} tháng ${l.month}${l.leap ? ' (nhuận)' : ''} '
                      'năm ${canChiYear(l.year)} ${kZodiacEmoji[zodiacOfYear(l.year)]}'),
                  const SizedBox(height: 2),
                  Text('Ngày ${canChiDay(l.jd)} · tháng ${canChiMonth(l.month, l.year)}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  for (final e in events) ...[
                    const SizedBox(height: 6),
                    Text('${e.emoji} ${e.name}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: e.dayOff ? const Color(0xFFFF8A80) : cs.primary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sắp tới": vài ngày lễ kế tiếp và còn bao nhiêu ngày.
class _Upcoming extends StatelessWidget {
  const _Upcoming();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final list = <(DateTime, CalEvent)>[];
    for (var i = 1; i <= 400 && list.length < 5; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      for (final e in eventsOn(d, solarToLunar(d))) {
        if (list.length < 5) list.add((d, e));
      }
    }
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sắp tới', style: tt.titleSmall),
            for (final (d, e) in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(e.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(e.name),
                subtitle: Text('${kWeekdayShort[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}'),
                trailing: Text('còn ${d.difference(start).inDays} ngày'),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Ngày lễ
// =====================================================================

class CalEvent {
  final String name;
  final String emoji;
  final bool dayOff; // ngày nghỉ lễ chính thức → tô đỏ
  const CalEvent(this.name, this.emoji, {this.dayOff = false});
}

/// Lễ theo dương lịch: (tháng, ngày).
const Map<(int, int), CalEvent> kSolarEvents = {
  (1, 1): CalEvent('Tết Dương lịch', '🎆', dayOff: true),
  (2, 14): CalEvent('Lễ Tình nhân', '💝'),
  (3, 8): CalEvent('Quốc tế Phụ nữ', '💐'),
  (4, 30): CalEvent('Ngày Thống nhất', '🇻🇳', dayOff: true),
  (5, 1): CalEvent('Quốc tế Lao động', '🛠️', dayOff: true),
  (6, 1): CalEvent('Quốc tế Thiếu nhi', '🎈'),
  (9, 2): CalEvent('Quốc khánh', '🇻🇳', dayOff: true),
  (10, 20): CalEvent('Phụ nữ Việt Nam', '🌹'),
  (10, 31): CalEvent('Halloween', '🎃'),
  (11, 20): CalEvent('Nhà giáo Việt Nam', '📚'),
  (12, 24): CalEvent('Đêm Giáng sinh', '🎄'),
  (12, 25): CalEvent('Giáng sinh', '🎄'),
};

/// Lễ theo âm lịch: (tháng, ngày).
const Map<(int, int), CalEvent> kLunarEvents = {
  (1, 1): CalEvent('Tết Nguyên Đán – mùng 1', '🧧', dayOff: true),
  (1, 2): CalEvent('Tết – mùng 2', '🧧', dayOff: true),
  (1, 3): CalEvent('Tết – mùng 3', '🧧', dayOff: true),
  (1, 15): CalEvent('Rằm tháng Giêng', '🏮'),
  (3, 3): CalEvent('Tết Hàn thực', '🍡'),
  (3, 10): CalEvent('Giỗ Tổ Hùng Vương', '🏯', dayOff: true),
  (4, 15): CalEvent('Lễ Phật đản', '🪷'),
  (5, 5): CalEvent('Tết Đoan Ngọ', '🍑'),
  (7, 15): CalEvent('Lễ Vu Lan', '🪷'),
  (8, 15): CalEvent('Tết Trung Thu', '🥮'),
  (10, 15): CalEvent('Rằm tháng Mười', '🌕'),
  (12, 23): CalEvent('Ông Công Ông Táo', '🐟'),
};

/// Các lễ của một ngày (âm lịch tháng nhuận không tính lễ).
List<CalEvent> eventsOn(DateTime d, LunarDate l) {
  final out = <CalEvent>[];
  final s = kSolarEvents[(d.month, d.day)];
  if (s != null) out.add(s);
  if (!l.leap) {
    final x = kLunarEvents[(l.month, l.day)];
    if (x != null) out.add(x);
    // Giao thừa: ngày cuối cùng của tháng Chạp
    if (l.month == 12 && solarToLunar(DateTime(d.year, d.month, d.day + 1)).day == 1) {
      out.add(const CalEvent('Giao thừa', '🎇'));
    }
  }
  if (d.month == 5 && d == nthWeekday(d.year, 5, DateTime.sunday, 2)) {
    out.add(const CalEvent('Ngày của Mẹ', '💐'));
  }
  if (d.month == 6 && d == nthWeekday(d.year, 6, DateTime.sunday, 3)) {
    out.add(const CalEvent('Ngày của Cha', '👔'));
  }
  return out;
}

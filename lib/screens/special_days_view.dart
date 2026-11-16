import 'package:flutter/material.dart';

import '../models/special_day.dart';
import '../services/app_state.dart';
import '../themes/season_theme.dart';
import '../utils/vn_format.dart';

/// "Ngày nhớ": sinh nhật, ngày giỗ, kỷ niệm... theo âm hoặc dương lịch, lặp mỗi năm.
/// Có đếm ngược, nhắc trước N ngày, và tuỳ chọn hiện đếm ngược trên mặt đồng hồ.
class SpecialDaysView extends StatelessWidget {
  const SpecialDaysView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, app.newSpecialDraft(), isNew: true),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngày'),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final now = DateTime.now();
          final items = [
            for (final d in app.specialDays) (d, d.nextFrom(now)),
          ]..sort((a, b) => a.$2.compareTo(b.$2));
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              const _MoonCard(),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Chưa có ngày nào.\nBấm "Thêm ngày" để thêm sinh nhật, ngày giỗ, kỷ niệm…',
                      textAlign: TextAlign.center),
                ),
              for (final (d, next) in items) _DayTile(day: d, next: next),
            ],
          );
        },
      ),
    );
  }
}

class _MoonCard extends StatelessWidget {
  const _MoonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Text('🌕', style: TextStyle(fontSize: 26)),
            title: const Text('Nhắc mùng 1 & Rằm'),
            subtitle: Text(app.remindMoon
                ? 'Lúc ${two(app.remindMoonHour)}:00${app.remindMoonEve ? ', nhắc cả hôm trước' : ''}'
                : 'Tắt'),
            value: app.remindMoon,
            onChanged: (v) => app.update(() => app.remindMoon = v),
          ),
          if (app.remindMoon)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Text('Giờ nhắc '),
                  DropdownButton<int>(
                    value: app.remindMoonHour,
                    items: [
                      for (var h = 4; h <= 22; h++) DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
                    ],
                    onChanged: (v) => app.update(() => app.remindMoonHour = v ?? 7),
                  ),
                  const Spacer(),
                  const Text('Hôm trước'),
                  Switch(
                    value: app.remindMoonEve,
                    onChanged: (v) => app.update(() => app.remindMoonEve = v),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final SpecialDay day;
  final DateTime next;
  const _DayTile({required this.day, required this.next});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final left = daysBetween(DateTime.now(), next);
    final years = day.yearsText(next);
    final l = solarToLunar(next);
    final when = '${kWeekdayShort[next.weekday - 1]}, ${next.day}/${next.month}/${next.year}'
        '${day.lunar ? '' : ' · âm ${l.day}/${l.month}'}';
    return Card(
      child: ListTile(
        onTap: () => _edit(context, day.copy()),
        leading: Text(day.emoji, style: const TextStyle(fontSize: 30)),
        title: Text(day.name.isEmpty ? '(chưa đặt tên)' : day.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          day.dateText,
          if (years != null) years,
          when,
          if (day.onClock) 'hiện trên đồng hồ',
        ].join(' · ')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(left == 0 ? '🎉' : '$left',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.primary)),
            Text(left == 0 ? 'Hôm nay' : 'ngày', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, SpecialDay d, {bool isNew = false}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _Editor(day: d, isNew: isNew),
  );
}

class _Editor extends StatefulWidget {
  final SpecialDay day;
  final bool isNew;
  const _Editor({required this.day, required this.isNew});

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final SpecialDay d = widget.day;
  late final TextEditingController _name = TextEditingController(text: d.name);
  late final TextEditingController _year = TextEditingController(text: d.year?.toString() ?? '');

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  void _save() {
    d.name = _name.text.trim().isEmpty ? (kSpecialKinds[d.kind]?.$2 ?? 'Ngày nhớ') : _name.text.trim();
    final y = int.tryParse(_year.text.trim());
    d.year = (y != null && y > 1800 && y < 2200) ? y : null;
    final maxDay = d.lunar ? 30 : DateTime(2024, d.month + 1, 0).day;
    if (d.day > maxDay) d.day = maxDay;
    app.saveSpecialDay(d);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final maxDay = d.lunar ? 30 : DateTime(2024, d.month + 1, 0).day;
    final next = d.nextFrom(DateTime.now());
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.isNew ? 'Thêm ngày nhớ' : 'Sửa ngày nhớ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in kSpecialKinds.entries)
                  ChoiceChip(
                    label: Text('${e.value.$1} ${e.value.$2}'),
                    selected: d.kind == e.key,
                    onSelected: (_) => setState(() => d.kind = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Tên',
                hintText: 'Ví dụ: Sinh nhật mẹ, Giỗ ông nội',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Âm lịch')),
                ButtonSegment(value: false, label: Text('Dương lịch')),
              ],
              selected: {d.lunar},
              onSelectionChanged: (v) => setState(() => d.lunar = v.first),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Ngày '),
                DropdownButton<int>(
                  value: d.day > maxDay ? maxDay : d.day,
                  items: [for (var i = 1; i <= maxDay; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) => setState(() => d.day = v ?? 1),
                ),
                const SizedBox(width: 16),
                const Text('Tháng '),
                DropdownButton<int>(
                  value: d.month,
                  items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) => setState(() => d.month = v ?? 1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Năm (nếu có)', isDense: true),
                  ),
                ),
              ],
            ),
            Text(
              'Lần tới: ${formatDateVn(next)} · ${countdownText(daysBetween(DateTime.now(), next))}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            if (d.lunar && d.day == 30)
              const Text('Tháng âm nào chỉ có 29 ngày thì tính vào ngày 29.',
                  style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Nhắc '),
                DropdownButton<int>(
                  value: d.remindBefore,
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('Không nhắc')),
                    DropdownMenuItem(value: 0, child: Text('Đúng ngày')),
                    DropdownMenuItem(value: 1, child: Text('Trước 1 ngày')),
                    DropdownMenuItem(value: 3, child: Text('Trước 3 ngày')),
                    DropdownMenuItem(value: 7, child: Text('Trước 1 tuần')),
                  ],
                  onChanged: (v) => setState(() => d.remindBefore = v ?? 0),
                ),
                const SizedBox(width: 12),
                if (d.remindBefore >= 0)
                  DropdownButton<int>(
                    value: d.remindHour,
                    items: [
                      for (var h = 4; h <= 22; h++) DropdownMenuItem(value: h, child: Text('lúc ${two(h)}:00')),
                    ],
                    onChanged: (v) => setState(() => d.remindHour = v ?? 8),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đếm ngược trên mặt đồng hồ'),
              subtitle: const Text('Nhiều ngày bật thì hiện ngày gần nhất'),
              value: d.onClock,
              onChanged: (v) => setState(() => d.onClock = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!widget.isNew)
                  TextButton.icon(
                    onPressed: () {
                      app.deleteSpecialDay(d);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xoá'),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Lưu')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

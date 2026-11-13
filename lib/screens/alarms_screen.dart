import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../services/app_state.dart';
import '../utils/vn_format.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo thức')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, app.newAlarmDraft(), isNew: true),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Thêm'),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (app.alarms.isEmpty) {
            return const _EmptyHint();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              const _WebNote(),
              for (final a in app.alarms) _AlarmTile(alarm: a),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Chưa có báo thức nào.\nBấm "Thêm" để tạo báo thức mới.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
    );
  }
}

class _WebNote extends StatelessWidget {
  const _WebNote();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFF1E2A3A),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Lưu ý: báo thức chỉ reo khi app đang mở (bản web: để tab mở, '
          'màn hình sáng). Bản cài trên Android/iOS sẽ reo được cả khi đóng app.',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final Alarm alarm;
  const _AlarmTile({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final until = app.timeUntil(alarm);
    final sub = StringBuffer(describeDays(alarm.days));
    if (alarm.label.isNotEmpty) sub.write(' · ${alarm.label}');
    if (until != null) {
      final h = until.inHours;
      final m = until.inMinutes % 60;
      sub.write('\nCòn ${h > 0 ? '$h giờ ' : ''}$m phút');
    }
    return Card(
      child: ListTile(
        onTap: () => _edit(context, alarm),
        title: Text(
          alarm.timeText,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w300,
            color: alarm.enabled ? Colors.white : Colors.white38,
          ),
        ),
        subtitle: Text(sub.toString()),
        isThreeLine: until != null,
        trailing: Switch(
          value: alarm.enabled,
          onChanged: (v) => app.toggleAlarm(alarm, v),
        ),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, Alarm source, {bool isNew = false}) async {
  // Sửa trên bản sao, chỉ lưu khi bấm "Lưu".
  final draft = Alarm.fromJson(source.toJson());
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AlarmEditor(draft: draft, isNew: isNew),
  );
}

class _AlarmEditor extends StatefulWidget {
  final Alarm draft;
  final bool isNew;
  const _AlarmEditor({required this.draft, required this.isNew});

  @override
  State<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<_AlarmEditor> {
  late final TextEditingController _label =
      TextEditingController(text: widget.draft.label);

  Alarm get a => widget.draft;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: a.hour, minute: a.minute),
      helpText: 'Chọn giờ báo thức',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        a.hour = t.hour;
        a.minute = t.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.isNew ? 'Báo thức mới' : 'Sửa báo thức',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _pickTime,
                child: Text(a.timeText,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300)),
              ),
            ),
            const Text('Lặp lại'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(kWeekdayShort[d - 1]),
                    selected: a.days.contains(d),
                    onSelected: (v) => setState(() {
                      if (v) {
                        a.days.add(d);
                      } else {
                        a.days.remove(d);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(describeDays(a.days),
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Tên báo thức (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Âm báo:'),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'alarm', label: Text('Chuông reo')),
                      ButtonSegment(value: 'alarm_soft', label: Text('Nhạc nhẹ')),
                    ],
                    selected: {a.sound},
                    onSelectionChanged: (v) {
                      setState(() => a.sound = v.first);
                      app.sound.preview(v.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!widget.isNew)
                  TextButton.icon(
                    onPressed: () {
                      app.deleteAlarm(a);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text('Xoá', style: TextStyle(color: Colors.redAccent)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Huỷ'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    a.label = _label.text.trim();
                    a.enabled = true;
                    app.saveAlarm(a);
                    Navigator.pop(context);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

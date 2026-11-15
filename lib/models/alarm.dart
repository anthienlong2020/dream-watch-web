/// Một báo thức. [days] chứa các thứ trong tuần (1 = Thứ Hai ... 7 = Chủ Nhật,
/// giống DateTime.weekday). [days] rỗng = chỉ reo một lần rồi tự tắt.
class Alarm {
  final int id;
  int hour;
  int minute;
  String label;
  Set<int> days;
  bool enabled;
  String sound; // 'alarm' hoặc 'alarm_soft'

  /// Lời nhắc (bản Pro): đọc [label] bằng giọng nói và/hoặc phát đoạn tự ghi âm.
  bool speak;
  bool hasVoice;

  /// Có phải lời nhắc (đọc chữ hoặc phát giọng ghi âm) thay vì chuông reo liên tục.
  bool get isReminder => (speak && label.isNotEmpty) || hasVoice;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    Set<int>? days,
    this.enabled = true,
    this.sound = 'alarm',
    this.speak = false,
    this.hasVoice = false,
  }) : days = days ?? <int>{};

  bool get isOnce => days.isEmpty;

  bool matches(DateTime t) {
    if (!enabled) return false;
    if (t.hour != hour || t.minute != minute) return false;
    return days.isEmpty || days.contains(t.weekday);
  }

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'days': days.toList()..sort(),
        'enabled': enabled,
        'sound': sound,
        'speak': speak,
        'hasVoice': hasVoice,
      };

  factory Alarm.fromJson(Map<String, dynamic> j) => Alarm(
        id: (j['id'] as num).toInt(),
        hour: (j['hour'] as num).toInt(),
        minute: (j['minute'] as num).toInt(),
        label: (j['label'] as String?) ?? '',
        days: ((j['days'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toSet(),
        enabled: (j['enabled'] as bool?) ?? true,
        sound: (j['sound'] as String?) ?? 'alarm',
        speak: (j['speak'] as bool?) ?? false,
        hasVoice: (j['hasVoice'] as bool?) ?? false,
      );
}

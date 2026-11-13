import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../chibi/chibi3d.dart';
import '../models/alarm.dart';
import '../models/clock_theme.dart';
import 'sound_service.dart';

/// Thông tin khi đang reo (báo thức hoặc hết giờ hẹn).
class RingInfo {
  final String title;
  final String subtitle;
  final Alarm? alarm; // null = hẹn giờ đếm ngược
  const RingInfo({required this.title, this.subtitle = '', this.alarm});
}

class _Snooze {
  final DateTime at;
  final Alarm alarm;
  _Snooze(this.at, this.alarm);
}

/// Toàn bộ trạng thái + cài đặt của app. Dùng chung qua biến [app].
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  final SoundService sound = SoundService.instance;

  // ---------- Giao diện ----------
  String themeId = 'khung_long';
  List<Uint8List?> customImages = List<Uint8List?>.filled(12, null);

  /// Chibi 3D theo từng vị trí (null = ảnh thường).
  List<ChibiSpec?> customChibi = List<ChibiSpec?>.filled(12, null);
  bool showTime = true;
  bool showDate = true;
  bool showRoman = true;
  bool keepAwake = true;
  bool showStars = true;
  bool inflate3d = true; // thổi phồng ảnh thường thành khối 3D
  bool spin360 = true; // ảnh 3D ở vị trí giờ + ở giữa quay tròn 360°

  // ---------- Tốc độ chuyển động (1.0 = mặc định, 0.25 = rất chậm, 2.0 = nhanh) ----------
  double hourSpeed = 1.0; // ảnh giờ + ảnh giữa đung đưa
  double minuteSpeed = 1.0; // ảnh phút nhảy bậc thang
  double secondSpeed = 1.0; // kim giây lướt

  /// Tên bộ cấu hình đang dùng (do người dùng đặt khi lưu / mở file).
  String? presetName;

  // ---------- Hình nền ----------
  List<Uint8List> backgrounds = [];
  int bgIntervalMin = 5; // đổi hình nền mỗi N phút
  double bgDim = 0.35; // độ tối phủ lên hình nền (0..0.8)

  // ---------- Âm báo mỗi giờ ----------
  bool chimeEnabled = true;
  /// 'chuong' = giai điệu, 'dem' = đánh số tiếng theo giờ, 'ca_hai' = cả hai
  String chimeMode = 'dem';
  bool chimeHalfHour = false;
  bool quietEnabled = true;
  int quietStart = 22; // từ 22 giờ
  int quietEnd = 6; // đến 6 giờ sáng
  double volume = 1.0;

  // ---------- Báo thức ----------
  List<Alarm> alarms = [];
  int _nextAlarmId = 1;
  final List<_Snooze> _snoozes = [];

  // ---------- Hẹn giờ (đếm ngược) ----------
  Duration timerTotal = const Duration(minutes: 5);
  Duration _timerLeftWhenPaused = const Duration(minutes: 5);
  DateTime? _timerEnd;
  bool get timerRunning => _timerEnd != null;

  // ---------- Bấm giờ ----------
  final Stopwatch stopwatch = Stopwatch();
  final List<Duration> laps = [];

  // ---------- Đang reo ----------
  RingInfo? ringing;
  Timer? _autoStop;

  /// Web: đã chạm màn hình lần đầu để mở khoá âm thanh chưa.
  bool started = !kIsWeb;

  Timer? _ticker;
  DateTime _lastMinute = _floorMinute(DateTime.now());

  static DateTime _floorMinute(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute);

  // ====================================================================
  // Khởi động / lưu trữ
  // ====================================================================

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    sound.volume = volume;
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    if (!kIsWeb) await _applyWakelock();
  }

  void _load() {
    final raw = _prefs.getString('settings');
    if (raw != null) {
      try {
        _applySettings(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    final rawAlarms = _prefs.getString('alarms');
    if (rawAlarms != null) {
      try {
        alarms = (jsonDecode(rawAlarms) as List)
            .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final a in alarms) {
          if (a.id >= _nextAlarmId) _nextAlarmId = a.id + 1;
        }
      } catch (_) {}
    }

    final rawBg = _prefs.getString('backgrounds');
    if (rawBg != null) {
      try {
        backgrounds = (jsonDecode(rawBg) as List)
            .map((e) => base64Decode(e as String))
            .toList();
      } catch (_) {}
    }

    final rawChibi = _prefs.getString('customChibi');
    if (rawChibi != null) {
      try {
        final list = jsonDecode(rawChibi) as List;
        for (var i = 0; i < 12 && i < list.length; i++) {
          customChibi[i] = ChibiSpec.fromJson(list[i]);
        }
      } catch (_) {}
    }

    final rawImages = _prefs.getString('customImages');
    if (rawImages != null) {
      try {
        final list = jsonDecode(rawImages) as List;
        for (var i = 0; i < 12 && i < list.length; i++) {
          final s = list[i] as String?;
          customImages[i] = s == null ? null : base64Decode(s);
        }
      } catch (_) {}
    }
  }

  Map<String, dynamic> _settingsMap() => {
        'presetName': presetName,
        'themeId': themeId,
        'showTime': showTime,
        'showDate': showDate,
        'showRoman': showRoman,
        'keepAwake': keepAwake,
        'showStars': showStars,
        'inflate3d': inflate3d,
        'spin360': spin360,
        'hourSpeed': hourSpeed,
        'minuteSpeed': minuteSpeed,
        'secondSpeed': secondSpeed,
        'bgIntervalMin': bgIntervalMin,
        'bgDim': bgDim,
        'chimeEnabled': chimeEnabled,
        'chimeMode': chimeMode,
        'chimeHalfHour': chimeHalfHour,
        'quietEnabled': quietEnabled,
        'quietStart': quietStart,
        'quietEnd': quietEnd,
        'volume': volume,
        'timerTotalSec': timerTotal.inSeconds,
      };

  void _applySettings(Map<String, dynamic> j) {
    presetName = (j['presetName'] as String?) ?? presetName;
    themeId = (j['themeId'] as String?) ?? themeId;
    showTime = (j['showTime'] as bool?) ?? showTime;
    showDate = (j['showDate'] as bool?) ?? showDate;
    showRoman = (j['showRoman'] as bool?) ?? showRoman;
    keepAwake = (j['keepAwake'] as bool?) ?? keepAwake;
    showStars = (j['showStars'] as bool?) ?? showStars;
    inflate3d = (j['inflate3d'] as bool?) ?? inflate3d;
    spin360 = (j['spin360'] as bool?) ?? spin360;
    hourSpeed = (j['hourSpeed'] as num?)?.toDouble() ?? hourSpeed;
    minuteSpeed = (j['minuteSpeed'] as num?)?.toDouble() ?? minuteSpeed;
    secondSpeed = (j['secondSpeed'] as num?)?.toDouble() ?? secondSpeed;
    bgIntervalMin = (j['bgIntervalMin'] as num?)?.toInt() ?? bgIntervalMin;
    bgDim = (j['bgDim'] as num?)?.toDouble() ?? bgDim;
    chimeEnabled = (j['chimeEnabled'] as bool?) ?? chimeEnabled;
    chimeMode = (j['chimeMode'] as String?) ?? chimeMode;
    chimeHalfHour = (j['chimeHalfHour'] as bool?) ?? chimeHalfHour;
    quietEnabled = (j['quietEnabled'] as bool?) ?? quietEnabled;
    quietStart = (j['quietStart'] as num?)?.toInt() ?? quietStart;
    quietEnd = (j['quietEnd'] as num?)?.toInt() ?? quietEnd;
    volume = (j['volume'] as num?)?.toDouble() ?? volume;
    final secs = (j['timerTotalSec'] as num?)?.toInt();
    if (secs != null && secs > 0) {
      timerTotal = Duration(seconds: secs);
      _timerLeftWhenPaused = timerTotal;
    }
  }

  void _saveSettings() {
    _prefs.setString('settings', jsonEncode(_settingsMap()));
  }

  void _saveAlarms() {
    _prefs.setString(
        'alarms', jsonEncode(alarms.map((a) => a.toJson()).toList()));
  }

  Future<bool> _saveImages() async {
    final ok = await _prefs.setString(
      'customImages',
      jsonEncode(customImages
          .map((b) => b == null ? null : base64Encode(b))
          .toList()),
    );
    final ok2 = await _prefs.setString(
      'customChibi',
      jsonEncode(customChibi.map((c) => c?.toJson()).toList()),
    );
    return ok && ok2;
  }

  /// Gọi khi đổi bất kỳ cài đặt nào.
  void update(VoidCallback change) {
    change();
    sound.volume = volume;
    _saveSettings();
    notifyListeners();
  }

  // ====================================================================
  // Khởi động trên web (mở khoá âm thanh + giữ màn hình sáng)
  // ====================================================================

  Future<void> startFromTap() async {
    started = true;
    notifyListeners();
    await sound.unlock();
    await _applyWakelock();
  }

  void setKeepAwake(bool v) {
    update(() => keepAwake = v);
    _applyWakelock();
  }

  Future<void> _applyWakelock() async {
    try {
      await WakelockPlus.toggle(enable: keepAwake);
    } catch (_) {}
  }

  // ====================================================================
  // Chủ đề
  // ====================================================================

  ClockTheme get theme {
    switch (themeId) {
      case 'con_giap':
        return buildZodiacTheme();
      case 'tu_chon':
        return buildCustomTheme(customImages, customChibi);
      default:
        return buildDinoTheme();
    }
  }

  /// Đặt ảnh cho một vị trí (0 = XII). Trả về false nếu lưu thất bại (đầy bộ nhớ).
  Future<bool> setCustomImage(int index, Uint8List? bytes, {ChibiSpec? chibi}) async {
    customImages[index] = bytes;
    customChibi[index] = chibi;
    themeId = 'tu_chon';
    _saveSettings();
    notifyListeners();
    try {
      return await _saveImages();
    } catch (_) {
      return false;
    }
  }

  Future<bool> setManyCustomImages(Map<int, Uint8List> images) async {
    images.forEach((i, b) {
      customImages[i] = b;
      customChibi[i] = null;
    });
    themeId = 'tu_chon';
    _saveSettings();
    notifyListeners();
    try {
      return await _saveImages();
    } catch (_) {
      return false;
    }
  }

  // ====================================================================
  // Hình nền
  // ====================================================================

  /// Không giới hạn số ảnh; chỉ bị chặn khi bộ nhớ đầy (bản web ~5 MB).
  static const int maxBackgrounds = 999;

  /// Hình nền đang hiện lúc [t] (đổi mỗi [bgIntervalMin] phút). null = nền đen.
  int? backgroundIndexAt(DateTime t) {
    if (backgrounds.isEmpty) return null;
    final minutes = t.millisecondsSinceEpoch ~/ 60000;
    return (minutes ~/ math.max(1, bgIntervalMin)) % backgrounds.length;
  }

  Future<bool> _saveBackgrounds() async {
    try {
      return await _prefs.setString(
          'backgrounds', jsonEncode(backgrounds.map(base64Encode).toList()));
    } catch (_) {
      return false;
    }
  }

  /// Thêm lần lượt từng hình nền cho tới khi bộ nhớ đầy.
  /// Trả về số ảnh đã thêm được.
  Future<int> addBackgrounds(List<Uint8List> images) async {
    var added = 0;
    for (final b in images) {
      if (backgrounds.length >= maxBackgrounds) break;
      backgrounds.add(b);
      if (await _saveBackgrounds()) {
        added++;
      } else {
        backgrounds.removeLast();
        await _saveBackgrounds();
        break;
      }
    }
    notifyListeners();
    return added;
  }

  Future<void> removeBackground(int index) async {
    backgrounds.removeAt(index);
    notifyListeners();
    await _saveBackgrounds();
  }

  // ====================================================================
  // Lưu / mở bộ cấu hình (file .dreamwatch trên thiết bị)
  // ====================================================================

  static const String presetExt = 'dreamwatch';

  /// Đóng gói ảnh giờ + ảnh nền + cài đặt (+ báo thức nếu muốn) thành 1 file.
  Uint8List exportPreset(String name, {bool withAlarms = false}) {
    presetName = name;
    _saveSettings();
    notifyListeners();
    final data = <String, dynamic>{
      'app': 'dream_watch',
      'version': 1,
      'name': name,
      'savedAt': DateTime.now().toIso8601String(),
      'settings': _settingsMap(),
      'customImages':
          customImages.map((b) => b == null ? null : base64Encode(b)).toList(),
      'customChibi': customChibi.map((c) => c?.toJson()).toList(),
      'backgrounds': backgrounds.map(base64Encode).toList(),
      if (withAlarms) 'alarms': alarms.map((a) => a.toJson()).toList(),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  /// Đọc file bộ cấu hình. Ném FormatException nếu không phải file của app.
  /// Trả về số ảnh nền KHÔNG lưu được vì bộ nhớ đầy (0 = lưu đủ).
  Future<int> importPreset(Uint8List bytes) async {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }
    final data = parsed;
    if (data == null || data['app'] != 'dream_watch') {
      throw const FormatException('Không phải file của Đồng hồ mộng mơ');
    }

    final settings = data['settings'];
    if (settings is Map<String, dynamic>) _applySettings(settings);
    presetName = (data['name'] as String?) ?? presetName;

    final imgs = (data['customImages'] as List?) ?? const [];
    customImages = List<Uint8List?>.generate(12, (i) {
      final v = i < imgs.length ? imgs[i] : null;
      return v is String ? base64Decode(v) : null;
    });
    final chibiList = (data['customChibi'] as List?) ?? const [];
    customChibi = List<ChibiSpec?>.generate(
        12, (i) => i < chibiList.length ? ChibiSpec.fromJson(chibiList[i]) : null);

    final alarmList = data['alarms'];
    if (alarmList is List) {
      alarms = alarmList
          .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final a in alarms) {
        if (a.id >= _nextAlarmId) _nextAlarmId = a.id + 1;
      }
      _saveAlarms();
    }

    sound.volume = volume;
    _saveSettings();
    try {
      await _saveImages();
    } catch (_) {}

    // Ảnh nền: thay toàn bộ, thêm lần lượt tới khi bộ nhớ đầy.
    final bgList = ((data['backgrounds'] as List?) ?? const [])
        .whereType<String>()
        .map(base64Decode)
        .toList();
    backgrounds = [];
    await _saveBackgrounds();
    final added = await addBackgrounds(bgList);
    notifyListeners();
    return bgList.length - added;
  }

  Future<void> clearCustomImages() async {
    customImages = List<Uint8List?>.filled(12, null);
    customChibi = List<ChibiSpec?>.filled(12, null);
    notifyListeners();
    await _saveImages();
  }

  // ====================================================================
  // Nhịp đồng hồ: kiểm tra âm báo giờ, báo thức, hẹn giờ
  // ====================================================================

  void _tick() {
    final now = DateTime.now();

    // Hẹn giờ đếm ngược
    final end = _timerEnd;
    if (end != null && !now.isBefore(end)) {
      _timerEnd = null;
      _timerLeftWhenPaused = timerTotal;
      _ring(const RingInfo(title: 'Hết giờ!', subtitle: 'Hẹn giờ đã kết thúc'),
          'alarm');
      notifyListeners();
    }

    // Báo lại (snooze)
    if (_snoozes.isNotEmpty) {
      final due = _snoozes.where((s) => !now.isBefore(s.at)).toList();
      for (final s in due) {
        _snoozes.remove(s);
        _ringAlarm(s.alarm);
      }
    }

    // Sang phút mới?
    final minute = _floorMinute(now);
    if (minute.isAfter(_lastMinute)) {
      // Nếu tab web bị trình duyệt "ngủ" vài phút, kiểm tra bù các phút bị lỡ
      // (tối đa 15 phút) nhưng chỉ đánh chuông cho phút hiện tại.
      var m = _lastMinute.add(const Duration(minutes: 1));
      var guard = 0;
      while (!m.isAfter(minute) && guard < 15) {
        _checkAlarms(m);
        m = m.add(const Duration(minutes: 1));
        guard++;
      }
      _lastMinute = minute;
      if (now.second < 10) _checkChime(now);
    }
  }

  void _checkAlarms(DateTime t) {
    var changed = false;
    for (final a in alarms) {
      if (a.matches(t)) {
        if (a.isOnce) {
          a.enabled = false;
          changed = true;
        }
        _ringAlarm(a);
      }
    }
    if (changed) {
      _saveAlarms();
      notifyListeners();
    }
  }

  bool isQuietHour(int hour) {
    if (!quietEnabled || quietStart == quietEnd) return false;
    if (quietStart < quietEnd) return hour >= quietStart && hour < quietEnd;
    return hour >= quietStart || hour < quietEnd;
  }

  void _checkChime(DateTime t) {
    if (!chimeEnabled || ringing != null) return;
    if (isQuietHour(t.hour)) return;
    if (t.minute == 0) {
      playHourChime(t.hour);
    } else if (t.minute == 30 && chimeHalfHour) {
      sound.playStrikes(1);
    }
  }

  /// Phát âm báo giờ theo kiểu đã chọn (cũng dùng cho nút "Nghe thử").
  void playHourChime(int hour) {
    final count = hour % 12 == 0 ? 12 : hour % 12;
    switch (chimeMode) {
      case 'chuong':
        sound.playChime();
        break;
      case 'ca_hai':
        sound.playChimeThenStrikes(count);
        break;
      default:
        sound.playStrikes(count);
    }
  }

  // ====================================================================
  // Reo / tắt / báo lại
  // ====================================================================

  void _ringAlarm(Alarm a) {
    _ring(
      RingInfo(
        title: a.timeText,
        subtitle: a.label.isEmpty ? 'Báo thức' : a.label,
        alarm: a,
      ),
      a.sound,
    );
  }

  void _ring(RingInfo info, String soundName) {
    sound.stopStrikes();
    ringing = info;
    sound.startRing(soundName);
    _autoStop?.cancel();
    // Tự tắt sau 3 phút nếu không ai bấm.
    _autoStop = Timer(const Duration(minutes: 3), dismissRing);
    notifyListeners();
  }

  void dismissRing() {
    _autoStop?.cancel();
    ringing = null;
    sound.stopRing();
    notifyListeners();
  }

  void snoozeRing({int minutes = 5}) {
    final a = ringing?.alarm;
    if (a != null) {
      _snoozes.add(_Snooze(DateTime.now().add(Duration(minutes: minutes)), a));
    }
    dismissRing();
  }

  // ====================================================================
  // Quản lý báo thức
  // ====================================================================

  Alarm newAlarmDraft() {
    final now = DateTime.now().add(const Duration(minutes: 1));
    return Alarm(id: _nextAlarmId, hour: now.hour, minute: now.minute);
  }

  void saveAlarm(Alarm a) {
    final i = alarms.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      alarms[i] = a;
    } else {
      alarms.add(a);
      _nextAlarmId = a.id + 1;
    }
    alarms.sort((x, y) => (x.hour * 60 + x.minute) - (y.hour * 60 + y.minute));
    _saveAlarms();
    notifyListeners();
  }

  void toggleAlarm(Alarm a, bool on) {
    a.enabled = on;
    _saveAlarms();
    notifyListeners();
  }

  void deleteAlarm(Alarm a) {
    alarms.removeWhere((x) => x.id == a.id);
    _snoozes.removeWhere((s) => s.alarm.id == a.id);
    _saveAlarms();
    notifyListeners();
  }

  /// Thời gian còn lại tới lần reo kế tiếp của báo thức (để hiển thị).
  Duration? timeUntil(Alarm a) {
    if (!a.enabled) return null;
    final now = DateTime.now();
    for (var d = 0; d <= 7; d++) {
      final day = DateTime(now.year, now.month, now.day + d, a.hour, a.minute);
      if (!day.isAfter(now)) continue;
      if (a.days.isEmpty || a.days.contains(day.weekday)) {
        return day.difference(now);
      }
    }
    return null;
  }

  // ====================================================================
  // Hẹn giờ đếm ngược
  // ====================================================================

  Duration get timerRemaining {
    final end = _timerEnd;
    if (end == null) return _timerLeftWhenPaused;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get timerIsFresh => !timerRunning && _timerLeftWhenPaused == timerTotal;

  void setTimer(Duration d) {
    if (d <= Duration.zero) return;
    timerTotal = d;
    _timerLeftWhenPaused = d;
    _timerEnd = null;
    _saveSettings();
    notifyListeners();
  }

  void startTimer() {
    if (_timerLeftWhenPaused <= Duration.zero) {
      _timerLeftWhenPaused = timerTotal;
    }
    _timerEnd = DateTime.now().add(_timerLeftWhenPaused);
    notifyListeners();
  }

  void pauseTimer() {
    _timerLeftWhenPaused = timerRemaining;
    _timerEnd = null;
    notifyListeners();
  }

  void resetTimer() {
    _timerEnd = null;
    _timerLeftWhenPaused = timerTotal;
    notifyListeners();
  }

  // ====================================================================
  // Bấm giờ
  // ====================================================================

  void stopwatchToggle() {
    if (stopwatch.isRunning) {
      stopwatch.stop();
    } else {
      stopwatch.start();
    }
    notifyListeners();
  }

  void stopwatchLap() {
    if (!stopwatch.isRunning) return;
    laps.insert(0, stopwatch.elapsed);
    notifyListeners();
  }

  void stopwatchReset() {
    stopwatch
      ..stop()
      ..reset();
    laps.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoStop?.cancel();
    super.dispose();
  }
}

/// Trạng thái dùng chung cho cả app.
final AppState app = AppState();

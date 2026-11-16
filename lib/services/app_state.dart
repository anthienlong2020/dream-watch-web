import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../chibi/chibi3d.dart';
import '../effects/element_effect.dart';
import '../models/alarm.dart';
import '../models/special_day.dart';
import '../themes/season_theme.dart';
import '../three_d/body_type.dart';
import '../models/clock_theme.dart';
import 'blob_store.dart';
import 'wake.dart' as wake;
import 'speech.dart';
import 'voice_recorder.dart';
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

  /// Các bộ ảnh mở từ file cấu hình (.dreamwatch), hiện trong danh sách Chủ đề hình ảnh.
  /// Ảnh lưu trong IndexedDB (key 'set:<tên>'), ở đây chỉ giữ tên + bản nạp sẵn.
  List<String> imageSets = [];
  final Map<String, ({List<Uint8List?> images, List<ChibiSpec?> chibi})> _setCache = {};
  final Set<String> _setLoading = {};

  /// Chibi 3D theo từng vị trí (null = ảnh thường).
  List<ChibiSpec?> customChibi = List<ChibiSpec?>.filled(12, null);
  bool showTime = true;
  bool showDate = true;
  bool showRoman = true;
  bool keepAwake = true;

  /// Chỉ giữ màn hình sáng khi đang cắm sạc (đỡ hao pin khi để qua đêm).
  bool keepAwakeOnlyCharging = true;

  /// Máy đang cắm sạc? null: không biết (iPhone, app native).
  bool? charging;

  /// Đang chạy bằng pin (biết chắc là không cắm sạc): vẽ chậm lại để đỡ hao pin.
  bool get powerSaving => kIsWeb && charging == false;

  /// Có thật sự giữ màn hình sáng lúc này không.
  bool get wakeWanted =>
      keepAwake && !(keepAwakeOnlyCharging && charging == false);
  int _chargeCheck = 0;
  bool showStars = true;
  /// Kiểu & dáng mặc định cho mọi vị trí.
  ImageStyle defaultStyle = ImageStyle.thoiPhong;
  BodyType defaultBody = BodyType.canDoi;

  /// Kiểu & dáng riêng của từng vị trí (0 = XII ... 11 = XI); null = theo mặc định.
  List<ImageStyle?> slotStyle = List<ImageStyle?>.filled(12, null);
  List<BodyType?> slotBody = List<BodyType?>.filled(12, null);

  /// Hệ (lửa, nước, điện...) mặc định và riêng từng vị trí.
  ElementType defaultElement = ElementType.none;
  List<ElementType?> slotElement = List<ElementType?>.filled(12, null);
  bool effectsOn = true;

  /// Theme mùa & lễ hội: 'off' = tắt, 'auto' = tự động theo ngày, hoặc id theme.
  // ---- Bản Standard / Pro ----
  /// Standard: đồng hồ quả lắc + 12 con số + chuông Big Ben (nhẹ máy). Pro: miễn phí, đủ tính năng, nặng máy hơn.
  bool isPro = false;
  String faceStyle = 'dream'; // Pro chọn mặt: 'dream' (hình ảnh mộng mơ) | 'pendulum' (quả lắc) | 'mech' (cơ khí trong suốt)
  bool tickTock = true; // tiếng tích tắc của quả lắc (mặc định bật)
  bool get showPendulum => !isPro || faceStyle == 'pendulum';
  bool get showMech => isPro && faceStyle == 'mech';

  /// Bật bản Pro (miễn phí; chỉ nặng máy hơn).
  void enablePro() {
    isPro = true;
    _prefs.setString('edition', 'pro');
    notifyListeners();
  }

  /// Quay về bản Standard (dữ liệu Pro vẫn giữ, mở khoá lại là có).
  void backToStandard() {
    isPro = false;
    _prefs.setString('edition', 'standard');
    notifyListeners();
  }

  String seasonMode = 'auto';
  bool seasonNightDim = true; // nền sáng + lễ hội ban đêm → phủ trời chạng vạng nhẹ
  String bgSource = 'event'; // khi có lễ hội: 'event' = ảnh nền riêng của lễ hội, 'tuy_chon' = ảnh nền của tôi

  /// Theme đang áp dụng (null nếu tắt).
  SeasonTheme? activeSeason([DateTime? at]) {
    final now = at ?? DateTime.now();
    if (seasonMode == 'off') return null;
    final id = seasonMode == 'auto' ? autoThemeId(now) : seasonMode;
    return themeById(id, now);
  }

  /// Màu hệ (Pha lê / Hào quang) mặc định và riêng từng vị trí.
  ElemColor defaultElemColor = ElemColor.tuDong;
  List<ElemColor?> slotElemColor = List<ElemColor?>.filled(12, null);
  List<ElemColor> get resolvedElemColors =>
      List.generate(12, (i) => slotElemColor[i] ?? defaultElemColor);

  List<ElementType> get resolvedElements =>
      List.generate(12, (i) => slotElement[i] ?? defaultElement);

  List<ImageStyle> get resolvedStyles =>
      List.generate(12, (i) => slotStyle[i] ?? defaultStyle);
  List<BodyType> get resolvedBodies =>
      List.generate(12, (i) => slotBody[i] ?? defaultBody);
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
  String chimeMode = 'westminster';
  bool chimeHalfHour = false;
  String hourBell = 'chuan'; // chuan | cao
  String hourVoice = 'tat'; // tat | nam | nu
  String voiceNameNam = '', voiceNameNu = ''; // giọng máy user chọn ('' = tự động)

  /// Báo giờ bằng giọng tự ghi: 'chung' + các giờ '0'..'23' đã ghi.
  Set<String> hourRecs = {};
  static String hourRecKey(String slot) => 'hourvoice:$slot';

  Future<void> saveHourRecording(String slot, Uint8List bytes, String mime) async {
    await saveVoice(hourRecKey(slot), bytes, mime);
    hourRecs = {...hourRecs, slot};
    _saveSettings();
    notifyListeners();
  }

  Future<void> deleteHourRecording(String slot) async {
    hourRecs = {...hourRecs}..remove(slot);
    _saveSettings();
    notifyListeners();
    try {
      await blobDelete(hourRecKey(slot));
    } catch (_) {}
  }

  Future<void> playHourRecording(String slot) async {
    final v = await loadVoice(hourRecKey(slot));
    if (v != null) await playVoiceBytes(v.$1, v.$2, volume: volume);
  }

  /// Giờ [hour]: phát câu riêng của giờ đó, không có thì câu chung, không có nữa thì giọng máy.
  Future<void> _playRecordedForHour(int hour) async {
    final slot = hourRecs.contains('$hour') ? '$hour' : (hourRecs.contains('chung') ? 'chung' : null);
    if (slot != null) {
      await playHourRecording(slot);
    } else {
      sound.speakHour(hour, voiceOverride: 'nu');
    }
  }
  bool quietEnabled = true;
  int quietStart = 22; // từ 22 giờ
  int quietEnd = 6; // đến 6 giờ sáng
  double volume = 1.0;

  // ---------- Báo thức ----------
  List<Alarm> alarms = [];
  int _nextAlarmId = 1;
  final List<_Snooze> _snoozes = [];

  // ---------- Ngày nhớ (âm/dương lịch, lặp mỗi năm) ----------
  List<SpecialDay> specialDays = [];
  int _nextSpecialId = 1;

  /// Nhắc mùng 1 & Rằm âm lịch: giờ nhắc, và có nhắc trước 1 ngày không.
  bool remindMoon = false;
  int remindMoonHour = 7;
  bool remindMoonEve = false;

  /// Đã bấm × ở nút "📲 Cài app" trên màn hình đồng hồ.
  bool installChipHidden = false;

  // ---------- Giờ thế giới ----------
  List<String> worldCities = ['tokyo', 'sydney', 'paris', 'newyork', 'losangeles'];

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

  late final AppLifecycleListener _life = AppLifecycleListener(
    // quay lại tab/cửa sổ → làm mới tiếng tích tắc (trình duyệt treo âm thanh khi ẩn tab)
    onResume: () => sound.resetTick(),
    onShow: () => sound.resetTick(),
  );

  Future<void> init() async {
    _life; // bắt đầu theo dõi ẩn/hiện app
    _prefs = await SharedPreferences.getInstance();
    _load();
    sound.volume = volume;
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    if (!kIsWeb) await _applyWakelock();
  }

  void _load() {
    final raw = _prefs.getString('settings');
    // Bản quyền: người đã dùng app từ trước (thử nghiệm) được giữ bản Pro; cài mới là Standard.
    final ed = _prefs.getString('edition');
    if (ed == null) {
      isPro = raw != null;
      _prefs.setString('edition', isPro ? 'pro' : 'standard');
    } else {
      isPro = ed == 'pro';
    }
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

    final rawDays = _prefs.getString('specialDays');
    if (rawDays != null) {
      try {
        specialDays = (jsonDecode(rawDays) as List)
            .map((e) => SpecialDay.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else {
      // lần đầu: có sẵn đếm ngược tới Tết trên mặt đồng hồ
      specialDays = [
        SpecialDay(id: 1, name: 'Tết Nguyên Đán', kind: 'le', lunar: true, day: 1, month: 1,
            remindBefore: -1, onClock: true),
      ];
    }
    for (final d in specialDays) {
      if (d.id >= _nextSpecialId) _nextSpecialId = d.id + 1;
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
        'imageSets': imageSets,
        'showTime': showTime,
        'showDate': showDate,
        'remindMoon': remindMoon,
        'remindMoonHour': remindMoonHour,
        'remindMoonEve': remindMoonEve,
        'worldCities': worldCities,
        'installChipHidden': installChipHidden,
        'showRoman': showRoman,
        'keepAwake': keepAwake,
        'keepAwakeOnlyCharging': keepAwakeOnlyCharging,
        'showStars': showStars,
        'defaultStyle': defaultStyle.name,
        'slotStyle': slotStyle.map((e) => e?.name).toList(),
        'slotBody': slotBody.map((e) => e?.name).toList(),
        'defaultElement': defaultElement.name,
        'slotElement': slotElement.map((e) => e?.name).toList(),
        'effectsOn': effectsOn,
        'seasonMode': seasonMode,
        'faceStyle': faceStyle,
        'tickOn': tickTock,
        'seasonNightDim': seasonNightDim,
        'bgSource': bgSource,
        'defaultElemColor': defaultElemColor.name,
        'slotElemColor': slotElemColor.map((e) => e?.name).toList(),
        'spin360': spin360,
        'bodyType': defaultBody.name,
        'hourSpeed': hourSpeed,
        'minuteSpeed': minuteSpeed,
        'secondSpeed': secondSpeed,
        'bgIntervalMin': bgIntervalMin,
        'bgDim': bgDim,
        'chimeEnabled': chimeEnabled,
        'chimeMode': chimeMode,
        'chimeHalfHour': chimeHalfHour,
        'hourBell': hourBell,
        'hourVoice': hourVoice,
        'hourRecs': hourRecs.toList(),
        'voiceNameNam': voiceNameNam,
        'voiceNameNu': voiceNameNu,
        'quietEnabled': quietEnabled,
        'quietStart': quietStart,
        'quietEnd': quietEnd,
        'volume': volume,
        'timerTotalSec': timerTotal.inSeconds,
      };

  void _applySettings(Map<String, dynamic> j) {
    presetName = (j['presetName'] as String?) ?? presetName;
    themeId = (j['themeId'] as String?) ?? themeId;
    final sets = j['imageSets'];
    if (sets is List) imageSets = sets.whereType<String>().toList();
    showTime = (j['showTime'] as bool?) ?? showTime;
    showDate = (j['showDate'] as bool?) ?? showDate;
    remindMoon = (j['remindMoon'] as bool?) ?? remindMoon;
    remindMoonHour = (j['remindMoonHour'] as num?)?.toInt() ?? remindMoonHour;
    remindMoonEve = (j['remindMoonEve'] as bool?) ?? remindMoonEve;
    installChipHidden = (j['installChipHidden'] as bool?) ?? installChipHidden;
    final wc = j['worldCities'];
    if (wc is List) worldCities = wc.whereType<String>().toList();
    showRoman = (j['showRoman'] as bool?) ?? showRoman;
    keepAwake = (j['keepAwake'] as bool?) ?? keepAwake;
    keepAwakeOnlyCharging = (j['keepAwakeOnlyCharging'] as bool?) ?? keepAwakeOnlyCharging;
    showStars = (j['showStars'] as bool?) ?? showStars;
    if (j['defaultStyle'] is String) {
      defaultStyle = imageStyleFromName(j['defaultStyle'] as String);
    } else if (j['inflate3d'] == false) {
      defaultStyle = ImageStyle.standard; // bản cũ đã tắt ảnh 3D
    }
    final ss = j['slotStyle'];
    if (ss is List) {
      slotStyle = List<ImageStyle?>.generate(12, (i) {
        final v = i < ss.length ? ss[i] : null;
        return v is String ? imageStyleFromName(v) : null;
      });
    }
    if (j['defaultElement'] is String) {
      defaultElement = elementFromName(j['defaultElement'] as String);
    }
    effectsOn = (j['effectsOn'] as bool?) ?? effectsOn;
    seasonMode = (j['seasonMode'] as String?) ?? seasonMode;
    faceStyle = (j['faceStyle'] as String?) ?? faceStyle;
    tickTock = (j['tickOn'] as bool?) ?? tickTock;
    seasonNightDim = (j['seasonNightDim'] as bool?) ?? seasonNightDim;
    bgSource = (j['bgSource'] as String?) ?? bgSource;
    if (j['defaultElemColor'] is String) {
      defaultElemColor = elemColorFromName(j['defaultElemColor'] as String);
    }
    final sc = j['slotElemColor'];
    if (sc is List) {
      slotElemColor = List<ElemColor?>.generate(12, (i) {
        final v = i < sc.length ? sc[i] : null;
        return v is String ? elemColorFromName(v) : null;
      });
    }
    final se = j['slotElement'];
    if (se is List) {
      slotElement = List<ElementType?>.generate(12, (i) {
        final v = i < se.length ? se[i] : null;
        return v is String ? elementFromName(v) : null;
      });
    }
    final sb = j['slotBody'];
    if (sb is List) {
      slotBody = List<BodyType?>.generate(12, (i) {
        final v = i < sb.length ? sb[i] : null;
        return v is String ? bodyTypeFromName(v) : null;
      });
    }
    spin360 = (j['spin360'] as bool?) ?? spin360;
    if (j['bodyType'] is String) defaultBody = bodyTypeFromName(j['bodyType'] as String);
    hourSpeed = (j['hourSpeed'] as num?)?.toDouble() ?? hourSpeed;
    minuteSpeed = (j['minuteSpeed'] as num?)?.toDouble() ?? minuteSpeed;
    secondSpeed = (j['secondSpeed'] as num?)?.toDouble() ?? secondSpeed;
    bgIntervalMin = (j['bgIntervalMin'] as num?)?.toInt() ?? bgIntervalMin;
    bgDim = (j['bgDim'] as num?)?.toDouble() ?? bgDim;
    chimeEnabled = (j['chimeEnabled'] as bool?) ?? chimeEnabled;
    chimeMode = (j['chimeMode'] as String?) ?? chimeMode;
    chimeHalfHour = (j['chimeHalfHour'] as bool?) ?? chimeHalfHour;
    hourBell = (j['hourBell'] as String?) ?? hourBell;
    hourVoice = (j['hourVoice'] as String?) ?? hourVoice;
    final hr = j['hourRecs'];
    if (hr is List) hourRecs = hr.whereType<String>().toSet();
    voiceNameNam = (j['voiceNameNam'] as String?) ?? voiceNameNam;
    voiceNameNu = (j['voiceNameNu'] as String?) ?? voiceNameNu;
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

  void _saveSpecialDays() {
    _prefs.setString(
        'specialDays', jsonEncode(specialDays.map((d) => d.toJson()).toList()));
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

  void setKeepAwakeOnlyCharging(bool v) {
    update(() => keepAwakeOnlyCharging = v);
    _applyWakelock();
  }

  /// Mỗi ~2 giây xem máy có đang cắm sạc không (chỉ trên web).
  void _checkCharging() {
    if (!kIsWeb) return;
    if (++_chargeCheck % 8 != 0) return;
    final c = wake.isCharging();
    if (c == charging) return;
    charging = c;
    notifyListeners();
    if (started) _applyWakelock();
  }

  Future<void> _applyWakelock() async {
    if (kIsWeb) {
      // Trên web tự xin "Screen Wake Lock" và xin lại mỗi khi quay về app.
      wake.setWake(wakeWanted);
      return;
    }
    try {
      await WakelockPlus.toggle(enable: keepAwake);
    } catch (_) {}
  }

  // ====================================================================
  // Chủ đề
  // ====================================================================

  ClockTheme get theme => themeOf(themeId);

  /// Chủ đề theo id: 'khung_long' = Chuẩn (Standard), 'tu_chon' = Ảnh của tôi,
  /// 'set:<tên>' = bộ ảnh mở từ file cấu hình.
  ClockTheme themeOf(String id) {
    if (id == 'tu_chon') return buildCustomTheme(customImages, customChibi);
    if (id.startsWith('set:')) {
      final name = id.substring(4);
      final s = _setCache[name];
      if (s == null) {
        _loadSet(name);
        return buildCustomTheme(const [], const []);
      }
      return buildCustomTheme(s.images, s.chibi);
    }
    return buildDinoTheme();
  }

  static String _setKey(String name) => 'set:$name';

  Future<void> _loadSet(String name) async {
    if (!_setLoading.add(name)) return;
    try {
      final raw = await blobGet(_setKey(name));
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final imgs = (j['images'] as List?) ?? const [];
      final ch = (j['chibi'] as List?) ?? const [];
      _setCache[name] = (
        images: List<Uint8List?>.generate(12, (i) {
          final v = i < imgs.length ? imgs[i] : null;
          return v is String ? base64Decode(v) : null;
        }),
        chibi: List<ChibiSpec?>.generate(12, (i) => i < ch.length ? ChibiSpec.fromJson(ch[i]) : null),
      );
      notifyListeners();
    } catch (_) {
    } finally {
      _setLoading.remove(name);
    }
  }

  /// Thêm một bộ ảnh vào danh sách (tên trùng thì thêm số), chọn luôn bộ đó.
  Future<String> addImageSet(String name, List<Uint8List?> images, List<ChibiSpec?> chibi) async {
    var n = name.trim().isEmpty ? 'Bộ ảnh' : name.trim();
    if (imageSets.contains(n)) {
      var k = 2;
      while (imageSets.contains('$n ($k)')) {
        k++;
      }
      n = '$n ($k)';
    }
    await blobPut(
        _setKey(n),
        jsonEncode({
          'images': images.map((b) => b == null ? null : base64Encode(b)).toList(),
          'chibi': chibi.map((c) => c?.toJson()).toList(),
        }));
    _setCache[n] = (
      images: List<Uint8List?>.generate(12, (i) => i < images.length ? images[i] : null),
      chibi: List<ChibiSpec?>.generate(12, (i) => i < chibi.length ? chibi[i] : null),
    );
    imageSets = [...imageSets, n];
    themeId = 'set:$n';
    _saveSettings();
    notifyListeners();
    return n;
  }

  Future<void> deleteImageSet(String name) async {
    imageSets = imageSets.where((s) => s != name).toList();
    _setCache.remove(name);
    if (themeId == 'set:$name') themeId = 'tu_chon';
    _saveSettings();
    notifyListeners();
    try {
      await blobDelete(_setKey(name));
    } catch (_) {}
  }

  /// Chép bộ ảnh đang chọn sang "Ảnh của tôi" để sửa từng ô.
  Future<bool> copySetToCustom(String name) async {
    final s = _setCache[name];
    if (s == null) return false;
    customImages = List.of(s.images);
    customChibi = List.of(s.chibi);
    themeId = 'tu_chon';
    _saveSettings();
    notifyListeners();
    try {
      return await _saveImages();
    } catch (_) {
      return false;
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
      // xuất bộ ảnh đang dùng (Ảnh của tôi, hoặc bộ đang chọn trong danh sách)
      'customImages': _activeImages().images.map((b) => b == null ? null : base64Encode(b)).toList(),
      'customChibi': _activeImages().chibi.map((c) => c?.toJson()).toList(),
      'backgrounds': backgrounds.map(base64Encode).toList(),
      if (withAlarms) 'alarms': alarms.map((a) => a.toJson()).toList(),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  ({List<Uint8List?> images, List<ChibiSpec?> chibi}) _activeImages() {
    if (themeId.startsWith('set:')) {
      final s = _setCache[themeId.substring(4)];
      if (s != null) return s;
    }
    return (images: customImages, chibi: customChibi);
  }

  /// Đọc file bộ cấu hình. Ném FormatException nếu không phải file của app.
  /// Trả về số ảnh nền KHÔNG lưu được vì bộ nhớ đầy (0 = lưu đủ).
  Future<int> importPreset(Uint8List bytes, {String fileName = ''}) async {
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
    final keepSets = imageSets; // danh sách bộ ảnh là của máy này, không lấy theo file
    if (settings is Map<String, dynamic>) _applySettings(settings);
    imageSets = keepSets;
    if (themeId.startsWith('set:') && !imageSets.contains(themeId.substring(4))) themeId = 'tu_chon';
    if (themeId == 'con_giap') themeId = 'khung_long';
    presetName = (data['name'] as String?) ?? presetName;

    // Bộ ảnh trong file → thêm thành 1 mục mới trong danh sách Chủ đề hình ảnh
    // ("Ảnh của tôi" giữ nguyên, không bị ghi đè).
    final imgs = (data['customImages'] as List?) ?? const [];
    final setImages = List<Uint8List?>.generate(12, (i) {
      final v = i < imgs.length ? imgs[i] : null;
      return v is String ? base64Decode(v) : null;
    });
    final chibiList = (data['customChibi'] as List?) ?? const [];
    final setChibi = List<ChibiSpec?>.generate(
        12, (i) => i < chibiList.length ? ChibiSpec.fromJson(chibiList[i]) : null);
    if (setImages.any((b) => b != null) || setChibi.any((c) => c != null)) {
      final base = fileName.replaceAll(RegExp(r'\.dreamwatch$', caseSensitive: false), '');
      try {
        await addImageSet((data['name'] as String?) ?? base, setImages, setChibi);
      } catch (_) {
        // không lưu được vào kho riêng → dùng cách cũ: đưa vào Ảnh của tôi
        customImages = setImages;
        customChibi = setChibi;
        themeId = 'tu_chon';
      }
    }

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
    _checkCharging();

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
    _checkSpecialDays(t);
  }

  /// Nhắc ngày nhớ (đúng giờ nhắc, trước N ngày) và mùng 1 / Rằm.
  void _checkSpecialDays(DateTime t) {
    if (t.minute != 0) return;
    final today = DateTime(t.year, t.month, t.day);
    final notes = <String>[];
    for (final d in specialDays) {
      if (d.remindBefore < 0 || d.remindHour != t.hour) continue;
      final next = d.nextFrom(today);
      final left = daysBetween(today, next);
      if (left != d.remindBefore) continue;
      final years = d.yearsText(next);
      notes.add('${d.emoji} ${d.name}${years == null ? '' : ' ($years)'}: '
          '${left == 0 ? 'hôm nay' : (left == 1 ? 'ngày mai' : 'còn $left ngày')}');
    }
    if (remindMoon && remindMoonHour == t.hour) {
      final l = solarToLunar(today);
      if (l.day == 1 || l.day == 15) {
        notes.add('${l.day == 15 ? '🌕 Hôm nay Rằm' : '🌑 Hôm nay mùng 1'} tháng ${l.month} âm lịch');
      }
      if (remindMoonEve) {
        final lt = solarToLunar(today.add(const Duration(days: 1)));
        if (lt.day == 1 || lt.day == 15) {
          notes.add('${lt.day == 15 ? '🌕 Ngày mai Rằm' : '🌑 Ngày mai mùng 1'} tháng ${lt.month} âm lịch');
        }
      }
    }
    if (notes.isEmpty || ringing != null) return;
    _ringNotice(notes);
  }

  /// Lời nhắc ngày nhớ: chuông nhẹ + (bản Pro) đọc lời nhắc; tự tắt sau 3 phút.
  void _ringNotice(List<String> notes) {
    sound.stopStrikes();
    ringing = RingInfo(title: 'Nhắc ngày', subtitle: notes.join('\n'));
    _autoStop?.cancel();
    _autoStop = Timer(const Duration(minutes: 3), dismissRing);
    sound.playChime();
    if (isPro) {
      // bỏ emoji khi đọc
      final text = notes.map((n) => n.replaceAll(RegExp(r'^\S+\s'), '')).join('. ');
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (ringing?.title == 'Nhắc ngày') {
          speakVi(text, male: hourVoice == 'nam', volume: volume,
              voiceName: hourVoice == 'nam' ? voiceNameNam : voiceNameNu);
        }
      });
    }
    notifyListeners();
  }

  /// Ngày nhớ hiện đếm ngược trên mặt đồng hồ: ngày gần nhất có bật "onClock".
  (SpecialDay, DateTime, int)? clockCountdown([DateTime? now]) {
    final today = now ?? DateTime.now();
    (SpecialDay, DateTime, int)? best;
    for (final d in specialDays) {
      if (!d.onClock) continue;
      final next = d.nextFrom(today);
      final left = daysBetween(today, next);
      if (best == null || left < best.$3) best = (d, next, left);
    }
    return best;
  }

  SpecialDay newSpecialDraft() {
    final l = solarToLunar(DateTime.now());
    return SpecialDay(id: _nextSpecialId, name: '', kind: 'sinhNhat', lunar: true, day: l.day, month: l.month);
  }

  void saveSpecialDay(SpecialDay d) {
    final i = specialDays.indexWhere((x) => x.id == d.id);
    if (i >= 0) {
      specialDays[i] = d;
    } else {
      specialDays.add(d);
      _nextSpecialId = d.id + 1;
    }
    _saveSpecialDays();
    notifyListeners();
  }

  void deleteSpecialDay(SpecialDay d) {
    specialDays.removeWhere((x) => x.id == d.id);
    _saveSpecialDays();
    notifyListeners();
  }

  void addWorldCity(String id) {
    if (worldCities.contains(id)) return;
    update(() => worldCities = [...worldCities, id]);
  }

  void removeWorldCity(String id) => update(() => worldCities = worldCities.where((c) => c != id).toList());

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
    } else if (chimeHalfHour) {
      if (chimeMode == 'westminster' || !isPro) {
        // nhạc chuông nhà thờ lúc 15, 30, 45 phút
        if (t.minute % 15 == 0) sound.playWestminster(t.minute ~/ 15);
      } else if (t.minute == 30) {
        sound.playStrikes(1);
      }
    }
  }

  void _syncVoice() {
    sound.recordedVoice = _playRecordedForHour;
    sound
      ..hourBell = hourBell
      ..voice = hourVoice
      ..voiceNameNam = voiceNameNam
      ..voiceNameNu = voiceNameNu;
  }

  /// Nghe thử riêng giọng đọc giờ ('nam' / 'nu').
  void testVoice(String v) {
    _syncVoice();
    sound.speakHour(DateTime.now().hour, voiceOverride: v);
  }

  /// Phát âm báo giờ theo kiểu đã chọn (cũng dùng cho nút "Nghe thử").
  void playHourChime(int hour) {
    final count = hour % 12 == 0 ? 12 : hour % 12;
    _syncVoice();
    if (!isPro) {
      // Standard: chuông Big Ben (Westminster) + đánh số tiếng, không giọng đọc
      sound.voice = 'tat';
      sound.playWestminsterHour(count, hour: hour);
      return;
    }
    switch (chimeMode) {
      case 'chuong':
        sound.playChime();
        Future.delayed(const Duration(milliseconds: 4200), () => sound.speakHour(hour));
        break;
      case 'giong':
        sound.speakHour(hour, voiceOverride: hourVoice == 'tat' ? 'nu' : hourVoice);
        break;
      case 'ca_hai':
        sound.playChimeThenStrikes(count, hour: hour);
        break;
      case 'westminster':
        sound.playWestminsterHour(count, hour: hour);
        break;
      default:
        sound.playStrikes(count, hour: hour);
    }
  }

  // ====================================================================
  // Reo / tắt / báo lại
  // ====================================================================

  void _ringAlarm(Alarm a) {
    if (isPro && a.isReminder) {
      _ringReminder(a);
      return;
    }
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

  Timer? _remindRepeat;

  /// Lời nhắc: chuông ngắn rồi đọc lời nhắc / phát giọng tự ghi, nhắc lại mỗi 30 giây
  /// tới khi bấm Tắt (tối đa 3 phút).
  void _ringReminder(Alarm a) {
    sound.stopStrikes();
    ringing = RingInfo(title: a.timeText, subtitle: a.label.isEmpty ? 'Lời nhắc' : a.label, alarm: a);
    _autoStop?.cancel();
    _autoStop = Timer(const Duration(minutes: 3), dismissRing);
    _remindRepeat?.cancel();
    void announce() {
      sound.playChime();
      Future.delayed(const Duration(milliseconds: 2600), () => playReminderVoice(a));
    }

    announce();
    _remindRepeat = Timer.periodic(const Duration(seconds: 30), (_) => announce());
    notifyListeners();
  }

  /// Phát nội dung lời nhắc: giọng tự ghi (nếu có), rồi đọc chữ (nếu bật).
  Future<void> playReminderVoice(Alarm a) async {
    if (a.hasVoice) {
      final v = await loadVoice(voiceKeyFor(a.id));
      if (v != null) {
        await playVoiceBytes(v.$1, v.$2, volume: volume);
        if (!a.speak) return;
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    if (a.speak && a.label.isNotEmpty) {
      speakVi(a.label, male: hourVoice == 'nam', volume: volume,
          voiceName: hourVoice == 'nam' ? voiceNameNam : voiceNameNu);
    }
  }

  void dismissRing() {
    _remindRepeat?.cancel();
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

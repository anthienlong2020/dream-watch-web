import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'speech.dart';

/// Phát âm thanh: chuông mỗi giờ, đánh số tiếng theo giờ, chuông báo thức.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _ringPlayer = AudioPlayer();
  double volume = 1.0;
  bool _ringing = false;
  int _strikeRun = 0;

  bool get isRinging => _ringing;

  /// Trên web, trình duyệt chỉ cho phát tiếng sau khi người dùng chạm vào
  /// trang. Gọi hàm này trong lần chạm đầu tiên.
  Future<void> unlock() async {
    warmUpVoices();
    try {
      final p = AudioPlayer();
      await p.setVolume(0.0);
      await p.play(AssetSource('sounds/silent.wav'));
      unawaited(p.onPlayerComplete.first.then((_) => p.dispose()));
    } catch (_) {}
  }

  Future<void> _playOnce(String file, {double? vol, String ext = 'wav'}) async {
    try {
      final p = AudioPlayer();
      unawaited(p.onPlayerComplete.first.then((_) => p.dispose()));
      await p.play(AssetSource('sounds/$file.$ext'), volume: vol ?? volume);
    } catch (_) {}
  }

  /// Chuông báo giờ (giai điệu ngắn).
  Future<void> playChime() => _playOnce('chime');

  /// Tiếng chuông đánh giờ: 'chuan' (trầm, ngân êm) hoặc 'cao' (coong coong, trong và cao).
  String hourBell = 'chuan';

  /// Đọc giờ sau khi đánh chuông: 'tat', 'nam', 'nu'.
  String voice = 'tat';

  String get _bellFile => hourBell == 'cao' ? 'strike_cao' : 'strike_big';

  /// Đánh [count] tiếng chuông, như đồng hồ quả lắc; xong thì đọc giờ nếu bật giọng nói.
  Future<void> playStrikes(int count, {int? hour, int? run}) async {
    final r = run ?? ++_strikeRun;
    for (var i = 0; i < count; i++) {
      if (r != _strikeRun) return; // có lệnh mới thì dừng lượt cũ
      await _playOnce(_bellFile, ext: 'mp3');
      await Future.delayed(const Duration(milliseconds: 2300));
    }
    if (r == _strikeRun && hour != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      speakHour(hour);
    }
  }

  /// Đọc "Bây giờ là x giờ ..." bằng giọng nam / nữ đã chọn.
  void speakHour(int hour, {String? voiceOverride}) {
    final v = voiceOverride ?? voice;
    if (v == 'tat') return;
    speakVi(hourSentence(hour), male: v == 'nam', volume: volume);
  }

  /// Giai điệu báo giờ rồi đánh số tiếng.
  Future<void> playChimeThenStrikes(int count, {int? hour}) async {
    final run = ++_strikeRun;
    await playChime();
    await Future.delayed(const Duration(milliseconds: 4200));
    await playStrikes(count, hour: hour, run: run);
  }

  void stopStrikes() => _strikeRun++;

  // ------------------------------------------------------------------
  // Chuông Westminster (chuông nhà thờ / Big Ben, giai điệu năm 1793)
  // ------------------------------------------------------------------

  /// Thời điểm (giây) nốt cuối của từng đoạn: 1 = :15, 2 = :30, 3 = :45, 4 = tròn giờ.
  static const _westLastNote = {1: 2.34, 2: 7.31, 3: 12.28, 4: 17.25};

  /// Đoạn nhạc Westminster: [quarter] = 1 (15 phút), 2 (30), 3 (45), 4 (tròn giờ).
  Future<void> playWestminster(int quarter) => _playOnce('west_q$quarter', ext: 'mp3');

  /// Tròn giờ kiểu Big Ben: đủ 4 câu nhạc, nghỉ một nhịp, rồi chuông lớn đánh số tiếng theo giờ.
  Future<void> playWestminsterHour(int count, {int? hour}) async {
    final run = ++_strikeRun;
    await playWestminster(4);
    await Future.delayed(Duration(milliseconds: ((_westLastNote[4]! + 2.6) * 1000).round()));
    await playStrikes(count, hour: hour, run: run);
  }

  /// Nghe thử một âm báo thức (không lặp).
  Future<void> preview(String sound) => _playOnce(sound);

  /// Reo liên tục cho tới khi gọi [stopRing].
  Future<void> startRing(String sound) async {
    _ringing = true;
    try {
      await _ringPlayer.stop();
      await _ringPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringPlayer.setVolume(volume);
      await _ringPlayer.play(AssetSource('sounds/$sound.wav'));
    } catch (_) {}
  }

  Future<void> stopRing() async {
    _ringing = false;
    try {
      await _ringPlayer.stop();
    } catch (_) {}
  }
}

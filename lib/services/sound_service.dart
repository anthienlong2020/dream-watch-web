import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

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

  /// Đánh [count] tiếng chuông, như đồng hồ quả lắc.
  Future<void> playStrikes(int count) async {
    final run = ++_strikeRun;
    for (var i = 0; i < count; i++) {
      if (run != _strikeRun) return; // có lệnh mới thì dừng lượt cũ
      await _playOnce('strike');
      await Future.delayed(const Duration(milliseconds: 1300));
    }
  }

  /// Giai điệu báo giờ rồi đánh số tiếng.
  Future<void> playChimeThenStrikes(int count) async {
    await playChime();
    await Future.delayed(const Duration(milliseconds: 4200));
    await playStrikes(count);
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
  Future<void> playWestminsterHour(int count) async {
    final run = ++_strikeRun;
    await playWestminster(4);
    await Future.delayed(Duration(milliseconds: ((_westLastNote[4]! + 2.6) * 1000).round()));
    for (var i = 0; i < count; i++) {
      if (run != _strikeRun) return;
      await _playOnce('strike_big', ext: 'mp3');
      await Future.delayed(const Duration(milliseconds: 2300));
    }
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

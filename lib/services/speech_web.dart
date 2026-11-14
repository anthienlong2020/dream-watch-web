import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Nạp sẵn danh sách giọng (trình duyệt tải danh sách giọng không đồng bộ).
void warmUpVoices() {
  try {
    web.window.speechSynthesis.getVoices();
  } catch (_) {}
}

const _maleHints = ['namminh', 'male', 'nam ', 'an -', 'microsoft an', 'minh', 'vic'];
const _femaleHints = ['hoaimy', 'female', 'my ', 'linh', 'mai', 'gft', 'nu '];

List<web.SpeechSynthesisVoice> _viVoices() => web.window.speechSynthesis
    .getVoices()
    .toDart
    .where((v) => v.lang.toLowerCase().replaceAll('_', '-').startsWith('vi'))
    .toList();

/// Tên các giọng tiếng Việt có trong máy (để user tự chọn giọng nam / nữ).
List<String> viVoiceNames() {
  try {
    return [for (final v in _viVoices()) v.name];
  } catch (_) {
    return const [];
  }
}

bool _has(String name, List<String> hints) {
  final n = '${name.toLowerCase()} ';
  return hints.any(n.contains);
}

/// Đọc [text] bằng giọng tiếng Việt nam / nữ.
/// Nếu máy có sẵn giọng đúng giới tính thì dùng giọng đó; nếu chỉ có 1 giọng
/// thì hạ / nâng cao độ để ra giọng nam trầm / nữ trong.
void speakVi(String text, {required bool male, double volume = 1.0, String voiceName = ''}) {
  try {
    final synth = web.window.speechSynthesis;
    final vi = _viVoices();
    final u = web.SpeechSynthesisUtterance(text)
      ..lang = 'vi-VN'
      ..rate = 0.92
      ..volume = volume.clamp(0.0, 1.0);
    web.SpeechSynthesisVoice? pick;
    var userPicked = false;
    for (final v in vi) {
      if (voiceName.isNotEmpty && v.name == voiceName) {
        pick = v;
        userPicked = true;
        break;
      }
    }
    if (pick == null) {
      for (final v in vi) {
        if (_has(v.name, male ? _maleHints : _femaleHints)) {
          pick = v;
          break;
        }
      }
    }
    if (pick != null) {
      u.voice = pick;
      // user tự chọn giọng → giữ nguyên; tự đoán theo tên → chỉnh nhẹ cho rõ nam/nữ
      u.pitch = userPicked ? 1.0 : (male ? 0.85 : 1.15);
    } else {
      // máy chỉ có 1 giọng: nâng / hạ cao độ thật rõ để ra giọng nữ / nam
      if (vi.isNotEmpty) u.voice = vi.first;
      u.pitch = male ? 0.7 : 1.8;
    }
    synth.cancel();
    synth.speak(u);
  } catch (_) {}
}

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

bool _has(String name, List<String> hints) {
  final n = '${name.toLowerCase()} ';
  return hints.any(n.contains);
}

/// Đọc [text] bằng giọng tiếng Việt nam / nữ.
/// Nếu máy có sẵn giọng đúng giới tính thì dùng giọng đó; nếu chỉ có 1 giọng
/// thì hạ / nâng cao độ để ra giọng nam trầm / nữ trong.
void speakVi(String text, {required bool male, double volume = 1.0}) {
  try {
    final synth = web.window.speechSynthesis;
    final all = synth.getVoices().toDart;
    final vi = all.where((v) => v.lang.toLowerCase().replaceAll('_', '-').startsWith('vi')).toList();
    final u = web.SpeechSynthesisUtterance(text)
      ..lang = 'vi-VN'
      ..rate = 0.92
      ..volume = volume.clamp(0.0, 1.0);
    web.SpeechSynthesisVoice? pick;
    for (final v in vi) {
      if (_has(v.name, male ? _maleHints : _femaleHints)) {
        pick = v;
        break;
      }
    }
    if (pick != null) {
      u.voice = pick;
      u.pitch = 1.0;
    } else {
      if (vi.isNotEmpty) u.voice = vi.first;
      u.pitch = male ? 0.6 : 1.25;
    }
    synth.cancel();
    synth.speak(u);
  } catch (_) {}
}

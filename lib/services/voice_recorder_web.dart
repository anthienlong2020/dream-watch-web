import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.MediaRecorder? _rec;
web.MediaStream? _stream;
final List<web.Blob> _chunks = [];
Completer<void>? _stopped;

bool get canRecordVoice {
  try {
    return web.window.navigator.mediaDevices.isA<web.MediaDevices>();
  } catch (_) {
    return false;
  }
}

/// Bắt đầu ghi âm (trình duyệt sẽ hỏi quyền dùng micro). Trả về false nếu không ghi được.
Future<bool> startVoiceRecording() async {
  try {
    _chunks.clear();
    _stream = await web.window.navigator.mediaDevices
        .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
        .toDart;
    final rec = web.MediaRecorder(_stream!);
    _stopped = Completer<void>();
    rec.ondataavailable = ((web.BlobEvent e) {
      if (e.data.size > 0) _chunks.add(e.data);
    }).toJS;
    rec.onstop = ((web.Event _) {
      if (!(_stopped?.isCompleted ?? true)) _stopped!.complete();
    }).toJS;
    rec.start();
    _rec = rec;
    return true;
  } catch (_) {
    _cleanup();
    return false;
  }
}

/// Dừng ghi âm, trả về (dữ liệu âm thanh, kiểu file).
Future<(Uint8List, String)?> stopVoiceRecording() async {
  final rec = _rec;
  if (rec == null) return null;
  try {
    rec.stop();
    await _stopped?.future.timeout(const Duration(seconds: 3));
    final mime = rec.mimeType.isEmpty ? 'audio/webm' : rec.mimeType;
    final blob = web.Blob(<web.BlobPart>[..._chunks].toJS, web.BlobPropertyBag(type: mime));
    final buf = await blob.arrayBuffer().toDart;
    return (buf.toDart.asUint8List(), mime);
  } catch (_) {
    return null;
  } finally {
    _cleanup();
  }
}

void _cleanup() {
  try {
    final tracks = _stream?.getTracks().toDart ?? const [];
    for (final t in tracks) {
      t.stop();
    }
  } catch (_) {}
  _stream = null;
  _rec = null;
}

/// Phát lại đoạn ghi âm.
Future<void> playVoiceBytes(Uint8List bytes, String mime, {double volume = 1.0}) async {
  try {
    final blob = web.Blob(<web.BlobPart>[bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
    final url = web.URL.createObjectURL(blob);
    final audio = web.HTMLAudioElement()
      ..src = url
      ..volume = volume.clamp(0.0, 1.0);
    audio.onended = ((web.Event _) => web.URL.revokeObjectURL(url)).toJS;
    await audio.play().toDart;
  } catch (_) {}
}

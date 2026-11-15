// Ghi âm giọng nói cho lời nhắc (bản Pro) và phát lại.
// Bản web dùng micro của trình duyệt (MediaRecorder). Bản cài sau này sẽ làm riêng.
import 'dart:convert';
import 'dart:typed_data';

import 'blob_store.dart';

export 'voice_recorder_stub.dart' if (dart.library.js_interop) 'voice_recorder_web.dart';

String voiceKeyFor(int alarmId) => 'voice:$alarmId';

Future<void> saveVoice(String key, Uint8List bytes, String mime) =>
    blobPut(key, jsonEncode({'mime': mime, 'data': base64Encode(bytes)}));

Future<(Uint8List, String)?> loadVoice(String key) async {
  final raw = await blobGet(key);
  if (raw == null) return null;
  final j = jsonDecode(raw) as Map<String, dynamic>;
  return (base64Decode(j['data'] as String), (j['mime'] as String?) ?? 'audio/webm');
}

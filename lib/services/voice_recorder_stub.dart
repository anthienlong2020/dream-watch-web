import 'dart:typed_data';

bool get canRecordVoice => false;
Future<bool> startVoiceRecording() async => false;
Future<(Uint8List, String)?> stopVoiceRecording() async => null;
Future<void> playVoiceBytes(Uint8List bytes, String mime, {double volume = 1.0}) async {}

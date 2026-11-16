import 'dart:js_interop';

@JS('dwInstall.state')
external JSString _state();

@JS('dwInstall.platform')
external JSString _platform();

@JS('dwInstall.prompt')
external JSPromise<JSString> _prompt();

/// 'installed' (đang chạy như app / vừa cài), 'ready' (Chrome cho bấm Cài ngay),
/// 'manual' (phải làm theo hướng dẫn), 'unsupported'.
String installState() {
  try {
    return _state().toDart;
  } catch (_) {
    return 'manual';
  }
}

/// 'android', 'ios', 'desktop', hoặc 'inapp' (trình duyệt nhúng trong Facebook, TikTok, Zalo…).
String installPlatform() {
  try {
    return _platform().toDart;
  } catch (_) {
    return 'desktop';
  }
}

/// Hiện hộp "Cài đặt" của trình duyệt. Trả về 'accepted', 'dismissed' hoặc 'unavailable'.
Future<String> promptInstall() async {
  try {
    return (await _prompt().toDart).toDart;
  } catch (_) {
    return 'unavailable';
  }
}

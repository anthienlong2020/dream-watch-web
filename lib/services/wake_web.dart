import 'dart:js_interop';

@JS('dwWake.supported')
external JSBoolean _supported();

@JS('dwWake.active')
external JSBoolean _active();

@JS('dwBattery.charging')
external JSAny? _charging();

@JS('dwWake.set')
external void _set(JSBoolean on);

/// Trình duyệt này có cho giữ màn hình sáng không
/// (Chrome Android: có; iPhone: Safari iOS 16.4+, app ngoài màn hình chính iOS 18.4+).
bool wakeSupported() {
  try {
    return _supported().toDart;
  } catch (_) {
    return false;
  }
}

/// Đang giữ màn hình sáng thật sự chưa.
bool wakeActive() {
  try {
    return _active().toDart;
  } catch (_) {
    return false;
  }
}

void setWake(bool on) {
  try {
    _set(on.toJS);
  } catch (_) {}
}

/// Máy có đang cắm sạc không. null: trình duyệt không cho biết (vd. iPhone).
bool? isCharging() {
  try {
    final v = _charging()?.dartify();
    return v is bool ? v : null;
  } catch (_) {
    return null;
  }
}

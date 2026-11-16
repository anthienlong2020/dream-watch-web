/// Ngoài web: app native dùng wakelock_plus (xem app_state.dart).
bool wakeSupported() => true;
bool wakeActive() => false;
void setWake(bool on) {}

/// Máy có đang cắm sạc không (null: không biết).
bool? isCharging() => null;

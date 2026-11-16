import 'dart:async';

import 'package:flutter/widgets.dart';

/// Đang chạy bằng pin (máy không cắm sạc). AppState đặt giá trị này;
/// tách riêng để các mặt đồng hồ không phải khởi tạo cả AppState.
final ValueNotifier<bool> powerSavingNotifier = ValueNotifier(false);

/// "Nhịp khung hình" cho các mặt đồng hồ.
///
/// Bình thường vẽ lại theo màn hình (60 hình/giây). Khi máy không cắm sạc
/// (`powerSavingNotifier`), chỉ vẽ ~12 hình/giây để đỡ hao pin: mọi chuyển động
/// vẫn tính theo giờ thực nên chỉ hơi kém mượt, không chậm đi.
class ClockFrame extends ChangeNotifier {
  ClockFrame(TickerProvider vsync)
      : _ctrl = AnimationController(vsync: vsync, duration: const Duration(seconds: 1)) {
    _ctrl.addListener(notifyListeners);
    powerSavingNotifier.addListener(_apply);
    _apply();
  }

  final AnimationController _ctrl;
  Timer? _timer;
  bool? _slow;

  void _apply() {
    final slow = powerSavingNotifier.value;
    if (slow == _slow) return;
    _slow = slow;
    if (slow) {
      _ctrl.stop();
      _timer ??= Timer.periodic(const Duration(milliseconds: 83), (_) => notifyListeners());
    } else {
      _timer?.cancel();
      _timer = null;
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    powerSavingNotifier.removeListener(_apply);
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }
}

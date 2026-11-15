import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Cho phép kéo cuộn bằng chuột (giống vuốt trên điện thoại), dùng khi chạy trên PC.
class DragAllScrollBehavior extends MaterialScrollBehavior {
  const DragAllScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Chế độ quay video: ẩn con trỏ chuột, thay bằng chấm tròn mờ như đầu ngón tay,
/// to và đậm hơn khi bấm giữ. Bật bằng link có `?touchdot=1` (trang phone.html tự bật).
class TouchDot extends StatefulWidget {
  final Widget child;
  const TouchDot({super.key, required this.child});

  static bool get enabled => Uri.base.queryParameters['touchdot'] == '1';

  @override
  State<TouchDot> createState() => _TouchDotState();
}

class _TouchDotState extends State<TouchDot> {
  Offset? _pos;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (e) => setState(() => _pos = e.localPosition),
      onExit: (_) => setState(() => _pos = null),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => setState(() {
          _pos = e.localPosition;
          _down = true;
        }),
        onPointerMove: (e) => setState(() => _pos = e.localPosition),
        onPointerUp: (e) => setState(() => _down = false),
        onPointerCancel: (e) => setState(() => _down = false),
        child: Stack(
          children: [
            widget.child,
            if (_pos != null)
              Positioned(
                left: _pos!.dx - 22,
                top: _pos!.dy - 22,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _down ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(_down ? 110 : 55),
                        border: Border.all(color: Colors.white.withAlpha(_down ? 200 : 120), width: 2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

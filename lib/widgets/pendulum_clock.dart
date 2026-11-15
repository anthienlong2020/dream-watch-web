import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Đồng hồ quả lắc cổ (bản Standard): ảnh đồng hồ cây gỗ, mặt đồng thau đã xoá số,
/// quả lắc đàn lia đung đưa; 12 hình (con số hoặc ảnh riêng) đặt khớp lên vành số.
///
/// Toạ độ tính theo ảnh nền gốc 725 × 2049 px (assets/standard/clock_bg.webp).
class PendulumClock extends StatefulWidget {
  /// Gọi mỗi khi qua 1 giây (để phát tiếng tích tắc), [even] = giây chẵn.
  final void Function(bool even)? onTick;
  final String dateText;

  /// Mặt đồng hồ hình ảnh (12 hình giờ/phút/giây) đặt khớp lên vành số.
  final Widget? face;
  const PendulumClock({super.key, this.onTick, this.dateText = '', this.face});

  // ---- toạ độ trong ảnh nền ----
  static const double imgW = 725, imgH = 2049;
  static const Offset dialCenter = Offset(362, 565);
  static const double ringRadius = 190; // bán kính vòng đặt 12 hình
  static const Offset spriteTopLeft = Offset(160, 920); // vị trí ảnh quả lắc
  static const Offset pivotInSprite = Offset(202, 20); // điểm treo trong ảnh quả lắc
  static const double spriteW = 405, spriteH = 1129;

  @override
  State<PendulumClock> createState() => _PendulumClockState();
}

class _PendulumClockState extends State<PendulumClock> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  int _lastSec = -1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      // Đầu đồng hồ (mặt số + trăng lịch) phóng to, căn giữa
      const hx0 = 40.0, headW = 645.0, headH = 925.0;
      var hs = w / headW;
      if (headH * hs > h * 0.7) hs = h * 0.7 / headH; // màn hình ngang / máy tính bảng
      final headLeft = (w - headW * hs) / 2;
      final headPx = headH * hs;
      // Thân đồng hồ (quả lắc) thu gọn cho vừa phần còn lại, căn giữa
      const tY0 = 925.0, tH = 1035.0, tW = PendulumClock.imgW;
      final rest = math.max(0.0, h - headPx);
      final ts = rest / tH;
      final trunkW = tW * ts;
      final trunkLeft = (w - trunkW) / 2;
      final dial = Offset(headLeft + (PendulumClock.dialCenter.dx - hx0) * hs, PendulumClock.dialCenter.dy * hs);
      final side = PendulumClock.ringRadius * hs / 0.40;

      Widget bg(double scale, double dx, double dy) => Positioned(
            left: -dx * scale,
            top: -dy * scale,
            width: PendulumClock.imgW * scale,
            height: PendulumClock.imgH * scale,
            child: Image.asset('assets/standard/clock_bg.webp', fit: BoxFit.fill),
          );

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // tường tối ấm
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.1,
                  colors: [Color(0xFF3A2618), Color(0xFF120A06)],
                ),
              ),
            ),
          ),
          // thân + quả lắc
          if (rest > 20)
            Positioned(
              left: trunkLeft,
              top: headPx - 2,
              width: trunkW,
              height: rest + 2,
              child: DecoratedBox(
                decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 18)]),
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      bg(ts, 0, tY0),
                      Positioned(
                        left: PendulumClock.spriteTopLeft.dx * ts,
                        top: (PendulumClock.spriteTopLeft.dy - tY0) * ts,
                        width: PendulumClock.spriteW * ts,
                        height: PendulumClock.spriteH * ts,
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (context, child) {
                            final now = DateTime.now();
                            if (now.second != _lastSec) {
                              if (_lastSec != -1) widget.onTick?.call(now.second.isEven);
                              _lastSec = now.second;
                            }
                            final ms = now.millisecondsSinceEpoch % 2000;
                            final ang = 0.06 * math.cos(ms / 2000 * 2 * math.pi);
                            return Transform.rotate(
                              angle: ang,
                              alignment: Alignment(
                                PendulumClock.pivotInSprite.dx / PendulumClock.spriteW * 2 - 1,
                                PendulumClock.pivotInSprite.dy / PendulumClock.spriteH * 2 - 1,
                              ),
                              child: child,
                            );
                          },
                          child: Image.asset('assets/standard/pendulum.webp', fit: BoxFit.fill),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // đầu đồng hồ
          Positioned(
            left: headLeft,
            top: 0,
            width: headW * hs,
            height: headPx,
            child: DecoratedBox(
              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 14)]),
              child: ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: [bg(hs, hx0, 0)])),
            ),
          ),
          if (widget.face != null)
            Positioned(
              left: dial.dx - side / 2,
              top: dial.dy - side / 2,
              width: side,
              height: side,
              child: widget.face!,
            ),
          // ngày tháng trên thanh gỗ dưới mặt số
          if (widget.dateText.isNotEmpty)
            Positioned(
              left: headLeft + 50 * hs,
              width: (headW - 100) * hs,
              top: 866 * hs,
              height: 50 * hs,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.dateText,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF3D27A),
                    shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

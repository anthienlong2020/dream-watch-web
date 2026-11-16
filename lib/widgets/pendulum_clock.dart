import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'clock_frame.dart';

/// Đồng hồ quả lắc cổ (bản Standard): ảnh đồng hồ cây gỗ, mặt đồng thau đã xoá số,
/// quả lắc đàn lia đung đưa; 12 hình (con số hoặc ảnh riêng) đặt khớp lên vành số.
///
/// Ảnh đầu đồng hồ (Gemini tạo, đã xoá số + kim): assets/standard/head.webp 1200 × 1385.
/// Ảnh thân quả lắc: assets/standard/trunk.webp 725 × 1035 + quả lắc pendulum.webp.
class PendulumClock extends StatefulWidget {
  /// Gọi mỗi khi qua 1 giây (để phát tiếng tích tắc), [even] = giây chẵn.
  final void Function(bool even)? onTick;
  final String dateText;

  /// Mặt đồng hồ hình ảnh (12 hình giờ/phút/giây) đặt khớp lên vành số.
  final Widget? face;

  /// true = mặt số giữ nguyên 12 số khắc của ảnh (bản Standard);
  /// false = mặt số đã xoá số để đặt hình ảnh chuyển động lên (bản Pro).
  final bool engravedNumbers;
  const PendulumClock({super.key, this.onTick, this.dateText = '', this.face, this.engravedNumbers = false});

  /// Đường kính vòng ngoài mặt số trong ảnh đầu (để phóng to bằng mặt đồng hồ bản Pro).
  static const double dialDiameter = 920;

  // ---- toạ độ trong ảnh đầu đồng hồ ----
  static const double headW = 1200, headH = 1385;
  static const Offset dialCenter = Offset(599.7, 838.2);
  static const double ringRadius = 354.2; // bán kính vòng 12 ô số
  // ---- toạ độ trong ảnh thân ----
  static const double trunkW = 725, trunkH = 1035;
  static const Offset spriteTopLeft = Offset(160, -5); // vị trí ảnh quả lắc trong ảnh thân
  static const Offset pivotInSprite = Offset(202, 20); // điểm treo trong ảnh quả lắc
  static const double spriteW = 405, spriteH = 1129;

  @override
  State<PendulumClock> createState() => _PendulumClockState();
}

class _PendulumClockState extends State<PendulumClock> with SingleTickerProviderStateMixin {
  late final ClockFrame _c = ClockFrame(this);
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
      const headW = PendulumClock.headW, headH = PendulumClock.headH;
      // phóng cận: mặt số rộng ~95% bề ngang (bằng mặt đồng hồ bản Pro), hai bên cột gỗ bị cắt bớt
      var hs = w * 0.95 / PendulumClock.dialDiameter;
      if (headH * hs > h * 0.72) hs = h * 0.72 / headH; // màn hình ngang / máy tính bảng
      final headLeft = w / 2 - PendulumClock.dialCenter.dx * hs;
      final headPx = headH * hs;
      // Thân đồng hồ (quả lắc) thu gọn cho vừa phần còn lại, căn giữa
      const tH = PendulumClock.trunkH, tW = PendulumClock.trunkW;
      final rest = math.max(0.0, h - headPx);
      final ts = rest / tH;
      final trunkW = tW * ts;
      final trunkLeft = (w - trunkW) / 2;
      final dial = Offset(headLeft + PendulumClock.dialCenter.dx * hs, PendulumClock.dialCenter.dy * hs);
      final side = PendulumClock.ringRadius * hs / 0.40;

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
                      Positioned.fill(child: Image.asset('assets/standard/trunk.webp', fit: BoxFit.fill)),
                      Positioned(
                        left: PendulumClock.spriteTopLeft.dx * ts,
                        top: PendulumClock.spriteTopLeft.dy * ts,
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
              child: Image.asset(
                  widget.engravedNumbers ? 'assets/standard/head_numbers.webp' : 'assets/standard/head.webp',
                  fit: BoxFit.fill),
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
              left: headLeft + 150 * hs,
              width: (headW - 300) * hs,
              top: 1328 * hs,
              height: 52 * hs,
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

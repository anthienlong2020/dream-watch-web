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
    const side = PendulumClock.ringRadius / 0.40; // vòng hình của DreamClock = 0.40 × cạnh
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: PendulumClock.imgW,
          height: PendulumClock.imgH,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset('assets/standard/clock_bg.webp', fit: BoxFit.fill)),
              // quả lắc: chu kỳ 2 giây, chạm biên đúng lúc tích – tắc
              Positioned(
                left: PendulumClock.spriteTopLeft.dx,
                top: PendulumClock.spriteTopLeft.dy,
                width: PendulumClock.spriteW,
                height: PendulumClock.spriteH,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) {
                    final now = DateTime.now();
                    if (now.second != _lastSec) {
                      if (_lastSec != -1) widget.onTick?.call(now.second.isEven);
                      _lastSec = now.second;
                    }
                    final ms = now.millisecondsSinceEpoch % 2000;
                    final ang = 0.05 * math.cos(ms / 2000 * 2 * math.pi);
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
              if (widget.face != null)
                Positioned(
                  left: PendulumClock.dialCenter.dx - side / 2,
                  top: PendulumClock.dialCenter.dy - side / 2,
                  width: side,
                  height: side,
                  child: widget.face!,
                ),
              // ngày tháng khắc trên thanh gỗ dưới mặt số
              if (widget.dateText.isNotEmpty)
                Positioned(
                  left: 60,
                  right: 60,
                  top: 868,
                  height: 48,
                  child: Center(
                    child: Text(
                      widget.dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ),
    );
  }
}

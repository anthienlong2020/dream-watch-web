import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Mặt số cổ điển cho bản Standard: 12 con số vàng đứng yên đúng vị trí + kim giờ, phút, giây
/// kiểu thép xanh chạm hoa (như đồng hồ cây thật). Kích thước theo khung vuông của DreamClock
/// (vòng số = 0.40 × cạnh) để khớp vị trí trên mặt đồng hồ.
class ClassicDial extends StatefulWidget {
  /// false = không vẽ 12 số (mặt số trong ảnh đã có số khắc sẵn).
  final bool showNumbers;
  const ClassicDial({super.key, this.showNumbers = true});

  @override
  State<ClassicDial> createState() => _ClassicDialState();
}

class _ClassicDialState extends State<ClassicDial> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(c.maxWidth, c.maxHeight);
      final ring = s * 0.40;
      final slot = s * 0.19;
      return Center(
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(children: [
            if (widget.showNumbers)
            for (var n = 1; n <= 12; n++)
              Positioned(
                left: s / 2 + ring * math.sin(n / 12 * 2 * math.pi) - slot / 2,
                top: s / 2 - ring * math.cos(n / 12 * 2 * math.pi) - slot / 2,
                width: slot,
                height: slot,
                child: Image.asset('assets/themes/so/$n.png', fit: BoxFit.contain),
              ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final now = DateTime.now();
                  final h = now.hour % 12, m = now.minute, sec = now.second, ms = now.millisecond;
                  final hourA = (h + m / 60 + sec / 3600) / 12 * 2 * math.pi;
                  final minA = (m + sec / 60) / 60 * 2 * math.pi;
                  // kim giây nhảy từng tích, nảy nhẹ như máy cơ
                  final bounce = ms < 150 ? math.sin(ms / 150 * math.pi) * 0.15 : 0.0;
                  final secA = (sec + bounce) / 60 * 2 * math.pi;
                  final c = Offset(s / 2, s / 2);
                  return Stack(children: [
                    ..._hand(_kHour, c, hourA, ring * 0.62),
                    ..._hand(_kMinute, c, minA, ring * 0.93),
                    ..._hand(_kSecond, c, secA, ring * 0.98),
                  ]);
                },
              ),
            ),
          ]),
        ),
      );
    });
  }
}

/// Ảnh kim (Gemini tạo, đã tách nền): kích thước ảnh, tâm lỗ trục, đỉnh mũi kim.
class _HandSprite {
  final String asset;
  final double w, h, px, py, tipY;
  const _HandSprite(this.asset, this.w, this.h, this.px, this.py, this.tipY);
}

const _kHour = _HandSprite('assets/standard/hand_hour.webp', 94, 402, 51.5, 363.2, 6);
const _kMinute = _HandSprite('assets/standard/hand_minute.webp', 82, 434, 43.2, 348.9, 6);
const _kSecond = _HandSprite('assets/standard/hand_second.webp', 45, 451, 22.5, 340, 6);

/// Một kim ảnh: phóng sao cho từ trục tới mũi dài [len], xoay quanh lỗ trục.
/// Có viền tối mờ quanh kim + bóng đổ để kim vàng nổi rõ trên mặt đồng thau cùng màu.
List<Widget> _hand(_HandSprite sp, Offset c, double angle, double len) {
  final k = len / (sp.py - sp.tipY);
  const boldX = 1.3; // làm kim đậm hơn một chút cho dễ nhìn trên điện thoại
  final kx = k * boldX;
  final w = sp.w * kx, h = sp.h * k;
  final align = Alignment(sp.px / sp.w * 2 - 1, sp.py / sp.h * 2 - 1);
  Widget img(Offset shift, {Color? tint, double blur = 0}) {
    Widget child = Image.asset(sp.asset, fit: BoxFit.fill);
    if (tint != null) child = ColorFiltered(colorFilter: ColorFilter.mode(tint, BlendMode.srcIn), child: child);
    if (blur > 0) child = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: child);
    return Positioned(
      left: c.dx - sp.px * kx + shift.dx,
      top: c.dy - sp.py * k + shift.dy,
      width: w,
      height: h,
      child: Transform.rotate(angle: angle, alignment: align, child: child),
    );
  }

  return [
    img(Offset(len * 0.03, len * 0.05), tint: const Color(0x77000000), blur: len * 0.02), // bóng đổ
    img(Offset.zero, tint: const Color(0xEE2A1A05), blur: len * 0.012), // viền tối
    img(Offset.zero),
  ];
}

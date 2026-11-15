import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mặt số cổ điển cho bản Standard: 12 con số vàng đứng yên đúng vị trí + kim giờ, phút, giây
/// kiểu thép xanh chạm hoa (như đồng hồ cây thật). Kích thước theo khung vuông của DreamClock
/// (vòng số = 0.40 × cạnh) để khớp vị trí trên mặt đồng hồ.
class ClassicDial extends StatefulWidget {
  const ClassicDial({super.key});

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
      final slot = s * 0.17;
      return Center(
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(children: [
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
                builder: (context, _) => CustomPaint(painter: _HandsPainter(DateTime.now(), ring)),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _HandsPainter extends CustomPainter {
  final DateTime now;
  final double ring;
  _HandsPainter(this.now, this.ring);

  static const _steel = Color(0xFF1E2430);
  static const _steelHi = Color(0xFF4A5A78);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final h = now.hour % 12, m = now.minute, s = now.second, ms = now.millisecond;
    final hourA = (h + m / 60 + s / 3600) / 12 * 2 * math.pi;
    final minA = (m + s / 60) / 60 * 2 * math.pi;
    // kim giây nhảy từng tic, nảy nhẹ như máy cơ
    final bounce = ms < 150 ? math.sin(ms / 150 * math.pi) * 0.15 : 0.0;
    final secA = (s + bounce) / 60 * 2 * math.pi;

    _ornateHand(canvas, c, hourA, ring * 0.58, ring * 0.075);
    _ornateHand(canvas, c, minA, ring * 0.88, ring * 0.055);
    // kim giây mảnh màu đồng
    _rotated(canvas, c, secA, () {
      final p = Paint()
        ..color = const Color(0xFF8B5A1A)
        ..strokeWidth = math.max(1.2, ring * 0.012)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, ring * 0.2), Offset(0, -ring * 0.95), p);
      canvas.drawCircle(Offset(0, ring * 0.16), ring * 0.035, Paint()..color = const Color(0xFF8B5A1A));
    });
    // trục giữa
    canvas.drawCircle(c, ring * 0.06,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFF1B0), Color(0xFF9C7420)])
              .createShader(Rect.fromCircle(center: c, radius: ring * 0.06)));
    canvas.drawCircle(c, ring * 0.022, Paint()..color = _steel);
  }

  void _rotated(Canvas canvas, Offset c, double a, void Function() draw) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(a);
    draw();
    canvas.restore();
  }

  /// Kim chạm hoa: thân thon, vòng hoa văn ở giữa, đầu mũi giáo; vẽ hướng lên (12 giờ) rồi xoay.
  void _ornateHand(Canvas canvas, Offset c, double a, double len, double w) {
    // bóng đổ
    canvas.save();
    canvas.translate(2, 3);
    _rotated(canvas, c, a, () => _handShape(canvas, len, w, const Color(0x55000000), blur: true));
    canvas.restore();
    _rotated(canvas, c, a, () => _handShape(canvas, len, w, _steel));
  }

  void _handShape(Canvas canvas, double len, double w, Color col, {bool blur = false}) {
    final p = Paint()..color = col;
    if (blur) p.maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.4);
    final stroke = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.32
      ..strokeCap = StrokeCap.round;
    if (blur) stroke.maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.4);
    // đuôi kim
    canvas.drawLine(Offset(0, len * 0.18), Offset(0, -len * 0.3), stroke..strokeWidth = w * 0.45);
    canvas.drawCircle(Offset(0, len * 0.18), w * 0.45, p);
    // vòng hoa văn (2 vòng lồng nhau)
    final ringC = Offset(0, -len * 0.42);
    canvas.drawCircle(ringC, w * 1.15, stroke..strokeWidth = w * 0.3);
    canvas.drawCircle(ringC + Offset(-w * 0.7, -w * 0.9), w * 0.55, stroke..strokeWidth = w * 0.22);
    canvas.drawCircle(ringC + Offset(w * 0.7, -w * 0.9), w * 0.55, stroke);
    // thân mảnh lên đầu mũi
    canvas.drawLine(ringC + Offset(0, -w * 1.1), Offset(0, -len * 0.82), stroke..strokeWidth = w * 0.32);
    // mũi giáo
    final tip = Path()
      ..moveTo(0, -len)
      ..quadraticBezierTo(w * 1.1, -len * 0.86, 0, -len * 0.78)
      ..quadraticBezierTo(-w * 1.1, -len * 0.86, 0, -len)
      ..close();
    canvas.drawPath(tip, p);
    if (!blur) {
      // ánh xanh thép
      canvas.drawLine(Offset(-w * 0.08, -len * 0.5), Offset(-w * 0.08, -len * 0.8),
          Paint()
            ..color = _steelHi
            ..strokeWidth = math.max(0.6, w * 0.08));
    }
  }

  @override
  bool shouldRepaint(_HandsPainter o) => o.now != now || o.ring != ring;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'season_theme.dart';
import '../effects/element_effect.dart';

// =====================================================================
// Lớp hiệu ứng theme phủ lên toàn màn hình (không nhận chạm).
// Mọi hạt tính theo thời gian thực từ "hạt giống" cố định, nên không cần
// lưu trạng thái và luôn mượt.
// =====================================================================

double _rnd(int a, int b, [int c = 0]) {
  var x = a * 374761393 + b * 668265263 + c * 2147483647;
  x = (x ^ (x >> 13)) * 1274126177;
  x = x ^ (x >> 16);
  return (x & 0xFFFFFF) / 0xFFFFFF;
}

/// Phủ hiệu ứng của [theme] lên vùng chứa. [time] tính bằng giây.
class ThemeOverlay extends StatelessWidget {
  final SeasonTheme theme;
  final double time;
  const ThemeOverlay({super.key, required this.theme, required this.time});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: ThemePainter(theme, time), size: Size.infinite),
      ),
    );
  }
}

class ThemePainter extends CustomPainter {
  final SeasonTheme theme;
  final double t;
  ThemePainter(this.theme, this.t);

  static final Map<String, TextPainter> _emojiCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final glow = theme.glow;
    if (glow != null) {
      // quầng sáng nhẹ trên và dưới màn hình
      final rect = Offset.zero & size;
      canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [glow, glow.withAlpha(0), glow.withAlpha(0), glow],
              stops: const [0.0, 0.25, 0.75, 1.0],
            ).createShader(rect));
    }
    var li = 0;
    for (final l in theme.layers) {
      _layer(canvas, size, l, li++);
    }
  }

  void _layer(Canvas canvas, Size size, Layer l, int li) {
    final w = size.width, h = size.height;
    final unit = math.min(w, h);
    // Mật độ: quà, lá, hoa, con vật... rơi/bay nhiều hơn hẳn
    final n = (l.count * switch (l.motion) {
      Motion.fall || Motion.rise => 3.0,
      Motion.fly => 2.5,
      Motion.wander || Motion.twinkle => 2.0,
      Motion.bounce => 1.7,
      _ => 1.0,
    }).round();
    for (var k = 0; k < n; k++) {
      final seed = li * 1000 + k;
      final r0 = _rnd(seed, 1), r1 = _rnd(seed, 2), r2 = _rnd(seed, 3);
      final sz = unit * (l.minSize + (l.maxSize - l.minSize) * r2);
      final col = l.colors[(seed * 7) % l.colors.length];
      final speed = l.speed * (0.7 + 0.6 * r1);
      switch (l.motion) {
        case Motion.fall:
        case Motion.rise:
          final ph = (t * speed + r0) % 1.0;
          final cyc = (t * speed + r0).floor();
          final x = w * _rnd(seed, cyc, 9) + math.sin(t * 1.3 + k) * unit * l.sway;
          final y = l.motion == Motion.fall ? -0.1 * h + ph * 1.2 * h : 1.1 * h - ph * 1.2 * h;
          _shape(canvas, l, Offset(x, y), sz, col, t * (1 + r1) + k, seed);
          break;
        case Motion.fly:
          final ph = (t * speed + r0) % 1.0;
          final dir = r1 < 0.5 ? 1.0 : -1.0;
          final x = dir > 0 ? -0.1 * w + ph * 1.2 * w : 1.1 * w - ph * 1.2 * w;
          final y = h * (0.08 + 0.5 * r2) + math.sin(t * 2 + k) * unit * 0.03;
          canvas.save();
          canvas.translate(x, y);
          // emoji con vật mặc định quay mặt sang trái → lật khi bay sang phải
          final faceLeft = l.shape == Shape.emoji;
          if ((dir < 0) != faceLeft) canvas.scale(-1, 1);
          _shape(canvas, l, Offset.zero, sz, col, t * 8 + k, seed);
          canvas.restore();
          break;
        case Motion.wander:
          final x = w * r0 + math.sin(t * 0.4 * (0.5 + r1) + k) * unit * 0.08;
          final y = h * r2 + math.cos(t * 0.33 * (0.5 + r0) + k * 1.7) * unit * 0.08;
          _shape(canvas, l, Offset(x, y), sz, col, t + k, seed);
          break;
        case Motion.twinkle:
          final a = (0.5 + 0.5 * math.sin(t * (1.5 + 2 * r1) + k * 2.1)).clamp(0.0, 1.0);
          if (a < 0.1) break;
          _shape(canvas, l, Offset(w * r0, h * r2 * 0.9), sz * (0.5 + 0.5 * a),
              col.withAlpha((a * col.alpha).round()), 0, seed);
          break;
        case Motion.burst:
          _firework(canvas, size, l, k, seed, unit);
          break;
        case Motion.garland:
          if (k == 0) _garland(canvas, size, l, unit);
          break;
        case Motion.collide:
          _collide(canvas, size, l, k, seed, unit);
          break;
        case Motion.aurora:
          _aurora(canvas, size, l, k, unit);
          break;
        case Motion.waterfall:
          _waterfall(canvas, size, l, k, seed, unit);
          break;
        case Motion.sleigh:
          if (k == 0) _sleigh(canvas, size, l, unit);
          break;
        case Motion.bounce:
          // nhảy tưng tưng, chạy qua lại khắp màn hình
          final x = w * (0.5 + 0.42 * math.sin(t * 0.13 * (0.6 + r1) + k * 2.3));
          final baseY = h * (0.2 + 0.65 * r2);
          final hop = (math.sin(t * l.speed * math.pi * (0.8 + 0.4 * r0) + k)).abs();
          final y = baseY - hop * unit * 0.08;
          _shape(canvas, l, Offset(x, y), sz, col, t * 0.8 + k, seed);
          break;
        case Motion.moon:
          final c = Offset(w * 0.82, h * 0.12);
          final r = unit * 0.07;
          canvas.drawCircle(c, r * 1.8,
              Paint()
                ..color = col.withAlpha(60)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
          canvas.drawCircle(c, r, Paint()..color = col);
          canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.1), r * 0.18, Paint()..color = const Color(0x22000000));
          canvas.drawCircle(c + Offset(r * 0.25, r * 0.3), r * 0.12, Paint()..color = const Color(0x1A000000));
          break;
      }
    }
  }

  /// Pháo hoa: mỗi chùm nổ ở một chỗ ngẫu nhiên, bung tròn rồi tắt dần.
  void _firework(Canvas canvas, Size size, Layer l, int k, int seed, double unit) {
    final x = t * l.speed + k / l.count;
    final cyc = x.floor();
    final ph = x - cyc;
    if (ph > 0.75) return; // nghỉ giữa các lần bắn
    final p = ph / 0.75;
    final c = Offset(size.width * (0.15 + 0.7 * _rnd(seed, cyc, 1)), size.height * (0.1 + 0.4 * _rnd(seed, cyc, 2)));
    final col = l.colors[(cyc + k) % l.colors.length];
    final r = unit * (0.12 + 0.08 * _rnd(seed, cyc, 3)) * Curves.easeOut.transform(p);
    final alpha = ((1 - p) * 255).round();
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      final q = c + Offset(math.cos(a), math.sin(a) + p * 0.25) * r;
      canvas.drawCircle(q, unit * 0.006 + 1,
          Paint()
            ..color = col.withAlpha(alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.004));
    }
    canvas.drawCircle(c, r * 0.25,
        Paint()
          ..color = col.withAlpha((alpha * 0.3).round())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.03));
  }

  /// Bi màu (Holi): 2 viên lao vào nhau, chạm nhau thì nổ tung thành bụi màu.
  void _collide(Canvas canvas, Size size, Layer l, int k, int seed, double unit) {
    final x = t * l.speed + k / l.count;
    final cyc = x.floor();
    final ph = x - cyc;
    final m = Offset(size.width * (0.2 + 0.6 * _rnd(seed, cyc, 1)), size.height * (0.15 + 0.6 * _rnd(seed, cyc, 2)));
    final ang = _rnd(seed, cyc, 3) * math.pi;
    final dir = Offset(math.cos(ang), math.sin(ang));
    final ca = l.colors[(cyc * 3 + k) % l.colors.length];
    final cb = l.colors[(cyc * 3 + k + 2) % l.colors.length];
    final r = unit * (l.minSize + (l.maxSize - l.minSize) * _rnd(seed, cyc, 4)) / 2;
    const hit = 0.45;
    if (ph < hit) {
      final d = unit * 0.45 * (1 - Curves.easeIn.transform(ph / hit)) + r;
      for (final (c, sign) in [(ca, 1.0), (cb, -1.0)]) {
        final p = m + dir * (d * sign);
        canvas.drawCircle(p, r, Paint()..color = c);
        canvas.drawCircle(p + Offset(-r * 0.35, -r * 0.35), r * 0.3, Paint()..color = const Color(0x88FFFFFF));
      }
      return;
    }
    // nổ tung: bụi màu của cả 2 viên trộn vào nhau, lan rộng rồi tan dần
    final p = (ph - hit) / (1 - hit);
    final spread = unit * 0.22 * Curves.easeOut.transform(p);
    final alpha = ((1 - p) * 200).round();
    for (var i = 0; i < 26; i++) {
      final a = _rnd(seed, cyc * 50 + i, 5) * 2 * math.pi;
      final dd = spread * (0.3 + 0.7 * _rnd(seed, cyc * 50 + i, 6));
      final q = m + Offset(math.cos(a), math.sin(a)) * dd + Offset(0, p * unit * 0.03);
      final rr = r * (0.5 + 1.3 * p) * (0.6 + 0.8 * _rnd(seed, cyc * 50 + i, 7));
      canvas.drawCircle(
          q,
          rr,
          Paint()
            ..color = (i.isEven ? ca : cb).withAlpha(alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, rr * 0.7));
    }
  }

  /// Dải cực quang uốn lượn như rèm sáng ở nửa trên màn hình.
  void _aurora(Canvas canvas, Size size, Layer l, int k, double unit) {
    final w = size.width, h = size.height;
    // 12 màu trong danh sách Màu, xếp theo vòng sắc độ; các dải cạnh nhau lệch 5 bậc
    // (~150°) nên luôn tương phản, cả dàn đổi màu lần lượt mỗi ~6 giây.
    const order = [
      ElemColor.vang, ElemColor.cam, ElemColor.doo, ElemColor.hong, ElemColor.tim, ElemColor.lam,
      ElemColor.lucBao, ElemColor.ngocBich, ElemColor.bacHa, ElemColor.trongSuot, ElemColor.bachKim,
      ElemColor.cauVong,
    ];
    final cx = t / 6;
    final ci = cx.floor();
    final f = Curves.easeInOut.transform(cx - ci);
    Color at(int i) => elemColorValue(ElementType.none, order[i % order.length], t + k);
    final col = Color.lerp(at(ci + k * 5), at(ci + 1 + k * 5), f)!;
    final baseY = h * (0.06 + 0.09 * k);
    final height = unit * (0.16 + 0.05 * math.sin(t * 0.3 + k));
    const steps = 48;
    double yAt(double x) =>
        baseY +
        math.sin(x / w * 2 * math.pi * 1.1 + t * l.speed * 2 * math.pi + k * 1.7) * unit * 0.05 +
        math.sin(x / w * 2 * math.pi * 2.7 - t * l.speed * 3 + k) * unit * 0.015;
    final top = Path()..moveTo(0, yAt(0));
    for (var i = 1; i <= steps; i++) {
      final x = w * i / steps;
      top.lineTo(x, yAt(x));
    }
    final band = Path.from(top);
    for (var i = steps; i >= 0; i--) {
      final x = w * i / steps;
      band.lineTo(x, yAt(x) + height * (0.7 + 0.3 * math.sin(x / w * 9 + t + k)));
    }
    band.close();
    final shimmer = 0.6 + 0.4 * math.sin(t * 0.8 + k * 2);
    canvas.drawPath(
        band,
        Paint()
          ..color = col.withAlpha((55 * shimmer).round())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.03));
    // tia rèm dọc lung linh
    final ray = Paint()..strokeWidth = math.max(1, unit * 0.006);
    for (var i = 0; i < steps; i++) {
      final x = w * (i + 0.5) / steps;
      final a = (0.5 + 0.5 * math.sin(x * 0.05 + t * 2 + k)) * 90 * shimmer;
      final y = yAt(x);
      ray.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [col.withAlpha(a.round()), col.withAlpha(0)],
      ).createShader(Rect.fromLTWH(x, y, 1, height));
      canvas.drawLine(Offset(x, y), Offset(x, y + height), ray);
    }
  }

  /// Thác nước: các dòng nước đổ xuống từng đợt, bắn tung toé ở đáy.
  void _waterfall(Canvas canvas, Size size, Layer l, int k, int seed, double unit) {
    final w = size.width, h = size.height;
    final x0 = w * (0.08 + 0.84 * (k + 0.5) / l.count) + math.sin(t * 0.7 + k) * unit * 0.01;
    final width = unit * (0.03 + 0.02 * _rnd(seed, 1));
    final col = l.colors[k % l.colors.length];
    for (var j = 0; j < 2; j++) {
      final ph = (t * l.speed * (0.8 + 0.4 * _rnd(seed, 2)) + _rnd(seed, 3) + j * 0.5) % 1.0;
      final head = -0.2 * h + ph * 1.5 * h; // đầu đợt nước
      final len = h * 0.38;
      final top = math.max(0.0, head - len), bottom = math.min(h, head);
      if (bottom > top) {
        final rect = Rect.fromLTRB(x0 - width / 2, top, x0 + width / 2, bottom);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(width / 2)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [col.withAlpha(0), col.withAlpha(150), Colors.white.withAlpha(210)],
                stops: const [0.0, 0.7, 1.0],
              ).createShader(rect));
      }
      // bắn tung toé khi đợt nước chạm đáy
      if (head > h && head < h * 1.3) {
        final p = (head - h) / (h * 0.3);
        final al = ((1 - p) * 220).round();
        for (var i = 0; i < 9; i++) {
          final a = math.pi * (1.1 + 0.8 * i / 8);
          final v = unit * (0.06 + 0.06 * _rnd(seed, i, 4));
          final q = Offset(x0 + math.cos(a) * v * p * 1.6, h + math.sin(a) * v * p * 2 + p * p * unit * 0.12);
          canvas.drawCircle(q, unit * 0.007, Paint()..color = Colors.white.withAlpha(al));
        }
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x0, h - unit * 0.01), width: width * 3, height: unit * 0.05),
            Paint()
              ..color = Colors.white.withAlpha((al * 0.5).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.02));
      }
    }
  }

  /// Ông già Noel trên xe tuần lộc bay ngang trời, để lại vệt kim tuyến.
  void _sleigh(Canvas canvas, Size size, Layer l, double unit) {
    final ph = (t * l.speed) % 1.0;
    if (ph > 0.6) return; // nghỉ giữa các lần bay qua
    final p = ph / 0.6;
    final s = unit * l.minSize;
    final x = size.width * 1.15 - p * (size.width * 1.15 + s * 5);
    final y = size.height * 0.14 + math.sin(p * math.pi * 4) * unit * 0.02 - math.sin(p * math.pi) * unit * 0.04;
    // vệt kim tuyến phía sau
    for (var i = 0; i < 14; i++) {
      final q = Offset(x + s * 3.3 + i * s * 0.35, y + math.sin(i * 0.9 + t * 6) * s * 0.15);
      final a = ((1 - i / 14) * 200).round();
      canvas.drawCircle(q, s * 0.06 * (1 - i / 16),
          Paint()
            ..color = l.colors.first.withAlpha(a)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04));
    }
    // dây cương nối tuần lộc với xe
    canvas.drawLine(Offset(x + s * 0.3, y + s * 0.1), Offset(x + s * 2.2, y + s * 0.15),
        Paint()
          ..color = const Color(0xCCFFD54F)
          ..strokeWidth = math.max(1, s * 0.03));
    final g = l.glyphs;
    _emoji(canvas, g[0], Offset(x, y + math.sin(t * 10) * s * 0.05), s, 0);
    _emoji(canvas, g[1], Offset(x + s * 1.05, y + math.sin(t * 10 + 1.5) * s * 0.05), s, 0);
    _emoji(canvas, g[2], Offset(x + s * 2.5, y + s * 0.15), s * 1.1, 0);
    // ông già Noel ngồi trên xe (vẽ sau để nổi lên trên chiếc xe)
    _emoji(canvas, g[3], Offset(x + s * 2.6, y - s * 0.45 + math.sin(t * 8) * s * 0.04), s * 0.9, 0);
  }

  void _emoji(Canvas canvas, String g, Offset p, double s, double rot) {
    final key = '$g|${s.round()}';
    final tp = _emojiCache.putIfAbsent(key, () {
      if (_emojiCache.length > 80) _emojiCache.clear();
      return TextPainter(
        text: TextSpan(text: g, style: TextStyle(fontSize: s)),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    canvas.save();
    canvas.translate(p.dx, p.dy);
    if (rot != 0) canvas.rotate(rot);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  /// Dây đèn / dây lồng đèn võng ngang phía trên màn hình.
  void _garland(Canvas canvas, Size size, Layer l, double unit) {
    final w = size.width;
    final y0 = size.height * 0.03;
    final sag = size.height * 0.05;
    final path = Path()..moveTo(0, y0);
    path.quadraticBezierTo(w / 2, y0 + sag * 2, w, y0);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, unit * 0.003)
          ..color = const Color(0x88FFFFFF));
    for (var i = 0; i < l.count; i++) {
      final f = (i + 0.5) / l.count;
      // điểm trên đường cong bậc 2
      final x = w * f;
      final y = y0 + sag * 2 * 2 * f * (1 - f);
      final col = l.colors[i % l.colors.length];
      final on = 0.55 + 0.45 * math.sin(t * 3 + i * 1.7);
      if (l.shape == Shape.lantern) {
        _lantern(canvas, Offset(x, y + unit * 0.035), unit * 0.035, col, swing: math.sin(t * 1.5 + i) * 0.12);
      } else {
        canvas.drawCircle(Offset(x, y + unit * 0.012), unit * 0.014,
            Paint()
              ..color = col.withAlpha((on * 255).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.01));
        canvas.drawCircle(Offset(x, y + unit * 0.012), unit * 0.007, Paint()..color = col);
      }
    }
  }

  // -------------------------------------------------------------------
  // Hình dạng
  // -------------------------------------------------------------------

  void _shape(Canvas canvas, Layer l, Offset p, double s, Color col, double spin, int seed) {
    switch (l.shape) {
      case Shape.dot:
        canvas.drawCircle(p, s / 2, Paint()..color = col);
        break;
      case Shape.firefly:
        final a = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(spin * 3));
        canvas.drawCircle(p, s,
            Paint()
              ..color = col.withAlpha((a * 120).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.8));
        canvas.drawCircle(p, s * 0.3, Paint()..color = col.withAlpha((a * 255).round()));
        break;
      case Shape.petal:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(spin * 0.8);
        canvas.scale(1, 0.55 + 0.45 * math.sin(spin * 1.7).abs());
        final path = Path()
          ..moveTo(0, -s / 2)
          ..quadraticBezierTo(s * 0.55, -s * 0.2, 0, s / 2)
          ..quadraticBezierTo(-s * 0.55, -s * 0.2, 0, -s / 2);
        canvas.drawPath(path, Paint()..color = col.withAlpha(230));
        canvas.restore();
        break;
      case Shape.leaf:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(math.sin(spin) * 1.2 + spin * 0.3);
        final path = Path()
          ..moveTo(0, -s / 2)
          ..quadraticBezierTo(s * 0.45, -s * 0.1, 0, s / 2)
          ..quadraticBezierTo(-s * 0.45, -s * 0.1, 0, -s / 2);
        canvas.drawPath(path, Paint()..color = col);
        canvas.drawLine(Offset(0, -s * 0.45), Offset(0, s * 0.6),
            Paint()
              ..color = Color.lerp(col, Colors.black, 0.35)!
              ..strokeWidth = math.max(0.6, s * 0.05));
        canvas.restore();
        break;
      case Shape.snowflake:
        final paint = Paint()
          ..color = col
          ..strokeWidth = math.max(0.8, s * 0.06)
          ..strokeCap = StrokeCap.round;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(spin * 0.3);
        for (var i = 0; i < 6; i++) {
          canvas.drawLine(Offset.zero, Offset(0, -s / 2), paint);
          canvas.drawLine(Offset(0, -s * 0.3), Offset(s * 0.12, -s * 0.4), paint);
          canvas.drawLine(Offset(0, -s * 0.3), Offset(-s * 0.12, -s * 0.4), paint);
          canvas.rotate(math.pi / 3);
        }
        canvas.restore();
        break;
      case Shape.confetti:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(spin);
        canvas.scale(1, math.cos(spin * 2.3));
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.5, height: s), Paint()..color = col);
        canvas.restore();
        break;
      case Shape.heart:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(math.sin(spin) * 0.4);
        final path = Path()
          ..moveTo(0, s * 0.35)
          ..cubicTo(-s * 0.6, -s * 0.1, -s * 0.25, -s * 0.55, 0, -s * 0.2)
          ..cubicTo(s * 0.25, -s * 0.55, s * 0.6, -s * 0.1, 0, s * 0.35);
        canvas.drawPath(path, Paint()..color = col);
        canvas.restore();
        break;
      case Shape.sparkle:
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final rr = i.isEven ? s / 2 : s * 0.1;
          final q = p + Offset(math.cos(a), math.sin(a)) * rr;
          if (i == 0) {
            path.moveTo(q.dx, q.dy);
          } else {
            path.lineTo(q.dx, q.dy);
          }
        }
        path.close();
        canvas.drawPath(path, Paint()..color = col);
        break;
      case Shape.balloon:
        final body = Rect.fromCenter(center: p, width: s * 0.8, height: s);
        canvas.drawLine(p + Offset(0, s / 2), p + Offset(math.sin(spin) * s * 0.2, s * 1.4),
            Paint()
              ..color = const Color(0x99FFFFFF)
              ..strokeWidth = 1);
        canvas.drawOval(body, Paint()..color = col);
        canvas.drawOval(Rect.fromCenter(center: p + Offset(-s * 0.15, -s * 0.2), width: s * 0.18, height: s * 0.28),
            Paint()..color = const Color(0x66FFFFFF));
        break;
      case Shape.lantern:
        _lantern(canvas, p, s, col, swing: math.sin(spin) * 0.1);
        break;
      case Shape.bat:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        final flap = math.sin(spin) * 0.6;
        final paint = Paint()..color = col;
        for (final dir in [-1.0, 1.0]) {
          final wing = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(dir * s * 0.3, -s * 0.35 * (1 + flap), dir * s * 0.6, -s * 0.1 * (1 + flap))
            ..quadraticBezierTo(dir * s * 0.45, s * 0.05, dir * s * 0.35, s * 0.02)
            ..quadraticBezierTo(dir * s * 0.2, s * 0.12, 0, s * 0.05)
            ..close();
          canvas.drawPath(wing, paint);
        }
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0.02), width: s * 0.18, height: s * 0.26), paint);
        canvas.restore();
        break;
      case Shape.feather:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(math.sin(spin) * 0.8);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.3, height: s), Paint()..color = col);
        canvas.drawLine(Offset(0, -s * 0.5), Offset(0, s * 0.65),
            Paint()
              ..color = Colors.white70
              ..strokeWidth = math.max(0.6, s * 0.03));
        canvas.restore();
        break;
      case Shape.emoji:
        if (l.glyphs.isEmpty) break;
        _emoji(canvas, l.glyphs[seed % l.glyphs.length], p,
            s, l.motion == Motion.fly ? 0 : math.sin(spin * 0.7) * 0.25);
        break;
      case Shape.sun:
        // mặt trời tí hon: tia nắng xoay + mặt cười
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.drawCircle(Offset.zero, s * 0.7,
            Paint()
              ..color = col.withAlpha(70)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.3));
        canvas.save();
        canvas.rotate(spin);
        final rayP = Paint()..color = const Color(0xFFFFA000);
        for (var i = 0; i < 8; i++) {
          final ray = Path()
            ..moveTo(-s * 0.07, -s * 0.32)
            ..lineTo(0, -s * 0.52)
            ..lineTo(s * 0.07, -s * 0.32)
            ..close();
          canvas.drawPath(ray, rayP);
          canvas.rotate(math.pi / 4);
        }
        canvas.restore();
        canvas.drawCircle(Offset.zero, s * 0.3,
            Paint()
              ..shader = const RadialGradient(colors: [Color(0xFFFFF176), Color(0xFFFFB300)])
                  .createShader(Rect.fromCircle(center: Offset.zero, radius: s * 0.3)));
        final face = Paint()..color = const Color(0xFF6D4C41);
        canvas.drawCircle(Offset(-s * 0.1, -s * 0.05), s * 0.03, face);
        canvas.drawCircle(Offset(s * 0.1, -s * 0.05), s * 0.03, face);
        canvas.drawArc(Rect.fromCenter(center: Offset(0, s * 0.03), width: s * 0.22, height: s * 0.16), 0.3,
            math.pi - 0.6, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(0.8, s * 0.03)
              ..color = const Color(0xFF6D4C41));
        canvas.drawCircle(Offset(-s * 0.18, s * 0.06), s * 0.04, Paint()..color = const Color(0x55FF5252));
        canvas.drawCircle(Offset(s * 0.18, s * 0.06), s * 0.04, Paint()..color = const Color(0x55FF5252));
        canvas.restore();
        break;
    }
  }

  void _lantern(Canvas canvas, Offset p, double s, Color col, {double swing = 0}) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(swing);
    canvas.drawCircle(Offset.zero, s * 0.9,
        Paint()
          ..color = col.withAlpha(70)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.5));
    canvas.drawLine(Offset(0, -s * 0.9), Offset(0, -s * 0.5),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = math.max(0.8, s * 0.05));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.9, height: s * 0.8), Paint()..color = col);
    final cap = Paint()..color = const Color(0xFFFFC107);
    canvas.drawRect(Rect.fromCenter(center: Offset(0, -s * 0.42), width: s * 0.45, height: s * 0.1), cap);
    canvas.drawRect(Rect.fromCenter(center: Offset(0, s * 0.42), width: s * 0.45, height: s * 0.1), cap);
    canvas.drawLine(Offset(0, s * 0.47), Offset(0, s * 0.75),
        Paint()
          ..color = const Color(0xFFFFC107)
          ..strokeWidth = math.max(0.8, s * 0.06));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ThemePainter o) => o.t != t || o.theme != theme;
}

/// Lớp theme tự chạy theo thời gian (có bộ đếm khung hình riêng).
class AnimatedThemeOverlay extends StatefulWidget {
  final SeasonTheme theme;
  const AnimatedThemeOverlay({super.key, required this.theme});

  @override
  State<AnimatedThemeOverlay> createState() => _AnimatedThemeOverlayState();
}

class _AnimatedThemeOverlayState extends State<AnimatedThemeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => ThemeOverlay(
        theme: widget.theme,
        time: (DateTime.now().millisecondsSinceEpoch % 100000000) / 1000.0,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Các hình vẽ chi tiết cho lễ hội. Mỗi hàm vẽ quanh gốc toạ độ (0,0),
/// [s] là kích thước chính (px), [t] là thời gian (giây) để làm lửa / nến lung linh.

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..color = c;

void _glow(Canvas canvas, Offset c, double r, Color col, int alpha) {
  canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [col.withAlpha(alpha), col.withAlpha(0)])
            .createShader(Rect.fromCircle(center: c, radius: r)));
}

/// Ngọn lửa nến nhỏ, lung linh theo [t].
void drawFlame(Canvas canvas, Offset c, double s, double t, [int seed = 0]) {
  final f = 1 + 0.12 * math.sin(t * 17 + seed) + 0.08 * math.sin(t * 29 + seed * 3);
  _glow(canvas, c, s * 2.2, const Color(0xFFFFC107), 110);
  final h = s * 1.4 * f;
  final flame = Path()
    ..moveTo(c.dx, c.dy - h)
    ..quadraticBezierTo(c.dx + s * 0.6, c.dy - h * 0.2, c.dx, c.dy + s * 0.25)
    ..quadraticBezierTo(c.dx - s * 0.6, c.dy - h * 0.2, c.dx, c.dy - h)
    ..close();
  canvas.drawPath(flame, _fill(const Color(0xFFFFA000)));
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, -h * 0.15), width: s * 0.45, height: h * 0.55),
      _fill(const Color(0xFFFFF8E1)));
}

// ---------------------------------------------------------------------------
// Tết: bao lì xì
// ---------------------------------------------------------------------------
void drawEnvelope(Canvas canvas, double s, Color col) {
  final w = s * 0.62, h = s;
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(s * 0.06));
  canvas.drawRRect(r, _fill(col));
  canvas.drawRRect(r, _stroke(const Color(0xFFFFD54F), math.max(0.8, s * 0.03)));
  // nắp phong bì
  final flap = Path()
    ..moveTo(-w / 2, -h / 2)
    ..lineTo(0, -h * 0.18)
    ..lineTo(w / 2, -h / 2);
  canvas.drawPath(flap, _stroke(const Color(0xAAFFD54F), math.max(0.8, s * 0.025)));
  // con dấu vàng chữ Phúc (vẽ hình hoa văn tròn)
  canvas.drawCircle(Offset(0, h * 0.08), s * 0.17, _fill(const Color(0xFFFFD54F)));
  canvas.drawCircle(Offset(0, h * 0.08), s * 0.11, _stroke(col, math.max(0.8, s * 0.025)));
  canvas.drawRect(Rect.fromCenter(center: Offset(0, h * 0.08), width: s * 0.1, height: s * 0.025), _fill(col));
  canvas.drawRect(Rect.fromCenter(center: Offset(0, h * 0.08), width: s * 0.025, height: s * 0.1), _fill(col));
}

// ---------------------------------------------------------------------------
// La Tomatina: quả cà chua thật (có cuống xanh)
// ---------------------------------------------------------------------------
void drawTomato(Canvas canvas, double r, Color col) {
  final rect = Rect.fromCenter(center: Offset.zero, width: r * 2.15, height: r * 1.85);
  canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [Color.lerp(col, Colors.white, 0.35)!, col, Color.lerp(col, Colors.black, 0.35)!],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect));
  // múi cà chua
  canvas.drawArc(Rect.fromCenter(center: Offset(-r * 0.25, 0), width: r * 1.1, height: r * 1.7), -1.2, 2.4,
      false, _stroke(const Color(0x33000000), math.max(0.6, r * 0.04)));
  canvas.drawArc(Rect.fromCenter(center: Offset(r * 0.25, 0), width: r * 1.1, height: r * 1.7), math.pi - 1.2,
      2.4, false, _stroke(const Color(0x33000000), math.max(0.6, r * 0.04)));
  // đài lá xanh hình sao + cuống
  final leaf = _fill(const Color(0xFF2E7D32));
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / 5;
    final p = Path()
      ..moveTo(0, -r * 0.82)
      ..lineTo(math.cos(a - 0.35) * r * 0.12, -r * 0.82 + math.sin(a - 0.35) * r * 0.12)
      ..lineTo(math.cos(a) * r * 0.42, -r * 0.82 + math.sin(a) * r * 0.25)
      ..lineTo(math.cos(a + 0.35) * r * 0.12, -r * 0.82 + math.sin(a + 0.35) * r * 0.12)
      ..close();
    canvas.drawPath(p, leaf);
  }
  canvas.drawLine(Offset(0, -r * 0.85), Offset(r * 0.06, -r * 1.12), _stroke(const Color(0xFF33691E), r * 0.09));
  canvas.drawOval(Rect.fromCenter(center: Offset(-r * 0.4, -r * 0.35), width: r * 0.45, height: r * 0.25),
      _fill(const Color(0x88FFFFFF)));
}

/// Cà chua vỡ: nước đỏ bắn tung + hạt.
void drawTomatoSplat(Canvas canvas, double r, double p, int seed, double Function(int, int, int) rnd) {
  final a = ((1 - p) * 230).round();
  final juice = _fill(const Color(0xFFD32F2F).withAlpha(a));
  canvas.drawCircle(Offset.zero, r * (1 + p * 1.2), Paint()
    ..color = const Color(0xFFE53935).withAlpha((a * 0.5).round())
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));
  for (var i = 0; i < 18; i++) {
    final ang = rnd(seed, i, 41) * 2 * math.pi;
    final d = r * (1 + 3.5 * p * (0.4 + 0.6 * rnd(seed, i, 42)));
    final q = Offset(math.cos(ang) * d, math.sin(ang) * d + p * p * r * 3);
    final rr = r * (0.12 + 0.22 * rnd(seed, i, 43)) * (1 - p * 0.4);
    canvas.drawCircle(q, rr, juice);
    if (i % 3 == 0) {
      canvas.drawOval(Rect.fromCenter(center: q + Offset(rr, 0), width: rr * 0.6, height: rr * 0.4),
          _fill(const Color(0xFFFFF59D).withAlpha(a)));
    }
  }
}

// ---------------------------------------------------------------------------
// Trung Thu: đèn ông sao, đèn kéo quân, đèn thỏ
// ---------------------------------------------------------------------------
void drawStarLantern(Canvas canvas, double s, Color col, double t, int seed) {
  _glow(canvas, Offset.zero, s * 1.1, const Color(0xFFFFC107), 90);
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? s * 0.55 : s * 0.24;
    final p = Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  star.close();
  canvas.drawPath(
      star,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFFF59D), col])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: s * 0.55)));
  canvas.drawPath(star, _stroke(const Color(0xFFFFD54F), math.max(0.8, s * 0.03)));
  // tua giấy ở 5 cánh
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / 5;
    final tip = Offset(math.cos(a) * s * 0.55, math.sin(a) * s * 0.55);
    final sway = math.sin(t * 3 + i + seed) * s * 0.05;
    canvas.drawLine(tip, tip + Offset(sway, s * 0.2), _stroke(const Color(0xFFFFEB3B), math.max(0.7, s * 0.025)));
  }
  drawFlame(canvas, Offset(0, s * 0.05), s * 0.07, t, seed);
}

void drawRevolvingLantern(Canvas canvas, double s, Color col, double t) {
  final w = s * 0.9, h = s;
  _glow(canvas, Offset.zero, s * 1.05, const Color(0xFFFFB300), 90);
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h * 0.72),
      Radius.circular(s * 0.06));
  canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(colors: [
          Color.lerp(col, Colors.black, 0.2)!,
          const Color(0xFFFFE0A0),
          Color.lerp(col, Colors.black, 0.2)!,
        ]).createShader(body.outerRect));
  // bóng hình người cưỡi ngựa chạy vòng quanh (kéo quân)
  canvas.save();
  canvas.clipRRect(body);
  final sil = _fill(const Color(0xAA3E2723));
  for (var i = 0; i < 3; i++) {
    var x = ((t * 0.25 + i / 3) % 1.0) * (w * 1.5) - w * 0.75;
    final y = h * 0.1;
    final u = s * 0.12;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: u * 1.8, height: u * 0.8), sil); // thân ngựa
    canvas.drawOval(Rect.fromCenter(center: Offset(x + u * 1.0, y - u * 0.45), width: u * 0.7, height: u * 0.4), sil);
    for (final dx in [-0.6, -0.3, 0.4, 0.7]) {
      final leg = math.sin(t * 6 + dx * 5 + i) * u * 0.2;
      canvas.drawLine(Offset(x + dx * u, y + u * 0.3), Offset(x + dx * u + leg, y + u * 0.9),
          _stroke(const Color(0xAA3E2723), u * 0.15));
    }
    canvas.drawCircle(Offset(x, y - u * 0.95), u * 0.28, sil); // người cưỡi
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y - u * 0.45), width: u * 0.4, height: u * 0.6), sil);
    canvas.drawLine(Offset(x - u * 0.3, y - u * 1.6), Offset(x + u * 0.5, y + u * 0.1),
        _stroke(const Color(0xAA3E2723), u * 0.08)); // ngọn giáo
    x += 0;
  }
  canvas.restore();
  final cap = _fill(const Color(0xFFB71C1C));
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h * 0.4), width: w * 1.08, height: h * 0.1),
          Radius.circular(s * 0.03)),
      cap);
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, h * 0.4), width: w * 1.08, height: h * 0.1),
          Radius.circular(s * 0.03)),
      cap);
  for (var i = 0; i < 5; i++) {
    final x = -w * 0.45 + i * w * 0.225;
    canvas.drawLine(Offset(x, h * 0.45), Offset(x, h * 0.62), _stroke(const Color(0xFFFFD54F), math.max(0.7, s * 0.02)));
  }
}

void drawRabbitLantern(Canvas canvas, double s, double t) {
  _glow(canvas, Offset.zero, s * 1.0, const Color(0xFFFFE0B2), 100);
  final body = Rect.fromCenter(center: Offset(0, s * 0.1), width: s * 0.95, height: s * 0.6);
  final paper = Paint()
    ..shader = const RadialGradient(colors: [Color(0xFFFFFDE7), Color(0xFFFFCDD2)]).createShader(body);
  canvas.drawOval(body, paper);
  final head = Offset(-s * 0.38, -s * 0.12);
  canvas.drawCircle(head, s * 0.22, paper);
  // 2 tai dài
  for (final dx in [-0.08, 0.06]) {
    canvas.save();
    canvas.translate(head.dx + s * dx, head.dy - s * 0.18);
    canvas.rotate(-0.25 + dx * 2 + math.sin(t * 2) * 0.05);
    final ear = Rect.fromCenter(center: Offset(0, -s * 0.18), width: s * 0.13, height: s * 0.42);
    canvas.drawOval(ear, paper);
    canvas.drawOval(ear.deflate(s * 0.03), _fill(const Color(0x88F48FB1)));
    canvas.restore();
  }
  canvas.drawCircle(head + Offset(-s * 0.08, -s * 0.02), s * 0.035, _fill(const Color(0xFFD32F2F)));
  canvas.drawCircle(Offset(s * 0.47, s * 0.05), s * 0.08, paper); // đuôi
  // bánh xe
  for (final dx in [-0.25, 0.25]) {
    canvas.drawCircle(Offset(s * dx, s * 0.45), s * 0.09, _fill(const Color(0xFF8D6E63)));
  }
  drawFlame(canvas, Offset(0, s * 0.1), s * 0.06, t, 3);
}

void drawZodiacLantern(Canvas canvas, double s, Color col, double t) {
  _glow(canvas, Offset.zero, s * 1.0, col, 90);
  final r = Rect.fromCenter(center: Offset.zero, width: s * 0.95, height: s * 0.85);
  // giấy sáng màu ở giữa để hình con giáp nổi rõ, viền đậm dần ra mép
  canvas.drawOval(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFFDF2), const Color(0xFFFFF0C0), col],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(r));
  canvas.drawOval(r, _stroke(Color.lerp(col, Colors.black, 0.3)!, math.max(0.8, s * 0.025)));
  final cap = _fill(const Color(0xFFFFC107));
  canvas.drawRect(Rect.fromCenter(center: Offset(0, -s * 0.44), width: s * 0.45, height: s * 0.1), cap);
  canvas.drawRect(Rect.fromCenter(center: Offset(0, s * 0.44), width: s * 0.45, height: s * 0.1), cap);
  for (var i = 0; i < 5; i++) {
    final x = -s * 0.16 + i * s * 0.08;
    canvas.drawLine(Offset(x, s * 0.5), Offset(x, s * 0.72), _stroke(const Color(0xFFFFC107), math.max(0.7, s * 0.02)));
  }
}

// ---------------------------------------------------------------------------
// Đèn trời (Yi Peng): lồng giấy hình thang, đốm lửa sáng bên trong
// ---------------------------------------------------------------------------
void drawSkyLantern(Canvas canvas, double s, Color col, double t, int seed) {
  final flick = 0.85 + 0.15 * math.sin(t * 11 + seed) * math.sin(t * 7.3 + seed * 2);
  _glow(canvas, Offset(0, s * 0.15), s * 1.3, const Color(0xFFFF9800), (110 * flick).round());
  final w1 = s * 0.75, w2 = s * 0.5, h = s;
  final shape = Path()
    ..moveTo(-w1 / 2, -h * 0.45)
    ..quadraticBezierTo(0, -h * 0.58, w1 / 2, -h * 0.45)
    ..lineTo(w2 / 2, h * 0.45)
    ..lineTo(-w2 / 2, h * 0.45)
    ..close();
  canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(col, Colors.black, 0.25)!, col, const Color(0xFFFFF3C4)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: w1, height: h)));
  // nan tre dọc
  final rib = _stroke(const Color(0x55BF360C), math.max(0.6, s * 0.012));
  for (final f in [-0.25, 0.0, 0.25]) {
    canvas.drawLine(Offset(w1 * f, -h * 0.5), Offset(w2 * f, h * 0.45), rib);
  }
  // vòng tre miệng đèn + dây đỡ đốm lửa
  canvas.drawLine(Offset(-w2 / 2, h * 0.45), Offset(w2 / 2, h * 0.45), _stroke(const Color(0xFF8D6E63), s * 0.025));
  final wire = _stroke(const Color(0x998D6E63), math.max(0.5, s * 0.008));
  canvas.drawLine(Offset(-w2 / 2, h * 0.45), Offset(0, h * 0.4), wire);
  canvas.drawLine(Offset(w2 / 2, h * 0.45), Offset(0, h * 0.4), wire);
  // đốm lửa bên trong (nhìn xuyên giấy) + ngọn lửa ở miệng
  _glow(canvas, Offset(0, h * 0.25), s * 0.45 * flick, const Color(0xFFFFEB3B), 200);
  drawFlame(canvas, Offset(0, h * 0.4), s * 0.07 * flick, t, seed);
}

// ---------------------------------------------------------------------------
// Phật Đản & Vu Lan: hoa đăng hình hoa sen có nến
// ---------------------------------------------------------------------------
void drawLotusLantern(Canvas canvas, double s, Color col, double t, int seed) {
  _glow(canvas, Offset(0, -s * 0.1), s * 1.1, const Color(0xFFFFC107), 90);
  // bóng phản chiếu trên nước
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.3), width: s * 1.1, height: s * 0.18),
      _fill(const Color(0x33FFE082)));
  final dark = Color.lerp(col, const Color(0xFFC2185B), 0.45)!;
  // lá sen xanh đỡ dưới
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.18), width: s * 1.15, height: s * 0.26),
      _fill(const Color(0xFF2E7D32)));
  // 2 lớp cánh sen
  for (var layer = 0; layer < 2; layer++) {
    final n = layer == 0 ? 7 : 5;
    final len = s * (layer == 0 ? 0.5 : 0.4);
    for (var i = 0; i < n; i++) {
      final a = math.pi + (i + 0.5) * math.pi / n;
      canvas.save();
      canvas.translate(0, s * 0.12);
      canvas.rotate(a + math.pi / 2);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.38, -len * 0.5, 0, -len)
        ..quadraticBezierTo(-len * 0.38, -len * 0.5, 0, 0);
      canvas.drawPath(
          petal,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [layer == 0 ? dark : col, const Color(0xFFFFF8F0)],
            ).createShader(Rect.fromLTWH(-len * 0.4, -len, len * 0.8, len)));
      canvas.restore();
    }
  }
  // nến giữa
  canvas.drawRect(Rect.fromCenter(center: Offset(0, -s * 0.02), width: s * 0.09, height: s * 0.16),
      _fill(const Color(0xFFFFF8E1)));
  drawFlame(canvas, Offset(0, -s * 0.13), s * 0.06, t, seed);
}

// ---------------------------------------------------------------------------
// Giáng sinh: xe trượt tuyết + ông già Noel + túi quà
// ---------------------------------------------------------------------------
/// Vẽ xe và ông già Noel, hướng chạy sang trái. Trả về vị trí miệng túi quà (để bắn quà ra).
Offset drawSleighSanta(Canvas canvas, double s, double t) {
  // càng trượt cong vàng
  final runner = _stroke(const Color(0xFFFFC107), s * 0.05);
  final r = Path()
    ..moveTo(-s * 0.75, s * 0.18)
    ..quadraticBezierTo(-s * 0.95, s * 0.18, -s * 0.9, s * 0.02)
    ..moveTo(-s * 0.75, s * 0.18)
    ..lineTo(s * 0.55, s * 0.18)
    ..quadraticBezierTo(s * 0.72, s * 0.18, s * 0.7, s * 0.05);
  canvas.drawPath(r, runner);
  for (final x in [-0.4, 0.25]) {
    canvas.drawLine(Offset(s * x, s * 0.18), Offset(s * x, s * 0.02), _stroke(const Color(0xFFFFC107), s * 0.035));
  }
  // túi quà to phía sau (bên phải)
  final sackC = Offset(s * 0.38, -s * 0.28);
  canvas.drawOval(Rect.fromCenter(center: sackC, width: s * 0.55, height: s * 0.6), _fill(const Color(0xFF8D6E63)));
  canvas.drawOval(Rect.fromCenter(center: sackC + Offset(-s * 0.08, -s * 0.08), width: s * 0.2, height: s * 0.25),
      _fill(const Color(0x33FFFFFF)));
  // quà ló ra miệng túi
  canvas.drawRect(Rect.fromCenter(center: sackC + Offset(-s * 0.05, -s * 0.32), width: s * 0.16, height: s * 0.13),
      _fill(const Color(0xFF43A047)));
  canvas.drawRect(Rect.fromCenter(center: sackC + Offset(s * 0.1, -s * 0.34), width: s * 0.13, height: s * 0.15),
      _fill(const Color(0xFF1E88E5)));
  canvas.drawLine(sackC + Offset(-s * 0.05, -s * 0.385), sackC + Offset(-s * 0.05, -s * 0.255),
      _stroke(const Color(0xFFFFD54F), s * 0.025));
  // thân xe đỏ, viền vàng, hoa văn cuộn
  final body = Path()
    ..moveTo(-s * 0.7, -s * 0.12)
    ..quadraticBezierTo(-s * 0.85, -s * 0.35, -s * 0.62, -s * 0.38)
    ..lineTo(-s * 0.55, -s * 0.05)
    ..lineTo(s * 0.62, -s * 0.05)
    ..quadraticBezierTo(s * 0.75, -s * 0.05, s * 0.68, s * 0.08)
    ..lineTo(-s * 0.6, s * 0.08)
    ..quadraticBezierTo(-s * 0.72, s * 0.05, -s * 0.7, -s * 0.12)
    ..close();
  canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE53935), Color(0xFF8E0000)],
        ).createShader(Rect.fromLTWH(-s * 0.85, -s * 0.4, s * 1.6, s * 0.5)));
  canvas.drawPath(body, _stroke(const Color(0xFFFFD54F), s * 0.022));
  canvas.drawArc(Rect.fromCenter(center: Offset(-s * 0.68, -s * 0.3), width: s * 0.14, height: s * 0.14), 0,
      math.pi * 1.5, false, _stroke(const Color(0xFFFFD54F), s * 0.02));
  // ông già Noel ngồi giữa xe, vẫy tay
  final sx = -s * 0.15, sy = -s * 0.2;
  canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: s * 0.42, height: s * 0.4), _fill(const Color(0xFFD32F2F)));
  canvas.drawRect(Rect.fromCenter(center: Offset(sx, sy + s * 0.05), width: s * 0.42, height: s * 0.06),
      _fill(const Color(0xFF212121)));
  canvas.drawRect(Rect.fromCenter(center: Offset(sx, sy + s * 0.05), width: s * 0.07, height: s * 0.06),
      _fill(const Color(0xFFFFD54F)));
  final head = Offset(sx - s * 0.02, sy - s * 0.3);
  canvas.drawCircle(head, s * 0.12, _fill(const Color(0xFFFFCCBC))); // mặt
  // râu trắng bồng bềnh
  final beard = _fill(Colors.white);
  for (final o in [const Offset(-0.09, 0.05), const Offset(0.0, 0.1), const Offset(0.09, 0.05), const Offset(-0.05, 0.12), const Offset(0.05, 0.13)]) {
    canvas.drawCircle(head + Offset(s * o.dx, s * o.dy), s * 0.075, beard);
  }
  canvas.drawCircle(head + Offset(-s * 0.04, -s * 0.03), s * 0.015, _fill(const Color(0xFF3E2723)));
  canvas.drawCircle(head + Offset(s * 0.04, -s * 0.03), s * 0.015, _fill(const Color(0xFF3E2723)));
  canvas.drawCircle(head + Offset(0, s * 0.0), s * 0.025, _fill(const Color(0xFFEF9A9A))); // mũi
  // mũ đỏ có chóp bông trắng
  final hat = Path()
    ..moveTo(head.dx - s * 0.13, head.dy - s * 0.06)
    ..quadraticBezierTo(head.dx, head.dy - s * 0.35, head.dx + s * 0.2, head.dy - s * 0.22)
    ..lineTo(head.dx + s * 0.13, head.dy - s * 0.06)
    ..close();
  canvas.drawPath(hat, _fill(const Color(0xFFD32F2F)));
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: head + Offset(0, -s * 0.07), width: s * 0.3, height: s * 0.07),
          Radius.circular(s * 0.03)),
      beard);
  canvas.drawCircle(Offset(head.dx + s * 0.2, head.dy - s * 0.22), s * 0.045, beard);
  // tay vẫy
  final wave = math.sin(t * 6) * 0.35;
  canvas.save();
  canvas.translate(sx - s * 0.18, sy - s * 0.08);
  canvas.rotate(-2.2 + wave);
  canvas.drawLine(Offset.zero, Offset(s * 0.22, 0), _stroke(const Color(0xFFD32F2F), s * 0.08));
  canvas.drawCircle(Offset(s * 0.25, 0), s * 0.045, _fill(Colors.white));
  canvas.restore();
  return sackC + Offset(0, -s * 0.35);
}

/// Quà & kẹo bắn ra từ túi: 0 hộp quà, 1 kẹo gậy, 2 kẹo mút tròn, 3 ngôi sao, 4 trái tim, 5 kẹo bọc giấy.
void drawGift(Canvas canvas, int kind, double s, Color col) {
  switch (kind % 6) {
    case 0:
      final r = Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.85);
      canvas.drawRect(r, _fill(col));
      final rib = _fill(const Color(0xFFFFD54F));
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.18, height: s * 0.85), rib);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.16), rib);
      canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.15, -s * 0.5), width: s * 0.3, height: s * 0.2), rib);
      canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.15, -s * 0.5), width: s * 0.3, height: s * 0.2), rib);
      break;
    case 1:
      final cane = Path()
        ..moveTo(0, s * 0.55)
        ..lineTo(0, -s * 0.25)
        ..arcToPoint(Offset(s * 0.4, -s * 0.25), radius: Radius.circular(s * 0.2))
        ..lineTo(s * 0.4, -s * 0.1);
      canvas.drawPath(cane, _stroke(Colors.white, s * 0.16));
      final dash = _stroke(const Color(0xFFE53935), s * 0.16)..strokeCap = StrokeCap.butt;
      for (var i = 0; i < 4; i++) {
        final y = s * 0.45 - i * s * 0.22;
        canvas.drawLine(Offset(0, y), Offset(0, y - s * 0.08), dash);
      }
      break;
    case 2:
      canvas.drawLine(Offset(0, s * 0.2), Offset(0, s * 0.75), _stroke(const Color(0xFFEEEEEE), s * 0.07));
      canvas.drawCircle(Offset.zero, s * 0.38, _fill(col));
      final sw = _stroke(Colors.white, s * 0.07);
      final spiral = Path()..moveTo(0, 0);
      for (var i = 1; i <= 24; i++) {
        final a = i * 0.55;
        final rr = s * 0.32 * i / 24;
        spiral.lineTo(math.cos(a) * rr, math.sin(a) * rr);
      }
      canvas.drawPath(spiral, sw);
      break;
    case 3:
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final r = i.isEven ? s * 0.5 : s * 0.22;
        final p = Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(star..close(), _fill(const Color(0xFFFFD740)));
      break;
    case 4:
      final heart = Path()
        ..moveTo(0, s * 0.4)
        ..cubicTo(-s * 0.6, 0, -s * 0.35, -s * 0.5, 0, -s * 0.18)
        ..cubicTo(s * 0.35, -s * 0.5, s * 0.6, 0, 0, s * 0.4);
      canvas.drawPath(heart, _fill(const Color(0xFFFF4081)));
      break;
    default:
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.55, height: s * 0.4), _fill(col));
      for (final sg in [-1.0, 1.0]) {
        final w = Path()
          ..moveTo(sg * s * 0.25, 0)
          ..lineTo(sg * s * 0.5, -s * 0.18)
          ..lineTo(sg * s * 0.5, s * 0.18)
          ..close();
        canvas.drawPath(w, _fill(col));
      }
      canvas.drawLine(Offset(-s * 0.12, -s * 0.12), Offset(s * 0.1, s * 0.12), _stroke(const Color(0x88FFFFFF), s * 0.05));
  }
}

// ---------------------------------------------------------------------------
// Sinh nhật: bánh kem 2 tầng, nến lung linh
// ---------------------------------------------------------------------------
void drawCake(Canvas canvas, double s, double t, List<Color> colors) {
  final cream = colors.length > 1 ? colors[1] : const Color(0xFFFFF3E0);
  final pink = colors.first;
  final sponge = colors.length > 2 ? colors[2] : const Color(0xFF8D6E63);
  // đĩa
  canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.42), width: s * 1.2, height: s * 0.16), _fill(const Color(0xDDE0E0E0)));
  // tầng dưới
  final low = Rect.fromCenter(center: Offset(0, s * 0.22), width: s, height: s * 0.38);
  canvas.drawRRect(RRect.fromRectAndRadius(low, Radius.circular(s * 0.05)), _fill(sponge));
  canvas.drawRect(Rect.fromLTWH(low.left, low.top + low.height * 0.45, low.width, low.height * 0.12), _fill(pink));
  // kem chảy
  final drip = Path()..moveTo(low.left, low.top);
  for (var i = 0; i <= 8; i++) {
    final x = low.left + low.width * i / 8;
    drip.lineTo(x, low.top + (i.isEven ? s * 0.09 : s * 0.04));
  }
  drip
    ..lineTo(low.right, low.top - s * 0.02)
    ..lineTo(low.left, low.top - s * 0.02)
    ..close();
  canvas.drawPath(drip, _fill(cream));
  // tầng trên
  final up = Rect.fromCenter(center: Offset(0, -s * 0.08), width: s * 0.68, height: s * 0.28);
  canvas.drawRRect(RRect.fromRectAndRadius(up, Radius.circular(s * 0.05)), _fill(pink));
  canvas.drawRect(Rect.fromLTWH(up.left, up.top, up.width, s * 0.06), _fill(cream));
  // dâu
  for (var i = 0; i < 5; i++) {
    canvas.drawCircle(Offset(up.left + up.width * (i + 0.5) / 5, up.top - s * 0.01), s * 0.035,
        _fill(const Color(0xFFD32F2F)));
  }
  // nến
  const candleCols = [Color(0xFF42A5F5), Color(0xFFFFCA28), Color(0xFF66BB6A), Color(0xFFAB47BC)];
  for (var i = 0; i < 4; i++) {
    final x = up.left + up.width * (i + 0.5) / 4;
    final top = up.top - s * 0.18;
    canvas.drawRect(Rect.fromLTWH(x - s * 0.018, top, s * 0.036, s * 0.17), _fill(candleCols[i]));
    canvas.drawLine(Offset(x - s * 0.018, top + s * 0.05), Offset(x + s * 0.018, top + s * 0.03),
        _stroke(Colors.white, s * 0.01));
    drawFlame(canvas, Offset(x, top - s * 0.02), s * 0.03, t, i);
  }
}

// ---------------------------------------------------------------------------
// Quốc khánh: lá cờ đỏ sao vàng nhỏ phấp phới
// ---------------------------------------------------------------------------
void drawVnFlag(Canvas canvas, double s, double t, int seed) {
  final w = s, h = s * 0.66;
  // cán cờ
  canvas.drawLine(Offset(-w * 0.52, -h * 0.5), Offset(-w * 0.52, h * 0.9),
      _stroke(const Color(0xFFE0C080), math.max(1, s * 0.05)));
  // mặt cờ gợn sóng
  final flag = Path();
  const n = 12;
  for (var i = 0; i <= n; i++) {
    final x = -w / 2 + w * i / n;
    final y = -h / 2 + math.sin(t * 6 + seed + i * 0.6) * h * 0.08 * i / n;
    i == 0 ? flag.moveTo(x, y) : flag.lineTo(x, y);
  }
  for (var i = n; i >= 0; i--) {
    final x = -w / 2 + w * i / n;
    final y = h / 2 + math.sin(t * 6 + seed + i * 0.6) * h * 0.08 * i / n;
    flag.lineTo(x, y);
  }
  flag.close();
  canvas.drawPath(flag, _fill(const Color(0xFFDA251D)));
  final dy = math.sin(t * 6 + seed + n / 2 * 0.6) * h * 0.04;
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? h * 0.3 : h * 0.12;
    final p = Offset(math.cos(a) * r, math.sin(a) * r + dy);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(star..close(), _fill(const Color(0xFFFFFF00)));
}

// ---------------------------------------------------------------------------
// Trung Thu: chị Hằng áo dài lụa bay, tay kéo chú Cuội, dải lụa uốn lượn
// Gốc toạ độ ở eo chị Hằng, hướng bay: lên trên – sang phải.
// ---------------------------------------------------------------------------
void drawHangNgaCuoi(Canvas canvas, double s, double t) {
  final skin = _fill(const Color(0xFFFFE0C8));
  final hair = _fill(const Color(0xFF2B1B17));
  // dải lụa phía sau
  for (final (col, ph, off) in [
    (const Color(0xCCFF8FB1), 0.0, 0.0),
    (const Color(0xCC80D8FF), 1.7, 0.08),
  ]) {
    final rib = Path()..moveTo(s * 0.05, -s * 0.38);
    for (var i = 1; i <= 16; i++) {
      final f = i / 16;
      rib.lineTo(-s * (0.15 + 1.1 * f) - s * off, -s * 0.38 + s * 1.15 * f + math.sin(t * 3 + ph + f * 6) * s * 0.12 * f);
    }
    canvas.drawPath(rib, _stroke(col, s * 0.04));
  }
  // váy áo dài thướt tha, vạt bay về phía sau
  final dress = Path()
    ..moveTo(s * 0.16, -s * 0.42)
    ..quadraticBezierTo(s * 0.26, -s * 0.05, s * 0.12, s * 0.28)
    ..quadraticBezierTo(-s * 0.05, s * 0.66 + math.sin(t * 2.5) * s * 0.05, -s * 0.62, s * 0.76)
    ..quadraticBezierTo(-s * 0.36, s * 0.42, -s * 0.2, s * 0.12)
    ..quadraticBezierTo(-s * 0.14, -s * 0.2, -s * 0.06, -s * 0.42)
    ..close();
  canvas.drawPath(
      dress,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F5), Color(0xFFF8BBD0), Color(0xFFE1BEE7)],
        ).createShader(Rect.fromLTWH(-s * 0.6, -s * 0.45, s * 0.85, s * 1.2)));
  // thắt lưng vàng
  canvas.drawLine(Offset(-s * 0.08, -s * 0.12), Offset(s * 0.16, -s * 0.14), _stroke(const Color(0xFFFFC107), s * 0.035));
  // tay trước vươn lên về phía trăng
  canvas.drawLine(Offset(s * 0.1, -s * 0.36), Offset(s * 0.42, -s * 0.72), _stroke(const Color(0xFFFFF0F5), s * 0.07));
  canvas.drawCircle(Offset(s * 0.44, -s * 0.75), s * 0.035, skin);
  // đầu nghiêng về phía trước, tóc búi cài trâm
  final head = Offset(s * 0.1, -s * 0.55);
  canvas.drawCircle(head + Offset(-s * 0.05, -s * 0.07), s * 0.075, hair);
  canvas.drawCircle(head, s * 0.085, skin);
  canvas.drawArc(Rect.fromCircle(center: head, radius: s * 0.09), math.pi * 1.05, math.pi * 0.95, true, hair);
  canvas.drawLine(head + Offset(-s * 0.12, -s * 0.1), head + Offset(-s * 0.01, -s * 0.13),
      _stroke(const Color(0xFFFFD54F), s * 0.015));
  canvas.drawCircle(head + Offset(s * 0.04, s * 0.0), s * 0.01, hair);
  canvas.drawCircle(head + Offset(s * 0.035, s * 0.04), s * 0.012, _fill(const Color(0xFFE57373)));
  // tay sau nắm tay chú Cuội
  final hand = Offset(-s * 0.2, s * 0.12);
  canvas.drawLine(Offset(-s * 0.02, -s * 0.34), hand, _stroke(const Color(0xFFFFF0F5), s * 0.06));
  // chú Cuội đung đưa phía dưới
  final sw = math.sin(t * 2.2) * 0.18;
  canvas.save();
  canvas.translate(hand.dx, hand.dy);
  canvas.rotate(sw);
  final c = s * 0.62; // Cuội nhỏ hơn
  canvas.drawLine(Offset.zero, Offset(-c * 0.05, c * 0.28), _stroke(const Color(0xFF8D6E63), c * 0.06)); // tay giơ lên
  final ch = Offset(-c * 0.12, c * 0.4);
  canvas.drawCircle(ch, c * 0.11, skin);
  canvas.drawArc(Rect.fromCircle(center: ch, radius: c * 0.115), math.pi, math.pi, true, hair); // tóc chỏm
  canvas.drawCircle(ch + Offset(-c * 0.03, -c * 0.12), c * 0.04, hair);
  canvas.drawCircle(ch + Offset(c * 0.04, c * 0.0), c * 0.012, hair);
  final body = Path()
    ..moveTo(-c * 0.22, c * 0.5)
    ..lineTo(c * 0.0, c * 0.5)
    ..lineTo(c * 0.04, c * 0.85)
    ..lineTo(-c * 0.26, c * 0.85)
    ..close();
  canvas.drawPath(body, _fill(const Color(0xFF8D6E63))); // áo nâu
  canvas.drawLine(Offset(-c * 0.18, c * 0.65), Offset(-c * 0.06, c * 0.68), _stroke(const Color(0xFFFFC107), c * 0.03));
  final kick = math.sin(t * 5) * c * 0.08;
  canvas.drawLine(Offset(-c * 0.18, c * 0.85), Offset(-c * 0.24 - kick, c * 1.12), _stroke(const Color(0xFF3E2723), c * 0.07));
  canvas.drawLine(Offset(-c * 0.03, c * 0.85), Offset(c * 0.0 + kick, c * 1.1), _stroke(const Color(0xFF3E2723), c * 0.07));
  canvas.restore();
}

/// Cây đa và thỏ ngọc in bóng trên mặt trăng.
void drawMoonBanyan(Canvas canvas, Offset c, double r) {
  final shade = _fill(const Color(0x40705A3A));
  final base = c + Offset(-r * 0.25, r * 0.45);
  canvas.drawLine(base, base + Offset(0, -r * 0.45), _stroke(const Color(0x55705A3A), r * 0.08));
  canvas.drawCircle(base + Offset(0, -r * 0.6), r * 0.28, shade);
  canvas.drawCircle(base + Offset(-r * 0.22, -r * 0.48), r * 0.18, shade);
  canvas.drawCircle(base + Offset(r * 0.2, -r * 0.5), r * 0.2, shade);
  // thỏ ngọc
  final rb = c + Offset(r * 0.35, r * 0.35);
  canvas.drawOval(Rect.fromCenter(center: rb, width: r * 0.26, height: r * 0.18), shade);
  canvas.drawCircle(rb + Offset(r * 0.1, -r * 0.1), r * 0.07, shade);
  canvas.drawOval(Rect.fromCenter(center: rb + Offset(r * 0.12, -r * 0.24), width: r * 0.05, height: r * 0.16), shade);
}

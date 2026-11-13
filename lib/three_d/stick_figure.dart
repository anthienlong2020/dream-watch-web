import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'body_type.dart';

/// Kiểu "Người que": hình (khuôn mặt / con vật) làm cái đầu to, bên dưới là
/// thân người que vẽ bằng nét, tay chân đung đưa như đang đi.
class StickFigureView extends StatelessWidget {
  /// Hình làm đầu (thường là SlotImageView phẳng).
  final Widget head;
  final double size;

  /// Góc quay (dùng để "xoay người": co bề ngang theo cos).
  final double yaw;
  final BodyType body;
  final Color color;

  const StickFigureView({
    super.key,
    required this.head,
    required this.size,
    this.yaw = 0,
    this.body = BodyType.canDoi,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = size * 0.5;
    final turn = math.cos(yaw);
    return SizedBox(
      width: size,
      height: size,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
            turn.abs() < 0.15 ? 0.15 * turn.sign : turn, 1, 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StickPainter(
                  t: DateTime.now().millisecondsSinceEpoch / 1000.0,
                  body: body,
                  color: color,
                  headBottom: headSize * 0.92,
                ),
              ),
            ),
            Positioned(
              left: (size - headSize) / 2,
              top: 0,
              width: headSize,
              height: headSize,
              child: head,
            ),
          ],
        ),
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  final double t;
  final BodyType body;
  final Color color;
  final double headBottom;
  _StickPainter({required this.t, required this.body, required this.color, required this.headBottom});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = switch (body) {
      BodyType.om => s * 0.035,
      BodyType.canDoi => s * 0.05,
      BodyType.map => s * 0.07,
    };
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = s / 2;
    final neck = Offset(cx, headBottom);
    final hip = Offset(cx, s * 0.78);
    final legLen = s * 0.2;
    final armLen = s * 0.2;
    final swing = math.sin(t * 2 * math.pi * 0.8) * 0.5; // đi bộ nhẹ nhàng

    // Thân (mập thì có bụng tròn)
    canvas.drawLine(neck, hip, p);
    if (body == BodyType.map) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, (neck.dy + hip.dy) / 2 + s * 0.02), width: s * 0.24, height: s * 0.2),
          Paint()..color = color);
    }
    // Tay
    final shoulder = Offset(cx, neck.dy + s * 0.05);
    // (góc tính từ trục ngang, 90° = thẳng xuống; dir -1 = bên trái, 1 = bên phải)
    for (final dir in [-1.0, 1.0]) {
      final a = math.pi / 2 - dir * 0.75 + swing * 0.4;
      canvas.drawLine(shoulder, shoulder + Offset(math.cos(a), math.sin(a)) * armLen, p);
    }
    // Chân: bước tới lui ngược chiều nhau
    for (final dir in [-1.0, 1.0]) {
      final a = math.pi / 2 - dir * 0.22 + swing * 0.35 * dir;
      canvas.drawLine(hip, hip + Offset(math.cos(a), math.sin(a)) * legLen, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StickPainter o) =>
      o.t != t || o.body != body || o.color != color || o.headBottom != headBottom;
}

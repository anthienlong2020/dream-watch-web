// Vẽ thử ảnh "thổi phồng" 3D ra build/preview/inflated.png để xem trước.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/three_d/inflated_3d.dart';

/// Một con khủng long vẽ giả, nền trong suốt.
Future<Uint8List> _fakeDino() async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final body = Paint()..color = const Color(0xFF66BB6A);
  c.drawOval(const Rect.fromLTWH(60, 120, 230, 150), body); // thân
  c.drawOval(const Rect.fromLTWH(230, 40, 120, 90), body); // đầu
  c.drawPath(
      Path()
        ..moveTo(250, 120)
        ..lineTo(290, 110)
        ..lineTo(280, 180)
        ..close(),
      body); // cổ
  c.drawPath(
      Path()
        ..moveTo(80, 170)
        ..quadraticBezierTo(20, 160, 5, 120)
        ..quadraticBezierTo(40, 215, 110, 240)
        ..close(),
      body); // đuôi
  for (final x in [110.0, 160.0, 210.0, 250.0]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, 240, 28, 70), const Radius.circular(12)), body);
  }
  c.drawOval(const Rect.fromLTWH(110, 170, 140, 80), Paint()..color = const Color(0xFFC5E1A5)); // bụng
  c.drawCircle(const Offset(310, 75), 11, Paint()..color = Colors.white);
  c.drawCircle(const Offset(313, 75), 6, Paint()..color = Colors.black);
  for (var k = 0; k < 6; k++) {
    final x = 110.0 + k * 30;
    c.drawPath(
        Path()
          ..moveTo(x - 14, 128 - math.sin(k / 5 * math.pi) * 6)
          ..lineTo(x, 100 - math.sin(k / 5 * math.pi) * 10)
          ..lineTo(x + 14, 128 - math.sin(k / 5 * math.pi) * 6)
          ..close(),
        Paint()..color = const Color(0xFFFFA726));
  }
  final img = await rec.endRecording().toImage(360, 320);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vẽ thử ảnh thổi phồng 3D', () async {
    final png = await _fakeDino();
    final model = await buildInflated(png, grid: 52);
    const yaws = [0.0, 0.4, -0.7, 1.2, math.pi];
    const cell = 300.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(const Rect.fromLTWH(0, 0, cell * 5, cell), Paint()..color = const Color(0xFF0B1020));
    for (var i = 0; i < yaws.length; i++) {
      canvas.save();
      canvas.translate(i * cell, 0);
      paintInflated(canvas, const Size(cell, cell), model, yaw: yaws[i]);
      canvas.restore();
    }
    final img = await rec.endRecording().toImage((cell * 5).round(), cell.round());
    final out = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/preview')..createSync(recursive: true);
    File('${dir.path}/inflated.png').writeAsBytesSync(out!.buffer.asUint8List());
    expect(model.mesh.triCount, greaterThan(100));
  });
}

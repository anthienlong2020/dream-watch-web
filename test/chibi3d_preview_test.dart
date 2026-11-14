// Vẽ thử Chibi 3D ra ảnh PNG (build/preview/) để xem trước hình dáng.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/chibi/chibi3d.dart';
import 'package:dream_watch/chibi/chibi_painter.dart';
import 'package:dream_watch/three_d/body_type.dart';

Future<Uint8List> _fakeFace() async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, 256, 256), Paint()..color = const Color(0xFF3E2723));
  c.drawOval(const Rect.fromLTWH(38, 60, 180, 196), Paint()..color = const Color(0xFFF1C27D));
  c.drawArc(const Rect.fromLTWH(30, 20, 196, 150), math.pi, math.pi, true,
      Paint()..color = const Color(0xFF3E2723));
  for (final x in [95.0, 161.0]) {
    c.drawOval(Rect.fromCenter(center: Offset(x, 150), width: 26, height: 32), Paint()..color = Colors.black);
    c.drawCircle(Offset(x + 5, 143), 5, Paint()..color = Colors.white);
  }
  c.drawArc(const Rect.fromLTWH(103, 175, 50, 36), 0.2, math.pi - 0.4, false,
      Paint()
        ..color = const Color(0xFFC62828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6);
  final img = await rec.endRecording().toImage(256, 256);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vẽ thử Chibi 3D', () async {
    final face = await _fakeFace();
    const yaws = [0.0, 0.45, -0.7, math.pi / 2, math.pi];
    const cell = 300.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(Rect.fromLTWH(0, 0, cell * yaws.length, cell * ChibiOutfit.values.length),
        Paint()..color = const Color(0xFF0B1020));
    for (var r = 0; r < ChibiOutfit.values.length; r++) {
      final spec = ChibiSpec(
        face: face,
        outfit: ChibiOutfit.values[r],
        outfitColor: kOutfitColors[(r * 2 + 3) % kOutfitColors.length],
        skin: const Color(0xFFF1C27D),
        hair: const Color(0xFF3E2723),
      );
      final atlas = await buildAtlas(spec);
      final mesh = buildChibiMesh(spec.outfit);
      for (var c = 0; c < yaws.length; c++) {
        canvas.save();
        canvas.translate(c * cell, r * cell);
        paintChibi3D(canvas, const Size(cell, cell), mesh, atlas, yaw: yaws[c]);
        canvas.restore();
      }
    }
    final img = await rec.endRecording()
        .toImage((cell * yaws.length).round(), (cell * ChibiOutfit.values.length).round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/preview')..createSync(recursive: true);
    File('${dir.path}/chibi3d.png').writeAsBytesSync(png!.buffer.asUint8List());
    expect(png.lengthInBytes, greaterThan(1000));
  });

  test('vẽ thử 3 dáng Chibi 3D', () async {
    final face = await _fakeFace();
    const yaws = [0.0, 0.6, math.pi / 2];
    const cell = 300.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(const Rect.fromLTWH(0, 0, cell * 3, cell * 3),
        Paint()..color = const Color(0xFF0B1020));
    final spec = ChibiSpec(
      face: face,
      outfit: ChibiOutfit.aoThun,
      outfitColor: kOutfitColors[4],
      skin: const Color(0xFFF1C27D),
      hair: const Color(0xFF3E2723),
    );
    final atlas = await buildAtlas(spec);
    for (var r = 0; r < 3; r++) {
      final mesh = buildChibiMesh(spec.outfit, body: BodyType.values[r]);
      for (var c = 0; c < 3; c++) {
        canvas.save();
        canvas.translate(c * cell, r * cell);
        paintChibi3D(canvas, const Size(cell, cell), mesh, atlas, yaw: yaws[c]);
        canvas.restore();
      }
    }
    final img = await rec.endRecording().toImage(900, 900);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/chibi_body.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

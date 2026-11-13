// Vẽ thử kiểu 3D phù điêu với 2 biểu tượng cắt từ ảnh chụp màn hình của L.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/three_d/inflated_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vẽ thử phù điêu', () async {
    const yaws = [0.0, 0.5, -0.8, math.pi * 0.85];
    const cell = 300.0;
    final files = ['test/fixtures/bocap.png', 'test/fixtures/nhanma.png'];
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(Rect.fromLTWH(0, 0, cell * yaws.length, cell * files.length * 2),
        Paint()..color = const Color(0xFF1C3B57));
    for (var f = 0; f < files.length; f++) {
      final bytes = File(files[f]).readAsBytesSync();
      for (var mode = 0; mode < 2; mode++) {
        final model = await buildInflated(bytes, grid: mode == 0 ? 64 : 52, relief: mode == 0);
        for (var i = 0; i < yaws.length; i++) {
          canvas.save();
          canvas.translate(i * cell, (f * 2 + mode) * cell);
          paintInflated(canvas, const Size(cell, cell), model, yaw: yaws[i]);
          canvas.restore();
        }
      }
    }
    final img = await rec.endRecording()
        .toImage((cell * yaws.length).round(), (cell * files.length * 2).round());
    final out = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/relief.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(out!.buffer.asUint8List());
  });
}

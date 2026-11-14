// Vẽ thử mặt đồng hồ với kiểu Người que và Chibi 3D (thú chibi) ra ảnh PNG.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/effects/element_effect.dart';
import 'package:dream_watch/models/clock_theme.dart';
import 'package:dream_watch/three_d/body_type.dart';
import 'package:dream_watch/widgets/dream_clock.dart';

Future<Uint8List> _fakeAnimal() async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final body = Paint()..color = const Color(0xFFFFB74D);
  c.drawCircle(const Offset(128, 140), 95, body);
  c.drawCircle(const Offset(60, 55), 35, body);
  c.drawCircle(const Offset(196, 55), 35, body);
  for (final x in [95.0, 161.0]) {
    c.drawCircle(Offset(x, 125), 14, Paint()..color = Colors.black);
  }
  c.drawOval(Rect.fromCenter(center: const Offset(128, 170), width: 40, height: 26),
      Paint()..color = const Color(0xFF6D4C41));
  final img = await rec.endRecording().toImage(256, 256);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('vẽ thử kiểu người que và thú chibi', (tester) async {
    final png = (await tester.runAsync(_fakeAnimal))!;
    final theme = buildCustomTheme(List<Uint8List?>.filled(12, png));
    final shots = <ui.Image>[];
    final configs = [
      (ImageStyle.nguoiQue, ElementType.none),
      (ImageStyle.chibi, ElementType.none),
      (ImageStyle.thoiPhong, ElementType.none),
      (ImageStyle.thoiPhong, ElementType.lua),
      (ImageStyle.chibi, ElementType.nuoc),
      (ImageStyle.standard, ElementType.dien),
      (ImageStyle.thoiPhong, ElementType.may),
      (ImageStyle.thoiPhong, ElementType.sap),
      (ImageStyle.standard, ElementType.dat),
      (ImageStyle.nguoiQue, ElementType.lua),
      (ImageStyle.chibi, ElementType.dien),
      (ImageStyle.thoiPhong, ElementType.bongBong),
      (ImageStyle.chibi, ElementType.moc),
      (ImageStyle.phuDieu, ElementType.kim),
      (ImageStyle.thoiPhong, ElementType.phaLe),
      (ImageStyle.thoiPhong, ElementType.haoQuangNgan),
      (ImageStyle.standard, ElementType.haoQuangDai),
    ];
    for (final (style, element) in configs) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 500,
              height: 500,
              child: ColoredBox(
                color: const Color(0xFF0B1020),
                child: DreamClock(
                  theme: theme,
                  styles: List.filled(12, style),
                  bodies: List.generate(12, (i) => BodyType.values[i % 3]),
                  elements: List.filled(12, element),
                  elemColors: List.generate(12, (i) => element == ElementType.phaLe
                      ? [ElemColor.trongSuot, ElemColor.ngocBich, ElemColor.hong, ElemColor.cauVong][i % 4]
                      : [ElemColor.vang, ElemColor.lam, ElemColor.tim, ElemColor.bachKim][i % 4]),
                ),
              ),
            ),
          ),
        ),
      ));
      for (var k = 0; k < 4; k++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      shots.add((await tester.runAsync(() => boundary.toImage()))!);
    }
    final out = await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      for (var i = 0; i < shots.length; i++) {
        c.drawImage(shots[i], Offset((i % 3) * 500.0, (i ~/ 3) * 500.0), Paint());
      }
      final img = await rec.endRecording().toImage(1500, 500 * ((shots.length + 2) ~/ 3));
      return img.toByteData(format: ui.ImageByteFormat.png);
    });
    File('build/preview/styles.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(out!.buffer.asUint8List());
    await tester.pumpWidget(const SizedBox());
  });
}

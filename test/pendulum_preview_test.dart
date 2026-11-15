import 'dart:io';
import 'dart:ui' as ui;

import 'package:dream_watch/widgets/classic_dial.dart';
import 'package:dream_watch/widgets/pendulum_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vẽ thử bản Standard: quả lắc + 12 con số', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: PendulumClock(
          dateText: 'Chủ Nhật, 15/11/2026',
          face: const ClassicDial(),
        ),
      ),
    ));
    await tester.runAsync(() async {
      final ctx = key.currentContext!;
      for (var n = 1; n <= 12; n++) {
        await precacheImage(AssetImage('assets/themes/so/$n.png'), ctx);
      }
      await precacheImage(const AssetImage('assets/standard/head.webp'), ctx);
      await precacheImage(const AssetImage('assets/standard/trunk.webp'), ctx);
      await precacheImage(const AssetImage('assets/standard/pendulum.webp'), ctx);
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final png = await tester.runAsync(() async {
      final img = await boundary.toImage();
      return img.toByteData(format: ui.ImageByteFormat.png);
    });
    File('build/preview/standard.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

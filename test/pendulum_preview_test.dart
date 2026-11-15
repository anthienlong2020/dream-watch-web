import 'dart:io';
import 'dart:ui' as ui;

import 'package:dream_watch/services/pro_code.dart';
import 'package:dream_watch/widgets/pendulum_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mã Pro: mã tạo bằng tool hợp lệ, mã bừa thì không', () {
    expect(isValidProCode('DW-ABXC-49LY'), isTrue);
    expect(isValidProCode('dw abxc 49ly'), isTrue);
    expect(isValidProCode('DW-ABXC-49LZ'), isFalse);
    expect(isValidProCode('hello'), isFalse);
  });

  test('vẽ thử đồng hồ quả lắc', () async {
    // máy test không có font chữ thật → nạp font hệ thống (nếu có) để nhìn rõ con số
    for (final f in [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
      '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
    ]) {
      if (File(f).existsSync()) {
        final bytes = File(f).readAsBytesSync();
        await (FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
        break;
      }
    }
    const w = 400.0, h = 760.0;
    final times = [DateTime(2026, 11, 15, 10, 9, 30, 400), DateTime(2026, 11, 15, 17, 0, 5, 300)];
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (var i = 0; i < times.length; i++) {
      c.save();
      c.translate(i * w, 0);
      c.clipRect(const Rect.fromLTWH(0, 0, w, h));
      PendulumPainter(times[i], dateText: 'Chủ Nhật, 15/11/2026').paint(c, const Size(w, h));
      c.restore();
    }
    final img = await rec.endRecording().toImage((w * times.length).round(), h.round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/pendulum.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

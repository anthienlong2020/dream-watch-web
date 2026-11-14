import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/themes/season_theme.dart';
import 'package:dream_watch/themes/theme_overlay.dart';

void main() {
  test('lịch theme tự động', () {
    expect(autoThemeId(DateTime(2026, 2, 17)), 'tet');
    expect(autoThemeId(DateTime(2026, 9, 25)), 'trungThu');
    expect(autoThemeId(DateTime(2026, 12, 24)), 'giangSinh');
    expect(autoThemeId(DateTime(2026, 10, 31)), 'halloween');
    expect(autoThemeId(DateTime(2026, 1, 1)), 'tet');
    for (final e in kTetDates.entries) {
      expect(lunarToSolar(1, 1, e.key), DateTime(e.key, e.value.$1, e.value.$2), reason: 'Tết ${e.key}');
    }
    for (final e in kTrungThuDates.entries) {
      expect(lunarToSolar(15, 8, e.key), DateTime(e.key, e.value.$1, e.value.$2), reason: 'Trung thu ${e.key}');
    }
    expect(lunarToSolar(15, 4, 2026), DateTime(2026, 5, 31)); // Phật Đản 2026
    expect(lunarToSolar(15, 10, 2026), DateTime(2026, 11, 24)); // Loy Krathong 2026
    expect(nthWeekday(2026, 11, DateTime.thursday, 4), DateTime(2026, 11, 26));
    expect(nthWeekday(2026, 8, DateTime.wednesday, -1), DateTime(2026, 8, 26));
    expect(autoThemeId(DateTime(2026, 11, 24)), 'thaDen');
    expect(autoThemeId(DateTime(2026, 9, 2)), 'quocKhanh');
    expect(autoThemeId(DateTime(2026, 11, 14)), 'dong');
    expect(autoThemeId(DateTime(2026, 8, 1)), 'thu');
    expect(easterOf(2026), DateTime(2026, 4, 5));
    expect(kZodiacName[zodiacOfYear(lunarYearOf(DateTime(2026, 3, 1)))], 'Ngọ');
    expect(kZodiacName[zodiacOfYear(lunarYearOf(DateTime(2026, 1, 20)))], 'Tỵ');
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  test('vẽ thử các theme', () async {
    final themes = allThemes(DateTime(2026, 2, 17));
    const w = 360.0, h = 480.0;
    const cols = 6;
    final rows = (themes.length + cols - 1) ~/ cols;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, w * cols, h * 10), Paint()..color = const Color(0xFF0B1020));
    for (var i = 0; i < themes.length; i++) {
      c.save();
      c.translate((i % cols) * w, (i ~/ cols) * h);
      c.clipRect(const Rect.fromLTWH(0, 0, w, h));
      ThemePainter(themes[i], 12.3).paint(c, const Size(w, h));
      c.drawCircle(const Offset(w / 2, h / 2), w * 0.4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = themes[i].accent);
      c.restore();
    }
    final img = await rec.endRecording().toImage((w * cols).round(), (h * rows).round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/themes.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

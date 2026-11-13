// Kiểm tra mặt đồng hồ vẽ được với mọi kiểu và dáng (không báo lỗi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/models/clock_theme.dart';
import 'package:dream_watch/three_d/body_type.dart';
import 'package:dream_watch/widgets/dream_clock.dart';

void main() {
  for (final style in ImageStyle.values) {
    for (final body in BodyType.values) {
      testWidgets('đồng hồ: ${style.name} / ${body.name}', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: 400,
            height: 400,
            child: DreamClock(
              theme: buildZodiacTheme(),
              styles: List.filled(12, style),
              bodies: List.filled(12, body),
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

// File này có sẵn để "flutter create ." không tạo bản mẫu (bản mẫu gọi MyApp gây lỗi).
import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/models/clock_theme.dart';

void main() {
  test('có đủ 12 hình trong mỗi chủ đề', () {
    expect(buildDinoTheme().slots.length, 12);
    expect(buildZodiacTheme().slots.length, 12);
    expect(buildCustomTheme(const []).slots.length, 12);
  });
}

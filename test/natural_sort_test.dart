import 'package:dream_watch/models/clock_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sắp tên file kiểu tự nhiên', () {
    final l = ['10.png', '2.png', 'b.png', '1.png', 'a 12.jpg', 'a 3.jpg']..sort(naturalCompare);
    expect(l, ['1.png', '2.png', '10.png', 'a 3.jpg', 'a 12.jpg', 'b.png']);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/models/alarm.dart';
import 'package:dream_watch/models/clock_theme.dart';
import 'package:dream_watch/utils/image_utils.dart';
import 'package:dream_watch/utils/vn_format.dart';

DateTime at(int h, int m, [int s = 0]) => DateTime(2026, 11, 12, h, m, s);

void main() {
  test('vị trí giờ', () {
    expect(hourSlot(at(0, 0)), 0); // XII
    expect(hourSlot(at(8, 52)), 8);
    expect(hourSlot(at(13, 0)), 1);
    expect(hourSlot(at(23, 59)), 11);
  });

  test('hình phút = hình ở mốc 5 phút vừa qua', () {
    expect(minuteSlot(at(8, 0)), 0);
    expect(minuteSlot(at(8, 4)), 0);
    expect(minuteSlot(at(20, 35)), 7);
    expect(minuteSlot(at(20, 39)), 7);
    expect(minuteSlot(at(20, 40)), 8);
    expect(minuteSlot(at(8, 59)), 11);
    expect(minuteAnchor(at(20, 37)), 35);
    expect(minuteAnchor(at(20, 40)), 40);
  });

  test('báo thức khớp giờ và thứ', () {
    final a = Alarm(id: 1, hour: 6, minute: 30, days: {1, 2, 3, 4, 5});
    // 12/11/2026 là Thứ Năm
    expect(a.matches(at(6, 30)), true);
    expect(a.matches(at(6, 31)), false);
    expect(a.matches(DateTime(2026, 11, 14, 6, 30)), false); // Thứ Bảy
  });

  test('tên file -> số vị trí', () {
    expect(numberFromFileName('3.png'), 3);
    expect(numberFromFileName('folder/khunglong_12.PNG'), 12);
    expect(numberFromFileName('dino.png'), null);
    expect(numberFromFileName('13.png'), null);
  });

  test('định dạng tiếng Việt', () {
    expect(formatDateVn(at(8, 0)), 'Thứ Năm, ngày 12 tháng 11 năm 2026');
    expect(formatDuration(const Duration(minutes: 5)), '05:00');
    expect(describeDays({6, 7}), 'Cuối tuần');
  });
}

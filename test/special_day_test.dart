import 'package:flutter_test/flutter_test.dart';

import 'package:dream_watch/models/special_day.dart';
import 'package:dream_watch/utils/world_time.dart';

void main() {
  test('ngày nhớ âm lịch: lần tới', () {
    final tet = SpecialDay(id: 1, name: 'Tết', lunar: true, day: 1, month: 1);
    expect(tet.nextFrom(DateTime(2026, 11, 16)), DateTime(2027, 2, 6));
    expect(tet.nextFrom(DateTime(2026, 2, 17)), DateTime(2026, 2, 17)); // đúng hôm nay
    expect(daysBetween(DateTime(2026, 11, 16), DateTime(2027, 2, 6)), 82);
    final ram10 = SpecialDay(id: 2, name: 'Rằm', lunar: true, day: 15, month: 10);
    expect(ram10.nextFrom(DateTime(2026, 11, 16)), DateTime(2026, 11, 23));
  });

  test('ngày nhớ dương lịch, 29/2 và số năm', () {
    final sn = SpecialDay(id: 3, name: 'SN', kind: 'sinhNhat', lunar: false, day: 29, month: 2, year: 2000);
    final n = sn.nextFrom(DateTime(2026, 11, 16));
    expect(n, DateTime(2027, 2, 28));
    expect(sn.yearsText(n), 'tròn 27 tuổi');
    final gio = SpecialDay(id: 4, name: 'Giỗ', kind: 'gio', lunar: true, day: 30, month: 12, year: 2020);
    final g = gio.nextFrom(DateTime(2026, 11, 16));
    // tháng Chạp năm Bính Ngọ: lấy ngày 30 nếu có, không thì 29 (đều là ngày trước Tết 2027)
    expect(g.isBefore(DateTime(2027, 2, 6)), true);
    expect(g.isAfter(DateTime(2027, 2, 3)), true);
    expect(gio.yearsText(g), 'giỗ lần thứ 6');
  });

  test('giờ thế giới + giờ mùa hè', () {
    final ny = cityById('newyork')!;
    expect(ny.offsetAt(DateTime.utc(2026, 7, 1)), -240); // giờ hè
    expect(ny.offsetAt(DateTime.utc(2026, 12, 1)), -300);
    final paris = cityById('paris')!;
    expect(paris.offsetAt(DateTime.utc(2026, 3, 29, 0, 59)), 60);
    expect(paris.offsetAt(DateTime.utc(2026, 3, 29, 1, 0)), 120);
    final syd = cityById('sydney')!;
    expect(syd.offsetAt(DateTime.utc(2026, 1, 10)), 660);
    expect(syd.offsetAt(DateTime.utc(2026, 6, 10)), 600);
    final t = ny.localTime(DateTime.utc(2026, 11, 16, 1, 30));
    expect((t.day, t.hour, t.minute), (15, 20, 30));
    expect(diffText(-720), 'Chậm hơn 12 giờ');
  });
}

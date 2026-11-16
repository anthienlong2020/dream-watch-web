/// Giờ thế giới không cần internet: múi giờ chuẩn + luật đổi giờ mùa hè
/// (Mỹ/Canada, châu Âu, Úc, New Zealand).
enum Dst { none, us, eu, au, nz }

class City {
  final String id;
  final String name;
  final String country;
  final String flag;
  final int offsetMin; // giờ chuẩn so với UTC, tính bằng phút
  final Dst dst;
  const City(this.id, this.name, this.country, this.flag, this.offsetMin, [this.dst = Dst.none]);

  /// Có đang giờ mùa hè (+1 giờ) tại thời điểm [utc] không.
  bool isDst(DateTime utc) {
    final y = utc.year;
    switch (dst) {
      case Dst.none:
        return false;
      case Dst.us:
        // từ 2:00 Chủ nhật thứ 2 tháng 3 đến 2:00 Chủ nhật đầu tháng 11 (giờ địa phương)
        final start = _sunday(y, 3, 2).add(Duration(hours: 2, minutes: -offsetMin));
        final end = _sunday(y, 11, 1).add(Duration(hours: 1, minutes: -offsetMin));
        return !utc.isBefore(start) && utc.isBefore(end);
      case Dst.eu:
        // 1:00 UTC Chủ nhật cuối tháng 3 → 1:00 UTC Chủ nhật cuối tháng 10
        final start = _lastSunday(y, 3).add(const Duration(hours: 1));
        final end = _lastSunday(y, 10).add(const Duration(hours: 1));
        return !utc.isBefore(start) && utc.isBefore(end);
      case Dst.au:
        // Nam bán cầu: 2:00 Chủ nhật đầu tháng 10 → 3:00 (giờ hè) Chủ nhật đầu tháng 4
        final end = _sunday(y, 4, 1).add(Duration(hours: 3, minutes: -offsetMin - 60));
        final start = _sunday(y, 10, 1).add(Duration(hours: 2, minutes: -offsetMin));
        return utc.isBefore(end) || !utc.isBefore(start);
      case Dst.nz:
        // 2:00 Chủ nhật cuối tháng 9 → 3:00 (giờ hè) Chủ nhật đầu tháng 4
        final end = _sunday(y, 4, 1).add(Duration(hours: 3, minutes: -offsetMin - 60));
        final start = _lastSunday(y, 9).add(Duration(hours: 2, minutes: -offsetMin));
        return utc.isBefore(end) || !utc.isBefore(start);
    }
  }

  int offsetAt(DateTime utc) => offsetMin + (isDst(utc) ? 60 : 0);

  /// Giờ địa phương (trả về DateTime "giả" dạng UTC để lấy giờ/phút/ngày).
  DateTime localTime(DateTime now) {
    final utc = now.toUtc();
    return utc.add(Duration(minutes: offsetAt(utc)));
  }
}

/// Chủ nhật thứ [nth] của tháng (0:00 UTC của ngày đó).
DateTime _sunday(int y, int m, int nth) {
  final first = DateTime.utc(y, m, 1);
  return DateTime.utc(y, m, 1 + (7 - first.weekday) % 7 + 7 * (nth - 1));
}

DateTime _lastSunday(int y, int m) {
  final last = DateTime.utc(y, m + 1, 0);
  return DateTime.utc(y, m, last.day - last.weekday % 7);
}

const List<City> kCities = [
  City('hanoi', 'Hà Nội / TP.HCM', 'Việt Nam', '🇻🇳', 420),
  City('bangkok', 'Bangkok', 'Thái Lan', '🇹🇭', 420),
  City('jakarta', 'Jakarta', 'Indonesia', '🇮🇩', 420),
  City('singapore', 'Singapore', 'Singapore', '🇸🇬', 480),
  City('kualalumpur', 'Kuala Lumpur', 'Malaysia', '🇲🇾', 480),
  City('manila', 'Manila', 'Philippines', '🇵🇭', 480),
  City('beijing', 'Bắc Kinh', 'Trung Quốc', '🇨🇳', 480),
  City('hongkong', 'Hồng Kông', 'Trung Quốc', '🇭🇰', 480),
  City('taipei', 'Đài Bắc', 'Đài Loan', '🇹🇼', 480),
  City('perth', 'Perth', 'Úc', '🇦🇺', 480),
  City('seoul', 'Seoul', 'Hàn Quốc', '🇰🇷', 540),
  City('tokyo', 'Tokyo', 'Nhật Bản', '🇯🇵', 540),
  City('brisbane', 'Brisbane', 'Úc', '🇦🇺', 600),
  City('sydney', 'Sydney', 'Úc', '🇦🇺', 600, Dst.au),
  City('melbourne', 'Melbourne', 'Úc', '🇦🇺', 600, Dst.au),
  City('auckland', 'Auckland', 'New Zealand', '🇳🇿', 720, Dst.nz),
  City('newdelhi', 'New Delhi', 'Ấn Độ', '🇮🇳', 330),
  City('dubai', 'Dubai', 'UAE', '🇦🇪', 240),
  City('moscow', 'Moskva', 'Nga', '🇷🇺', 180),
  City('istanbul', 'Istanbul', 'Thổ Nhĩ Kỳ', '🇹🇷', 180),
  City('warsaw', 'Warszawa', 'Ba Lan', '🇵🇱', 60, Dst.eu),
  City('prague', 'Praha', 'Séc', '🇨🇿', 60, Dst.eu),
  City('berlin', 'Berlin', 'Đức', '🇩🇪', 60, Dst.eu),
  City('paris', 'Paris', 'Pháp', '🇫🇷', 60, Dst.eu),
  City('amsterdam', 'Amsterdam', 'Hà Lan', '🇳🇱', 60, Dst.eu),
  City('rome', 'Roma', 'Ý', '🇮🇹', 60, Dst.eu),
  City('madrid', 'Madrid', 'Tây Ban Nha', '🇪🇸', 60, Dst.eu),
  City('london', 'London', 'Anh', '🇬🇧', 0, Dst.eu),
  City('newyork', 'New York', 'Mỹ', '🇺🇸', -300, Dst.us),
  City('washington', 'Washington D.C.', 'Mỹ', '🇺🇸', -300, Dst.us),
  City('toronto', 'Toronto', 'Canada', '🇨🇦', -300, Dst.us),
  City('chicago', 'Chicago', 'Mỹ', '🇺🇸', -360, Dst.us),
  City('houston', 'Houston', 'Mỹ', '🇺🇸', -360, Dst.us),
  City('denver', 'Denver', 'Mỹ', '🇺🇸', -420, Dst.us),
  City('losangeles', 'Los Angeles', 'Mỹ', '🇺🇸', -480, Dst.us),
  City('sanjose', 'San Jose', 'Mỹ', '🇺🇸', -480, Dst.us),
  City('seattle', 'Seattle', 'Mỹ', '🇺🇸', -480, Dst.us),
  City('vancouver', 'Vancouver', 'Canada', '🇨🇦', -480, Dst.us),
  City('honolulu', 'Honolulu', 'Mỹ', '🇺🇸', -600),
];

City? cityById(String id) {
  for (final c in kCities) {
    if (c.id == id) return c;
  }
  return null;
}

/// "Nhanh hơn 2 giờ", "Chậm hơn 14 giờ 30 phút", "Cùng giờ".
String diffText(int minutes) {
  if (minutes == 0) return 'Cùng giờ';
  final a = minutes.abs(), h = a ~/ 60, m = a % 60;
  final s = h > 0 ? '$h giờ${m > 0 ? ' $m phút' : ''}' : '$m phút';
  return '${minutes > 0 ? 'Nhanh' : 'Chậm'} hơn $s';
}

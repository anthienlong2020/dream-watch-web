import 'package:flutter/material.dart';

// =====================================================================
// Theme mùa & lễ hội: chỉ thêm lớp hiệu ứng (hoa rơi, tuyết, pháo hoa...)
// và màu nhấn cho vòng đồng hồ, chữ giờ. KHÔNG đổi ảnh user đã chọn.
// =====================================================================

/// Các kiểu chuyển động của hạt.
enum Motion { fall, rise, fly, wander, burst, twinkle, garland, moon }

/// Hình dạng hạt (vẽ bằng code) hoặc emoji.
enum Shape { dot, petal, leaf, snowflake, confetti, heart, sparkle, balloon, lantern, bat, feather, firefly, emoji }

class Layer {
  final Motion motion;
  final Shape shape;
  final int count;
  final List<Color> colors;
  final List<String> glyphs; // cho Shape.emoji
  final double minSize, maxSize; // theo bề ngang màn hình
  final double speed; // số lượt / giây (càng lớn càng nhanh)
  final double sway; // độ lắc ngang
  const Layer({
    required this.motion,
    required this.shape,
    this.count = 20,
    this.colors = const [Colors.white],
    this.glyphs = const [],
    this.minSize = 0.012,
    this.maxSize = 0.03,
    this.speed = 0.08,
    this.sway = 0.03,
  });
}

class SeasonTheme {
  final String id;
  final String name;
  final String emoji;
  final Color accent; // màu vòng đồng hồ + chữ giờ
  final Color? glow; // quầng sáng nhẹ ở mép màn hình
  final List<Layer> layers;
  final bool autoOnly; // false = có thể tự chọn và cũng có thể bật tự động
  const SeasonTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accent,
    required this.layers,
    this.glow,
    this.autoOnly = false,
  });
}

/// 12 con giáp theo năm âm lịch (Tý = 0).
const List<String> kZodiacEmoji = ['🐭', '🐃', '🐯', '🐱', '🐲', '🐍', '🐴', '🐐', '🐵', '🐓', '🐶', '🐷'];
const List<String> kZodiacName = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];
int zodiacOfYear(int lunarYear) => ((lunarYear - 4) % 12 + 12) % 12;

const _pinks = [Color(0xFFFFB7C5), Color(0xFFFF8FB1), Color(0xFFFFD1DC)];
const _mai = [Color(0xFFFFD54F), Color(0xFFFFE082), Color(0xFFFFC107)];
const _autumn = [Color(0xFFFF9F43), Color(0xFFE85D04), Color(0xFFB5651D), Color(0xFFF4C430)];
const _party = [
  Color(0xFFFF5252), Color(0xFFFFEB3B), Color(0xFF69F0AE), Color(0xFF40C4FF),
  Color(0xFFE040FB), Color(0xFFFFAB40),
];
const _fireworks = [Color(0xFFFF5252), Color(0xFFFFD740), Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFE040FB)];

/// Theme Tết có con giáp của năm.
SeasonTheme tetTheme(int lunarYear) {
  final z = zodiacOfYear(lunarYear);
  return SeasonTheme(
    id: 'tet',
    name: 'Tết Nguyên Đán – năm ${kZodiacName[z]}',
    emoji: '🧧',
    accent: const Color(0xFFFFC107),
    glow: const Color(0x55FF1744),
    layers: [
      const Layer(motion: Motion.garland, shape: Shape.lantern, count: 7,
          colors: [Color(0xFFE53935), Color(0xFFFF7043)]),
      const Layer(motion: Motion.fall, shape: Shape.petal, count: 16, colors: _mai, speed: 0.06),
      const Layer(motion: Motion.fall, shape: Shape.petal, count: 10, colors: _pinks, speed: 0.06),
      const Layer(motion: Motion.burst, shape: Shape.dot, count: 2,
          colors: [Color(0xFFFF5252), Color(0xFFFFD740)], speed: 0.35),
      Layer(motion: Motion.rise, shape: Shape.emoji, count: 2, glyphs: [kZodiacEmoji[z]],
          minSize: 0.06, maxSize: 0.08, speed: 0.04, sway: 0.05),
    ],
  );
}

/// Tất cả theme (theme Tết mặc định theo năm hiện tại).
List<SeasonTheme> allThemes(DateTime now) => [
      const SeasonTheme(
        id: 'xuan', name: 'Mùa xuân', emoji: '🌸', accent: Color(0xFFFF8FB1),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 24, colors: _pinks, speed: 0.06),
          Layer(motion: Motion.fall, shape: Shape.petal, count: 8, colors: _mai, speed: 0.07),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 8, colors: [Color(0xFFFFF59D)]),
        ],
      ),
      const SeasonTheme(
        id: 'ha', name: 'Mùa hạ', emoji: '☀️', accent: Color(0xFFFFC93C), glow: Color(0x33FFC107),
        layers: [
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 18, colors: [Color(0xFFDCE775), Color(0xFFFFF176)]),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 10, colors: [Color(0xFFFFFFFF), Color(0xFFFFE082)]),
          Layer(motion: Motion.rise, shape: Shape.dot, count: 10, colors: [Color(0x99B3E5FC)], speed: 0.05,
              minSize: 0.008, maxSize: 0.02),
        ],
      ),
      const SeasonTheme(
        id: 'thu', name: 'Mùa thu', emoji: '🍂', accent: Color(0xFFFF9F43),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.leaf, count: 22, colors: _autumn, speed: 0.055,
              minSize: 0.018, maxSize: 0.04, sway: 0.06),
        ],
      ),
      const SeasonTheme(
        id: 'dong', name: 'Mùa đông', emoji: '❄️', accent: Color(0xFF9ADCFF), glow: Color(0x3381D4FA),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.dot, count: 60, colors: [Colors.white], speed: 0.07,
              minSize: 0.004, maxSize: 0.012, sway: 0.02),
          Layer(motion: Motion.fall, shape: Shape.snowflake, count: 12, colors: [Color(0xFFE1F5FE)], speed: 0.05,
              minSize: 0.02, maxSize: 0.04),
        ],
      ),
      const SeasonTheme(
        id: 'giangSinh', name: 'Giáng sinh', emoji: '🎄', accent: Color(0xFFE53935), glow: Color(0x3343A047),
        layers: [
          Layer(motion: Motion.garland, shape: Shape.dot, count: 14,
              colors: [Color(0xFFFF5252), Color(0xFF69F0AE), Color(0xFFFFD740), Color(0xFF40C4FF)]),
          Layer(motion: Motion.fall, shape: Shape.dot, count: 45, colors: [Colors.white], speed: 0.07,
              minSize: 0.004, maxSize: 0.011),
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 4, glyphs: ['🎁', '⭐', '🔔', '🍬'], speed: 0.04,
              minSize: 0.04, maxSize: 0.055),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 8, colors: [Color(0xFFFFD740)]),
        ],
      ),
      tetTheme(lunarYearOf(now)),
      const SeasonTheme(
        id: 'namMoi', name: 'Năm mới', emoji: '🎆', accent: Color(0xFFFFD54F),
        layers: [
          Layer(motion: Motion.burst, shape: Shape.dot, count: 4, colors: _fireworks, speed: 0.4),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 14, colors: [Colors.white, Color(0xFFFFD740)]),
        ],
      ),
      const SeasonTheme(
        id: 'valentine', name: 'Valentine', emoji: '💝', accent: Color(0xFFFF4F8B), glow: Color(0x33FF4081),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.heart, count: 18,
              colors: [Color(0xFFFF4081), Color(0xFFFF8FB1), Color(0xFFE53935)], speed: 0.05),
          Layer(motion: Motion.rise, shape: Shape.heart, count: 6, colors: [Color(0x88FFFFFF)], speed: 0.04),
        ],
      ),
      const SeasonTheme(
        id: 'carnival', name: 'Lễ hội Carnival (Brazil)', emoji: '🦜', accent: Color(0xFF00C853),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.confetti, count: 45, colors: _party, speed: 0.08),
          Layer(motion: Motion.fall, shape: Shape.feather, count: 8,
              colors: [Color(0xFF00C853), Color(0xFFFFD600), Color(0xFF2962FF), Color(0xFFD50000)], speed: 0.04,
              minSize: 0.03, maxSize: 0.05),
          Layer(motion: Motion.fly, shape: Shape.emoji, count: 3, glyphs: ['🦜'], speed: 0.06,
              minSize: 0.05, maxSize: 0.07),
        ],
      ),
      const SeasonTheme(
        id: 'phuNu', name: 'Ngày Phụ nữ (8/3, 20/10)', emoji: '💐', accent: Color(0xFFE91E63),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 22,
              colors: [Color(0xFFE91E63), Color(0xFFF06292), Color(0xFFD81B60)], speed: 0.05),
          Layer(motion: Motion.rise, shape: Shape.emoji, count: 3, glyphs: ['🌹', '💐', '🌷'], speed: 0.035,
              minSize: 0.045, maxSize: 0.06),
        ],
      ),
      const SeasonTheme(
        id: 'phucSinh', name: 'Lễ Phục Sinh', emoji: '🐣', accent: Color(0xFFB39DDB),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 14,
              colors: [Color(0xFFB2EBF2), Color(0xFFFFF59D), Color(0xFFE1BEE7)], speed: 0.05),
          Layer(motion: Motion.rise, shape: Shape.emoji, count: 4, glyphs: ['🥚', '🐣', '🐰', '🌷'], speed: 0.035,
              minSize: 0.045, maxSize: 0.06),
        ],
      ),
      const SeasonTheme(
        id: 'thieuNhi', name: 'Quốc tế Thiếu nhi 1/6', emoji: '🎈', accent: Color(0xFF29B6F6),
        layers: [
          Layer(motion: Motion.rise, shape: Shape.balloon, count: 10, colors: _party, speed: 0.045,
              minSize: 0.035, maxSize: 0.055),
          Layer(motion: Motion.fall, shape: Shape.confetti, count: 25, colors: _party, speed: 0.07),
        ],
      ),
      const SeasonTheme(
        id: 'trungThu', name: 'Tết Trung Thu', emoji: '🏮', accent: Color(0xFFFFB300), glow: Color(0x33FFA000),
        layers: [
          Layer(motion: Motion.moon, shape: Shape.dot, count: 1, colors: [Color(0xFFFFF8E1)]),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 14, colors: [Colors.white]),
          Layer(motion: Motion.rise, shape: Shape.lantern, count: 7,
              colors: [Color(0xFFE53935), Color(0xFFFF9800), Color(0xFFFFEB3B)], speed: 0.03,
              minSize: 0.03, maxSize: 0.05),
          Layer(motion: Motion.rise, shape: Shape.emoji, count: 1, glyphs: ['🐇'], speed: 0.025,
              minSize: 0.06, maxSize: 0.06),
        ],
      ),
      const SeasonTheme(
        id: 'halloween', name: 'Halloween', emoji: '🎃', accent: Color(0xFFFF7518), glow: Color(0x447B1FA2),
        layers: [
          Layer(motion: Motion.fly, shape: Shape.bat, count: 7, colors: [Color(0xFF1A1A1A), Color(0xFF4A148C)],
              speed: 0.07, minSize: 0.03, maxSize: 0.05),
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 4, glyphs: ['🎃', '👻', '🍬', '🕸️'], speed: 0.035,
              minSize: 0.045, maxSize: 0.06),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 10, colors: [Color(0xFFFF9800)]),
        ],
      ),
      const SeasonTheme(
        id: 'nhaGiao', name: 'Nhà giáo Việt Nam 20/11', emoji: '📚', accent: Color(0xFF4FC3F7),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 16, colors: _pinks, speed: 0.05),
          Layer(motion: Motion.rise, shape: Shape.emoji, count: 3, glyphs: ['💐', '📚', '✏️'], speed: 0.035,
              minSize: 0.045, maxSize: 0.06),
        ],
      ),
      // ---- Chỉ tự chọn (lễ hội các nước) ----
      const SeasonTheme(
        id: 'hanami', name: 'Ngắm hoa anh đào (Nhật Bản)', emoji: '🌸', accent: Color(0xFFFFB7C5),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 45, colors: _pinks, speed: 0.06, sway: 0.05),
        ],
      ),
      const SeasonTheme(
        id: 'holi', name: 'Lễ hội sắc màu Holi (Ấn Độ)', emoji: '🎨', accent: Color(0xFFE040FB),
        layers: [
          Layer(motion: Motion.burst, shape: Shape.dot, count: 4, colors: _party, speed: 0.3),
          Layer(motion: Motion.wander, shape: Shape.dot, count: 24, colors: _party, minSize: 0.01, maxSize: 0.03),
        ],
      ),
      const SeasonTheme(
        id: 'diwali', name: 'Lễ hội ánh sáng Diwali (Ấn Độ)', emoji: '🪔', accent: Color(0xFFFFB300),
        glow: Color(0x33FF6F00),
        layers: [
          Layer(motion: Motion.garland, shape: Shape.dot, count: 16, colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)]),
          Layer(motion: Motion.burst, shape: Shape.dot, count: 2, colors: [Color(0xFFFFD740), Color(0xFFFF6E40)], speed: 0.35),
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 14, colors: [Color(0xFFFFCA28)]),
        ],
      ),
      const SeasonTheme(
        id: 'songkran', name: 'Té nước Songkran (Thái Lan)', emoji: '💦', accent: Color(0xFF29B6F6),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.dot, count: 40, colors: [Color(0xCC81D4FA), Color(0xCCB3E5FC)],
              speed: 0.16, minSize: 0.005, maxSize: 0.012, sway: 0.01),
          Layer(motion: Motion.burst, shape: Shape.dot, count: 2, colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)], speed: 0.45),
        ],
      ),
      const SeasonTheme(
        id: 'hoiAn', name: 'Đêm phố cổ Hội An', emoji: '🏮', accent: Color(0xFFFFA000), glow: Color(0x33FF6F00),
        layers: [
          Layer(motion: Motion.garland, shape: Shape.lantern, count: 8,
              colors: [Color(0xFFE53935), Color(0xFFFFB300), Color(0xFF8E24AA), Color(0xFF43A047)]),
          Layer(motion: Motion.rise, shape: Shape.lantern, count: 6,
              colors: [Color(0xFFE53935), Color(0xFFFFB300), Color(0xFF8E24AA)], speed: 0.025),
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 10, colors: [Color(0xFFFFE082)]),
        ],
      ),
      const SeasonTheme(
        id: 'sinhNhat', name: 'Sinh nhật', emoji: '🎂', accent: Color(0xFFFF80AB),
        layers: [
          Layer(motion: Motion.rise, shape: Shape.balloon, count: 9, colors: _party, speed: 0.045,
              minSize: 0.035, maxSize: 0.055),
          Layer(motion: Motion.fall, shape: Shape.confetti, count: 35, colors: _party, speed: 0.08),
          Layer(motion: Motion.burst, shape: Shape.dot, count: 1, colors: _fireworks, speed: 0.35),
        ],
      ),
    ];

SeasonTheme? themeById(String id, DateTime now) {
  for (final t in allThemes(now)) {
    if (t.id == id) return t;
  }
  return null;
}

// ---------------------------------------------------------------------
// Lịch tự động
// ---------------------------------------------------------------------

/// Ngày mùng 1 Tết (dương lịch).
const Map<int, (int, int)> kTetDates = {
  2026: (2, 17), 2027: (2, 6), 2028: (1, 26), 2029: (2, 13), 2030: (2, 3),
  2031: (1, 23), 2032: (2, 11), 2033: (1, 31), 2034: (2, 19), 2035: (2, 8),
};

/// Rằm tháng 8 âm lịch (Trung Thu, dương lịch).
const Map<int, (int, int)> kTrungThuDates = {
  2026: (9, 25), 2027: (9, 15), 2028: (10, 3), 2029: (9, 22), 2030: (9, 12),
  2031: (10, 1), 2032: (9, 19), 2033: (9, 8), 2034: (9, 27), 2035: (9, 16),
};

/// Năm âm lịch của một ngày (để biết con giáp).
int lunarYearOf(DateTime d) {
  final t = kTetDates[d.year];
  if (t == null) return d.year;
  return d.isBefore(DateTime(d.year, t.$1, t.$2)) ? d.year - 1 : d.year;
}

/// Ngày Chủ nhật Phục Sinh (thuật toán Gregory).
DateTime easterOf(int y) {
  final a = y % 19, b = y ~/ 100, c = y % 100, d = b ~/ 4, e = b % 4;
  final f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3, h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31, day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime(y, month, day);
}

bool _within(DateTime d, DateTime from, DateTime to) {
  final x = DateTime(d.year, d.month, d.day);
  return !x.isBefore(from) && !x.isAfter(to);
}

/// Theme tự động cho một ngày (lễ hội ưu tiên trước, rồi tới 4 mùa).
String autoThemeId(DateTime d) {
  final y = d.year;
  final tet = kTetDates[y];
  if (tet != null) {
    final day = DateTime(y, tet.$1, tet.$2);
    if (_within(d, day.subtract(const Duration(days: 7)), day.add(const Duration(days: 7)))) return 'tet';
  }
  final tt = kTrungThuDates[y];
  if (tt != null) {
    final day = DateTime(y, tt.$1, tt.$2);
    if (_within(d, day.subtract(const Duration(days: 5)), day)) return 'trungThu';
  }
  if ((d.month == 12 && d.day == 31) || (d.month == 1 && d.day <= 1)) return 'namMoi';
  if (d.month == 12 && d.day >= 15 && d.day <= 26) return 'giangSinh';
  if (d.month == 10 && d.day >= 25) return 'halloween';
  if (d.month == 2 && d.day >= 10 && d.day <= 14) return 'valentine';
  final easter = easterOf(y);
  final carnivalTue = easter.subtract(const Duration(days: 47));
  if (_within(d, carnivalTue.subtract(const Duration(days: 3)), carnivalTue)) return 'carnival';
  if (_within(d, easter.subtract(const Duration(days: 2)), easter.add(const Duration(days: 1)))) {
    return 'phucSinh';
  }
  if ((d.month == 3 && d.day >= 6 && d.day <= 8) || (d.month == 10 && d.day >= 18 && d.day <= 20)) {
    return 'phuNu';
  }
  if ((d.month == 5 && d.day >= 30) || (d.month == 6 && d.day == 1)) return 'thieuNhi';
  if (d.month == 11 && d.day >= 18 && d.day <= 20) return 'nhaGiao';
  if (d.month <= 3) return 'xuan';
  if (d.month <= 6) return 'ha';
  if (d.month <= 9) return 'thu';
  return 'dong';
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

// =====================================================================
// Theme mùa & lễ hội: chỉ thêm lớp hiệu ứng (hoa rơi, tuyết, pháo hoa...)
// và màu nhấn cho vòng đồng hồ, chữ giờ. KHÔNG đổi ảnh user đã chọn.
// =====================================================================

/// Các kiểu chuyển động của hạt.
enum Motion { fall, rise, fly, wander, burst, twinkle, garland, moon, collide, aurora, waterfall, sleigh, bounce, bloom, pair, firecracker }

/// Hình dạng hạt (vẽ bằng code) hoặc emoji.
enum Shape { dot, petal, leaf, snowflake, confetti, heart, sparkle, balloon, lantern, bat, feather, firefly, emoji, sun, waterBall }

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

/// Con giáp nguyên con (không chỉ cái đầu) cho theme Tết.
const List<String> kZodiacFullBody = ['🐀', '🐂', '🐅', '🐈', '🐉', '🐍', '🐎', '🐐', '🐒', '🐓', '🐕', '🐖'];
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
    name: 'Năm mới & Tết Nguyên Đán – năm ${kZodiacName[z]}',
    emoji: '🧧',
    accent: const Color(0xFFFFC107),
    glow: const Color(0x55FF1744),
    layers: [
      const Layer(motion: Motion.garland, shape: Shape.lantern, count: 7,
          colors: [Color(0xFFE53935), Color(0xFFFF7043)]),
      const Layer(motion: Motion.fall, shape: Shape.petal, count: 16, colors: _mai, speed: 0.06),
      const Layer(motion: Motion.fall, shape: Shape.petal, count: 10, colors: _pinks, speed: 0.06),
      const Layer(motion: Motion.burst, shape: Shape.dot, count: 3, colors: _fireworks, speed: 0.38),
      const Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 8, colors: [Colors.white, Color(0xFFFFD740)]),
      // dây pháo đỏ treo hai bên nổ tí tách
      const Layer(motion: Motion.firecracker, shape: Shape.dot, count: 2,
          colors: [Color(0xFFE53935), Color(0xFFFFD740)], speed: 1.0),
      // con giáp của năm (nguyên con) chạy / bay ngang trời
      Layer(motion: Motion.fly, shape: Shape.emoji, count: 2, glyphs: [kZodiacFullBody[z]],
          minSize: 0.08, maxSize: 0.1, speed: 0.045),
    ],
  );
}

/// Tất cả theme (theme Tết mặc định theo năm hiện tại).
List<SeasonTheme> allThemes(DateTime now) => [
      const SeasonTheme(
        id: 'xuan', name: 'Mùa xuân', emoji: '🌸', accent: Color(0xFFFF8FB1),
        layers: [
          // trăm hoa đua nở: hoa, mầm non bung ra khắp nơi rồi khép lại
          Layer(motion: Motion.bloom, shape: Shape.emoji, count: 22,
              glyphs: ['🌸', '🌼', '🌷', '🌺', '🌻', '🌱', '💮', '🌿', '🏵️'], speed: 0.12,
              minSize: 0.035, maxSize: 0.06),
          // chim bay từng đôi tìm bạn
          Layer(motion: Motion.pair, shape: Shape.emoji, count: 3, glyphs: ['🐦', '🕊️'], speed: 0.05,
              minSize: 0.045, maxSize: 0.055),
          Layer(motion: Motion.wander, shape: Shape.emoji, count: 4, glyphs: ['🦋', '🐝'],
              minSize: 0.03, maxSize: 0.04),
          Layer(motion: Motion.fall, shape: Shape.leaf, count: 6, colors: [Color(0xFF9CCC65), Color(0xFF66BB6A)],
              speed: 0.05),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 8, colors: [Color(0xFFFFF59D)]),
        ],
      ),
      const SeasonTheme(
        id: 'ha', name: 'Mùa hạ', emoji: '☀️', accent: Color(0xFFFFC93C), glow: Color(0x33FFC107),
        layers: [
          Layer(motion: Motion.bounce, shape: Shape.sun, count: 6, colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              minSize: 0.04, maxSize: 0.06, speed: 0.6),
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 12, colors: [Color(0xFFDCE775), Color(0xFFFFF176)]),
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
          // ông già Noel trên xe tuần lộc bay ngang trời
          Layer(motion: Motion.sleigh, shape: Shape.emoji, count: 1, glyphs: ['🦌', '🦌', '🛷', '🎅'],
              colors: [Color(0xFFFFE082)], minSize: 0.07, maxSize: 0.07, speed: 0.05),
        ],
      ),
      tetTheme(lunarYearOf(now)),
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
          // bi màu lao vào nhau, chạm nhau mới nổ tung thành bụi màu
          Layer(motion: Motion.collide, shape: Shape.dot, count: 10, colors: _party, speed: 0.22,
              minSize: 0.035, maxSize: 0.05),
        ],
      ),
      const SeasonTheme(
        id: 'diwali', name: 'Lễ hội ánh sáng Diwali (Ấn Độ)', emoji: '🪔', accent: Color(0xFFFFB300),
        glow: Color(0x33FF6F00),
        layers: [
          // dải cực quang uốn lượn
          Layer(motion: Motion.aurora, shape: Shape.dot, count: 8,
              colors: [Color(0xFF00E676), Color(0xFF1DE9B6), Color(0xFF7C4DFF), Color(0xFFFF4081)], speed: 0.05),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 14, colors: [Colors.white]),
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 10, colors: [Color(0xFFFFCA28)]),
        ],
      ),
      const SeasonTheme(
        id: 'songkran', name: 'Té nước Songkran (Thái Lan)', emoji: '💦', accent: Color(0xFF29B6F6),
        layers: [
          // bóng nước trong suốt va nhau, vỡ ra thành giọt nước rơi xuống
          Layer(motion: Motion.collide, shape: Shape.waterBall, count: 12,
              colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFF4FC3F7)], speed: 0.2,
              minSize: 0.06, maxSize: 0.09),
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
      const SeasonTheme(
        id: 'phatDan', name: 'Lễ Phật Đản (rằm tháng 4 âm)', emoji: '🪷', accent: Color(0xFFFFCA28),
        glow: Color(0x33FFD54F),
        layers: [
          Layer(motion: Motion.bloom, shape: Shape.emoji, count: 14, glyphs: ['🪷', '🪷', '🌸'], speed: 0.08,
              minSize: 0.045, maxSize: 0.07),
          Layer(motion: Motion.rise, shape: Shape.lantern, count: 5,
              colors: [Color(0xFFFFCA28), Color(0xFFFF8A65), Color(0xFFF48FB1)], speed: 0.025),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 10, colors: [Color(0xFFFFF59D)]),
        ],
      ),
      const SeasonTheme(
        id: 'doanNgo', name: 'Tết Đoan Ngọ (5/5 âm)', emoji: '🍑', accent: Color(0xFFFF7043),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 6,
              glyphs: ['🍑', '🥭', '🍒', '🍉', '🍋', '🍇', '🌿'], speed: 0.05, minSize: 0.04, maxSize: 0.06),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 8, colors: [Color(0xFFFFE082)]),
        ],
      ),
      const SeasonTheme(
        id: 'vuLan', name: 'Lễ Vu Lan (rằm tháng 7 âm)', emoji: '🌹', accent: Color(0xFFE57373),
        glow: Color(0x22FF8A80),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.petal, count: 10,
              colors: [Color(0xFFE53935), Color(0xFFFFFFFF), Color(0xFFF48FB1)], speed: 0.04),
          Layer(motion: Motion.bloom, shape: Shape.emoji, count: 8, glyphs: ['🌹', '🪷', '🌹'], speed: 0.07,
              minSize: 0.04, maxSize: 0.06),
          Layer(motion: Motion.rise, shape: Shape.lantern, count: 4,
              colors: [Color(0xFFFFCA28), Color(0xFFFF8A65)], speed: 0.02),
        ],
      ),
      const SeasonTheme(
        id: 'thaDen', name: 'Lễ hội thả đèn trời Loy Krathong (Thái Lan)', emoji: '🏮',
        accent: Color(0xFFFFB74D), glow: Color(0x33FF9800),
        layers: [
          Layer(motion: Motion.moon, shape: Shape.dot, count: 1, colors: [Color(0xFFFFF8E1)]),
          Layer(motion: Motion.rise, shape: Shape.lantern, count: 6,
              colors: [Color(0xFFFFB74D), Color(0xFFFFCC80), Color(0xFFFF8A65)], speed: 0.018,
              minSize: 0.015, maxSize: 0.035, sway: 0.02),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 10, colors: [Color(0xFFFFE0B2)]),
        ],
      ),
      const SeasonTheme(
        id: 'quocKhanh', name: 'Quốc khánh 2/9', emoji: '🇻🇳', accent: Color(0xFFFFD600),
        glow: Color(0x33E53935),
        layers: [
          Layer(motion: Motion.rise, shape: Shape.balloon, count: 5,
              colors: [Color(0xFFE53935), Color(0xFFFFD600)], speed: 0.045, minSize: 0.035, maxSize: 0.05),
          Layer(motion: Motion.twinkle, shape: Shape.sparkle, count: 10, colors: [Color(0xFFFFD600)]),
          Layer(motion: Motion.burst, shape: Shape.dot, count: 2,
              colors: [Color(0xFFE53935), Color(0xFFFFD600)], speed: 0.35),
        ],
      ),
      const SeasonTheme(
        id: 'traiDat', name: 'Ngày Trái Đất 22/4', emoji: '🌍', accent: Color(0xFF66BB6A),
        layers: [
          Layer(motion: Motion.bloom, shape: Shape.emoji, count: 14, glyphs: ['🌱', '🌳', '🌻', '🌿', '🌍', '🌼'],
              speed: 0.1, minSize: 0.035, maxSize: 0.06),
          Layer(motion: Motion.wander, shape: Shape.emoji, count: 3, glyphs: ['🦋', '🐝', '🐞'],
              minSize: 0.03, maxSize: 0.04),
          Layer(motion: Motion.fall, shape: Shape.leaf, count: 6, colors: [Color(0xFF9CCC65), Color(0xFF43A047)],
              speed: 0.05),
        ],
      ),
      const SeasonTheme(
        id: 'ngayCuaMe', name: 'Ngày của Mẹ', emoji: '💐', accent: Color(0xFFF06292),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 5, glyphs: ['💐', '🌷', '🌸', '💗', '🌹'],
              speed: 0.045, minSize: 0.035, maxSize: 0.055),
          Layer(motion: Motion.rise, shape: Shape.heart, count: 6,
              colors: [Color(0xFFFF80AB), Color(0xFFF8BBD0)], speed: 0.04),
        ],
      ),
      const SeasonTheme(
        id: 'tomatina', name: 'Lễ hội ném cà chua La Tomatina (Tây Ban Nha)', emoji: '🍅',
        accent: Color(0xFFE53935),
        layers: [
          Layer(motion: Motion.collide, shape: Shape.dot, count: 10,
              colors: [Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFFF5252), Color(0xFFC62828)], speed: 0.25,
              minSize: 0.04, maxSize: 0.055),
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 3, glyphs: ['🍅'], speed: 0.06,
              minSize: 0.035, maxSize: 0.05),
        ],
      ),
      const SeasonTheme(
        id: 'taOn', name: 'Lễ Tạ Ơn (Thanksgiving)', emoji: '🦃', accent: Color(0xFFE08A2E),
        layers: [
          Layer(motion: Motion.fall, shape: Shape.leaf, count: 14, colors: _autumn, speed: 0.05, sway: 0.06,
              minSize: 0.018, maxSize: 0.04),
          Layer(motion: Motion.fall, shape: Shape.emoji, count: 3, glyphs: ['🦃', '🌽', '🥧', '🍁', '🎃'],
              speed: 0.04, minSize: 0.04, maxSize: 0.055),
        ],
      ),
      const SeasonTheme(
        id: 'diaDeMuertos', name: 'Lễ hội hoa cúc vạn thọ Día de Muertos (Mexico)', emoji: '🌼',
        accent: Color(0xFFFF9800), glow: Color(0x33AB47BC),
        layers: [
          Layer(motion: Motion.garland, shape: Shape.confetti, count: 12,
              colors: [Color(0xFFE91E63), Color(0xFFFF9800), Color(0xFF7E57C2), Color(0xFF26C6DA), Color(0xFF8BC34A)]),
          Layer(motion: Motion.fall, shape: Shape.petal, count: 16,
              colors: [Color(0xFFFF9800), Color(0xFFFFB300), Color(0xFFFF6F00)], speed: 0.05),
          Layer(motion: Motion.wander, shape: Shape.firefly, count: 8, colors: [Color(0xFFFFCC80)]),
        ],
      ),
    ];

SeasonTheme? themeById(String id, DateTime now) {
  if (id == 'namMoi') id = 'tet'; // Năm mới đã gộp chung với Tết
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
  2026: (2, 17), 2027: (2, 6), 2028: (1, 26), 2029: (2, 13), 2030: (2, 2),
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

// ---------------------------------------------------------------------
// Âm lịch Việt Nam (thuật toán Hồ Ngọc Đức, múi giờ +7)
// ---------------------------------------------------------------------
int _jdFromDate(int d, int m, int y) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a, mm = m + 12 * a - 3;
  return d + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
}

DateTime _jdToDate(int jd) {
  final a = jd + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (b * 146097) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  return DateTime(b * 100 + d - 4800 + m ~/ 10, m + 3 - 12 * (m ~/ 10), e - (153 * m + 2) ~/ 5 + 1);
}

int _newMoonDay(int k) {
  const dr = math.pi / 180;
  final t = k / 1236.85, t2 = t * t, t3 = t2 * t;
  var jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
  jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
  final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
  final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
  final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
  var c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) + 0.0021 * math.sin(2 * dr * m);
  c1 = c1 - 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
  c1 = c1 - 0.0004 * math.sin(dr * 3 * mpr);
  c1 = c1 + 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
  c1 = c1 - 0.0074 * math.sin(dr * (m - mpr)) + 0.0004 * math.sin(dr * (2 * f + m));
  c1 = c1 - 0.0004 * math.sin(dr * (2 * f - m)) - 0.0006 * math.sin(dr * (2 * f + mpr));
  c1 = c1 + 0.0010 * math.sin(dr * (2 * f - mpr)) + 0.0005 * math.sin(dr * (2 * mpr + m));
  final deltat = t < -11
      ? 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
      : -0.000278 + 0.000265 * t + 0.000262 * t2;
  return (jd1 + c1 - deltat + 0.5 + 7 / 24).floor();
}

int _sunLongitude(int dayNumber) {
  const dr = math.pi / 180;
  final t = (dayNumber - 0.5 - 7 / 24 - 2451545.0) / 36525, t2 = t * t;
  final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
  final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
  var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
  dl += (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) + 0.000290 * math.sin(dr * 3 * m);
  var l = (l0 + dl) * dr;
  l -= math.pi * 2 * (l / (math.pi * 2)).floor();
  return (l / math.pi * 6).floor();
}

int _lunarMonth11(int yy) {
  final off = _jdFromDate(31, 12, yy) - 2415021;
  final k = (off / 29.530588853).floor();
  var nm = _newMoonDay(k);
  if (_sunLongitude(nm) >= 9) nm = _newMoonDay(k - 1);
  return nm;
}

int _leapMonthOffset(int a11) {
  final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
  var i = 1;
  var arc = _sunLongitude(_newMoonDay(k + i));
  int last;
  do {
    last = arc;
    i++;
    arc = _sunLongitude(_newMoonDay(k + i));
  } while (arc != last && i < 14);
  return i - 1;
}

/// Ngày âm lịch (tháng thường, không nhuận) → ngày dương lịch.
DateTime lunarToSolar(int day, int month, int year) {
  final int a11, b11;
  if (month < 11) {
    a11 = _lunarMonth11(year - 1);
    b11 = _lunarMonth11(year);
  } else {
    a11 = _lunarMonth11(year);
    b11 = _lunarMonth11(year + 1);
  }
  final k = (0.5 + (a11 - 2415021.076998695) / 29.530588853).floor();
  var off = month - 11;
  if (off < 0) off += 12;
  if (b11 - a11 > 365) {
    final leapOff = _leapMonthOffset(a11);
    if (off >= leapOff) off += 1;
  }
  return _jdToDate(_newMoonDay(k + off) + day - 1);
}

/// Thứ [nth] (1 = đầu tiên, -1 = cuối cùng) của [weekday] trong tháng.
DateTime nthWeekday(int y, int m, int weekday, int nth) {
  if (nth > 0) {
    final first = DateTime(y, m, 1);
    return DateTime(y, m, 1 + (weekday - first.weekday + 7) % 7 + 7 * (nth - 1));
  }
  final last = DateTime(y, m + 1, 0);
  return DateTime(y, m, last.day - (last.weekday - weekday + 7) % 7);
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
  if ((d.month == 12 && d.day == 31) || (d.month == 1 && d.day <= 1)) return 'tet';
  bool nearLunar(int day, int month, int before, [int after = 0]) {
    for (final ly in [y - 1, y]) {
      final x = lunarToSolar(day, month, ly);
      if (_within(d, x.subtract(Duration(days: before)), x.add(Duration(days: after)))) return true;
    }
    return false;
  }

  if (nearLunar(15, 4, 2)) return 'phatDan';
  if (nearLunar(5, 5, 1)) return 'doanNgo';
  if (nearLunar(15, 7, 5)) return 'vuLan';
  if (nearLunar(15, 10, 2)) return 'thaDen';
  if (d.month == 9 && d.day <= 2) return 'quocKhanh';
  if (d.month == 4 && d.day >= 21 && d.day <= 22) return 'traiDat';
  final me = nthWeekday(y, 5, DateTime.sunday, 2);
  if (_within(d, me.subtract(const Duration(days: 1)), me)) return 'ngayCuaMe';
  if (_within(d, nthWeekday(y, 8, DateTime.wednesday, -1), nthWeekday(y, 8, DateTime.wednesday, -1))) {
    return 'tomatina';
  }
  final taOn = nthWeekday(y, 11, DateTime.thursday, 4);
  if (_within(d, taOn.subtract(const Duration(days: 1)), taOn)) return 'taOn';
  if (d.month == 11 && d.day <= 2) return 'diaDeMuertos';
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

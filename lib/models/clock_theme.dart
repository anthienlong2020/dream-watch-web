import 'dart:typed_data';

/// Một hình hiển thị trên mặt đồng hồ: ảnh do người dùng chọn (bytes),
/// ảnh có sẵn trong app (asset), hoặc emoji dự phòng.
class SlotImage {
  final Uint8List? bytes;
  final String? asset;
  final String emoji;

  const SlotImage({this.bytes, this.asset, required this.emoji});
}

/// Một bộ chủ đề gồm 12 hình. Chỉ số 0 = vị trí XII, 1 = I, ..., 11 = XI.
class ClockTheme {
  final String id;
  final String name;
  final List<SlotImage> slots;

  const ClockTheme({required this.id, required this.name, required this.slots});

  SlotImage slot(int index) => slots[index % 12];
}

/// Vị trí trên mặt đồng hồ -> chữ số La Mã (viết thường như bản cũ).
const List<String> kRoman = [
  'xii', 'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x', 'xi'
];

/// Số hiển thị cho vị trí (0 -> 12).
int slotNumber(int index) => index == 0 ? 12 : index;

/// Giờ hiện tại đang ở vị trí nào (0..11).
int hourSlot(DateTime t) => t.hour % 12;

/// Hình nào làm "hình phút": hình đứng ở mốc 5 phút vừa qua.
/// Ví dụ 20:35..20:39 -> hình ở vị trí VII (mốc 35 phút), 20:40 -> VIII.
int minuteSlot(DateTime t) => (t.minute ~/ 5) % 12;

/// Mốc 5 phút vừa qua (0, 5, 10, ... 55).
int minuteAnchor(DateTime t) => t.minute - t.minute % 5;

const List<String> _dinoEmoji = [
  '🦖', '🦕', '🐊', '🦎', '🐢', '🐍', '🐉', '🐲', '🦏', '🦣', '🦤', '🐘'
];

/// 12 con giáp: XII = Tý, I = Sửu, ..., XI = Hợi.
const List<String> _zodiacEmoji = [
  '🐭', '🐃', '🐯', '🐱', '🐲', '🐍', '🐴', '🐐', '🐵', '🐓', '🐶', '🐷'
];

const List<String> _zodiacNames = [
  'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'
];

String zodiacName(int index) => _zodiacNames[index % 12];

ClockTheme buildDinoTheme() => ClockTheme(
      id: 'khung_long',
      name: 'Khủng long',
      slots: List.generate(
        12,
        (i) => SlotImage(
          asset: 'assets/themes/khung_long/${slotNumber(i)}.png',
          emoji: _dinoEmoji[i],
        ),
      ),
    );

ClockTheme buildZodiacTheme() => ClockTheme(
      id: 'con_giap',
      name: '12 con giáp',
      slots: List.generate(12, (i) => SlotImage(emoji: _zodiacEmoji[i])),
    );

/// Chủ đề của người dùng: ô nào chưa có ảnh thì dùng emoji khủng long.
ClockTheme buildCustomTheme(List<Uint8List?> images) => ClockTheme(
      id: 'tu_chon',
      name: 'Ảnh của tôi',
      slots: List.generate(
        12,
        (i) => SlotImage(
          bytes: i < images.length ? images[i] : null,
          emoji: _dinoEmoji[i],
        ),
      ),
    );

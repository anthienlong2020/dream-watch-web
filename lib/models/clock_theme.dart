import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../chibi/chibi3d.dart';

/// Một hình hiển thị trên mặt đồng hồ: ảnh do người dùng chọn (bytes),
/// ảnh có sẵn trong app (asset), hoặc emoji dự phòng.
class SlotImage {
  final Uint8List? bytes;
  final String? asset;
  final String emoji;

  /// Nhân vật Chibi 3D (nếu có thì vẽ 3D thay cho ảnh).
  final ChibiSpec? chibi;

  const SlotImage({this.bytes, this.asset, required this.emoji, this.chibi});
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

/// Ảnh khủng long có sẵn trong thư mục assets/themes/khung_long/ (tên file tuỳ ý),
/// đã sắp theo tên kiểu tự nhiên (2 đứng trước 10), lấy tối đa 12 ảnh đầu tiên.
List<String> _dinoFiles = const [];

final _imageExt = RegExp(r'\.(png|jpe?g|webp|gif|bmp)$', caseSensitive: false);

/// So sánh tên file kiểu tự nhiên: "2.png" < "10.png", "anh 3" < "anh 12".
int naturalCompare(String a, String b) {
  final re = RegExp(r'(\d+)|(\D+)');
  final pa = re.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final pb = re.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]), nb = int.tryParse(pb[i]);
    final c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

/// Tìm ảnh trong thư mục khủng long (gọi 1 lần lúc mở app).
Future<void> loadDinoAssets() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final files = manifest
        .listAssets()
        .where((p) => p.startsWith('assets/themes/khung_long/') && _imageExt.hasMatch(p))
        .toList()
      ..sort(naturalCompare);
    _dinoFiles = files.take(12).toList();
  } catch (_) {
    _dinoFiles = const [];
  }
}

/// Ảnh thứ 1 → vị trí I, ảnh thứ 2 → II, ..., ảnh thứ 12 → XII. Thiếu ảnh thì dùng emoji.
ClockTheme buildDinoTheme() => ClockTheme(
      id: 'khung_long',
      name: 'Khủng long',
      slots: List.generate(12, (i) {
        final n = slotNumber(i) - 1; // vị trí XII (i = 0) dùng ảnh thứ 12
        return SlotImage(
          asset: n < _dinoFiles.length ? _dinoFiles[n] : null,
          emoji: _dinoEmoji[i],
        );
      }),
    );

ClockTheme buildZodiacTheme() => ClockTheme(
      id: 'con_giap',
      name: '12 con giáp',
      slots: List.generate(12, (i) => SlotImage(emoji: _zodiacEmoji[i])),
    );

/// Chủ đề của người dùng: ô nào chưa có ảnh thì dùng emoji khủng long.
ClockTheme buildCustomTheme(List<Uint8List?> images,
        [List<ChibiSpec?> chibis = const []]) =>
    ClockTheme(
      id: 'tu_chon',
      name: 'Ảnh của tôi',
      slots: List.generate(
        12,
        (i) => SlotImage(
          bytes: i < images.length ? images[i] : null,
          emoji: _dinoEmoji[i],
          chibi: i < chibis.length ? chibis[i] : null,
        ),
      ),
    );

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Thu nhỏ ảnh người dùng chọn (giữ nền trong suốt, xuất PNG) để lưu gọn
/// trong bộ nhớ trình duyệt / máy. Ảnh động GIF chỉ lấy khung đầu.
Future<Uint8List> shrinkImage(Uint8List bytes, {int maxSide = 320}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final first = (await probe.getNextFrame()).image;
  final w = first.width;
  final h = first.height;
  first.dispose();

  final scale = math.min(1.0, maxSide / math.max(w, h));
  final tw = math.max(1, (w * scale).round());
  final th = math.max(1, (h * scale).round());

  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: tw,
    targetHeight: th,
  );
  final img = (await codec.getNextFrame()).image;
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  if (data == null) return bytes;
  return data.buffer.asUint8List();
}

/// Thu nhỏ ảnh nền (ảnh chụp, không cần trong suốt) và nén JPEG cho nhẹ,
/// để lưu được nhiều hình nền trong bộ nhớ trình duyệt.
Future<Uint8List> shrinkToJpeg(Uint8List bytes,
    {int maxSide = 1080, int quality = 78}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final first = (await probe.getNextFrame()).image;
  final w = first.width;
  final h = first.height;
  first.dispose();

  final scale = math.min(1.0, maxSide / math.max(w, h));
  final tw = math.max(1, (w * scale).round());
  final th = math.max(1, (h * scale).round());

  final codec = await ui.instantiateImageCodec(bytes,
      targetWidth: tw, targetHeight: th);
  final frame = (await codec.getNextFrame()).image;
  final raw = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.dispose();
  if (raw == null) return bytes;

  final image = img.Image.fromBytes(
    width: tw,
    height: th,
    bytes: raw.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: quality);
}

/// Lấy số 1..12 trong tên file (vd "3.png", "khunglong_12.jpg"). Trả về null nếu không có.
int? numberFromFileName(String name) {
  var base = name.split('/').last.split('\\').last;
  final dot = base.lastIndexOf('.');
  if (dot > 0) base = base.substring(0, dot);
  final matches = RegExp(r'\d+').allMatches(base).toList();
  if (matches.isEmpty) return null;
  final n = int.tryParse(matches.last.group(0)!);
  if (n == null || n < 1 || n > 12) return null;
  return n;
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Các kiểu trang phục chibi.
enum ChibiOutfit { aoThun, vay, vest, khungLong, heroNam, heroNu }

const Map<ChibiOutfit, String> kOutfitNames = {
  ChibiOutfit.aoThun: 'Áo thun',
  ChibiOutfit.vay: 'Váy',
  ChibiOutfit.vest: 'Vest',
  ChibiOutfit.khungLong: 'Đồ khủng long',
  ChibiOutfit.heroNam: '💪 Siêu anh hùng nam (tỷ lệ thật)',
  ChibiOutfit.heroNu: '🦸 Nữ anh hùng (tỷ lệ thật)',
};

/// Bảng màu trang phục.
const List<Color> kOutfitColors = [
  Color(0xFFE53935), // đỏ
  Color(0xFFFF8F00), // cam
  Color(0xFFFDD835), // vàng
  Color(0xFF43A047), // xanh lá
  Color(0xFF1E88E5), // xanh dương
  Color(0xFF8E24AA), // tím
  Color(0xFFEC407A), // hồng
  Color(0xFF6D4C41), // nâu
  Color(0xFF37474F), // xám đậm
  Color(0xFFFAFAFA), // trắng
];

// =====================================================================
// Khoanh mặt: ảnh gốc + phóng to + dịch chuyển -> hình tròn
// =====================================================================

/// Vị trí khoanh mặt, tính theo khung xem có cạnh [viewport].
class FaceCrop {
  final double zoom; // 1 = ảnh vừa kín khung tròn
  final Offset offset; // dịch tâm ảnh so với tâm khung (pixel của khung xem)
  final double viewport;
  const FaceCrop({this.zoom = 1, this.offset = Offset.zero, required this.viewport});
}

/// Vẽ phần ảnh nằm trong khung tròn [crop] vào hình tròn tâm [center], bán kính [r].
void paintFaceCircle(Canvas canvas, ui.Image photo, FaceCrop crop, Offset center, double r) {
  final w = photo.width.toDouble();
  final h = photo.height.toDouble();
  final k = (2 * r) / crop.viewport; // quy đổi từ khung xem sang hình vẽ
  final base = crop.viewport / math.min(w, h); // ảnh phủ kín khung
  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
  canvas.translate(center.dx + crop.offset.dx * k, center.dy + crop.offset.dy * k);
  canvas.scale(base * crop.zoom * k);
  canvas.drawImage(photo, Offset(-w / 2, -h / 2), Paint()..filterQuality = FilterQuality.medium);
  canvas.restore();
}

// =====================================================================
// Vẽ nhân vật chibi (đầu to, thân nhỏ) trên khung vuông cạnh [s]
// =====================================================================

void paintChibi(
  Canvas canvas,
  double s, {
  required ui.Image photo,
  required FaceCrop crop,
  required ChibiOutfit outfit,
  required Color color,
  required Color skin,
}) {
  final cx = s / 2;
  final headR = s * 0.26;
  final headC = Offset(cx, s * 0.33);
  final torsoTop = s * 0.585;
  final torsoBottom = s * 0.80;
  final torsoW = s * 0.30;
  final legBottom = s * 0.91;

  final outline = Paint()
    ..color = const Color(0xFF2B2B2B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.012
    ..strokeJoin = StrokeJoin.round;
  Paint fill(Color c) => Paint()..color = c;
  final darker = Color.lerp(color, Colors.black, 0.25)!;

  // Bóng dưới chân
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, s * 0.945), width: s * 0.42, height: s * 0.05),
    fill(const Color(0x40000000)),
  );

  // Đuôi khủng long (vẽ trước để nằm sau thân)
  if (outfit == ChibiOutfit.khungLong) {
    final tail = Path()
      ..moveTo(cx + torsoW * 0.35, s * 0.74)
      ..quadraticBezierTo(cx + s * 0.36, s * 0.78, cx + s * 0.40, s * 0.66)
      ..quadraticBezierTo(cx + s * 0.30, s * 0.86, cx + torsoW * 0.30, s * 0.84)
      ..close();
    canvas.drawPath(tail, fill(color));
    canvas.drawPath(tail, outline);
  }

  // Chân + giày
  for (final dir in [-1.0, 1.0]) {
    final lx = cx + dir * torsoW * 0.22;
    final leg = RRect.fromRectAndRadius(
      Rect.fromLTRB(lx - s * 0.045, torsoBottom - s * 0.02, lx + s * 0.045, legBottom),
      Radius.circular(s * 0.03),
    );
    final legColor = switch (outfit) {
      ChibiOutfit.aoThun => const Color(0xFF3949AB),
      ChibiOutfit.vay => skin,
      ChibiOutfit.vest => const Color(0xFF263238),
      ChibiOutfit.khungLong => color,
      ChibiOutfit.heroNam => color,
      ChibiOutfit.heroNu => color,
    };
    canvas.drawRRect(leg, fill(legColor));
    canvas.drawRRect(leg, outline);
    final shoe = Rect.fromCenter(
        center: Offset(lx + dir * s * 0.012, legBottom), width: s * 0.11, height: s * 0.05);
    final shoeColor =
        outfit == ChibiOutfit.khungLong ? darker : const Color(0xFF4E342E);
    canvas.drawOval(shoe, fill(shoeColor));
    canvas.drawOval(shoe, outline);
  }

  // Tay (sau thân)
  for (final dir in [-1.0, 1.0]) {
    final shoulder = Offset(cx + dir * torsoW * 0.45, torsoTop + s * 0.04);
    final hand = Offset(cx + dir * torsoW * 0.78, torsoTop + s * 0.15);
    final sleeve = Paint()
      ..color = switch (outfit) {
        ChibiOutfit.vay => skin,
        ChibiOutfit.vest => const Color(0xFF263238),
        _ => color,
      }
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, hand, Paint()
      ..color = outline.color
      ..strokeWidth = sleeve.strokeWidth + outline.strokeWidth * 2
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(shoulder, hand, sleeve);
    canvas.drawCircle(hand, s * 0.04, fill(skin));
    canvas.drawCircle(hand, s * 0.04, outline);
  }

  // Thân
  final Path body;
  if (outfit == ChibiOutfit.vay) {
    body = Path()
      ..moveTo(cx - torsoW * 0.36, torsoTop)
      ..lineTo(cx + torsoW * 0.36, torsoTop)
      ..lineTo(cx + torsoW * 0.66, torsoBottom + s * 0.015)
      ..quadraticBezierTo(cx, torsoBottom + s * 0.05, cx - torsoW * 0.66, torsoBottom + s * 0.015)
      ..close();
  } else {
    body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - torsoW / 2, torsoTop, cx + torsoW / 2, torsoBottom),
        Radius.circular(s * 0.07),
      ));
  }
  final bodyColor = outfit == ChibiOutfit.vest ? const Color(0xFF263238) : color;
  canvas.drawPath(body, fill(bodyColor));

  switch (outfit) {
    case ChibiOutfit.aoThun:
      // Ngôi sao trên áo
      _star(canvas, Offset(cx, (torsoTop + torsoBottom) / 2), s * 0.035,
          fill(Color.lerp(color, Colors.white, 0.6)!));
      break;
    case ChibiOutfit.vay:
      // Nơ eo
      canvas.drawRect(
          Rect.fromLTRB(cx - torsoW * 0.42, torsoTop + s * 0.06, cx + torsoW * 0.42,
              torsoTop + s * 0.085),
          fill(darker));
      break;
    case ChibiOutfit.vest:
      // Áo sơ mi trắng hình chữ V + cà vạt màu đã chọn
      final v = Path()
        ..moveTo(cx - torsoW * 0.22, torsoTop)
        ..lineTo(cx + torsoW * 0.22, torsoTop)
        ..lineTo(cx, torsoTop + s * 0.11)
        ..close();
      canvas.drawPath(v, fill(Colors.white));
      final tie = Path()
        ..moveTo(cx - s * 0.015, torsoTop + s * 0.005)
        ..lineTo(cx + s * 0.015, torsoTop + s * 0.005)
        ..lineTo(cx + s * 0.02, torsoTop + s * 0.09)
        ..lineTo(cx, torsoTop + s * 0.11)
        ..lineTo(cx - s * 0.02, torsoTop + s * 0.09)
        ..close();
      canvas.drawPath(tie, fill(color));
      break;
    case ChibiOutfit.heroNam:
    case ChibiOutfit.heroNu:
      // Đai lưng vàng + huy hiệu tròn trên ngực
      canvas.drawRect(
          Rect.fromLTRB(cx - torsoW / 2, torsoBottom - s * 0.04, cx + torsoW / 2, torsoBottom - s * 0.015),
          fill(const Color(0xFFFFC107)));
      if (outfit == ChibiOutfit.heroNam) {
        canvas.drawCircle(Offset(cx, torsoTop + s * 0.06), s * 0.03, fill(const Color(0xFFFFC107)));
      }
      break;
    case ChibiOutfit.khungLong:
      // Bụng sáng màu
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, (torsoTop + torsoBottom) / 2 + s * 0.01),
              width: torsoW * 0.6,
              height: (torsoBottom - torsoTop) * 0.7),
          fill(Color.lerp(color, Colors.white, 0.55)!));
      break;
  }
  canvas.drawPath(body, outline);

  // Cổ
  canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, torsoTop - s * 0.005), width: s * 0.07, height: s * 0.04),
      fill(skin));

  // Mũ trùm khủng long: vòng mũ + gai phía trên đầu
  if (outfit == ChibiOutfit.khungLong) {
    for (var i = -2; i <= 2; i++) {
      final a = -math.pi / 2 + i * 0.38;
      final base = headC + Offset(math.cos(a), math.sin(a)) * (headR * 1.06);
      final tip = headC + Offset(math.cos(a), math.sin(a)) * (headR * 1.24);
      final side = Offset(-math.sin(a), math.cos(a)) * (s * 0.032);
      final spike = Path()
        ..moveTo(base.dx + side.dx, base.dy + side.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(base.dx - side.dx, base.dy - side.dy)
        ..close();
      canvas.drawPath(spike, fill(Color.lerp(color, Colors.yellow, 0.35)!));
      canvas.drawPath(spike, outline);
    }
    canvas.drawCircle(headC, headR * 1.10, fill(color));
    canvas.drawCircle(headC, headR * 1.10, outline);
  }

  // Đầu = khuôn mặt người dùng
  canvas.drawCircle(headC, headR, fill(skin));
  paintFaceCircle(canvas, photo, crop, headC, headR);
  canvas.drawCircle(
    headC,
    headR,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.014,
  );
  canvas.drawCircle(headC, headR + s * 0.009, outline);

  // Má hồng nhỏ cho dễ thương
  for (final dir in [-1.0, 1.0]) {
    canvas.drawOval(
      Rect.fromCenter(
          center: headC + Offset(dir * headR * 0.55, headR * 0.38),
          width: headR * 0.26,
          height: headR * 0.14),
      fill(const Color(0x33FF4081)),
    );
  }
}

void _star(Canvas canvas, Offset c, double r, Paint p) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  canvas.drawPath(path, p);
}

// =====================================================================
// Màu da: lấy trung bình vùng giữa khuôn mặt đã khoanh
// =====================================================================

Future<Color> sampleSkinColor(ui.Image photo, FaceCrop crop) async {
  const n = 48;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paintFaceCircle(canvas, photo, crop, const Offset(n / 2, n / 2), n / 2);
  final img = await rec.endRecording().toImage(n, n);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  if (data == null) return const Color(0xFFF1C27D);
  var r = 0, g = 0, b = 0, count = 0;
  // Vùng má/mũi: giữa ảnh, hơi lệch xuống dưới
  for (var y = (n * 0.45).round(); y < (n * 0.75).round(); y++) {
    for (var x = (n * 0.3).round(); x < (n * 0.7).round(); x++) {
      final i = (y * n + x) * 4;
      if (data.getUint8(i + 3) < 200) continue;
      r += data.getUint8(i);
      g += data.getUint8(i + 1);
      b += data.getUint8(i + 2);
      count++;
    }
  }
  if (count == 0) return const Color(0xFFF1C27D);
  return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
}

/// Màu tóc: lấy trung bình dải trên cùng của khung mặt.
Future<Color> sampleHairColor(ui.Image photo, FaceCrop crop) async {
  const n = 48;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paintFaceCircle(canvas, photo, crop, const Offset(n / 2, n / 2), n / 2);
  final img = await rec.endRecording().toImage(n, n);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  if (data == null) return const Color(0xFF3E2723);
  var r = 0, g = 0, b = 0, count = 0;
  for (var y = (n * 0.04).round(); y < (n * 0.16).round(); y++) {
    for (var x = (n * 0.35).round(); x < (n * 0.65).round(); x++) {
      final i = (y * n + x) * 4;
      if (data.getUint8(i + 3) < 200) continue;
      r += data.getUint8(i);
      g += data.getUint8(i + 1);
      b += data.getUint8(i + 2);
      count++;
    }
  }
  if (count == 0) return const Color(0xFF3E2723);
  return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
}

/// Ảnh khuôn mặt hình tròn (PNG vuông [size]) để dán lên đầu Chibi 3D.
Future<Uint8List> renderFacePng(ui.Image photo, FaceCrop crop, {int size = 256}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paintFaceCircle(canvas, photo, crop, Offset(size / 2, size / 2), size / 2);
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

// =====================================================================
// Xuất PNG nền trong suốt
// =====================================================================

Future<Uint8List> renderChibiPng({
  required ui.Image photo,
  required FaceCrop crop,
  required ChibiOutfit outfit,
  required Color color,
  required Color skin,
  int size = 360,
}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paintChibi(canvas, size.toDouble(),
      photo: photo, crop: crop, outfit: outfit, color: color, skin: skin);
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

/// Đọc ảnh người dùng chọn thành ui.Image (thu nhỏ còn tối đa 1200px cho nhẹ).
Future<ui.Image> decodePhoto(Uint8List bytes, {int maxSide = 1200}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final first = (await probe.getNextFrame()).image;
  final w = first.width, h = first.height;
  if (math.max(w, h) <= maxSide) return first;
  first.dispose();
  final sc = maxSide / math.max(w, h);
  final codec = await ui.instantiateImageCodec(bytes,
      targetWidth: (w * sc).round(), targetHeight: (h * sc).round());
  return (await codec.getNextFrame()).image;
}

/// Vẽ chibi xem trước trên màn hình.
class ChibiPreviewPainter extends CustomPainter {
  final ui.Image photo;
  final FaceCrop crop;
  final ChibiOutfit outfit;
  final Color color;
  final Color skin;

  ChibiPreviewPainter({
    required this.photo,
    required this.crop,
    required this.outfit,
    required this.color,
    required this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintChibi(canvas, math.min(size.width, size.height),
        photo: photo, crop: crop, outfit: outfit, color: color, skin: skin);
  }

  @override
  bool shouldRepaint(covariant ChibiPreviewPainter o) =>
      o.photo != photo ||
      o.crop != crop ||
      o.outfit != outfit ||
      o.color != color ||
      o.skin != skin;
}

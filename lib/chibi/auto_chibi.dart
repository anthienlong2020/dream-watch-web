import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../three_d/body_type.dart';
import 'chibi3d.dart';
import 'chibi_painter.dart' show ChibiOutfit;

// =====================================================================
// "Thú Chibi": tự biến một ảnh bất kỳ (con vật, đồ vật) thành Chibi 3D,
// lấy cả ảnh làm khuôn mặt, màu tóc/mũ = màu chủ đạo của ảnh.
// =====================================================================

final Map<(Object, ChibiOutfit), Future<ChibiSpec?>> _cache = {};

/// [source]: Uint8List (ảnh người dùng) hoặc String (đường dẫn asset).
/// [outfit]: bộ đồ (mặc định đồ thú có mũ trùm).
Future<ChibiSpec?> autoChibiSpec(Object source, {ChibiOutfit outfit = ChibiOutfit.khungLong}) {
  final key = (source, outfit);
  if (!_cache.containsKey(key) && _cache.length > 40) {
    _cache.remove(_cache.keys.first);
  }
  return _cache.putIfAbsent(key, () async {
    try {
      final Uint8List bytes;
      if (source is Uint8List) {
        bytes = source;
      } else {
        bytes = (await rootBundle.load(source as String)).buffer.asUint8List();
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
      final img = (await codec.getNextFrame()).image;

      // Màu chủ đạo: trung bình các điểm có hình
      final data = await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      var r = 0, g = 0, b = 0, n = 0;
      if (data != null) {
        for (var i = 0; i < data.lengthInBytes; i += 16) {
          if (data.getUint8(i + 3) < 128) continue;
          r += data.getUint8(i);
          g += data.getUint8(i + 1);
          b += data.getUint8(i + 2);
          n++;
        }
      }
      final main = n == 0
          ? const Color(0xFF8D6E63)
          : Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);

      // Khuôn mặt = cả ảnh đặt giữa hình tròn, nền màu chủ đạo
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawCircle(const Offset(128, 128), 128, Paint()..color = main);
      final w = img.width.toDouble(), h = img.height.toDouble();
      final k = 200 / (w > h ? w : h);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, w, h),
        Rect.fromCenter(center: const Offset(128, 132), width: w * k, height: h * k),
        Paint()..filterQuality = FilterQuality.medium,
      );
      img.dispose();
      final faceImg = await rec.endRecording().toImage(256, 256);
      final png = await faceImg.toByteData(format: ui.ImageByteFormat.png);
      faceImg.dispose();

      return ChibiSpec(
        face: png!.buffer.asUint8List(),
        outfit: outfit,
        // siêu anh hùng: bộ đồ xanh kinh điển (áo choàng, bốt đỏ)
        outfitColor: outfit == ChibiOutfit.heroNam || outfit == ChibiOutfit.heroNu
            ? const Color(0xFF1E5BD8)
            : main,
        skin: Color.lerp(main, Colors.white, 0.35)!,
        hair: main,
      );
    } catch (_) {
      return null;
    }
  });
}

/// Hiển thị "thú Chibi" từ một ảnh; trong lúc dựng thì hiện [fallback].
class AutoChibiView extends StatefulWidget {
  final Object source;
  final double size;
  final double yaw;
  final bool hiDetail;
  final BodyType body;
  final Widget fallback;
  final ChibiOutfit outfit;
  final double headScale;

  const AutoChibiView({
    super.key,
    required this.source,
    required this.size,
    required this.fallback,
    required this.body,
    this.yaw = 0,
    this.hiDetail = false,
    this.outfit = ChibiOutfit.khungLong,
    this.headScale = 1.0,
  });

  @override
  State<AutoChibiView> createState() => _AutoChibiViewState();
}

class _AutoChibiViewState extends State<AutoChibiView> {
  ChibiSpec? _spec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AutoChibiView old) {
    super.didUpdateWidget(old);
    if (!identical(old.source, widget.source) || old.outfit != widget.outfit) _load();
  }

  void _load() {
    final src = widget.source;
    final outfit = widget.outfit;
    autoChibiSpec(src, outfit: outfit).then((s) {
      if (mounted && identical(src, widget.source) && outfit == widget.outfit) {
        setState(() => _spec = s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec;
    if (s == null) return widget.fallback;
    return Chibi3DView(
      spec: s,
      size: widget.size,
      yaw: widget.yaw,
      hiDetail: widget.hiDetail,
      body: widget.body,
      headScale: widget.headScale,
    );
  }
}

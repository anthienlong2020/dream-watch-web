import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// =====================================================================
// Hệ (nguyên tố): đổi chất liệu + hiệu ứng động bao quanh hình,
// kiểu game "người lửa, người nước...". Kết hợp được với mọi kiểu hiển thị.
// Hiệu ứng tính theo thời gian thực (không lưu trạng thái) nên nhẹ và ổn định.
// =====================================================================

enum ElementType { none, lua, nuoc, dien }

const Map<ElementType, String> kElementNames = {
  ElementType.none: 'Không',
  ElementType.lua: '🔥 Lửa',
  ElementType.nuoc: '💧 Nước',
  ElementType.dien: '⚡ Điện',
};

ElementType elementFromName(String? s) =>
    ElementType.values.firstWhere((e) => e.name == s, orElse: () => ElementType.none);

// ---------------------------------------------------------------------
// Đường viền của hình (để lửa bốc ra đúng mép, sét loé quanh người)
// ---------------------------------------------------------------------

/// Điểm viền mặc định: hình elip (dùng cho emoji, Chibi, người que...).
final List<Offset> kEllipseEdge = [
  for (var i = 0; i < 28; i++)
    Offset(0.36 * math.sin(i / 28 * 2 * math.pi), -0.4 * math.cos(i / 28 * 2 * math.pi)),
];

final Map<Object, Future<List<Offset>>> _edgeCache = {};

/// Các điểm trên viền hình, toạ độ chuẩn hoá trong khung vuông (-0.5..0.5),
/// đúng như ảnh được vẽ kiểu "vừa khung" (contain).
Future<List<Offset>> edgePointsOf(Object source) {
  if (!_edgeCache.containsKey(source) && _edgeCache.length > 60) {
    _edgeCache.remove(_edgeCache.keys.first);
  }
  return _edgeCache.putIfAbsent(source, () async {
    try {
      final Uint8List bytes = source is Uint8List
          ? source
          : (await rootBundle.load(source as String)).buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 48);
      final img = (await codec.getNextFrame()).image;
      final w = img.width, h = img.height;
      final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      img.dispose();
      bool solid(int x, int y) =>
          x >= 0 && y >= 0 && x < w && y < h && data.getUint8((y * w + x) * 4 + 3) > 100;
      final m = math.max(w, h).toDouble();
      final pts = <Offset>[];
      var anyHole = false;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (!solid(x, y)) {
            anyHole = true;
            continue;
          }
          if (!solid(x - 1, y) || !solid(x + 1, y) || !solid(x, y - 1) || !solid(x, y + 1)) {
            pts.add(Offset((x + 0.5 - w / 2) / m, (y + 0.5 - h / 2) / m));
          }
        }
      }
      if (!anyHole || pts.length < 6) return kEllipseEdge;
      // Lấy thưa bớt cho nhẹ
      final step = math.max(1, pts.length ~/ 60);
      return [for (var i = 0; i < pts.length; i += step) pts[i]];
    } catch (_) {
      return kEllipseEdge;
    }
  });
}

// ---------------------------------------------------------------------
// Số ngẫu nhiên "cố định" theo hạt giống (cùng thời điểm luôn ra cùng hình)
// ---------------------------------------------------------------------

double _rnd(int a, int b, [int c = 0]) {
  var x = a * 374761393 + b * 668265263 + c * 2147483647;
  x = (x ^ (x >> 13)) * 1274126177;
  x = x ^ (x >> 16);
  return (x & 0xFFFFFF) / 0xFFFFFF;
}

// ---------------------------------------------------------------------
// Chất liệu: phủ màu lên chính hình
// ---------------------------------------------------------------------

ColorFilter? materialFilter(ElementType e) {
  switch (e) {
    case ElementType.lua:
      return const ColorFilter.matrix(<double>[
        0.40, 0.75, 0.15, 0, 45, //
        0.16, 0.38, 0.06, 0, 8, //
        0.03, 0.06, 0.01, 0, 0, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.nuoc:
      return const ColorFilter.matrix(<double>[
        0.10, 0.15, 0.05, 0, 10, //
        0.18, 0.38, 0.08, 0, 70, //
        0.20, 0.40, 0.15, 0, 140, //
        0, 0, 0, 0.82, 0, //
      ]);
    case ElementType.dien:
      return const ColorFilter.matrix(<double>[
        0.28, 0.12, 0.02, 0, 0, //
        0.15, 0.55, 0.10, 0, 30, //
        0.15, 0.30, 0.60, 0, 95, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.none:
      return null;
  }
}

// ---------------------------------------------------------------------
// Widget bọc ngoài hình
// ---------------------------------------------------------------------

class ElementLayer extends StatefulWidget {
  final ElementType element;
  final double size;
  final Widget child;

  /// Ảnh gốc (Uint8List / đường dẫn asset) để lấy viền; null = dùng elip.
  final Object? edgeSource;

  /// Hiệu ứng đầy đủ (hình giờ, hình giữa) hay nhẹ (các hình quanh vòng).
  final bool full;

  /// Thời điểm (giây) – truyền từ đồng hồ để mọi hình chạy cùng nhịp.
  final double time;

  /// Hạt giống riêng cho mỗi vị trí để các hình không giống hệt nhau.
  final int seed;

  const ElementLayer({
    super.key,
    required this.element,
    required this.size,
    required this.child,
    required this.time,
    this.edgeSource,
    this.full = false,
    this.seed = 0,
  });

  @override
  State<ElementLayer> createState() => _ElementLayerState();
}

class _ElementLayerState extends State<ElementLayer> {
  List<Offset> _edges = kEllipseEdge;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ElementLayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.edgeSource, widget.edgeSource)) _load();
  }

  void _load() {
    final src = widget.edgeSource;
    if (src == null) {
      _edges = kEllipseEdge;
      return;
    }
    edgePointsOf(src).then((e) {
      if (mounted && identical(src, widget.edgeSource)) setState(() => _edges = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    if (e == ElementType.none) return widget.child;
    final filter = materialFilter(e);
    final args = _FxArgs(e, widget.time, _edges, widget.full, widget.seed);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackPainter(args))),
          Positioned.fill(
            child: filter == null ? widget.child : ColorFiltered(colorFilter: filter, child: widget.child),
          ),
          Positioned.fill(child: CustomPaint(painter: _FrontPainter(args))),
        ],
      ),
    );
  }
}

class _FxArgs {
  final ElementType e;
  final double t;
  final List<Offset> edges;
  final bool full;
  final int seed;
  const _FxArgs(this.e, this.t, this.edges, this.full, this.seed);
}

// ---------------------------------------------------------------------
// Lớp phía sau: quầng sáng
// ---------------------------------------------------------------------

class _BackPainter extends CustomPainter {
  final _FxArgs a;
  _BackPainter(this.a);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final pulse = 0.5 + 0.5 * math.sin(a.t * 3 + a.seed);
    final Color glow;
    switch (a.e) {
      case ElementType.lua:
        glow = Color.fromARGB((70 + 50 * pulse).round(), 255, 120, 20);
        break;
      case ElementType.nuoc:
        glow = Color.fromARGB((50 + 30 * pulse).round(), 60, 160, 255);
        break;
      case ElementType.dien:
        glow = Color.fromARGB((60 + 70 * pulse).round(), 90, 220, 255);
        break;
      case ElementType.none:
        return;
    }
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 0.85, height: s * 0.95),
      Paint()
        ..color = glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _BackPainter o) => true;
}

// ---------------------------------------------------------------------
// Lớp phía trước: lửa, bong bóng, tia sét
// ---------------------------------------------------------------------

class _FrontPainter extends CustomPainter {
  final _FxArgs a;
  _FrontPainter(this.a);

  @override
  void paint(Canvas canvas, Size size) {
    switch (a.e) {
      case ElementType.lua:
        _fire(canvas, size.width);
        break;
      case ElementType.nuoc:
        _water(canvas, size.width);
        break;
      case ElementType.dien:
        _electric(canvas, size.width);
        break;
      case ElementType.none:
        break;
    }
  }

  Offset _edge(int k, int cyc, Offset c, double s) {
    final e = a.edges[(_rnd(k, cyc, a.seed) * a.edges.length).floor() % a.edges.length];
    return c + e * s;
  }

  void _fire(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final n = a.full ? 52 : 18;
    const life = 1.2;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var k = 0; k < n; k++) {
      final x = a.t / life + k / n;
      final cyc = x.floor();
      final ph = x - cyc;
      final r2 = _rnd(k, cyc, 7);
      final start = _edge(k, cyc, c, s);
      final rise = ph * s * 0.42 * (0.6 + 0.7 * r2);
      final wob = math.sin(ph * 7 + k) * s * 0.035 * ph;
      final p = start + Offset(wob, -rise);
      final rad = s * 0.095 * (1 - ph * 0.85) * (0.5 + 0.8 * _rnd(k, cyc, 3)) + 0.5;
      final col = ph < 0.35
          ? Color.lerp(const Color(0xFFFFF59D), const Color(0xFFFFA726), ph / 0.35)!
          : Color.lerp(const Color(0xFFFFA726), const Color(0xFFD84315), (ph - 0.35) / 0.65)!;
      paint
        ..color = col.withAlpha(((1 - ph) * 210).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.55);
      canvas.drawCircle(p, rad, paint);
    }
  }

  void _water(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    // Bong bóng nổi lên từ trong thân
    final nb = a.full ? 12 : 4;
    const life = 2.4;
    for (var k = 0; k < nb; k++) {
      final x = a.t / life + k / nb;
      final cyc = x.floor();
      final ph = x - cyc;
      final e = a.edges[(_rnd(k, cyc, a.seed) * a.edges.length).floor() % a.edges.length];
      final inward = 0.2 + 0.6 * _rnd(k, cyc, 5);
      final start = c + e * (s * inward);
      final p = start + Offset(math.sin(ph * 6 + k) * s * 0.02, -ph * s * 0.28);
      final rad = s * (0.018 + 0.022 * _rnd(k, cyc, 9));
      final alpha = (math.sin(ph * math.pi) * 220).round();
      canvas.drawCircle(
          p,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, s * 0.006)
            ..color = Colors.white.withAlpha(alpha));
      canvas.drawCircle(p + Offset(-rad * 0.35, -rad * 0.35), rad * 0.25,
          Paint()..color = Colors.white.withAlpha(alpha));
    }
    // Giọt nước nhỏ xuống từ phần dưới
    final bottom = a.edges.where((e) => e.dy > 0.1).toList();
    if (bottom.isEmpty) return;
    final nd = a.full ? 6 : 2;
    const dlife = 1.6;
    for (var k = 0; k < nd; k++) {
      final x = a.t / dlife + k / nd;
      final cyc = x.floor();
      final ph = x - cyc;
      final e = bottom[(_rnd(k, cyc, a.seed + 11) * bottom.length).floor() % bottom.length];
      final p = c + e * s + Offset(0, ph * ph * s * 0.22);
      final rad = s * 0.022 * (1 - ph * 0.5);
      final path = Path()
        ..moveTo(p.dx, p.dy - rad * 1.8)
        ..quadraticBezierTo(p.dx + rad, p.dy - rad * 0.2, p.dx, p.dy + rad)
        ..quadraticBezierTo(p.dx - rad, p.dy - rad * 0.2, p.dx, p.dy - rad * 1.8);
      canvas.drawPath(path, Paint()..color = const Color(0xFF81D4FA).withAlpha(((1 - ph) * 230).round()));
    }
    // Ánh sáng lăn tăn trên mặt nước (vài vệt trắng mảnh chạy ngang)
    final ns = a.full ? 5 : 2;
    for (var k = 0; k < ns; k++) {
      final y = ((a.t * 0.25 + k / ns) % 1.0 - 0.5) * s * 0.7;
      final w = s * (0.12 + 0.1 * _rnd(k, 1, a.seed));
      final x0 = (_rnd(k, 2, a.seed) - 0.5) * s * 0.3;
      canvas.drawLine(
          c + Offset(x0 - w / 2, y),
          c + Offset(x0 + w / 2, y + math.sin(a.t * 2 + k) * s * 0.01),
          Paint()
            ..color = Colors.white.withAlpha(90)
            ..strokeWidth = math.max(1, s * 0.008)
            ..strokeCap = StrokeCap.round);
    }
  }

  void _electric(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final nb = a.full ? 4 : 2;
    const period = 0.32;
    for (var k = 0; k < nb; k++) {
      final x = a.t / period + k * 0.37;
      final cyc = x.floor();
      final ph = x - cyc;
      if (ph > 0.5) continue; // tia sét chỉ loé trong chốc lát
      final from = _edge(k * 2, cyc, c, s);
      // Đầu kia: điểm viền khác hoặc phóng ra ngoài
      final toEdge = _rnd(k, cyc, 21) < 0.6;
      final Offset to = toEdge
          ? _edge(k * 2 + 1, cyc, c, s)
          : from + (from - c) * (0.35 + 0.4 * _rnd(k, cyc, 22));
      final path = Path()..moveTo(from.dx, from.dy);
      const segs = 7;
      final dir = to - from;
      final perp = Offset(-dir.dy, dir.dx) / (dir.distance + 0.001);
      for (var i = 1; i < segs; i++) {
        final f = i / segs;
        final j = (_rnd(k, cyc * 31 + i, 13) - 0.5) * s * 0.09;
        final p = from + dir * f + perp * j;
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(to.dx, to.dy);
      final fade = 1 - ph / 0.5;
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.03
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF4DD0E1).withAlpha((fade * 200).round())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, s * 0.009)
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withAlpha((fade * 255).round()));
    }
    // Tia lửa điện li ti nhấp nháy quanh viền
    final ns = a.full ? 14 : 5;
    for (var k = 0; k < ns; k++) {
      final cyc = (a.t * 8 + k * 0.53).floor();
      if (_rnd(k, cyc, 41) > 0.55) continue;
      final p = _edge(k + 100, cyc, c, s);
      canvas.drawCircle(
          p,
          s * 0.012,
          Paint()
            ..color = const Color(0xFFB2EBF2)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.008));
    }
  }

  @override
  bool shouldRepaint(covariant _FrontPainter o) => true;
}

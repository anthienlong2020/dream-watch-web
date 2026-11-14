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

enum ElementType { none, lua, nuoc, dien, may, sap, dat, bongBong, moc, kim, phaLe, haoQuangNgan, haoQuangDai }

const Map<ElementType, String> kElementNames = {
  ElementType.none: 'Không',
  ElementType.lua: '🔥 Lửa',
  ElementType.nuoc: '💧 Nước',
  ElementType.dien: '⚡ Điện',
  ElementType.may: '☁️ Mây',
  ElementType.sap: '🕯️ Sáp',
  ElementType.dat: '🪨 Đất',
  ElementType.bongBong: '🫧 Bong bóng',
  ElementType.moc: '🌿 Mộc (cây)',
  ElementType.kim: '🛡️ Kim (vàng kim)',
  ElementType.phaLe: '💎 Tượng pha lê',
  ElementType.haoQuangNgan: '✨ Hào quang – tóc dựng',
  ElementType.haoQuangDai: '✨ Hào quang – tóc dài',
};

/// Hệ nào dùng thêm lựa chọn màu.
bool elementHasColor(ElementType e) =>
    e == ElementType.phaLe || e == ElementType.haoQuangNgan || e == ElementType.haoQuangDai;

/// Màu cho hệ Pha lê / Hào quang.
enum ElemColor { tuDong, trongSuot, cauVong, vang, cam, ngocBich, lucBao, bacHa, lam, tim, hong, doo, bachKim }

const Map<ElemColor, String> kElemColorNames = {
  ElemColor.tuDong: 'Màu tự động',
  ElemColor.trongSuot: 'Trong suốt',
  ElemColor.cauVong: '🌈 Cầu vồng',
  ElemColor.vang: 'Vàng',
  ElemColor.cam: 'Cam',
  ElemColor.ngocBich: 'Ngọc bích (xanh lá)',
  ElemColor.lucBao: 'Lục bảo (xanh lục)',
  ElemColor.bacHa: 'Bạc hà',
  ElemColor.lam: 'Lam',
  ElemColor.tim: 'Tím',
  ElemColor.hong: 'Hồng',
  ElemColor.doo: 'Đỏ',
  ElemColor.bachKim: 'Bạch kim',
};

ElemColor elemColorFromName(String? s) =>
    ElemColor.values.firstWhere((e) => e.name == s, orElse: () => ElemColor.tuDong);

const List<Color> _rainbow = [
  Color(0xFFFF5252), Color(0xFFFFAB40), Color(0xFFFFEB3B), Color(0xFF69F0AE),
  Color(0xFF40C4FF), Color(0xFF7C4DFF), Color(0xFFFF4081),
];

/// Màu thực tế của hệ (cầu vồng: đổi màu theo thời gian).
Color elemColorValue(ElementType e, ElemColor c, double t) {
  var cc = c;
  if (cc == ElemColor.tuDong) {
    cc = e == ElementType.phaLe ? ElemColor.trongSuot : ElemColor.vang;
  }
  switch (cc) {
    case ElemColor.trongSuot:
      return const Color(0xFFE3F2FD);
    case ElemColor.cauVong:
      final x = (t * 0.25) % 1.0 * _rainbow.length;
      final i = x.floor();
      return Color.lerp(_rainbow[i % _rainbow.length], _rainbow[(i + 1) % _rainbow.length], x - i)!;
    case ElemColor.vang:
      return const Color(0xFFFFD54F);
    case ElemColor.cam:
      return const Color(0xFFFF9F43);
    case ElemColor.bacHa:
      return const Color(0xFFA8F0D8);
    case ElemColor.ngocBich:
      return const Color(0xFF66D19E);
    case ElemColor.lucBao:
      return const Color(0xFF00A383);
    case ElemColor.lam:
      return const Color(0xFF42A5F5);
    case ElemColor.tim:
      return const Color(0xFFB062D9);
    case ElemColor.hong:
      return const Color(0xFFF48FB1);
    case ElemColor.doo:
      return const Color(0xFFE53935);
    case ElemColor.bachKim:
      return const Color(0xFFE8ECEF);
    case ElemColor.tuDong:
      return const Color(0xFFFFD54F);
  }
}

ElementType elementFromName(String? s) => s == 'khoi'
    ? ElementType.may // hệ Gió/Khói cũ đã gộp vào Mây
    : ElementType.values.firstWhere((e) => e.name == s, orElse: () => ElementType.none);

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

/// Một lọn tóc nhọn từ [base] tới [tip], bề ngang gốc [w], màu [col] phát sáng.
void _spike(Canvas canvas, Offset base, Offset tip, double w, Color col, double s) {
  final d = tip - base;
  final perp = Offset(-d.dy, d.dx) / (d.distance + 0.001);
  final l = base + perp * (w / 2), r = base - perp * (w / 2);
  final mid = base + d * 0.55;
  final path = Path()
    ..moveTo(l.dx, l.dy)
    ..quadraticBezierTo(mid.dx + perp.dx * w * 0.25, mid.dy + perp.dy * w * 0.25, tip.dx, tip.dy)
    ..quadraticBezierTo(mid.dx - perp.dx * w * 0.1, mid.dy - perp.dy * w * 0.1, r.dx, r.dy)
    ..close();
  canvas.drawPath(
      path,
      Paint()
        ..color = col.withAlpha(140)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
  canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(col, Colors.black, 0.15)!, Color.lerp(col, Colors.white, 0.55)!],
        ).createShader(Rect.fromPoints(base, tip)));
  canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, s * 0.004)
        ..color = Color.lerp(col, Colors.black, 0.45)!.withAlpha(160));
}

/// Vị trí đầu ước lượng từ viền hình: đỉnh cao nhất + bề ngang phần trên.
class _HairGeo {
  final Offset headC; // toạ độ chuẩn hoá (-0.5..0.5)
  final double headR;
  const _HairGeo(this.headC, this.headR);

  static _HairGeo of(List<Offset> edges) {
    var minY = 1.0, maxY = -1.0;
    for (final e in edges) {
      if (e.dy < minY) minY = e.dy;
      if (e.dy > maxY) maxY = e.dy;
    }
    final band = (maxY - minY) * 0.3;
    var lo = 1.0, hi = -1.0;
    for (final e in edges) {
      if (e.dy < minY + band) {
        if (e.dx < lo) lo = e.dx;
        if (e.dx > hi) hi = e.dx;
      }
    }
    final r = ((hi - lo) / 2).clamp(0.08, 0.3);
    return _HairGeo(Offset((lo + hi) / 2, minY + r * 0.9), r);
  }
}

/// Khung bong bóng bao quanh hình, phập phồng nhẹ như bong bóng xà phòng.
Rect _bubbleRect(double t, double s, Offset c) {
  final w = math.sin(t * 2.2) * 0.03;
  return Rect.fromCenter(center: c, width: s * 1.0 * (1 + w), height: s * 1.0 * (1 - w));
}

// ---------------------------------------------------------------------
// Chất liệu: phủ màu lên chính hình
// ---------------------------------------------------------------------

ColorFilter? materialFilter(ElementType e, [Color tint = const Color(0xFFFFFFFF)]) {
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
    case ElementType.may:
      return const ColorFilter.matrix(<double>[
        0.30, 0.35, 0.08, 0, 125, //
        0.30, 0.35, 0.08, 0, 128, //
        0.30, 0.35, 0.08, 0, 140, //
        0, 0, 0, 0.92, 0, //
      ]);
    case ElementType.sap:
      return const ColorFilter.matrix(<double>[
        0.50, 0.28, 0.08, 0, 75, //
        0.42, 0.28, 0.08, 0, 62, //
        0.35, 0.22, 0.10, 0, 45, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.dat:
      return const ColorFilter.matrix(<double>[
        0.20, 0.38, 0.08, 0, 45, //
        0.15, 0.28, 0.06, 0, 28, //
        0.10, 0.18, 0.04, 0, 12, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.bongBong:
      // giữ màu gốc, sáng và mát hơn một chút như nhìn qua lớp bong bóng
      return const ColorFilter.matrix(<double>[
        0.85, 0, 0, 0, 22, //
        0, 0.85, 0, 0, 25, //
        0, 0, 0.88, 0, 40, //
        0, 0, 0, 0.96, 0, //
      ]);
    case ElementType.moc:
      // gỗ - lá: nâu ấm pha xanh rêu
      return const ColorFilter.matrix(<double>[
        0.15, 0.30, 0.05, 0, 18, //
        0.28, 0.55, 0.10, 0, 55, //
        0.06, 0.12, 0.02, 0, 10, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.kim:
      // vàng kim: độ sáng -> dải màu vàng
      return const ColorFilter.matrix(<double>[
        0.42, 0.75, 0.14, 0, 40, //
        0.32, 0.58, 0.10, 0, 22, //
        0.09, 0.18, 0.03, 0, 0, //
        0, 0, 0, 1, 0, //
      ]);
    case ElementType.phaLe:
      // tượng pha lê: giữ khối sáng tối của hình, nhuộm màu đá quý, hơi trong
      final r = tint.red / 255.0, g = tint.green / 255.0, b = tint.blue / 255.0;
      return ColorFilter.matrix(<double>[
        0.3 * 0.9 * r, 0.59 * 0.9 * r, 0.11 * 0.9 * r, 0, 60 * r + 20, //
        0.3 * 0.9 * g, 0.59 * 0.9 * g, 0.11 * 0.9 * g, 0, 60 * g + 20, //
        0.3 * 0.9 * b, 0.59 * 0.9 * b, 0.11 * 0.9 * b, 0, 60 * b + 20, //
        0, 0, 0, 0.8, 0, //
      ]);
    case ElementType.haoQuangNgan:
    case ElementType.haoQuangDai:
      // sáng rực lên, ánh màu hào quang
      final r = tint.red / 255.0, g = tint.green / 255.0, b = tint.blue / 255.0;
      return ColorFilter.matrix(<double>[
        0.9, 0, 0, 0, 40 * r + 10, //
        0, 0.9, 0, 0, 40 * g + 10, //
        0, 0, 0.9, 0, 40 * b + 10, //
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

  /// Màu (cho Pha lê / Hào quang).
  final ElemColor color;

  const ElementLayer({
    super.key,
    required this.element,
    required this.size,
    required this.child,
    required this.time,
    this.edgeSource,
    this.full = false,
    this.seed = 0,
    this.color = ElemColor.tuDong,
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
    final tint = elemColorValue(e, widget.color, widget.time);
    final filter = materialFilter(e, widget.color == ElemColor.cauVong ? const Color(0xFFF2F2F2) : tint);
    final args = _FxArgs(e, widget.time, _edges, widget.full, widget.seed, tint);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackPainter(args))),
          Positioned.fill(
            child: _material(filter, widget.child),
          ),
          Positioned.fill(child: CustomPaint(painter: _FrontPainter(args))),
        ],
      ),
    );
  }
}

extension on _ElementLayerState {
  /// Phủ chất liệu; riêng Mây/Khói làm mềm viền một chút cho "bông".
  Widget _material(ColorFilter? filter, Widget child) {
    Widget w = filter == null ? child : ColorFiltered(colorFilter: filter, child: child);
    if (widget.element == ElementType.may) {
      final sigma = widget.size * 0.01;
      w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
    }
    if (widget.element == ElementType.phaLe) {
      // Mặt cắt pha lê: các tia sáng tối xen kẽ xoay chậm, chỉ hiện trên hình
      final rot = widget.time * 0.25 + widget.seed;
      w = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => SweepGradient(
          transform: GradientRotation(rot),
          colors: const [
            Color(0x30FFFFFF), Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x10000000),
            Color(0x30FFFFFF), Color(0x00FFFFFF), Color(0x48FFFFFF), Color(0x14000000),
            Color(0x30FFFFFF),
          ],
        ).createShader(r),
        child: w,
      );
      if (widget.color == ElemColor.cauVong) {
        // pha lê cầu vồng: dải màu cầu vồng trôi qua thân
        final shift = widget.time * 0.2;
        w = ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            tileMode: TileMode.repeated,
            transform: GradientRotation(shift),
            colors: [for (final c in _rainbow) c.withAlpha(110), _rainbow.first.withAlpha(110)],
          ).createShader(Rect.fromLTWH(r.left, r.top, r.width * 0.8, r.height * 0.8)),
          child: w,
        );
      }
    }
    if (widget.element == ElementType.kim || widget.element == ElementType.phaLe) {
      // Vệt sáng loá chạy chéo qua thân, chỉ hiện trên chính hình (như áo giáp vàng)
      final p = (widget.time * 0.35 + widget.seed * 0.13) % 1.8 - 0.4;
      w = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0x00FFFFFF), Color(0xCCFFF8E1), Color(0x00FFFFFF)],
          stops: [(p - 0.12).clamp(0.0, 1.0), p.clamp(0.0, 1.0), (p + 0.12).clamp(0.0, 1.0)],
        ).createShader(r),
        child: w,
      );
    }
    return w;
  }
}

class _FxArgs {
  final ElementType e;
  final double t;
  final List<Offset> edges;
  final bool full;
  final int seed;
  final Color tint;
  const _FxArgs(this.e, this.t, this.edges, this.full, this.seed, this.tint);
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
      case ElementType.may:
        glow = Color.fromARGB((60 + 25 * pulse).round(), 255, 255, 255);
        break;
      case ElementType.sap:
        glow = Color.fromARGB((40 + 25 * pulse).round(), 255, 200, 120);
        break;
      case ElementType.dat:
        glow = Color.fromARGB(70, 60, 35, 15);
        break;
      case ElementType.moc:
        glow = Color.fromARGB((45 + 25 * pulse).round(), 120, 200, 90);
        break;
      case ElementType.kim:
        glow = Color.fromARGB((60 + 50 * pulse).round(), 255, 200, 60);
        break;
      case ElementType.bongBong:
        _bubbleBack(canvas, s, c);
        return;
      case ElementType.phaLe:
        glow = a.tint.withAlpha((50 + 40 * pulse).round());
        break;
      case ElementType.haoQuangNgan:
      case ElementType.haoQuangDai:
        _auraBack(canvas, s, c);
        return;
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

  /// Hào quang: quầng sáng + lưỡi năng lượng bốc lên bao quanh người,
  /// và (kiểu tóc dài) mái tóc dài phía sau lưng.
  void _auraBack(Canvas canvas, double s, Offset c) {
    final col = a.tint;
    final flick = 0.85 + 0.15 * math.sin(a.t * 9 + a.seed);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -s * 0.05), width: s * 1.0 * flick, height: s * 1.25 * flick),
      Paint()
        ..color = col.withAlpha(90)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12),
    );
    final n = a.full ? 26 : 10;
    for (var k = 0; k < n; k++) {
      final e = a.edges[(k * a.edges.length ~/ n) % a.edges.length];
      final base = c + e * s * 1.08;
      final ph = (a.t * 2.2 + _rnd(k, 3, a.seed)) % 1.0;
      final h = s * (0.16 + 0.14 * _rnd(k, 4, a.seed)) * (0.7 + 0.5 * math.sin(ph * math.pi));
      final lean = e.dx * 0.6;
      final tip = base + Offset(lean * h, -h);
      final w = s * 0.05;
      final path = Path()
        ..moveTo(base.dx - w, base.dy)
        ..quadraticBezierTo(base.dx - w * 0.3, base.dy - h * 0.55, tip.dx, tip.dy)
        ..quadraticBezierTo(base.dx + w * 0.3, base.dy - h * 0.55, base.dx + w, base.dy)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(col, Colors.white, 0.35)!.withAlpha(150)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.015));
    }
    if (a.e == ElementType.haoQuangDai) {
      final hg = _HairGeo.of(a.edges);
      final hc = c + hg.headC * s;
      final r = hg.headR * s;
      // mái tóc dài: những lọn to rủ xuống sau lưng tới tận chân
      for (var k = 0; k < 11; k++) {
        final f = k / 10; // 0 = bên phải, 1 = bên trái
        final side = 1 - 2 * f;
        final base = hc + Offset(side * r * 1.05, -r * 0.2 + (1 - side.abs()) * r * 0.1);
        final sway = math.sin(a.t * 1.5 + k) * s * 0.025;
        final tip = Offset(c.dx + side * s * (0.46 + 0.06 * _rnd(k, 8, a.seed)) + sway,
            c.dy + s * (0.5 + 0.1 * _rnd(k, 9, a.seed)));
        _spike(canvas, base, tip, s * 0.16, col, s);
      }
    }
  }

  /// Thân bong bóng phía sau hình: tím xanh trong suốt như ảnh mẫu.
  void _bubbleBack(Canvas canvas, double s, Offset c) {
    final rect = _bubbleRect(a.t, s, c);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [Color(0x55FFFFFF), Color(0x55B3B0FF), Color(0x707C83FF), Color(0x6080D8FF)],
          stops: [0.0, 0.35, 0.75, 1.0],
        ).createShader(rect),
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
      case ElementType.may:
        _cloud(canvas, size.width);
        break;
      case ElementType.sap:
        _wax(canvas, size.width);
        break;
      case ElementType.dat:
        _earth(canvas, size.width);
        break;
      case ElementType.bongBong:
        _bubble(canvas, size.width);
        break;
      case ElementType.moc:
        _wood(canvas, size.width);
        break;
      case ElementType.kim:
        _metal(canvas, size.width);
        break;
      case ElementType.phaLe:
        _metal(canvas, size.width); // lấp lánh như đá quý
        break;
      case ElementType.haoQuangNgan:
      case ElementType.haoQuangDai:
        _hairFront(canvas, size.width);
        break;
      case ElementType.none:
        break;
    }
  }

  /// Bong bóng: viền tím xanh, đốm sáng trắng góc trên-trái, đốm xanh nhạt
  /// góc dưới-phải (giống ảnh mẫu), thêm bong bóng nhỏ bay lên.
  void _bubble(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final rect = _bubbleRect(a.t, s, c);
    // viền đậm dần ra mép
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x707268FF), Color(0xB05A6CFF)],
          stops: [0.0, 0.72, 0.93, 1.0],
        ).createShader(rect),
    );
    // đốm sáng trắng trên-trái
    canvas.save();
    final hl = rect.topLeft + Offset(rect.width * 0.3, rect.height * 0.2);
    canvas.translate(hl.dx, hl.dy);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rect.width * 0.26, height: rect.height * 0.13),
      Paint()
        ..color = const Color(0xE6FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025),
    );
    canvas.restore();
    // đốm xanh nhạt dưới-phải
    canvas.save();
    final hl2 = rect.topLeft + Offset(rect.width * 0.76, rect.height * 0.82);
    canvas.translate(hl2.dx, hl2.dy);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rect.width * 0.22, height: rect.height * 0.1),
      Paint()
        ..color = const Color(0xAAE0FFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    canvas.restore();
    // bong bóng nhỏ bay lên quanh
    final n = a.full ? 6 : 2;
    const life = 3.5;
    for (var k = 0; k < n; k++) {
      final x = a.t / life + k / n;
      final cyc = x.floor();
      final ph = x - cyc;
      final side = _rnd(k, cyc, a.seed) < 0.5 ? -1.0 : 1.0;
      final p = c +
          Offset(side * s * (0.42 + 0.08 * _rnd(k, cyc, 2)) + math.sin(ph * 6 + k) * s * 0.02,
              s * 0.4 - ph * s * 0.9);
      final r = s * (0.025 + 0.025 * _rnd(k, cyc, 3));
      final al = math.sin(ph * math.pi);
      final br = Rect.fromCircle(center: p, radius: r);
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [
                Color.fromARGB((90 * al).round(), 255, 255, 255),
                Color.fromARGB((110 * al).round(), 140, 150, 255),
              ],
            ).createShader(br));
      canvas.drawCircle(p + Offset(-r * 0.35, -r * 0.35), r * 0.22,
          Paint()..color = Colors.white.withAlpha((220 * al).round()));
    }
  }

  /// Mộc: lá non mọc quanh viền đung đưa, lá rơi lả tả.
  void _wood(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    const greens = [Color(0xFF66BB6A), Color(0xFF9CCC65), Color(0xFF43A047), Color(0xFFC0CA33)];
    void leaf(Offset p, double len, double angle, Color col, int alpha) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle);
      final w = len * 0.42;
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w, -len * 0.5, 0, -len)
        ..quadraticBezierTo(-w, -len * 0.5, 0, 0);
      canvas.drawPath(path, Paint()..color = col.withAlpha(alpha));
      canvas.drawLine(Offset.zero, Offset(0, -len * 0.85),
          Paint()
            ..color = const Color(0x5533691E)
            ..strokeWidth = math.max(0.6, len * 0.05));
      canvas.restore();
    }

    // lá mọc trên viền (cố định chỗ, đung đưa theo gió)
    final top = a.edges.where((e) => e.dy < 0.15).toList();
    final src = top.isEmpty ? a.edges : top;
    final ng = a.full ? 13 : 5;
    for (var k = 0; k < ng; k++) {
      final e = src[(_rnd(k, 5, a.seed) * src.length).floor() % src.length];
      final p = c + e * s;
      final out = math.atan2(e.dy, e.dx) + math.pi / 2; // hướng ra ngoài
      final sway = math.sin(a.t * 1.6 + k * 1.3) * 0.25;
      leaf(p, s * (0.1 + 0.06 * _rnd(k, 6, a.seed)), out + sway, greens[k % greens.length], 240);
    }
    // lá rơi
    final nf = a.full ? 8 : 3;
    const life = 4.0;
    for (var k = 0; k < nf; k++) {
      final x = a.t / life + k / nf;
      final cyc = x.floor();
      final ph = x - cyc;
      final start = _edge(k + 50, cyc, c, s);
      final p = start + Offset(math.sin(ph * 5 + k) * s * 0.08, ph * s * 0.45);
      final ang = math.sin(ph * 4 + k) * 1.2 + k;
      leaf(p, s * 0.075, ang, greens[(k + 1) % greens.length], ((1 - ph) * 230).round());
    }
  }

  /// Tóc dựng nhọn trên đỉnh đầu (cả 2 kiểu), kèm tia điện nhỏ loé quanh.
  void _hairFront(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final col = a.tint;
    final hg = _HairGeo.of(a.edges);
    final hc = c + hg.headC * s;
    final r = hg.headR * s;
    final long = a.e == ElementType.haoQuangDai;
    final n = long ? 7 : 9;
    for (var k = 0; k < n; k++) {
      // xoè hình quạt phía trên đầu: từ trái (-160°) sang phải (-20°)
      final ang = -math.pi * (0.89 - 0.78 * k / (n - 1));
      final dir = Offset(math.cos(ang), math.sin(ang));
      final base = hc + dir * (r * 0.75);
      final len = r * (long ? 0.75 : 1.0) * (0.8 + 0.5 * _rnd(k, 1, a.seed)) *
          (1 + 0.04 * math.sin(a.t * 6 + k));
      final up = Offset(dir.dx * 0.8, dir.dy - 0.5);
      final tip = base + up / up.distance * len;
      _spike(canvas, base, tip, r * 0.38, col, s);
    }
    // tia điện nhỏ
    if (a.full) {
      final cyc = (a.t * 3).floor();
      if (_rnd(1, cyc, a.seed) < 0.6) {
        final from = _edge(3, cyc, c, s);
        final dirOut = (from - c) / ((from - c).distance + 0.001);
        final path = Path()..moveTo(from.dx, from.dy);
        var p = from;
        for (var i = 0; i < 5; i++) {
          p = p + dirOut * s * 0.04 + Offset(-dirOut.dy, dirOut.dx) * ((_rnd(i, cyc, 5) - 0.5) * s * 0.06);
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1, s * 0.008)
              ..color = const Color(0xEEE1F5FE));
      }
    }
  }

  /// Kim: những ngôi sao lấp lánh trên viền giáp vàng.
  void _metal(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final n = a.full ? 8 : 3;
    for (var k = 0; k < n; k++) {
      final x = a.t * 0.9 + k * 0.37;
      final cyc = x.floor();
      final ph = x - cyc;
      final tw = math.sin(ph * math.pi);
      if (tw < 0.05) continue;
      final p = _edge(k + 200, cyc, c, s);
      final r = s * 0.05 * tw;
      final star = Path();
      for (var i = 0; i < 8; i++) {
        final ang = i * math.pi / 4;
        final rr = i.isEven ? r : r * 0.18;
        final q = p + Offset(math.cos(ang), math.sin(ang)) * rr;
        if (i == 0) {
          star.moveTo(q.dx, q.dy);
        } else {
          star.lineTo(q.dx, q.dy);
        }
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFF8E1).withAlpha((tw * 255).round()));
      canvas.drawCircle(
          p,
          r * 0.5,
          Paint()
            ..color = const Color(0xFFFFE082).withAlpha((tw * 160).round())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));
    }
  }

  /// Mây: các cụm mây bông trôi ngang quanh thân.
  void _cloud(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final n = a.full ? 7 : 3;
    for (var k = 0; k < n; k++) {
      final speed = 0.05 + 0.04 * _rnd(k, 1, a.seed);
      final x = ((a.t * speed + _rnd(k, 2, a.seed)) % 1.0 - 0.5) * s * 1.3;
      final y = (_rnd(k, 3, a.seed) - 0.5) * s * 0.8 + math.sin(a.t * 0.7 + k) * s * 0.02;
      final r = s * (0.06 + 0.05 * _rnd(k, 4, a.seed));
      // mờ dần khi trôi ra xa thân
      final fade = (1 - (x.abs() / (s * 0.65))).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withAlpha((170 * fade).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35);
      final p = c + Offset(x, y);
      canvas.drawCircle(p, r, paint);
      canvas.drawCircle(p + Offset(-r * 0.9, r * 0.25), r * 0.7, paint);
      canvas.drawCircle(p + Offset(r * 0.9, r * 0.3), r * 0.65, paint);
    }
  }

  /// Sáp: bóng láng như nến, sáp chảy giọt ở chân, ngọn lửa nến nhỏ trên đỉnh.
  void _wax(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    // vệt bóng láng
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(-s * 0.12, -s * 0.15), width: s * 0.16, height: s * 0.28),
        Paint()
          ..color = Colors.white.withAlpha(70)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03));
    // giọt sáp chảy chậm từ phần dưới
    final bottom = a.edges.where((e) => e.dy > 0.05).toList();
    if (bottom.isNotEmpty) {
      final n = a.full ? 6 : 3;
      const life = 6.0;
      for (var k = 0; k < n; k++) {
        final x = a.t / life + k / n;
        final cyc = x.floor();
        final ph = x - cyc;
        final e = bottom[(_rnd(k, cyc, a.seed + 3) * bottom.length).floor() % bottom.length];
        final top = c + e * s;
        final len = s * 0.12 * Curves.easeOut.transform(ph);
        final w = s * 0.03;
        final rr = RRect.fromRectAndRadius(
            Rect.fromLTWH(top.dx - w / 2, top.dy - w, w, len + w), Radius.circular(w / 2));
        canvas.drawRRect(rr, Paint()..color = const Color(0xFFFFF3E0).withAlpha(((1 - ph) * 230).round()));
        canvas.drawCircle(Offset(top.dx, top.dy + len), w * 0.75,
            Paint()..color = const Color(0xFFFFF3E0).withAlpha(((1 - ph) * 230).round()));
      }
    }
    // ngọn lửa nến trên đỉnh đầu
    if (a.full) {
      var topPt = a.edges.first;
      for (final e in a.edges) {
        if (e.dy < topPt.dy) topPt = e;
      }
      final base = c + topPt * s;
      final flick = 1 + 0.12 * math.sin(a.t * 17) + 0.06 * math.sin(a.t * 29);
      final h = s * 0.12 * flick;
      final flame = Path()
        ..moveTo(base.dx, base.dy - h)
        ..quadraticBezierTo(base.dx + s * 0.04, base.dy - h * 0.35, base.dx, base.dy)
        ..quadraticBezierTo(base.dx - s * 0.04, base.dy - h * 0.35, base.dx, base.dy - h);
      canvas.drawPath(
          flame,
          Paint()
            ..color = const Color(0xFFFFB74D)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012));
      canvas.drawCircle(base + Offset(0, -h * 0.3), s * 0.012, Paint()..color = const Color(0xFFFFF9C4));
    }
  }

  /// Đất: vết nứt trên thân, bụi đất và sỏi nhỏ rơi lả tả.
  void _earth(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    // vết nứt cố định cho mỗi vị trí
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, s * 0.008)
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xAA2D1B0E);
    final nc = a.full ? 5 : 2;
    for (var k = 0; k < nc; k++) {
      final e = a.edges[(_rnd(k, 77, a.seed) * a.edges.length).floor() % a.edges.length];
      var p = c + e * s;
      final path = Path()..moveTo(p.dx, p.dy);
      final dir = (c - p) / ((c - p).distance + 0.001);
      for (var i = 0; i < 4; i++) {
        final jitter = Offset(-dir.dy, dir.dx) * ((_rnd(k, i, a.seed + 5) - 0.5) * s * 0.06);
        p = p + dir * (s * 0.05) + jitter;
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, crack);
    }
    // bụi đất rơi
    final n = a.full ? 18 : 6;
    const life = 1.8;
    for (var k = 0; k < n; k++) {
      final x = a.t / life + k / n;
      final cyc = x.floor();
      final ph = x - cyc;
      final start = _edge(k, cyc, c, s);
      final p = start + Offset((_rnd(k, cyc, 8) - 0.5) * s * 0.06, ph * ph * s * 0.3);
      final big = _rnd(k, cyc, 12) < 0.2; // vài viên sỏi to hơn
      final r = s * (big ? 0.018 : 0.008);
      canvas.drawCircle(
          p,
          r,
          Paint()..color = (big ? const Color(0xFF6D4C41) : const Color(0xFFA1887F))
              .withAlpha(((1 - ph) * 230).round()));
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

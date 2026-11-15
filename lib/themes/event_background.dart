import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ảnh nền riêng cho từng lễ hội: vẽ bằng code (bầu trời, trăng/mặt trời, đồi, phố, biển...)
/// nên hợp màu với hiệu ứng của lễ hội đó, không tốn dung lượng.
/// Muốn dùng ảnh thật thì chép ảnh vào assets/events/ đặt tên theo mã lễ hội,
/// vd: tet.jpg, giangSinh.png → app tự dùng ảnh đó thay cho cảnh vẽ.

enum Ground { none, hills, city, sea, pines }

/// Biểu tượng / cảnh đặc trưng của lễ hội.
enum Landmark { none, autumnTrees, fuji, taj, pyramid, hoiAn, thaiTemple, harvest, sugarloaf, stream }

class EventScene {
  final List<Color> sky; // trên → dưới
  final bool moon, sun, stars, bokeh;
  final Ground ground;
  final Color groundColor;
  final List<Color> bokehColors;
  final Landmark landmark;
  const EventScene({
    this.landmark = Landmark.none,
    required this.sky,
    this.moon = false,
    this.sun = false,
    this.stars = false,
    this.bokeh = false,
    this.ground = Ground.hills,
    this.groundColor = const Color(0xFF101418),
    this.bokehColors = const [Color(0xFFFFD54F)],
  });
}

const Map<String, EventScene> kEventScenes = {
  'tet': EventScene(
      sky: [Color(0xFF3A0808), Color(0xFF7A1414), Color(0xFFC0392B)],
      bokeh: true,
      bokehColors: [Color(0xFFFFD54F), Color(0xFFFF8A65)],
      ground: Ground.city,
      groundColor: Color(0xFF2A0606)),
  'xuan': EventScene(
      sky: [Color(0xFFB9DDF7), Color(0xFFF9DCEB), Color(0xFFFFF4DE)],
      sun: true,
      groundColor: Color(0xFF6FA860)),
  'ha': EventScene(
      sky: [Color(0xFF1F7FD6), Color(0xFF79C3FA), Color(0xFFFFE3A3)], sun: true, ground: Ground.sea,
      groundColor: Color(0xFF1C8FB0)),
  // mùa thu nhẹ nhàng: trời xanh nhạt pha kem, nắng vàng mật ong, hàng cây lá vàng cam
  'thu': EventScene(
      sky: [Color(0xFFC9DDE8), Color(0xFFF4E6CC), Color(0xFFF2CE96)], sun: true,
      groundColor: Color(0xFFB98A45), landmark: Landmark.autumnTrees),
  'dong': EventScene(
      sky: [Color(0xFF17304A), Color(0xFF4A78A0), Color(0xFFCBE3F2)], groundColor: Color(0xFFE6F2FA)),
  'giangSinh': EventScene(
      sky: [Color(0xFF050F26), Color(0xFF0E2A56), Color(0xFF1B4A75)], moon: true, stars: true,
      ground: Ground.pines, groundColor: Color(0xFF0B2A1C)),
  'valentine': EventScene(
      sky: [Color(0xFF34092A), Color(0xFF7E1C4A), Color(0xFFF07AA4)], bokeh: true,
      bokehColors: [Color(0xFFFF80AB), Color(0xFFFFFFFF)], ground: Ground.none),
  'carnival': EventScene(
      sky: [Color(0xFF02254A), Color(0xFF0A6A4C), Color(0xFFF0C010)], bokeh: true,
      bokehColors: [Color(0xFF00E676), Color(0xFFFFEA00), Color(0xFF2979FF)], ground: Ground.city,
      groundColor: Color(0xFF02180F), landmark: Landmark.sugarloaf),
  'phuNu': EventScene(
      sky: [Color(0xFFF5D2DE), Color(0xFFF0B0D0), Color(0xFFFFEEF4)], bokeh: true,
      bokehColors: [Color(0xFFFFFFFF), Color(0xFFFF80AB)], ground: Ground.none),
  'phucSinh': EventScene(
      sky: [Color(0xFFC6E3A8), Color(0xFFF0F7CE), Color(0xFFFFE2EA)], sun: true, groundColor: Color(0xFF7CB860)),
  'thieuNhi': EventScene(
      sky: [Color(0xFF6FCBFF), Color(0xFFBDEEFF), Color(0xFFFFF9DC)], sun: true, groundColor: Color(0xFF8BC34A)),
  'trungThu': EventScene(
      sky: [Color(0xFF090D2A), Color(0xFF182656), Color(0xFF363C78)], stars: true,
      groundColor: Color(0xFF070A1C)),
  'halloween': EventScene(
      sky: [Color(0xFF100015), Color(0xFF360A46), Color(0xFFE0651A)], moon: true, stars: true,
      ground: Ground.pines, groundColor: Color(0xFF07020A)),
  'nhaGiao': EventScene(
      sky: [Color(0xFFD8EEFF), Color(0xFFB8DCFF), Color(0xFFFFF6DC)], sun: true, groundColor: Color(0xFF81B26A)),
  'hanami': EventScene(
      sky: [Color(0xFFBFD9F2), Color(0xFFFFD6E2), Color(0xFFFFF3F7)], sun: true, groundColor: Color(0xFFB98AA0),
      landmark: Landmark.fuji, ground: Ground.none),
  'holi': EventScene(
      sky: [Color(0xFFFFDDF5), Color(0xFFDDEEFF), Color(0xFFFFF1D0)], bokeh: true,
      bokehColors: [Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFFFFEA00), Color(0xFFFF4081)],
      ground: Ground.none),
  'diwali': EventScene(
      sky: [Color(0xFF040318), Color(0xFF120A36), Color(0xFF3A1860)], stars: true, ground: Ground.none,
      groundColor: Color(0xFF05030F), landmark: Landmark.taj),
  'songkran': EventScene(
      // xanh biển đậm để bóng nước trong suốt & giọt nước nhạt nổi rõ
      sky: [Color(0xFF0A3D66), Color(0xFF125E8C), Color(0xFF1F7FAE)], sun: true, ground: Ground.sea,
      groundColor: Color(0xFF0A4C78), landmark: Landmark.thaiTemple),
  'hoiAn': EventScene(
      sky: [Color(0xFF0C091D), Color(0xFF2A1838), Color(0xFF5A2C18)], moon: true, stars: true,
      ground: Ground.none, groundColor: Color(0xFF0A0610), landmark: Landmark.hoiAn),
  'sinhNhat': EventScene(
      sky: [Color(0xFF27144C), Color(0xFF572884), Color(0xFFFF9AC8)], bokeh: true,
      bokehColors: [Color(0xFFFFD54F), Color(0xFFFF80AB), Color(0xFF80D8FF)], ground: Ground.none),
  'phatGiao': EventScene(
      sky: [Color(0xFF120C28), Color(0xFF2E2050), Color(0xFF5A4070)], moon: true, stars: true,
      ground: Ground.none, groundColor: Color(0xFF0E1428), landmark: Landmark.stream),
  'doanNgo': EventScene(
      sky: [Color(0xFFFFD69C), Color(0xFFFFB068), Color(0xFFFF8858)], sun: true, groundColor: Color(0xFF5E8C3A)),
  'thaDen': EventScene(
      sky: [Color(0xFF030518), Color(0xFF12183C), Color(0xFF36284C)], stars: true,
      ground: Ground.sea, groundColor: Color(0xFF070A1E)),
  'quocKhanh': EventScene(
      sky: [Color(0xFF360000), Color(0xFF860000), Color(0xFFD02B2B)], stars: true, bokeh: true,
      bokehColors: [Color(0xFFFFD600)], ground: Ground.city, groundColor: Color(0xFF200000)),
  'traiDat': EventScene(
      sky: [Color(0xFFA4E4CC), Color(0xFFD8EBBE), Color(0xFFFFD0B2)], sun: true, groundColor: Color(0xFF4E9A52)),
  'ngayCuaMe': EventScene(
      sky: [Color(0xFFFFE0EA), Color(0xFFFFC4DA), Color(0xFFFFEEF4)], bokeh: true,
      bokehColors: [Color(0xFFFFFFFF), Color(0xFFF06292)], ground: Ground.none),
  'tomatina': EventScene(
      sky: [Color(0xFFFFD3A0), Color(0xFFFF9880), Color(0xFFFF6868)], sun: true, ground: Ground.city,
      groundColor: Color(0xFF8A3A2A)),
  'taOn': EventScene(
      sky: [Color(0xFF46230F), Color(0xFF9C502A), Color(0xFFF0A25E)], sun: true, groundColor: Color(0xFF4A2A12),
      ground: Ground.none, landmark: Landmark.harvest),
  'diaDeMuertos': EventScene(
      sky: [Color(0xFF18092C), Color(0xFF461858), Color(0xFFFF8A40)], stars: true, groundColor: Color(0xFF0C0414),
      ground: Ground.none, landmark: Landmark.pyramid),
};

/// Ảnh thật trong assets/events/ (nếu có) theo mã lễ hội.
Map<String, String> _eventImages = const {};

Future<void> loadEventImages() async {
  try {
    final m = await AssetManifest.loadFromAssetBundle(rootBundle);
    final re = RegExp(r'^assets/events/([^/]+)\.(png|jpe?g|webp)$', caseSensitive: false);
    _eventImages = {
      for (final p in m.listAssets())
        if (re.firstMatch(Uri.decodeFull(p)) case final mm?) mm.group(1)!: p,
    };
  } catch (_) {}
}

bool hasEventBackground(String id) => _eventImages.containsKey(id) || kEventScenes.containsKey(id);

/// Ảnh nền của lễ hội [id] (ảnh thật nếu có, không thì cảnh vẽ).
class EventBackground extends StatelessWidget {
  final String id;
  const EventBackground({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final img = _eventImages[id];
    if (img != null) return Image.asset(img, fit: BoxFit.cover);
    final scene = kEventScenes[id];
    if (scene == null) return const SizedBox.shrink();
    return RepaintBoundary(child: CustomPaint(painter: _ScenePainter(scene), size: Size.infinite));
  }
}

/// Vẽ cảnh nền của lễ hội [id] lên [canvas] (dùng cho ảnh xem thử).
void paintEventScene(Canvas canvas, Size size, String id) {
  final s = kEventScenes[id];
  if (s != null) _ScenePainter(s).paint(canvas, size);
}

class _ScenePainter extends CustomPainter {
  final EventScene s;
  _ScenePainter(this.s);

  double _r(int a, int b) {
    var x = (a * 73856093) ^ (b * 19349663);
    x = (x ^ (x >> 13)) * 1274126177;
    return ((x ^ (x >> 16)) & 0xFFFF) / 0xFFFF;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: s.sky,
          ).createShader(rect));
    final u = math.min(w, h);

    if (s.stars) {
      final p = Paint()..color = Colors.white;
      for (var i = 0; i < 110; i++) {
        final x = _r(i, 1) * w, y = _r(i, 2) * h * 0.6;
        p.color = Colors.white.withAlpha((60 + 160 * _r(i, 3)).round());
        canvas.drawCircle(Offset(x, y), 0.4 + 1.3 * _r(i, 4), p);
      }
    }
    if (s.bokeh) {
      for (var i = 0; i < 22; i++) {
        final c = s.bokehColors[i % s.bokehColors.length];
        final r = u * (0.03 + 0.07 * _r(i, 5));
        canvas.drawCircle(
            Offset(_r(i, 6) * w, _r(i, 7) * h * 0.85),
            r,
            Paint()
              ..color = c.withAlpha((25 + 45 * _r(i, 8)).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35));
      }
    }
    if (s.moon || s.sun) {
      final c = Offset(w * 0.78, h * (s.sun ? 0.16 : 0.13));
      final r = u * (s.moon ? 0.09 : 0.08);
      final col = s.moon ? const Color(0xFFFFF6D8) : const Color(0xFFFFF3B0);
      canvas.drawCircle(
          c,
          r * 3,
          Paint()
            ..shader = RadialGradient(colors: [col.withAlpha(90), col.withAlpha(0)])
                .createShader(Rect.fromCircle(center: c, radius: r * 3)));
      canvas.drawCircle(c, r, Paint()..color = col);
      if (s.moon) {
        // vết trên mặt trăng
        final crater = Paint()..color = const Color(0x22B0A080);
        canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.2), r * 0.22, crater);
        canvas.drawCircle(c + Offset(r * 0.35, r * 0.25), r * 0.15, crater);
        canvas.drawCircle(c + Offset(-r * 0.1, r * 0.45), r * 0.1, crater);
      }
    }

    _landmark(canvas, size, u);
    final g = s.groundColor;
    switch (s.ground) {
      case Ground.none:
        break;
      case Ground.hills:
        for (var layer = 0; layer < 3; layer++) {
          final base = h * (0.8 + layer * 0.07);
          final path = Path()..moveTo(0, h);
          for (var x = 0.0; x <= w; x += w / 40) {
            path.lineTo(x, base - math.sin(x / w * math.pi * (1.5 + layer) + layer * 2) * u * (0.07 - layer * 0.015));
          }
          path
            ..lineTo(w, h)
            ..close();
          canvas.drawPath(path, Paint()..color = Color.lerp(g, s.sky.last, 0.45 - layer * 0.2)!);
        }
        break;
      case Ground.pines:
        canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = g);
        for (var i = 0; i < 14; i++) {
          final x = w * (i + _r(i, 9) * 0.6) / 13;
          final th = u * (0.12 + 0.12 * _r(i, 10));
          final y = h * 0.88;
          final tree = Path()
            ..moveTo(x, y - th)
            ..lineTo(x - th * 0.32, y)
            ..lineTo(x + th * 0.32, y)
            ..close();
          canvas.drawPath(tree, Paint()..color = Color.lerp(g, Colors.black, 0.3)!);
        }
        break;
      case Ground.city:
        final p = Paint()..color = g;
        final win = Paint();
        var x = 0.0;
        var i = 0;
        while (x < w) {
          final bw = u * (0.06 + 0.07 * _r(i, 11));
          final bh = h * (0.08 + 0.14 * _r(i, 12));
          final r = Rect.fromLTWH(x, h - bh, bw + 1, bh);
          canvas.drawRect(r, p);
          // cửa sổ sáng ấm
          for (var k = 0; k < 6; k++) {
            if (_r(i * 10 + k, 13) < 0.5) continue;
            win.color = const Color(0xFFFFD27A).withAlpha((110 + 100 * _r(i * 10 + k, 14)).round());
            canvas.drawRect(
                Rect.fromLTWH(r.left + bw * (0.2 + 0.4 * (k % 2)), r.top + bh * (0.12 + 0.13 * (k ~/ 2)),
                    bw * 0.18, bh * 0.06),
                win);
          }
          x += bw;
          i++;
        }
        break;
      case Ground.sea:
        final top = h * 0.8;
        final sea = Rect.fromLTWH(0, top, w, h - top);
        canvas.drawRect(
            sea,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(g, s.sky.last, 0.35)!, g],
              ).createShader(sea));
        final shine = Paint()
          ..color = Colors.white.withAlpha(60)
          ..strokeWidth = 1.5;
        for (var i = 0; i < 26; i++) {
          final y = top + (h - top) * _r(i, 15);
          final x = w * _r(i, 16);
          final len = u * (0.03 + 0.08 * _r(i, 17));
          canvas.drawLine(Offset(x, y), Offset(x + len, y), shine);
        }
        break;
    }
  }

  void _landmark(Canvas canvas, Size size, double u) {
    final w = size.width, h = size.height;
    Paint fill(Color c) => Paint()..color = c;
    switch (s.landmark) {
      case Landmark.none:
        break;
      case Landmark.autumnTrees:
        // hàng cây tán vàng, cam, đỏ nhạt trên đồi; thảm lá dưới gốc
        final gy = h * 0.84;
        const foliage = [Color(0xFFF2B33D), Color(0xFFE8893A), Color(0xFFF5CF6A), Color(0xFFD9653B)];
        for (var i = 0; i < 7; i++) {
          final cx = w * (i + 0.3 + 0.4 * _r(i, 101)) / 7;
          final th = u * (0.12 + 0.08 * _r(i, 102));
          final base = gy + u * 0.02 * _r(i, 103);
          canvas.drawLine(Offset(cx, base), Offset(cx, base - th),
              Paint()
                ..color = const Color(0xFF7A5230)
                ..strokeWidth = u * 0.014);
          for (var k = 0; k < 7; k++) {
            final c = foliage[(i + k) % foliage.length];
            canvas.drawCircle(
                Offset(cx + (_r(i * 9 + k, 104) - 0.5) * u * 0.13, base - th - (_r(i * 9 + k, 105) - 0.3) * u * 0.08),
                u * (0.035 + 0.025 * _r(i * 9 + k, 106)),
                fill(c.withAlpha(230)));
          }
        }
        break;
      case Landmark.fuji:
        // núi Phú Sĩ đỉnh tuyết + cây hoa anh đào hai bên
        final base = h * 0.93, peak = h * 0.69;
        final m = Path()
          ..moveTo(-w * 0.1, base)
          ..quadraticBezierTo(w * 0.28, base - h * 0.04, w * 0.43, peak + h * 0.01)
          ..lineTo(w * 0.57, peak + h * 0.01)
          ..quadraticBezierTo(w * 0.72, base - h * 0.04, w * 1.1, base)
          ..close();
        canvas.drawPath(
            m,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5C6BC0), Color(0xFF7E8CC8), Color(0xFFB0A8D0)],
              ).createShader(Rect.fromLTWH(0, peak, w, base - peak)));
        final snow = Path()
          ..moveTo(w * 0.35, peak + h * 0.06)
          ..lineTo(w * 0.43, peak + h * 0.01)
          ..lineTo(w * 0.57, peak + h * 0.01)
          ..lineTo(w * 0.65, peak + h * 0.06);
        for (var i = 0; i <= 8; i++) {
          final x = w * (0.65 - 0.3 * i / 8);
          snow.lineTo(x, peak + h * (i.isEven ? 0.06 : 0.085));
        }
        snow.close();
        canvas.drawPath(snow, fill(Colors.white));
        canvas.drawRect(Rect.fromLTWH(0, base - h * 0.01, w, h - base + h * 0.01), fill(const Color(0xFFB98AA0)));
        for (final cx in [w * 0.08, w * 0.25, w * 0.82, w * 0.97]) {
          final ty = base + h * 0.02;
          canvas.drawLine(Offset(cx, ty), Offset(cx, ty - h * 0.1),
              Paint()
                ..color = const Color(0xFF4E342E)
                ..strokeWidth = u * 0.02);
          for (var i = 0; i < 9; i++) {
            canvas.drawCircle(Offset(cx + (_r(i, cx.round()) - 0.5) * u * 0.22, ty - h * 0.11 - _r(i, 77) * u * 0.1),
                u * (0.04 + 0.03 * _r(i, 78)), fill(Color.lerp(const Color(0xFFF8BBD0), const Color(0xFFF48FB1), _r(i, 79))!));
          }
        }
        break;
      case Landmark.taj:
        // cung điện mái vòm Ấn Độ (dáng Taj Mahal) phản chiếu trên hồ
        final sil = fill(const Color(0xFF0E0A24));
        final rim = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, u * 0.004)
          ..color = const Color(0x88FFC46B);
        final cx = w / 2, gy = h * 0.84;
        final bw = u * 0.62;
        final b = Path()..addRect(Rect.fromLTWH(cx - bw / 2, gy - u * 0.2, bw, u * 0.2));
        // mái vòm chính trên tháp tròn
        b.addRect(Rect.fromLTWH(cx - u * 0.13, gy - u * 0.28, u * 0.26, u * 0.09));
        b.moveTo(cx - u * 0.15, gy - u * 0.28);
        b.cubicTo(cx - u * 0.2, gy - u * 0.42, cx - u * 0.05, gy - u * 0.48, cx, gy - u * 0.56);
        b.cubicTo(cx + u * 0.05, gy - u * 0.48, cx + u * 0.2, gy - u * 0.42, cx + u * 0.15, gy - u * 0.28);
        b.close();
        // 2 vòm nhỏ hai bên
        for (final dx in [-0.2, 0.2]) {
          final x = cx + u * dx;
          b.moveTo(x - u * 0.05, gy - u * 0.2);
          b.quadraticBezierTo(x, gy - u * 0.33, x + u * 0.05, gy - u * 0.2);
          b.close();
        }
        // 4 tháp nhọn (minaret)
        for (final dx in [-0.42, -0.36, 0.36, 0.42]) {
          final x = cx + u * dx;
          b.addRect(Rect.fromLTWH(x - u * 0.012, gy - u * 0.34, u * 0.024, u * 0.34));
          b.addOval(Rect.fromCenter(center: Offset(x, gy - u * 0.35), width: u * 0.04, height: u * 0.04));
        }
        canvas.drawPath(b, sil);
        canvas.drawPath(b, rim);
        // cổng vòm chính sáng ấm
        canvas.drawRRect(
            RRect.fromRectAndCorners(Rect.fromLTWH(cx - u * 0.06, gy - u * 0.16, u * 0.12, u * 0.16),
                topLeft: Radius.circular(u * 0.06), topRight: Radius.circular(u * 0.06)),
            fill(const Color(0xFFFFB74D)));
        // đèn dầu diya dọc nền
        for (var i = 0; i < 16; i++) {
          final x = w * (i + 0.5) / 16;
          canvas.drawCircle(Offset(x, gy + u * 0.01), u * 0.008, fill(const Color(0xFFFFD54F)));
        }
        // hồ nước phản chiếu
        final pool = Rect.fromLTWH(0, gy + u * 0.02, w, h - gy);
        canvas.drawRect(pool, fill(const Color(0xFF0A0820)));
        canvas.save();
        canvas.translate(0, (gy + u * 0.02) * 2);
        canvas.scale(1, -1);
        canvas.clipRect(Rect.fromLTWH(0, gy + u * 0.02 - u * 0.4, w, u * 0.4));
        canvas.drawPath(b, fill(const Color(0x55302060)));
        canvas.restore();
        break;
      case Landmark.pyramid:
        // kim tự tháp bậc thang Chichén Itzá + xương rồng + đồng cúc vạn thọ
        final gy = h * 0.86, cx = w / 2;
        final sil = fill(const Color(0xFF2A1238));
        for (var i = 0; i < 9; i++) {
          final bw = u * (0.7 - i * 0.055);
          canvas.drawRect(Rect.fromLTWH(cx - bw / 2, gy - u * 0.035 * (i + 1), bw, u * 0.036), sil);
        }
        canvas.drawRect(Rect.fromLTWH(cx - u * 0.1, gy - u * 0.39, u * 0.2, u * 0.08), sil);
        canvas.drawRect(Rect.fromLTWH(cx - u * 0.025, gy - u * 0.36, u * 0.05, u * 0.05), fill(const Color(0xFFFF9800)));
        canvas.drawRect(Rect.fromLTWH(cx - u * 0.05, gy - u * 0.315, u * 0.1, u * 0.315), fill(const Color(0xFF341848)));
        for (final dx in [-0.42, 0.4]) {
          final x = w / 2 + u * dx * 1.1;
          final ca = fill(const Color(0xFF1E0E26));
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x - u * 0.025, gy - u * 0.24, u * 0.05, u * 0.24), Radius.circular(u * 0.025)),
              ca);
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x - u * 0.09, gy - u * 0.17, u * 0.035, u * 0.1), Radius.circular(u * 0.017)),
              ca);
          canvas.drawRect(Rect.fromLTWH(x - u * 0.07, gy - u * 0.09, u * 0.05, u * 0.02), ca);
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x + u * 0.055, gy - u * 0.2, u * 0.035, u * 0.1), Radius.circular(u * 0.017)),
              ca);
          canvas.drawRect(Rect.fromLTWH(x + u * 0.02, gy - u * 0.12, u * 0.05, u * 0.02), ca);
        }
        canvas.drawRect(Rect.fromLTWH(0, gy, w, h - gy), fill(const Color(0xFF1A0A22)));
        for (var i = 0; i < 60; i++) {
          canvas.drawCircle(Offset(_r(i, 91) * w, gy + _r(i, 92) * (h - gy)), u * (0.01 + 0.012 * _r(i, 93)),
              fill(Color.lerp(const Color(0xFFFF9800), const Color(0xFFFFC107), _r(i, 94))!));
        }
        break;
      case Landmark.hoiAn:
        // phố cổ: nhà tường vàng mái ngói, đèn lồng dưới hiên, Chùa Cầu, sông Hoài
        final river = h * 0.84;
        var x = -u * 0.05;
        var i = 0;
        while (x < w) {
          final hw = u * (0.16 + 0.06 * _r(i, 61));
          final hh = u * (0.13 + 0.07 * _r(i, 62));
          final top = river - hh;
          canvas.drawRect(Rect.fromLTWH(x, top, hw, hh), fill(Color.lerp(const Color(0xFFC9A227), const Color(0xFFE0B84A), _r(i, 63))!));
          canvas.drawRect(Rect.fromLTWH(x + hw * 0.2, top + hh * 0.35, hw * 0.25, hh * 0.65), fill(const Color(0xFF5D3A1A)));
          canvas.drawRect(Rect.fromLTWH(x + hw * 0.58, top + hh * 0.3, hw * 0.22, hh * 0.25), fill(const Color(0xFFFFD27A)));
          final roof = Path()
            ..moveTo(x - hw * 0.08, top + hh * 0.05)
            ..quadraticBezierTo(x + hw * 0.1, top - hh * 0.05, x + hw * 0.2, top - hh * 0.28)
            ..lineTo(x + hw * 0.8, top - hh * 0.28)
            ..quadraticBezierTo(x + hw * 0.9, top - hh * 0.05, x + hw * 1.08, top + hh * 0.05)
            ..close();
          canvas.drawPath(roof, fill(const Color(0xFF6D3B1F)));
          for (var k = 0; k < 3; k++) {
            final lc = Offset(x + hw * (0.2 + 0.3 * k), top + hh * 0.12);
            final col = const [Color(0xFFE53935), Color(0xFFFFB300), Color(0xFF8E24AA)][(i + k) % 3];
            canvas.drawCircle(lc, u * 0.035, Paint()
              ..color = col.withAlpha(90)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.02));
            canvas.drawOval(Rect.fromCenter(center: lc, width: u * 0.03, height: u * 0.026), fill(col));
          }
          x += hw + u * 0.01;
          i++;
        }
        // sông + Chùa Cầu bắc ngang bên trái
        canvas.drawRect(Rect.fromLTWH(0, river, w, h - river), fill(const Color(0xFF101830)));
        for (var k = 0; k < 30; k++) {
          final y = river + (h - river) * _r(k, 64);
          final lx = w * _r(k, 65);
          canvas.drawLine(Offset(lx, y), Offset(lx + u * 0.04, y), Paint()
            ..color = const [Color(0x88FFB300), Color(0x66E53935), Color(0x55FFFFFF)][k % 3]
            ..strokeWidth = 1.5);
        }
        final bx = w * 0.04, bw = u * 0.42, by = river - u * 0.02;
        canvas.drawArc(Rect.fromLTWH(bx, by - u * 0.04, bw, u * 0.12), math.pi, math.pi, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.025
          ..color = const Color(0xFF4E2A12));
        canvas.drawRect(Rect.fromLTWH(bx + bw * 0.1, by - u * 0.12, bw * 0.8, u * 0.08), fill(const Color(0xFF8B4513)));
        final br = Path()
          ..moveTo(bx + bw * 0.02, by - u * 0.11)
          ..quadraticBezierTo(bx + bw * 0.15, by - u * 0.13, bx + bw * 0.22, by - u * 0.2)
          ..lineTo(bx + bw * 0.78, by - u * 0.2)
          ..quadraticBezierTo(bx + bw * 0.85, by - u * 0.13, bx + bw * 0.98, by - u * 0.11)
          ..close();
        canvas.drawPath(br, fill(const Color(0xFF5A2E14)));
        break;
      case Landmark.thaiTemple:
        // tháp chùa kiểu Thái (prang) trắng xanh bên bờ biển
        final gy = h * 0.8;
        for (final (dx, sc) in [(-0.3, 0.6), (0.0, 1.0), (0.3, 0.6)]) {
          final cx = w / 2 + u * dx;
          final th = u * 0.45 * sc, bw = u * 0.16 * sc;
          final tower = Path();
          for (var k = 0; k < 6; k++) {
            final y0 = gy - th * k / 6, y1 = gy - th * (k + 1) / 6;
            final w0 = bw * (1 - k / 7), w1 = bw * (1 - (k + 0.85) / 7);
            tower
              ..moveTo(cx - w0 / 2, y0)
              ..lineTo(cx - w1 / 2, y1)
              ..lineTo(cx + w1 / 2, y1)
              ..lineTo(cx + w0 / 2, y0)
              ..close();
          }
          tower
            ..moveTo(cx - bw * 0.06, gy - th)
            ..lineTo(cx, gy - th * 1.22)
            ..lineTo(cx + bw * 0.06, gy - th)
            ..close();
          canvas.drawPath(tower, fill(const Color(0xFFECEFF1)));
          for (var k = 1; k < 6; k++) {
            final y = gy - th * k / 6;
            canvas.drawLine(Offset(cx - bw * (1 - k / 7) / 2, y), Offset(cx + bw * (1 - k / 7) / 2, y),
                Paint()
                  ..color = const Color(0xFF4FC3F7)
                  ..strokeWidth = math.max(1, u * 0.004));
          }
        }
        break;
      case Landmark.harvest:
        // mùa gặt: đồng lúa mì vàng, nhà kho đỏ, bí ngô
        final gy = h * 0.82;
        canvas.drawRect(Rect.fromLTWH(0, gy, w, h - gy), fill(const Color(0xFFD4A03A)));
        final bx = w * 0.62, bw = u * 0.28, bh = u * 0.18;
        canvas.drawRect(Rect.fromLTWH(bx, gy - bh, bw, bh), fill(const Color(0xFF8E2A1E)));
        final roof = Path()
          ..moveTo(bx - u * 0.02, gy - bh)
          ..lineTo(bx + bw * 0.25, gy - bh - u * 0.09)
          ..lineTo(bx + bw * 0.75, gy - bh - u * 0.09)
          ..lineTo(bx + bw + u * 0.02, gy - bh)
          ..close();
        canvas.drawPath(roof, fill(const Color(0xFF5A1A12)));
        canvas.drawRect(Rect.fromLTWH(bx + bw * 0.38, gy - bh * 0.6, bw * 0.24, bh * 0.6), fill(const Color(0xFFF5E6C8)));
        final cross = Paint()
          ..color = const Color(0xFF8E2A1E)
          ..strokeWidth = u * 0.008;
        canvas.drawLine(Offset(bx + bw * 0.38, gy - bh * 0.6), Offset(bx + bw * 0.62, gy), cross);
        canvas.drawLine(Offset(bx + bw * 0.62, gy - bh * 0.6), Offset(bx + bw * 0.38, gy), cross);
        final stalk = Paint()
          ..color = const Color(0xFFF2C14E)
          ..strokeWidth = math.max(1, u * 0.004);
        for (var i = 0; i < 70; i++) {
          final x = w * _r(i, 71), y = gy + (h - gy) * _r(i, 72);
          canvas.drawLine(Offset(x, y), Offset(x + u * 0.005, y - u * 0.05), stalk);
          canvas.drawOval(Rect.fromCenter(center: Offset(x + u * 0.006, y - u * 0.055), width: u * 0.012, height: u * 0.028),
              fill(const Color(0xFFE0A82E)));
        }
        for (final (px, ps) in [(0.12, 1.0), (0.24, 0.75), (0.86, 0.85)]) {
          final c = Offset(w * px, h * 0.93);
          final r = u * 0.05 * ps;
          for (final dx in [-0.45, 0.0, 0.45]) {
            canvas.drawOval(Rect.fromCenter(center: c + Offset(r * dx, 0), width: r * 1.1, height: r * 1.5),
                fill(dx == 0 ? const Color(0xFFFF8F00) : const Color(0xFFEF6C00)));
          }
          canvas.drawRect(Rect.fromLTWH(c.dx - r * 0.08, c.dy - r * 0.95, r * 0.16, r * 0.3), fill(const Color(0xFF33691E)));
        }
        break;
      case Landmark.sugarloaf:
        // núi Đường (Pão de Açúcar) bên vịnh Rio
        final gy = h * 0.86;
        final m = Path()
          ..moveTo(w * 0.55, gy)
          ..cubicTo(w * 0.6, gy - u * 0.5, w * 0.82, gy - u * 0.55, w * 0.9, gy)
          ..close();
        canvas.drawPath(m, fill(const Color(0xFF0B3A2A)));
        final m2 = Path()
          ..moveTo(w * 0.3, gy)
          ..cubicTo(w * 0.33, gy - u * 0.25, w * 0.45, gy - u * 0.27, w * 0.5, gy)
          ..close();
        canvas.drawPath(m2, fill(const Color(0xFF0E4632)));
        canvas.drawLine(Offset(w * 0.41, gy - u * 0.2), Offset(w * 0.72, gy - u * 0.42),
            Paint()
              ..color = const Color(0x99FFFFFF)
              ..strokeWidth = 1);
        canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.56, gy - u * 0.31), width: u * 0.03, height: u * 0.02),
            fill(const Color(0xFFFFEB3B)));
        break;
      case Landmark.stream:
        // dòng suối đêm giữa hai bờ cỏ lau, mặt nước lấp lánh
        final top = h * 0.8;
        final bank = Path()
          ..moveTo(0, top - u * 0.06)
          ..quadraticBezierTo(w * 0.3, top - u * 0.1, w * 0.6, top - u * 0.04)
          ..quadraticBezierTo(w * 0.85, top - u * 0.01, w, top - u * 0.07)
          ..lineTo(w, top)
          ..lineTo(0, top)
          ..close();
        canvas.drawPath(bank, fill(const Color(0xFF0B1424)));
        final water = Rect.fromLTWH(0, top, w, h - top);
        canvas.drawRect(
            water,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1C2A55), Color(0xFF0D1838)],
              ).createShader(water));
        for (var i = 0; i < 40; i++) {
          final y = top + (h - top) * _r(i, 81);
          final x = w * _r(i, 82);
          canvas.drawLine(Offset(x, y), Offset(x + u * (0.03 + 0.06 * _r(i, 83)), y),
              Paint()
                ..color = const Color(0x55FFE0A0)
                ..strokeWidth = 1.2);
        }
        final reed = Paint()
          ..color = const Color(0xFF162A1E)
          ..strokeWidth = math.max(1, u * 0.004);
        for (var i = 0; i < 30; i++) {
          final x = w * _r(i, 84);
          final y = top - u * 0.02;
          canvas.drawLine(Offset(x, y), Offset(x + (_r(i, 85) - 0.5) * u * 0.04, y - u * (0.05 + 0.07 * _r(i, 86))), reed);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.s != s;
}

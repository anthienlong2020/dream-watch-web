import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ảnh nền riêng cho từng lễ hội: vẽ bằng code (bầu trời, trăng/mặt trời, đồi, phố, biển...)
/// nên hợp màu với hiệu ứng của lễ hội đó, không tốn dung lượng.
/// Muốn dùng ảnh thật thì chép ảnh vào assets/events/ đặt tên theo mã lễ hội,
/// vd: tet.jpg, giangSinh.png → app tự dùng ảnh đó thay cho cảnh vẽ.

enum Ground { none, hills, city, sea, pines }

class EventScene {
  final List<Color> sky; // trên → dưới
  final bool moon, sun, stars, bokeh;
  final Ground ground;
  final Color groundColor;
  final List<Color> bokehColors;
  const EventScene({
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
  'thu': EventScene(
      sky: [Color(0xFF4E2E20), Color(0xFFB45F26), Color(0xFFF0B060)], sun: true,
      groundColor: Color(0xFF5A3418)),
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
      groundColor: Color(0xFF02180F)),
  'phuNu': EventScene(
      sky: [Color(0xFFF5D2DE), Color(0xFFF0B0D0), Color(0xFFFFEEF4)], bokeh: true,
      bokehColors: [Color(0xFFFFFFFF), Color(0xFFFF80AB)], ground: Ground.none),
  'phucSinh': EventScene(
      sky: [Color(0xFFC6E3A8), Color(0xFFF0F7CE), Color(0xFFFFE2EA)], sun: true, groundColor: Color(0xFF7CB860)),
  'thieuNhi': EventScene(
      sky: [Color(0xFF6FCBFF), Color(0xFFBDEEFF), Color(0xFFFFF9DC)], sun: true, groundColor: Color(0xFF8BC34A)),
  'trungThu': EventScene(
      sky: [Color(0xFF090D2A), Color(0xFF182656), Color(0xFF363C78)], moon: true, stars: true,
      groundColor: Color(0xFF070A1C)),
  'halloween': EventScene(
      sky: [Color(0xFF100015), Color(0xFF360A46), Color(0xFFE0651A)], moon: true, stars: true,
      ground: Ground.pines, groundColor: Color(0xFF07020A)),
  'nhaGiao': EventScene(
      sky: [Color(0xFFD8EEFF), Color(0xFFB8DCFF), Color(0xFFFFF6DC)], sun: true, groundColor: Color(0xFF81B26A)),
  'hanami': EventScene(
      sky: [Color(0xFFFFE0EA), Color(0xFFFFCCD9), Color(0xFFFFF3F7)], sun: true, groundColor: Color(0xFFB98AA0)),
  'holi': EventScene(
      sky: [Color(0xFFFFDDF5), Color(0xFFDDEEFF), Color(0xFFFFF1D0)], bokeh: true,
      bokehColors: [Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFFFFEA00), Color(0xFFFF4081)],
      ground: Ground.none),
  'diwali': EventScene(
      sky: [Color(0xFF040318), Color(0xFF120A36), Color(0xFF28104E)], stars: true, ground: Ground.city,
      groundColor: Color(0xFF05030F)),
  'songkran': EventScene(
      sky: [Color(0xFF79D4FF), Color(0xFFB8EEFF), Color(0xFFE6FAFF)], sun: true, ground: Ground.sea,
      groundColor: Color(0xFF29A8D8)),
  'hoiAn': EventScene(
      sky: [Color(0xFF0C091D), Color(0xFF2A1838), Color(0xFF5A2C18)], moon: true, stars: true,
      ground: Ground.city, groundColor: Color(0xFF0A0610)),
  'sinhNhat': EventScene(
      sky: [Color(0xFF27144C), Color(0xFF572884), Color(0xFFFF9AC8)], bokeh: true,
      bokehColors: [Color(0xFFFFD54F), Color(0xFFFF80AB), Color(0xFF80D8FF)], ground: Ground.none),
  'phatDan': EventScene(
      sky: [Color(0xFF181030), Color(0xFF3A2858), Color(0xFFEFC06A)], moon: true, stars: true,
      ground: Ground.sea, groundColor: Color(0xFF1A1430)),
  'doanNgo': EventScene(
      sky: [Color(0xFFFFD69C), Color(0xFFFFB068), Color(0xFFFF8858)], sun: true, groundColor: Color(0xFF5E8C3A)),
  'vuLan': EventScene(
      sky: [Color(0xFF120A1C), Color(0xFF36162C), Color(0xFF762838)], moon: true, stars: true,
      ground: Ground.sea, groundColor: Color(0xFF14080F)),
  'thaDen': EventScene(
      sky: [Color(0xFF030518), Color(0xFF12183C), Color(0xFF36284C)], moon: true, stars: true,
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
      sky: [Color(0xFF46230F), Color(0xFF9C502A), Color(0xFFF0A25E)], sun: true, groundColor: Color(0xFF4A2A12)),
  'diaDeMuertos': EventScene(
      sky: [Color(0xFF18092C), Color(0xFF461858), Color(0xFFFF8A40)], stars: true, groundColor: Color(0xFF0C0414)),
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

  @override
  bool shouldRepaint(_ScenePainter old) => old.s != s;
}

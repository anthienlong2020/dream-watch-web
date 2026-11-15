import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Đồng hồ quả lắc (bản Standard): vỏ gỗ, mặt men ngà viền đồng, quả lắc đung đưa,
/// 12 con số hoạt hình nhún nhảy đúng vị trí trên mặt số.
/// - Số của giờ hiện tại: to hơn, nhảy cao, thỉnh thoảng nhào lộn.
/// - Số kim phút đang chỉ tới: lắc lư mạnh hơn.
/// - Đầu mỗi giờ (lúc chuông đổ): cả dàn nhảy múa, nốt nhạc bay lên.
class PendulumClock extends StatefulWidget {
  /// Gọi mỗi khi qua 1 giây (để phát tiếng tích tắc), [even] = giây chẵn.
  final void Function(bool even)? onTick;
  final String dateText;

  /// Mặt đồng hồ hình ảnh (12 hình giờ/phút/giây) đặt khớp lên mặt số.
  final Widget? face;
  const PendulumClock({super.key, this.onTick, this.dateText = '', this.face});

  @override
  State<PendulumClock> createState() => _PendulumClockState();
}

class _PendulumClockState extends State<PendulumClock> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  int _lastSec = -1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final now = DateTime.now();
        if (now.second != _lastSec) {
          if (_lastSec != -1) widget.onTick?.call(now.second.isEven);
          _lastSec = now.second;
        }
        return LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          final dial = PendulumPainter.dialOf(size);
          // vòng hình của DreamClock có bán kính 0.40 × cạnh → khớp vòng số 0.72 × bán kính mặt số
          final side = dial.r * 0.72 / 0.40;
          return Stack(children: [
            Positioned.fill(
              child: CustomPaint(painter: PendulumPainter(now, dateText: widget.dateText, dancers: widget.face == null)),
            ),
            if (widget.face != null)
              Positioned(
                left: dial.c.dx - side / 2,
                top: dial.c.dy - side / 2,
                width: side,
                height: side,
                child: widget.face!,
              ),
          ]);
        });
      },
    );
  }
}

/// 12 màu tươi cho 12 con số.
const List<Color> kDanceColors = [
  Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047),
  Color(0xFF00ACC1), Color(0xFF1E88E5), Color(0xFF5E35B1), Color(0xFFD81B60),
  Color(0xFF6D4C41), Color(0xFF00897B), Color(0xFFF4511E), Color(0xFF8E24AA),
];

class PendulumPainter extends CustomPainter {
  final DateTime now;
  final String dateText;

  /// true = vẽ 12 con số hoạt hình + kim; false = chỉ vẽ mặt số (hình ảnh đặt lên trên).
  final bool dancers;
  PendulumPainter(this.now, {this.dateText = '', this.dancers = true});

  /// Tâm và bán kính mặt số theo kích thước vùng vẽ.
  static ({Offset c, double r}) dialOf(Size size) {
    final cw = math.min(size.width * 0.92, size.height * 0.56);
    final top = size.height * 0.03;
    final r = cw * 0.42;
    return (c: Offset(size.width / 2, top + cw * 0.12 + r + cw * 0.06), r: r);
  }

  static final Map<String, TextPainter> _digits = {};

  /// Chỉ dùng cho ảnh xem thử khi test (máy test không có font mặc định).
  static String? fontFamily;

  double get t => now.millisecondsSinceEpoch % 10000000 / 1000.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _wall(canvas, size);
    final cw = math.min(w * 0.92, h * 0.56);
    final cx = w / 2;
    final top = h * 0.03;
    final r = cw * 0.42; // bán kính mặt số
    final cy = top + cw * 0.12 + r + cw * 0.06;
    final headBottom = cy + r + cw * 0.1;
    final boxTop = headBottom + cw * 0.02;
    final boxBottom = math.max(boxTop + cw * 0.5, h * 0.97);
    final bw = cw * 0.62;

    // ---- thân đồng hồ (hộp quả lắc) ----
    _wood(canvas, Rect.fromLTRB(cx - bw / 2, boxTop - cw * 0.03, cx + bw / 2, boxBottom), cw * 0.04);
    final win = Rect.fromLTRB(cx - bw * 0.36, boxTop + cw * 0.08, cx + bw * 0.36, boxBottom - cw * 0.06);
    _pendulum(canvas, win, cw);

    // ---- đầu đồng hồ ----
    final head = Rect.fromLTRB(cx - cw / 2, top + cw * 0.12, cx + cw / 2, headBottom);
    _crown(canvas, cx, top, cw);
    _wood(canvas, head, cw * 0.06);
    // hoa văn viền vàng đồng
    canvas.drawRRect(RRect.fromRectAndRadius(head.deflate(cw * 0.025), Radius.circular(cw * 0.05)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cw * 0.008
          ..color = const Color(0xAAD4AF37));
    _dial(canvas, Offset(cx, cy), r);

    // tấm biển đồng ghi ngày
    if (dateText.isNotEmpty) {
      final plate = Rect.fromCenter(center: Offset(cx, boxTop + cw * 0.035), width: bw * 0.86, height: cw * 0.06);
      canvas.drawRRect(
          RRect.fromRectAndRadius(plate, Radius.circular(cw * 0.012)),
          Paint()
            ..shader = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFF3D27A), Color(0xFFB8860B)])
                .createShader(plate));
      final tp = TextPainter(
        text: TextSpan(
            text: dateText,
            style: TextStyle(
                fontFamily: fontFamily, color: const Color(0xFF3E2723), fontSize: cw * 0.032, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: plate.width * 0.94);
      tp.paint(canvas, plate.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // -------------------------------------------------------------------------
  void _wall(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A2A22), Color(0xFF4E3A2E), Color(0xFF2A1E18)],
          ).createShader(rect));
    // giấy dán tường sọc mờ
    final stripe = Paint()..color = const Color(0x0FFFFFFF);
    for (var x = 0.0; x < size.width; x += size.width / 14) {
      canvas.drawRect(Rect.fromLTWH(x, 0, size.width / 28, size.height), stripe);
    }
    // ánh đèn ấm phía trên
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.25),
        size.width * 0.9,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0x33FFD27A), const Color(0x00FFD27A)])
              .createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.25), radius: size.width * 0.9)));
  }

  void _wood(Canvas canvas, Rect r, double radius) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF3E2410), Color(0xFF7A4A22), Color(0xFF9C6232), Color(0xFF7A4A22), Color(0xFF3E2410)],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(r));
    // vân gỗ
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x1A000000);
    for (var i = 1; i < 9; i++) {
      final x = r.left + r.width * i / 9;
      final p = Path()..moveTo(x, r.top + radius);
      p.cubicTo(x + r.width * 0.02, r.top + r.height * 0.3, x - r.width * 0.02, r.top + r.height * 0.6, x, r.bottom - radius);
      canvas.drawPath(p, grain);
    }
  }

  void _crown(Canvas canvas, double cx, double top, double cw) {
    final p = Path()
      ..moveTo(cx - cw * 0.5, top + cw * 0.16)
      ..quadraticBezierTo(cx - cw * 0.25, top + cw * 0.02, cx, top + cw * 0.02)
      ..quadraticBezierTo(cx + cw * 0.25, top + cw * 0.02, cx + cw * 0.5, top + cw * 0.16)
      ..close();
    canvas.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF4A2C14), Color(0xFF8B5A2B), Color(0xFF4A2C14)])
              .createShader(Rect.fromLTWH(cx - cw / 2, top, cw, cw * 0.16)));
    // núm trang trí bằng đồng
    canvas.drawCircle(Offset(cx, top + cw * 0.02), cw * 0.03,
        Paint()..shader = const RadialGradient(colors: [Color(0xFFFFF1B0), Color(0xFFB8860B)])
            .createShader(Rect.fromCircle(center: Offset(cx, top + cw * 0.02), radius: cw * 0.03)));
  }

  void _dial(Canvas canvas, Offset c, double r) {
    // viền đồng
    canvas.drawCircle(
        c,
        r * 1.08,
        Paint()
          ..shader = const SweepGradient(
            colors: [Color(0xFFB8860B), Color(0xFFFFE08A), Color(0xFFB8860B), Color(0xFFFFE08A), Color(0xFFB8860B)],
          ).createShader(Rect.fromCircle(center: c, radius: r * 1.08)));
    // mặt men ngà
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFFBF0), Color(0xFFF1E6C8), Color(0xFFDCCBA0)],
                  stops: [0.0, 0.8, 1.0])
              .createShader(Rect.fromCircle(center: c, radius: r)));
    // vạch phút
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * 2 * math.pi - math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      final big = i % 5 == 0;
      canvas.drawLine(c + d * r * (big ? 0.88 : 0.92), c + d * r * 0.97,
          Paint()
            ..color = const Color(0xFF3E2723)
            ..strokeWidth = big ? r * 0.018 : r * 0.007);
    }

    if (!dancers) {
      // chỉ mặt số + kính phản chiếu; giờ phút giây do hình ảnh thể hiện
      canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92), math.pi * 1.1, math.pi * 0.45, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.05
            ..strokeCap = StrokeCap.round
            ..color = const Color(0x22FFFFFF));
      return;
    }
    final h = now.hour % 12, m = now.minute, s = now.second, ms = now.millisecond;
    // tròn giờ: cả dàn nhảy múa trong lúc chuông đổ
    final party = m == 0 && s < 40;
    final hourNum = h == 0 ? 12 : h;
    var minuteNum = ((m + 2.5) ~/ 5) % 12;
    if (minuteNum == 0) minuteNum = 12;

    // các con số: vẽ số thường trước, số giờ hiện tại vẽ sau cùng (nổi lên trên)
    final order = [for (var n = 1; n <= 12; n++) if (n != hourNum) n, hourNum];
    for (final n in order) {
      final a = n / 12 * 2 * math.pi - math.pi / 2;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r * 0.7;
      final isHour = n == hourNum;
      final energy = party ? 1.25 : (isHour ? 1.0 : (n == minuteNum ? 0.65 : 0.3));
      _dancer(canvas, n, pos, r * (isHour ? 0.27 : 0.2), energy, isHour, party);
    }

    // kim giờ, kim phút, kim giây
    final hourA = (h + m / 60) / 12 * 2 * math.pi - math.pi / 2;
    final minA = (m + s / 60) / 60 * 2 * math.pi - math.pi / 2;
    // kim giây nhảy từng tic, có nảy nhẹ
    final bounce = ms < 120 ? math.sin(ms / 120 * math.pi) * 0.02 : 0.0;
    final secA = (s + bounce) / 60 * 2 * math.pi - math.pi / 2;
    _hand(canvas, c, hourA, r * 0.48, r * 0.05, const Color(0xFF1B1B1B), spade: true);
    _hand(canvas, c, minA, r * 0.76, r * 0.035, const Color(0xFF1B1B1B), spade: true);
    _hand(canvas, c, secA, r * 0.84, r * 0.012, const Color(0xFFC62828));
    canvas.drawCircle(c, r * 0.05,
        Paint()..shader = const RadialGradient(colors: [Color(0xFFFFF1B0), Color(0xFFB8860B)])
            .createShader(Rect.fromCircle(center: c, radius: r * 0.05)));
    // kính mặt số phản chiếu
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92), math.pi * 1.1, math.pi * 0.45, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x22FFFFFF));
  }

  void _hand(Canvas canvas, Offset c, double a, double len, double width, Color col, {bool spade = false}) {
    final d = Offset(math.cos(a), math.sin(a));
    final perp = Offset(-d.dy, d.dx);
    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width);
    final p = Path()
      ..moveTo((c - d * len * 0.15 + perp * width / 2).dx, (c - d * len * 0.15 + perp * width / 2).dy)
      ..lineTo((c + d * len * 0.8 + perp * width * 0.35).dx, (c + d * len * 0.8 + perp * width * 0.35).dy);
    if (spade) {
      // đầu kim hình lá bích cổ điển
      final tipBase = c + d * len * 0.8;
      p
        ..quadraticBezierTo((tipBase + perp * width * 1.8).dx, (tipBase + perp * width * 1.8).dy,
            (c + d * len).dx, (c + d * len).dy)
        ..quadraticBezierTo((tipBase - perp * width * 1.8).dx, (tipBase - perp * width * 1.8).dy,
            (tipBase - perp * width * 0.35).dx, (tipBase - perp * width * 0.35).dy);
    } else {
      p.lineTo((c + d * len).dx, (c + d * len).dy);
      p.lineTo((c + d * len * 0.8 - perp * width * 0.35).dx, (c + d * len * 0.8 - perp * width * 0.35).dy);
    }
    p
      ..lineTo((c - d * len * 0.15 - perp * width / 2).dx, (c - d * len * 0.15 - perp * width / 2).dy)
      ..close();
    canvas.drawPath(p.shift(const Offset(2, 3)), shadow);
    canvas.drawPath(p, Paint()..color = col);
  }

  /// Một con số hoạt hình: thân là chữ số, có mắt, miệng, tay đeo găng trắng, chân đi giày.
  void _dancer(Canvas canvas, int n, Offset pos, double s, double energy, bool isHour, bool party) {
    final ph = n * 0.9;
    final beat = t * math.pi * (party ? 2.4 : 1.6) + ph;
    final hop = -(math.sin(beat)).abs() * s * (party ? 0.35 : 0.2) * energy;
    var rot = math.sin(beat * 0.5) * 0.14 * energy;
    // số giờ nhào lộn mỗi ~8 giây
    if (isHour) {
      final f = (t % 8) / 8;
      if (f > 0.9) rot += (f - 0.9) / 0.1 * 2 * math.pi;
    }
    final col = kDanceColors[(n - 1) % kDanceColors.length];
    canvas.save();
    canvas.translate(pos.dx, pos.dy + hop);
    canvas.rotate(rot);

    if (isHour) {
      canvas.drawCircle(Offset.zero, s * 0.95,
          Paint()
            ..shader = RadialGradient(colors: [col.withAlpha(110), col.withAlpha(0)])
                .createShader(Rect.fromCircle(center: Offset.zero, radius: s * 0.95)));
    }

    final (tp, fillTp) = _digit(n, s, col);
    final gw = tp.width, gh = tp.height * 0.72; // chiều cao phần nét số
    final dark = Color.lerp(col, Colors.black, 0.5)!;

    // chân + giày (bước nhún nhảy)
    final step = math.sin(beat * 2) * 0.45 * energy;
    final legPaint = Paint()
      ..color = dark
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;
    for (final sg in [-1.0, 1.0]) {
      final hip = Offset(sg * gw * 0.18, gh * 0.42);
      final a = math.pi / 2 + sg * 0.15 + step * sg;
      final foot = hip + Offset(math.cos(a), math.sin(a)) * s * 0.28;
      canvas.drawLine(hip, foot, legPaint);
      canvas.drawOval(Rect.fromCenter(center: foot + Offset(sg * s * 0.04, s * 0.02), width: s * 0.17, height: s * 0.09),
          Paint()..color = const Color(0xFF212121));
    }
    // tay vẫy, găng trắng
    final wave = math.sin(beat * 1.7) * 0.8 * energy;
    for (final sg in [-1.0, 1.0]) {
      final sh = Offset(sg * gw * 0.46, 0);
      final a = sg > 0 ? -0.5 - wave * (party ? 1.2 : 0.8) : math.pi + 0.5 + wave * (party ? 1.2 : 0.8);
      final hand = sh + Offset(math.cos(a), math.sin(a)) * s * 0.3;
      canvas.drawLine(sh, hand, legPaint);
      canvas.drawCircle(hand, s * 0.065, Paint()..color = Colors.white);
      canvas.drawCircle(hand, s * 0.065, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.015
        ..color = dark);
    }

    // thân chữ số: viền trắng dày + màu
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    fillTp.paint(canvas, Offset(-fillTp.width / 2, -fillTp.height / 2));

    // mặt: mắt to (thỉnh thoảng chớp), má hồng, miệng cười
    final blink = ((t + n * 0.37) % 4.2) < 0.12 ? 0.15 : 1.0;
    final eyeY = -gh * 0.12;
    final eyeDx = math.max(gw * 0.16, s * 0.09);
    for (final sg in [-1.0, 1.0]) {
      final e = Offset(sg * eyeDx, eyeY);
      canvas.drawOval(Rect.fromCenter(center: e, width: s * 0.15, height: s * 0.19 * blink), Paint()..color = Colors.white);
      if (blink > 0.5) {
        canvas.drawCircle(e + Offset(0, s * 0.02), s * 0.045, Paint()..color = const Color(0xFF1B1B1B));
        canvas.drawCircle(e + Offset(-s * 0.015, -s * 0.0), s * 0.015, Paint()..color = Colors.white);
      }
      canvas.drawCircle(Offset(sg * eyeDx * 1.25, eyeY + s * 0.14), s * 0.04, Paint()..color = const Color(0x66FF4081));
    }
    final mouth = Rect.fromCenter(center: Offset(0, eyeY + s * 0.13), width: s * (party || isHour ? 0.2 : 0.14),
        height: s * (party || isHour ? 0.16 : 0.08));
    if (party || isHour) {
      canvas.drawArc(mouth, 0, math.pi, true, Paint()..color = const Color(0xFF6D1B1B));
    } else {
      canvas.drawArc(mouth, 0.2, math.pi - 0.4, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.025
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF3E2723));
    }
    canvas.restore();

    // nốt nhạc bay lên khi cả dàn đang nhảy
    if (party) {
      for (var k = 0; k < 2; k++) {
        final f = ((t * 0.7 + n * 0.29 + k * 0.5) % 1.0);
        final q = pos + Offset(math.sin(f * 6 + n) * s * 0.4, -s * 0.5 - f * s * 1.6);
        final note = _note(k.isEven ? '♪' : '♫', s * 0.45, col);
        canvas.save();
        canvas.translate(q.dx, q.dy);
        note.paint(canvas, Offset(-note.width / 2, -note.height / 2));
        canvas.restore();
      }
    }
  }

  /// Chữ số 2 lớp: viền trắng dày phía dưới + màu chuyển sắc phía trên.
  (TextPainter, TextPainter) _digit(int n, double s, Color col) {
    final style = TextStyle(
        fontFamily: fontFamily, fontSize: s * 1.15, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -s * 0.08);
    TextPainter make(String key, Paint fg) => _digits.putIfAbsent(key, () {
          if (_digits.length > 80) _digits.clear();
          return TextPainter(
            text: TextSpan(text: '$n', style: style.copyWith(foreground: fg)),
            textDirection: TextDirection.ltr,
          )..layout();
        });
    final stroke = make(
        'o$n|${s.round()}',
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.12
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white);
    final fill = make(
        'f$n|${s.round()}',
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(col, Colors.white, 0.3)!, col, Color.lerp(col, Colors.black, 0.25)!],
          ).createShader(Rect.fromLTWH(0, 0, s, s * 1.15)));
    return (stroke, fill);
  }

  TextPainter _note(String g, double s, Color col) {
    final key = '$g|${s.round()}|${col.toARGB32()}';
    return _digits.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(text: g, style: TextStyle(fontFamily: fontFamily, fontSize: s, color: col, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void _pendulum(Canvas canvas, Rect win, double cw) {
    // kính tối trong suốt
    canvas.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(cw * 0.03)), Paint()..color = const Color(0xFF1A120C));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(win, Radius.circular(cw * 0.03)));
    // 2 quả tạ dây xích hai bên
    for (final sg in [-1.0, 1.0]) {
      final x = win.center.dx + sg * win.width * 0.33;
      canvas.drawLine(Offset(x, win.top), Offset(x, win.top + win.height * 0.45),
          Paint()
            ..color = const Color(0xFFB8860B)
            ..strokeWidth = cw * 0.006);
      final wr = Rect.fromCenter(center: Offset(x, win.top + win.height * 0.52), width: cw * 0.06, height: win.height * 0.16);
      canvas.drawRRect(RRect.fromRectAndRadius(wr, Radius.circular(cw * 0.015)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF8B6914), Color(0xFFFFE08A), Color(0xFF8B6914)])
              .createShader(wr));
    }
    // quả lắc: chu kỳ 2 giây, chạm biên đúng lúc tích / tắc
    final ms = now.millisecondsSinceEpoch % 2000;
    final ang = 0.2 * math.cos(ms / 2000 * 2 * math.pi);
    final pivot = Offset(win.center.dx, win.top - cw * 0.02);
    final len = win.height * 0.78;
    final bob = pivot + Offset(math.sin(ang), math.cos(ang)) * len;
    canvas.drawLine(pivot, bob,
        Paint()
          ..color = const Color(0xFFC9A227)
          ..strokeWidth = cw * 0.012);
    final br = cw * 0.11;
    canvas.drawCircle(bob + const Offset(3, 4), br, Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(bob, br,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: const [Color(0xFFFFF4C2), Color(0xFFE0B040), Color(0xFF8B6914)],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: bob, radius: br)));
    canvas.drawCircle(bob, br * 0.7, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw * 0.004
      ..color = const Color(0x88FFF4C2));
    canvas.restore();
    // vệt phản chiếu trên kính
    final glare = Path()
      ..moveTo(win.left + win.width * 0.1, win.top)
      ..lineTo(win.left + win.width * 0.25, win.top)
      ..lineTo(win.left + win.width * 0.05, win.bottom)
      ..lineTo(win.left - win.width * 0.1, win.bottom)
      ..close();
    canvas.save();
    canvas.clipRect(win);
    canvas.drawPath(glare, Paint()..color = const Color(0x14FFFFFF));
    canvas.restore();
    canvas.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(cw * 0.03)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cw * 0.012
          ..color = const Color(0xFFC9A227));
  }

  @override
  bool shouldRepaint(PendulumPainter o) => o.now != now || o.dateText != dateText || o.dancers != dancers;
}


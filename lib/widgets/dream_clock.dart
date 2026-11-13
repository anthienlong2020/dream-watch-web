import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/clock_theme.dart';
import '../three_d/body_type.dart';
import '../effects/element_effect.dart';
import 'extruded_3d.dart';
import 'slot_image_view.dart';

/// Mặt đồng hồ mộng mơ:
/// - 12 hình xếp quanh vòng tròn ở vị trí 12 giờ.
/// - Hình của GIỜ hiện tại: quay quanh trục thẳng đứng như một khối có độ dày
///   (đung đưa trái - phải tới góc 3/4 như góc máy điện ảnh), và hiện TO ở
///   giữa mặt đồng hồ (thở chậm, cứ 30 giây phóng to rồi thu nhỏ từ từ).
/// - Hình PHÚT (hình ở mốc 5 phút vừa qua) nhảy theo số phút thật:
///   20:35 nhảy tại chỗ ở phút 35; 20:36 nhảy tới phút 36 rồi về 35;
///   20:37 nhảy tới lui 35 <-> 37; ... 20:40 chuyển sang hình ở mốc 40.
/// - Một bản nhỏ của hình phút chạy vòng quanh mặt đồng hồ làm kim GIÂY.
class DreamClock extends StatefulWidget {
  final ClockTheme theme;
  final bool showRoman;
  final bool showStars;

  /// Kiểu hiển thị của từng vị trí (0 = XII ... 11 = XI).
  final List<ImageStyle> styles;

  /// Ảnh 3D (Chibi / thổi phồng) ở vị trí giờ và ở giữa quay tròn 360°.
  final bool spin360;

  /// Dáng của từng vị trí: ốm / cân đối / mập.
  final List<BodyType> bodies;

  /// Hệ (lửa, nước, điện...) của từng vị trí.
  final List<ElementType> elements;

  /// Bật/tắt toàn bộ hiệu ứng hệ (tắt khi máy yếu).
  final bool effectsOn;

  /// Hệ số tốc độ: 1.0 = mặc định, nhỏ hơn = chậm hơn.
  final double hourSpeed;
  final double minuteSpeed;
  final double secondSpeed;

  const DreamClock({
    super.key,
    required this.theme,
    this.showRoman = true,
    this.showStars = true,
    this.styles = const [],
    this.spin360 = true,
    this.bodies = const [],
    this.elements = const [],
    this.effectsOn = true,
    this.hourSpeed = 1.0,
    this.minuteSpeed = 1.0,
    this.secondSpeed = 1.0,
  });

  /// Thời gian (ms) đã "co giãn" theo tốc độ, để mọi chuyển động chạy chậm/nhanh.
  int scaledMs(int ms, double speed) => (ms * speed.clamp(0.1, 4.0)).round();

  @override
  State<DreamClock> createState() => _DreamClockState();
}

class _DreamClockState extends State<DreamClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _frame;

  @override
  void initState() {
    super.initState();
    // Chỉ dùng làm "nhịp khung hình"; mọi chuyển động tính theo giờ thực.
    _frame = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(c.maxWidth, c.maxHeight);
      return Center(
        child: SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _frame,
            builder: (context, _) => _buildFace(s, DateTime.now()),
          ),
        ),
      );
    });
  }

  Widget _buildFace(double s, DateTime now) {
    _fxTime = (now.millisecondsSinceEpoch % 100000000) / 1000.0;
    final cx = s / 2;
    final cy = s / 2;
    final ringR = s * 0.40;
    final slotSize = s * 0.155;
    final hSlot = hourSlot(now);
    final mSlot = minuteSlot(now);
    final ms = now.millisecondsSinceEpoch;
    final secFrac = now.millisecond / 1000.0;

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _SkyPainter(ringR: ringR, showStars: widget.showStars),
        ),
      ),
    ];

    // Chữ số La Mã
    if (widget.showRoman) {
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final r = ringR * 0.78;
        final fs = s * 0.055;
        children.add(Positioned(
          left: cx + r * math.sin(a) - fs * 1.5,
          top: cy - r * math.cos(a) - fs * 0.7,
          width: fs * 3,
          height: fs * 1.4,
          child: Center(
            child: Text(
              kRoman[i],
              style: TextStyle(
                color: const Color(0xDDFFFFFF),
                fontSize: fs,
                height: 1.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ));
      }
    }

    // Hình to ở giữa = giờ hiện tại
    children.add(_centerImage(s, cx, cy, now, hSlot));

    // 11 hình đứng yên quanh vòng (hình phút được vẽ riêng vì nó nhảy đi)
    for (var i = 0; i < 12; i++) {
      if (i == mSlot) continue;
      final a = i * math.pi / 6;
      final x = cx + ringR * math.sin(a);
      final y = cy - ringR * math.cos(a);
      final Widget raw = i == hSlot
          ? _turning(i, slotSize, _hourAngle(i, ms))
          // Ảnh 3D đứng yên hơi nghiêng 3/4 cho thấy khối
          : SlotImageView(
              image: widget.theme.slot(i),
              size: slotSize,
              yaw: 0.35,
              style: _style(i),
              body: _body(i));
      final img = _fx(i, raw, slotSize, full: i == hSlot);
      children.add(Positioned(
        left: x - slotSize / 2,
        top: y - slotSize / 2,
        width: slotSize,
        height: slotSize,
        child: img,
      ));
    }

    // Hình phút nhảy theo số phút thật
    children.add(_minuteJumper(s, cx, cy, ringR, slotSize, now, hSlot, mSlot));

    // Kim giây: hình nhỏ nhảy từ vạch giây trước sang vạch giây hiện tại
    final runnerSize = s * 0.095;
    // Thời gian lướt trong mỗi giây: chậm thì lướt gần trọn giây, nhanh thì bật gọn.
    final glide = (0.75 / widget.secondSpeed.clamp(0.1, 4.0)).clamp(0.2, 0.97);
    final t = (secFrac / glide).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(t);
    final secPos = now.second - 1 + eased;
    final a = secPos * math.pi / 30;
    final hopUp = math.sin(t * math.pi) * s * 0.02;
    final rx = cx + ringR * math.sin(a);
    final ry = cy - ringR * math.cos(a);
    // Đẩy hình ra phía ngoài vòng một chút khi nhảy
    final ox = math.sin(a) * hopUp;
    final oy = -math.cos(a) * hopUp;
    children.add(Positioned(
      left: rx + ox - runnerSize / 2,
      top: ry + oy - runnerSize / 2,
      width: runnerSize,
      height: runnerSize,
      // Chibi 3D quay mặt theo hướng chạy
      child: _fx(
          mSlot,
          SlotImageView(
              image: widget.theme.slot(mSlot),
              size: runnerSize,
              yaw: 0.8 * math.cos(a),
              style: _style(mSlot),
              body: _body(mSlot)),
          runnerSize),
    ));

    return Stack(clipBehavior: Clip.none, children: children);
  }

  /// Thời điểm hiện tại (giây) cho hiệu ứng hệ, cập nhật mỗi khung hình.
  double _fxTime = 0;

  ElementType _element(int i) => !widget.effectsOn || i >= widget.elements.length
      ? ElementType.none
      : widget.elements[i];

  /// Bọc hiệu ứng hệ quanh hình ở vị trí [i] (nếu có).
  Widget _fx(int i, Widget child, double size, {bool full = false}) {
    final e = _element(i);
    if (e == ElementType.none) return child;
    final img = widget.theme.slot(i);
    final style = _style(i);
    // Ảnh phẳng / thổi phồng: lấy đúng viền ảnh; kiểu khác dùng viền elip
    final edgeSrc = (style == ImageStyle.standard || style == ImageStyle.thoiPhong) &&
            img.chibi == null
        ? (img.bytes ?? img.asset)
        : null;
    return ElementLayer(
      element: e,
      size: size,
      time: _fxTime,
      edgeSource: edgeSrc,
      full: full,
      seed: i,
      child: child,
    );
  }

  ImageStyle _style(int i) =>
      i < widget.styles.length ? widget.styles[i] : ImageStyle.thoiPhong;
  BodyType _body(int i) => i < widget.bodies.length ? widget.bodies[i] : BodyType.canDoi;

  /// Hình ở vị trí [i] có quay 360° không (chỉ ảnh 3D, khi bật tuỳ chọn).
  bool _spins(int i) =>
      widget.spin360 && SlotImageView.is3D(widget.theme.slot(i), _style(i));

  /// Góc của ảnh giờ: ảnh 3D quay 360°, ảnh phẳng đung đưa 3/4.
  double _hourAngle(int i, int realMs) {
    final ms = widget.scaledMs(realMs, widget.hourSpeed);
    return _spins(i)
        ? spinAngleAt(swingPhase(ms, 12000))
        : swingAngleAt(swingPhase(ms, 9000));
  }

  /// Hình đang xoay: Chibi 3D thì quay thật, ảnh phẳng thì dùng khối dày 2.5D.
  Widget _turning(int i, double size, double angle, {bool hi = false}) {
    final img = widget.theme.slot(i);
    final style = _style(i);
    if (SlotImageView.is3D(img, style) || style == ImageStyle.nguoiQue) {
      return SlotImageView(
          image: img, size: size, yaw: angle, hiDetail: hi, style: style, body: _body(i));
    }
    return Extruded3D(
      size: size,
      angleY: angle,
      depth: hi ? 0.12 : 0.14,
      layers: hi ? 10 : 6,
      child: SlotImageView(image: img, size: size, style: ImageStyle.standard),
    );
  }

  /// Hình phút: nhảy tới lui giữa mốc 5 phút vừa qua và phút hiện tại.
  Widget _minuteJumper(double s, double cx, double cy, double ringR,
      double slotSize, DateTime now, int hSlot, int mSlot) {
    const hopMs = 1100; // thời gian mỗi bước nhảy ở tốc độ 1.0
    final realMs = now.millisecondsSinceEpoch;
    final ms = widget.scaledMs(realMs, widget.minuteSpeed);
    final anchor = minuteAnchor(now);
    final d = now.minute - anchor; // 0..4 bước
    final frac = (ms % hopMs) / hopMs;

    double pos; // vị trí theo phút (có thể lẻ khi đang bay)
    var backward = false;
    if (d == 0) {
      pos = anchor.toDouble();
    } else {
      final idx = (ms ~/ hopMs) % (2 * d);
      final double from;
      final double to;
      if (idx < d) {
        from = (anchor + idx).toDouble();
        to = from + 1;
      } else {
        from = (now.minute - (idx - d)).toDouble();
        to = from - 1;
        backward = true;
      }
      pos = from + (to - from) * Curves.easeInOut.transform(frac);
    }

    final a = pos * math.pi / 30;
    final hop = math.sin(frac * math.pi) * s * 0.04;
    final x = cx + ringR * math.sin(a);
    final y = cy - ringR * math.cos(a) - hop;
    // Nhún nhẹ khi chạm đất
    final squash = 1.0 + 0.05 * math.cos(frac * 2 * math.pi);

    final slotImg = widget.theme.slot(mSlot);
    Widget img = SlotImageView(
        image: slotImg,
        size: slotSize,
        yaw: backward ? -0.6 : 0.6,
        style: _style(mSlot),
        body: _body(mSlot));
    final is3d = SlotImageView.is3D(slotImg, _style(mSlot));
    if (mSlot == hSlot) {
      // Vừa là hình giờ vừa là hình phút: vừa đung đưa vừa nhảy
      img = _turning(mSlot, slotSize, _hourAngle(mSlot, realMs));
    } else if (backward && !is3d) {
      // Quay đầu khi nhảy về
      img = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: img,
      );
    }

    return Positioned(
      left: x - slotSize / 2,
      top: y - slotSize / 2,
      width: slotSize,
      height: slotSize,
      child: Transform.scale(
          scaleX: 2 - squash, scaleY: squash, child: _fx(mSlot, img, slotSize, full: mSlot == hSlot)),
    );
  }

  Widget _centerImage(double s, double cx, double cy, DateTime now, int hSlot) {
    final size = s * 0.40;
    // Góc xoay và độ phóng to dùng CHUNG một pha nên luôn khớp nhau:
    // nhìn thẳng thì to nhất, nghiêng 3/4 thì nhỏ lại.
    final ms = widget.scaledMs(now.millisecondsSinceEpoch, widget.hourSpeed);
    final double angle;
    final double scale;
    if (_spins(hSlot)) {
      // Ảnh 3D: quay tròn 360°, to nhất khi quay mặt trước ra
      angle = spinAngleAt(swingPhase(ms, 16000));
      scale = spinZoomAt(angle, amount: 0.14);
    } else {
      final phase = swingPhase(ms, 14000);
      angle = swingAngleAt(phase, maxAngle: 0.65);
      scale = swingZoomAt(phase, amount: 0.14);
    }

    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: Transform.scale(
        scale: scale,
        child: _fx(hSlot, _turning(hSlot, size, angle, hi: true), size, full: true),
      ),
    );
  }
}

/// Nền: vòng tròn mảnh + các ngôi sao (đứng yên, không chớp).
class _SkyPainter extends CustomPainter {
  final double ringR;
  final bool showStars;

  _SkyPainter({required this.ringR, required this.showStars});

  static final List<_Star> _stars = _makeStars();

  static List<_Star> _makeStars() {
    final rnd = math.Random(7);
    final list = <_Star>[];
    for (var i = 0; i < 26; i++) {
      final r = math.sqrt(rnd.nextDouble()) * 0.88; // tỷ lệ theo bán kính vòng
      final a = rnd.nextDouble() * 2 * math.pi;
      list.add(_Star(
        x: r * math.sin(a),
        y: r * math.cos(a),
        big: i % 3 == 0,
        bright: rnd.nextDouble(),
      ));
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0x99FFFFFF),
    );
    if (!showStars) return;

    for (final st in _stars) {
      final p = c + Offset(st.x * ringR, st.y * ringR);
      final alpha = (120 + 120 * st.bright).round();
      final paint = Paint()..color = Color.fromARGB(alpha, 255, 255, 255);
      if (st.big) {
        _sparkle(canvas, p, ringR * (0.035 + 0.02 * st.bright), paint);
      } else {
        canvas.drawCircle(p, ringR * 0.007 + 0.6, paint);
      }
    }
  }

  void _sparkle(Canvas canvas, Offset p, double r, Paint paint) {
    final path = Path();
    const n = 4;
    for (var i = 0; i < n * 2; i++) {
      final a = i * math.pi / n;
      final rr = i.isEven ? r : r * 0.18;
      final pt = p + Offset(rr * math.sin(a), -rr * math.cos(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    // Tia chéo nhỏ
    final d = r * 0.45;
    final thin = Paint()
      ..color = paint.color
      ..strokeWidth = 1;
    canvas.drawLine(p + Offset(-d, -d), p + Offset(d, d), thin);
    canvas.drawLine(p + Offset(-d, d), p + Offset(d, -d), thin);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.showStars != showStars || old.ringR != ringR;
}

class _Star {
  final double x, y, bright;
  final bool big;
  const _Star({required this.x, required this.y, required this.big, required this.bright});
}

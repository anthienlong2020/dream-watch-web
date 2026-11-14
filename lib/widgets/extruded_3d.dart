import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hiển thị một hình phẳng như một "khối" có độ dày khi xoay quanh trục Y.
///
/// Cách làm: chồng nhiều lớp của cùng một hình lệch nhau theo chiều sâu (Z).
/// Lớp trước và lớp sau giữ màu gốc, các lớp giữa tô tối hơn làm "thân".
/// Nhờ vậy khi xoay tới góc nghiêng 90° ta thấy một khối dày mang đúng hình
/// dáng con vật, thay vì chỉ còn một đường thẳng.
class Extruded3D extends StatelessWidget {
  /// Hình gốc (thường là SlotImageView).
  final Widget child;

  /// Cạnh khung vuông chứa hình (để tính phối cảnh và độ dày).
  final double size;

  /// Góc xoay quanh trục thẳng đứng, tính bằng radian. 0 = nhìn thẳng mặt trước.
  final double angleY;

  /// Độ dày so với kích thước hình (0.10 = dày 10%).
  final double depth;

  /// Số lớp chồng (càng nhiều càng mịn, nhưng tốn máy hơn).
  final int layers;

  const Extruded3D({
    super.key,
    required this.child,
    required this.size,
    required this.angleY,
    this.depth = 0.10,
    this.layers = 8,
  });

  static const ColorFilter _shade = ColorFilter.matrix(<double>[
    0.45, 0, 0, 0, 0, //
    0, 0.42, 0, 0, 0, //
    0, 0, 0.40, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final n = math.max(2, layers);
    final thick = size * depth;
    final perspective = 0.6 / math.max(size, 1);
    final cosA = math.cos(angleY);

    // Gần như nhìn thẳng thì chỉ cần vẽ lớp mặt trước cho nhẹ máy.
    // Đặt đúng chỗ của lớp mặt trước để không bị "giật" kích thước khi
    // chuyển qua lại giữa 1 lớp và nhiều lớp.
    if (cosA.abs() > 0.985) {
      final frontZ = cosA > 0 ? -thick / 2 : thick / 2;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, perspective)
          ..rotateY(angleY)
          ..translate(0.0, 0.0, frontZ),
        child: child,
      );
    }

    final items = <_Layer>[];
    for (var i = 0; i < n; i++) {
      final z = (i / (n - 1) - 0.5) * thick; // âm = phía trước
      final isFace = i == 0 || i == n - 1;
      items.add(_Layer(z: z, depthAfterTurn: z * cosA, isFace: isFace));
    }
    // Vẽ lớp xa trước, lớp gần sau (z lớn hơn = xa hơn).
    items.sort((a, b) => b.depthAfterTurn.compareTo(a.depthAfterTurn));

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final l in items)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspective)
              ..rotateY(angleY)
              ..translate(0.0, 0.0, l.z),
            child: l.isFace ? child : ColorFiltered(colorFilter: _shade, child: child),
          ),
      ],
    );
  }
}

class _Layer {
  final double z;
  final double depthAfterTurn;
  final bool isFace;
  _Layer({required this.z, required this.depthAfterTurn, required this.isFace});
}

/// Pha (0..1) của chu kỳ đung đưa, dùng chung cho góc xoay và độ phóng to
/// để hai chuyển động luôn khớp nhau.
double swingPhase(int epochMs, int periodMs) =>
    (epochMs % periodMs) / periodMs;

/// Góc đung đưa qua trái rồi qua phải tới góc 3/4 (kiểu góc máy điện ảnh),
/// không quay hết vòng. Dạng hình sin nên tự chậm lại ở hai đầu.
double swingAngleAt(double phase, {double maxAngle = 0.7}) =>
    maxAngle * math.sin(phase * 2 * math.pi);

/// Góc quay tròn 360° cho ảnh 3D: chậm lại khi quay mặt trước ra người xem,
/// nhanh hơn khi đi qua phía sau, để mặt trước được ngắm lâu hơn.
double spinAngleAt(double phase) =>
    2 * math.pi * phase - 0.85 * math.sin(2 * math.pi * phase);

/// Phóng to khớp với góc quay: to nhất khi nhìn thẳng mặt trước.
double spinZoomAt(double angle, {double amount = 0.12}) =>
    1.0 + amount * (1 + math.cos(angle)) / 2;

/// Phóng to khớp với đung đưa: to nhất khi nhìn thẳng, nhỏ lại ở góc 3/4.
double swingZoomAt(double phase, {double amount = 0.12}) =>
    1.0 + amount * (1 + math.cos(phase * 4 * math.pi)) / 2;

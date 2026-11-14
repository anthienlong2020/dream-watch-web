import 'package:flutter/material.dart';

import '../chibi/auto_chibi.dart';
import '../chibi/chibi3d.dart';
import '../chibi/chibi_painter.dart' show ChibiOutfit;
import '../three_d/body_type.dart';
import '../three_d/inflated_3d.dart';
import '../three_d/stick_figure.dart';
import '../models/clock_theme.dart';

/// Vẽ một hình của chủ đề trong khung vuông [size], theo kiểu [style]:
/// Standard (phẳng), 3D thổi phồng, Chibi 3D hoặc Người que.
/// Không truyền [style]: vẽ phẳng (riêng Chibi đã tạo thì vẽ 3D).
class SlotImageView extends StatelessWidget {
  final SlotImage image;
  final double size;

  /// Góc quay (cho các kiểu 3D và người que).
  final double yaw;

  /// Vẽ thật mịn (dùng cho hình to ở giữa).
  final bool hiDetail;

  /// Kiểu hiển thị; null = phẳng.
  final ImageStyle? style;

  /// Dáng: ốm / cân đối / mập.
  final BodyType body;

  const SlotImageView({
    super.key,
    required this.image,
    required this.size,
    this.yaw = 0,
    this.hiDetail = false,
    this.style,
    this.body = BodyType.canDoi,
  });

  static bool _hasFile(SlotImage img) => img.bytes != null || img.asset != null;

  /// Hình này với kiểu [style] có được vẽ thành khối 3D quay được không.
  static bool is3D(SlotImage img, ImageStyle? style) {
    switch (style) {
      case ImageStyle.thoiPhong:
      case ImageStyle.phuDieu:
        return _hasFile(img);
      case ImageStyle.chibi:
      case ImageStyle.heroNam:
      case ImageStyle.heroNu:
        return img.chibi != null || _hasFile(img);
      case null:
        return img.chibi != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flat = SlotImageView(image: image, size: size, style: ImageStyle.standard);
    final chibi = image.chibi;
    switch (style) {
      case null:
        if (chibi != null) {
          return Chibi3DView(spec: chibi, size: size, yaw: yaw, hiDetail: hiDetail, body: body);
        }
        break;
      case ImageStyle.standard:
        break;
      case ImageStyle.thoiPhong:
      case ImageStyle.phuDieu:
        if (_hasFile(image)) {
          return Inflated3DView(
            source: image.bytes ?? image.asset!,
            size: size,
            yaw: yaw,
            hiDetail: hiDetail,
            body: body,
            relief: style == ImageStyle.phuDieu,
            fallback: flat,
          );
        }
        break;
      case ImageStyle.chibi:
        if (chibi != null) {
          return Chibi3DView(spec: chibi, size: size, yaw: yaw, hiDetail: hiDetail, body: body);
        }
        if (_hasFile(image)) {
          return AutoChibiView(
            source: image.bytes ?? image.asset!,
            size: size,
            yaw: yaw,
            hiDetail: hiDetail,
            body: body,
            fallback: flat,
          );
        }
        break;
      case ImageStyle.heroNam:
      case ImageStyle.heroNu:
        final outfit = style == ImageStyle.heroNam ? ChibiOutfit.heroNam : ChibiOutfit.heroNu;
        if (chibi != null) {
          // Chibi người thật đã tạo: giữ khuôn mặt + màu, đổi sang thân anh hùng
          return Chibi3DView(
            spec: _heroSpec(chibi, outfit),
            size: size,
            yaw: yaw,
            hiDetail: hiDetail,
            body: body,
          );
        }
        if (_hasFile(image)) {
          return AutoChibiView(
            source: image.bytes ?? image.asset!,
            size: size,
            yaw: yaw,
            hiDetail: hiDetail,
            body: body,
            outfit: outfit,
            headScale: 1.7, // biểu tượng / con vật làm đầu: phóng to cho dễ nhìn
            fallback: flat,
          );
        }
        break;
      case ImageStyle.nguoiQue:
        return StickFigureView(head: flat, size: size, yaw: yaw, body: body);
    }
    return _flat();
  }

  static final Expando<Map<ChibiOutfit, ChibiSpec>> _heroCache = Expando();

  /// Bản sao của chibi đã tạo nhưng mặc đồ anh hùng (giữ nguyên đối tượng để
  /// không phải dựng lại mỗi khung hình).
  static ChibiSpec _heroSpec(ChibiSpec base, ChibiOutfit outfit) {
    final m = _heroCache[base] ??= {};
    return m[outfit] ??= ChibiSpec(
      face: base.face,
      outfit: outfit,
      outfitColor: base.outfitColor,
      skin: base.skin,
      hair: base.hair,
    );
  }

  Widget _flat() {
    final emoji = _EmojiView(emoji: image.emoji, size: size);
    Widget child;
    final bytes = image.bytes;
    final asset = image.asset;
    if (bytes != null) {
      child = Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => emoji,
      );
    } else if (asset != null) {
      child = Image.asset(
        asset,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => emoji,
      );
    } else {
      child = emoji;
    }
    return SizedBox(width: size, height: size, child: child);
  }
}

class _EmojiView extends StatelessWidget {
  final String emoji;
  final double size;
  const _EmojiView({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size * 0.72, height: 1.0),
      ),
    );
  }
}

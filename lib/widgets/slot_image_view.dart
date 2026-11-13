import 'package:flutter/material.dart';

import '../chibi/chibi3d.dart';
import '../models/clock_theme.dart';

/// Vẽ một hình của chủ đề trong khung vuông [size].
/// Ưu tiên: ảnh người dùng -> ảnh có sẵn -> emoji.
class SlotImageView extends StatelessWidget {
  final SlotImage image;
  final double size;

  /// Góc quay (chỉ dùng cho Chibi 3D).
  final double yaw;

  /// Vẽ Chibi 3D thật mịn (dùng cho hình to ở giữa).
  final bool hiDetail;

  const SlotImageView({
    super.key,
    required this.image,
    required this.size,
    this.yaw = 0,
    this.hiDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final chibi = image.chibi;
    if (chibi != null) {
      return Chibi3DView(spec: chibi, size: size, yaw: yaw, hiDetail: hiDetail);
    }
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

import 'package:flutter/material.dart';

import '../models/clock_theme.dart';

/// Vẽ một hình của chủ đề trong khung vuông [size].
/// Ưu tiên: ảnh người dùng -> ảnh có sẵn -> emoji.
class SlotImageView extends StatelessWidget {
  final SlotImage image;
  final double size;

  const SlotImageView({super.key, required this.image, required this.size});

  @override
  Widget build(BuildContext context) {
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

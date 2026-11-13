import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../utils/vn_format.dart';
import '../widgets/dream_clock.dart';
import '../widgets/tick_builder.dart';

const Color kCyan = Color(0xFF4FF3F0);

/// Màn hình chính: giờ số ở trên, mặt đồng hồ hình ảnh ở giữa, ngày ở dưới.
/// Chạm vào giờ hoặc ngày để ẩn/hiện (giống bản cũ).
class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            const _Background(),
            SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              final timeSize = (w * 0.13).clamp(28.0, 72.0);
              final dateSize = (w * 0.05).clamp(14.0, 28.0);
              return Column(
                children: [
                  const SizedBox(height: 16),
                  _Toggle(
                    visible: app.showTime,
                    onTap: () => app.update(() => app.showTime = !app.showTime),
                    child: TickBuilder(
                      builder: (_) => Text(
                        formatClock(DateTime.now()),
                        style: TextStyle(
                          color: kCyan,
                          fontSize: timeSize,
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DreamClock(
                        theme: app.theme,
                        showRoman: app.showRoman,
                        showStars: app.showStars,
                        inflate3d: app.inflate3d,
                        spin360: app.spin360,
                        bodyType: app.bodyType,
                        hourSpeed: app.hourSpeed,
                        minuteSpeed: app.minuteSpeed,
                        secondSpeed: app.secondSpeed,
                      ),
                    ),
                  ),
                  _Toggle(
                    visible: app.showDate,
                    onTap: () => app.update(() => app.showDate = !app.showDate),
                    child: TickBuilder(
                      interval: const Duration(seconds: 5),
                      builder: (_) => Text(
                        formatDateVn(DateTime.now()),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kCyan, fontSize: dateSize),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            ),
          ],
        );
      },
    );
  }
}

/// Hình nền do người dùng chọn, tự đổi mỗi N phút (mờ dần sang ảnh mới).
class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (app.backgrounds.isEmpty) return const SizedBox.shrink();
        return TickBuilder(
          interval: const Duration(seconds: 5),
          builder: (context) {
            final i = app.backgroundIndexAt(DateTime.now());
            if (i == null) return const SizedBox.shrink();
            return AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: SizedBox.expand(
                key: ValueKey('bg$i-${app.backgrounds.length}'),
                child: Image.memory(
                  app.backgrounds[i],
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  color: Colors.black.withAlpha((app.bgDim * 255).round()),
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Chạm để ẩn/hiện. Khi ẩn vẫn giữ chỗ để chạm lại là hiện.
class _Toggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  final Widget child;

  const _Toggle({required this.visible, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

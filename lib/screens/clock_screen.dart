import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/classic_dial.dart';
import '../widgets/mechanical_clock.dart';
import '../widgets/pendulum_clock.dart';

import '../services/app_state.dart';
import '../themes/event_background.dart';
import '../themes/theme_overlay.dart';
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
        // Pro chọn mặt cơ khí trong suốt (3D)
        if (app.showMech) {
          // Khung web 3D "nuốt" mọi cú chạm phía trên nó, nên khi màn hình
          // "Chạm để bắt đầu" hoặc báo thức đang hiện thì tạm ẩn khung 3D.
          if (!app.started || app.ringing != null) {
            return const ColoredBox(color: Color(0xFF0D0B14));
          }
          return ColoredBox(
            color: const Color(0xFF0D0B14),
            child: SafeArea(
              child: MechanicalClock(
                onTick: (even) {
                  if (app.tickTock && app.started) app.sound.tick(even);
                },
              ),
            ),
          );
        }
        // Bản Standard (hoặc Pro chọn mặt quả lắc): đồng hồ quả lắc số nhảy múa
        if (app.showPendulum) {
          return ColoredBox(
            color: Colors.black,
            child: SafeArea(
              child: TickBuilder(
                interval: const Duration(seconds: 30),
                builder: (_) => PendulumClock(
                  onTick: (even) {
                    if (app.tickTock && app.started) app.sound.tick(even);
                  },
                  // Standard: 12 số đứng yên + kim như đồng hồ thật; Pro: hình ảnh chuyển động
                  engravedNumbers: !app.isPro,
                  face: !app.isPro
                      ? const ClassicDial(showNumbers: false)
                      : DreamClock(
                    theme: app.theme,
                    showRoman: false,
                    showStars: false,
                    ringColor: const Color(0x00000000),
                    styles: app.isPro ? app.resolvedStyles : const [],
                    spin360: app.spin360,
                    bodies: app.isPro ? app.resolvedBodies : const [],
                    elements: app.isPro ? app.resolvedElements : const [],
                    effectsOn: app.isPro && app.effectsOn,
                    elemColors: app.isPro ? app.resolvedElemColors : const [],
                    hourSpeed: app.hourSpeed,
                    minuteSpeed: app.minuteSpeed,
                    secondSpeed: app.secondSpeed,
                  ),
                ),
              ),
            ),
          );
        }
        final season = app.activeSeason();
        final accent = season?.accent ?? kCyan;
        // Lễ hội có ảnh nền riêng → dùng ảnh nền đó (hợp màu với hiệu ứng)
        final eventBg = season != null && app.bgSource == 'event' && hasEventBackground(season.id);
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: eventBg
                  ? SizedBox.expand(key: ValueKey('ev${season.id}'), child: EventBackground(id: season.id))
                  : const _Background(key: ValueKey('user-bg')),
            ),
            if (!eventBg && season != null && season.night && app.seasonNightDim) const _NightSky(),
            // dây cờ, dây đèn treo phía trên: nằm dưới chữ giờ để không che số
            if (season != null) Positioned.fill(child: AnimatedThemeOverlay(theme: season, back: true)),
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
                          color: accent,
                          fontSize: timeSize,
                          fontWeight: FontWeight.w400,
                          shadows: _readable,
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
                        styles: app.resolvedStyles,
                        spin360: app.spin360,
                        bodies: app.resolvedBodies,
                        elements: app.resolvedElements,
                        effectsOn: app.effectsOn,
                        elemColors: app.resolvedElemColors,
                        ringColor: season == null
                            ? const Color(0x99FFFFFF)
                            : season.accent.withAlpha(190),
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
                        style: TextStyle(color: accent, fontSize: dateSize, shadows: _readable),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            ),
            // Theme mùa & lễ hội: hiệu ứng phủ lên trên, không nhận chạm
            if (season != null) Positioned.fill(child: AnimatedThemeOverlay(theme: season, back: false)),
          ],
        );
      },
    );
  }
}

/// Viền bóng tối mờ quanh chữ: đọc rõ trên mọi hình nền, sáng hay tối.
const List<Shadow> _readable = [
  Shadow(color: Color(0xCC000000), blurRadius: 6),
  Shadow(color: Color(0x99000000), blurRadius: 2, offset: Offset(0, 1)),
];

/// Độ sáng trung bình (0..1) của từng hình nền, tính 1 lần trên ảnh thu nhỏ.
final Expando<double> _lumCache = Expando('lum');
final Expando<bool> _lumPending = Expando('lumPending');

Future<void> _measure(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 24);
    final img = (await codec.getNextFrame()).image;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return;
    var sum = 0.0;
    final n = data.lengthInBytes ~/ 4;
    // chỉ xét nửa trên ảnh: bầu trời là nơi pháo hoa, cực quang xuất hiện
    final half = n ~/ 2;
    for (var i = 0; i < half; i++) {
      final r = data.getUint8(i * 4), g = data.getUint8(i * 4 + 1), b = data.getUint8(i * 4 + 2);
      sum += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
    }
    _lumCache[bytes] = half == 0 ? 0.5 : sum / half;
    app.update(() {});
  } catch (_) {
    _lumCache[bytes] = 0.5;
  }
}

/// Trời chạng vạng: nền sáng + lễ hội ban đêm → phủ màu xanh đêm trong suốt (đậm ở trên,
/// nhạt dần xuống dưới) để hiệu ứng ánh sáng nổi lên mà vẫn thấy hình nền.
class _NightSky extends StatelessWidget {
  const _NightSky();

  @override
  Widget build(BuildContext context) {
    return TickBuilder(
      interval: const Duration(seconds: 5),
      builder: (context) {
        double lum = 0.0; // không có hình nền → nền đen sẵn rồi
        if (app.backgrounds.isNotEmpty) {
          final i = app.backgroundIndexAt(DateTime.now());
          if (i != null) {
            final bytes = app.backgrounds[i];
            final v = _lumCache[bytes];
            if (v == null && _lumPending[bytes] != true) {
              _lumPending[bytes] = true;
              _measure(bytes);
            }
            lum = (v ?? 0.5) * (1 - app.bgDim);
          }
        }
        final k = ((lum - 0.25) / 0.4).clamp(0.0, 1.0);
        return IgnorePointer(
          child: AnimatedOpacity(
            opacity: k,
            duration: const Duration(seconds: 2),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xA60A1030), Color(0x660A1030), Color(0x400A1030)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

/// Hình nền do người dùng chọn, tự đổi mỗi N phút (mờ dần sang ảnh mới).
class _Background extends StatelessWidget {
  const _Background({super.key});

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

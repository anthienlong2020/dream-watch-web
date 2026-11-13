import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/clock_theme.dart';
import '../services/app_state.dart';
import '../widgets/slot_image_view.dart';
import '../widgets/tick_builder.dart';

/// Màn hình phủ khi báo thức / hẹn giờ đang reo.
class RingOverlay extends StatelessWidget {
  final RingInfo info;
  const RingOverlay({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final img = app.theme.slot(hourSlot(DateTime.now()));
    return Material(
      color: const Color(0xF20B1020),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TickBuilder(
                  interval: const Duration(milliseconds: 50),
                  builder: (_) {
                    final ms = DateTime.now().millisecondsSinceEpoch;
                    final wobble = math.sin(ms / 70) * 0.18;
                    final bounce = 1 + 0.08 * math.sin(ms / 160);
                    return Transform.rotate(
                      angle: wobble,
                      child: Transform.scale(
                        scale: bounce,
                        child: SlotImageView(image: img, size: 180),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(info.title,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300)),
                const SizedBox(height: 8),
                Text(info.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Colors.white70)),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (info.alarm != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                        onPressed: () => app.snoozeRing(minutes: 5),
                        icon: const Icon(Icons.snooze),
                        label: const Text('Báo lại 5 phút', style: TextStyle(fontSize: 17)),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      ),
                      onPressed: app.dismissRing,
                      icon: const Icon(Icons.alarm_off),
                      label: const Text('Tắt', style: TextStyle(fontSize: 17)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bản web: trình duyệt cần một lần chạm để cho phép phát âm thanh.
class StartOverlay extends StatelessWidget {
  const StartOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: app.startFromTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlotImageView(image: app.theme.slot(hourSlot(DateTime.now())), size: 140),
              const SizedBox(height: 24),
              const Text('Đồng hồ mộng mơ',
                  style: TextStyle(fontSize: 30, color: Color(0xFF4FF3F0))),
              const SizedBox(height: 12),
              const Text('Chạm vào màn hình để bắt đầu',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('(để bật âm thanh báo giờ và báo thức)',
                  style: TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}

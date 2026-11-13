import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import '../utils/vn_format.dart';
import '../widgets/tick_builder.dart';

/// Tab "Đếm giờ": gồm Hẹn giờ (đếm ngược) và Bấm giờ.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  String _mode = 'countdown';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'countdown',
                icon: Icon(Icons.hourglass_bottom),
                label: Text('Hẹn giờ')),
            ButtonSegment(
                value: 'stopwatch',
                icon: Icon(Icons.timer_outlined),
                label: Text('Bấm giờ')),
          ],
          selected: {_mode},
          onSelectionChanged: (v) => setState(() => _mode = v.first),
        ),
        centerTitle: true,
      ),
      body: _mode == 'countdown' ? const _Countdown() : const _StopwatchView(),
    );
  }
}

// =====================================================================
// Hẹn giờ
// =====================================================================

class _Countdown extends StatelessWidget {
  const _Countdown();

  static const _presets = [1, 3, 5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final running = app.timerRunning;
    final fresh = app.timerIsFresh;
    return LayoutBuilder(builder: (context, c) {
      final dial = (c.maxWidth * 0.7).clamp(160.0, 320.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: dial,
              height: dial,
              child: TickBuilder(
                builder: (_) {
                  final left = app.timerRemaining;
                  final total = app.timerTotal.inMilliseconds;
                  final frac = total == 0 ? 0.0 : left.inMilliseconds / total;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: frac.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: Colors.white12,
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: running ? null : () => _customDialog(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatDuration(left + const Duration(milliseconds: 999)),
                                style: TextStyle(
                                  fontSize: dial * 0.2,
                                  fontWeight: FontWeight.w300,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (!running)
                                const Text('Chạm để chỉnh',
                                    style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: fresh ? null : app.resetTimer,
                  icon: const Icon(Icons.replay),
                  label: const Text('Đặt lại'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                  onPressed: running ? app.pauseTimer : app.startTimer,
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(running ? 'Tạm dừng' : (fresh ? 'Bắt đầu' : 'Tiếp tục')),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (!running) ...[
              const Text('Chọn nhanh', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final m in _presets)
                    ChoiceChip(
                      label: Text(m >= 60 ? '${m ~/ 60} giờ' : '$m phút'),
                      selected: app.timerTotal == Duration(minutes: m),
                      onSelected: (_) => app.setTimer(Duration(minutes: m)),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _customDialog(BuildContext context) async {
    final t = app.timerTotal;
    final h = TextEditingController(text: '${t.inHours}');
    final m = TextEditingController(text: '${t.inMinutes % 60}');
    final s = TextEditingController(text: '${t.inSeconds % 60}');
    Widget field(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
          ),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt thời gian'),
        content: Row(
          children: [
            field(h, 'Giờ'),
            const SizedBox(width: 8),
            field(m, 'Phút'),
            const SizedBox(width: 8),
            field(s, 'Giây'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xong')),
        ],
      ),
    );
    if (ok == true) {
      final d = Duration(
        hours: int.tryParse(h.text) ?? 0,
        minutes: int.tryParse(m.text) ?? 0,
        seconds: int.tryParse(s.text) ?? 0,
      );
      app.setTimer(d);
    }
  }
}

// =====================================================================
// Bấm giờ
// =====================================================================

class _StopwatchView extends StatelessWidget {
  const _StopwatchView();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final sw = app.stopwatch;
    final running = sw.isRunning;
    final started = running || sw.elapsedMilliseconds > 0;
    return Column(
      children: [
        const SizedBox(height: 32),
        TickBuilder(
          interval: const Duration(milliseconds: 40),
          builder: (_) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatStopwatch(sw.elapsed),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: !started
                  ? null
                  : (running ? app.stopwatchLap : app.stopwatchReset),
              icon: Icon(running ? Icons.flag_outlined : Icons.replay),
              label: Text(running ? 'Vòng' : 'Đặt lại'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
              onPressed: app.stopwatchToggle,
              icon: Icon(running ? Icons.pause : Icons.play_arrow),
              label: Text(running ? 'Dừng' : (started ? 'Tiếp tục' : 'Bắt đầu')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: app.laps.length,
            itemBuilder: (context, i) {
              final lap = app.laps[i];
              final prev = i + 1 < app.laps.length ? app.laps[i + 1] : Duration.zero;
              final n = app.laps.length - i;
              return ListTile(
                dense: true,
                leading: Text('Vòng $n'),
                title: Text('+${formatStopwatch(lap - prev)}',
                    style: const TextStyle(color: Colors.white60)),
                trailing: Text(formatStopwatch(lap),
                    style: const TextStyle(fontSize: 16)),
              );
            },
          ),
        ),
      ],
    );
  }
}

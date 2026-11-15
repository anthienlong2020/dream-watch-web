import 'dart:async';

import 'package:flutter/material.dart';

import 'mech/mech_view.dart';

/// Mặt "Cơ khí trong suốt": bộ máy 3D (Three.js) chạy trong khung web riêng,
/// chỉ tải khi người dùng chọn mặt này nên bản Standard/Pro thường vẫn nhẹ.
/// Tiếng tích tắc phát từ app (theo cài đặt), đồng bộ với giây đồng hồ thật.
class MechanicalClock extends StatefulWidget {
  const MechanicalClock({super.key, required this.onTick});
  final void Function(bool even) onTick;

  @override
  State<MechanicalClock> createState() => _MechanicalClockState();
}

class _MechanicalClockState extends State<MechanicalClock> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    _t = Timer(Duration(milliseconds: 1000 - now.millisecond), () {
      if (!mounted) return;
      if (TickerMode.of(context)) widget.onTick(DateTime.now().second.isEven);
      _schedule();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => mechView();
}

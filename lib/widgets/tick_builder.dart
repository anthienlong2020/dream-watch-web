import 'dart:async';

import 'package:flutter/widgets.dart';

/// Vẽ lại [builder] đều đặn mỗi [interval] (dùng cho chữ giờ, đếm ngược...).
class TickBuilder extends StatefulWidget {
  final Duration interval;
  final WidgetBuilder builder;

  const TickBuilder({
    super.key,
    this.interval = const Duration(milliseconds: 200),
    required this.builder,
  });

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

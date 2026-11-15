import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const _ver = String.fromEnvironment('BUILD_VERSION', defaultValue: 'dev');
bool _registered = false;

/// true khi mặt cơ khí đang dùng bộ thoát Tourbillon (trang 3D tự phát tiếng
/// tích tắc nhanh 6 nhịp/giây) → app tạm tắt tiếng tích tắc 1 giây của mình.
final mechQuiet = ValueNotifier<bool>(false);

Widget mechView() {
  if (!_registered) {
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory('mech-clock', (int _) {
      final f = web.HTMLIFrameElement()
        ..src = 'movement/index.html?embed=1&v=${Uri.encodeComponent(_ver)}'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.background = 'transparent';
      return f;
    });
    web.window.addEventListener(
      'message',
      ((web.MessageEvent e) {
        final d = e.data.dartify();
        if (d is Map && d['mechEscapement'] != null) {
          mechQuiet.value = d['mechEscapement'] == 'tourbillon';
        }
      }).toJS,
    );
  }
  return const HtmlElementView(viewType: 'mech-clock');
}

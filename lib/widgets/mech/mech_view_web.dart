import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const _ver = String.fromEnvironment('BUILD_VERSION', defaultValue: 'dev');
bool _registered = false;

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
  }
  return const HtmlElementView(viewType: 'mech-clock');
}

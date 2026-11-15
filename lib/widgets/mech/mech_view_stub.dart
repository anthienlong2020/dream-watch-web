import 'package:flutter/material.dart';

final mechQuiet = ValueNotifier<bool>(false);

Widget mechView() => const Center(
      child: Text('Mặt cơ khí trong suốt chỉ có trên bản web', style: TextStyle(color: Colors.white70)),
    );

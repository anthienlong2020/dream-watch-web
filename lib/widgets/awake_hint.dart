import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/wake.dart';

/// Nhắc trên bản web: báo thức / hẹn giờ chỉ reo khi app đang mở và màn hình còn sáng.
/// Chỉ hiện khi chưa bật "Giữ màn hình luôn sáng" hoặc máy không hỗ trợ.
class AwakeHint extends StatelessWidget {
  const AwakeHint({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final supported = wakeSupported();
        final onBattery =
            supported && app.keepAwake && app.keepAwakeOnlyCharging && app.charging == false;
        if (supported && app.keepAwake && !onBattery) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  onBattery
                      ? 'Máy đang chạy bằng pin nên màn hình sẽ tự tắt cho đỡ hao pin. '
                          'Muốn báo thức reo, hãy cắm sạc và để app mở như đồng hồ để bàn.'
                      : supported
                      ? 'Báo thức chỉ reo khi app đang mở và màn hình còn sáng. '
                          'Bật "Giữ màn hình luôn sáng" rồi đặt máy như đồng hồ để bàn nhé.'
                      : 'Báo thức chỉ reo khi app đang mở và màn hình còn sáng. '
                          'Máy này chưa tự giữ sáng được, hãy chỉnh "Tự khoá màn hình" '
                          'của máy thành "Không bao giờ".',
                  style: TextStyle(color: cs.onSecondaryContainer, fontSize: 13),
                ),
              ),
              if (supported && !onBattery)
                TextButton(
                  onPressed: () => app.setKeepAwake(true),
                  child: const Text('Bật'),
                ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import '../services/install.dart';

const String kAppLink = 'https://anthienlong2020.github.io/dream-watch-web/';

/// Bấm "Cài vào màn hình chính": Chrome cho cài thẳng thì hiện hộp Cài đặt của
/// trình duyệt; không thì mở bảng hướng dẫn đúng loại máy.
Future<void> startInstall(BuildContext context) async {
  if (installState() == 'ready') {
    final r = await promptInstall();
    if (!context.mounted) return;
    if (r == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã cài! Tìm biểu tượng Đồng hồ mộng mơ trên màn hình chính nhé.'),
      ));
      return;
    }
    if (r == 'dismissed') return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _Guide(platform: installPlatform()),
  );
}

/// Nút nhỏ góc trên phải màn hình đồng hồ. Tự ẩn khi đã cài, hoặc khi bấm ×.
class InstallChip extends StatefulWidget {
  const InstallChip({super.key});

  @override
  State<InstallChip> createState() => _InstallChipState();
}

class _InstallChipState extends State<InstallChip> {
  Timer? _poll;
  String _state = installState();

  @override
  void initState() {
    super.initState();
    // Chrome báo "cài được" sau vài giây → kiểm tra lại một lúc
    var n = 0;
    _poll = Timer.periodic(const Duration(seconds: 2), (t) {
      final s = installState();
      if (s != _state && mounted) setState(() => _state = s);
      if (++n > 30) t.cancel();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _chip(context));

  Widget _chip(BuildContext context) {
    if (_state == 'installed' || _state == 'unsupported' || app.installChipHidden || !app.started) {
      return const Positioned(top: 0, right: 0, child: SizedBox.shrink());
    }
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 8,
      child: Material(
        color: const Color(0xCC1B1630),
        shape: const StadiumBorder(side: BorderSide(color: Color(0x66FFD54F))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              customBorder: const StadiumBorder(),
              onTap: () async {
                await startInstall(context);
                if (mounted) setState(() => _state = installState());
              },
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 7, 4, 7),
                child: Text('📲 Cài app', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => app.update(() => app.installChipHidden = true),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 7, 10, 7),
                child: Icon(Icons.close, size: 16, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ ở đầu trang Cài đặt (luôn có, kể cả khi đã bấm × ở màn hình đồng hồ).
class InstallCard extends StatelessWidget {
  const InstallCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = installState();
    if (s == 'installed' || s == 'unsupported') return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Text('📲', style: TextStyle(fontSize: 28)),
        title: const Text('Cài vào màn hình chính'),
        subtitle: const Text('Mở như app thật, toàn màn hình, không cần vào kho ứng dụng'),
        trailing: FilledButton(onPressed: () => startInstall(context), child: const Text('Cài')),
      ),
    );
  }
}

class _Step {
  final String text;
  final IconData? icon;
  const _Step(this.text, [this.icon]);
}

/// Bảng hướng dẫn từng bước theo loại máy.
class _Guide extends StatelessWidget {
  final String platform;
  const _Guide({required this.platform});

  @override
  Widget build(BuildContext context) {
    final (title, steps) = switch (platform) {
      'inapp' => (
          'Mở bằng trình duyệt trước',
          const [
            _Step('Bạn đang xem trong Facebook / TikTok / Zalo — ở đây không cài được.'),
            _Step('Bấm nút ⋯ (hoặc ⋮) ở góc màn hình.', Icons.more_horiz),
            _Step('Chọn "Mở bằng trình duyệt" (Chrome hoặc Safari).', Icons.open_in_browser),
            _Step('Trong trình duyệt, bấm lại nút "📲 Cài app".'),
          ]
        ),
      'ios' => (
          'Cài trên iPhone / iPad',
          const [
            _Step('Bấm nút Chia sẻ (ô vuông có mũi tên lên). Trên iOS mới, nút này có thể nằm trong nút ••• ở thanh dưới.',
                Icons.ios_share),
            _Step('Kéo xuống, chọn "Thêm vào MH chính".', Icons.add_box_outlined),
            _Step('Bấm "Thêm" ở góc trên.', Icons.check),
          ]
        ),
      'android' => (
          'Cài trên Android',
          const [
            _Step('Bấm nút ⋮ ở góc trên bên phải Chrome.', Icons.more_vert),
            _Step('Kéo menu xuống, chọn "Cài đặt và tạo lối tắt" (máy cũ: "Thêm vào màn hình chính").',
                Icons.add_to_home_screen),
            _Step('Bấm "Cài đặt" hoặc "Thêm".', Icons.check),
          ]
        ),
      _ => (
          'Cài trên máy tính',
          const [
            _Step('Mở link bằng Chrome hoặc Edge.', Icons.language),
            _Step('Bấm biểu tượng cài đặt ở cuối thanh địa chỉ, hoặc menu ⋮ → "Truyền, lưu và chia sẻ" → "Cài đặt trang".',
                Icons.install_desktop),
            _Step('Bấm "Cài đặt".', Icons.check),
          ]
        ),
    };
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.primary,
                    child: Text('${i + 1}', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i].text, style: const TextStyle(fontSize: 16))),
                  if (steps[i].icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(steps[i].icon, color: cs.primary),
                  ],
                ],
              ),
            ),
          if (platform == 'inapp')
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: kAppLink));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Đã chép link, dán vào Chrome/Safari nhé.')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Chép link'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đã hiểu')),
          ),
        ],
      ),
    );
  }
}

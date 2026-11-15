import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/clock_theme.dart';
import '../services/app_state.dart';
import '../effects/element_effect.dart';
import '../three_d/body_type.dart';
import '../services/file_saver.dart';
import '../services/speech.dart';
import '../services/voice_recorder.dart';
import '../themes/event_background.dart';
import '../themes/season_theme.dart';
import '../utils/image_utils.dart';
import '../widgets/slot_image_view.dart';
import 'chibi_maker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      // Mỗi phần tự lắng nghe [app] để cập nhật khi cài đặt thay đổi.
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: [
          const _Header('Phiên bản'),
          const _EditionCard(),
          if (!app.isPro) ...const [
            _Header('Âm báo mỗi giờ'),
            _ChimeSettings(),
            SizedBox(height: 16),
            Center(
              child: Text('Phiên bản: $kBuildVersion',
                  style: TextStyle(fontSize: 12, color: Colors.white38)),
            ),
          ] else ...const [
          _Header('Bộ cấu hình của tôi'),
          _PresetSettings(),
          _Header('Theme mùa & lễ hội'),
          _SeasonSettings(),
          _Header('Chủ đề hình ảnh'),
          _ThemePicker(),
          SizedBox(height: 8),
          _CustomImagesEditor(),
          _Header('Kiểu, dáng & hệ từng hình'),
          _StyleSettings(),
          _Header('Âm báo mỗi giờ'),
          _ChimeSettings(),
          _Header('Tốc độ chuyển động'),
          _SpeedSettings(),
          _Header('Hình nền'),
          _BackgroundSettings(),
          _Header('Hiển thị'),
          _DisplaySettings(),
          SizedBox(height: 16),
          Center(
            child: Text('Phiên bản: $kBuildVersion',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
          ),
          ],
        ],
        ),
      ),
    );
  }
}

/// Mã phiên bản (gắn lúc build trên GitHub) để biết điện thoại đã tải bản mới chưa.
const String kBuildVersion = String.fromEnvironment('BUILD_VERSION', defaultValue: 'thử nghiệm');

/// Thẻ phiên bản: Standard / Pro, nhập mã mở khoá, chọn mặt đồng hồ (Pro).
class _EditionCard extends StatefulWidget {
  const _EditionCard();

  @override
  State<_EditionCard> createState() => _EditionCardState();
}

class _EditionCardState extends State<_EditionCard> {
  Future<void> _enablePro() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bật bản Pro (miễn phí)'),
        content: const Text(
            'Bản Pro mở toàn bộ tính năng: ảnh riêng, 3D, mặt đồng hồ cơ khí trong suốt, hiệu ứng, lễ hội, hình nền, giọng đọc…\n\n'
            '⚠️ Lưu ý: bản Pro dùng nhiều hiệu ứng và lưu ảnh riêng trong máy nên chiếm nhiều dung lượng hơn, '
            'tốn pin hơn và cần điện thoại khoẻ hơn. Máy yếu có thể bị giật; khi đó có thể quay về bản Standard '
            'bất cứ lúc nào, ảnh và cài đặt vẫn được giữ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bật Pro')),
        ],
      ),
    );
    if (ok == true) {
      app.enablePro();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('⭐ Đã bật bản Pro. Chúc bạn tạo chiếc đồng hồ mộng mơ của riêng mình!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: app, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    if (app.isPro) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⭐ Đang dùng bản Pro (miễn phí)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Mặt đồng hồ:'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'dream', label: Text('Mộng mơ')),
                  ButtonSegment(value: 'pendulum', label: Text('Quả lắc')),
                  ButtonSegment(value: 'mech', label: Text('Cơ khí')),
                ],
                selected: {const ['pendulum', 'mech'].contains(app.faceStyle) ? app.faceStyle : 'dream'},
                showSelectedIcon: false,
                onSelectionChanged: (v) => app.update(() => app.faceStyle = v.first),
              ),
              const SizedBox(height: 4),
              Text(
                switch (app.faceStyle) {
                  'pendulum' => 'Đồng hồ quả lắc, mặt số là hình ảnh của tôi.',
                  'mech' => 'Bộ máy 3D trong suốt: bánh răng, dây cót, quả lắc chạy thật. Xoay, phóng to, chạm vào bộ phận để xem tên. Nặng máy nhất.',
                  _ => 'Đồng hồ hình ảnh mộng mơ, đủ hiệu ứng và lễ hội.',
                },
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: app.backToStandard,
                  child: const Text('Quay về bản Standard (nhẹ máy hơn)', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn đang dùng bản Standard (miễn phí)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Đồng hồ quả lắc: 12 con số xoay, nhảy bậc thang như bản mộng mơ, kèm chuông Big Ben.',
                style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 10),
            const Text('⭐ Bản Pro (miễn phí) có thêm:', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text(
              '• 12 hình ảnh của chính bạn thay cho con số\n'
              '• Biến ảnh thành 3D, pha lê, siêu anh hùng, bọc lửa, nước, sấm sét…\n'
              '• Gần 30 lễ hội tự đổi theo ngày, ảnh nền riêng từng lễ\n'
              '• Giọng đọc "Bây giờ là 5 giờ chiều", nhiều kiểu chuông\n'
              '• Lời nhắc bằng chữ hoặc giọng tự ghi âm\n'
              '• Hình nền của bạn, lưu & chia sẻ bộ cấu hình',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text('Bản Pro cũng miễn phí, chỉ nặng máy hơn vì nhiều hiệu ứng và ảnh riêng.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60)),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _enablePro, icon: const Icon(Icons.star), label: const Text('Bật bản Pro (miễn phí)')),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

// =====================================================================
// Chọn chủ đề
// =====================================================================

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    // Danh sách: Chuẩn (Standard), Ảnh của tôi, rồi các bộ mở từ file cấu hình
    final ids = ['khung_long', 'tu_chon', for (final n in app.imageSets) 'set:$n'];
    String label(String id) => switch (id) {
          'khung_long' => '⭐ Chuẩn (Standard)',
          'tu_chon' => '🖼️ Ảnh của tôi',
          _ => '📁 ${id.substring(4)}',
        };
    final current = ids.contains(app.themeId) ? app.themeId : 'khung_long';
    final t = app.themeOf(current);
    final setName = current.startsWith('set:') ? current.substring(4) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: current,
              items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(label(id)))],
              onChanged: (v) => app.update(() => app.themeId = v ?? 'khung_long'),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 1; i <= 12; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: SlotImageView(image: t.slot(i % 12), size: 34),
                    ),
                ],
              ),
            ),
            if (setName != null)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Chép sang Ảnh của tôi để sửa'),
                    onPressed: () async {
                      final ok = await app.copySetToCustom(setName);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Không lưu được: bộ nhớ trình duyệt đầy, hãy bớt ảnh nền.')));
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xoá khỏi danh sách'),
                    onPressed: () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Xoá bộ "$setName"?'),
                          content: const Text('Chỉ xoá khỏi app. File .dreamwatch trên máy vẫn còn, '
                              'mở lại lúc nào cũng được.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
                          ],
                        ),
                      );
                      if (yes == true) await app.deleteImageSet(setName);
                    },
                  ),
                ],
              ),
            const Text(
              'Mở file cấu hình (.dreamwatch) ở mục "Bộ cấu hình" bên dưới thì bộ ảnh trong file '
              'tự thêm vào danh sách này.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Ảnh của tôi: 12 ô ảnh
// =====================================================================

class _CustomImagesEditor extends StatefulWidget {
  const _CustomImagesEditor();

  @override
  State<_CustomImagesEditor> createState() => _CustomImagesEditorState();
}

class _CustomImagesEditorState extends State<_CustomImagesEditor> {
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<List<PlatformFile>> _pick({required bool many}) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: many,
      withData: true,
    );
    return res?.files ?? const [];
  }

  Future<void> _pickOne(int index) async {
    final files = await _pick(many: false);
    if (files.isEmpty || files.first.bytes == null) return;
    setState(() => _busy = true);
    try {
      final small = await shrinkImage(files.first.bytes!);
      final ok = await app.setCustomImage(index, small);
      if (!ok) _toast('Không lưu được ảnh (bộ nhớ đầy?). Hãy thử ảnh nhỏ hơn.');
    } catch (_) {
      _toast('Không đọc được ảnh này. Hãy thử file PNG hoặc JPG khác.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Chạm vào một ô: chọn ảnh thường hoặc tạo Chibi từ ảnh người.
  Future<void> _slotMenu(int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Vị trí ${kRoman[index].toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Chọn ảnh'),
              subtitle: const Text('Con vật, đồ vật... (PNG nền trong suốt đẹp nhất)'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural),
              title: const Text('Tạo Chibi từ ảnh người'),
              subtitle: const Text('Ghép khuôn mặt vào nhân vật đầu to thân nhỏ'),
              onTap: () => Navigator.pop(ctx, 'chibi'),
            ),
            if (app.customImages[index] != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xoá ảnh ở vị trí này'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'image':
        await _pickOne(index);
        break;
      case 'clear':
        await app.setCustomImage(index, null);
        break;
      case 'chibi':
        final res = await Navigator.push<ChibiResult>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChibiMakerScreen(slotLabel: kRoman[index].toUpperCase()),
          ),
        );
        if (res != null) {
          final ok = await app.setCustomImage(index, res.png, chibi: res.spec);
          if (!ok) _toast('Không lưu được (bộ nhớ đầy?).');
        }
        break;
    }
  }

  /// Chọn nhiều ảnh: ảnh có số 1..12 trong tên sẽ vào đúng vị trí đó,
  /// các ảnh còn lại lấp vào ô trống theo thứ tự I, II, ... XII.
  Future<void> _pickMany() async {
    final files = await _pick(many: true);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = <int, Uint8List>{};
      final leftovers = <PlatformFile>[];
      for (final f in files) {
        if (f.bytes == null) continue;
        final n = numberFromFileName(f.name);
        if (n != null && !result.containsKey(n % 12)) {
          result[n % 12] = await shrinkImage(f.bytes!);
        } else {
          leftovers.add(f);
        }
      }
      leftovers.sort((x, y) => x.name.compareTo(y.name));
      const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
      var k = 0;
      for (final slot in order) {
        if (k >= leftovers.length) break;
        if (result.containsKey(slot)) continue;
        result[slot] = await shrinkImage(leftovers[k].bytes!);
        k++;
      }
      final ok = await app.setManyCustomImages(result);
      _toast(ok
          ? 'Đã thêm ${result.length} ảnh.'
          : 'Không lưu được hết ảnh (bộ nhớ đầy?). Hãy dùng ảnh nhỏ hơn.');
    } catch (_) {
      _toast('Có ảnh không đọc được. Hãy dùng PNG hoặc JPG.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final theme = buildCustomTheme(app.customImages, app.customChibi);
    const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ảnh của tôi', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Chạm vào một ô để chọn ảnh hoặc tạo Chibi từ ảnh người, giữ lâu để xoá. '
              'Mẹo: đặt tên file 1.png ... 12.png rồi bấm "Chọn nhiều ảnh" để '
              'tự xếp đúng vị trí. Ảnh PNG nền trong suốt nhìn đẹp nhất.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.8,
              children: [
                for (final i in order)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _busy ? null : () => _slotMenu(i),
                    onLongPress: app.customImages[i] == null
                        ? null
                        : () => app.setCustomImage(i, null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: app.customImages[i] != null
                              ? Colors.tealAccent.withAlpha(140)
                              : Colors.white24,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: LayoutBuilder(
                                builder: (_, c) => SlotImageView(
                                  image: theme.slot(i),
                                  size: c.biggest.shortestSide,
                                ),
                              ),
                            ),
                          ),
                          Text(kRoman[i].toUpperCase(),
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _pickMany,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn nhiều ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || app.customImages.every((b) => b == null)
                      ? null
                      : () async {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xoá hết ảnh của tôi?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Không')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xoá')),
                              ],
                            ),
                          );
                          if (yes == true) await app.clearCustomImages();
                        },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Xoá hết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Âm báo mỗi giờ
// =====================================================================

/// Ghi âm giọng báo giờ: 1 câu chung + câu riêng cho từng giờ (giống đồng hồ biết gọi tên bạn).
class _HourRecorder extends StatefulWidget {
  const _HourRecorder();

  @override
  State<_HourRecorder> createState() => _HourRecorderState();
}

class _HourRecorderState extends State<_HourRecorder> {
  String? _rec; // ô đang ghi

  @override
  void dispose() {
    if (_rec != null) stopVoiceRecording();
    super.dispose();
  }

  static String _label(String slot) {
    if (slot == 'chung') return 'Câu chung (giờ nào chưa ghi riêng)';
    final h = int.parse(slot);
    return '${h.toString().padLeft(2, '0')}:00 · ${hourSentence(h).replaceFirst('Bây giờ là ', '')}';
  }

  Future<void> _toggle(String slot) async {
    if (_rec == slot) {
      final r = await stopVoiceRecording();
      setState(() => _rec = null);
      if (r != null && r.$1.isNotEmpty) await app.saveHourRecording(slot, r.$1, r.$2);
      return;
    }
    if (_rec != null) return; // đang ghi ô khác
    final ok = await startVoiceRecording();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không mở được micro. Hãy cho phép trình duyệt dùng micro rồi thử lại.')));
      }
      return;
    }
    setState(() => _rec = slot);
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _rec == slot) _toggle(slot);
    });
  }

  Widget _row(String slot) {
    final has = app.hourRecs.contains(slot);
    final recording = _rec == slot;
    return Row(
      children: [
        Icon(has ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18, color: has ? Colors.greenAccent : Colors.white38),
        const SizedBox(width: 8),
        Expanded(child: Text(_label(slot), style: const TextStyle(fontSize: 13.5))),
        IconButton(
          tooltip: recording ? 'Dừng ghi' : 'Ghi âm',
          onPressed: () => _toggle(slot),
          icon: Icon(recording ? Icons.stop_circle : Icons.mic, color: recording ? Colors.redAccent : null),
        ),
        if (has && !recording) ...[
          IconButton(tooltip: 'Nghe lại', onPressed: () => app.playHourRecording(slot), icon: const Icon(Icons.play_circle_outline)),
          IconButton(tooltip: 'Xoá', onPressed: () => app.deleteHourRecording(slot), icon: const Icon(Icons.delete_outline)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi giọng người thương báo giờ 💕 Mỗi câu tối đa 15 giây. Đến giờ, app phát câu của giờ đó; '
              'giờ nào chưa ghi thì phát câu chung.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
            if (_rec != null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('🔴 Đang ghi… bấm ⏹ để dừng', style: TextStyle(color: Colors.redAccent)),
              ),
            _row('chung'),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Câu riêng từng giờ (${app.hourRecs.where((s) => s != 'chung').length}/24 đã ghi)',
                  style: const TextStyle(fontSize: 14)),
              children: [for (var h = 0; h < 24; h++) _row('$h')],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thử nhanh giọng nam / nữ và chọn giọng máy cho từng loại.
class _VoicePicker extends StatefulWidget {
  const _VoicePicker();

  @override
  State<_VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<_VoicePicker> {
  List<String> _names = const [];

  @override
  void initState() {
    super.initState();
    warmUpVoices();
    _load();
    // danh sách giọng của trình duyệt có khi nạp chậm
    Future.delayed(const Duration(milliseconds: 800), _load);
  }

  void _load() {
    if (!mounted) return;
    setState(() => _names = viVoiceNames());
  }

  Widget _row(String label, String v, String current, void Function(String) set) {
    final value = _names.contains(current) ? current : '';
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: [
              const DropdownMenuItem(value: '', child: Text('Tự động')),
              for (final n in _names) DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (x) => app.update(() => set(x ?? '')),
          ),
        ),
        IconButton(
          tooltip: 'Thử $label',
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () => app.testVoice(v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
        child: Column(
          children: [
            _row('Giọng nam', 'nam', app.voiceNameNam, (x) => app.voiceNameNam = x),
            _row('Giọng nữ', 'nu', app.voiceNameNu, (x) => app.voiceNameNu = x),
            if (_names.length <= 1)
              const Text(
                'Máy chỉ có 1 giọng tiếng Việt nên app đổi cao độ để ra giọng nam / nữ. '
                'Muốn có thêm giọng: Cài đặt điện thoại → Chuyển văn bản thành giọng nói → '
                'Công cụ của Google → Tiếng Việt → chọn giọng khác.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChimeSettings extends StatelessWidget {
  const _ChimeSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final on = app.chimeEnabled;
    // Bản Standard: luôn là chuông Big Ben, không giọng đọc
    final mode = app.isPro ? app.chimeMode : 'westminster';
    final hours = List<int>.generate(24, (i) => i);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Báo giờ'),
            subtitle: const Text('Phát âm thanh khi tròn giờ'),
            value: on,
            onChanged: (v) => app.update(() => app.chimeEnabled = v),
          ),
          if (!app.isPro)
            const ListTile(
              leading: Text('🔔', style: TextStyle(fontSize: 22)),
              title: Text('Chuông Big Ben (Westminster)'),
              subtitle: Text('Bản Pro có thêm giai điệu khác và giọng đọc "Bây giờ là… giờ"'),
            ),
          if (app.isPro)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButton<String>(
              isExpanded: true,
              value: const ['westminster', 'dem', 'chuong', 'ca_hai', 'giong'].contains(app.chimeMode)
                  ? app.chimeMode
                  : 'dem',
              items: const [
                DropdownMenuItem(value: 'westminster', child: Text('🔔 Chuông nhà thờ Westminster (Big Ben)')),
                DropdownMenuItem(value: 'dem', child: Text('Đánh số tiếng theo giờ')),
                DropdownMenuItem(value: 'chuong', child: Text('Giai điệu ngắn')),
                DropdownMenuItem(value: 'ca_hai', child: Text('Giai điệu ngắn + đánh số tiếng')),
                DropdownMenuItem(value: 'giong', child: Text('🗣️ Chỉ đọc giờ bằng giọng nói')),
              ],
              onChanged: on ? (v) => app.update(() => app.chimeMode = v ?? app.chimeMode) : null,
            ),
          ),
          if (mode != 'chuong' && mode != 'giong')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Text('Chuông đánh giờ:'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: app.hourBell == 'cao' ? 'cao' : 'chuan',
                      items: const [
                        DropdownMenuItem(value: 'chuan', child: Text('Chuẩn – boong boong (trầm, êm)')),
                        DropdownMenuItem(value: 'cao', child: Text('Coong coong (cao, trong)')),
                      ],
                      onChanged: on ? (v) => app.update(() => app.hourBell = v ?? 'chuan') : null,
                    ),
                  ),
                ],
              ),
            ),
          if (app.isPro)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                const Text('Đọc giờ:'),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'tat', label: Text('Tắt')),
                      ButtonSegment(value: 'nam', label: Text('Giọng nam')),
                      ButtonSegment(value: 'nu', label: Text('Giọng nữ')),
                      ButtonSegment(value: 'ghi', label: Text('🎙️ Tự ghi')),
                    ],
                    selected: {app.hourVoice},
                    showSelectedIcon: false,
                    onSelectionChanged: on ? (v) => app.update(() => app.hourVoice = v.first) : null,
                  ),
                ),
              ],
            ),
          ),
          if (app.isPro && app.hourVoice != 'ghi') const _VoicePicker(),
          if (app.isPro && app.hourVoice == 'ghi') const _HourRecorder(),
          if (app.isPro)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Đọc "Bây giờ là 5 giờ chiều" sau tiếng chuông. Dùng giọng tiếng Việt có sẵn trong máy; '
              'nếu máy chỉ có 1 giọng thì app chỉnh cao độ cho ra giọng nam / nữ.',
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              mode == 'westminster'
                  ? 'Như đồng hồ quả lắc xưa: tròn giờ ngân đủ 4 câu "téng tèng teng tèng…", '
                      'rồi chuông lớn đánh số tiếng theo giờ (3 giờ đánh 3 tiếng, 12 giờ đánh 12 tiếng).'
                  : '"Đánh số tiếng": 3 giờ đánh 3 tiếng, 12 giờ đánh 12 tiếng, như đồng hồ quả lắc.',
              style: const TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
          ),
          if (mode == 'westminster')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text('Nghe thử:', style: TextStyle(color: Colors.white70)),
                  for (final (q, label) in const [(1, '15 phút'), (2, '30 phút'), (3, '45 phút')])
                    ActionChip(label: Text(label), onPressed: () => app.sound.playWestminster(q)),
                  ActionChip(
                    label: const Text('Tròn giờ'),
                    onPressed: () => app.playHourChime(DateTime.now().hour),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            title: Text(mode == 'westminster' ? 'Báo cả 15, 30, 45 phút' : 'Báo cả nửa giờ'),
            subtitle: Text(mode == 'westminster'
                ? 'Mỗi 15 phút ngân thêm 1 câu: :15 một câu, :30 hai câu, :45 ba câu'
                : 'Đánh 1 tiếng lúc :30'),
            value: app.chimeHalfHour,
            onChanged: on ? (v) => app.update(() => app.chimeHalfHour = v) : null,
          ),
          SwitchListTile(
            title: const Text('Giờ yên lặng'),
            subtitle: Text('Không báo giờ từ ${app.quietStart}h đến ${app.quietEnd}h'),
            value: app.quietEnabled,
            onChanged: on ? (v) => app.update(() => app.quietEnabled = v) : null,
          ),
          if (app.quietEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Từ'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: app.quietStart,
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(value: h, child: Text('$h giờ')),
                    ],
                    onChanged: on
                        ? (v) => app.update(() => app.quietStart = v ?? app.quietStart)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Text('đến'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: app.quietEnd,
                    items: [
                      for (final h in hours)
                        DropdownMenuItem(value: h, child: Text('$h giờ')),
                    ],
                    onChanged: on
                        ? (v) => app.update(() => app.quietEnd = v ?? app.quietEnd)
                        : null,
                  ),
                ],
              ),
            ),
          SwitchListTile(
            title: const Text('Tiếng tích tắc của quả lắc'),
            subtitle: const Text('Mỗi giây kêu "tích – tắc" nhẹ như đồng hồ thật (mặt đồng hồ quả lắc)'),
            value: app.tickTock,
            onChanged: (v) => app.update(() => app.tickTock = v),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: Slider(
              value: app.volume,
              onChanged: (v) => app.update(() => app.volume = v),
            ),
            trailing: TextButton(
              onPressed: () => app.playHourChime(DateTime.now().hour),
              child: const Text('Nghe thử'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Hiển thị
// =====================================================================

class _DisplaySettings extends StatelessWidget {
  const _DisplaySettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Hiện giờ dạng số'),
            value: app.showTime,
            onChanged: (v) => app.update(() => app.showTime = v),
          ),
          SwitchListTile(
            title: const Text('Hiện ngày tháng'),
            value: app.showDate,
            onChanged: (v) => app.update(() => app.showDate = v),
          ),
          SwitchListTile(
            title: const Text('Hiện số La Mã'),
            value: app.showRoman,
            onChanged: (v) => app.update(() => app.showRoman = v),
          ),
          SwitchListTile(
            title: const Text('Ảnh 3D quay tròn 360°'),
            subtitle: const Text(
                'Ảnh giờ và ảnh giữa (Chibi 3D, ảnh thổi phồng) quay hết vòng. '
                'Tắt thì chỉ đung đưa trái - phải.'),
            value: app.spin360,
            onChanged: (v) => app.update(() => app.spin360 = v),
          ),
          SwitchListTile(
            title: const Text('Hiện ngôi sao'),
            value: app.showStars,
            onChanged: (v) => app.update(() => app.showStars = v),
          ),
          SwitchListTile(
            title: const Text('Giữ màn hình luôn sáng'),
            subtitle: const Text('Để báo thức và báo giờ hoạt động ổn định'),
            value: app.keepAwake,
            onChanged: app.setKeepAwake,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Tốc độ chuyển động
// =====================================================================

const List<double> _speedSteps = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0];

String _speedLabel(double v) {
  if (v <= 0.25) return 'Rất chậm';
  if (v <= 0.5) return 'Chậm';
  if (v <= 0.75) return 'Hơi chậm';
  if (v <= 1.0) return 'Vừa';
  if (v <= 1.5) return 'Hơi nhanh';
  return 'Nhanh';
}

class _SpeedSettings extends StatelessWidget {
  const _SpeedSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _speedRow('Giờ', 'Ảnh giờ và ảnh giữa đung đưa', app.hourSpeed,
                  (v) => app.update(() => app.hourSpeed = v)),
              _speedRow('Phút', 'Ảnh phút nhảy bậc thang', app.minuteSpeed,
                  (v) => app.update(() => app.minuteSpeed = v)),
              _speedRow('Giây', 'Kim giây lướt vòng (vẫn đúng 1 bước/giây)',
                  app.secondSpeed, (v) => app.update(() => app.secondSpeed = v)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => app.update(() {
                    app.hourSpeed = 1.0;
                    app.minuteSpeed = 1.0;
                    app.secondSpeed = 1.0;
                  }),
                  child: const Text('Về mặc định'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedRow(String title, String hint, double value,
      ValueChanged<double> onChanged) {
    var idx = _speedSteps.indexWhere((x) => (x - value).abs() < 0.01);
    if (idx < 0) idx = 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              const Spacer(),
              Text(_speedLabel(_speedSteps[idx]),
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(hint, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          Slider(
            value: idx.toDouble(),
            min: 0,
            max: (_speedSteps.length - 1).toDouble(),
            divisions: _speedSteps.length - 1,
            label: _speedLabel(_speedSteps[idx]),
            onChanged: (v) => onChanged(_speedSteps[v.round()]),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Hình nền
// =====================================================================

class _BackgroundSettings extends StatefulWidget {
  const _BackgroundSettings();

  @override
  State<_BackgroundSettings> createState() => _BackgroundSettingsState();
}

class _BackgroundSettingsState extends State<_BackgroundSettings> {
  /// Đang hiện ảnh nền Event → nút đổi hình nền theo thời gian bị làm mờ.
  bool get _eventBgNow {
    final s = app.activeSeason();
    return s != null && app.bgSource == 'event' && hasEventBackground(s.id);
  }

  bool _busy = false;
  static const _intervals = [1, 2, 5, 10, 15, 30, 60];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    final files = res?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final out = <Uint8List>[];
      for (final f in files) {
        final b = f.bytes;
        if (b == null) continue;
        out.add(await shrinkToJpeg(b));
      }
      final added = await app.addBackgrounds(out);
      if (added < out.length) {
        _toast('Đã thêm $added/${out.length} ảnh. Bộ nhớ trình duyệt đã đầy, '
            'hãy xoá bớt ảnh nền cũ nếu muốn thêm nữa.');
      } else {
        _toast('Đã thêm $added hình nền (tổng ${app.backgrounds.length}).');
      }
    } catch (_) {
      _toast('Có ảnh không đọc được. Hãy dùng PNG hoặc JPG.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(builder: (context) {
                final season = app.activeSeason();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Khi đang có lễ hội, dùng:'),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'event', label: Text('Ảnh nền Event')),
                        ButtonSegment(value: 'tuy_chon', label: Text('Ảnh nền của tôi')),
                      ],
                      selected: {app.bgSource == 'tuy_chon' ? 'tuy_chon' : 'event'},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) => app.update(() => app.bgSource = v.first),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.bgSource == 'event'
                          ? (season != null
                              ? 'Đang dùng ảnh nền riêng của ${season.emoji} ${season.name}. '
                                  'Hết lễ hội thì tự quay về ảnh nền của bạn bên dưới.'
                              : 'Mỗi lễ hội có ảnh nền riêng hợp màu với hiệu ứng. '
                                  'Ngày thường dùng ảnh nền của bạn bên dưới.')
                          : 'Lễ hội vẫn dùng ảnh nền của bạn (có thể bị lệch màu với hiệu ứng).',
                      style: const TextStyle(fontSize: 12.5, color: Colors.white60),
                    ),
                    const Divider(height: 20),
                  ],
                );
              }),
              const Text(
                'Chọn bao nhiêu ảnh cũng được, ảnh tự đổi lần lượt theo thời gian '
                'bên dưới. Dùng ảnh 1080p trở xuống để ít dung lượng nhất. '
                'Giữ lâu vào ảnh để xoá. Chưa có ảnh nào thì nền màu đen.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              if (app.backgrounds.isNotEmpty)
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: app.backgrounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => GestureDetector(
                      onLongPress: () => app.removeBackground(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(app.backgrounds[i],
                            width: 60, height: 84, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _busy ||
                          app.backgrounds.length >= AppState.maxBackgrounds
                      ? null
                      : _add,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wallpaper),
                  label: const Text('Thêm hình nền'),
                ),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: _eventBgNow ? 0.4 : 1,
                child: IgnorePointer(
                  ignoring: _eventBgNow,
                  child: Row(
                children: [
                  const Expanded(child: Text('Đổi hình nền mỗi')),
                  DropdownButton<int>(
                    value: _intervals.contains(app.bgIntervalMin)
                        ? app.bgIntervalMin
                        : 5,
                    items: [
                      for (final m in _intervals)
                        DropdownMenuItem(
                            value: m,
                            child: Text(m == 60 ? '1 giờ' : '$m phút')),
                    ],
                    onChanged: (v) =>
                        app.update(() => app.bgIntervalMin = v ?? 5),
                  ),
                ],
              ),
                ),
              ),
              Row(
                children: [
                  const Text('Độ tối nền'),
                  Expanded(
                    child: Slider(
                      value: app.bgDim.clamp(0.0, 0.8),
                      max: 0.8,
                      onChanged: (v) => app.update(() => app.bgDim = v),
                    ),
                  ),
                  Text('${(app.bgDim * 100).round()}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Lưu / mở bộ cấu hình ra file trên thiết bị
// =====================================================================

class _PresetSettings extends StatefulWidget {
  const _PresetSettings();

  @override
  State<_PresetSettings> createState() => _PresetSettingsState();
}

class _PresetSettingsState extends State<_PresetSettings> {
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    return cleaned.isEmpty ? 'bo_dong_ho' : cleaned;
  }

  Future<void> _save() async {
    final nameCtrl = TextEditingController(text: app.presetName ?? '');
    var withAlarms = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Lưu bộ cấu hình'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên bộ (vd: Gia đình, Khủng long xanh)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: withAlarms,
                onChanged: (v) => setD(() => withAlarms = v ?? false),
                title: const Text('Kèm danh sách báo thức'),
              ),
              const Text(
                'Gồm: 12 ảnh giờ, ảnh nền, chủ đề, tốc độ, báo giờ, hiển thị. '
                'Hãy nhớ nơi lưu file để lần sau mở lại.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim().isEmpty ? 'Bộ đồng hồ' : nameCtrl.text.trim();
    setState(() => _busy = true);
    try {
      final bytes = app.exportPreset(name, withAlarms: withAlarms);
      final fileName = '${_safeFileName(name)}.${AppState.presetExt}';
      final saved = await saveBytesToDevice(bytes, fileName);
      if (saved) {
        _toast('Đã lưu "$fileName" (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). '
            'Bản web: file nằm trong thư mục Tải xuống / Downloads.');
      }
    } catch (e) {
      _toast('Không lưu được file: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final file = res?.files.first;
    final bytes = file?.bytes;
    if (bytes == null || !mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mở bộ cấu hình?'),
        content: Text('Ảnh nền và cài đặt hiện tại sẽ được thay bằng nội dung của "${file!.name}". '
            'Bộ ảnh giờ trong file được thêm thành một mục mới trong "Chủ đề hình ảnh" '
            '(Ảnh của tôi giữ nguyên).\nNếu chưa lưu bộ hiện tại, hãy bấm Huỷ và lưu trước.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mở')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      final missing = await app.importPreset(bytes, fileName: file!.name);
      _toast(missing == 0
          ? 'Đã mở bộ "${app.presetName ?? file!.name}".'
          : 'Đã mở bộ, nhưng $missing ảnh nền không vừa bộ nhớ trình duyệt.');
    } on FormatException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('File bị lỗi hoặc không đúng định dạng.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                app.presetName == null
                    ? 'Chưa đặt tên bộ cấu hình'
                    : 'Đang dùng: ${app.presetName}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lưu toàn bộ ảnh + cài đặt thành 1 file trên máy để giữ lâu dài, '
                'chuyển sang máy khác hoặc gửi cho bạn bè. Khi cần thì mở lại.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_alt),
                    label: const Text('Lưu thành file'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _open,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Mở file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Kiểu, dáng & hệ: mặc định + riêng từng vị trí (danh sách thả xuống)
// =====================================================================

class _StyleSettings extends StatelessWidget {
  const _StyleSettings();

  static Widget _drop<T>(T value, List<T> values, String Function(T) label,
      ValueChanged<T> onChanged) {
    return DropdownButton<T>(
      isExpanded: true,
      value: value,
      items: [
        for (final v in values) DropdownMenuItem<T>(value: v, child: Text(label(v))),
      ],
      onChanged: (v) => onChanged(v as T),
    );
  }

  /// Một khối gồm: hình + tên vị trí + Kiểu (dòng 1), Dáng + Hệ (dòng 2).
  Widget _block({
    required Widget leading,
    required Widget style,
    required Widget body,
    required Widget element,
    Widget? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(children: [leading, Expanded(child: style)]),
          Row(
            children: [
              const SizedBox(width: 92),
              Expanded(child: body),
              const SizedBox(width: 8),
              Expanded(child: element),
            ],
          ),
          if (color != null)
            Row(children: [const SizedBox(width: 92), Expanded(child: color)]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = app.theme;
        const order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0];
        final stylesN = <ImageStyle?>[null, ...ImageStyle.values];
        final bodiesN = <BodyType?>[null, ...BodyType.values];
        final elemsN = <ElementType?>[null, ...kElementChoices];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kiểu – Standard: ảnh phẳng. 3D thổi phồng: khối tròn như thú bông. '
                  '3D phù điêu: như tượng đúc, chỗ sáng nổi cao, có ánh kim loại – hợp '
                  'với biểu tượng, huy hiệu. '
                  'Chibi 3D: ảnh làm mặt trên thân chibi (con vật thành "thú chibi"). '
                  'Người que: ảnh làm đầu trên thân người que.\n'
                  'Hệ – đổi chất liệu và thêm hiệu ứng động quanh hình. Tượng pha lê và '
                  'Hào quang có thêm lựa chọn màu.',
                  style: TextStyle(fontSize: 12.5, color: Colors.white60),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật hiệu ứng hệ'),
                  subtitle: const Text('Tắt nếu máy chạy chậm'),
                  value: app.effectsOn,
                  onChanged: (v) => app.update(() => app.effectsOn = v),
                ),
                _block(
                  leading: const SizedBox(
                    width: 92,
                    child: Text('Mặc định', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  style: _drop<ImageStyle>(app.defaultStyle, ImageStyle.values,
                      (v) => kImageStyleNames[v]!, (v) => app.update(() => app.defaultStyle = v)),
                  body: _drop<BodyType>(app.defaultBody, BodyType.values,
                      (v) => 'Dáng: ${kBodyTypeNames[v]!}', (v) => app.update(() => app.defaultBody = v)),
                  element: _drop<ElementType>(app.defaultElement, kElementChoices,
                      (v) => 'Hệ: ${kElementNames[v]!}',
                      (v) => app.update(() => app.defaultElement = v)),
                  color: elementHasColor(app.defaultElement)
                      ? _drop<ElemColor>(app.defaultElemColor, ElemColor.values,
                          (v) => 'Màu: ${kElemColorNames[v]!}',
                          (v) => app.update(() => app.defaultElemColor = v))
                      : null,
                ),
                const Divider(),
                for (final i in order)
                  _block(
                    leading: SizedBox(
                      width: 92,
                      child: Row(
                        children: [
                          SlotImageView(image: theme.slot(i), size: 34),
                          const SizedBox(width: 8),
                          Text(kRoman[i].toUpperCase()),
                        ],
                      ),
                    ),
                    style: _drop<ImageStyle?>(app.slotStyle[i], stylesN,
                        (v) => v == null ? 'Kiểu: mặc định' : kImageStyleNames[v]!,
                        (v) => app.update(() => app.slotStyle[i] = v)),
                    body: _drop<BodyType?>(app.slotBody[i], bodiesN,
                        (v) => v == null ? 'Dáng: mặc định' : 'Dáng: ${kBodyTypeNames[v]!}',
                        (v) => app.update(() => app.slotBody[i] = v)),
                    element: _drop<ElementType?>(app.slotElement[i], elemsN,
                        (v) => v == null ? 'Hệ: mặc định' : 'Hệ: ${kElementNames[v]!}',
                        (v) => app.update(() => app.slotElement[i] = v)),
                    color: elementHasColor(app.slotElement[i] ?? app.defaultElement)
                        ? _drop<ElemColor?>(app.slotElemColor[i], <ElemColor?>[null, ...ElemColor.values],
                            (v) => v == null ? 'Màu: mặc định' : 'Màu: ${kElemColorNames[v]!}',
                            (v) => app.update(() => app.slotElemColor[i] = v))
                        : null,
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => app.update(() {
                      app.slotStyle = List<ImageStyle?>.filled(12, null);
                      app.slotBody = List<BodyType?>.filled(12, null);
                      app.slotElement = List<ElementType?>.filled(12, null);
                      app.slotElemColor = List<ElemColor?>.filled(12, null);
                    }),
                    child: const Text('Đưa tất cả về mặc định'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// Theme mùa & lễ hội
// =====================================================================

class _SeasonSettings extends StatelessWidget {
  const _SeasonSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final now = DateTime.now();
        final themes = allThemes(now);
        final today = themeById(autoThemeId(now), now);
        final ids = ['off', 'auto', ...themes.map((t) => t.id)];
        String label(String id) {
          if (id == 'off') return 'Tắt';
          if (id == 'auto') return '🗓️ Tự động theo ngày';
          final t = themes.firstWhere((t) => t.id == id);
          return '${t.emoji} ${t.name}';
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thêm hiệu ứng theo mùa và ngày lễ (hoa rơi, tuyết, pháo hoa, lồng đèn...) '
                  'và màu nhấn cho vòng đồng hồ. Không thay đổi ảnh bạn đã chọn.',
                  style: TextStyle(fontSize: 12.5, color: Colors.white60),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: ids.contains(app.seasonMode) ? app.seasonMode : 'auto',
                  items: [
                    for (final id in ids) DropdownMenuItem(value: id, child: Text(label(id))),
                  ],
                  onChanged: (v) => app.update(() => app.seasonMode = v ?? 'auto'),
                ),
                if (app.seasonMode == 'auto' && today != null)
                  Text('Hôm nay: ${today.emoji} ${today.name}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Trời chạng vạng cho lễ hội ban đêm'),
                  subtitle: const Text(
                      'Lễ hội ánh sáng, Tết, Trung Thu, Giáng sinh… cần nền tối mới thấy rõ pháo hoa, cực quang, '
                      'đèn lồng. Khi hình nền sáng, app tự phủ lớp trời tối nhẹ phía trên; nền vốn tối thì giữ nguyên.'),
                  value: app.seasonNightDim,
                  onChanged: (v) => app.update(() => app.seasonNightDim = v),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
